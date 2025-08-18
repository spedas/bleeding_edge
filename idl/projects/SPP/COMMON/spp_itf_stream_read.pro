; this routine decoms a single ITF

pro spp_itf_decom,itf_buffer,itf_struct=itf_struct

  p = 0L
  bsize = n_elements(itf_buffer) - p
  
  if bsize ne 8198 then begin
    dprint,'improper size: ',bsize
    return
  endif

  sync = swap_endian( ulong(itf_buffer,p) , /swap_if_little_endian)
  if sync ne 'FEFA30C8'x then begin
    dprint,dlevel=1,'bad sync at p=',p
    printdat,sync,/hex
;    savetomain,itf_buffer
    hexprint,itf_buffer[0:63]
    return
  endif


  itf_length =  swap_endian( uint(itf_buffer,p+6) , /swap_if_little_endian)
  itf_vc  = itf_buffer[p+4]
  itf_seq = itf_buffer[p+5]
  itf_offset = swap_endian( uint(itf_buffer,p+8) , /swap_if_little_endian)

  if size(/type, itf_struct) ne 8 then begin
    dprint,size(/type,itf)
    last_seq = itf_seq       ; force restart
    pointer = ptr_new(!null) 
    dprint,'ITF initialization done'
  endif else begin
    last_seq = itf_struct.seq
    pointer =  itf_struct.pointer
  endelse
  

  if size(/type,itf_struct) eq 8 then last_seq = itf_struct.seq else last_seq = 0
  dseq = byte(itf_seq - last_seq)
  
  gap = dseq ne 1b
  
  
  data_size = itf_length-4
  check_sum = swap_endian( uint(itf_buffer,p+itf_length+6) , /swap_if_little_endian)
  itf_struct = { $
     sync:sync, $
     itf_length : itf_length, $
     bsize: bsize, $
     data_size : data_size, $
     vc:itf_vc, $
     seq:itf_seq, $
     offset: itf_offset, $
     pointer: pointer,  $
     check_sum: check_sum, $
     dseq: dseq, $
     gap: gap}
  
  if itf_struct.offset ge 8183 then dprint,dlevel=1,'No packet header in ITF: ',itf_struct.offset  

  if debug(2) then begin
    dprint,dlevel=2,phelp=0,'New frame ',bsize,itf_vc,itf_seq,itf_length,"   offset:",itf_offset ,"   leftover:", n_elements(*itf_struct.pointer)
 ;   hexprint,itf_buffer[p:p+64-1]
  endif


  if dseq ne 1 then begin
    if debug(1) then dprint,dlevel=1,'Skipped ',dseq,' ITFs'
  endif

  remainder = *itf_struct.pointer
  offset = itf_struct.offset

  if  (dseq eq 1) && (itf_struct.offset ne 0) && (n_elements(remainder) ge 6) then begin    ; prepend the bytes left over from the previous ITF
    pkt_size = swap_endian(uint(remainder,4) ,/swap_if_little_endian ) + 7       ;  size of split packet
    n_remainder = n_elements(remainder)
;    dprint,dlevel=2,n_remainder, pkt_size, pkt_size-n_remainder, itf_struct.offset
    if itf_struct.offset eq (pkt_size-n_remainder) then begin
      offset=0
    endif else begin
      dprint,dlevel=1,'Offset error: ',n_remainder, pkt_size, pkt_size-n_remainder, itf_struct.offset
      remainder = !null
      offset = itf_struct.offset
    endelse
  endif else begin
    remainder = !null   
    offset = itf_struct.offset
  endelse
  
  dbuffer = [remainder,itf_buffer[p+10: p+10+data_size-1]]
  spp_ccsds_pkt_handler,dbuffer,offset,remainder = *itf_struct.pointer

;  ds = n_elements(dbuffer)
;  npackets = 0

;  if n_elements(dbuffer) ne ds then dprint,'error', n_elements(dbuffer),data_size
  
;  ptp_header ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, ptp_spare:0, ptp_path:0, ptp_size: ds +17 }
 

if 0 then begin
  while q lt ds do begin
    ccsds = spp_swp_ccsds_decom(dbuffer[q:*],error=error,remainder=*itf_struct.pointer)
    if ~keyword_set(ccsds) then begin
      if debug(2) then begin
        b = *itf_struct.pointer
        pkt_size = swap_endian(uint(b,4) ,/swap_if_little_endian ) + 7
        dprint,dlevel=2,'Incomplete CCSDS, saving ',n_elements(b),' bytes for later ',pkt_size,pkt_size - n_elements(b)
        ;      hexprint,dbuffer[q:*]
        ;      printdat,*itf_struct.pointer
      endif
      break
    endif
    npackets +=1
    if debug(2) then begin
;      if ccsds.seq_group and 1 then head2 = string(
      dat = (*ccsds.pdata)[12:17]
      dprint,dlevel=2,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i5,"   ",8(" ",Z02))',npackets,q,ccsds.apid,ccsds.seq_group,ccsds.seqn,ccsds.pkt_size,dat
      ;      hexprint,ccsds.data
    endif  
;    q_last =q  
    q += ccsds.pkt_size
    if 1 then begin
      ptp_header ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, ptp_spare:0, ptp_path:0, ptp_size: 17 + ccsds.pkt_size }
      spp_ccsds_pkt_handler,ptp_header = ptp_header,ccsds = ccsds      
    endif

  endwhile
  
endif  
;    dprint,dlevel=4,'ITF remainder:',ds-q, q,ds
end






pro spp_itf_stream_read,buffer,info=info

  common spp_itf_stream_read_com,last_time,total_bytes,rate_sm,last_seq

  bsize = n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
  if bsize eq 0 then begin
    dprint,dlevel=2,'Empty buffer'
    return
  endif
  
  ;*info.buffer_ptr = !null
 ; printdat,info
  if 0 then begin
    spp_itf_decom,buffer,info=itfstruct
    return
  endif
  
  
  if keyword_set(*info.buffer_ptr)  then begin
    concat_buffer = [*info.buffer_ptr,buffer]
    dprint,dlevel=1,'Using previously stored bytes ',n_elements(concat_buffer)
    *info.buffer_ptr = !null
    spp_itf_stream_read,concat_buffer,info=info
    return
  endif

  time = info.time_received
  nitf = bsize / 8198
  remainder = bsize mod 8198

  dsize = 0L
  for i = 0l,nitf -1 do begin
    spp_itf_decom,buffer[i*8198:i*8198+8197],itf_struct= *info.exec_proc_ptr
    dsize += (*info.exec_proc_ptr).data_size
    ;   printdat,info.exec_proc_ptr
  endfor
  dprint,dlevel=3,dsize

  if keyword_set(last_time) then begin
    dt = time - last_time
    total_bytes += dsize
    if dt gt .1 then begin
      rate = total_bytes*1.d/dt
      store_data,'ITF_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
      total_bytes =0
      last_time = time
    endif
  endif else begin
    last_time = time
    total_bytes = 0
  endelse


;  dprint,dlevel=2,bsize,nitf,remainder
  if remainder ne 0 then begin
    dprint,dlevel=2,'incomplete ITF ',remainder
    *info.buffer_ptr = buffer[i*8198:*]
 ;   printdat,*info.buffer_ptr
  endif



end


