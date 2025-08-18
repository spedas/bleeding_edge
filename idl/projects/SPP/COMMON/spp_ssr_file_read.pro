; $LastChangedBy: ali $
; $LastChangedDate: 2025-03-13 13:05:13 -0700 (Thu, 13 Mar 2025) $
; $LastChangedRevision: 33171 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_ssr_file_read.pro $
;
; This routine reads SSR files (series of CCSDS packets)

pro spp_ssr_file_read,files,dwait=dwait,no_products=no_products,sort_flag=sort_flag,no_init=no_init,finish=finish,kernels=kernels

  if ~keyword_set(files) then return

  dummy = {cdf_tools}

  if not keyword_set(dwait) then   dwait = 10
  t0 = systime(1)

  apdat_info = spp_apdat(/get_info)

  if n_elements(sort_flag) eq 0 then sort_flag=1
  spp_swp_apdat_init  ,no_products=no_products
  spp_apdat_info,save_flag=1,rt_flag=0
  if ~keyword_set(no_init) then begin
    spp_apdat_info,/clear
    apdat_info['file_hash_list'].remove,/all
  endif

  info = {socket_recorder   }
  info.run_proc = 1
  on_ioerror, nextfile

  for i=0,n_elements(files)-1 do begin
    if apdat_info.haskey('break') then begin
      dprint,'Break point here',dlevel=3
      if apdat_info['break'] ne 0 then stop
    endif
    filename = files[i]
    basename = file_basename(filename)
    hashcode = basename.hashcode()
    filetime = spp_spc_met_to_unixtime(ulong(strmid(basename,0,10)),kernels=kernels)
    info.input_sourcename = filename
    info.input_sourcehash = hashcode
    fi=file_info_string(filename)
    met=time_string(filetime,tformat=' MET:YYYY-MM-DD/hh:mm:ss (DOY)')
    if apdat_info['file_hash_list'].haskey(hashcode)  then begin
      dprint,dlevel=1,'Skipping already loaded file '+fi+met
      continue
    endif
    file_open,'r',info.input_sourcename ,unit=lun,dlevel=3,compress=-1
    if lun eq 0 then begin
      dprint,'Bad file '+fi+met
      continue
    endif
    dprint,dlevel=2,'Loading '+fi+' LUN:'+strtrim(lun,2)+met
    spp_ssr_lun_read,lun,info=info

    fst = fstat(lun)
    compression = float(fst.cur_ptr)/fst.size
    dprint,dlevel=3,'Loaded File:'+fst.name+' Compression: '+strtrim(float(fst.cur_ptr)/fst.size,2)
    if 0 then begin
      nextfile:
      dprint,!error_state.msg
      printdat,!error_state
      dprint,'Skipping file '+fi
      spawn,'echo "'+str_sub(strjoin([scope_traceback(),fi,!error_state.msg,getenv(/e)],'\n'),'$','')+'" | mailx -s "spp_ssr_file_read error" rahmati@berkeley.edu'
      message,'Aborting.'
    endif
    free_lun,lun
    spp_apdat_info,current_filename=filename   ; info.input_sourcename
  endfor
  if not keyword_set(no_clear) then del_data,'spp_*'  ; store_data,/clear,'*'
  spp_apdat_info,finish=finish,rt_flag=0,/all,sort_flag=sort_flag
  dt=systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt

end