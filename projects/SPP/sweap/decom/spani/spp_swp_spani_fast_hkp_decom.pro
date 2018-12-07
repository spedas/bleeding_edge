;;; Fast Housekeeping Data as of SPAN-I FPGA rev #22, 3/10/2015

function spp_swp_spani_fast_hkp_decom,ccsds,ptp_header=ptp_header,apdat=apdat,plot=plot, source_dict=source_dict 

  ;;-----------------------------------------
  ;; 1. 16 CCSDS header bytes (should be 10?)
  ;; 2. 512 ADC values, each 2 bytes
  

  
  ccsds_data = spp_swp_ccsds_data(ccsds)
  b = ccsds_data
  nb = n_elements(b)
  if nb ne (512*2+16) then begin
    dprint,dlevel=1,"Incorrect packet size"
    return,0
  endif
  data = swap_endian(/swap_if_little_endian,  uint(b,16,512))
  
  
  ;;-----------------------------------------
  ;; The data is sorted LSB 16 bits followed 
  ;; by MSB 16 bits. Therefore, we need to
  ;; switch LSB and MSB.
  ;ind = indgen(256)*2
  ;ind = reform(transpose([[ind+1],[ind]]),512)
  ;data = data[ind]


  ;;-----------------------------------------
  ;; Plot data (before and after)
  plot = 0
  if keyword_set(plot) then begin
     !P.MULTI = [0,0,2]
     xx = indgen(512)
     plot, xx,data
     ;oplot,xx,data, color=250
     plot, xx,data, /ylog,yst=1,yr=[1,max(data) > 10]
     ;oplot,xx,data, color=250
     !P.MULTI = 0
  endif

  ;; New York Second
  times = ccsds.time + (0.87*findgen(512)/512.)
  time = ccsds.time


  fhk = { $
        ;time:       ptp_header.ptp_time, $
        time:       time, $
  ;      times:      times, $
        met:        ccsds.met,  $
        delay_time:  0d, $   needs fixing! ;  ptp_header.ptp_time - ccsds.time, $
        seqn:   ccsds.seqn, $

        ;; 16 bits x offset 16 bytes x 512 values
        ADC:        data $

        }
;printdat,fhk
;return,0   ; cluge to prevent error
  return,fhk

end


