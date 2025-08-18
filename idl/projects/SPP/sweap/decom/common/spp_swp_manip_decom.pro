; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2021-06-08 14:37:19 -0700 (Tue, 08 Jun 2021) $
; $LastChangedRevision: 30033 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/common/spp_swp_manip_decom.pro $

function spp_swp_manip_decom,ccsds, source_dict=source_dict  ;ptp_header=ptp_header   ,apdat=apdat

  ;; From Tony's e-mail, the buffer should
  ;; be...
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

  ;print, b
  
;  common spp_swp_Manip_decom_common, last_time
;  time = ptp_header.ptp_time
;  if ~keyword_set(last_time) then last_time = time
;  time_delta = time-last_time
;  last_time = time
;  ccsds.gap = time_delta lt 0 || time_delta gt 3
  
;  dprint,dlevel=5,format='("Manip ",i5," 0x", Z03, " packets ",i5," ",a)',  ccsds.seqn_delta,apdat.apid,ccsds.seqn,time_string(ccsds.time,prec=3)

;  dprint,time_delta
  ;dprint,spp_swp_word_decom(b, 17)
  ;ccsds.gap=ccsds.tim
 ; printdat,time_string(ccsds.time);  -1.2623e9
;  dprint,dlevel=2,n_elements(b)
  ;if n_elements(b) lt 107 then return,0
  
  ccsds.gap = abs(ccsds.time_delta) gt 4
;  if 0 then begin ; old method.
;    manip = {$;time:       ptp_header.ptp_time, $
;            time: ccsds.time, $
;            met:        ccsds.met,  $
;  ;          delay_time: ptp_header.ptp_time - ccsds.time, $
;            seqn:   ccsds.seqn, $
;  ;          sync:       spp_swp_word_decom(b,10), $      ;; ,,, 16
;  ;          length:     spp_swp_word_decom(b,12), $      ;; ,,, 16
;  ;          mlinmove:   b[14],$                          ;; ,,,  8
;  ;          mlincoast:  b[15],$                          ;; ,,,  8
;  ;          mlinerror:  b[16],$                          ;; ,,,  8
;            mov_flag:  total(/preserve,(b[[14,15,16,21,22,23,28,29,30]] * [1,2,4,8,16,32,64,128,256])), $
;            lin_flag:  total(/preserve,(b[14:16] ne 0) * byte([1,2,4]))  , $
;            lin_pos:    spp_swp_float_decom(b,17),$      ;; ,,, 32
;  ;          myawmove:   b[21],$                          ;; ,,,  8
;  ;          myawcoast:  b[22],$                          ;; ,,,  8
;  ;          myawerror:  b[23],$                          ;; ,,,  8
;            yaw_flag: total(/preserve,(b[21:23] ne 0) * byte([1,2,4]))  , $
;            yaw_pos:    spp_swp_float_decom(b,24),$      ;; ,,, 32
;  ;         mrotmove:   b[28],$                          ;; ,,,  8
;  ;         mrotcoast:  b[29],$                          ;; ,,,  8
;  ;         mroterror:  b[30],$                          ;; ,,,  8
;            rot_flag: total(/preserve,(b[28:30] ne 0) * byte([1,2,4]))  , $
;            rot_pos:    spp_swp_float_decom(b,31),$      ;; ,,, 32
;  ;          daqDIOLED0: b[35],$                         ;; ,,,  8
;  ;          daqDIOLED1: b[36],$                         ;; ,,,  8
;  ;          daqDIOLED2: b[37],$                         ;; ,,,  8
;  ;          daqDIOLED3: b[38],$                         ;; ,,,  8
;  ;          daqDIOLED4: b[39],$                         ;; ,,,  8
;  ;          daqDIOLED5: b[40],$                         ;; ,,,  8
;  ;          daqDIOLED6: b[41],$                         ;; ,,,  8
;  ;          daqDIOLED7: b[42],$                         ;; ,,,  8
;  ;          daqAO0:     spp_swp_float_decom(b,43),$                     ;; ,,, 32
;  ;          daqAO1:     spp_swp_float_decom(b,47),$                     ;; ,,, 32
;  ;          daqPulseT:  spp_swp_float_decom(b,51),$                     ;; ,,, 32
;  ;          daqAI0:     spp_swp_float_decom(b,55),$                     ;; ,,, 32
;  ;          daqAI1:     spp_swp_float_decom(b,59),$                     ;; ,,, 32
;  ;          daqAI2:     spp_swp_float_decom(b,63),$                     ;; ,,, 32
;  ;          daqAI3:     spp_swp_float_decom(b,67),$                            ;; ,,, 32
;  ;          daqAI4:     spp_swp_float_decom(b,71),$                            ;; ,,, 32
;  ;          daqAI5:     spp_swp_float_decom(b,75),$                            ;; ,,, 32
;  ;          daqAI6:     spp_swp_float_decom(b,79),$                            ;; ,,, 32
;  ;          daqAI7:     spp_swp_float_decom(b,83),$                            ;; ,,, 32
;  ;          daqAI8:     spp_swp_float_decom(b,87),$                            ;; ,,, 32
;  ;          daqAI9:     spp_swp_float_decom(b,91),$                            ;; ,,, 32
;  ;          daqAI10:    spp_swp_float_decom(b,95),$                            ;; ,,, 32
;  ;           daqAI11:    spp_swp_float_decom(b,99),$                            ;; ,,, 32
;  ;          daqAI12:    spp_swp_float_decom(b,103),$
;            gap:ccsds.gap}
;            ;daqAI13:    spp_swp_float_decom(b,107),$    ;; ,,, 32
;            ;daqAI14:    spp_swp_float_decom(b,111),$    ;; ,,, 32
;            ;daqAI15:    spp_swp_float_decom(b,115)}     ;; ,,, 32
;   endif
   
    manip = {$;time:       ptp_header.ptp_time, $
            time:         ccsds.time + 7.* 3600., $
            met:          ccsds.met,  $
            ;             delay_time: ptp_header.ptp_time - ccsds.time, $
            seqn:         ccsds.seqn, $
            ;             sync:       spp_swp_word_decom(b,10), $      
            ;             length:     spp_swp_word_decom(b,12), $      
            lincnts:      swap_endian(/swap_if_big_endian, ishft(long(b[14]), 24) +  ishft(long(b[15]),16) + $
                                                           ishft(long(b[16]), 8) + long(b[17])) / 12598.432, $
            yawcnts:      swap_endian(/swap_if_big_endian, ishft(long(b[18]), 24) +  ishft(long(b[19]),16) + $
                                                           ishft(long(b[20]), 8) + long(b[21])) /111.11111, $                    
            rotcnts:      swap_endian(/swap_if_big_endian, ishft(long(b[22]), 24) +  ishft(long(b[23]),16) +$
                                                           ishft(long(b[24]), 8) + long(b[25])) / 55.60, $                     
            linlowlim:    total(b[26:27]), $
            linhilim:     total(b[28:29]), $
            yawlowlim:    total(b[30:31]), $
            yawhilim:     total(b[32:33]), $
            rotlowlim:    total(b[34:35]), $
            rothilim:     total(b[36:37]), $
            linpwm:       total(b[38:39]), $
            linduty:      total(b[40:41]), $
            yawpwm:       total(b[42:43]), $
            yawduty:      total(b[44:45]), $
            rotpwm:       total(b[46:47]), $
            rotduty:      total(b[48:49]), $
            gap:ccsds.gap} 
  
  return,manip

end

