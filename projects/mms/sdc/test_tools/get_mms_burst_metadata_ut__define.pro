pro get_mms_burst_metadata_ut::setup
  compile_opt strictarr
  url = get_mms_sitl_connection(host='sdc-web2', port='8080', auth='0', /rebuild)
  
end

;SEGMENTID=1013, 1812820840 - 1812821430 (2015-06-12T17:20:05 - 2015-06-12T17:29:55)
;time selections are inclusive on the low end and exclusive on the high end

function get_mms_burst_metadata_ut::test_mms1_time_range
  compile_opt strictarr
  data = get_mms_burst_metadata(1812820840, 1812821431, sc_id='mms1')
  assert, n_elements(data) eq 60, 'Expected 60 results, got ' + strtrim(n_elements(data),2)
  assert, size(data, /type) eq 8, 'Result is not a structure'
  assert, data[0].mms1.time eq 1812820840, 'Start time does not match expected value'
  
  return, 1
end

function get_mms_burst_metadata_ut::test_mms2_time_range
  compile_opt strictarr
  data = get_mms_burst_metadata(1812820840, 1812821431, sc_id='mms2')
  assert, n_elements(data) eq 60, 'Expected 60 results, got ' + strtrim(n_elements(data),2)
  assert, size(data, /type) eq 8, 'Result is not a structure'
  assert, data[0].mms2.time eq 1812820840, 'Start time does not match expected value'

  return, 1
end

function get_mms_burst_metadata_ut::test_mms3_time_range
  compile_opt strictarr
  data = get_mms_burst_metadata(1812820840, 1812821431, sc_id='mms3')
  assert, n_elements(data) eq 60, 'Expected 60 results, got ' + strtrim(n_elements(data),2)
  assert, size(data, /type) eq 8, 'Result is not a structure'
  assert, data[0].mms3.time eq 1812820840, 'Start time does not match expected value'
  
  return, 1
end

function get_mms_burst_metadata_ut::test_mms4_time_range
  compile_opt strictarr
  data = get_mms_burst_metadata(1812820840, 1812821431, sc_id='mms4')
  assert, n_elements(data) eq 60, 'Expected 60 results, got ' + strtrim(n_elements(data),2)
  assert, size(data, /type) eq 8, 'Result is not a structure'
  assert, data[0].mms4.time eq 1812820840, 'Start time does not match expected value'

  return, 1
end

function get_mms_burst_metadata_ut::test_two
  compile_opt strictarr
  data = get_mms_burst_metadata(1812820840, 1812821431, sc_id=['mms1', 'mms4'])
  tags = tag_names(data[0])
  assert, tags[0] eq 'MMS1'
  assert, tags[1] eq 'MMS4'

  return, 1
end

function get_mms_burst_metadata_ut::test_two_diff_order
  compile_opt strictarr
  data = get_mms_burst_metadata(1812820840, 1812821431, sc_id=['mms4', 'mms1'])
  tags = tag_names(data[0])
  assert, tags[0] eq 'MMS4'
  assert, tags[1] eq 'MMS1'

  return, 1
end

function get_mms_burst_metadata_ut::test_all
  compile_opt strictarr
  data = get_mms_burst_metadata(1812821440, 1812822031)
  assert, n_tags(data[0]) eq 4, 'Expected 4 structure elements, got ' + strtrim(n_tags(data[0]),2)

  return, 1
end

function get_mms_burst_metadata_ut::test_with_caps
  compile_opt strictarr
  data = get_mms_burst_metadata(1812820840, 1812821431,sc_id='MMS1')
  assert, n_tags(data[0]) eq 1, 'Expected 1 structure element, got ' + strtrim(n_tags(data[0]),2)

  return, 1
end

function get_mms_burst_metadata_ut::test_with_invalid_id
  compile_opt strictarr
  
  ; this test causes undesirable errors in the production LaTiS log
  ; enable again if we run this against a dev LaTiS server
  return, 1
  
  print, 'Note: Error expected...'
  data = get_mms_burst_metadata(1812820840, 1812821431, sc_id='mms5')
  assert, data eq -1, 'Expected no results, got ' + strtrim(n_elements(data),2)

  return, 1
end

function get_mms_burst_metadata_ut::test_one_of_two_with_invalid_id
  compile_opt strictarr

  ; this test causes undesirable errors in the production LaTiS log
  ; enable again if we run this against a dev LaTiS server
  return, 1
  
  print, 'Note: Error expected...'
  data = get_mms_burst_metadata(1812820840, 1812821431, sc_id=['mms1','mms5'])
  assert, data eq -1, 'Expected no results, got ' + strtrim(n_elements(data),2)
  ;Note, if any are invalid, the query will fail.

  return, 1
end

function get_mms_burst_metadata_ut::test_empty_time_range
  compile_opt strictarr
  print, 'Note: Error expected...'
  data = get_mms_burst_metadata(-999, -998, sc_id='mms1')
  assert, data eq -1, 'Expected no results, got ' + strtrim(n_elements(data),2)

  return, 1
end

function get_mms_burst_metadata_ut::test_reversed_time_range
  compile_opt strictarr
  print, 'Note: Error expected...'
  data = get_mms_burst_metadata(1812821430, 1812820841, sc_id='mms1')
  assert, data eq -1, 'Expected no results, got ' + strtrim(n_elements(data),2)

  return, 1
end


pro get_mms_burst_metadata_ut__define
  compile_opt strictarr
  
  define = { get_mms_burst_metadata_ut, inherits MGutTestCase }
end