; Checks local cache if download fails

pro abs_check_local_cache, local_flist, start_date, end_date, file_flag

  file_flag = 0

  start_year_str = strmid(start_date, 0, 4)
  start_year = fix(start_year_str)
  start_month = fix(strmid(start_date, 5, 2))
  start_day = fix(strmid(start_date, 8, 2))
  start_jul = julday(start_month, start_day, start_year, 0, 0, 0)

  ; Convert end date
  end_year = fix(strmid(end_date, 0, 4))
  end_month = fix(strmid(end_date, 5, 2))
  end_day = fix(strmid(end_date, 8, 2))
  end_jul = julday(end_month, end_day, end_year, 0, 0, 0)

  if start_year ne end_year then file_flag = 1

;  lastpos = strlen(local_dir)
;  if strmid(local_dir, lastpos-1, lastpos) eq path_sep() then begin
;    data_dir = local_dir + 'data' + path_sep() + 'mms' + path_sep()
;  endif else begin
;    data_dir = local_dir + path_sep() + 'data' + path_sep() + 'mms' + path_sep()
;  endelse

data_dir = !MMS.LOCAL_DATA_DIR

  if file_flag eq 0 then begin
    ; First, get the directory to search
    file_dir = filepath('', root_dir=data_dir, $
      subdirectory=['sitl','abs_selections',start_year_str])
    ;file_dir = data_dir + 'sitl/abs_selections/' + start_year_str + '/'
    search_string = file_dir + '*.sav'
    search_results = file_search(search_string)
    
    ; Parse the filenames to see if they are consistent with query
    cut_filenames = strarr(n_elements(search_results))
    file_juls = dblarr(n_elements(search_results))
    
    if n_elements(search_results) eq 1 and search_results(0) eq '' then begin
      local_flist = ''
      file_flag = 1
    endif else begin

      for i = 0, n_elements(search_results)-1 do begin
        slash = strpos(search_results(i), path_sep(), /reverse_search)
        cut_filenames(i) = strmid(search_results(i), slash+1, strlen(search_results(i))-slash-1)
        split_string = strsplit(cut_filenames(i), '_', /extract)
        date_string = split_string(2)
        date_array = strsplit(date_string, '-', /extract)
        yrtem = double(date_array(0))
        motem = double(date_array(1))
        dytem = double(date_array(2))
        hrtem = double(date_array(3))
        mttem = double(date_array(4))
      
        secstring = date_array(5)
        secsplit = strsplit(secstring, '.', /extract)
      
        sctem = double(secsplit(0))
      
        file_juls(i) = julday(motem, dytem, yrtem, 0, 0, 0)
      endfor
    
      loc_match = where(file_juls ge start_jul and file_juls le end_jul, count_match)
    
      if count_match gt 0 then begin
        local_flist = search_results(loc_match)
      endif else begin
        local_flist = ''
        file_flag = 1
      endelse
    endelse

  endif else begin
    local_flist = ''
    file_flag = 1
  endelse

end