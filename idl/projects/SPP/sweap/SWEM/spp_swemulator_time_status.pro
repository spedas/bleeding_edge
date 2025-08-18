
function spp_swemulator_time_status,buffer   ;  decoms 12 Word time and status message from SWEMulator
  ddd=3
  v = swap_endian( uint(buffer,0,12+ddd) ,/swap_if_little_endian)
  f0 = v[3]
  met = V[4] * 2d^16 + V[5]  + V[6]/(2d^16)
  time=spp_spc_met_to_unixtime(met)

  ts = { time:time, f0:f0,  MET:met, revnum:buffer[8+6],  power_flag: buffer[9+6], fifo_cntr:buffer[10+6], fifo_flag: buffer[11+6], $
    sync: v[6+ddd], counts:v[7+ddd]  , parity_frame: v[8+ddd],  command:v[9+ddd],  telem_fifo_flag:v[10+ddd],  inst_power_flag:v[11+ddd]  }
  if debug(5) then begin
    dprint,phelp=4,dlevel=2,ts
    hexprint,v    
  endif
  return,ts
end



