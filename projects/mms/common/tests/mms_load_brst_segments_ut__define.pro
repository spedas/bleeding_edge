;+
;
; Unit tests for mms_load_brst_segments
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
;
; brst segments used in these tests:
;                 start      -    stop
;   2015-10-16: 13:02:24.000 - 13:03:04.000
;   2015-10-16: 13:03:34.000 - 13:04:54.000
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-04-24 08:15:35 -0700 (Mon, 24 Apr 2017) $
; $LastChangedRevision: 23219 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_brst_segments_ut__define.pro $
;-

; regression test to make sure last week's burst intervals are available (added 10/5/2016)
function mms_load_brst_segments_ut::test_load_recent_intervals
  lastweek = systime(/seconds)-14.*24*60*60
  trange = lastweek+[0, 12.*24*60*60]
  mms_load_brst_segments, trange=trange
  assert, spd_data_exists('mms_bss_burst', time_string(trange[0]), time_string(trange[1])), $
    'Problem loading recent burst segments!!'
  return, 1
end

function mms_load_brst_segments_ut::test_load_suffix
  mms_load_brst_segments, trange=['2015-12-15', '2015-12-16'], suffix='_testsuffix'
  assert, spd_data_exists('mms_bss_burst_testsuffix', '2015-12-15', '2015-12-16'), $
    'Problem with the suffix keyword when loading burst segment bar'
  return, 1
end

function mms_load_brst_segments_ut::test_load_singletime
  mms_load_brst_segments, trange=['2015-10-16/13:02:25', '2015-10-16/13:02:25']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02:24', '2015-10-16/13:02:26'), $
    'Problem loading burst bar with start time = end time in a burst interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_overlap_two_segs
  mms_load_brst_segments, trange=['2015-10-16/13:03', '2015-10-16/13:04:05']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:03', '2015-10-16/13:04:05'), $
    'Problem loading burst bar with start time after start of an interval and end time before the end of the next interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_full_day
  mms_load_brst_segments, trange=['2015-10-16', '2015-10-17']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16', '2015-10-17'), $
    'Problem loading burst segments for the full day'
  return, 1
end

function mms_load_brst_segments_ut::test_load_one_interval
  mms_load_brst_segments, trange=['2015-10-16/13:02', '2015-10-16/13:04']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02', '2015-10-16/13:04'), $
    'Problem loading burst bar for a single interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_inside_one_interval
  mms_load_brst_segments, trange=['2015-10-16/13:02:30', '2015-10-16/13:03']
  assert, spd_data_exists('mms_bss_burst','2015-10-16/13:02:24', '2015-10-16/13:03:04'), $
    'Problem loading burst bar when requested trange is inside the burst interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_overlap_starttime
  mms_load_brst_segments, trange=['2015-10-16/13:02:00', '2015-10-16/13:03']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02:00', '2015-10-16/13:03'), $
    'Problem loading burst bar when we only overlap the start time of an interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_overlap_endtime
  mms_load_brst_segments, trange=['2015-10-16/13:02:40', '2015-10-16/13:03:16']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02:40', '2015-10-16/13:03:16'), $
    'Problem loading burst bar when we only overlap the end time of an interval'
  return, 1
end

function mms_load_brst_segments_ut::test_exact_range
  mms_load_brst_segments, trange=['2015-10-16/13:02:24', '2015-10-16/13:03:04']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02:24', '2015-10-16/13:03:04'), $
    'Problem loading burst bar when using the exact trange of the burst interval'
  return, 1
end

function mms_load_brst_segments_ut::test_start_end_keywords
  mms_load_brst_segments, trange=['2015-10-16/13:00', '2015-10-16/14:00'], start_times = start_bursts, end_times = end_bursts
  starts = ['2015-10-16/12:56:04', $
            '2015-10-16/13:02:24', $
            '2015-10-16/13:03:34', $
            '2015-10-16/13:05:24', $
            '2015-10-16/13:09:04', $
            '2015-10-16/13:33:44', $
            '2015-10-16/13:39:04', $
            '2015-10-16/13:54:04', $
            '2015-10-16/13:55:34', $
            '2015-10-16/13:57:14']
  ends = ['2015-10-16/12:58:34', $
          '2015-10-16/13:03:14', $
          '2015-10-16/13:05:04', $
          '2015-10-16/13:07:44', $, $
          '2015-10-16/13:09:44', $
          '2015-10-16/13:35:24', $
          '2015-10-16/13:41:44', $
          '2015-10-16/13:55:34', $
          '2015-10-16/13:57:14', $
          '2015-10-16/13:58:44']
  assert, array_equal(time_string(start_bursts), starts) && array_equal(time_string(end_bursts), ends), $
    'Problem with start/end interval keywords in mms_load_brst_segments'
  return, 1
end

pro mms_load_brst_segments_ut::setup
  del_data, '*'
end

function mms_load_brst_segments_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_brst_segments']
  return, 1
end

pro mms_load_brst_segments_ut__define

  define = { mms_load_brst_segments_ut, inherits MGutTestCase }
end