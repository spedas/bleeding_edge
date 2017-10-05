pro convert_time_stamp, cyclestart, times, timestrings

;  load_leap_table2, leaps, juls_unix
;
;  ; Add leap seconds to timestamps to convert to TAI (Need to double check that
;  ; I subtracted properly)
;  JULs = Juls_unix + leaps/double(86400)
;  
;  start_jul = cyclestart/double(86400) + julday(1, 1, 1958, 0, 0, 0)
;  
;  loc_greater = where(start_jul gt juls, count_greater)
;  
;  last_loc = loc_greater(count_greater-1)
;  current_leap = leaps(last_loc)
;
;  ; Convert cyclestart to UTC format FDW HACK - +9 adjusts for SPICE calculations 
;  cyclestart_utc_sec = floor(cyclestart - current_leap + 9)
;  times_utc_sec = cyclestart_utc_sec + times*10
;  times_jul = times_utc_sec/(86400D) + julday(1, 1, 1958, 0, 0, 0)

  cyclestart_unix = mms_tai2unix(cyclestart)
  ;times_utc_sec = cyclestart_unix + times*10
  temp = times*10
  times_utc_sec = temp+replicate(cyclestart_unix, n_elements(temp))
  times_jul = times_utc_sec/(86400D) + julday(1, 1, 1970, 0, 0, 0)
  timestrings = strarr(n_elements(times_jul))
  
  
  
  for i = 0, n_elements(times_jul)-1 do begin
    caldat, times_jul(i), cmonth, cday, cyear, chour, cminute, csecond
    cmostr = string(cmonth, format = '(i02)')
    cdaystr = string(cday, format = '(i02)')
    cyearstr = string(cyear, format = '(i4)')
    chourstr = string(chour, format = '(i02)')
    cminstr = string(cminute, format = '(i02)')
    
    if csecond lt 10 then begin
      csecstr = '0'+string(csecond, format = '(10F0)')
    endif else begin
      csecstr = string(csecond, format = '(10F0)')
    endelse
    
    ; create a tplot timestring for cyclestart
    timestrings(i) = cyearstr+'-'+cmostr+'-'+cdaystr+'/'+chourstr+':'+$
      cminstr+':'+csecstr + ' '
  endfor
 
 
end