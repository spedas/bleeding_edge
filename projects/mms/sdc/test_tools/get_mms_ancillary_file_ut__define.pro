pro get_mms_ancillary_file_ut::setup
  compile_opt strictarr
  url = get_mms_sitl_connection(host='sdc-web1', port='80', auth='0', /rebuild)

end


function get_mms_ancillary_file_ut::test_filename_only
  compile_opt strictarr
  ;test use of filename alone
  file_name='MMS1_PREDEPH_2015167_2015182.V00'
  status = get_mms_ancillary_file(filename=file_name)
  assert, status eq 0, 'Error encountered when returning file'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_nonexistent_file
  compile_opt strictarr
  print, 'Error Expected'
  ;test nonexistent file
  status = get_mms_ancillary_file(filename="foo")
  assert, status eq -1, 'Nonexistent File Returned Data'

  return, 1
end


function get_mms_ancillary_file_ut::test_multiple_files
  compile_opt strictarr
  ;test multiple files
  status = get_mms_ancillary_file(filename=['MMS1_DEFERR_2015159_2015160.V00', 'MMS1_PREDEPH_2015167_2015182.V00'])
  assert, status eq 0, 'Error Encountered When Testing Multiple Files'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_sc_id_only
  compile_opt strictarr
  ;test scID only
  status = get_mms_ancillary_file(sc_id='mms4', start_date='2015-06-10', end_date='2015-06-11')
  assert, status eq 0, 'Error Encountered When Testing scID'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_multiple_sc_ids
  compile_opt strictarr
  ;test multiple sc_ids
  status = get_mms_ancillary_file(sc_id=['mms3','mms4'], start_date='2015-03-13', end_date='2015-03-14')
  assert, status eq 0, 'Error Encountered When Testing Multiple scIDs'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_single_product
  compile_opt strictarr
  ;test product
  ;DEFQ type has fewer files than other types
  status = get_mms_ancillary_file(product='DEFQ', start_date='2015-04-15', end_date='2015-05-20')
  assert, status eq 0, 'Error Encountered when testing product'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_multiple_product
  compile_opt strictarr
  ;test multiple product
  ;DEFQ and PREDQ have fewer files than other types
  status = get_mms_ancillary_file(product=['DEFQ','PREDQ'], start_date='2015-04-15', end_date='2015-05-20')
  assert, status eq 0, 'Error encountered when testing multiple products'
  
  return, 1
end



function get_mms_ancillary_file_ut::test_one_of_each
  compile_opt strictarr
  ;test one of each
  status = get_mms_ancillary_file(sc_id='mms4', product='PREDATT')
  assert, status eq 0, 'Error encountered while testing sc_id and product'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_mix
  compile_opt strictarr
  ;test a mix
  status = get_mms_ancillary_file(sc_id=['mms1','mms3'], product=['PREDEPH','DEFERR'], start_date='2015-04-10', end_date='2015-05-01')
  assert, status eq 0, 'Error encountered when testing multiple query arguments'

  return, 1
end


function get_mms_ancillary_file_ut::test_matching_constraints
  compile_opt strictarr
  ;test filename with matching constraints
  status = get_mms_ancillary_file(filename="MMS1_DEFEPH_2015144_2015145.V00", sc_id='mms1')
  assert, status eq 0, 'Matching constraints Returned Unexpected Data'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_conflicting_constraints
  compile_opt strictarr
  print, 'No Results Expected'
  ;test filename with conflicting constraints
  status = get_mms_ancillary_file(filename="MMS1_DEFERR_2015159_2015160.V00", sc_id='mms2')
  assert, status eq -1, 'Conflicting constraints Returned Data'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_relative_path
  compile_opt strictarr
  ;test local relative path
  test_dir = 'testdir'
  file_mkdir, test_dir
  status = get_mms_ancillary_file(filename='MMS1_DEFERR_2015159_2015160.V00', local_dir=test_dir)
  file_delete, test_dir, /recursive
  assert, status eq 0, 'Error in testing relative path'
  ;Unable to save result to subdir
  
  return, 1
end


function get_mms_ancillary_file_ut::test_start_date
  compile_opt strictarr
  ;test start_date
  ;choose start_date to be 20 days ago
  start_date = systime(/julian) - 20
  start_date_str =  tai_to_date_str(start_date)
  status = get_mms_ancillary_file(start_date=start_date_str, sc_id='mms1', product='DEFERR')
  assert, status eq 0, 'Error encountered when testing start date'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_end_date
  compile_opt strictarr
  ;test end_date
  status = get_mms_ancillary_file(end_date='2015-03-26', sc_id='mms2', product='DEFERR')
  status = get_mms_ancillary_file(end_date='2015-04-03', sc_id='mms2', product='PREDATT')
  assert, status eq 0, 'Error encountered when testing end date'
  
  return, 1
end


function get_mms_ancillary_file_ut::test_date_range
  compile_opt strictarr
  ;test date range
  status = get_mms_ancillary_file(start_date='2015-06-13', end_date='2015-06-14', sc_id='mms4', product='DEFATT')
  status = get_mms_ancillary_file(start_date='2015-04-11', end_date='2015-04-14', sc_id='mms1', product='DEFEPH')
  assert, status eq 0, 'Error encountered when testing date range'
  
  return, 1
end

pro get_mms_ancillary_file_ut__define
  compile_opt strictarr

  define = { get_mms_ancillary_file_ut, inherits MGutTestCase }
end