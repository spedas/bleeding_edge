;+
;
; Unit tests for mms_load_data
;
; REQUIRED (in working directory): 
;     test_auth_info_team.sav - sav file containing username and password
;     test_auth_info_pub.sav - sav file containing an empty username and password
;     
; To run:
;     IDL> mgunit, 'mms_load_data_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-10-09 09:19:08 -0700 (Mon, 09 Oct 2017) $
; $LastChangedRevision: 24128 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_data_ut__define.pro $
;-


; test MMS team member access
; after downloading some L2 data
; regression test for bug in mms_login_lasp, 3/15/2016
function mms_load_data_ut::test_team_access_after_l2
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2017-01-04', '2017-01-05'], $
    instrument='fgm', level='l2', data_rate='srvy', probe=1
  assert, tnames('*_fgm_r_gsm_srvy_l2') ne '', 'Problem loading L2 FGM data'
  mms_load_data, trange=['2017-01-05', '2017-01-06'], instrument='dfg', level='l2pre', data_rate='srvy', probe=1
  assert, tnames('*_dfg_b_gsm_srvy_l2pre') ne '', 'Problem loading L2pre FGM data after loading L2 FGM data'
  mms_sitl_logout
  return, 1
end

; test MMS team member access 
function mms_load_data_ut::test_team_access
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2017-01-21', '2017-01-22'], $
      instrument='dfg', level='l2pre', data_rate='srvy', probe=1
  get_data, 'mms1_dfg_b_dmpa_srvy_l2pre', data=d
  assert, is_struct(d), 'Problem accessing the SDC with an MMS username/password'
  mms_sitl_logout
  return, 1
end

; test MMS team member access with multiple calls
function mms_load_data_ut::test_team_access_multi
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2017-01-21', '2017-01-22'], $
    instrument='dfg', level='l2pre', data_rate='srvy', probe=1
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2016-01-21', '2016-01-22'], $
    instrument='fpi', level='sitl', data_rate='fast', probe=1
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2017-01-21', '2017-01-22'], $
    instrument='hpca', level='l1b', data_rate='srvy', probe=1
  assert, tnames('mms1_dfg_b_dmpa_srvy_l2pre') ne '', 'Problem loading L2pre DFG data (team, multi-call test)'
  assert, tnames('mms1_hpca_hplus_number_density') ne '', 'Problem loading L1b HPCA data (team, multi-call test)'
  assert, tnames('mms1_fpi_eEnergySpectr_pX') ne '', 'Problem loading SITL FPI data (team, multi-call test)'
  mms_sitl_logout
  return, 1
end

; test public access to the SDC
function mms_load_data_ut::test_public_access_sdc
  mms_load_data, login_info='test_auth_info_pub.sav', trange=['2017-01-21', '2017-01-22'], $
    instrument='fgm', level='l2', data_rate='srvy', probe=1
    mms_sitl_logout
  return, 1
end

; test public access to the SDC with multiple calls
function mms_load_data_ut::test_public_access_sdc_multi
  mms_load_data, login_info='test_auth_info_pub.sav', trange=['2017-01-21', '2017-01-22'], $
    instrument='fgm', level='l2', data_rate='srvy', probe=1
  mms_load_data, login_info='test_auth_info_pub.sav', trange=['2017-01-21', '2017-01-22'], $
    instrument='fpi', level='l2', data_rate='fast', probe=1, datatype='des-moms'
  mms_load_data, login_info='test_auth_info_pub.sav', trange=['2017-01-21', '2017-01-22'], $
    instrument='edi', level='l2', data_rate='srvy', probe=1, datatype='efield'
  
  assert, tnames('mms1_fgm_b_gsm_srvy_l2') ne '', 'Problem loading L2 FGM data (public, multi-call test)'
  assert, tnames('mms1_des_numberdensity_fast') ne '', 'Problem loading L2 FPI data (public, multi-call test)'
  assert, tnames('mms1_edi_e_gsm_srvy_l2') ne '', 'Problem loading L2 EDI data (public, multi-call test)'
  mms_sitl_logout
  return, 1
end

pro mms_load_data_ut::setup
  ; do some setup for the tests
  del_data, '*'
end

function mms_load_data_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, 'mms_load_data'
  return, 1
end

pro mms_load_data_ut__define
  define = { mms_load_data_ut, inherits MGutTestCase }
end