;+
;
; Unit tests for mms_part_getspec
;
; To run:
;     IDL> mgunit, 'mms_part_getspec_ut'
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-03-08 09:26:59 -0800 (Thu, 08 Mar 2018) $
; $LastChangedRevision: 24855 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_part_getspec_ut__define.pro $
;-

function mms_part_getspec_ut::test_hpca_flux_units
  mms_part_getspec, probe=4, instrument='hpca', units='flux', trange=['2017-10-15/10:50', '2017-10-15/11:00']
  mms_hpca_calc_anodes, fov=[0, 360]
  tplot, ['mms4_hpca_hplus_flux_elev_0-360', 'mms4_hpca_hplus_phase_space_density_energy']
  makepng, 'hpca_hplus_flux_comparison'
  return, 1
end

function mms_part_getspec_ut::test_pa_limits_fpi
  mms_part_getspec, probe=4, trange=['2015-12-15/10:50', '2015-12-15/11:00'], pitch=[0, 90]
  get_data, 'mms4_des_dist_fast_pa', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with PA limits for FPI'
  return, 1
end

function mms_part_getspec_ut::test_pa_limits_fpi_brst
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], pitch=[0, 90], data_rate='brst'
  get_data, 'mms4_des_dist_brst_pa', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with PA limits for FPI (brst)'
  return, 1
end

function mms_part_getspec_ut::test_pa_limits_hpca
  mms_part_getspec, probe=4, trange=['2015-12-15/10:50', '2015-12-15/11:00'], pitch=[45, 135], instrument='hpca'
  get_data, 'mms4_hpca_hplus_phase_space_density_pa', data=d
  assert, total(finite(d.Y[0, 0:4])) eq 0 and total(finite(d.Y[0, 13:*])) eq 0, 'Problem with PA limits for HPCA!'
  return, 1
end

function mms_part_getspec_ut::test_tplotnames
  mms_part_getspec, probe=4, trange=['2015-12-15/10:50', '2015-12-15/11:00'], tplotnames=tn
  assert, n_elements(tn) eq 5 && array_equal(tn, 'mms4_des_dist_fast_'+['energy', 'theta', 'phi', 'pa', 'gyro']), 'Problem with tplotnames keyword'
  return, 1
end

function mms_part_getspec_ut::test_tplotnames_multi_sc
  mms_part_getspec, probes=[1, 2, 3, 4], trange=['2015-12-15/10:50', '2015-12-15/11:00'], tplotnames=tn
  vars = ['mms1_des_dist_fast_'+['energy', 'theta', 'phi', 'pa', 'gyro'], 'mms2_des_dist_fast_'+['energy', 'theta', 'phi', 'pa', 'gyro'], 'mms3_des_dist_fast_'+['energy', 'theta', 'phi', 'pa', 'gyro'], 'mms4_des_dist_fast_'+['energy', 'theta', 'phi', 'pa', 'gyro']]
  assert, n_elements(tn) eq 20 && array_equal(tn, vars), 'Problem with tplotnames keyword'
  return, 1
end

function mms_part_getspec_ut::test_suffix
  mms_part_getspec, probe=4, trange=['2015-12-15/10:50', '2015-12-15/11:00'], suffix='_testsuffix'
  assert, spd_data_exists('mms4_des_dist_fast_energy_testsuffix mms4_des_dist_fast_theta_testsuffix mms4_des_dist_fast_pa_testsuffix', '2015-12-15/10:50', '2015-12-15/11:00'), 'Problem with suffix!'
  return, 1
end

function mms_part_getspec_ut::test_theta_limits_fpi
  mms_part_getspec, probe=4, trange=['2015-12-15/10:50', '2015-12-15/11:00'], theta=[0, 90]
  get_data, 'mms4_des_dist_fast_theta', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with theta limits for FPI'
  return, 1
end

function mms_part_getspec_ut::test_theta_limits_fpi_brst
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], theta=[0, 90], data_rate='brst'
  get_data, 'mms4_des_dist_brst_theta', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with theta limits for FPI (brst)'
  return, 1
end

function mms_part_getspec_ut::test_theta_limits_hpca
  mms_part_getspec, probe=2, trange=['2017-10-15/10:00', '2017-10-15/11:00'], instrument='hpca', theta=[0, 90]
  get_data, 'mms2_hpca_hplus_phase_space_density_theta', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with theta limits for HPCA!'
  return, 1
end

function mms_part_getspec_ut::test_theta_limits_hpca_brst
  del_data, '*'
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], instrument='hpca', theta=[0, 90], data_rate='brst'
  get_data, 'mms4_hpca_hplus_phase_space_density_theta', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with theta limits for HPCA! (brst)'
  return, 1
end

function mms_part_getspec_ut::test_phi_limits_fpi
  mms_part_getspec, probe=4, trange=['2015-12-15/10:50', '2015-12-15/11:00'], phi=[0, 175]
  get_data, 'mms4_des_dist_fast_phi', data=d
  assert, total(finite(d.Y[0, 16:-2])) eq 0, 'Problem with phi limits for FPI'
  return, 1
end

function mms_part_getspec_ut::test_phi_limits_fpi_brst
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], phi=[0, 175], data_rate='brst'
  get_data, 'mms4_des_dist_brst_phi', data=d
  assert, total(finite(d.Y[0, 16:-2])) eq 0, 'Problem with phi limits for FPI (brst)'
  return, 1
end

function mms_part_getspec_ut::test_phi_limits_hpca
  mms_part_getspec, probe=1, trange=['2016-12-15/10:00', '2016-12-15/11:00'], phi=[0, 175], instrument='hpca'
  get_data, 'mms1_hpca_hplus_phase_space_density_phi', data=d
  assert, total(finite(d.Y[0, 8:-2])) eq 0, 'Problem with phi limits for HPCA'
  return, 1
end

function mms_part_getspec_ut::test_phi_limits_hpca_brst
  mms_part_getspec, probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07'], phi=[0, 175], instrument='hpca', data_rate='brst'
  get_data, 'mms1_hpca_hplus_phase_space_density_phi', data=d
  assert, total(finite(d.Y[0, 8:-2])) eq 0, 'Problem with phi limits for HPCA (brst)'
  return, 1
end

function mms_part_getspec_ut::test_energy_limits_fpi_brst
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], energy=[0, 100], data_rate='brst'
  get_data, 'mms4_des_dist_brst_energy', data=d
  assert, total(finite(d.Y[0, 9:*])) eq 0, 'Problem with energy limits for FPI (brst)'
  return, 1
end

function mms_part_getspec_ut::test_energy_limits_fpi
  mms_part_getspec, probe=4, trange=['2015-12-15/10:00', '2015-12-15/11:00'], energy=[0, 100]
  get_data, 'mms4_des_dist_fast_energy', data=d
  assert, total(finite(d.Y[0, 9:*])) eq 0, 'Problem with energy limits for FPI'
  return, 1
end

function mms_part_getspec_ut::test_energy_limits_hpca_brst
  mms_part_getspec, probe=1, trange=['2015-12-15/10:00', '2015-12-15/11:00'], energy=[0, 100], instrument='hpca', data_rate='brst'
  get_data, 'mms1_hpca_hplus_phase_space_density_energy', data=d
  assert, total(finite(d.Y[0, 27:*])) eq 0, 'Problem with energy limits for HPCA (brst)'
  return, 1
end

function mms_part_getspec_ut::test_energy_limits_hpca
  mms_part_getspec, probe=1, trange=['2017-10-15/10:00', '2017-10-15/11:00'], energy=[0, 100], instrument='hpca'
  get_data, 'mms1_hpca_hplus_phase_space_density_energy', data=d
  assert, total(finite(d.Y[0, 27:*])) eq 0, 'Problem with energy limits for HPCA'
  return, 1
end

function mms_part_getspec_ut::test_all_outputs_hpca_srvy
  mms_part_getspec, probe=1, trange=['2017-10-15/15:00', '2017-10-15/16:00'], instrument='hpca', species='hplus',  /silent, data_rate='srvy', outputs='energy phi theta pa gyro moments'
  mms_part_getspec, probe=1, trange=['2017-10-15/15:00', '2017-10-15/16:00'], instrument='hpca', species='oplus',  /silent, data_rate='srvy', outputs='energy phi theta pa gyro moments'
  mms_part_getspec, probe=1, trange=['2017-10-15/15:00', '2017-10-15/16:00'], instrument='hpca', species='heplus',  /silent, data_rate='srvy', outputs='energy phi theta pa gyro moments'
  mms_part_getspec, probe=1, trange=['2017-10-15/15:00', '2017-10-15/16:00'], instrument='hpca', species='heplusplus',  /silent, data_rate='srvy', outputs='energy phi theta pa gyro moments'
  assert, spd_data_exists('mms1_hpca_heplusplus_phase_space_density_energy mms1_hpca_heplusplus_phase_space_density_theta mms1_hpca_heplusplus_phase_space_density_phi mms1_hpca_heplusplus_phase_space_density_pa mms1_hpca_heplusplus_phase_space_density_gyro', '2017-10-15/15:00', '2017-10-15/16:00'), 'Problem testing all outputs for HPCA'
  return, 1
end

function mms_part_getspec_ut::test_all_outputs_fpi_fast
  mms_part_getspec, probe=1, trange=['2015-12-15/10:00', '2015-12-15/11:00'], instrument='fpi', species='i', /silent, data_rate='fast', outputs='energy phi theta pa gyro moments'
  mms_part_getspec, probe=1, trange=['2015-12-15/10:00', '2015-12-15/11:00'], instrument='fpi', species='e', /silent, data_rate='fast', outputs='energy phi theta pa gyro moments'
  assert, spd_data_exists('mms1_des_dist_fast_energy mms1_des_dist_fast_pa mms1_des_dist_fast_phi mms1_des_dist_fast_theta mms1_des_dist_fast_gyro', '2015-12-15/10:00', '2015-12-15/11:00'), 'Problem with FPI fast with all outputs!'
  return, 1
end

function mms_part_getspec_ut::test_add_dir_hpca
  mms_part_getspec, trange=['2017-10-15', '2017-10-15/00:20'], /add_bfield, /add_ram, probe=1, instrument='hpca'
  assert, spd_data_exists('mms1_hpca_hplus_phase_space_density_theta mms1_hpca_hplus_phase_space_density_theta_bdata mms1_hpca_hplus_phase_space_density_minustheta_bdata mms1_hpca_hplus_phase_space_density_theta_vdata', '2017-10-15', '2017-10-15/00:20'), 'Problem with HPCA add direction'
  assert, spd_data_exists('mms1_hpca_hplus_phase_space_density_phi mms1_hpca_hplus_phase_space_density_phi_bdata mms1_hpca_hplus_phase_space_density_minusphi_bdata', '2017-10-15', '2017-10-15/00:20'), 'Problem with HPCA add direction'
  assert, spd_data_exists('mms1_hpca_hplus_phase_space_density_phi mms1_hpca_hplus_phase_space_density_phi_vdata', '2017-10-15', '2017-10-15/00:20'), 'Problem with HPCA add direction'
  return, 1
end

function mms_part_getspec_ut::test_add_dir_fpi
  mms_part_getspec, trange=['2015-12-15', '2015-12-15/00:20'], /add_bfield, /add_ram, probe=1, instrument='fpi'
  assert, spd_data_exists('mms1_des_dist_fast_phi mms1_des_dist_fast_phi_bdata mms1_des_dist_fast_minusphi_bdata mms1_des_dist_fast_phi_vdata', '2015-12-15', '2015-12-15/00:20'), 'Problem with FPI add direction'
  assert, spd_data_exists('mms1_des_dist_fast_phi mms1_des_dist_fast_phi_vdata', '2015-12-15', '2015-12-15/00:20'), 'Problem with FPI add direction'
  assert, spd_data_exists('mms1_des_dist_fast_phi mms1_des_dist_fast_phi_bdata mms1_des_dist_fast_minusphi_bdata', '2015-12-15', '2015-12-15/00:20'), 'Problem with FPI add direction'
  return, 1
end

function mms_part_getspec_ut::test_dir_interval
  mms_part_getspec, dir_interval=4, trange=['2015-12-15', '2015-12-15/00:20'], /add_bfield, /add_ram, probe=1, instrument='fpi'
  get_data, 'mms1_des_dist_fast_phi_bdata', data=d
  assert, d.X[1]-d.X[0] eq 4.0, 'Problem with dir_interval keyword in mms_part_getspec'
  return, 1
end

function mms_part_getspec_ut::test_hpca_regression
  timespan, '2016-10-16/17:39:00', 5, /min
  mms_part_getspec, /silent, instrument='hpca', probe='1', species='hplus', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro', 'moments']
  assert, spd_data_exists('mms1_hpca_hplus_phase_space_density_energy mms1_hpca_hplus_phase_space_density_theta mms1_hpca_hplus_phase_space_density_phi mms1_hpca_hplus_phase_space_density_pa mms1_hpca_hplus_phase_space_density_gyro', '2016-10-16/17:39:00', '2016-10-16/17:44:00'), 'Problem with HPCA regression test'
  return, 1
end

function mms_part_getspec_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_part_getspec', 'mms_part_products']
  return, 1
end

pro mms_part_getspec_ut__define
  define = {mms_part_getspec_ut, $
            inherits spd_tests_with_img_ut}
end
