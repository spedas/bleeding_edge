; Test of FPI calibration submission
; 

local_dir = '/Users/frederickwilder/'
local_dir = '/Users/moka/'

start_jul = julday(2, 7, 2009, 2, 0, 0)
stop_jul = julday(2, 7, 2009, 2, 0, 50)

start_unix = double(86400) * (start_jul - julday(1, 1, 1970, 0, 0, 0 ))
stop_unix = double(86400) * (stop_jul - julday(1, 1, 1970, 0, 0, 0 ))

start_tai = mms_unix2tai(start_unix)
stop_tai = mms_unix2tai(stop_unix)

sourceid = 'fwilder(FPITEST)'

fom = 150

mms_check_fpi_calibration_segment, start_tai, stop_tai, fom, sourceid, $
                                   error_flags, error_msg, yellow_warning_flags, $
                                   yellow_warning_msg, orange_warning_flags, $
                                   orange_warning_msg
                                   
; There will be errors

stop

; Now try to submit, there will still be errors

mms_submit_fpi_calibration_segment, start_tai, stop_tai, fom, sourceid, local_dir, $
                                    error_flags, error_msg, yellow_warning_flags, $
                                    yellow_warning_msg, orange_warning_flags, $
                                    orange_warning_msg, problem_status

stop

; Fix seglengths and submit with low fom

new_stop = julday(2, 7, 2009, 2, 0, 30)
new_stop_unix = double(86400) * (new_stop - julday(1, 1, 1970, 0, 0, 0 ))
stop_tai = mms_unix2tai(new_stop_unix)

mms_submit_fpi_calibration_segment, start_tai, stop_tai, fom, sourceid, local_dir, $
                                    error_flags, error_msg, yellow_warning_flags, $
                                    yellow_warning_msg, orange_warning_flags, $
                                    orange_warning_msg, problem_status, /warning_override

stop

; Now we use appropriate fom and submit without errors or warnings.

fom = 215

mms_submit_fpi_calibration_segment, start_tai, stop_tai, fom, sourceid, local_dir, $
  error_flags, error_msg, yellow_warning_flags, $
  yellow_warning_msg, orange_warning_flags, $
  orange_warning_msg, problem_status

end