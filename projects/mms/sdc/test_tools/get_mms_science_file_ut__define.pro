pro get_mms_science_file_ut::setup
  compile_opt strictarr
  url = get_mms_sitl_connection(host='sdc-web1', port='80', auth='0', /rebuild)
  
end


function get_mms_science_file_ut::test_filename_only
  compile_opt strictarr
  ;test use of filename alone
  status = get_mms_science_file(filename="mms2_dsp_srvy_l1a_177_20150523_v0.3.0.cdf")
  assert, status eq 0, 'Filename returned unexpected data'

  return, 1
end


function get_mms_science_file_ut::test_nonexistent_file
  compile_opt strictarr
  ;test nonexistent file
  print, 'Error expected'
  status = get_mms_science_file(filename="foo")
  assert, status eq -1, 'Nonexistent file returned data'

  return, 1
end


function get_mms_science_file_ut::test_multiple_files
  compile_opt strictarr
  ;test multiple files
  status = get_mms_science_file(filename=["mms2_dsp_srvy_l1a_177_20150523_v0.3.0.cdf", "mms3_dsp_srvy_l1b_178_20150524_v1.1.1.cdf"])
  assert, status eq 0, 'Multiple files returned unexpected results'

  return, 1
end


function get_mms_science_file_ut::test_one_valid
  compile_opt strictarr
  ;test multiple files, all but one invalid
  status = get_mms_science_file(filename=["mms3_dsp_srvy_l1b_178_20150524_v1.1.1.cdf", "foo", "bar"], local_dir=test_dir)
  ;status is 0 if at least one filename is valid
  assert, status eq 0, 'Error during download of valid and invalid files'
  ;got single file
  ;TODO: print error, but hard to know in general (e.g. with other params) what the expected number is

  return, 1
end


function get_mms_science_file_ut::test_multiple_valid
  compile_opt strictarr
  ;test multiple files, more than one valid
  status = get_mms_science_file(filename=["mms1_scm_comm_l1a_scmcomm_20150524_v0.8.0.cdf", "mms3_dsp_srvy_l1b_178_20150524_v1.1.1.cdf" ,"foo"], local_dir=test_dir)
  ;status is 0 if at least one filename is valid
  assert, status eq 0, 'unexpected data returned'
  
  return, 1
end


function get_mms_science_file_ut::test_single_sc_id
  compile_opt strictarr
  ;test sc_id only
  status = get_mms_science_file(sc_id='mms1', start_date='2015-03-13', end_date='2015-03-15')
  assert, status eq 0, 'Error during download with single scID'

  return, 1
end


function get_mms_science_file_ut::test_multiple_sc_ids
  compile_opt strictarr
  ;test multiple sc_ids
  status = get_mms_science_file(sc_id=['mms1','mms3'], start_date='2015-03-13', end_date='2015-03-15')
  assert, status eq 0, 'Error during download with multiple scIDs'

  return, 1
end


function get_mms_science_file_ut::test_single_instrument_id
  compile_opt strictarr
  ;test instrument_id
  status = get_mms_science_file(instrument_id='mec', start_date='2015-03-13', end_date='2015-03-15')
  assert, status eq 0, 'Single ID returned unexpected results' 

  return, 1
end


function get_mms_science_file_ut::test_multiple_instrument_id
  compile_opt strictarr
  ;test multiple instrument_id
  status = get_mms_science_file(instrument_id=['dsp','scm'], start_date='2015-03-16', end_date='2015-03-16')
  assert, status eq 0, 'Multiple IDs returned unexpected results'

  return, 1
end


function get_mms_science_file_ut::test_single_data_rate_mode
  compile_opt strictarr
  ;test data_rate_mode
  status = get_mms_science_file(data_rate_mode='srvy', instrument_id=['afg','edp'], start_date='2015-06-08', end_date='2015-06-08')
  assert, status eq 0, 'Single data rate mode returned unexpected results' 

  return, 1
end


function get_mms_science_file_ut::test_multiple_data_rate_mode
  compile_opt strictarr
  ;test multiple data_rate_mode
  status = get_mms_science_file(data_rate_mode=['fast','slow'], instrument_id='afg', start_date='2015-06-18', end_date='2015-06-18')
  assert, status eq 0, 'Multiple data rate modes returned unexpected results'

  return, 1
end


function get_mms_science_file_ut::test_single_data_level
  compile_opt strictarr
  ;test data_level
  status = get_mms_science_file(data_level='ql', start_date='2015-03-21', end_date='2015-03-21')
  assert, status eq 0, 'Single data level returned unexpected results'

  return, 1
end


function get_mms_science_file_ut::test_multiple_data_level
  compile_opt strictarr
  ;test multiple data_level
  status = get_mms_science_file(data_level=['ql','l1a'], data_rate_mode='fast', start_date='2015-05-15', end_date='2015-05-15')
  assert, status eq 0, 'Multiple data levels returned unexpected results'

  return, 1
end


function get_mms_science_file_ut::test_one_of_each
  compile_opt strictarr
  ;test one of each
  status = get_mms_science_file(sc_id='mms1', instrument_id='afg', data_rate_mode='srvy', data_level='ql', start_date='2015-03-25', end_date='2015-03-26')
  assert, status eq 0, 'Multiple query arguments returned unexpected results'

  return, 1
end


function get_mms_science_file_ut::test_mix
  compile_opt strictarr
  ;test a mix
  status = get_mms_science_file(sc_id=['mms1','mms3'], instrument_id=['afg', 'edp'], data_rate_mode=['fast','comm'], data_level=['l1b','l1a'], start_date='2015-03-16', end_date='2015-03-16')
  assert, status eq 0, 'Multiple arguments for each query parameter returned unexpected results'

  return, 1
end


function get_mms_science_file_ut::test_matching_constraints
  compile_opt strictarr
  ;test filename with matching constraints
  status = get_mms_science_file(filename="mms3_dsp_srvy_l1b_178_20150524_v1.1.1.cdf", sc_id='mms3')
  assert, status eq 0, 'Matching constraints returned unexpected results'

  return, 1
end


function get_mms_science_file_ut::test_conflicting_constraints
  compile_opt strictarr
  ;test filename with conflicting constraints
  print, 'No results expected'
  status = get_mms_science_file(filename="mms3_dsp_srvy_l1b_178_20150524_v1.1.1.cdf", sc_id='mms1')
  assert, status eq -1, 'Conflicting constraints returned unexpected data'

  return, 1
end


function get_mms_science_file_ut::test_relative_path
  compile_opt strictarr
  ;test local relative path
  sub_dir='subdir'
  file_mkdir, sub_dir
  status = get_mms_science_file(filename="mms3_dsp_srvy_l1b_178_20150524_v1.1.1.cdf", local_dir='subdir')
  file_delete, sub_dir, /recursive
  assert, status eq 0, 'Unexpected results in saving to relative path'

  return, 1
end


function get_mms_science_file_ut::test_absolute_path
 compile_opt strictarr
  ;test local absolute path
  caldat, systime(/julian), month, day, year, hour, minute, second
  timestamp = strcompress((string(year) +'-'+string(month)+'-'+string(day)+'-'+string(hour) +'-'+string(minute)+'-'+string(second)), /remove_all)
  test_dir = '/tmp/' + timestamp
  file_mkdir, test_dir
  status = get_mms_science_file(filename="mms3_dsp_srvy_l1b_178_20150524_v1.1.1.cdf", local_dir=test_dir)
  file_delete, test_dir, /recursive
  assert, status eq 0, 'Unexpected results in saving to absolute path'

  return, 1
end


function get_mms_science_file_ut::test_path_without_permission
  compile_opt strictarr
  ;test local path without permission
  test_dir = 'no_permissions'
  file_mkdir, test_dir
  file_chmod, test_dir, U_WRITE=0, G_WRITE=0, O_WRITE=0
  print, 'Error expected'
  status = get_mms_science_file(filename="mms3_dsp_srvy_l1b_178_20150524_v1.1.1.cdf", local_dir=test_dir)
  file_delete, test_dir, /recursive
  assert, status eq -1, 'Path without permission returned unexpected results' 
  return, 1
end


function get_mms_science_file_ut::test_start_date
  compile_opt strictarr
  ;test start_date. Assumes files have been created in last 4 days.
  start_date = systime(/JULIAN)-4
  start_date_str = tai_to_date_str(start_date) 
  status = get_mms_science_file(start_date=start_date_str, sc_id='mms1', $
    instrument_id = 'dsp', data_level = 'l2', descriptor = 'epsd', data_rate_mode='slow')
  assert, status eq 0, 'Start date returned unexpected results'
  
  return, 1
end


function get_mms_science_file_ut::test_end_date
  compile_opt strictarr
  ;test end_date
  status = get_mms_science_file(end_date='2015-03-13', sc_id='mms1')
  assert, status eq 0, 'End date returned unexpected results' 
  
  return, 1
end


function get_mms_science_file_ut::test_date_range
  compile_opt strictarr
  ;test date range
  status = get_mms_science_file(start_date='2015-03-13', end_date='2015-03-14', sc_id='mms1')
  assert, status eq 0, 'Date range returned unexpected results' 
  
  return, 1
end


function get_mms_science_file_ut::test_range_for_same_date
  compile_opt strictarr
  ;test date range for same date
  status = get_mms_science_file(start_date='2015-03-14', end_date='2015-03-14', sc_id='mms1')
  assert, status eq 0, 'Date range for same date returned unexpected results' 

  return, 1
end


pro get_mms_science_file_ut__define
  compile_opt strictarr
  
  define = { get_mms_science_file_ut, inherits MGutTestCase }
end