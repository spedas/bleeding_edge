pro get_mms_srois_ut::setup
  compile_opt strictarr

  url = get_mms_sitl_connection(host='lasp.colorado.edu', port='80', auth='0', /rebuild)
end


function get_mms_srois_ut::test_nonexistent_sc_id
  compile_opt strictarr

  ;test nonexistent sc_id
  result = get_mms_srois(sc_id="foo")
  assert, result eq -1, 'Nonexistent sc_id returned data'

  return, 1
end


pro get_mms_srois_ut::check_ordered, result
  for i=1, n_elements(result)-1 do begin
    assert, result[i].start_time ge result[i-1].start_time, 'Result is not ordered by start_time'
  endfor
end


function get_mms_srois_ut::test_sc_id
  compile_opt strictarr
  
  sc_id = 'mms4'
  result = get_mms_srois(sc_id=sc_id)
  assert, isa(result, /array), 'Error encountered when testing sc_id'
  index = where(result.sc_id ne sc_id, count)
  assert, count eq 0, 'Returned invalid sc_ids'
  self->check_ordered, result
  
  return, 1
end


function get_mms_srois_ut::test_start_time
  compile_opt strictarr
  
  ;choose start_time to be 20 days ago
  start_time = systime(/julian) - 20
  start_time_str =  tai_to_date_str(start_time)
  result = get_mms_srois(start_time=start_time_str)
  assert, isa(result, /array), 'Error encountered when testing start_time'
  index = where(result.start_time lt start_time_str, count)
  assert, count eq 0, 'Returned invalid start_times'
  self->check_ordered, result
  
  return, 1
end


function get_mms_srois_ut::test_end_time
  compile_opt strictarr
  
  ; SROIs start a bit late (2015-11-06)
  end_time_str = '2015-12-01'
  result = get_mms_srois(end_time=end_time_str)
  assert, isa(result, /array), 'Error encountered when testing end_time'
  index = where(result.start_time ge end_time_str, count)
  assert, count eq 0, 'Returned invalid end_times'
  self->check_ordered, result
  
  return, 1
end


function get_mms_srois_ut::test_mixed
  compile_opt strictarr

  start_time_str = '2016-01-01'
  end_time_str = '2016-02-01'
  sc_id = 'mms1'
  result = get_mms_srois(sc_id=sc_id, start_time=start_time_str, end_time=end_time_str)
  assert, isa(result, /array), 'Error encountered when testing mixed constraints'
  index = where(result.sc_id ne sc_id, count)
  assert, count eq 0, 'Returned invalid sc_ids'
  index = where(result.start_time lt start_time_str, count)
  assert, count eq 0, 'Returned invalid start_times'
  index = where(result.start_time ge end_time_str, count)
  assert, count eq 0, 'Returned invalid end_times'
  self->check_ordered, result
  
  return, 1
end


pro get_mms_srois_ut::check_end_time_format, result, end_time_str
  assert, isa(result, /array), 'Error encountered when testing end_time using ' + end_time_str
  index = where(result.start_time ge end_time_str, count)
  assert, count eq 0, 'Returned invalid start_times using ' + end_time_str
  assert, n_elements(result) eq 1, "Didn't get exactly one SROI using" + end_time_str
end


function get_mms_srois_ut::test_end_time_format
  compile_opt strictarr

  ; time chosen to return exactly one SROI
  end_time_str = '2015-11-06/02:30:39.000'
  result = get_mms_srois(end_time=end_time_str, sc_id='mms1')
  self->check_end_time_format, result, end_time_str
  
  ; accept T as middle character
  end_time_str = '2015-11-06T02:30:39.000'
  result = get_mms_srois(end_time=end_time_str, sc_id='mms1')
  ; changing the ISO middle character changes the boundary comparison
  self->check_end_time_format, result, '2015-11-06/02:30:39.000'
  
  ; accept space as middle character
  end_time_str = '2015-11-06 02:30:39.000'
  result = get_mms_srois(end_time=end_time_str, sc_id='mms1')
  ; changing the ISO middle character changes the boundary comparison
  self->check_end_time_format, result, '2015-11-06/02:30:39.000'

  ; this one fails on the latis server
  ; end_time_str = '2015-11-06/02:30:39.0'
  ; Service failed to handle the query: mms/sdc/public/service/latis/mms_events_view.csv?
  ; start_time_utc,end_time_utc,sc_id,start_orbit&event_type=SROI&start_time_utc<2015-11-06T02:30:39.0&sc_id=mms1

  ; no fractional seconds
  end_time_str = '2015-11-06/02:30:39'
  result = get_mms_srois(end_time=end_time_str, sc_id='mms1')
  self->check_end_time_format, result, end_time_str

  ; one second less should return no matching SROI, exclusive end boundary
  end_time_str = '2015-11-06/02:30:38'
  result = get_mms_srois(end_time=end_time_str, sc_id='mms1')
  assert, result eq -1, 'Exclusive end_time filter bad'


  return, 1
end


pro get_mms_srois_ut__define
  compile_opt strictarr

  define = { get_mms_srois_ut, inherits MGutTestCase }
end