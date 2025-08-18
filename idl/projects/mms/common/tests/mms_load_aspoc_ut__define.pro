;+
;
; Unit tests for mms_load_aspoc
;
; To run:
;     IDL> mgunit, 'mms_load_aspoc_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-10-09 09:19:08 -0700 (Mon, 09 Oct 2017) $
; $LastChangedRevision: 24128 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_aspoc_ut__define.pro $
;-

function mms_load_aspoc_ut::test_varformat
  mms_load_aspoc, varformat='*ionc*'
  assert, n_elements(tnames()) eq 3, 'Problem with varformat in mms_load_aspoc!'
  return, 1
end

function mms_load_aspoc_ut::test_data_spdf
  mms_load_aspoc, level='l2', probes=[1, 4], /spdf
  assert, spd_data_exists('mms1_aspoc_ionc_l2 mms4_asp2_ionc_l2 mms4_asp1_energy_l2 mms1_asp2_energy_l2 mms4_aspoc_status_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading ASPOC data from SPDF'
  return, 1
end

function mms_load_aspoc_ut::test_load_caps
  mms_load_aspoc, level='L2', probe=4, data_rate='SRVY'
  assert, spd_data_exists('mms4_aspoc_ionc_l2 mms4_asp1_ionc_l2 mms4_asp2_ionc_l2 mms4_asp1_energy_l2 mms4_aspoc_status_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 ASPOC data (caps)'
  return, 1
end

function mms_load_aspoc_ut::test_load_multi_probe
  mms_load_aspoc, level='l2', probes=[1, '2', 3, 4]
  assert, spd_data_exists('mms1_aspoc_ionc_l2 mms2_asp1_ionc_l2 mms3_asp2_ionc_l2 mms4_asp1_energy_l2 mms1_aspoc_status_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 ASPOC data.'
  return, 1
end

function mms_load_aspoc_ut::test_load_l2
  mms_load_aspoc, level='l2'
  assert, spd_data_exists('mms1_aspoc_ionc_l2 mms1_asp1_ionc_l2 mms1_asp2_ionc_l2 mms1_asp1_energy_l2 mms1_aspoc_status_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 ASPOC data.'
  return, 1
end

function mms_load_aspoc_ut::test_load_suffix
  mms_load_aspoc, level='l2', probe='3', suffix='_suffix_test'
  assert, spd_data_exists('mms3_aspoc_ionc_l2_suffix_test mms3_asp1_ionc_l2_suffix_test mms3_asp2_ionc_l2_suffix_test mms3_asp1_energy_l2_suffix_test mms3_aspoc_status_l2_suffix_test', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 ASPOC data.'
  return, 1
end

pro mms_load_aspoc_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
end

function mms_load_aspoc_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_aspoc']
  return, 1
end

pro mms_load_aspoc_ut__define

  define = { mms_load_aspoc_ut, inherits MGutTestCase }
end