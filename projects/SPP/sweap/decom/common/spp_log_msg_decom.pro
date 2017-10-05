function spp_log_msg_decom,ccsds, ptp_header=ptp_header, apdat=apdat

  ;printdat,ccsds
  ;time=ccsds.time
  ;printdat,ptp_header
  ;hexprint,ccsds.data

  if n_params() eq 0 then begin
    dprint,'Not working yet.',dlevel=2
    return,!null
  endif

  
  
  time = ptp_header.ptp_time
  ccsds_data = spp_swp_ccsds_data(ccsds)  
  msg = string(ccsds_data[10:*])
  dprint,dlevel=4,time_string(time)+  ' "'+msg+'"'
  str={time:time,seq:ccsds.seqn,size:ccsds.pkt_size,msg:msg}
  return,str

end
