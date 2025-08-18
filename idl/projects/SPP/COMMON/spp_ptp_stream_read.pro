  ; $LastChangedBy: davin-mac $
  ; $LastChangedDate: 2018-05-28 15:52:35 -0700 (Mon, 28 May 2018) $
  ; $LastChangedRevision: 25286 $
  ; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_ptp_stream_read.pro $


pro spp_ptp_stream_read,buffer,info=info,no_sum=no_sum,verbose=verbose,dlevel=dlevel  ;,time=time
  
  dlevel = 3
  bsize= n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
  time = info.time_received
  message,/info,'possible obsolete routine'
  
  common spp_ptp_stream_read_com,last_time,total_bytes,rate_sm
  
  if ~keyword_set(no_sum) then begin
    if keyword_set(last_time) then begin
      dt = time - last_time
      len = n_elements(buffer)
      total_bytes += len
      if dt gt .1 then begin
        rate = total_bytes/dt
        store_data,'PTP_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
        total_bytes =0
        last_time = time
      endif
    endif else begin
      last_time = time
      total_bytes = 0
    endelse    
  endif


  ;; Handle remainder of buffer from previous call
  if n_elements( *info.buffer_ptr ) ne 0 then begin
     remainder =  *info.buffer_ptr
     dprint,dlevel=dlevel,'Using ',strtrim(n_elements(*info.buffer_ptr),2),' remainder bytes from previous call'
     dprint,dlevel=dlevel+2,/phelp, remainder
     *info.buffer_ptr = !null
     if bsize gt 0 then  spp_ptp_stream_read, [remainder,buffer],info=info,/no_sum
     return
  endif
  
  p=0L
  nbad = 0
  badbuffer = bytarr(100000)
  while p lt bsize do begin
    
      if p gt bsize-17 then begin
        dprint,dlevel=dlevel,'Buffer is too small. Saving ', n_elements(buffer)-p,' bytes for next call.'
        *info.buffer_ptr = buffer[p:*]    ;; Store remainder of buffer to be used on the next call to this procedure
        return
      endif
      ptphdr   = buffer[p:p+16]
      ptp_size =  swap_endian( uint(ptphdr,0) ,  /swap_if_little_endian)
      if ptp_size le 17 then begin
        dprint,dlevel=dlevel+1,'PTP pkt has invalid size.  Resyncing...'
        p += 1
        badbuffer[nbad++] = ptphdr[0]
        continue
      endif
      ptp_code = ptphdr[2]
      if ptp_code ne 3  then begin
        dprint,dlevel=dlevel+1,'PTP pkt has invalid code: ',ptp_code,' Resyncing...'
        p += 1
        badbuffer[nbad++] = ptphdr[0]
        continue
      endif
      ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))
      if ptp_scid ne '00bb'x  then begin
        dprint,dlevel=dlevel+1,'PTP pkt has invalid spacecraft ID: ',ptp_scid,' Resyncing...'
        p += 1
        badbuffer[nbad++] = ptphdr[0]
        continue
      endif
      days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
      ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
      us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
      utime = (days-4383L) * 86400L + ms/1000d
      if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
      ;      if keyword_set(time) then dt = utime-time  else dt = 0
      source   =    ptphdr[13]
      spare    =    ptphdr[14]
      path  = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
      ptp_header ={ ptp_time:utime, ptp_scid: ptp_scid, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size}
      if nbad ne 0 then begin
        dprint,dlevel=dlevel,'Skipped ',nbad,' bytes to resync stream.'
        if debug(dlevel+1) then hexprint,badbuffer[0:nbad-1]
      endif
      if p+ptp_size gt bsize then begin   ;; Buffer doesn't have complete pkt.
        dprint,dlevel=dlevel,'Buffer has incomplete packet. Saving ', n_elements(buffer)-p,' bytes for next call.'
        *info.buffer_ptr = buffer[p:*]  ;; Store remainder of buffer to be used on the next call to this procedure
        return
      endif
      spp_ccsds_pkt_handler, buffer[p+17:p+ptp_size-1],ptp_header = ptp_header
      p += ptp_size
  endwhile

  if p ne bsize then dprint,dlevel=1,'Buffer incomplete',p,ptp_size,bsize
  return
end
