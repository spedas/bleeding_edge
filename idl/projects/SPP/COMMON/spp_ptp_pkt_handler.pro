


;function spp_sweap_therm_temp,dval,parameter=p
;  if not keyword_set (p) then begin
;;    p = {func:'mvn_sep_therm_temp2',R1:10000d, xmax:1023d, Rv:1d8, thm:thermistor_temp()}
;     p = {func:'spp_sweap_therm_temp',R1:10000d, xmax:1023d, Rv:1d7, thm:'thermistor_resistance_ysi4908'}
;  endif
;
;  if n_params() eq 0 then return,p
;
;;print,dval
;  x = dval/p.xmax
;  rt = p.r1*(x/(1-x*(1+p.R1/p.Rv)))
;  tc = thermistor_resistance_ysi4908(rt,/inverse)
; ; print,dval,x,rt,tc
;  return,float(tc)
;end


;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10, 2.69E-06,  -2.33E-02, 9.33E+01]


;function spp_swp_int4_decom,buffer,n
;   return,   swap_endian(/swap_if_little_endian,  long(buffer,n) )
;end







function spp_log_message_decom,ccsds, ptp_header=ptp_header, apdat=apdat
;  printdat,ccsds
;  time=ccsds.time
;  printdat,ptp_header
;  hexprint,ccsds.data
  time = ptp_header.ptp_time
  msg = string(ccsds.data[10:*])
  dprint,dlevel=2,time_string(time)+  ' "'+msg+'"'
  str={time:time,seq:ccsds.seq_cntr,size:ccsds.size,msg:msg}
  return,str
end


  
  
pro spp_ptp_pkt_handler,buffer,time=time,size=ptp_size

message, 'This routine is now deprecated'

  if n_elements(buffer) le 2 then begin
    dprint,'buffer too small!'
    return
  endif
;  printdat,bufferdprint
  ptp_size = swap_endian( uint(buffer,0) ,/swap_if_little_endian)   ; first two bytes provide the size
  if ptp_size ne n_elements(buffer) then begin
    dprint,dlevel=1,time_string(time,/local_time),' PTP size error- size is ',ptp_size
;    hexprint,buffer
;    savetomain,buffer,time
;    stop
    return
  endif
  ptp_code = buffer[2]
  if ptp_code eq 0 then begin
    dprint,'End of Transmission Code'
    printdat,buffer,/hex
;    savetomain,buffer
    return
  endif
  if ptp_code eq 'ff'x then begin
    dprint,'PTP Message ',ptp_size
    dprint,string(buffer[3:*])
    return
  endif
  if ptp_code ne 3 then begin
    dprint,'Unknown PTP code: ',ptp_code
    return
  endif
  ga   = buffer[3:16]
  sc_id = swap_endian(/swap_if_little_endian, uint(ga,0))   
  days  = swap_endian(/swap_if_little_endian, uint(ga,2))
  ms    = swap_endian(/swap_if_little_endian, ulong(ga,4))
  us    = swap_endian(/swap_if_little_endian, uint(ga,8))
  source   =    ga[10]
  spare    =    ga[11]
  path  = swap_endian(/swap_if_little_endian, uint(ga,12))
  utime = (days-4383L) * 86400L + ms/1000d 
  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
  if keyword_set(time) then dt = utime-time  else dt = 0
;  dprint,dlevel=4,time_string(utime,prec=3),ptp_size,sc_id,days,ms,us,source,path,dt,format='(a,i6," x",Z04,i6,i9,i6," x",Z02," x",Z04,f10.2)'
  if ptp_size le 17 then begin
    dprint,dlevel=2,'PTP size error - not enough bytes: '+strtrim(ptp_size,2)+ ' '+time_string(utime) ;,dwait=120
    if debug(2) then hexprint,buffer
    return
  endif
  ptp_header ={ ptp_time:utime, ptp_scid: sc_id, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size }
  if sc_id ne 'BB'x then begin
    dprint,dlevel=2,'Unknown SC_ID: '+string(sc_id)
    hexprint,buffer
  endif
  if debug(4) then begin
    dprint,dlevel=2,'ptp_size=',ptp_size
;    printdat,/hex,buffer
    hexprint,buffer    
  endif
  spp_ccsds_pkt_handler, buffer[17:*],ptp_header = ptp_header
 ; printdat,time_string(ptp_header.ptp_time)
  return
end



