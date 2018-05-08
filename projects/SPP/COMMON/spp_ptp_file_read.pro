  ; $LastChangedBy: davin-mac $
  ; $LastChangedDate: 2018-05-07 14:19:03 -0700 (Mon, 07 May 2018) $
  ; $LastChangedRevision: 25176 $
  ; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_ptp_file_read.pro $
  ; adding code



pro spp_ptp_file_read,files,dwait=dwait,no_products=no_products,no_clear=n0_clear
  
  oldmethod =0
  
  if not keyword_set(dwait) then   dwait = 10
  t0 = systime(1)
  if oldmethod then begin
    spp_swp_startup,rt_flag=0,save=1,/clear
  endif else begin
    spp_swp_apdat_init  ,no_products=no_products
    spp_apdat_info,rt_flag=0,save_flag=1,/clear 
  endelse
  info = {socket_recorder   }
  info.run_proc = 1
  on_ioerror, nextfile


  for i=0,n_elements(files)-1 do begin
    info.filename = files[i] 
    tplot_options,title=info.filename
    file_open,'r',info.filename,unit=lun,dlevel=3,compress=-1
    sizebuf = bytarr(2)
    fi = file_info(info.filename)
    dprint,dlevel=1,'Reading file: '+info.filename+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)
    if lun eq 0 then continue
      if 1 then begin
        spp_ptp_lun_read,lun,info=info
      endif else begin
        while ~eof(lun) do begin
          info.time_received = systime(1)
          point_lun,-lun,fp
          if ~keyword_set( *info.buffer_ptr) then begin
            readu,lun,sizebuf
            sz = sizebuf[0]*256 + sizebuf[1]
            if sz gt 17 then  begin
              remainder = sizebuf  
              sz -= 2
            endif else begin
              remainder = !null
              sz = 100L         
            endelse
          endif else begin
            remainder = !null
            szr =  swap_endian( uint(*info.buffer_ptr,0) ,  /swap_if_little_endian)
            sz = szr - n_elements(*info.buffer_ptr)
            dprint,'Resync:',dlevel=3,sz
          endelse
          buffer = bytarr(sz)
          readu,lun,buffer,transfer_count=nb
          if nb ne sz then begin
            dprint,'File read error. Aborting @ ',fp,' bytes'
            break
          endif
          spp_ptp_stream_read,[remainder,buffer],info=info  
          if debug(2) then begin
            dprint,dwait=dwait,dlevel=2,'File percentage: ' ,(fp*100.)/fi.size
          endif
        endwhile
      endelse    
    fst = fstat(lun)
    dprint,dlevel=2,'Compression: ',float(fst.cur_ptr)/fst.size
    free_lun,lun
    if 0 then begin
      nextfile:
      dprint,!error_state.msg
      dprint,'Skipping file'
    endif
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
  if not keyword_set(no_clear) then del_data,'spp_*'  ; store_data,/clear,'*'
  if oldmethod then begin
    spp_apid_data,/finish
    spp_apid_data,/rt_flag    ; re-enable realtime
  endif else begin
    spp_apdat_info,/finish,/rt_flag,/all
  endelse
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
end


