

pro spp_msg_pkt_handler,buffer,time=time   
source = 0b
spare = 0b
ptp_scid = 0u
path =  0u
ptp_size = 0u
utime = time
  ptp_header ={ ptp_time:utime, ptp_scid: 0u, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size }
  spp_ccsds_pkt_handler,buffer,ptp_header = ptp_header;,error=error
  if keyword_set(error) then dprint,error
  return
end





pro spp_msg_stream_read,buffer, info=info  ;,time=time   ;,   fileunit=fileunit   ,ptr=ptr
  bsize= n_elements(buffer)
  time = info.time_received
  
  if n_elements( *info.buffer_ptr ) ne 0 then begin   ; Handle remainder of buffer from previous call
    remainder =  *info.buffer_ptr
    if debug(3) then begin
      dprint,dlevel=2,'Using remainder buffer from previous call'
      dprint,dlevel=2,/phelp, remainder
      hexprint,remainder,nbytes=32
    endif
    undefine , *info.buffer_ptr
    if bsize gt 0 then  spp_msg_stream_read, [remainder,buffer],info=info
    return
  endif

  if 0 && debug(3) then dprint,/phelp,time_string(time),buffer,dlevel=3
  
  ptr=0L
  while ptr lt bsize do begin
    if ptr gt bsize-6 then begin
      dprint,dlevel=0,'SWEMulator MSG stream size error ',ptr,bsize
      *info.buffer_ptr = buffer[ptr:*]                   ; store remainder of buffer to be used on the next call to this procedure
      return
    endif
    msg_header = swap_endian( uint(buffer,ptr,3) ,/swap_if_little_endian) 
    sync  = msg_header[0]
    code  = msg_header[1]
    psize = msg_header[2]*2
    
    if 0 then begin
      dprint,ptr,psize,bsize
      hexprint,msg_header
;    hexprint,buffer,nbytes=32
    endif
    
    if sync ne 'a829'x then begin
      dprint,format='(i,z,z,i,a)',ptr,sync,code,psize,dlevel=0,    ' Sync not recognized'
;      hexprint,buffer
      return
    endif

    if psize lt 12 then begin
      dprint,format="('Bad MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,'???',0
      break
    endif


    if ptr+6+psize gt bsize then begin
      dprint,dlevel=3,'Buffer has incomplete packet. Saving ',n_elements(buffer)-ptr,' bytes for next call.'
      *info.buffer_ptr = buffer[ptr:*]                   ; store remainder of buffer to be used on the next call to this procedure
      return
      break
    endif

    if debug(4) then begin
      dprint,format='(i,i,z,z,i)',ptr,bsize,sync,code,psize,dlevel=3
;      hexprint,buffer[ptr+6:ptr+6+psize-1] ;,nbytes=32
      hexprint,buffer[ptr:ptr+6+psize-1] ;,nbytes=32
    endif
    
    
    case code of
      'c1'x :begin
          time_status = spp_swemulator_time_status(buffer[ptr:ptr+6+psize-1])
          store_data,/append,'swemulator_',data=time_status,tagnames='*'
          if debug(3) then begin
            dprint,dlevel=2,'C1; psize:',psize
            hexprint,buffer[ptr:ptr+6+psize-1]
          endif
        end
      'c2'x : dprint,dlevel=2,"Can't deal with C2 messages now'
      'c3'x :begin
        spp_msg_pkt_handler,buffer[ptr+6:ptr+6+psize-1],time=time
        if debug(3) then begin
          dprint,dlevel=2
          hexprint,     buffer[ptr:ptr+6+psize-1]  ;   buffer[ptr+6:ptr+6+psize-1]
        endif
        end
      else:  dprint,dlevel=1,'Unknown code'
    endcase
    
    ptr += ( psize+6)
  endwhile
  if ptr ne bsize then dprint,'MSG buffer size error?'
  return
end


