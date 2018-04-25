function spp_log_msg_decom,ccsds, ptp_header=ptp_header, apdat=apdat,dlevel=dlevel

  ;printdat,ccsds
  ;time=ccsds.time
  ;printdat,ptp_header
  ;hexprint,ccsds.data

  if n_params() eq 0 then begin
    dprint,'Not working yet.',dlevel=2
    return,!null
  endif

;  dprint,ptp_header.ptp_time - ccsds.time,'  '+time_string(ptp_header.ptp_time),dlevel=4
  if keyword_set(ptp_header) then ccsds.time = ptp_header.ptp_time   ; Correct the time
  
  
  
  time = ptp_header.ptp_time
 ; time=ccsds.time
  ccsds_data = spp_swp_ccsds_data(ccsds)  
  msg = string(ccsds_data[10:*])
  dprint,dlevel=4,time_string(time)+  ' "'+msg+'"'
  str={time:time,seq:ccsds.seqn,size:ccsds.pkt_size,msg:msg}
  return,str

end
