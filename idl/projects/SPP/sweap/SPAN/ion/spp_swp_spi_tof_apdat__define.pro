;+
; $LastChangedBy: ali $
; $LastChangedDate: 2021-06-14 10:41:21 -0700 (Mon, 14 Jun 2021) $
; $LastChangedRevision: 30043 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_tof_apdat__define.pro $

; SPP_SWP_SPI_TOF_APDAT
;
; APID: 0x3BA
; Descritpion: SPAN-Ai TOF512 Package
; Size: 536 Bytes
;
;----------------------------------------------
; Byte  |   Bits   |        Data Value
;----------------------------------------------
;   0   | 00001aaa | ApID Upper Byte
;   1   | aaaaaaaa | ApID Lower Byte
;   2   | 11cccccc | Sequence Count Upper Byte
;   3   | cccccccc | Sequence Count Lower Byte
;   4   | LLLLLLLL | Message Length Upper Byte
;   5   | LLLLLLLL | Message Length Lower Byte
;   6   | MMMMMMMM | MET Byte 5
;   7   | MMMMMMMM | MET Byte 4
;   8   | MMMMMMMM | MET Byte 3
;   9   | MMMMMMMM | MET Byte 2
;  10   | ssssssss | MET Byte 1 [subseconds]
;  11   | ssssssss | s = MET subseconds
;       |          | x = Cycle Count LSBs
;       |          |     (sub NYS Indicator)
;  12   | LTCSNNNN | L = Log Compressed
;       |          | T = No Targeted Sweep
;       |          | C = Compress/Truncate TOF
;       |          | S = Summing
;       |          | N = 2^N Sum/Sample Period
;  13   | QQQQQQQQ | Spare
;  14   | mmmmmmmm | Mode ID Upper Byte
;  15   | mmmmmmmm | Mode ID Lower Byte
;  16   | FFFFFFFF | F0 Counter Upper Byte
;  17   | FFFFFFFF | F0 Counter Lower Byte
;  18   | AAtHDDDD | A = Attenuator State
;       |          | t = Test Pulser
;       |          | H = HV Enable
;       |          | D = HV Mode
;  19   | XXXXXXXX | X = Peak Count Step
;  20   | 000000fT | f = Full histogram
;       |          | T = Target Histogram
;  21   | NNNNCCCC | N = 2^N
;       |          | C = Channel
;  22   | XXXXXXXX | Maximum HV Step
;  23   | UUUUUUUU | Minimum HV Step
;
; 24 - 535
; --------
; Histogram data is 512 compressed bytes which
; are the sum of the number of counts for each of the 512
; possible time of flight measurements during the
; measurement period.  Each bin represents 406.9ps of time
; measurement if truncation compression is used.  The bins
; are not all the same width if log compression is used.
;
;-

FUNCTION spp_swp_spi_tof_apdat::decom, ccsds, source_dict=source_dict

  ;; Check keywords
  IF n_params() EQ 0 THEN BEGIN
    dprint,'Not working yet.',dlevel=2
    RETURN,!null
  ENDIF

  ;; Extract data from CCSDS
  ccsds_data = spp_swp_ccsds_data(ccsds)
  b = ccsds_data

  ;; Check Packet Size
  psize1 = 536   ;; correct size
  psize2 = 564   ;; corrupt size after decompression
  IF n_elements(b) NE psize1 AND $
    n_elements(b) NE psize2 THEN BEGIN
    dprint,dlevel=1, 'Size error ',ccsds.pkt_size,ccsds.apid
    return,0
  ENDIF

  ;; TOF Counts
  cnts = b[24:(511+24)]

  ;; Decompress TOF Counts
  cnts = float(reform(spp_swp_log_decomp(temporary(cnts),0)))

  ;; Fill Structure
  tof_str = {$
    time:         ccsds.time, $
    MET:          ccsds.met,  $
    apid:         ccsds.apid, $
    seqn:         ccsds.seqn,  $
    seqn_delta:   ccsds.seqn_delta,  $
    seqn_group:   ccsds.seqn_group,  $
    pkt_size:     ccsds.pkt_size,  $
    source_apid:  ccsds.source_apid,  $
    source_hash:  ccsds.source_hash,  $
    compr_ratio:  ccsds.compr_ratio,  $
    header_bytes:  b[0:23] , $
    full_hist:ishft(b[20] AND '11'b,-1),$
    targ_hist:b[20] AND '1'b,$
    accum:ishft(b[21],-4),$
    channel:b[21] AND '1111'b,$
    max_hv:b[22],$
    min_hv:b[23],$
    tof:cnts,$
    gap:ccsds.gap}

  RETURN, tof_str

END

PRO spp_swp_spi_tof_apdat__define

  void = {spp_swp_spi_tof_apdat,$
    ;; Superclass
    inherits spp_gen_apdat,$
    flag: 0 $
  }

END
