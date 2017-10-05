;+
;
; Unit tests for mms_load_dsp
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-04-03 09:24:09 -0700 (Mon, 03 Apr 2017) $
; $LastChangedRevision: 23084 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_dsp_ut__define.pro $
;-


function mms_load_dsp_ut::test_load
  mms_load_dsp
  assert, spd_data_exists('mms1_dsp_lfb_x mms2_dsp_lfb_y mms3_dsp_lfb_z mms4_dsp_lfb_x', '2015-12-15', '2015-12-16'), 'Problem loading dsp data'
  assert, spd_data_exists('mms1_dsp_lfe_x mms2_dsp_lfe_y mms3_dsp_lfe_z mms4_dsp_lfe_x', '2015-12-15', '2015-12-16'), 'Problem loading dsp data'
  assert, spd_data_exists('mms1_dsp_mfe_x mms2_dsp_mfe_y mms3_dsp_mfe_z mms4_dsp_mfe_x', '2015-12-15', '2015-12-16'), 'Problem loading dsp data'
  return, 1
end

function mms_load_dsp_ut::test_multi_probe
  mms_load_dsp, probes=[1, 2]
  assert, spd_data_exists('mms1_dsp_lfb_x mms2_dsp_lfb_y mms1_dsp_lfe_z mms2_dsp_mfe_x', '2015-12-15', '2015-12-16'), 'Problem loading dsp data for multiple spacecraft'
  return, 1
end

function mms_load_dsp_ut::test_multi_probe_mixed_type
  mms_load_dsp, probes=['1', 2, 3, '4']
  assert, spd_data_exists('mms1_dsp_lfb_x mms2_dsp_lfb_y mms3_dsp_lfb_z mms4_dsp_lfb_x', '2015-12-15', '2015-12-16'), 'Problem loading dsp data with mixed probe types'
  assert, spd_data_exists('mms1_dsp_lfe_x mms2_dsp_lfe_y mms3_dsp_lfe_z mms4_dsp_lfe_x', '2015-12-15', '2015-12-16'), 'Problem loading dsp data with mixed probe types'
  assert, spd_data_exists('mms1_dsp_mfe_x mms2_dsp_mfe_y mms3_dsp_mfe_z mms4_dsp_mfe_x', '2015-12-15', '2015-12-16'), 'Problem loading dsp data with mixed probe types'
  return, 1
end

function mms_load_dsp_ut::test_default_level
  mms_load_dsp, probe=1
  assert, spd_data_exists('mms1_dsp_lfb_x mms1_dsp_lfe_y mms1_dsp_mfe_z', '2015-12-15', '2015-12-16'), 'Problem loading default level dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_l1b
  mms_load_dsp, probe=1, level='l1b'
  assert, spd_data_exists('mms1_dsp_lfe_x mms1_dsp_lfe_y mms1_dsp_mfe_z', '2015-12-15', '2015-12-16'), 'Problem loading l1b dsp data'
  assert, ~spd_data_exists('mms1_dsp_lfb_y mms1_dsp_mfb_z', '2015-12-15', '2015-12-16'), 'Problem loading l1b dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_l2
  mms_load_dsp, probe=1, data_rate='fast', level='l2'
  assert, spd_data_exists('mms1_dsp_bpsd_scm3_fast_l2 mms1_dsp_epsd_y', '2015-12-15', '2015-12-16'), 'Problem loading l2 data'
  return, 1
end

function mms_load_dsp_ut::test_load_l1a
  mms_load_dsp, probe=1, level='l1a'
  assert, spd_data_exists('mms1_dsp_lfb_x mms1_dsp_lfe_y mms1_dsp_mfe_z', '2015-12-15', '2015-12-16'), 'Problem loading l1a dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_invalid_level
  mms_load_dsp, probe=1, level='ql'
  assert, ~spd_data_exists('mms1_dsp_lfb_x mms1_dsp_lfe_y mms1_dsp_mfe_z', '2015-12-15', '2015-12-16'), 'Problem loading ql dsp data (invalid level)'
  return, 1
end

function mms_load_dsp_ut::test_load_invalid_rate
  mms_load_dsp, probe=1, data_rate='brst'
  assert, ~spd_data_exists('mms1_dsp_lfb_x', '2015-12-15', '2015-12-16'), 'Problem loading brst dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_fast_caps
  mms_load_dsp, probe=1, level='l2', data_rate='FAST'
  assert, spd_data_exists('mms1_dsp_epsd_x mms1_dsp_epsd_z mms1_dsp_epsd_omni mms1_dsp_bpsd_scm1_fast_l2 mms1_dsp_swd_E12_Counts', '2015-12-15', '2015-12-16'), 'Problem loading FAST (caps) dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_fast
  mms_load_dsp, probe=1, data_rate='fast'
  assert, spd_data_exists('mms1_dsp_epsd_x mms1_dsp_epsd_z mms1_dsp_epsd_omni mms1_dsp_bpsd_scm1_fast_l2 mms1_dsp_swd_E12_Counts', '2015-12-15', '2015-12-16'), 'Problem loading fast dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_slow_l2
  mms_load_dsp, probe=1, level='l2', data_rate='slow'
  assert, spd_data_exists('mms1_dsp_epsd_y mms1_dsp_bpsd_scm3_slow_l2', '2015-12-15', '2015-12-16'), 'Problem loading l2 slow dsp data' 
  assert, ~spd_data_exists('mms1_bpsd_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading l2 slow dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_srvy_l1b
  mms_load_dsp, probe=1, data_rate='srvy'
  assert, spd_data_exists('mms1_dsp_lfe_x mms1_dsp_lfe_y mms1_dsp_lfe_z mms1_dsp_mfe_x mms1_dsp_mfe_y mms1_dsp_mfe_z', '2015-12-15', '2015-12-16'), 'Problem loading fast dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_slow_l1a
  mms_load_dsp, probe=1, level='l1a', data_rate='slow'
  assert, ~spd_data_exists('mms1_dsp_epsd_y mms1_dsp_epsd_omni mms1_bpsd_omni_slow_l2', '2015-12-15', '2015-12-16'), 'Problem loading l1a slow dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_srvy
  mms_load_dsp, probe=1, data_rate='srvy'
  assert, spd_data_exists('mms1_dsp_lfb_x mms1_dsp_lfe_y mms1_dsp_mfe_z', '2015-12-15', '2015-12-16'), 'Problem loading srvy dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_suffix
  mms_load_dsp, probe=3, datatype='epsd', suffix='_suffixtest', data_rate='fast', level='l2'
  assert, spd_data_exists('mms3_dsp_epsd_y_suffixtest', '2015-12-15', '2015-12-16'), 'Problem with dsp suffix test'
  return, 1
end

function mms_load_dsp_ut::test_load_epsd
  mms_load_dsp, probe=3, datatype='epsd'
  assert, spd_data_exists('mms3_dsp_lfe_x mms3_dsp_lfe_y mms3_dsp_lfe_z mms3_dsp_mfe_x mms3_dsp_mfe_y mms3_dsp_mfe_z', '2015-12-15', '2015-12-16'), 'Problem loading fast dsp data'
  assert, ~spd_data_exists('mms1_dsp_lfe_x mms1_dsp_lfe_y mms1_dsp_lfe_z mms1_dsp_mfe_x mms1_dsp_mfe_y mms1_dsp_mfe_z', '2015-12-15', '2015-12-16'), 'Problem loading fast dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_bpsd
  mms_load_dsp, probe=3, datatype='bpsd'
  assert, spd_data_exists('mms3_dsp_lfb_x mms3_dsp_lfb_y mms3_dsp_lfb_z', '2015-12-15', '2015-12-16'), 'Problem loading bpsd dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_swd
  mms_load_dsp, probe=3, datatype='swd', data_rate='fast', level='l2'
  assert, spd_data_exists('mms3_dsp_swd_E12_Counts', '2015-12-15', '2015-12-16'), 'Problem loading swd dsp data'
  return, 1
end

function mms_load_dsp_ut::test_trange
  mms_load_dsp, trange=['2015-12-10', '2015-12-20'], probe=1, datatype='bpsd'
  assert, spd_data_exists('mms1_dsp_lfb_x mms1_dsp_lfb_y mms1_dsp_lfb_z', '2015-12-10', '2015-12-20'), 'Problem loading bpsd dsp data with trange keyword'
  return, 1
end

function mms_load_dsp_ut::test_timeclip
  mms_load_dsp, probe=1, time_clip=['2015-12-15 04:00:00', '2015-12-15 08:00:00'], datatype='bpsd'
  assert, spd_data_exists('mms1_dsp_lfb_x mms1_dsp_lfb_y mms1_dsp_lfb_z', '2015-12-10', '2015-12-20'), 'Problem loading bpsd dsp data with trange keyword'
  return, 1
end

function mms_load_dsp_ut::test_load_spdf
  mms_load_dsp, probe=1, /spdf, datatype='epsd', data_rate='fast', level='l2'
  assert, spd_data_exists('mms1_dsp_epsd_x mms1_dsp_epsd_y mms1_dsp_epsd_z mms1_dsp_epsd_omni', '2015-12-15', '2015-12-16'), 'Problem loading dsp data from SPDF'
  return, 1
end

function mms_load_dsp_ut::test_load_dsp_cdf_filenames
  mms_load_dsp, probe=3, datatype='epsd', /spdf, suffix='_fromspdf', data_rate='fast', level='l2', cdf_filenames=spdf_filenames
  mms_load_dsp, probe=3, datatype='epsd', suffix='_fromsdc', data_rate='fast', level='l2', cdf_filenames=sdc_filenames
  assert, array_equal(strlowcase(spdf_filenames), strlowcase(sdc_filenames)), 'Problem with cdf_filenames keyword (SDC vs. SPDF) for dsp data'
  return, 1
end

function mms_load_dsp_ut::test_load_all_datatypes
  mms_load_dsp, probe=1, datatype='*'
  assert, spd_data_exists('mms1_dsp_lfe mms1_dsp_mfe mms1_dsp_lfb', '2015-12-15', '2015-12-16'), $
    'Problem loading DSP data with the datatype keyword specified'
  return, 1
end

pro mms_load_dsp_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
end

function mms_load_dsp_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_dsp', 'mms_dsp_fix_metadata']
  return, 1
end

pro mms_load_dsp_ut__define

  define = { mms_load_dsp_ut, inherits MGutTestCase }
end