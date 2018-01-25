;  This routine will read files that have the same format as that which is produced by the SWEMulator

pro spp_msg_file_read,files
  
;  common spp_msg_file_read, time_status
  t0 = systime(1)
  spp_swp_startup,rt_flag=0,save=1,/clear
  info = {buffer_ptr: ptr_new(/allocate_heap) , time_received:0d}


  for i=0,n_elements(files)-1 do begin
    file = files[i]
    file_open,'r',file,unit=lun,dlevel=4
    sizebuf = bytarr(6)
    fi = file_info(file)
    dprint,dlevel=1,'Reading file: '+file+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)
    while ~eof(lun) do begin
      point_lun,-lun,fp
      readu,lun,sizebuf
      msg_header = swap_endian( uint(sizebuf,0,3) ,/swap_if_little_endian)
      sync  = msg_header[0]
      code  = msg_header[1]
      psize = msg_header[2]*2
      if sync ne 'a829'x then begin
        hexprint,msg_header
        dprint,sync,code,psize,fp   ,  ' Sync not recognized'   
        point_lun,lun, fp+2
        continue
      endif

      if psize lt 12 then begin
        dprint,format="('Bad MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,file,fp
        hexprint,msg_header
;        continue
      endif
      if psize gt 2L^13 then begin
        dprint,format="('Large MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,file,fp
        hexprint,msg_header
      endif
      
      buffer = bytarr(psize)
      readu,lun,buffer
      
      info.time_received = systime(1)
      spp_msg_stream_read,[sizebuf,buffer] , info = info    ;,time=systime(1)    ; read only a single message and pass it on
      
if 0 then begin      
      w= where(buffer ne 0,nw)
      if code eq 'c1'x then begin
        time_status = spp_swemulator_time_status(buffer)
        dprint,dlevel=3,time_status
;        hexprint,buffer
;        v = swap_endian( uint(buffer,0,12) ,/swap_if_little_endian)
;        dprint,v
        continue
      endif

;      hexprint,buffer
      spp_msg_pkt_handler,[sizebuf,buffer]   ;,time=systime(1)   ;,size=ptp_size
      if nw lt 20000 then begin
        dprint,dlevel=1,code,psize,nw,fp
      endif
endif
    endwhile
    free_lun,lun
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  spp_apid_data,/finish,rt_flag=1
end


