;+
;
; Unit tests for mms_load_fsm
;
; To run:
;     IDL> mgunit, 'mms_load_fsm_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-05-29 07:04:58 -0700 (Tue, 29 May 2018) $
; $LastChangedRevision: 25293 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_fsm_ut__define.pro $
;-

function mms_load_fsm_ut::test_varformat_array_still_flagged
  mms_load_fsm, level='l3', data_rate='brst', varformat=['*fsm_b_gse*', '*fsm_b_mag*'], probe=4
  get_data, 'mms4_fsm_flag_brst_l3', data=flags
  get_data, 'mms4_fsm_b_gse_brst_l3', data=flagged
  assert, ~finite(flagged.y[(where(flags.Y ne 0))[0], 0]), $
    'Problem with removing flags in mms_load_fsm (varformat == array)'
  assert, spd_data_exists('mms4_fsm_b_mag_brst_l3 mms4_fsm_b_gse_brst_l3 mms4_fsm_flag_brst_l3', '2015-12-15', '2015-12-15/01'), 'Problem loading FSM data with varformat keyword - data not being deflagged?'
  return, 1
end

function mms_load_fsm_ut::test_varformat_still_flagged
  mms_load_fsm, probes=4, level='l3', data_rate='brst', varformat='*fsm_b_gse*'
  get_data, 'mms4_fsm_flag_brst_l3', data=flags
  get_data, 'mms4_fsm_b_gse_brst_l3', data=flagged
  assert, ~finite(flagged.y[(where(flags.Y ne 0))[0], 0]), $
    'Problem with removing flags in mms_load_fsm (varformat == string)'
  assert, spd_data_exists('mms4_fsm_b_gse_brst_l3 mms4_fsm_flag_brst_l3', '2015-12-15', '2015-12-15/01'), 'Problem loading FSM data with varformat - deflagging broken?'
  return, 1
end

function mms_load_fsm_ut::test_load
  mms_load_fsm, probe=4, level='l3'
  assert, spd_data_exists('mms4_fsm_b_gse_brst_l3 mms4_fsm_b_mag_brst_l3', '2015-12-15', '2015-12-15/1'), 'Problem loading L2 FSM data'
  return, 1
end

function mms_load_fsm_ut::test_multi_probe
  mms_load_fsm, probes=[1, 2, 3, 4], level='l3'
  assert, spd_data_exists('mms1_fsm_b_gse_brst_l3 mms2_fsm_b_gse_brst_l3 mms3_fsm_b_gse_brst_l3 mms4_fsm_b_gse_brst_l3', '2015-12-15', '2015-12-15/1'), 'Problem loading FSM data for multiple spacecraft'
  return, 1
end

function mms_load_fsm_ut::test_load_suffix
  mms_load_fsm, level='l3', suffix='_suffixtest', probe=4
  assert, spd_data_exists('mms4_fsm_b_mag_brst_l3_suffixtest mms4_fsm_b_gse_brst_l3_suffixtest', '2015-12-15', '2015-12-15/01'), 'Problem with L2 FSM suffix test'
  return, 1
end

function mms_load_fsm_ut::test_trange
  mms_load_fsm, trange=['2015-12-15', '2015-12-15/01'], level='l3', probe=4
  assert, spd_data_exists('mms4_fsm_b_gse_brst_l3', '2015-12-15', '2015-12-15/01'), 'Problem with trange keyword while loading FSM data'
  return, 1
end

function mms_load_fsm_ut::test_keep_flagged
  mms_load_fsm, probe=4, level='l3', /keep_flagged, trange=['2015-12-15/00:45', '2015-12-15/00:45:50'], /time_clip
  get_data, 'mms4_fsm_flag_brst_l3', data=flags
  get_data, 'mms4_fsm_b_gse_brst_l3', data=flagged
  assert, finite(flagged.y[(where(flags.Y ne 0))[0], 0]), $
    'Problem with keep_flagged keyword in mms_load_fsm'
  return, 1
end

function mms_load_fsm_ut::test_remove_flagged_default
  mms_load_fsm, probe=4, level='l3'
  get_data, 'mms4_fsm_flag_brst_l3', data=flags
  get_data, 'mms4_fsm_b_mag_brst_l3', data=flagged
  assert, ~finite(flagged.y[(where(flags.Y ne 0))[0], 0]), $
    'Problem with removing flags in mms_load_fsm'
  return, 1
end

pro mms_load_fsm_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 0.05, /day
  ; create a connection to the LASP SDC with team member access
  mms_load_data, login_info='test_auth_info_team.sav', instrument='fgm'
end

function mms_load_fsm_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_fsm']
  return, 1
end

pro mms_load_fsm_ut__define
  define = { mms_load_fsm_ut, inherits MGutTestCase }
end