;$LastChangedBy: davin-mac $
;$LastChangedDate: 2021-08-18 22:37:39 -0700 (Wed, 18 Aug 2021) $
;$LastChangedRevision: 30222 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_swemulator_apdat__define.pro $

function swfo_stis_swemulator_apdat::decom , ccsds, source_dict=source_dict
  ccsds_data = swfo_ccsds_data(ccsds)
  if source_dict.haskey('ptp_header') then ptp_header = source_dict.ptp_header

  if ccsds.pkt_size ne 34 then begin
    dprint,dlevel=3, 'Size error',ccsds.pkt_size
    ; hexprint,ccsds_data
    return,!null
  endif
  
  ;if self.test then printdat,ptp_header ,time_string(ptp_header.ptp_time)

  buffer = ccsds_data[10:33]
  v = swap_endian( uint(buffer,0,12) ,/swap_if_little_endian)

  f0 = v[0]
  met = V[1] * 2d^16 + V[2]  + V[3]/(2d^16)
  ;time=swfo_spc_met_to_unixtime(met+1527806500)   ; note that swemulator MET is incorrect
  time = ccsds.time
  ;print,time, round(ptp_header.ptp_time -MET),round(systime(1) -MET),'  ',time_string(ptp_header.ptp_time),'  ',time_string(time)
  if keyword_set(ptp_header) then delay_ptp = ptp_header.ptp_time - time else delay_ptp = !values.d_nan
  delay_ccsds = ccsds.time - time

  tns = { time:time,time_delay_ptp:delay_ptp,time_delay_ccsds:delay_ccsds, f0:f0,  MET:met, revnum:buffer[8],  power_flag: buffer[9], fifo_cntr:buffer[10], fifo_flag: buffer[11], $
    heater_flag: buffer[12], misc_flag:buffer[13], counts:v[7]  , parity_frame: v[8],  command:v[9],  rate_full:buffer[20], rate_target:buffer[21],  inst_power_flag:v[11]  }

  return, tns
end


PRO swfo_stis_swemulator_apdat__define
  void = {swfo_stis_swemulator_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
END

