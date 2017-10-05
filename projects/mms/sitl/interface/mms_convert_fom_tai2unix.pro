pro mms_convert_fom_tai2unix, tai_fomstr, unix_fomstr, start_string

  ;------------------------------------------------------------------------------
  ; Load the leap table, get the first
  ;------------------------------------------------------------------------------
  
;  load_leap_table2, leaps, Juls
;  
;  table_length = n_elements(leaps)
;  
;  ; Add leap seconds to timestamps to convert to TAI (Need to double check that
;  ; I subtracted properly)
;  Juls_TAI = Juls + leaps/double(86400)
;  
;  ; Convert NTP to Juls
;
;  start_tai_jul = double(tai_fomstr.cyclestart)/double(86400) + julday(1, 1, 1958, 0, 0, 0)
;  
;  loc_greater = where(start_tai_jul gt juls_tai, count_greater)
;  
;  last_loc = loc_greater(count_greater-1)
;  current_leap = leaps(last_loc) 
  
  ;------------------------------------------------------------------------------
  ; Convert the "cyclestart" variable
  ;------------------------------------------------------------------------------
  
  ;FDWHACK - +9 to agree with SPICE
  
;  cyclestart_utc_sec = double(tai_fomstr.cyclestart) - current_leap + 9
;  cyclestart_juls = cyclestart_utc_sec/double(86400) + julday(1, 1, 1958, 0, 0, 0)
;  cyclestart_unix = double(86400)*(cyclestart_juls - julday(1, 1, 1970, 0, 0, 0))
  
  cyclestart_unix = mms_tai2unix(tai_fomstr.cyclestart)
  cyclestart_juls = cyclestart_unix/double(86400) + julday(1, 1, 1970, 0, 0, 0)
  
  caldat, cyclestart_juls, cmonth, cday, cyear, chour, cminute, csecond
  
  if cmonth lt 10 then begin
    cmostr = '0'+string(cmonth, format = '(I1)')
  endif else begin
    cmostr = string(cmonth, format = '(I2)')
  endelse

  if cday lt 10 then begin
    cdaystr = '0'+string(cday, format = '(I1)')
  endif else begin
    cdaystr = string(cday, format = '(I2)')
  endelse

  if chour lt 10 then begin
    chourstr = '0'+string(chour, format = '(I1)')
  endif else begin
    chourstr = string(chour, format = '(I2)')
  endelse
  
  if cminute lt 10 then begin
    cminstr = '0'+string(cminute, format = '(I1)')
  endif else begin
    cminstr = string(cminute, format = '(I2)')
  endelse  
  
  if csecond lt 10 then begin
    csecstr = '0'+string(csecond, format = '(10F0)')
  endif else begin
    csecstr = string(csecond, format = '(10F0)')
  endelse
  
  cyearstr = string(cyear, format = '(I4)')
  
  ; create a tplot timestring for cyclestart
  start_string = cyearstr+'-'+cmostr+'-'+cdaystr+'/'+chourstr+':'+$
    cminstr+':'+csecstr
    
  ;------------------------------------------------------------------------------
  ; Create the modified structure
  ;------------------------------------------------------------------------------
  
  unix_fomstr = tai_fomstr
  
  unix_fomstr.cyclestart = cyclestart_unix
  
  ;timestamps_unix = cyclestart_unix + dindgen(n_elements(unix_fomstr.timestamps))*10
  
  timestamps_unix = mms_tai2unix(unix_fomstr.timestamps)
  
  ;str_element, unix_fomstr, 'unix_fomstr.timestamps', timestamps_unix, /add_replace
  
  str_element, unix_fomstr, 'timestamps', /delete  
  str_element, unix_fomstr, 'timestamps', timestamps_unix, /add
  
end
