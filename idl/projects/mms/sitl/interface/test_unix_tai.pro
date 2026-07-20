pro test_unix_tai

   ; Compare different methods of converting Unix times to TAI values and back.
   ; The test interval shows the behavior surrounding the leap second added at the end of 2016.
   start_utc = '2016-12-31/23:59:00'
   start_unix = time_double(start_utc)
   print,'     unix_in        utc_in           tai (mms)   tai (spd)   unix_out   UTC out (mms)         unix_out    UTC out (spd)'
   for i=0,70 do begin
       unix_time = start_unix+i
       unix_string = time_string(unix_time)
       ; Convert to tai using old MMS and updated SPD algorithm. mms leap seconds are 1 sec too late
       unix2tai = mms_unix2tai(unix_time)
       unix2tai_spd = spd_unix2tai(unix_time)
       ; Round trip the mms and spd TAI times back to Unix times and UTC strings, using the original MMS and new SPD methods.
       ; mms leap seconds are subtracted 35 sec early.
       tai2unix = mms_tai2unix(unix2tai)
       tai2unix_str = time_string(tai2unix)
       tai2unix_spd  = spd_tai2unix(unix2tai_spd)
       tai2unix_spd_str = time_string(tai2unix_spd)
       print,ulong(unix_time), " ", unix_string, " ",unix2tai, ulong(unix2tai_spd), ulong(tai2unix), " ", tai2unix_str, " ", ulong(tai2unix_spd), " ", tai2unix_spd_str  
   endfor
end