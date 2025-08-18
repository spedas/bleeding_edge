; Here's a test for the new fetch
; 

start_jul = julday(11, 23, 2013, 0, 0, 0)
stop_jul = julday(11, 26, 2013, 0, 0, 0)

start_time_unix = 86400D * (start_jul - julday(1, 1, 1970, 0, 0, 0 ))
stop_time_unix = 86400D * (stop_jul - julday(1, 1, 1970, 0, 0, 0 ))

local_dir = '/Users/frederickwilder/'

mms_get_abs_fom_files, local_dir, local_flist, start_time_unix, stop_time_unix, pw_flag, pw_message

end