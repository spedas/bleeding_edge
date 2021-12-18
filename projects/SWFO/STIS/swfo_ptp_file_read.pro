; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-12-17 09:47:01 -0800 (Fri, 17 Dec 2021) $
; $LastChangedRevision: 30471 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ptp_file_read.pro $
; adding code

pro swfo_ptp_file_read,files,dwait=dwait,no_products=no_products,no_clear=no_clear,file_type=file_type


  if not keyword_set(dwait) then   dwait = 10
  t0 = systime(1)
  dprint,'Initializing STIS data'
  swfo_stis_apdat_init  ,no_products=no_products
  dprint,'Clearing stored data'
  swfo_apdat_info,rt_flag=0,save_flag=1,/clear
  info = {  socket_recorder   }
  info.run_proc = 1
  on_ioerror, nextfile
  if ~isa(file_type) then file_type = 'ptp_file'

  for i=0,n_elements(files)-1 do begin
    info.input_sourcename = files[i]
    info.input_sourcehash = info.input_sourcename.hashcode()
    swfo_apdat_info,current_filename = info.input_sourcename
;    tplot_options,title=info.input_sourcename
    file_open,'r',info.input_sourcename,unit=lun,dlevel=3,compress=-1
    sizebuf = bytarr(2)
    fi = file_info(info.input_sourcename)
    dprint,dlevel=1,'Reading '+file_info_string(info.input_sourcename)+' LUN:'+strtrim(lun,2)
    if lun eq 0 then continue
    case file_type of
      'ptp_file':      swfo_ptp_lun_read,lun,info=info
      'gse_file':      swfo_gsemsg_lun_read,lun,info=info
    endcase
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

  swfo_apdat_info,current_filename=''
  swfo_apdat_info,/finish,/rt_flag,/all

  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt

end

