PRO test_fomtime

  local_dir = '/Users/frederickwilder/'
  get_latest_fom_from_soc, local_dir, fom_file, error_flag, error_message
  restore,fom_file
  print, '=== FOM from SOC ==='
  print, fomstr.timestamps[0:5]
  
  mms_convert_fom_tai2unix, fomstr, unix_fomstr, start_string
  mms_convert_fom_unix2tai, unix_fomstr, tai_fomstr
  print, '=== FOM after time conversion ==='
  print, tai_fomstr.timestamps[0:5]
  
  print, start_string
  
  ; try it with my other rountines
  
;  unix_times = mms_tai2unix(fomstr.timestamps[0:5])
;  tai_times = mms_unix2tai(unix_times)
;  
;  print, tai_times

END
