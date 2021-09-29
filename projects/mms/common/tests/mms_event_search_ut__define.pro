;+
;
; Unit tests for mms_event_search
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-04-29 11:43:09 -0700 (Mon, 29 Apr 2019) $
; $LastChangedRevision: 27129 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_event_search_ut__define.pro $
;-
function mms_event_search_ut::test_jet_reversal
  mms_event_search, 'jet reversal', descriptions=d, authors=a, start_times=starts, end_times=ends
  assert, d[0] eq 'Vz jet reversal in BL region' and a[0] eq 'seriksson(EVA)' and starts[0] eq 1441787294.0d and ends[0] eq 1441787534.0d, 'Problem with event search routine'
  return, 1
end

function mms_event_search_ut::test_bz_cs
  mms_event_search, 'bz cs', descriptions=d, authors=a, start_times=starts, end_times=ends
  assert, d[0] eq 'Sharp sheath CS with Bz minima in center.' and a[0] eq 'fwilder(EVA)' and starts[0] eq 1447226054.0d and ends[0] eq 1447226084.0d, 'Problem with event search routine'
  return, 1
end

function mms_event_search_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  self->addTestingRoutine, ['mms_event_search', 'mms_events']
  return, 1
end

pro mms_event_search_ut__define
  define = { mms_event_search_ut, inherits MGutTestCase }
end