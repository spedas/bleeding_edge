; $LastChangedBy: ali $
; $LastChangedDate: 2021-06-14 10:41:21 -0700 (Mon, 14 Jun 2021) $
; $LastChangedRevision: 30043 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_ssr_lun_read.pro $
;
;function spp_ptp_header_struct,ptphdr
;  ptp_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
;  ptp_code = ptphdr[2]
;  ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))
;
;  days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
;  ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
;  us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
;  utime = (days-4383L) * 86400L + ms/1000d
;  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
;  ;      if keyword_set(time) then dt = utime-time  else dt = 0
;  source   =    ptphdr[13]
;  spare    =    ptphdr[14]
;  path  = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
;  ptp_header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
;  return,ptp_header
;end


pro spp_ssr_lun_read,in_lun,out_lun,info=info

  dwait = 10.
  valid_APIDs= bytarr('7ff'x)
  valid_APIDs['7b0'x:'7df'x] = 1b
  source_dict = dictionary()

  on_ioerror, nextfile
  info.time_received = systime(1)
  msg = time_string(info.time_received,tformat='hh:mm:ss -',local=localtime)
  ;    in_lun = info.hfp
  out_lun = info.dfp
  buf = bytarr(6)
  remainder = !null
  nbytes = 0
  run_proc = struct_value(info,'run_proc',default=1)
  source_dict.source_info = info
  while file_poll_input(in_lun,timeout=0) && ~eof(in_lun) do begin
    readu,in_lun,buf,transfer_count=nb
    nbytes += nb
    if keyword_set(out_lun) then writeu,out_lun, buf
    ccsds_hdr = [remainder,buf]
    sz = ccsds_hdr[4]*256 + ccsds_hdr[5] + 7
    if (sz lt 8  || sz gt 8096) then  begin     ;; Lost sync - read one byte at a time  - should put other checks in here (i.e. valid APIDS)
      remainder = ccsds_hdr[1:*]
      buf = bytarr(1)
      if debug(2) then begin
        dprint,dlevel=2,'Lost sync:',dwait=10
      endif
      continue
    endif
    ptp_header = !null  ; spp_ptp_header_struct(ccsds_hdr)
    ccsds_remainder = bytarr(sz - n_elements(ccsds_hdr))
    readu,in_lun,ccsds_remainder,transfer_count=nb
    nbytes += nb
    if keyword_set(out_lun) then writeu,out_lun, ccsds_remainder
    ccsds_buf = [ccsds_hdr,ccsds_remainder]

    fst = fstat(in_lun)
    if debug(2) && fst.cur_ptr ne 0 && fst.size ne 0 then begin
      dprint,dwait=dwait,dlevel=2,fst.compress ? '(Compressed) ' : '','File percentage: ' ,(fst.cur_ptr*100.)/fst.size
    endif

    if nb ne  sz-6 then begin
      fst = fstat(in_lun)
      dprint,'File read error. Aborting @ ',fst.cur_ptr,' bytes'
      break
    endif
    if debug(5) then begin
      hexprint,dlevel=3,ccsds_buf,nbytes=32
    endif
    if run_proc then   spp_ccsds_spkt_handler,ccsds_buf, source_dict=source_dict  ; ,source_info=info  ,ptp_header=ptp_header

    buf = bytarr(6)
    remainder=!null
  endwhile

  bsz = n_elements(ccsds_buf)
  if nbytes ne 0 then msg += string(/print,nbytes,ccsds_buf[0:(bsz < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
  else msg+= ' No data available'

  dprint,dlevel=4,msg
  info.msg = msg

  if 0 then begin
    nextfile:
    dprint,!error_state.msg
    dprint,'Skipping file'
  endif
  ;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size

end
