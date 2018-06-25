; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-06-18 06:17:08 -0700 (Mon, 18 Jun 2018) $
; $LastChangedRevision: 25364 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/common/spp_power_supply_decom.pro $


function spp_power_supply_decom,ccsds, source_dict=source_dict  ;ptp_header=ptp_header,apdat=apdat

  if n_params() eq 0 then begin
    dprint,'Not working yet.',dlevel=2
    return,!null
  endif

  ;str = create_struct(ptp_header,ccsds)
  str = 0
  ;dprint,format="('Generic routine for',Z04)",ccsds.apid
  size = ccsds.pkt_size
  if size lt 22 then begin
    dprint,'power supply decom error'
    return,0
  endif
  ccsds_data = spp_swp_ccsds_data(ccsds)
;  printdat,ccsds
  b = ccsds_data
  if debug(4) then begin
     dprint,dlevel=3,'Power Supply',ccsds.pkt_size, n_elements(ccsds_data),'  ',time_string(ccsds.time,/local)
 ;    hexprint,ccsds_data
  endif
  case size of
     60: begin   ;  HVPS
;        b = [ b , byte( ['80'x,'00'x] ) ] ;; correct error of truncation of data array
;        hexprint,b
        ;dprint,spp_swp_float_decom(b,4),spp_swp_float_decom(b,8)
        str= { time: ccsds.time,  $
;         time: ptp_header.ptp_time, $
               type: b[12],  $
               num:  b[13],   $
               poll: spp_swp_word_decom(b,14),  $
               name: string(b[16:16+14-1]),  $
               statuscode: b[30],  $
               output:  b[31],  $
               normalstatus:  b[32:32+8-1],  $
               Volts_setting: spp_swp_float_decom(b,40),  $
               Volts: abs(spp_swp_float_decom(b,44)),  $
               current: spp_swp_float_decom(b,48) * 1e3,  $
               VLIM: spp_swp_float_decom(b,52), $
               clim: spp_swp_float_decom(b,56) *1e3, $
               gap: ccsds.gap}
        if debug(3) then begin
          dprint,dlevel=4,str,phelp=2
          dprint,dlevel=3,time_string(str.time),' ',str.current
        endif
     end  
     80: begin   ; Agilent PS
       str= { $
         time: ccsds.time,  $
 ;        time: ptp_header.ptp_time, $
         type: b[12],  $
         num:  b[13],   $
         poll: spp_swp_word_decom(b,14),  $
         name: string(b[16:16+14-1]),  $
         statuscode: b[30],  $
         output:  b[31],  $
         p25v_lim: spp_swp_float_decom(b,32), $
         p25i_lim: spp_swp_float_decom(b,36), $
         p25v    : spp_swp_float_decom(b,40), $
         p25i    : spp_swp_float_decom(b,44), $
         n25v_lim: spp_swp_float_decom(b,48), $
         n25i_lim: spp_swp_float_decom(b,52), $
         n25v    : spp_swp_float_decom(b,56), $
         n25i    : spp_swp_float_decom(b,60), $
         p6v_lim : spp_swp_float_decom(b,64), $
         p6i_lim : spp_swp_float_decom(b,68), $
         p6v     : spp_swp_float_decom(b,72), $
         p6i     : spp_swp_float_decom(b,76), $
         gap: ccsds.gap}
       if debug(5) then begin
         dprint,dlevel=3,'APS:',time_string(ccsds.time)
     ;    hexprint,b[12:*]  
         printdat,str     
       endif
     end
     else: dprint,'Unknown size: ',size
  endcase
  ;printdat,time_string(ptp_header.ptp_time,/local)
  ;printdat,str
  return,str
end

