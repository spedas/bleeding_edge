;+
;PROCEDURE:   mvn_swe_read_l0
;PURPOSE:
;  Reads in MAVEN Level 0 telemetry files (PFDPU packets wrapped in 
;  spacecraft packets).  SWEA packets are identified, decompressed if
;  necessary, and decomuted.  SWEA housekeeping and data are stored in 
;  a common block (mvn_swe_com).
;
;  The packets can be any combination of:
;
;    Housekeeping:      normal rate  (APID 28)
;                       fast rate    (APID A6)
;                       pfp analog   (APID 23)
;
;    3D Distributions:  survey mode  (APID A0)
;                       archive mode (APID A1)
;
;    PAD Distributions: survey mode  (APID A2)
;                       archive mode (APID A3)
;
;    ENGY Spectra:      survey mode  (APID A4)
;                       archive mode (APID A5)
;
;  Sampling and averaging of 3D, PAD, and ENGY data are controlled by group
;  and cycle parameters.  The group parameter (G = 0,1,2) sets the summing of
;  adjacent energy bins.  The cycle parameter (N = 0,1,2,3,4,5) sets sampling 
;  of 2-second measurement cycles.  Data products are sampled every 2^N cycles.
;
;  3D distributions are stored in 1, 2 or 4 packets, depending on the group 
;  parameter.  Multiple packets must be stitched together (see swe_3d_stitch).
;
;  PAD packets have one of 3 possible lengths, depending on the group parameter.
;  The PAD data array is sized to accomodate the largest packet (G = 0).  When
;  energies are summed, only 1/2 or 1/4 of this data array is used.
;
;  ENGY spectra always have 64 energy channels (G = 0).
;
;USAGE:
;  mvn_swe_read_l0, filename
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
; $LastChangedDate: 2024-01-08 16:01:00 -0800 (Mon, 08 Jan 2024) $
; $LastChangedRevision: 32336 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_read_l0.pro $
;
;CREATED BY:    David L. Mitchell  04-25-13
;FILE: mvn_swe_read_l0.pro
;-
pro mvn_swe_read_l0, filename, trange=trange, cdrift=cdrift, maxbytes=maxbytes, $
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
  n_A0 = 0L   ; 3D survey
  n_A1 = 0L   ; 3D archive
  n_A2 = 0L   ; PAD survey
  n_A3 = 0L   ; PAD archive
  n_A4 = 0L   ; ENGY survey
  n_A5 = 0L   ; ENGY archive
  n_A6 = 0L   ; Fast Housekeeping
  n_XX = 0L   ; Unrecognized packets

; Packet pointer arrays

  ptr_23 = lonarr(nbytes/60L   + 1L)
  ptr_28 = lonarr(nbytes/112L  + 1L)
  ptr_A0 = lonarr(nbytes/1296L + 1L)
  ptr_A1 = lonarr(nbytes/1296L + 1L)
  ptr_A2 = lonarr(nbytes/272L  + 1L)
  ptr_A3 = lonarr(nbytes/272L  + 1L)
  ptr_A4 = lonarr(nbytes/1040L + 1L)
  ptr_A5 = lonarr(nbytes/1040L + 1L)
  ptr_A6 = lonarr(nbytes/1808L + 1L)

; Fixed sync bytes used to identify packets in telemetry stream
;   byte 0 --> version (0), secondary header (8)
;   byte 1 --> APID (for SWEA: 28, A0, A1, A2, A3, A4, A5, or A6)
;   byte 2 --> packet control sequence (11______)
;   byte 3 --> packet counter (00-FF)
;   byte 4 --> MSB of packet length (variable for compressed and uncompressed SWEA packets)
;   byte 5 --> LSB of packet length (09 for uncompressed SWEA packets, variable otherwise)

  s_23 = '082303'X
  s_28 = '082803'X
  s_A0 = '08A003'X
  s_A1 = '08A103'X
  s_A2 = '08A203'X
  s_A3 = '08A303'X
  s_A4 = '08A403'X
  s_A5 = '08A503'X
  s_A6 = '08A603'X

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
        s_A0 : ptr_A0[n_A0++] = n
        s_A1 : ptr_A1[n_A1++] = n
        s_A2 : ptr_A2[n_A2++] = n
        s_A3 : ptr_A3[n_A3++] = n
        s_A4 : ptr_A4[n_A4++] = n
        s_A5 : ptr_A5[n_A5++] = n
        s_A6 : ptr_A6[n_A6++] = n
        else : n_XX++
      endcase
    
    endif else pklen = 1L
    
    n = n + pklen

  endwhile
  
  if (vflg) then begin
    print,n_23," PFP Analog packets   (APID 23)"
    print,n_28," Housekeeping packets (APID 28)"
    print,n_A0," 3D Survey packets    (APID A0)"
    print,n_A1," 3D Archive packets   (APID A1)"
    print,n_A2," PAD Survey packets   (APID A2)"
    print,n_A3," PAD Archive packets  (APID A3)"
    print,n_A4," ENGY Survey packets  (APID A4)"
    print,n_A5," ENGY Archive packets (APID A5)"
    print,n_A6," Fast Hsk packets     (APID A6)"
    print,n_XX," unrecognized packets"
  endif
  
  ptr_23 = ptr_23[0L:((n_23 - 1L) > 0L)]
  ptr_28 = ptr_28[0L:((n_28 - 1L) > 0L)]
  ptr_A0 = ptr_A0[0L:((n_A0 - 1L) > 0L)]
  ptr_A1 = ptr_A1[0L:((n_A1 - 1L) > 0L)]
  ptr_A2 = ptr_A2[0L:((n_A2 - 1L) > 0L)]
  ptr_A3 = ptr_A3[0L:((n_A3 - 1L) > 0L)]
  ptr_A4 = ptr_A4[0L:((n_A4 - 1L) > 0L)]
  ptr_A5 = ptr_A5[0L:((n_A5 - 1L) > 0L)]
  ptr_A6 = ptr_A6[0L:((n_A6 - 1L) > 0L)]

  if ((n_28 + n_A0 + n_A1 + n_A2 + n_A3 + n_A4 + n_A5 + n_A6) eq 0L) then begin
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
    a0_s = a0
    a1_s = a1
    a2_s = a2
    a3_s = a3
    a4_s = a4
    a5_s = a5
    a6_s = a6
  endif

  if (n_23 gt 0L) then pfp_hsk = replicate(pfp_hsk_str, n_23)
  if (n_28 gt 0L) then swe_hsk = replicate(swe_hsk_str, n_28)
  if (n_A0 gt 0L) then a0 = replicate(swe_a0_str, n_A0)
  if (n_A1 gt 0L) then a1 = replicate(swe_a0_str, n_A1)
  if (n_A2 gt 0L) then a2 = replicate(swe_a2_str, n_A2)
  if (n_A3 gt 0L) then a3 = replicate(swe_a2_str, n_A3)
  if (n_A4 gt 0L) then a4 = replicate(swe_a4_str, n_A4)
  if (n_A5 gt 0L) then a5 = replicate(swe_a4_str, n_A5)
  if (n_A6 gt 0L) then a6 = replicate(swe_a6_str, n_A6)

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

; 3D Distributions - Survey (APID A0)

  for k=0L,(n_A0 - 1L) do begin
    n = ptr_A0[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

    pkt = mav_pfdpu_part_decompress_data2(tlm[i:j])
	plen = n_elements(pkt)

	if (plen ne 1296) then begin
	  print,"Bad A0 packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  bad_str.apid = 'A0'X
	  bad_str.npkt = pkt[3]
	  bad_str.plen = plen

	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      bad_str.met = clock + subsecs
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

	endif else begin

	  a0[k].addr = n
	  a0[k].npkt = pkt[3]
			   
      tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      a0[k].met    = clock + subsecs
	  a0[k].time   = mvn_spc_met_to_unixtime(a0[k].met,correct=dflg)

	  a0[k].cflg   = mvn_swe_getbits(pkt[12],7)          ; first bit
	  a0[k].modeID = mvn_swe_getbits(pkt[12],[6,0])      ; last 7 bits
			   
	  a0[k].ctype  = mvn_swe_getbits(pkt[13],[7,6])      ; first 2 bits
	  a0[k].group  = mvn_swe_getbits(pkt[13],[5,4])      ; next 2 bits
	  a0[k].period = mvn_swe_getbits(pkt[13],[3,0])      ; last 4 bits
			   
	  a0[k].lut    = mvn_swe_getbits(pkt[14],[2,0])      ; last 3 bits
	   
	  a0[k].e0     = mvn_swe_getbits(pkt[15],[1,0])      ; last 2 bits
			   
	  a0[k].data = reform(decom[pkt[16:1295]],80,16)     ; counts
	  a0[k].var  = reform(devar[pkt[16:1295]],80,16)     ; variance

	endelse

  endfor
  
  if (n_A0 gt 0L) then begin
    indx = where(a0.addr ne -1L, n_A0)
    if (n_A0 gt 0L) then a0 = temporary(a0[indx]) else a0 = 0
  endif

; 3D Distributions - Archive (APID A1)

  for k=0L,(n_A1 - 1L) do begin
    n = ptr_A1[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

	pkt = mav_pfdpu_part_decompress_data2(tlm[i:j])
	plen = n_elements(pkt)

	if (plen ne 1296) then begin
	  print,"Bad A1 packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  bad_str.apid = 'A1'X
	  bad_str.npkt = pkt[3]
	  bad_str.plen = plen

	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      bad_str.met = clock + subsecs
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

    endif else begin

	  a1[k].addr = n
	  a1[k].npkt = pkt[3]
			   
	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      a1[k].met    = clock + subsecs
	  a1[k].time   = mvn_spc_met_to_unixtime(a1[k].met,correct=dflg)

	  a1[k].cflg   = mvn_swe_getbits(pkt[12],7)          ; first bit
	  a1[k].modeID = mvn_swe_getbits(pkt[12],[6,0])      ; last 7 bits
			   
	  a1[k].ctype  = mvn_swe_getbits(pkt[13],[7,6])      ; first 2 bits
	  a1[k].group  = mvn_swe_getbits(pkt[13],[5,4])      ; next 2 bits
	  a1[k].period = mvn_swe_getbits(pkt[13],[3,0])      ; last 4 bits
			   
	  a1[k].lut    = mvn_swe_getbits(pkt[14],[2,0])      ; last 3 bits
			   
	  a1[k].e0     = mvn_swe_getbits(pkt[15],[1,0])      ; last 2 bits

	  a1[k].data = reform(decom[pkt[16:1295]],80,16)     ; counts
	  a1[k].var  = reform(devar[pkt[16:1295]],80,16)     ; variance

	endelse

  endfor
  
  if (n_A1 gt 0L) then begin
    indx = where(a1.addr ne -1L, n_A1)
    if (n_A1 gt 0L) then a1 = temporary(a1[indx]) else a1 = 0
  endif

; PAD Distributions - Survey (APID A2)

  for k=0L,(n_A2 - 1L) do begin
    n = ptr_A2[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

	pkt = mav_pfdpu_part_decompress_data2(tlm[i:j])
	plen = n_elements(pkt)

    if ((plen ne 1040) && (plen ne 528) && (plen ne 272)) then begin
	  print,"Bad A2 packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  bad_str.apid = 'A2'X
	  bad_str.npkt = pkt[3]
	  bad_str.plen = plen

	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      bad_str.met = clock + subsecs
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

	endif else begin
			   
	  a2[k].addr = n
	  a2[k].npkt = pkt[3]
			   
	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      a2[k].met    = clock + subsecs
	  a2[k].time   = mvn_spc_met_to_unixtime(a2[k].met,correct=dflg)

	  a2[k].cflg   = mvn_swe_getbits(pkt[12],7)            ; first bit
	  a2[k].modeID = mvn_swe_getbits(pkt[12],[6,0])        ; last 7 bits
			   
	  a2[k].ctype  = mvn_swe_getbits(pkt[13],[7,6])        ; first 2 bits
	  a2[k].group  = mvn_swe_getbits(pkt[13],[5,4])        ; next 2 bits
	  a2[k].period = mvn_swe_getbits(pkt[13],[3,0])        ; last 4 bits

	  a2[k].Baz    = pkt[14]                               ; 0-255
	  a2[k].Bel    = mvn_swe_getbits(pkt[15],[5,0])        ; 0-39
			   
	  n_e = swe_ne[a2[k].group]
	  bmax = 16*n_e + 15

	  if ((bmax+1) eq n_elements(pkt)) then begin
        a2[k].data[*,0:(n_e-1)] = reform(decom[pkt[16:bmax]],16,n_e)  ; counts
        a2[k].var[*,0:(n_e-1)]  = reform(devar[pkt[16:bmax]],16,n_e)  ; variance
	  endif else begin
	    print, "Bad A2 packet: ",n,format='(a,Z)'
	    a2[k].addr = -1L
	  endelse

	endelse

  endfor
  
  if (n_A2 gt 0L) then begin
    indx = where(a2.addr ne -1L, n_A2)
    if (n_A2 gt 0L) then a2 = temporary(a2[indx]) else a2 = 0
  endif

; PAD Distributions - Archive (APID A3)

  for k=0L,(n_A3 - 1L) do begin
    n = ptr_A3[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

	pkt = mav_pfdpu_part_decompress_data2(tlm[i:j])
	plen = n_elements(pkt)

    if ((plen ne 1040) && (plen ne 528) && (plen ne 272)) then begin
	  print,"Bad A3 packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  bad_str.apid = 'A3'X
	  bad_str.npkt = pkt[3]
	  bad_str.plen = plen

	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      bad_str.met = clock + subsecs
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

	endif else begin

	  a3[k].addr = n
	  a3[k].npkt = pkt[3]
			   
	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      a3[k].met    = clock + subsecs
	  a3[k].time   = mvn_spc_met_to_unixtime(a3[k].met,correct=dflg)

	  a3[k].cflg   = mvn_swe_getbits(pkt[12],7)            ; first bit
	  a3[k].modeID = mvn_swe_getbits(pkt[12],[6,0])        ; last 7 bits
			   
	  a3[k].ctype  = mvn_swe_getbits(pkt[13],[7,6])        ; first 2 bits
	  a3[k].group  = mvn_swe_getbits(pkt[13],[5,4])        ; next 2 bits
	  a3[k].period = mvn_swe_getbits(pkt[13],[3,0])        ; last 4 bits
							  
	  a3[k].Baz    = float(pkt[14])
	  a3[k].Bel    = float(mvn_swe_getbits(pkt[15],[5,0])) ; last 6 bits

	  n_e = swe_ne[a3[k].group]
	  bmax = 16*n_e + 15

	  if ((bmax+1) eq n_elements(pkt)) then begin
        a3[k].data[*,0:(n_e-1)] = reform(decom[pkt[16:bmax]],16,n_e)  ; counts
        a3[k].var[*,0:(n_e-1)]  = reform(devar[pkt[16:bmax]],16,n_e)  ; variance
	  endif else begin
	    print, "Bad A3 packet: ",n,format='(a,Z)'
	    a3[k].addr = -1L
	  endelse

	endelse

  end
  
  if (n_A3 gt 0L) then begin
    indx = where(a3.addr ne -1L, n_A3)
    if (n_A3 gt 0L) then a3 = temporary(a3[indx]) else a3 = 0
  endif

; Energy Spectra - Survey (APID A4)

  for k=0L,(n_A4 - 1L) do begin
    n = ptr_A4[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

	pkt = mav_pfdpu_part_decompress_data2(tlm[i:j])
	plen = n_elements(pkt)

	if (plen ne 1040) then begin
	  print,"Bad A4 packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  bad_str.apid = 'A4'X
	  bad_str.npkt = pkt[3]
	  bad_str.plen = plen

	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      bad_str.met = clock + subsecs
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

	endif else begin

	  a4[k].addr = n
	  a4[k].npkt = pkt[3]
			   
	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      a4[k].met    = clock + subsecs
	  a4[k].time   = mvn_spc_met_to_unixtime(a4[k].met,correct=dflg)

	  a4[k].cflg   = mvn_swe_getbits(pkt[12],7)           ; first bit
	  a4[k].modeID = mvn_swe_getbits(pkt[12],[6,0])       ; last 7 bits
			   
	  a4[k].ctype  = mvn_swe_getbits(pkt[13],[7,6])       ; first 2 bits
	  a4[k].smode  = mvn_swe_getbits(pkt[13],3)           ; fifth bit
	  a4[k].period = mvn_swe_getbits(pkt[13],[2,0])       ; last 3 bits
			   
	  a4[k].lut    = mvn_swe_getbits(pkt[14],[2,0])       ; last 3 bits
							  
	  a4[k].data = reform(decom[pkt[16:1039]],64,16)      ; counts
	  a4[k].var  = reform(devar[pkt[16:1039]],64,16)      ; variance

	endelse

  end
  
  if (n_A4 gt 0L) then begin
    indx = where(a4.addr ne -1L, n_A4)
    if (n_A4 gt 0L) then a4 = temporary(a4[indx]) else a4 = 0
  endif

; Energy Spectra - Archive (APID A5)

  for k=0L,(n_A5 - 1L) do begin
    n = ptr_A5[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

	pkt = mav_pfdpu_part_decompress_data2(tlm[i:j])
	plen = n_elements(pkt)

	if (plen ne 1040) then begin
	  print,"Bad A5 packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  bad_str.apid = 'A5'X
	  bad_str.npkt = pkt[3]
	  bad_str.plen = plen

	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      bad_str.met = clock + subsecs
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

	endif else begin

      a5[k].addr = n
	  a5[k].npkt = pkt[3]
			   
	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      a5[k].met    = clock + subsecs
	  a5[k].time   = mvn_spc_met_to_unixtime(a5[k].met,correct=dflg)

	  a5[k].cflg   = mvn_swe_getbits(pkt[12],7)           ; first bit
	  a5[k].modeID = mvn_swe_getbits(pkt[12],[6,0])       ; last 7 bits
			   
	  a5[k].ctype  = mvn_swe_getbits(pkt[13],[7,6])       ; first 2 bits
	  a5[k].smode  = mvn_swe_getbits(pkt[13],3)           ; fifth bit
	  a5[k].period = mvn_swe_getbits(pkt[13],[2,0])       ; last 3 bits
			   
	  a5[k].lut    = mvn_swe_getbits(pkt[14],[2,0])       ; last 3 bits
							  
	  a5[k].data = reform(decom[pkt[16:1039]],64,16)      ; counts
	  a5[k].var  = reform(devar[pkt[16:1039]],64,16)      ; variance

	endelse

  end
  
  if (n_A5 gt 0L) then begin
    indx = where(a5.addr ne -1L, n_A5)
    if (n_A5 gt 0L) then a5 = temporary(a5[indx]) else a5 = 0
  endif

; Fast Housekeeping (APID A6)

  for k=0L,(n_A6 - 1L) do begin
    n = ptr_A6[k]
    head = long(tlm[lindgen(17) + n])                   ; spacecraft header
    pklen = 7L + head[5] + 256L*head[4]
    i = n + 11L                                         ; first index of packet
    j = (i + 6L + head[16] + 256L*head[15]) < lastbyte  ; last index of packet

	pkt = mav_pfdpu_part_decompress_data2(tlm[i:j])    ; is fhsk ever compressed?
	plen = n_elements(pkt)

	if (plen ne 1808) then begin
	  print,"Bad A6 packet: ",n,format='(a,Z)'

	  bad_str.addr = n
	  m = (plen < maxlen) - 1L
	  bad_str.dump[0L:m] = pkt[0L:m]

	  bad_str.apid = 'A6'X
	  bad_str.npkt = pkt[3]
	  bad_str.plen = plen

	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      bad_str.met = clock + subsecs
	  bad_str.time = mvn_spc_met_to_unixtime(bad_str.met,correct=dflg)

	  badpkt = [temporary(badpkt), bad_str]

	endif else begin

	  a6[k].addr = n
	  a6[k].npkt = pkt[3]
			   
	  tb = long(pkt[6:11])
	  clock = double(tb[3] + 256L*(tb[2] + 256L*(tb[1] + 256L*tb[0])))
	  subsecs = double(tb[5] + 256L*tb[4])/65536D

      a6[k].met  = clock + subsecs
	  a6[k].time = mvn_spc_met_to_unixtime(a6[k].met,correct=dflg)
	  a6[k].cflg = mvn_swe_getbits(pkt[12],7)

	  msb = 2L*lindgen(224*4) + 16L
	  lsb = msb + 1L
	  ahsk = float(fix(pkt[msb])*256 + fix(pkt[lsb]))

      for ch=0,3 do begin
        mux = mvn_swe_getbits(pkt[ch+12],[4,0])
        value = ahsk[(ch*224):(ch*224)+223]*swe_v[mux]
        if (mux eq 1) then value += 40.  ; MCPHV pull-down resistor
        if ((mux eq 0) or (mux eq 9) or (mux eq 16)) then begin
          T = swe_t[order] & for i=(order-1),0,-1 do T = swe_t[i] + T*value
          value = T
        endif
        a6[k].mux[ch] = mux
        a6[k].name[ch] = swe_hsk_names[mux]
        a6[k].value[*,ch] = value
      endfor

	endelse

  end
  
  if (n_A6 gt 0L) then begin
    indx = where(a6.addr ne -1L, n_A6)
    if (n_A6 gt 0L) then a6 = temporary(a6[indx]) else a6 = 0
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
      if (n_23 gt 0L) then pfp_hsk = temporary(pfp_hsk[jndx]) else pfp_hsk = 0
    endif
    if (tflg) then begin
      if (n_23 eq 0L) then begin
        print,"No PFP HSK packets within TRANGE."
        pfp_hsk = 0
      endif else begin
        indx = where((pfp_hsk.time ge tstart) and (pfp_hsk.time le tstop), n_23)
        pfp_hsk = temporary(pfp_hsk[indx])
      endelse
    endif
  endif

  if (n_28 gt 0L) then begin
    indx = where(swe_hsk.time lt t0, count, complement=jndx, ncomp=n_28)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = swe_hsk[indx[i]].addr
        print,"Zero MET in HSK: ",n,format='(a,Z)'
      endfor
      if (n_28 gt 0L) then swe_hsk = temporary(swe_hsk[jndx]) else swe_hsk = 0
    endif
    if (tflg) then begin
      if (n_28 eq 0L) then begin
        print,"No HSK packets within TRANGE."
        swe_hsk = 0
      endif else begin
        indx = where((swe_hsk.time ge tstart) and (swe_hsk.time le tstop), n_28)
        swe_hsk = temporary(swe_hsk[indx])
      endelse
    endif
  endif

  if (n_A0 gt 0L) then begin
    indx = where(a0.time lt t0, count, complement=jndx, ncomp=n_A0)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = a0[indx[i]].addr
        print,"Zero MET in A0: ",n,format='(a,Z)'
      endfor
      if (n_A0 gt 0L) then a0 = temporary(a0[jndx]) else a0 = 0
    endif
    if (tflg) then begin
      if (n_A0 eq 0L) then begin
        print,"No A0 packets within TRANGE."
        a0 = 0
      endif else begin
        indx = where((a0.time ge tstart) and (a0.time le tstop), n_A0)
        a0 = temporary(a0[indx])
      endelse
    endif
  endif

  if (n_A1 gt 0L) then begin
    indx = where(a1.time lt t0, count, complement=jndx, ncomp=n_A1)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = a1[indx[i]].addr
        print,"Zero MET in A1: ",n,format='(a,Z)'
      endfor
      if (n_A1 gt 0L) then a1 = temporary(a1[jndx]) else a1 = 0
    endif
    if (tflg) then begin
      indx = where((a1.time ge tstart) and (a1.time le tstop), n_A1)
      if (n_A1 eq 0L) then begin
        print,"No A1 packets within TRANGE."
        a1 = 0
      endif else a1 = temporary(a1[indx])
    endif
  endif

  if (n_A2 gt 0L) then begin
    indx = where(a2.time lt t0, count, complement=jndx, ncomp=n_A2)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = a2[indx[i]].addr
        print,"Zero MET in A2: ",n,format='(a,Z)'
      endfor
      if (n_A2 gt 0L) then a2 = temporary(a2[jndx]) else a2 = 0
    endif
    if (tflg) then begin
      if (n_A2 eq 0L) then begin
        print,"No A2 packets within TRANGE."
        a2 = 0
      endif else begin
        indx = where((a2.time ge tstart) and (a2.time le tstop), n_A2)
        a2 = temporary(a2[indx])
      endelse
    endif
  endif

  if (n_A3 gt 0L) then begin
    indx = where(a3.time lt t0, count, complement=jndx, ncomp=n_A3)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = a3[indx[i]].addr
        print,"Zero MET in A3: ",n,format='(a,Z)'
      endfor
      if (n_A3 gt 0L) then a3 = temporary(a3[jndx]) else a3 = 0
    endif
    if (tflg) then begin
      if (n_A3 eq 0L) then begin
        print,"No A3 packets within TRANGE."
        a3 = 0
      endif else begin
        indx = where((a3.time ge tstart) and (a3.time le tstop), n_A3)
        a3 = temporary(a3[indx])
      endelse
    endif
  endif

  if (n_A4 gt 0L) then begin
    indx = where(a4.time lt t0, count, complement=jndx, ncomp=n_A4)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = a4[indx[i]].addr
        print,"Zero MET in A4: ",n,format='(a,Z)'
      endfor
      if (n_A4 gt 0L) then a4 = temporary(a4[jndx]) else a4 = 0
    endif
    if (tflg) then begin
      if (n_A4 eq 0L) then begin
        print,"No A4 packets within TRANGE."
        a4 = 0
      endif else begin
        indx = where((a4.time ge tstart) and (a4.time le tstop), n_A4)
        a4 = temporary(a4[indx])
      endelse
    endif
  endif

  if (n_A5 gt 0L) then begin
    indx = where(a5.time lt t0, count, complement=jndx, ncomp=n_A5)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = a5[indx[i]].addr
        print,"Zero MET in A5: ",n,format='(a,Z)'
      endfor
      if (n_A5 gt 0L) then a5 = temporary(a5[jndx]) else a5 = 0
    endif
    if (tflg) then begin
      if (n_A5 eq 0L) then begin
        print,"No A5 packets within TRANGE."
        a5 = 0
      endif else begin
        indx = where((a5.time ge tstart) and (a5.time le tstop), n_A5)
        a5 = temporary(a5[indx])
      endelse
    endif
  endif

  if (n_A6 gt 0L) then begin
    indx = where(a6.time lt t0, count, complement=jndx, ncomp=n_A6)
    if (count gt 0L) then begin
      for i=0,(count-1) do begin
        n = a6[indx[i]].addr
        print,"Zero MET in A6: ",n,format='(a,Z)'
      endfor
      if (n_A6 gt 0L) then a6 = temporary(a6[jndx]) else a6 = 0
    endif
    if (tflg) then begin
      if (n_A6 eq 0L) then begin
        print,"No A6 packets within TRANGE."
        a6 = 0
      endif else begin
        indx = where((a6.time ge tstart) and (a6.time le tstop), n_A6)
        a6 = temporary(a6[indx])
      endelse
    endif
  endif

; Change definition of frame counter (e0) in 3D packets for group
; parameter of 1.  I want e0 to always increment by 1.
;
;     Group      E0 (FSW)      E0 (IDL)
;    -----------------------------------
;       0        0,1,2,3       0,1,2,3
;       1        0,2           0,1        <-- new definition
;       2        0             0
;    -----------------------------------

  if (n_A0 gt 0L) then begin
    indx = where(a0.group eq 1, count)
    if (count gt 0L) then a0[indx].e0 = a0[indx].e0/2B
  endif

  if (n_A1 gt 0L) then begin
    indx = where(a1.group eq 1, count)
    if (count gt 0L) then a1[indx].e0 = a1[indx].e0/2B
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
    if (size(a0_s,/type) eq 8) then begin
      if (size(a0,/type) eq 8) then a0 = [temporary(a0_s), temporary(a0)] $
                               else a0 = temporary(a0_s)
    endif
    if (size(a1_s,/type) eq 8) then begin
      if (size(a1,/type) eq 8) then a1 = [temporary(a1_s), temporary(a1)] $
                               else a1 = temporary(a1_s)
    endif
    if (size(a2_s,/type) eq 8) then begin
      if (size(a2,/type) eq 8) then a2 = [temporary(a2_s), temporary(a2)] $
                               else a2 = temporary(a2_s)
    endif
    if (size(a3_s,/type) eq 8) then begin
      if (size(a3,/type) eq 8) then a3 = [temporary(a3_s), temporary(a3)] $
                               else a3 = temporary(a3_s)
    endif
    if (size(a4_s,/type) eq 8) then begin
      if (size(a4,/type) eq 8) then a4 = [temporary(a4_s), temporary(a4)] $
                               else a4 = temporary(a4_s)
    endif
    if (size(a5_s,/type) eq 8) then begin
      if (size(a5,/type) eq 8) then a5 = [temporary(a5_s), temporary(a5)] $
                               else a5 = temporary(a5_s)
    endif
    if (size(a6_s,/type) eq 8) then begin
      if (size(a6,/type) eq 8) then a6 = [temporary(a6_s), temporary(a6)] $
                               else a6 = temporary(a6_s)
    endif
  endif

  return

end
