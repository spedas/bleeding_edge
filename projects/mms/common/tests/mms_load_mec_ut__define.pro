;+
;
; Unit tests for mms_load_mec
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-05-01 13:01:19 -0700 (Mon, 01 May 2017) $
; $LastChangedRevision: 23256 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_mec_ut__define.pro $
;-

function mms_load_mec_ut::test_varformat_r
  mms_load_mec, probe=4, level='l2', varformat='*_r_*'
  assert, spd_data_exists('mms4_mec_r_eci mms4_mec_r_gsm mms4_mec_r_geo mms4_mec_r_sm', '2016-2-10', '2016-2-11'), $
    'Problem with varformat in mms_load_mec'
  assert, ~spd_data_exists('mms4_mec_v_eci', '2016-2-10', '2016-2-11'), $
    'varformat regression in mms_load_mec'
  return, 1
end

function mms_load_mec_ut::test_varformat_v
  mms_load_mec, probe=4, level='l2', varformat='*_v_*'
  assert, spd_data_exists('mms4_mec_v_eci mms4_mec_v_gsm mms4_mec_v_geo mms4_mec_v_sm', '2016-2-10', '2016-2-11'), $
    'Problem with varformat in mms_load_mec'
  assert, ~spd_data_exists('mms4_mec_r_eci', '2016-2-10', '2016-2-11'), $
    'varformat regression in mms_load_mec'
  return, 1
end

function mms_load_mec_ut::test_multi_probe
  mms_load_mec, probe=[1, 2, '3', '4'], level='l2', data_rate='srvy'
  assert, spd_data_exists('mms1_mec_r_gsm mms2_mec_r_gsm mms3_mec_r_gsm mms4_mec_r_gsm', '2016-2-10', '2016-2-11'), $
    'Problem loading multi-probe MEC data'
  return, 1
end

function mms_load_mec_ut::test_load_brst_caps
  mms_load_mec, probe=1, level='L2', data_rate='BrST'
  assert, spd_data_exists('mms1_mec_r_gsm mms1_mec_r_sm', '2016-2-10', '2016-2-11') , $
    'Problem loading MEC brst data with caps'
  return, 1
end

function mms_load_mec_ut::test_load_brst
  mms_load_mec, probe=1, level='l2', data_rate='brst', suffix='_brst'
  assert, spd_data_exists('mms1_mec_r_gsm_brst', '2016-2-10', '2016-2-11'), $
    'Problem loading MEC brst data'
  return, 1
end

function mms_load_mec_ut::test_load_brst_spdf
  mms_load_mec, probe=3, level='l2', data_rate='brst', /spdf, suffix='_brst_from_spdf'
  assert, spd_data_exists('mms3_defatt_spinras_brst_from_spdf mms3_defatt_spindec_brst_from_spdf mms3_mec_r_gsm_brst_from_spdf mms3_mec_v_gsm_brst_from_spdf', '2016-02-10', '2016-02-11'), $
    'Problem with loading MEC brst data from SPDF'
  return, 1
end

function mms_load_mec_ut::test_load_mec_cdf_filenames
  mms_load_mec, probe=1, level='l2', /spdf, suffix='_fromspdf', cdf_filenames=spdf_filenames
  mms_load_mec, probe=1, level='l2', suffix='_fromsdc', cdf_filenames=sdc_filenames
  assert, array_equal(strlowcase(spdf_filenames), strlowcase(sdc_filenames)), 'Problem with cdf_filenames keyword (SDC vs. SPDF)'
  return, 1
end

function mms_load_mec_ut::test_load_spdf
  mms_load_mec, probes=[1, 4], /spdf
  assert, spd_data_exists('mms4_mec_r_gsm mms1_mec_r_gsm mms1_defatt_spinras mms4_defatt_spinras', '2016-2-10', '2016-2-11')
  return, 1
end

function mms_load_mec_ut::test_load_eci_coord_sys
  mms_load_mec, probes=[2, 3], suffix='_coordstest'
  assert, cotrans_get_coord('mms3_defatt_spinras_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms2_defatt_spindec_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_L_vec_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_Z_vec_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data' 
  assert, cotrans_get_coord('mms3_mec_P_vec_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms2_mec_L_phase_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_Z_phase_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_P_phase_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_L_vec_coordstest_0') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms2_mec_L_vec_coordstest_1') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_r_moon_de421_eci_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_r_sun_de421_eci_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_quat_eci_to_bcs_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms2_mec_quat_eci_to_dbcs_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_quat_eci_to_dmpa_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_quat_eci_to_smpa_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms2_mec_quat_eci_to_dsl_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_quat_eci_to_ssl_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_quat_eci_to_gsm_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_quat_eci_to_geo_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms2_mec_quat_eci_to_sm_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_quat_eci_to_gse_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_quat_eci_to_gse2000_coordstest') eq 'j2000', 'Problem with coordinate system in MEC data'
  assert, cotrans_get_coord('mms3_mec_r_eci_coordstest') eq 'j2000', 'Problem with coordinate system in ECI position data'
  assert, cotrans_get_coord('mms3_mec_v_eci_coordstest') eq 'j2000', 'Problem with coordinate system in ECI velocity data'
  assert, cotrans_get_coord('mms2_mec_r_eci_coordstest') eq 'j2000', 'Problem with coordinate system in ECI position data'
  assert, cotrans_get_coord('mms2_mec_v_eci_coordstest') eq 'j2000', 'Problem with coordinate system in ECI velocity data'
  return, 1
end

function mms_load_mec_ut::test_load_datatype
  mms_load_mec, datatype='ephts04d', probe=2
  assert, spd_data_exists('mms2_mec_r_sm mms2_mec_r_gsm', '2016-2-10', '2016-2-11'), $
    'Problem loading MEC data with datatype keyword specified'
  return, 1
end

pro mms_load_mec_ut::setup
  del_data, '*'
  timespan, '2016-2-10', 1, /day
  ; create a connection to the LASP SDC with public access
  mms_load_data, login_info='test_auth_info_pub.sav', instrument='mec'
end

function mms_load_mec_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_mec', 'mms_mec_fix_metadata']
  return, 1
end

pro mms_load_mec_ut__define

  define = { mms_load_mec_ut, inherits MGutTestCase }
end