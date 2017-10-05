PRO test_backstructure

  ; CASE 1
  tspan = time_double(['2009-02-06','2009-02-07'])
  mms_get_back_structure, tspan[0], tspan[1], BAKStr, pw_flag, pw_message
  ans = (pw_flag) ? pw_message : 'OK'
  print, ans
  stop
  
  ; CASE 2
  tspan = time_double(['2009-02-01','2009-02-05'])
  mms_get_back_structure, tspan[0], tspan[1], BAKStr, pw_flag, pw_message
  ans = (pw_flag) ? pw_message : 'OK'
  print, ans
  stop
END
