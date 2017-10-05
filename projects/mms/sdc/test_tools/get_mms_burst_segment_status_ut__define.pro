;docformat = 'rst' 
;+ 
; Tests the burst data segment returned based on given parameters. 
; 
; NOTES: 
; Time span for first sample (SEGMENTID=1013) is currently TAISTARTTIME=1812820840 to TAIENDTIME=1812821430 (2015-06-12T17:20:05 to 2015-06-12T17:29:55)
; Time span for second sample (SEGMENTID=900) is currently TAISTARTTIME=1809567960 to TAIENDTIME=1809570950 (2015-05-06T01:45:25 to 2015-05-06T02:35:15)
; TODO: test_not_pending, none right now
; 
; :Author:
;   Doug Lindholm, Alexia Newgord 
;-

pro get_mms_burst_segment_status_ut::setup
  compile_opt strictarr
  url = get_mms_sitl_connection(host='sdc-web2', port='8080', auth='0', /rebuild)
  
end

;+
;Testing SEGMENTID 1013
;-
function get_mms_burst_segment_status_ut::test_get_by_segmentid
  compile_opt strictarr
  data = get_mms_burst_segment_status(data_segment_id = 1013)
  assert, n_elements(data) eq 1, 'Got more than one record'
  assert, size(data, /type) eq 8, 'Result is not a structure'
  assert, data[0].taiStartTime eq 1812820840, 'taiStartTime does not match expected value'
  
  return, 1
end

function get_mms_burst_segment_status_ut::test_get_by_invalid_id
  compile_opt strictarr
  print, 'Note: Error expected...'
  data = get_mms_burst_segment_status(data_segment_id=-1)
  assert, data eq -1, 'Should have gotten no results.'

  return, 1
end

function get_mms_burst_segment_status_ut::test_is_pending
  compile_opt strictarr
  data = get_mms_burst_segment_status(is_pending=1)
  assert, data[0].ISPENDING eq 1

  return, 1
end

;+
;Testing SEGMENTID 900
;-
function get_mms_burst_segment_status_ut::test_start_time_during_segment
  compile_opt strictarr
  data = get_mms_burst_segment_status(start_time=1809567961)
  assert, data[0].TAISTARTTIME eq 1809567960 and data[0].TAIENDTIME eq 1809570950, $
    'Segment should match if start_time is between taiStartTime and taiEndTime'

  return, 1
end

;+
;Testing SEGMENTID 900
;-
function get_mms_burst_segment_status_ut::test_end_time_during_segment
  compile_opt strictarr
  data = get_mms_burst_segment_status(end_time=1809567961)
  assert, data[0].TAISTARTTIME eq 1809567960 and data[0].TAIENDTIME eq 1809570950, $
    'Segment should match if end_time is between taiStartTime and taiEndTime'

  return, 1
end

;+
;Testing SEGMENTID 900
;-
function get_mms_burst_segment_status_ut::test_start_time_equals_end_time
  compile_opt strictarr
  ;start_time is 2015-05-06T02:35:15 (end time for segment 900), end_time is 2015-05-11T01:46:05
  ;start times are inclusive, end times are exclusive 
  data = get_mms_burst_segment_status(start_time=1809570950, end_time=1810000000)
  assert, data[0].TAISTARTTIME ne 1809567960 and data[0].TAIENDTIME ne 1809570950, $
    'Segment should not match if start_time equals taiEndTime'

  return, 1
end

;+
;Testing SEGMENTID 900 
;-
function get_mms_burst_segment_status_ut::test_end_time_equals_start_time
  compile_opt strictarr
  print, 'Warning expected'
  ;end_time is 2015-05-06T01:45:25 (start time for segment 900)
  ;start times are inclusive, end times are exclusive
  data = get_mms_burst_segment_status(start_time=1809567960, end_time=1809567960)
  assert, data eq -1, 'Segment should not match if end_time equals taiStartTime'

  return, 1
end

;+
;Testing SEGMENTID 1016, 
;which includes SITL activity
;-
function get_mms_burst_segment_status_ut::test_get_sitl_activity
  compile_opt strictarr
  data = get_mms_burst_segment_status(data_segment_id = 1016)
  assert, n_elements(data) eq 1, 'Got more than one record'
  assert, size(data, /type) eq 8, 'Result is not a structure'
  assert, data[0].taiStartTime eq 1812822640, 'taiStartTime does not match expected value'
  assert, data[0].sourceId eq 'fwilder(EVA)'
  assert, data[0].discussion eq 'Enhanced Wave Activity'

  return, 1
end



pro get_mms_burst_segment_status_ut__define
  compile_opt strictarr
  
  define = { get_mms_burst_segment_status_ut, inherits MGutTestCase }
end