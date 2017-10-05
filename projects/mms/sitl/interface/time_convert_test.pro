; Code to test my new time convsersion
; 

; Create some TAI tags

start_jul = julday(4, 1, 1980, 0, 0)
stop_jul = julday(4, 2, 1980, 0, 0)

start_unix = double(86400) * (start_jul - julday(1, 1, 1970, 0, 0, 0 ))
stop_unix = double(86400) * (stop_jul - julday(1, 1, 1970, 0, 0, 0 ))

times_unix = [long(start_unix), long(stop_unix)]

times_tai = mms_unix2tai(times_unix)

times_unix2 = mms_tai2unix(times_tai)

end
