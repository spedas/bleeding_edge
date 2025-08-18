; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2024-04-03 11:56:56 -0700 (Wed, 03 Apr 2024) $
; $LastChangedRevision: 32517 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/common/spp_swp_newmanip_decom.pro $

function spp_swp_newmanip_decom,ccsds, source_dict=source_dict  ;ptp_header=ptp_header   ,apdat=apdat


  ;; buffer_length = n_elements(buffer)
  ;; if buffer_length lt 12 then begin
  ;;    dprint,'Invalid buffer length:',buffer_length
  ;;    return, 0
  ;; endif


  ;;-------------------------------------
  ;; NOTES:
  ;; First 17 bytes are PTP header
  ;;


  if n_params() eq 0 then begin
    dprint,'Not working yet.',dlevel=2
    return,!null
  endif

  ;; New York Second
  time = ccsds.time + (0.87*findgen(512)/512.)

  b  = spp_swp_ccsds_data(ccsds)



  ccsds.gap = abs(ccsds.time_delta) gt 4

  manip = {$;time:       ptp_header.ptp_time, $
    time:         ccsds.time + 7.* 3600. - 7200., $ ; offset for difference between manip computer and gseos
    met:          ccsds.met,  $
    ;             delay_time: ptp_header.ptp_time - ccsds.time, $
    seqn:         ccsds.seqn, $
    ;             sync:       spp_swp_word_decom(b,10), $
    ;             length:     spp_swp_word_decom(b,12), $
    lincnts:      swap_endian(/swap_if_big_endian, ishft(long(b[14]), 24) +  ishft(long(b[15]), 16) + $
                              ishft(long(b[16]), 8) + long(b[17])) *0.00000326571428571426, $
    ;;/ ((25400/0.03) /15.24) / 5.51182, $; /12598.432, $ old units conversion
    yawcnts:      swap_endian(/swap_if_big_endian, ishft(long(b[18]), 24) +  ishft(long(b[19]), 16) + $
    ishft(long(b[20]), 8) + long(b[21])) * (0.29/3600.), $; /111.11111, $ old units conversion in comment
    rotcnts:      swap_endian(/swap_if_big_endian, ishft(long(b[22]), 24) +  ishft(long(b[23]), 16) + $
    ishft(long(b[24]), 8) + long(b[25]))  * (0.29/3600.), $; /55.60, $ old units conversion in comment
;    linlowlim:    total(b[26:27]), $
;    linhilim:     total(b[28:29]), $
;    yawlowlim:    total(b[30:31]), $
;    yawhilim:     total(b[32:33]), $
;    rotlowlim:    total(b[34:35]), $
;    rothilim:     total(b[36:37]), $
;    linpwm:       total(b[38:39]), $
;    linduty:      total(b[40:41]), $
;    yawpwm:       total(b[42:43]), $
;    yawduty:      total(b[44:45]), $
;    rotpwm:       total(b[46:47]), $
;    rotduty:      total(b[48:49]), $
    gap:ccsds.gap}

  return,manip

end

