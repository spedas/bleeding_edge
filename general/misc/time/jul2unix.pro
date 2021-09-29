; This routine converts Julian days into UNIX time

function jul2unix, jd, time_string = time_string

  CALdat, jd, month, day, year, hour, minute, second
  np = n_elements (jd)
  Time_string = strarr(np)

  for K = 0, np-1 do time_string[k] = $
     strcompress (string  (year [k]),/rem)+ '-' + $
     strcompress (string  (month [k]),/rem) + '-' + $
     strcompress (string  (day [k]),/rem) + '/' +$
     strcompress (string  (hour [k]),/rem) + ':' + $
     strcompress (string  (minute [k]),/rem)+ ':' + $
     strcompress (string  (second[k]),/rem)

  return, time_double (time_string)
end
