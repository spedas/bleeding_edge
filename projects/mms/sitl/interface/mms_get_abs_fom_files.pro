; File to get historic ABS selections. Note that the time stamps on sitl and abs files are not referring
; to the contents of the files, but the date and time at which the foms were created.
 
pro mms_get_abs_fom_files, local_flist, pw_flag, pw_message, trange=trange



login_flag = 0

pw_flag = 0

;lastpos = strlen(local_dir)
;if strmid(local_dir, lastpos-1, lastpos) eq path_sep() then begin
;  data_dir = local_dir + 'data' + path_sep() + 'mms' + path_sep()
;endif else begin
;  data_dir = local_dir + path_sep() + 'data' + path_sep() + 'mms' + path_sep()
;endelse

temp_dir = !MMS.LOCAL_DATA_DIR
spawnstring = 'echo ' + temp_dir
spawn, spawnstring, data_dir

;----------------------------------------------------------------------------
; Convert start and stop times to the format the sdc code wants
;;----------------------------------------------------------------------------
if ~undefined(trange) && n_elements(trange) eq 2 then begin
  t = timerange(trange)
endif else begin
  t = timerange()
  t = [t[0],t[1]+3.d0*86400.d0,t[1]]
endelse

st = time_string(t)
start_date = strmid(st[0],0,10)
end_date = strmatch(strmid(st[1],11,8),'00:00:00')?strmid(time_string(t[1]-10.d0),0,10):strmid(st[1],0,10)

start_hour = strmid(st[0], 11, 2)
end_hour = strmid(st[1], 11, 2)
start_date += '-'
start_date += start_hour
end_date += '-'
end_date += end_hour

; Now query the SDC to see what files exist.
filenames = mms_get_abs_file_names(start_date=start_date, end_date=end_date)

type_string = typename(filenames)

if type_string ne 'STRING' then begin
  login_flag = 1
endif else begin

; Now we parse the file names so we can compare with local cache
  cut_filenames = strarr(n_elements(filenames))
  full_filenames = cut_filenames
  file_type = cut_filenames
  file_year = cut_filenames
  file_dir = cut_filenames
  download_flags = intarr(n_elements(filenames))

  for i = 0, n_elements(filenames)-1 do begin
      first_slash = strpos(filenames(i), '/', /reverse_search)
      cut_filenames(i) = strmid(filenames(i), first_slash+1, strlen(filenames(i)))
      split_string = strsplit(cut_filenames(i), '_', /extract)
      file_type(i) = split_string(0) + '_' + split_string(1)
      file_year(i) = strmid(split_string(2), 0, 4)
    
      ; now we create the directory path
      file_dir(i) = filepath('', root_dir=data_dir, $
        subdirectory=['sitl',file_type(i), file_year(i)])
        
      ;file_dir(i) = data_dir + 'sitl/' + file_type(i) + '/' + file_year(i) + '/'
      full_filenames(i) = file_dir(i) + cut_filenames(i)
    
      ; Now check and see if this crap is already in the 
      search_string = full_filenames(i)
      search_results = file_search(search_string)

      if n_elements(search_results) eq 1 and search_results(0) eq '' then begin
        download_flags(i) = 1 ; No existing files, so download from SDC
      endif

  endfor

  loc_download = where(download_flags eq 1, count_download)

  if count_download gt 0 then begin
    download_filenames = cut_filenames(loc_download)
    download_dirs = file_dir(loc_download)

    for j = 0, count_download-1 do begin
      file_mkdir, download_dirs(j)
      disp_string = 'Downloaded File ('  + strtrim(string(j+1),2) + ' of ' + $
        strtrim(string(count_download),2) + '): ' + download_filenames(j)
        status = get_mms_abs_selections(filename = download_filenames(j), $
        local_dir = download_dirs(j))
        print, disp_string
    endfor
  
  endif

local_flist = full_filenames

endelse

; Alternative - we check local cache if unable to connect to SDC
if login_flag eq 1 then begin
  print, 'Unable to connect to SDC, checking local cache.'
  abs_check_local_cache, local_flist, start_date, end_date, file_flag
  
  if file_flag eq 1 then pw_flag = 1
  
endif

pw_message = 'Unable to connect to SDC or find data in the local directory.'

end