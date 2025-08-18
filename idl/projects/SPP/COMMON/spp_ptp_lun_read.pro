
function spp_ptp_header_struct,ptphdr
  ptp_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
  ptp_code = ptphdr[2]
  ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))

  days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
  ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
  us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
  utime = (days-4383L) * 86400L + ms/1000d
  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
  ;      if keyword_set(time) then dt = utime-time  else dt = 0
  source   =    ptphdr[13]
  spare    =    ptphdr[14]
  path  = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
  ptp_header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
  return,ptp_header
end




pro spp_ptp_lun_read,in_lun,out_lun,info=info,source_dict = source_dict

  dwait = 10.
  ;printdat,info
  if isa(source_dict,'DICTIONARY') eq 0 then source_dict = dictionary()
  
  on_ioerror, nextfile
    time = systime(1)
    info.time_received = time
    msg = time_string(info.time_received,tformat='hh:mm:ss -',local=localtime)
;    in_lun = info.hfp
    out_lun = info.dfp
    buf = bytarr(17)
    remainder = !null
    nbytes = 0UL
    run_proc = struct_value(info,'run_proc',default=1)
    fst = fstat(in_lun)
    spp_apdat_info,current_filename= fst.name
    source_dict.source_info = info    
    while file_poll_input(in_lun,timeout=0) && ~eof(in_lun) do begin
      readu,in_lun,buf,transfer_count=nb
      nbytes += nb
      if keyword_set(out_lun) then writeu,out_lun, buf
      ptp_buf = [remainder,buf]
      sz = ptp_buf[0]*256 + ptp_buf[1]
      if (sz lt 17) || (ptp_buf[2] ne 3) || (ptp_buf[3] ne 0) || (ptp_buf[4] ne 'bb'x) then  begin     ;; Lost sync - read one byte at a time
          remainder = ptp_buf[1:*]
          buf = bytarr(1)
          if debug(2) then begin
            dprint,dlevel=1,'Lost sync:',dwait=2
          endif
          continue  
      endif
      ptp_header = spp_ptp_header_struct(ptp_buf)
      ccsds_buf = bytarr(sz - n_elements(ptp_buf))
      readu,in_lun,ccsds_buf,transfer_count=nb
      nbytes += nb
      if keyword_set(out_lun) then writeu,out_lun, ccsds_buf
      
      fst = fstat(in_lun)
      if debug(2) && fst.cur_ptr ne 0 && fst.size ne 0 then begin
        dprint,dwait=dwait,dlevel=2,fst.compress ? '(Compressed) ' : '','File percentage: ' ,(fst.cur_ptr*100.)/fst.size
      endif
      
      if nb ne  sz-17 then begin
        fst = fstat(in_lun)
        dprint,'File read error. Aborting @ ',fst.cur_ptr,' bytes'
        break
      endif
      if debug(5) then begin
        hexprint,dlevel=3,ccsds_buf,nbytes=32
      endif
      source_dict.ptp_header  = ptp_header
      if ptp_header.ptp_path ne 'dead'x  then begin
        if run_proc then   spp_ccsds_spkt_handler,ccsds_buf,source_dict=source_dict
      endif else begin
        dprint,'DEAD PTP ',ptp_header.ptp_size,' byte packet at time:'+time_string(ptp_header.ptp_time),dlevel = 2
      endelse
      buf = bytarr(17)
      remainder=!null
    endwhile
    flush,out_lun

    if 0 then begin
      nextfile:
      dprint,!error_state.msg
      dprint,'Skipping file'
    endif    

    if ~keyword_set(no_sum) then begin
      if keyword_set(info.last_time) then begin
        dt = time - info.last_time
        info.total_bytes += nbytes
        if dt gt .1 then begin
          rate = info.total_bytes/dt
          store_data,'PTP_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
          info.total_bytes =0
          info.last_time = time
        endif
      endif else begin
        info.last_time = time
        info.total_bytes = 0
      endelse
    endif

    
    if nbytes ne 0 then msg += string(/print,nbytes,([ptp_buf,ccsds_buf])[0:(nbytes < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
    else msg+= ' No data available'

    dprint,dlevel=5,msg
    info.msg = msg

;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size
  
end


