pro get_latest_fom_from_soc, fom_file, error_flag, error_msg

  ; For now, lets ignore start and end time, and just grab the most recent file
  
;  lastpos = strlen(local_dir)
;  if strmid(local_dir, lastpos-1, lastpos) eq path_sep() then begin
;    data_dir = local_dir + 'data' + path_sep() + 'mms' + path_sep()
;  endif else begin
;    data_dir = local_dir + path_sep() + 'data' + path_sep() + 'mms' + path_sep()
;  endelse

  temp_dir = !MMS.LOCAL_DATA_DIR
  spawnstring = 'echo ' + temp_dir
  spawn, spawnstring, data_dir

  temptime = systime(/utc)

  yearstr = strmid(temptime, 20, 4)
  
  dir_path = filepath('',root_dir=data_dir, $
    subdirectory=['sitl', 'abs_selections', yearstr])
  
  ;dir_path = data_dir + 'sitl/abs_selections/' + yearstr + '/'
  
  error_flag = 0
  error_msg = 'ERROR: Either no FOM structure exists for the time specified, or login failed.'
  
  current_leap = 35
  
  file_mkdir, dir_path

  status = get_mms_abs_selections(local_dir = dir_path)
  
  if status eq 0 then begin
  
    ; Find most recent file by finding largest time_tag
    search_string = dir_path + 'abs_selections_*.sav'
    flist = file_search(search_string)
    dir_length = strlen(dir_path)
    
    
    fjul = dblarr(n_elements(flist))
    
    for i = 0, n_elements(flist)-1 do begin
      last_slash = strpos(flist(i), path_sep(), /reverse_search)
      fyear = fix(strmid(flist(i), last_slash+16, 4))
      fmonth = fix(strmid(flist(i), last_slash+21, 2))
      fday = fix(strmid(flist(i), last_slash+24, 2))
      fhour = fix(strmid(flist(i), last_slash+27, 2))
      fmin = fix(strmid(flist(i), last_slash+30, 2))
      fsec = fix(strmid(flist(i), last_slash+33, 2))
      fjul(i) = julday(fmonth, fday, fyear, fhour, fmin, fsec)
    endfor
    
    fjulmax = max(fjul, maxidx)
    
    fom_file = flist(maxidx)
    
    restore, fom_file
    
    if n_tags(fomstr) eq 0 then begin
      fom_file = ''
      error_flag = 1
    endif

  endif else begin
  
    ; Error message for non-existant file
    error_flag = 1
    fom_file = ''
  endelse

end