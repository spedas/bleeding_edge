pro get_mms_sitl_selections_ut::setup
  compile_opt strictarr
  url = get_mms_sitl_connection(host='sdc-web1', port='80', auth='0', /rebuild)
  
end


function get_mms_sitl_selections_ut::test_no_args
  compile_opt strictarr
  ;test latest with no args
  status = get_mms_sitl_selections()
  assert, status eq 0, 'Error returned when getting latest data.'
  
  return, 1
end


function get_mms_sitl_selections_ut::test_filename_only
  compile_opt strictarr
  ;test use of filename alone
  status = get_mms_sitl_selections(filename="sitl_selections_2015-05-08-20-47-22.sav")
  assert, status eq 0, 'Error returned when searching by file name only'

  return, 1
end


function get_mms_sitl_selections_ut::test_nonexistent_file
  compile_opt strictarr
  ;test nonexistent file
  print, 'Error expected'
  status = get_mms_sitl_selections(filename="foo")
  assert, status eq -1, 'Nonexistent file returned data'
  return, 1
end


function get_mms_sitl_selections_ut::test_multiple_files
  compile_opt strictarr
  ;test multiple files
  status = get_mms_sitl_selections(filename=["sitl_selections_2015-05-08-20-47-22.sav", "abs_selections_2015-05-08-00-01-27.sav"])
  assert, status eq 0, 'Multiple files returned unexpected results'
  
  return, 1
end


function get_mms_sitl_selections_ut::test_start_date
  compile_opt strictarr
  ;test start_date
  status = get_mms_sitl_selections(start_time='2015-05-12')  ;YYYY-MM-DD
  assert, status eq 0, 'Error encountered when testing start date'
  
  return, 1
end


function get_mms_sitl_selections_ut::test_end_date
  compile_opt strictarr
  ;test end_date
  status = get_mms_sitl_selections(end_time='2015-05-15')
  assert, status eq 0, 'Error encountered when testing end date'
  
  return, 1
end


function get_mms_sitl_selections_ut::test_date_range
  compile_opt strictarr
  ;test date range
  status = get_mms_sitl_selections(start_time='2015-05-08', end_time='2015-05-14')
  assert, status eq 0, 'Error encountered when testing date ranges'
  
  return, 1
end


pro get_mms_sitl_selections_ut__define
  compile_opt strictarr
  
  define = { get_mms_sitl_selections_ut, inherits MGutTestCase }
end