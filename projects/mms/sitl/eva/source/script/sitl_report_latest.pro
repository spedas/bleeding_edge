PRO sitl_report_latest, dir=dir, force=force
  compile_opt idl2
  
  ;//////////////////////////////////////////////
  paramset = 'SITL_Dayside_Basic';'SITL_Tail_Basic';'SITL_Basic_NoFPI';'SITL_Basic_Tail'; SITL_Basic_Dayside
  if undefined(dir) then dir = './' $;'/Volumes/moka/public_html/eva/' $
  else dir = spd_addslash(dir)
  ;////////////////////////////////////////////////
  mms_init
  
  ;-------------
  ; CATCH ERROR
  ;-------------
  catch, error_status; !ERROR_STATE is set
  if error_status ne 0 then begin
    catch, /cancel; Disable the catch system
    eva_error_message, error_status
    message, /reset; Clear !ERROR_STATE
    return
  endif
  
  ;------------------
  ; SITL .sav files
  ;------------------
  days = 3
  current_time = time_string(systime(/utc,/seconds))
  start_temp = time_string(systime(/utc,/seconds)-86400.d0*double(days))
  start_time = strmid(start_temp,0,10)+'-00'

  local_dir = filepath('', root_dir=!MMS.LOCAL_DATA_DIR, $
    subdirectory=['sitl','sitl_selections',strmid(systime(/utc), 20, 4)])

  file_mkdir, local_dir
  
  ;If only the end_time is specified, files with timestamps before or on that time are returned.
  status = get_mms_selections_file("sitl_selections", $
    start_time=start_time, local_dir=local_dir)
  
  fileSITL = file_search(local_dir+'*',count=imax); files from old to new
  
  
  for i=0,imax-1 do begin
    restore, fileSITL[i]
    mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
    fomSITL = unix_FOMstr
    tfom = eva_sitl_tfom(fomSITL)
    store_data,'mms_stlm_fomstr',data=eva_sitl_strct_read(fomSITL,tfom[0])
    options,'mms_stlm_fomstr',ytitle='FOM', ysubtitle='(SITL)',psym=0, constant=[50,100,150,200]
    options,'mms_stlm_fomstr','unix_FOMStr_mod',fomSITL
    infoSITL = sitl_report_latest_info(unix_FOMstr,fileSITL[i],dir)
    sitl_report_latest_json, infoSITL, dir
  endfor
  
  ;------------------
  ; ABS .sav files
  ;------------------
  ; ABS
  eva_sitl_load_soca_simple, unix_FOMstr=unix_FOMstr,/no_gui, fom_file=fom_file
  fomABS = unix_FOMstr
  fileABS = fom_file
  if n_tags(fomABS) eq 0 then begin
    print, 'Failed to load FOMstr (AUTO)'
    return
  endif
  infoABS = sitl_report_latest_info(fomABS,fileABS,dir)
  sitl_report_latest_json, infoABS, dir, /ABS
  
  
  ;------------------------------------
  ; plot
  ;------------------------------------
  clock= tic()
  sitl_report_latest_plot, infoSITL, paramset,dir
  if(infoSITL.str_orbit ne infoABS.str_orbit) then begin
    sitl_report_latest_plot, infoABS,paramset,dir
  endif
  laptime = toc(clock)
  print, 'plot time: ', laptime, ' seconds'
END