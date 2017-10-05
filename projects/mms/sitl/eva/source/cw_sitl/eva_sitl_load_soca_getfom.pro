Function eva_sitl_load_soca_getfom, pref, parent
  compile_opt idl2

  ;////////////////////////////////////
  local_dir = !MMS.LOCAL_DATA_DIR
  ;/////////////////////////////////////

  ;------------------------------------
  ; Get the latest FOMstr
  ;------------------------------------
  if strlen(pref.ABS_LOCAL) gt 0 then begin
    fom_file = pref.ABS_LOCAL
    error_flag = 0
    error_msg = ''
  endif else begin
    get_latest_fom_from_soc, fom_file, error_flag, error_msg
  endelse
  
  ;------------------------------------
  ; Abort if error (This should not happen often)
  ;------------------------------------
  if error_flag then begin
    msg = error_msg
    print,'EVA: '+msg
    result=dialog_message(msg,/center)
    unix_FOMstr = error_flag
    return, unix_FOMstr
  endif
  
  ;--------------------------------------
  ; Get a historical FOMstr if not valid
  ;--------------------------------------
  restore,fom_file
  if (not FOMstr.VALID) then begin
    print, 'EVA: FOMStr.VALID = ', FOMstr.VALID
    print, 'EVA: FOMStr.ERROR = ', FOMstr.ERROR
    print, 'EVA: FOMStr.ERRNO = ', FOMstr.ERRNO
    msg = 'No valid buffers found in the latest FOMstr.'
    msg = [msg,' ']
    msg = [msg,'Perhaps, the latest metadata evaluation was']
    msg = [msg,'performed on a ROI where no fast survey or']
    msg = [msg,'burst data was collected.']
    msg = [msg,' ']
    msg = [msg,'EVA will search and load the latest and valid']
    msg = [msg,'FOMstr.']
    result=dialog_message(msg,/center)
    
    sdur = 90.d0; Search from the last 90 days.
    etime = systime(/seconds,/utc)
    stime = etime - sdur*86400.d0
    timespan, time_string(stime), sdur
    mms_get_abs_fom_files,local_flist,pw_flag,pw_message
    nmax = n_elements(local_flist)
    found = 0
    if nmax gt 0 then begin; if list exists
      for n=0,nmax-1 do begin; for each file
        restore,local_flist[n]; restore
        if FOMstr.VALID then begin; and check the validity
          found=1
          break; if found, break
        endif
      endfor; for each file
    endif
    if (not found) then return, 0
  endif
  
  ;--------------
  ; Load FOMstr
  ;--------------
  
  ;---- adjustment for EVA ----
  mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
  print,'EVA: fom_file = '+fom_file
  nmax = unix_FOMStr.Nsegs
  discussion = strarr(nmax)
  discussion[0:nmax-1] = ' '
  str_element,/add,unix_FOMStr,'discussion',discussion
  
  ;---- update cw_sitl label ----
  nmax = n_elements(unix_FOMstr.timestamps)
  start_time = time_string(unix_FOMstr.timestamps[0],precision=3)
  end_time = time_string(unix_FOMstr.timestamps[nmax-1],precision=3)
  lbl = ' '+start_time+' - '+end_time
  print,'EVA: updating cw_sitl target_time label:'
  print,'EVA: '+ lbl
  id_sitl = widget_info(parent, find_by_uname='eva_sitl')
  sitl_stash = WIDGET_INFO(id_sitl, /CHILD)
  WIDGET_CONTROL, sitl_stash, GET_UVALUE=sitl_state, /NO_COPY
  widget_control, sitl_state.lblTgtTimeMain, SET_VALUE=lbl
  WIDGET_CONTROL, sitl_stash, SET_UVALUE=sitl_state, /NO_COPY
  
  return, unix_FOMstr
END