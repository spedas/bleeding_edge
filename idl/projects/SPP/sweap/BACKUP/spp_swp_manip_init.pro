
;function spp_swp_manip_decom,ccsds,ptp_header=ptp_header,apdat=apdat
;
;  str = create_struct(ptp_header,ccsds)  
;  ;dprint,format="('Generic routine for ',Z04)",ccsds.apid                                                                                              
;  stop
;  return,str
;
;end

;function spp_swp_manip_decom,ccsds,ptp_header=ptp_header,apdat=apdat

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
  ;; NO, first 10 bytes are PTP header
  ;;
  b = ccsds.data
  
;  dprint,'hello'
  manip = { $
          time:       ptp_header.ptp_time, $
          met:        ccsds.met,  $
          delay_time: ptp_header.ptp_time - ccsds.time, $
          seq_cntr:   ccsds.seq_cntr, $

          sync:       spp_swp_word_decom(b,10), $      ;; ,,, 16
          length:     spp_swp_word_decom(b,12), $      ;; ,,, 16
          mlinmove:   b[14],$                          ;; ,,,  8
          mlincoast:  b[15],$                          ;; ,,,  8
          mlinerror:  b[16],$                          ;; ,,,  8
          mlinpos:    spp_swp_float_decom(b,17),$      ;; ,,, 32
          myawmove:   b[21],$                          ;; ,,,  8
          myawcoast:  b[22],$                          ;; ,,,  8
          myawerror:  b[23],$                          ;; ,,,  8
          myawpos:    spp_swp_float_decom(b,24),$      ;; ,,, 32
          mrotmove:   b[28],$                          ;; ,,,  8
          mrotcoast:  b[29],$                          ;; ,,,  8
          mroterror:  b[30],$                          ;; ,,,  8
          mrotpos:    spp_swp_float_decom(b,31),$      ;; ,,, 32
          daqDIOLED0: b[35],$                          ;; ,,,  8
          daqDIOLED1: b[36],$                          ;; ,,,  8
          daqDIOLED2: b[37],$                          ;; ,,,  8
          daqDIOLED3: b[38],$                          ;; ,,,  8
          daqDIOLED4: b[39],$                          ;; ,,,  8
          daqDIOLED5: b[40],$                          ;; ,,,  8
          daqDIOLED6: b[41],$                          ;; ,,,  8
          daqDIOLED7: b[42],$                          ;; ,,,  8
          daqAO0:     spp_swp_float_decom(b,43),$                     ;; ,,, 32
          daqAO1:     spp_swp_float_decom(b,47),$                     ;; ,,, 32
          daqPulseT:  spp_swp_float_decom(b,51),$                     ;; ,,, 32
          daqAI0:     spp_swp_float_decom(b,55),$                     ;; ,,, 32
          daqAI1:     spp_swp_float_decom(b,59),$                     ;; ,,, 32
          daqAI2:     spp_swp_float_decom(b,63),$                     ;; ,,, 32
          daqAI3:     spp_swp_float_decom(b,67),$                            ;; ,,, 32
          daqAI4:     spp_swp_float_decom(b,71),$                            ;; ,,, 32
          daqAI5:     spp_swp_float_decom(b,75),$                            ;; ,,, 32
          daqAI6:     spp_swp_float_decom(b,79),$                            ;; ,,, 32
          daqAI7:     spp_swp_float_decom(b,83),$                            ;; ,,, 32
          daqAI8:     spp_swp_float_decom(b,87),$                            ;; ,,, 32
          daqAI9:     spp_swp_float_decom(b,91),$                            ;; ,,, 32
          daqAI10:    spp_swp_float_decom(b,95),$                            ;; ,,, 32
          daqAI11:    spp_swp_float_decom(b,99),$                            ;; ,,, 32
          daqAI12:    spp_swp_float_decom(b,103)};,$                           ;; ,,, 32
          ;daqAI13:    spp_swp_float_decom(b,107),$                           ;; ,,, 32
          ;daqAI14:    spp_swp_float_decom(b,111),$                           ;; ,,, 32
          ;daqAI15:    spp_swp_float_decom(b,115)}                            ;; ,,, 32
  return,manip
end


pro spp_swp_manip_init

  spp_apid_data,'7c3'x,routine='spp_swp_manip_decom',tname='spp_manip_',tfields='*',name='SWEAP SPAN-I Manip',rt_tags='M???POS',save=1,/rt_flag

end



