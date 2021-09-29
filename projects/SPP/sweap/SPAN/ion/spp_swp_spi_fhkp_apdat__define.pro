;; Fast Housekeeping Data as of SPAN-I FPGA rev #22, 3/10/2015
;; 1. 16 CCSDS header bytes (should be 10?)
;; 2. 512 ADC values, each 2 bytes

FUNCTION spp_swp_spi_fhkp_apdat::decom, ccsds, source_dict=source_dict
   
   ;; Check Error #1
   if n_params() eq 0 then begin
      dprint,'Not working yet.'
      return,!null
   endif

   ccsds_data = spp_swp_ccsds_data(ccsds)
   b = ccsds_data
   nb = n_elements(b)
   if nb ne (512*2+16) then begin
      dprint,dlevel=1,"Incorrect packet size"
      return,0
   endif
   data = swap_endian(/swap_if_little_endian,  uint(b,16,512))
  
   ;; The data is sorted LSB 16 bits followed 
   ;; by MSB 16 bits. Therefore, we need to
   ;; switch LSB and MSB.
   ;;ind = indgen(256)*2
   ;;ind = reform(transpose([[ind+1],[ind]]),512)
   ;;data = data[ind]

   ;; Plot data (before and after)
   plot = 0
   if keyword_set(plot) and $
    total(data) ne 0 then begin
      !P.MULTI = [0,0,2]
      xx = indgen(512)
      plot, xx,data, yst=1, yr=minmax(data)
      plot, xx,data, /ylog,yst=1,yr=minmax(data)
      !P.MULTI = 0
   endif

   ;; New York Second
   ;; time = ccsds.time + (0.87*findgen(512)/512.)

   spai = { $
          time:       ccsds.time,$
          met:        ccsds.met,$
          ;; delay_time: ptp_header.ptp_time - ccsds.time, $
          seqn:       ccsds.seqn, $
          ;; 16 bits x offset 16 bytes x 512 values
          ADC:        data $
          }

   IF debug(5) THEN printdat,spai,/hex
   return, spai

END


PRO spp_swp_spi_fhkp_apdat__define
   void = {spp_swp_spi_fhkp_apdat, $
           inherits spp_gen_apdat, $ ; superclass
           flag: 0  $
          }
END
