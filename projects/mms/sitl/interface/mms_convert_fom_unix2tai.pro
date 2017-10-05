pro mms_convert_fom_unix2tai, unix_fomstr, tai_fomstr

  ;------------------------------------------------------------------------------
  ; Load the leap table, get the first
  ;------------------------------------------------------------------------------
  
;  load_leap_table2, leaps, juls
;  
;  table_length = n_elements(leaps)
;  
;  start_unix_jul = unix_fomstr.cyclestart/double(86400) + julday(1, 1, 1970, 0, 0, 0)
;  
;  loc_greater = where(start_unix_jul gt juls, count_greater)
;  
;  last_loc = loc_greater(count_greater-1)
;  current_leap = leaps(last_loc)

  ;------------------------------------------------------------------------------
  ; Convert the cyclestart
  ;------------------------------------------------------------------------------
  
  ; FDWHACK -9 is to be consistent with SPICE
  
;  cycle_start_utc = double(86400)*(start_unix_jul - julday(1, 1, 1958, 0, 0, 0))
;  cycle_start_tai = cycle_start_utc + current_leap - 9
  
  cycle_start_tai = mms_unix2tai(unix_fomstr.cyclestart)
  
  ;------------------------------------------------------------------------------
  ; Create the modified structure
  ;------------------------------------------------------------------------------
  
  tai_fomstr = unix_fomstr
  
  tai_fomstr.cyclestart = cycle_start_tai
  
  ; Lets create new_timetags
  
  ;timestamps_tai = cycle_start_tai + dindgen(n_elements(tai_fomstr.timestamps))*10
  
  timestamps_tai = mms_unix2tai(tai_fomstr.timestamps)
  
  str_element, tai_fomstr, 'timestamps', /delete
  str_element, tai_fomstr, 'timestamps', ulong(timestamps_tai), /add


end