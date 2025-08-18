; $LastChangedBy: ali $
; $LastChangedDate: 2022-05-01 12:57:34 -0700 (Sun, 01 May 2022) $
; $LastChangedRevision: 30793 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_gsemsg_lun_read.pro $

function swfo_gsemsg_header_struct,buf
  ;printdat,buf
  gse_pkt = {time:0d,gap:0}
  return,gse_pkt

  ;  ptp_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
  ;  ptp_code = ptphdr[2]
  ;  ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))
  ;
  ;  days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
  ;  ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
  ;  us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
  ;  utime = (days-4383L) * 86400L + ms/1000d
  ;  ;      if keyword_set(time) then dt = utime-time  else dt = 0
  ;  source   =    ptphdr[13]
  ;  spare    =    ptphdr[14]
  ;  path  = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
  ;  header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
  ;  return,header
end


;+
;  PROCEDURE SWFO_GSEMSG_LUN_READ
;  This procedure is only specific to SWFO in the "sync bytes" found in the PTP header.  Otherwise it could be considered generic
;  It purpose is to read bytes from a previously opened PTP file OR stream.  It returns at the end of file (for files) or when
;  no more bytes are available for reading from a stream.
;  It should gracefully handle sync errors and find sync up on a PTP header.
;  When a complete PTP header and its enclosed CCSDS packet are read in, it will execute the routine "swfo_ccsds_spkt_handler"
;-

pro swfo_gsemsg_lun_read,in_lun,out_lun,info=info

  dwait = 10.
  ;printdat,info
  if isa(info.user_dict,'DICTIONARY') eq 0 then begin
    info.user_dict = dictionary()
    dprint,dlevel=1,'Created user dictionary'
  endif

  source_dict = info.user_dict
  if ~source_dict.haskey('sync_ccsds_buf') then source_dict.sync_ccsds_buf = !null   ; this contains the contents of the buffer from the last call

  ;printdat,source_dict.sync_ccsds_buf

  on_ioerror, nextfile
  time = systime(1)
  info.time_received = time
  msg = time_string(info.time_received,tformat='hh:mm:ss -',local=localtime)
  ;    in_lun = info.hfp
  out_lun = info.dfp
  buf = bytarr(6)
  remainder = !null
  nbytes = 0UL
  run_proc = struct_value(info,'run_proc',default=1)
  fst = fstat(in_lun)
  ;    swfo_apdat_info,current_filename= fst.name
  ;printdat,in_lun
  while file_poll_input(in_lun,timeout=0) && ~eof(in_lun) do begin
    readu,in_lun,buf,transfer_count=nb
    if debug(4) then begin
      dprint,nb,dlevel=3
      hexprint,buf
    endif
    nbytes += nb
    if keyword_set(out_lun) then writeu,out_lun, buf
    msg_buf = [remainder,buf]
    sz = msg_buf[4]*256L + msg_buf[5]
    if (sz lt 4) || (msg_buf[0] ne 'A8'x) || (msg_buf[1] ne '29'x) || (msg_buf[2] ne '00'x) then  begin     ;; Lost sync - read one byte at a time
      remainder = msg_buf[1:*]
      buf = bytarr(1)
      if debug(2) then begin
        dprint,dlevel=1,'Lost sync:',dwait=2
      endif
      continue
    endif
    case msg_buf[3] of
      'c1'x: begin
        if sz ne 'c'x then begin
          dprint,'Invalid GSE message. word size: ',sz
          message,'Error',/cont
        endif
        buf = bytarr(sz*2)
        readu,in_lun,buf,transfer_count=nb
        nbytes += nb
        if debug(3) then begin
          dprint,nb,dlevel=3
          hexprint,buf
        endif
        if keyword_set(out_lun) then writeu,out_lun, buf
        gse_header = swfo_gsemsg_header_struct(buf)
        source_dict.gse_header  = gse_header
      end
      'c3'x: begin
        sync_pattern = ['1a'x,  'cf'x ,'fc'x, '1d'x ]
        buf = bytarr(sz*2)
        readu,in_lun,buf,transfer_count=nb
        nbytes += nb
        if debug(3) then begin
          dprint,nb,dlevel=3
          hexprint,buf
        endif
        if keyword_set(out_lun) then writeu,out_lun, buf
        source_dict.sync_ccsds_buf = [source_dict.sync_ccsds_buf, buf]
        while 1 do begin ; start processing packet stream
          nbuf = n_elements(source_dict.sync_ccsds_buf)
          skipped = 0UL
          while (nbuf ge 4) && (array_equal(source_dict.sync_ccsds_buf[0:3] ,sync_pattern) eq 0) do begin
            dprint,dlevel=4, 'searching for sync pattern: ',nbuf
            source_dict.sync_ccsds_buf = source_dict.sync_ccsds_buf[1:*]    ; increment one byte at a time looking for sync pattern
            nbuf = n_elements(source_dict.sync_ccsds_buf)
            skipped++
          endwhile
          if skipped then dprint,dlevel=2,'Skipped ',skipped,' bytes to find sync word'
          nbuf = n_elements(source_dict.sync_ccsds_buf)
          if nbuf lt 10 then begin
            dprint,dlevel=4,'Incomplete packet header - wait for later'
            ;         source_dict.sync_ccsds_buf = sync_ccsds_buf
            break
          endif
          pkt_size = source_dict.sync_ccsds_buf[4+4] * 256u + source_dict.sync_ccsds_buf[5+4] + 7
          ;dprint,dlevel=2,'pkt_size: ',pkt_size
          if nbuf lt pkt_size + 4 then begin
            dprint,dlevel=4,'Incomplete packet - wait for later'
            ;      source_dict.sync_ccsds_buf = sync_ccsds_buf
            break
          endif
          ccsds_buf = source_dict.sync_ccsds_buf[4:pkt_size+4-1]  ; not robust!!!
          if run_proc then   swfo_ccsds_spkt_handler,ccsds_buf,source_dict=source_dict
          if n_elements(source_dict.sync_ccsds_buf) eq pkt_size+4 then source_dict.sync_ccsds_buf = !null $
          else    source_dict.sync_ccsds_buf = source_dict.sync_ccsds_buf[pkt_size+4:*]
        endwhile
      end
      else:    message,'GSE msg file error - unknown code'
    endcase

    fst = fstat(in_lun)
    if debug(2) && fst.cur_ptr ne 0 && fst.size ne 0 then begin
      dprint,dwait=dwait,dlevel=2,fst.compress ? '(Compressed) ' : '','File percentage: ' ,(fst.cur_ptr*100.)/fst.size
    endif

    if nb ne  sz*2 then begin
      fst = fstat(in_lun)
      dprint,'File read error. Aborting @ ',fst.cur_ptr,' bytes'
      break
    endif
    if debug(5) then begin
      hexprint,dlevel=3,ccsds_buf,nbytes=32
    endif
    buf = bytarr(6)     ; initializef for next gse message
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
        store_data,'GSE_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
        info.total_bytes =0
        info.last_time = time
      endif
    endif else begin
      info.last_time = time
      info.total_bytes = 0
    endelse
  endif

  ddata = buf
  nb = n_elements(buf)
  ; if nb ne 0 then msg += string(/print,nb,(ddata)[0:(nb < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
  if nbytes ne 0 then msg += string(/print,nbytes,format='(i6 ," bytes: ")')  $
  else msg+= ' No data available'

  dprint,dlevel=5,msg
  info.msg = msg

  ;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size

end


