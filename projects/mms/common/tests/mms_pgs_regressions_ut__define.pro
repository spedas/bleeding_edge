;+
;
; These are regression tests for bugs in mms_part_products
;
; To run:
;     IDL> mgunit, 'mms_pgs_regressions_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-05-03 09:14:43 -0700 (Thu, 03 May 2018) $
; $LastChangedRevision: 25160 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_pgs_regressions_ut__define.pro $
;-

; the following calculates the energy spectra of ions in the solar wind
; with and without bulk velocity subtraction, and checks that the maximum
; flux shifts down to the lowest energies when the ion bulk velocity was subtracted
; this test includes a pitch angle range, forcing FAC calculations
function mms_pgs_regressions_ut::test_bulk_vel_subtract_pa_range
  start_time = '2016-12-07/14:42:45' ; Tplot time range
  stop_time  = '2016-12-07/14:43:15'
  time = '2016-12-07/14:42:45'
  timespan, [start_time, stop_time]

  trange = timerange()
  support_trange = trange + [-60,60]
  probe = '3'
  rate = 'brst'
  species = 'i'

  mms_load_fpi, datatype=['d'+species+'s-dist', 'd'+species+'s-moms'], data_rate=rate, probe=probe, /time_clip
  mms_load_state, probes=probe, trange=support_trange
  mms_load_fgm, probe=probe, trange=support_trange, level='l2'

  name = 'mms'+probe+'_d'+species+'s_dist_'+rate
  bname = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  pos_name = 'mms' + probe+ '_defeph_pos'
  vel_name = 'mms' + probe+ '_d'+species+'s_bulkv_dbcs_brst'
  outputs = ['energy', 'theta', 'phi', 'pa', 'moments']
  pitch_angles = [1, 179]

  ; no bulk velocity subtraction
  mms_part_products_new, name, output=outputs, /silent, suffix='_Xgse', pitch=pitch_angles, mag_name=bname, pos_name=pos_name, vel_name=vel_name;, fac_type='Xgse'

  ; and now with bulk velocity subtraction
  mms_part_products_new, name, output=outputs, /silent, /subtract_bulk, suffix='_Xgse_bulk', pitch=pitch_angles, mag_name=bname, pos_name=pos_name, vel_name=vel_name;, fac_type='Xgse'

  get_data, 'mms3_dis_dist_brst_energy_Xgse', data=d
  max_data = max(d.Y[0, *], maxidx)
  assert, maxidx ne 0, 'Problem with mms_part_products regression test with bulk velocity subtraction'
  get_data, 'mms3_dis_dist_brst_energy_Xgse_bulk', data=d
  max_data = max(d.Y[0, *], maxidx)
  assert, maxidx eq 0 or (maxidx eq 1 and d.Y[0,0] eq 0.0), 'Problem with mms_part_products regression test with bulk velocity subtraction'
  return, 1
end

; the following calculates the energy spectra of ions in the solar wind 
; with and without bulk velocity subtraction, and checks that the maximum 
; flux shifts down to the lowest energies when the ion bulk velocity was subtracted
function mms_pgs_regressions_ut::test_bulk_vel_subtract
  start_time = '2016-12-07/14:42:45' ; Tplot time range
  stop_time  = '2016-12-07/14:43:15'
  time = '2016-12-07/14:42:45'
  timespan, [start_time, stop_time]
  
  trange = timerange()
  support_trange = trange + [-60,60]
  probe = '3'
  rate = 'brst'
  species = 'i'
  
  mms_load_fpi, datatype=['d'+species+'s-dist', 'd'+species+'s-moms'], data_rate=rate, probe=probe, /time_clip
  mms_load_state, probes=probe, trange=support_trange
  mms_load_fgm, probe=probe, trange=support_trange, level='l2'
  
  name = 'mms'+probe+'_d'+species+'s_dist_'+rate
  bname = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  pos_name = 'mms' + probe+ '_defeph_pos'
  vel_name = 'mms' + probe+ '_d'+species+'s_bulkv_dbcs_brst'
  outputs = ['energy', 'theta', 'phi']

  ; no bulk velocity subtraction
  mms_part_products_new, name, output=outputs, /silent, suffix='_Xgse', pitch=pitch_angles, mag_name=bname, pos_name=pos_name, vel_name=vel_name, fac_type='Xgse'

  ; and now with bulk velocity subtraction
  mms_part_products_new, name, output=outputs, /silent, /subtract_bulk, suffix='_Xgse_bulk', pitch=pitch_angles, mag_name=bname, pos_name=pos_name, vel_name=vel_name, fac_type='Xgse'

  get_data, 'mms3_dis_dist_brst_energy_Xgse', data=d
  max_data = max(d.Y[0, *], maxidx)
  assert, maxidx ne 0, 'Problem with mms_part_products regression test with bulk velocity subtraction'
  get_data, 'mms3_dis_dist_brst_energy_Xgse_bulk', data=d
  max_data = max(d.Y[0, *], maxidx)
  assert, maxidx eq 0 or (maxidx eq 1 and d.Y[0,0] eq 0.0), 'Problem with mms_part_products regression test with bulk velocity subtraction'
  return, 1
end

pro mms_pgs_regressions_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
  ; create a connection to the LASP SDC with team member access
  mms_load_data, login_info='test_auth_info_team.sav', instrument='fgm'
end

function mms_pgs_regressions_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_part_products', $
    'spd_pgs_moments', $
    'spd_pgs_make_theta_spec', $
    'spd_pgs_make_phi_spec', $
    'spd_pgs_make_e_spec', $
    'spd_pgs_v_shift', $
    'spd_pgs_regrid', $
    'spd_pgs_do_fac', $
    'mms_pgs_split_hpca', $
    'spd_pgs_limit_range']
  self->addTestingRoutine, ['mms_get_dist', $
    'mms_get_fpi_dist', $
    'mms_get_hpca_dist'], /is_function
  return, 1
end

pro mms_pgs_regressions_ut__define

  define = { mms_pgs_regressions_ut, inherits MGutTestCase }
end