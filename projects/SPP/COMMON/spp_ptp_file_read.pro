  ; $LastChangedBy: davin-mac $
  ; $LastChangedDate: 2018-10-01 14:52:34 -0700 (Mon, 01 Oct 2018) $
  ; $LastChangedRevision: 25880 $
  ; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_ptp_file_read.pro $
  ; adding code



pro spp_ptp_file_read,files,dwait=dwait,no_products=no_products,no_clear=no_clear
  
  
  if not keyword_set(dwait) then   dwait = 10
  t0 = systime(1)
  spp_swp_apdat_init  ,no_products=no_products
  spp_apdat_info,rt_flag=0,save_flag=1,/clear 
  info = {  socket_recorder   }
  info.run_proc = 1
  on_ioerror, nextfile

  for i=0,n_elements(files)-1 do begin
    info.input_sourcename = files[i] 
    info.input_sourcehash = info.input_sourcename.hashcode()
    spp_apdat_info,current_filename = info.input_sourcename
    tplot_options,title=info.input_sourcename
    file_open,'r',info.input_sourcename,unit=lun,dlevel=3,compress=-1
    sizebuf = bytarr(2)
    fi = file_info(info.input_sourcename)
    dprint,dlevel=1,'Reading file: '+info.input_sourcename+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)
    if lun eq 0 then continue
    spp_ptp_lun_read,lun,info=info
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
  
  spp_apdat_info,current_filename=''
  spp_apdat_info,/finish,/rt_flag,/all

  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  
end


