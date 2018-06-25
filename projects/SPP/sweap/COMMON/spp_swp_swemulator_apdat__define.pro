function spp_swp_swemulator_apdat::decom , ccsds, source_dict=source_dict
  ccsds_data = spp_swp_ccsds_data(ccsds)
  if source_dict.haskey('ptp_header') then ptp_header = source_dict.ptp_header
  
  if ccsds.time gt 1.76e9 then  ccsds.time -= 315576000   ; fix error in timing
  if ccsds.pkt_size ne 34 then begin
    dprint,dlevel=3, 'Size error',ccsds.pkt_size
   ; hexprint,ccsds_data
    return,!null
  endif

   buffer = ccsds_data[10:33]
   v = swap_endian( uint(buffer,0,12) ,/swap_if_little_endian)

   f0 = v[0]
   met = V[1] * 2d^16 + V[2]  + V[3]/(2d^16)
   time=spp_spc_met_to_unixtime(met+1527806500)   ; note that swemulator MET is incorrect
   ;print,time, round(ptp_header.ptp_time -MET),round(systime(1) -MET),'  ',time_string(ptp_header.ptp_time),'  ',time_string(time)
   if keyword_set(ptp_header) then delay_ptp = ptp_header.ptp_time - time else delay_ptp = !values.d_nan
   delay_ccsds = ccsds.time - time

   tns = { time:time,time_delay_ptp:delay_ptp,time_delay_ccsds:delay_ccsds, f0:f0,  MET:met, revnum:buffer[8],  power_flag: buffer[9], fifo_cntr:buffer[10], fifo_flag: buffer[11], $
     heater_flag: buffer[12], misc_flag:buffer[13], counts:v[7]  , parity_frame: v[8],  command:v[9],  rate_full:buffer[20], rate_target:buffer[21],  inst_power_flag:v[11]  }
  
;  hexprint,buffer
  ;printdat,tns
  
  return, tns 
end 
 
 

 
 
PRO spp_swp_swemulator_apdat__define
void = {spp_swp_swemulator_apdat, $
  inherits spp_gen_apdat $    ; superclass
  }
END



