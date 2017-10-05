;+
;
; Unit tests for mms_load_fast_segments
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-08-08 09:34:17 -0700 (Tue, 08 Aug 2017) $
; $LastChangedRevision: 23764 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_fast_segments_ut__define.pro $
;-

; the following is a regression test for a bug fixed on 8/8/17
function mms_load_fast_segments_ut::test_june_20_bug
  spd_mms_load_bss, trange=['2017-06-20/15:50', '2017-06-20/16:20'], datatype=['fast', 'burst', 'status']
  assert, spd_data_exists('mms_bss_fast mms_bss_burst mms_bss_status', '2017-06-20', '2017-06-21'), 'Problem with fast segments regression test'
  return, 1
end

function mms_load_fast_segments_ut::test_no_kws
  timespan, '15-12-15', 1, /day
  mms_load_fast_segments
  assert, spd_data_exists('mms_bss_fast', '2015-12-15', '2015-12-16'), 'Problem loading fast segments with no keywords specified'
  return, 1
end

function mms_load_fast_segments_ut::test_overlap_start
  mms_load_fast_segments, trange=['2015-10-16/5:02:00', '2015-10-16/13:02:25']
  assert, spd_data_exists('mms_bss_fast', '2015-10-16/5:02:00', '2015-10-16/13:02:25'), $
    'Problem loading fast segment bar when the user requests a time that overlaps the start time'
  return, 1
end

function mms_load_fast_segments_ut::test_suffix_keyword
  mms_load_fast_segments, trange=['2015-12-15', '2015-12-16'], suffix='_testsuffix'
  assert, spd_data_exists('mms_bss_fast_testsuffix', '2015-12-15', '2015-12-16'), $
    'Problem with suffix keyword in mms_load_fast_segments'
  return, 1
end

function mms_load_fast_segments_ut::test_exact_range
  mms_load_fast_segments, trange=['2015-10-16/05:02:34', '2015-10-16/16:33:54']
  assert, spd_data_exists('mms_bss_fast', '2015-10-16/05:02:34', '2015-10-16/16:33:54'), $
    'Problem loading fast bar when using the exact trange'
  return, 1
end

function mms_load_fast_segments_ut::test_multi_days
  mms_load_fast_segments, trange=['2015-12-1', '2015-12-16']
  assert, spd_data_exists('mms_bss_fast', '2015-12-1', '2015-12-16'), $
    'Problem loading fast bar for multiple days'
  return, 1
end

function mms_load_fast_segments_ut::test_start_end_keywords
  mms_load_fast_segments, trange=['2015-12-1', '2015-12-16'], start_times=start_times, end_times=end_times
  starts = ['2015-11-29/00:01:34', $
            '2015-11-29/23:55:04', $
            '2015-11-30/23:55:34', $
            '2015-12-01/23:48:54', $
            '2015-12-02/23:42:14', $
            '2015-12-03/23:35:34', $
            '2015-12-04/23:28:44', $
            '2015-12-05/23:21:54', $
            '2015-12-06/23:15:14', $
            '2015-12-07/23:08:25', $
            '2015-12-08/23:01:54', $
            '2015-12-09/22:55:24', $
            '2015-12-10/22:48:54', $
            '2015-12-11/22:42:24', $
            '2015-12-12/22:36:04', $
            '2015-12-13/22:29:24', $
            '2015-12-14/22:45:54', $
            '2015-12-15/22:39:14', $
            '2015-12-16/22:32:24', $
            '2015-12-17/22:25:34']
  ends = ['2015-11-29/13:46:34', $
          '2015-11-30/13:39:54', $
          '2015-12-01/13:50:04', $
          '2015-12-02/13:43:24', $
          '2015-12-03/13:36:34', $
          '2015-12-04/13:29:54', $
          '2015-12-05/13:23:14', $
          '2015-12-06/13:16:34', $
          '2015-12-07/13:10:04', $
          '2015-12-08/13:03:35', $
          '2015-12-09/12:57:04', $
          '2015-12-10/12:50:34', $
          '2015-12-11/12:44:04', $
          '2015-12-12/12:37:34', $
          '2015-12-13/12:30:54', $
          '2015-12-14/12:24:04', $
          '2015-12-15/12:31:14', $
          '2015-12-16/12:24:24', $
          '2015-12-17/12:17:34', $
          '2015-12-18/12:10:54']
  assert, array_equal(time_string(start_times), starts) && array_equal(time_string(end_times), ends), $
    'Problem loading fast intervals using keywords'
  return, 1
end

pro mms_load_fast_segments_ut::setup
  del_data, '*'
end

function mms_load_fast_segments_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_fast_segments']
  return, 1
end

pro mms_load_fast_segments_ut__define
  define = { mms_load_fast_segments_ut, inherits MGutTestCase }
end