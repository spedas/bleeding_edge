;+
;
; Unit tests for mms_load_edi
;
; To run:
;     IDL> mgunit, 'mms_load_edi_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-10-09 09:19:08 -0700 (Mon, 09 Oct 2017) $
; $LastChangedRevision: 24128 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_edi_ut__define.pro $
;-

function mms_load_edi_ut::test_multi_data_rates
  mms_load_edi, probe=1, data_rate=['srvy', 'brst']
  assert, spd_data_exists('mms1_edi_e_dsl_brst_l2 mms1_edi_e_dsl_srvy_l2', '2015-12-15', '2015-12-16'), $
    'Problem with multiple data rates'
  return, 1
end

function mms_load_edi_ut::test_load_spdf
  mms_load_edi, probes=[1, 4], level='l2', /spdf
  assert, spd_data_exists('mms1_edi_vdrift_gse_srvy_l2 mms1_edi_vdrift_gsm_srvy_l2 mms4_edi_vdrift_dsl_srvy_l2 mms4_edi_vdrift_gse_srvy_l2 mms4_edi_vdrift_gsm_srvy_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading EDI data from SPDF'
  return, 1
end

function mms_load_edi_ut::test_load_multi_probe
  mms_load_edi, probes=[1, 2, '3', 4], level='l2'
  assert, spd_data_exists('mms1_edi_vdrift_dsl_srvy_l2 mms2_edi_vdrift_dsl_srvy_l2 mms3_edi_vdrift_dsl_srvy_l2 mms4_edi_vdrift_dsl_srvy_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading EDI with multiple probes specified'
  return, 1
end

function mms_load_edi_ut::test_load_ql
  mms_load_edi, level='ql', probe=1
  assert, spd_data_exists('mms1_edi_E_dmpa mms1_edi_v_ExB_dmpa mms1_edi_E_bc_dmpa mms1_edi_v_ExB_bc_dmpa', '2015-12-15', '2015-12-16'), $
    'Problem loading QL EDI data'
  return, 1
end

function mms_load_edi_ut::test_load_burst_caps
  mms_load_edi, level='L2', data_rate='BRST', probe=1
  assert, spd_data_exists('mms1_edi_vdrift_gse_brst_l2 mms1_edi_vdrift_gsm_brst_l2 mms1_edi_e_dsl_brst_l2 mms1_edi_e_gse_brst_l2 mms1_edi_e_gsm_brst_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading burst mode L2 EDI data'
  return, 1
end

function mms_load_edi_ut::test_load_burst_l2
  mms_load_edi, level='l2', data_rate='brst', probe=1
  assert, spd_data_exists('mms1_edi_vdrift_gse_brst_l2 mms1_edi_vdrift_gsm_brst_l2 mms1_edi_e_dsl_brst_l2 mms1_edi_e_gse_brst_l2 mms1_edi_e_gsm_brst_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading burst mode L2 EDI data'
  return, 1
end

function mms_load_edi_ut::test_load_l2
  mms_load_edi, level='l2', probe=1
  assert, spd_data_exists('mms1_edi_vdrift_dsl_srvy_l2 mms1_edi_vdrift_gse_srvy_l2 mms1_edi_vdrift_gsm_srvy_l2 mms1_edi_e_dsl_srvy_l2 mms1_edi_e_gse_srvy_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 EDI data'
  return, 1
end

function mms_load_edi_ut::test_load_suffix
  mms_load_edi, level='l2', probe=1, suffix='_testsuffix'
  assert, spd_data_exists('mms1_edi_vdrift_dsl_srvy_l2_testsuffix mms1_edi_e_dsl_srvy_l2_testsuffix', '2015-12-15', '2015-12-16'), $
    'Problem with EDI suffix keyword'
  return, 1
end

function mms_load_edi_ut::test_load_spdf_suffix
  mms_load_edi, level='l2', probe=1, suffix='_testsuffix', /spdf
  assert, spd_data_exists('mms1_edi_vdrift_dsl_srvy_l2_testsuffix mms1_edi_e_dsl_srvy_l2_testsuffix', '2015-12-15', '2015-12-16'), $
    'Problem with EDI suffix keyword'
  return, 1
end

function mms_load_edi_ut::test_load_datatype_amb
  mms_load_edi, level='l2', probe='4', datatype='amb'
  assert, spd_data_exists('mms4_edi_flux1_0_srvy_l2 mms4_edi_flux1_180_srvy_l2', '2015-12-15', '2015-12-16'), $
    'Problem with EDI amb datatype?'
  return, 1
end

function mms_load_edi_ut::test_load_datatype_caps
  mms_load_edi, level='l2', probe=3, datatype='AMB'
  assert, spd_data_exists('mms3_edi_flux1_0_srvy_l2 mms3_edi_flux1_180_srvy_l2', '2015-12-15', '2015-12-16'), $
    'Problem with EDI amb datatype (all caps)?'
  return, 1
end

function mms_load_edi_ut::test_load_datatypes_star
  mms_load_edi, level='l2', datatype='*'
  assert, spd_data_exists('mms1_edi_flux1_0_srvy_l2 mms1_edi_vdrift_dsl_srvy_l2 mms1_edi_e_gsm_srvy_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading * datatypes'
  return, 1
end

function mms_load_edi_ut::test_load_tplotnames
  mms_load_edi, level='l2', probe=2, datatype='efield', tplotnames=tn
  assert, n_elements(tn) eq 22, 'Problem with tplotnames keyword in EDI load routine'
  return, 1
end

pro mms_load_edi_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
end

function mms_load_edi_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_edi', 'mms_edi_set_metadata']
  return, 1
end

pro mms_load_edi_ut__define
  define = { mms_load_edi_ut, inherits MGutTestCase }
end