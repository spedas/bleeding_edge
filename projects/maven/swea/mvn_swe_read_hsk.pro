;+
;PROCEDURE:   mvn_swe_read_hsk
;PURPOSE:
;  Reads in MAVEN Level 0 telemetry files (PFDPU packets wrapped in 
;  spacecraft packets).  SWEA normal housekeeping packets (APID 28)
;  are identified and decomuted.  Data are stored in a common block
;  (mvn_swe_com).
;
;USAGE:
;  mvn_swe_read_hsk, filename
;
;INPUTS:
;       filename:      The full filename (including path) of a binary file containing 
;                      zero or more SWEA APID's.  This file can contain compressed
;                      packets.
;
;KEYWORDS:
;       TRANGE:        Only keep packets within this time range.
;
;       CDRIFT:        Correct for spacecraft clock drift using SPICE.
;                      Default = 0 (no).
;
;       MAXBYTES:      Maximum number of bytes to process.  Default is entire file.
;
;       BADPKT:        An array of structures providing details of bad packets.
;
;       APPEND:        Append data to any previously loaded data.
;
;       VERBOSE:       If set, then print diagnostic information to stdout.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-02 11:13:42 -0700 (Wed, 02 Aug 2023) $
; $LastChangedRevision: 31974 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_read_hsk.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_swe_read_hsk.pro
;-
pro mvn_swe_read_hsk, filename, trange=trange, cdrift=cdrift, maxbytes=maxbytes, $
                      badpkt=badpkt, append=append, verbose=verbose

  @mvn_swe_com
  
  if keyword_set(trange) then begin
    tstart = min(time_double(trange), max=tstop)
    tflg = 1
  endif else tflg = 0
  
  dflg = keyword_set(cdrift)
  vflg = keyword_set(verbose)

; Read in the telemetry file and store the packets in a byte array

  openr, lun, filename, /get_lun, error=err
  
  if (err ne 0) then begin
    print, !error_state.msg
    return
  endif
  
  tlm = read_binary(lun, data_type=1, endian='big')  ; array of bytes

  free_lun,lun
  nbytes = n_elements(tlm)
  if (vflg) then print,nbytes," bytes"

  if keyword_set(maxbytes) then begin
    if (maxbytes lt 0) then begin
      print,"Maxbytes reached.  Skipping file."
      return
    endif
    if (maxbytes lt nbytes) then begin
      print,"Processing only the first ",string(maxbytes)," bytes"
      tlm = temporary(tlm[0L:(maxbytes-1L)])
    endif
    maxbytes = maxbytes - nbytes
  endif

; Counters for each SWEA packet type.

  n_23 = 0L   ; PFP analog housekeeping
  n_28 = 0L   ; SWEA Housekeeping
  n_XX = 0L   ; Unrecognized packets

; Packet pointer arrays

  ptr_23 = lonarr(nbytes/60L   + 1L)
  ptr_28 = lonarr(nbytes/112L  + 1L)

; Fixed sync bytes used to identify packets in telemetry stream
;   byte 0 --> version (0), secondary header (8)
;   byte 1 --> APID (for SWEA: 28, A0, A1, A2, A3, A4, A5, or A6)
;   byte 2 --> packet control sequence (11______)
;   byte 3 --> packet counter (00-FF)
;   byte 4 --> MSB of packet length (variable for compressed and uncompressed SWEA packets)
;   byte 5 --> LSB of packet length (09 for uncompressed SWEA packets, variable otherwise)

  s_23 = '082303'X
  s_28 = '082803'X

; For L0 data, all PFP packets are wrapped in a spacecraft packet.  The spacecraft header
; has the same format as the PFP headers.  There are four possible PFP APID's:
  
  s_P0 = '085003'X
  s_P1 = '085103'X
  s_P2 = '085303'X
  s_P3 = '086203'X

; Make one pass through the telemetry and count the number of packets of each type.

  n = 0L
  lastbyte = nbytes - 1L

  while (n lt (nbytes-14L)) do begin
    head = long(tlm[lindgen(14) + n])
    sync = head[2]/64L + 256L*(head[1] + 256L*head[0])  ; spacecraft header

    if ((sync eq s_P0) or (sync eq s_P1) or (sync eq s_P2) or (sync eq s_P3)) then begin
      pklen = 7L + head[5] + 256L*head[4]

      sync = head[13]/64L + 256L*(head[12] + 256L*head[11])  ; PFP header

      case sync of
        s_23 : ptr_23[n_23++] = n
        s_28 : ptr_28[n_28++] = n
        else : n_XX++
      endcase
    
    endif else pklen = 1L
    
    n = n + pklen

  endwhile
  
  if (vflg) then begin
    print,n_23," PFP Analog packets   (APID 23)"
    print,n_28," Housekeeping packets (APID 28)"
    print,n_XX," unrecognized packets"
  endif
  
  ptr_23 = ptr_23[0L:((n_23 - 1L) > 0L)]
  ptr_28 = ptr_28[0L:((n_28 - 1L) > 0L)]

  if (n_28 eq 0L) then begin
    print,"No SWEA packets!",format='(/,a,/)'
    return
  endif
  
; Define the data types, then make and array for each type

  maxlen = 2048

  bad_str = {time     : 0D            , $    ; packet unix time
             met      : 0D            , $    ; packet mission elapsed time
             addr     : -1L           , $    ; packet address
             npkt     : 0B            , $    ; packet counter
             plen     : 0             , $    ; packet length
             apid     : 0B            , $    ; packet APID
             dump     : bytarr(maxlen)   }   ; raw packet bytes

; Initialize the data arrays
; If no packets of a certain type exist, then don't overwrite whatever is in the common block.
; This allows sequential loading from multiple files containing subsets of the data (i.e. from 
; the splitter).

  if keyword_set(append) then begin
    pfp_hsk_s = pfp_hsk
    swe_hsk_s = swe_hsk
  endif

  if (n_23 gt 0L) then pfp_hsk = replicate(pfp_hsk_str, n_23)
  if (n_28 gt 0L) then swe_hsk = replicate(swe_hsk_str, n_28)

; Pass through the telemetry and decommute

  n = 0L
  if (size(badpkt,/type) ne 8) then badpkt = replicate(bad_str,1)

; PFP Analog Housekeeping (APID 23)
;   PFP analog housekeeping temperature, voltage and current monitors.
;   This includes a SWEA current monitor, and the primary regulated 28V
;   supply that powers SWEA.

  order = n_elements(pfp_t) - 1

  for k=0L,(n_23 - 1L) do begin
    n = ptr_23[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

	pkt = tlm[i:j]  ; housekeeping packets are never compressed
	plen = n_elements(pkt)

	if (plen ne 60) then begin
	  print,"Bad PFP packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  msb = 2*indgen(5)
	  lsb = msb + 1
	  ccsds = uint(pkt[msb])*256 + uint(pkt[lsb])

	  bad_str.apid = '23'X
	  bad_str.npkt = mvn_swe_getbits(ccsds[1],[13,0])
	  bad_str.plen = plen

	  bad_str.met = double(ccsds[3])*65536D + double(ccsds[4])
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

    endif else begin

	  pfp_hsk[k].addr = n

; Header (bytes 0-9)

	  msb = 2*indgen(5)
	  lsb = msb + 1
	  ccsds = uint(pkt[msb])*256 + uint(pkt[lsb])

	  pfp_hsk[k].ver  = mvn_swe_getbits(ccsds[0],[15,13])
	  pfp_hsk[k].type = mvn_swe_getbits(ccsds[0],12)
	  pfp_hsk[k].hflg = mvn_swe_getbits(ccsds[0],11)
	  pfp_hsk[k].APID = mvn_swe_getbits(ccsds[0],[10,0])
	  pfp_hsk[k].gflg = mvn_swe_getbits(ccsds[1],[15,14])
	  pfp_hsk[k].npkt = mvn_swe_getbits(ccsds[1],[13,0])
	  pfp_hsk[k].plen = ccsds[2]
			   
	  pfp_hsk[k].met  = double(ccsds[3])*65536D + double(ccsds[4])
	  pfp_hsk[k].time = mvn_spc_met_to_unixtime(pfp_hsk[k].met,correct=dflg)

; PFP Analog Housekeeping (bytes 10-57)

	  msb = 2L*lindgen(24) + 10L
	  lsb = msb + 1L
	  ahsk = float(fix(pkt[msb])*256 + fix(pkt[lsb]))

	  pfp_hsk[k].N5AV    = ahsk[0]*pfp_v[0]
	  pfp_hsk[k].P5AV    = ahsk[1]*pfp_v[1]
	  pfp_hsk[k].P5DV    = ahsk[2]*pfp_v[2]
      pfp_hsk[k].P3P3DV  = ahsk[3]*pfp_v[3]
	  pfp_hsk[k].P1P5DV  = ahsk[4]*pfp_v[4]
	  pfp_hsk[k].P28V    = ahsk[5]*pfp_v[5]
	  pfp_hsk[k].SWE28I  = ahsk[6]*pfp_v[6]

	  T = pfp_t[order] & for i=(order-1),0,-1 do T = pfp_t[i] + T*ahsk[7]
	  pfp_hsk[k].REGT    = T

	  pfp_hsk[k].SWI28I  = ahsk[8]*pfp_v[8]
	  pfp_hsk[k].STA28I  = ahsk[9]*pfp_v[9]
	  pfp_hsk[k].MAG128I = ahsk[10]*pfp_v[10]
	  pfp_hsk[k].MAG228I = ahsk[11]*pfp_v[11]
	  pfp_hsk[k].SEP28I  = ahsk[12]*pfp_v[12]
	  pfp_hsk[k].LPW28I  = ahsk[13]*pfp_v[13]
	  pfp_hsk[k].PFP28V  = ahsk[14]*pfp_v[14]
	  pfp_hsk[k].PFP28I  = ahsk[15]*pfp_v[15]

	  T = pfp_t[order] & for i=(order-1),0,-1 do T = pfp_t[i] + T*ahsk[16]
	  pfp_hsk[k].DCBT   = T

	  T = pfp_t[order] & for i=(order-1),0,-1 do T = pfp_t[i] + T*ahsk[17]
	  pfp_hsk[k].FPGAT   = T

	  pfp_hsk[k].FLASH0V = ahsk[18]*pfp_v[18]
	  pfp_hsk[k].FLASH1V = ahsk[19]*pfp_v[19]
	  pfp_hsk[k].PF3P3DV = ahsk[20]*pfp_v[20]
	  pfp_hsk[k].PF1P5DV = ahsk[21]*pfp_v[21]
	  pfp_hsk[k].PFPVREF = ahsk[22]*pfp_v[22]
	  pfp_hsk[k].PFPAGND = ahsk[23]*pfp_v[23]

; 2 spare bytes (58-59)

	endelse

  endfor
  
  if (n_23 gt 0L) then begin
    indx = where(pfp_hsk.addr ne -1L, n_23)
    if (n_23 gt 0L) then pfp_hsk = temporary(pfp_hsk[indx]) else begin
      print,"No PFP housekeeping (APID 23)!"
      pfp_hsk = 0
    endelse
  endif

; Housekeeping (APID 28)
;   SWEA housekeeping includes 3 temperatures (thermistors on the LVPS, 
;   digital board, and anode board), analyzer voltages, MCP bias, and
;   numerous voltages provided by the LVPS to the front-end electronics
;   and digital board.  A total of 24 values are multiplexed into 224
;   housekeeping messages.  Time resolutions are:
;
;     anode counters   : 448 messages in 1.95 sec --> 0.00435 sec
;     hsk per channel  :   9 messages in 1.95 sec --> 0.21 sec
;     fast hsk (1 ch)  : 224 messages in 1.95 sec --> 0.00871 sec
;     dwell hsk (1 ch) : 448 messages in 1.95 sec --> 0.00435 sec
;
;   Only one channel at a time can be the fast housekeeping channel, 
;   with 224 messages per cycle.
;
;   In dwell mode, all 448 housekeeping messages are devoted to one 
;   channel -- all other channels are ignored.
;
;   The 24 housekeeping channels are:
;
;   Channel   Value
;  -----------------------------------------
;      0      LVPST
;      1      MCPHV
;      2      NRV     (scaled)
;      3      ANALV
;      4      DEF1V
;      5      DEF2V
;      6      -       (unused)
;      7      -       (unused)
;      8      V0V
;      9      ANALT
;     10      P12V
;     11      N12V
;     12      MCP28V  (after enable plug)
;     13      NR28V   (after enable plug)
;     14      -       (unused)
;     15      -       (unused)
;     16      DIGT
;     17      P2P5DV
;     18      P5DV
;     19      P3P3DV
;     20      P5AV
;     21      N5AV
;     22      P28V    (before enable plug)
;     23      -       (unused)
;  -----------------------------------------
;

  order = n_elements(swe_t) - 1

  for k=0L,(n_28 - 1L) do begin
    n = ptr_28[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

	pkt = tlm[i:j]  ; housekeeping packets are never compressed
	plen = n_elements(pkt)

	if (plen ne 112) then begin
	  print,"Bad HSK packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  msb = 2*indgen(5)
	  lsb = msb + 1
	  ccsds = uint(pkt[msb])*256 + uint(pkt[lsb])

	  bad_str.apid = '28'X
	  bad_str.npkt = mvn_swe_getbits(ccsds[1],[13,0])
	  bad_str.plen = plen

	  bad_str.met = double(ccsds[3])*65536D + double(ccsds[4])
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

    endif else begin

	  swe_hsk[k].addr = n

; Header (bytes 0-9)

	  msb = 2*indgen(5)
	  lsb = msb + 1
	  ccsds = uint(pkt[msb])*256 + uint(pkt[lsb])

	  swe_hsk[k].ver  = mvn_swe_getbits(ccsds[0],[15,13])
	  swe_hsk[k].type = mvn_swe_getbits(ccsds[0],12)
	  swe_hsk[k].hflg = mvn_swe_getbits(ccsds[0],11)
	  swe_hsk[k].APID = mvn_swe_getbits(ccsds[0],[10,0])
	  swe_hsk[k].gflg = mvn_swe_getbits(ccsds[1],[15,14])
	  swe_hsk[k].npkt = mvn_swe_getbits(ccsds[1],[13,0])
	  swe_hsk[k].plen = ccsds[2]
			   
	  swe_hsk[k].met  = double(ccsds[3])*65536D + double(ccsds[4])
	  swe_hsk[k].time = mvn_spc_met_to_unixtime(swe_hsk[k].met,correct=dflg)

; SWEA Analog Housekeeping (bytes 10-57)

	  msb = 2L*lindgen(24) + 10L
	  lsb = msb + 1L
	  ahsk = float(fix(pkt[msb])*256 + fix(pkt[lsb]))

	  T = swe_t[order] & for i=(order-1),0,-1 do T = swe_t[i] + T*ahsk[0]
	  swe_hsk[k].LVPST  = T

	  swe_hsk[k].MCPHV  = ahsk[1]*swe_v[1] + 40. ; pull-down resistor
	  swe_hsk[k].NRV    = ahsk[2]*swe_v[2]
	  swe_hsk[k].ANALV  = ahsk[3]*swe_v[3]
      swe_hsk[k].DEF1V  = ahsk[4]*swe_v[4]
	  swe_hsk[k].DEF2V  = ahsk[5]*swe_v[5]
	  swe_hsk[k].V0V    = ahsk[8]*swe_v[8]

	  T = swe_t[order] & for i=(order-1),0,-1 do T = swe_t[i] + T*ahsk[9]
	  swe_hsk[k].ANALT  = T

	  swe_hsk[k].P12V   = ahsk[10]*swe_v[10]
	  swe_hsk[k].N12V   = ahsk[11]*swe_v[11]
	  swe_hsk[k].MCP28V = ahsk[12]*swe_v[12]
	  swe_hsk[k].NR28V  = ahsk[13]*swe_v[13]

	  T = swe_t[order] & for i=(order-1),0,-1 do T = swe_t[i] + T*ahsk[16]
	  swe_hsk[k].DIGT   = T

	  swe_hsk[k].P2P5DV = ahsk[17]*swe_v[17]
	  swe_hsk[k].P5DV   = ahsk[18]*swe_v[18]
	  swe_hsk[k].P3P3DV = ahsk[19]*swe_v[19]
	  swe_hsk[k].P5AV   = ahsk[20]*swe_v[20]
	  swe_hsk[k].N5AV   = ahsk[21]*swe_v[21]
	  swe_hsk[k].P28V   = ahsk[22]*swe_v[22]

; Flight Software Housekeeping (bytes 58-89)

	  swe_hsk[k].modeID    = pkt[58]
	  swe_hsk[k].opts      = pkt[59]
	  swe_hsk[k].DistSvy   = pkt[60]
	  swe_hsk[k].DistArc   = pkt[61]
	  swe_hsk[k].PadSvy    = pkt[62]
	  swe_hsk[k].PadArc    = pkt[63]
	  swe_hsk[k].SpecSvy   = pkt[64]
	  swe_hsk[k].SpecArc   = pkt[65]
	  swe_hsk[k].LUTADR[0] = pkt[66]
	  swe_hsk[k].LUTADR[1] = pkt[67]
	  swe_hsk[k].LUTADR[2] = pkt[68]
	  swe_hsk[k].LUTADR[3] = pkt[69]
	  swe_hsk[k].CSMLMT    = pkt[70]
	  swe_hsk[k].CSMCTR    = pkt[71]
	  swe_hsk[k].RSTLMT    = pkt[72]
	  swe_hsk[k].RSTSEC    = pkt[73]
	  swe_hsk[k].MUX[0]    = pkt[74]
	  swe_hsk[k].MUX[1]    = pkt[75]
	  swe_hsk[k].MUX[2]    = pkt[76]
	  swe_hsk[k].MUX[3]    = pkt[77]
      swe_hsk[k].DSF[0]    = float(uint(pkt[78])*256 + uint(pkt[79]))/4096.
	  swe_hsk[k].DSF[1]    = float(uint(pkt[80])*256 + uint(pkt[81]))/4096.
	  swe_hsk[k].DSF[2]    = float(uint(pkt[82])*256 + uint(pkt[83]))/4096.
	  swe_hsk[k].DSF[3]    = float(uint(pkt[84])*256 + uint(pkt[85]))/4096.
	  swe_hsk[k].DSF[4]    = float(uint(pkt[86])*256 + uint(pkt[87]))/4096.
	  swe_hsk[k].DSF[5]    = float(uint(pkt[88])*256 + uint(pkt[89]))/4096.

; LUT, Checksums, Command Counter, and Digital Housekeeping (bytes 92-109)
			   
      swe_hsk[k].SSCTL     = uint(pkt[90])*256 + uint(pkt[91])
      swe_hsk[k].SIFCTL    = nibble(uint(pkt[92])*256 + uint(pkt[93]))
      swe_hsk[k].MCPDAC    = uint(pkt[94])*256 + uint(pkt[95])
	  swe_hsk[k].Chksum[0] = pkt[96]
	  swe_hsk[k].Chksum[1] = pkt[97]
	  swe_hsk[k].Chksum[2] = pkt[98]
	  swe_hsk[k].Chksum[3] = pkt[99]
	  swe_hsk[k].CmdCnt    = uint(pkt[100])*256 + uint(pkt[101])
	  swe_hsk[k].HSKREG    = nibble(uint(pkt[108])*256 + uint(pkt[109]))

; 2 spare bytes (110-111)

	endelse

  endfor
  
  if (n_28 gt 0L) then begin
    indx = where(swe_hsk.addr ne -1L, n_28)
    if (n_28 gt 0L) then swe_hsk = temporary(swe_hsk[indx]) else begin
      print,"No housekeeping (APID 28)!"
      swe_hsk = 0
    endelse
  endif

; Check for bogus HSK packets (usually first packet after turnon).
; A raw value of '00'X for temperature corresponds to 165 C, which is bogus.

  if (n_28 gt 0L) then begin
    indx = where(swe_hsk.LVPST lt 100., count)
    if (count gt 0L) then swe_hsk = temporary(swe_hsk[indx])
  endif

; Check for packets with zero MET - discard them
; Trim data to requested time range

  t0 = mvn_spc_met_to_unixtime(10D)

  if (n_23 gt 0L) then begin
    indx = where(pfp_hsk.time lt t0, count, complement=jndx, ncomp=n_23)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = pfp_hsk[indx[i]].addr
        print,"Zero MET in PFP HSK: ",n,format='(a,Z)'
      endfor
      if (n_23 eq 0L) then begin
        print,"No valid PFP HSK packets!"
        pfp_hsk = 0
      endif else pfp_hsk = temporary(pfp_hsk[jndx])
    endif
    if (tflg) then begin
      indx = where((pfp_hsk.time ge tstart) and (pfp_hsk.time le tstop), n_23)
      if (n_23 eq 0L) then begin
        print,"No PFP HSK packets within TRANGE."
        pfp_hsk = 0
      endif else pfp_hsk = temporary(pfp_hsk[indx])
    endif
  endif

  if (n_28 gt 0L) then begin
    indx = where(swe_hsk.time lt t0, count, complement=jndx, ncomp=n_28)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = swe_hsk[indx[i]].addr
        print,"Zero MET in HSK: ",n,format='(a,Z)'
      endfor
      if (n_28 eq 0L) then begin
        print,"No valid HSK packets!"
        swe_hsk = 0
      endif else swe_hsk = temporary(swe_hsk[jndx])
    endif
    if (tflg) then begin
      indx = where((swe_hsk.time ge tstart) and (swe_hsk.time le tstop), n_28)
      if (n_28 eq 0L) then begin
        print,"No HSK packets within TRANGE."
        swe_hsk = 0
      endif else swe_hsk = temporary(swe_hsk[indx])
    endif
  endif

; Trim and sort bad packet addresses
  
  if (n_elements(badpkt) gt 1L) then badpkt = badpkt[1L:*] else badpkt = 0

; Append to previously loaded data

  if keyword_set(append) then begin
    if (size(pfp_hsk_s,/type) eq 8) then begin
      if (size(pfp_hsk,/type) eq 8) then pfp_hsk = [temporary(pfp_hsk_s), temporary(pfp_hsk)] $
                                    else pfp_hsk = temporary(pfp_hsk_s)
    endif
    if (size(swe_hsk_s,/type) eq 8) then begin
      if (size(swe_hsk,/type) eq 8) then swe_hsk = [temporary(swe_hsk_s), temporary(swe_hsk)] $
                                    else swe_hsk = temporary(swe_hsk_s)
    endif
  endif

  return

end
