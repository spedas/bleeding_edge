;+
; 
; 
;-
function test_unix_to_tt2000_vect_sample
  dprint, dlevel=1, 'Testing using sample data'
  result = 0; 0 indicates failure
  data = read_csv("C:\Users\DC\Documents\Projects\Tasks\261\mag_DASI_Virginia_2025_08_05.csv")
  tstr = time_string(data.field1)
  t = time_double(tstr)
  tt2000_new = unix_to_tt2000_vect(t+1)
  for k=0, n_elements(t)-1 do append_array, tt2000_old, unix_to_tt2000(t[k]+1)
  if ~array_equal(tt2000_new,tt2000_old) then dprint, dlevel=1, 'Sample Data Test Failed' else result = 1
  return, result
end

function test_unix_to_tt2000_vect_varyingls
  dprint, dlevel=1, 'Testing using varying leap seconds post 2000'
  result = 0; 0 indicates failure
  
  ref_leap_date = 1341100800.0000000
  t = double([0.0:86399.0])+ref_leap_date-double(86400.0/2.0) ; the leap second date is about halfway through the time array 
  
  tt2000_new = unix_to_tt2000_vect(t+1)
  for k=0, n_elements(t)-1 do append_array, tt2000_old, unix_to_tt2000(t[k]+1)
  if ~array_equal(tt2000_new,tt2000_old) then dprint, dlevel=1, 'Varying Leap Second Test Failed' else result = 1
  return, result
end

function test_unix_to_tt2000_vect_pre2000
  dprint, dlevel=1, 'Testing pre2000 times'
  result = 0; 0 indicates failure

  t = double([0.0:86399.0])+time_double('2000-01-01/12:00:00')-double(86401.0) ; the dates end right before jan 1 2000

  tt2000_new = unix_to_tt2000_vect(t+1)
  for k=0, n_elements(t)-1 do append_array, tt2000_old, unix_to_tt2000(t[k]+1)
  if ~array_equal(tt2000_new,tt2000_old) then dprint, dlevel=1, 'Pre2000 Test Failed' else result = 1
  return, result
end

function test_unix_to_tt2000_vect_pre2000_varyingls
  dprint, dlevel=1, 'Testing pre 2000 times with varying leap seconds'
  result = 0; 0 indicates failure
  
  ref_leap_date = 915148800.00000000
  t = double([0.0:86399.0])+ref_leap_date-double(86400.0/2.0) ; the leap second date is about halfway through the time array

  tt2000_new = unix_to_tt2000_vect(t+1)
  for k=0, n_elements(t)-1 do append_array, tt2000_old, unix_to_tt2000(t[k]+1)
  if ~array_equal(tt2000_new,tt2000_old) then dprint, dlevel=1, 'Varying Leap Second pre2000 Test Failed' else result = 1
  return, result
end

function test_unix_to_tt2000_vect_pre2000_varyingls_neglsdate
  dprint, dlevel=1, 'Testing pre2000 dates where epoch is negative with varying leap seconds'
  result = 0; 0 indicates failure

  ref_leap_date = -157766400.00000000
  t = double([0.0:86399.0])+ref_leap_date-double(86400.0/2.0) ; the leap second date is about halfway through the time array

  tt2000_new = unix_to_tt2000_vect(t+1)
  for k=0, n_elements(t)-1 do append_array, tt2000_old, unix_to_tt2000(t[k]+1)
  if ~array_equal(tt2000_new,tt2000_old) then dprint, dlevel=1, 'Varying Leap Second negative leapsecond date Test Failed' else result = 1
  return, result
end

function test_unix_to_tt2000_vect_trans2000
  dprint, dlevel=1, 'Testing data that spans before and after the 01/01/2000'
  result = 0; 0 indicates failure

  ref_leap_date = 946728000.00000000
  t = double([0.0:86399.0])+ref_leap_date-double(86400.0/2.0) ; the leap second date is about halfway through the time array

  tt2000_new = unix_to_tt2000_vect(t+1)
  for k=0, n_elements(t)-1 do append_array, tt2000_old, unix_to_tt2000(t[k]+1)
  if ~array_equal(tt2000_new,tt2000_old) then dprint, dlevel=1, 'Y2000 Interval Test Failed' else result = 1
  return, result
end

function test_unix_to_tt2000_vect ;variables?
  ; format of data:
  ; • double array
  ; • each element is number of seconds after 1970
  ; • time cadence is 1 second
  ; • each array spans 24 hours (86400 seconds)
  ; note: be careful with data types, int overflows are common with numbers of this size  
  
  ; test with sample data file
  t_1 = test_unix_to_tt2000_vect_sample()
  ; test varying leap seconds over interval
  t_2 = test_unix_to_tt2000_vect_varyingls()
  ; test before year 2000
  t_3 = test_unix_to_tt2000_vect_pre2000()
  ; test varying leap seconds over interval before year 2000
  t_4 = test_unix_to_tt2000_vect_pre2000_varyingls()
  ; test with interval containing 01/01/2000
  t_5 = test_unix_to_tt2000_vect_trans2000()
  ; test varying leap seconds over interval before year 2000 where leap second date is negative
  t_6 = test_unix_to_tt2000_vect_pre2000_varyingls_neglsdate()
  
  dprint, dlevel=1, 'Sucess rate: '+string(100.00*((t_1+t_2+t_3+t_4+t_5+t_6)/6.0) )
end