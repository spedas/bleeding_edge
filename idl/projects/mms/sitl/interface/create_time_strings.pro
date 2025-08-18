; Program to take the time stamp and turn it into a string.
; Assumes times are in TAI time.

pro create_time_strings, times, timestrings

;load_leap_table2, leaps, juls_unix
;
;JULs = Juls_unix + leaps/double(86400)

timestrings = strarr(n_elements(times))

unix_times = mms_tai2unix(times)

for i = 0, n_elements(times)-1 do begin
  
;  time_jul = times(i)/double(86400) + julday(1, 1, 1958, 0, 0, 0)
;  
;  loc_greater = where(time_jul gt juls, count_greater)
;  
;  last_loc = loc_greater(count_greater-1)
;  current_leap = leaps(last_loc)
;  
;  time_utc_sec = floor(times(i) - current_leap + 9)

  time_unix = unix_times(i)
  
  ;time_jul = time_utc_sec/(86400D) + julday(1, 1, 1958, 0, 0, 0)
  time_jul = time_unix/(86400D) + julday(1, 1, 1970, 0, 0, 0)
  
  caldat, time_jul, cmonth, cday, cyear, chour, cminute, csecond
  cmostr = string(cmonth, format = '(i02)')
  cdaystr = string(cday, format = '(i02)')
  cyearstr = string(cyear, format = '(i4)')
  chourstr = string(chour, format = '(i02)')
  cminstr = string(cminute, format = '(i02)')

  csecstr = string(csecond, format = '(i02)')
  
  timestrings(i) = cyearstr+'-'+cmostr+'-'+cdaystr+'/'+chourstr+':'+$
    cminstr+':'+csecstr + ' '
  
endfor

end