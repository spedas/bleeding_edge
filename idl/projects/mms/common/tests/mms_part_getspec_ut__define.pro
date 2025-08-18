;+
;
; Unit tests for mms_part_getspec
;
; To run:
;     IDL> mgunit, 'mms_part_getspec_ut'
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2023-11-09 10:31:32 -0800 (Thu, 09 Nov 2023) $
; $LastChangedRevision: 32226 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_part_getspec_ut__define.pro $
;-

function mms_part_getspec_ut::test_des_photoelectron_corrections
  ; load the moments data for comparisons
  mms_load_fpi, datatype='des-moms', trange=['2015-12-15', '2015-12-15/1'],  probe=1, /time_clip, data_rate='fast'
  mms_part_getspec, probe=1, species='e', /photoelectron_corrections, trange=['2015-12-15', '2015-12-15/1'], data_rate='fast', output='moments'
  calc, '"diff"=100*("mms1_des_dist_fast_density"-"mms1_des_numberdensity_fast")/"mms1_des_numberdensity_fast"
  get_data, 'diff', data=diff
  ; check that difference is <= 5% of the density provided by the moments files
  assert, (minmax(abs(diff.Y)))[1] le 5.0, 'Problem with photoelectron corrections in PGS'
  return, 1
end

; the following produce validation plots that compare DIS and HPCA spectra
function mms_part_getspec_ut::test_dis_hpca_cold
  assert,(!d.name ne "Z"),"Graphics not available",/skip
  mms_part_getspec, energy=[0, 300], suffix='_cold', instrument='hpca', trange=['2017-08-12/23', '2017-08-12/24'], output=['energy', 'pa', 'gyro', 'phi', 'theta'], probe=3
  mms_part_getspec, energy=[0, 300], suffix='_cold', species='i', instrument='fpi', trange=['2017-08-12/23', '2017-08-12/24'], output=['energy','phi','theta','pa','gyro'], probe=3
  tplot, ['mms3_dis_dist_fast_pa_cold', 'mms3_hpca_hplus_phase_space_density_pa_cold']
  makepng, 'dis-vs-hpca-pa-cold'
  if (!d.name ne "Z") then window, 1, retain=2
  tplot, window=1, ['mms3_dis_dist_fast_gyro_cold', 'mms3_hpca_hplus_phase_space_density_gyro_cold']
  makepng, 'dis-vs-hpca-gyro-cold'
  if (!d.name ne "Z") then window, 2, retain=2
  tplot, window=2, ['mms3_dis_dist_fast_energy_cold', 'mms3_hpca_hplus_phase_space_density_energy_cold']
  makepng, 'dis-vs-hpca-energy-cold'
  return, 1
end

function mms_part_getspec_ut::test_dis_hpca_full
  assert,(!d.name ne "Z"),"Graphics not available",/skip
  mms_part_getspec, suffix='_full', instrument='hpca', trange=['2017-08-12/23', '2017-08-12/24'], output=['energy', 'pa', 'gyro', 'phi', 'theta'], probe=3
  mms_part_getspec, suffix='_full', species='i', instrument='fpi', trange=['2017-08-12/23', '2017-08-12/24'], output=['energy','phi','theta','pa','gyro'], probe=3
  tplot, ['mms3_dis_dist_fast_pa_full', 'mms3_hpca_hplus_phase_space_density_pa_full']
  makepng, 'dis-vs-hpca-pa-full'
  flatten_spectra, /ylog, time='2017-08-12/23:35:12', /png
  if (!d.name ne "Z") then window, 1, retain=2
  tplot, window=1, ['mms3_dis_dist_fast_gyro_full', 'mms3_hpca_hplus_phase_space_density_gyro_full']
  makepng, 'dis-vs-hpca-gyro-full'
  flatten_spectra, /ylog, time='2017-08-12/23:35:12', /png
  if (!d.name ne "Z") then window, 2, retain=2
  tplot, window=2, ['mms3_dis_dist_fast_energy_full', 'mms3_hpca_hplus_phase_space_density_energy_full']
  makepng, 'dis-vs-hpca-energy-full'
  flatten_spectra, /ylog, time='2017-08-12/23:35:12', /png
  return, 1
end

; -----------------end of the DIS vs. HPCA validation plots

; the following compares eflux produced from the PSD from the getspec code with the eflux in the CDF 
; file (converted to eflux by multiplying by energy)
function mms_part_getspec_ut::test_hpca_eflux_vs_pgs
  mms_part_getspec, suffix='_full', instrument='hpca', trange=['2017-08-12/23', '2017-08-12/24'], output=['energy', 'pa', 'gyro', 'phi', 'theta'], probe=3
  mms_load_hpca, trange=['2017-08-12/23', '2017-08-12/24'], /time_clip, probe=3, datatype='ion'
  mms_hpca_calc_anodes, fov=[0, 360], probe=3
  mms_hpca_spin_sum, probe='3', /avg
  get_data, 'mms3_hpca_hplus_flux_elev_0-360_spin', data=d, dlimits=dl
  newdy = d.Y
  for vi=0, n_elements(d.X)-1 do newdy[vi, *] = d.Y[vi, *]*d.V
  store_data, 'hpca_eflux', data={x: d.X, y: newdy, v: d.v}, dlimits=dl
  ylim, 'hpca_eflux', 0, 0, 1
  zlim, 'hpca_eflux', 0, 0, 1
  tplot, ['mms3_hpca_hplus_phase_space_density_energy_full', 'hpca_eflux']
  makepng, 'hpca-pgs-eflux-vs-cdf-eflux'
  flatten_spectra, /ylog, time='2017-08-12/23:35:12', /png
  return, 1
end

function mms_part_getspec_ut::test_fpi_eflux_vs_pgs
  mms_part_getspec, suffix='_full', instrument='fpi', species='i', trange=['2017-08-12/23', '2017-08-12/24'], output=['energy', 'pa', 'gyro', 'phi', 'theta'], probe=3
  mms_load_fpi, datatype='dis-moms', trange=['2017-08-12/23', '2017-08-12/24'], /time_clip, probe=3
  tplot, ['mms3_dis_energyspectr_omni_fast', 'mms3_dis_dist_fast_energy_full']
  makepng, 'dis-eflux-vs-pgs-eflux'
  return, 1
end

function mms_part_getspec_ut::test_fpi_e_eflux_vs_pgs
  spd_graphics_config
  mms_part_getspec, suffix='_full', instrument='fpi', species='e', trange=['2017-08-12/23', '2017-08-12/24'], output=['energy', 'pa', 'gyro', 'phi', 'theta'], probe=3
  mms_load_fpi, datatype='des-moms', trange=['2017-08-12/23', '2017-08-12/24'], /time_clip, probe=3
  tplot, ['mms3_des_energyspectr_omni_fast', 'mms3_des_dist_fast_energy_full']
  makepng, 'des-eflux-vs-pgs-eflux'
  return, 1
end

function mms_part_getspec_ut::test_fpi_multipad
  mms_part_getspec, probe=4, trange=['2017-10-15/10:50', '2017-10-15/11:00'], output='pa multipad'
  mms_part_getpad, probe=4
  tplot, ['mms4_des_dist_fast_pa', 'mms4_des_dist_fast_pad_6.5200000eV_27525.000eV']
  makepng, 'multipad-des-pgs-vs-getpad'
  assert, spd_data_exists('mms4_des_dist_fast_pa mms4_des_dist_fast_pad_6.5200000eV_27525.000eV', '2017-10-15/10:50', '2017-10-15/11:00'), 'Problem with multipad test in mms_part_getspec_ut'
  return, 1
end

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
  assert, total(finite(d.Y[0, 0:3])) eq 0 and total(finite(d.Y[0, 12:*])) eq 0, 'Problem with PA limits for HPCA!'
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
  mms_part_getspec, probe=1, trange=['2016-10-16/17:40:00', '2016-10-16/17:42:00'], energy=[0, 100], instrument='hpca', data_rate='brst'
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

function mms_part_getspec_ut::test_add_dir_fpi_suffix
  mms_part_getspec, suffix='_suffix', trange=['2015-12-15', '2015-12-15/00:20'], /add_bfield, /add_ram, probe=1, instrument='fpi'
  assert, spd_data_exists('mms1_des_dist_fast_phi_suffix mms1_des_dist_fast_phi_bdata mms1_des_dist_fast_minusphi_bdata mms1_des_dist_fast_phi_vdata', '2015-12-15', '2015-12-15/00:20'), 'Problem with FPI add direction (suffix)'
  assert, spd_data_exists('mms1_des_dist_fast_phi_suffix mms1_des_dist_fast_phi_vdata', '2015-12-15', '2015-12-15/00:20'), 'Problem with FPI add direction (suffix)'
  assert, spd_data_exists('mms1_des_dist_fast_phi_suffix mms1_des_dist_fast_phi_bdata mms1_des_dist_fast_minusphi_bdata', '2015-12-15', '2015-12-15/00:20'), 'Problem with FPI add direction (suffix)'
  get_data, 'mms1_des_dist_fast_phi_with_b_suffix', data=d
  assert, n_elements(tnames(d)) eq 3, 'Problem with FPI add direction (suffix)'
  get_data, 'mms1_des_dist_fast_phi_with_v_suffix', data=d
  assert, n_elements(tnames(d)) eq 2, 'Problem with FPI add direction (suffix)'
  get_data, 'mms1_des_dist_fast_phi_with_bv_suffix', data=d
  assert, n_elements(tnames(d)) eq 4, 'Problem with FPI add direction (suffix)'
  get_data, 'mms1_des_dist_fast_theta_with_b_suffix', data=d
  assert, n_elements(tnames(d)) eq 3, 'Problem with FPI add direction (suffix)'
  get_data, 'mms1_des_dist_fast_theta_with_v_suffix', data=d
  assert, n_elements(tnames(d)) eq 2, 'Problem with FPI add direction (suffix)'
  get_data, 'mms1_des_dist_fast_theta_with_bv_suffix', data=d
  assert, n_elements(tnames(d)) eq 4, 'Problem with FPI add direction (suffix)'
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

pro mms_part_getspec_ut::teardown
  del_data, '*'
end

function mms_part_getspec_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_part_getspec', 'mms_part_products']
  mms_init
  return, 1
end

pro mms_part_getspec_ut__define
  define = {mms_part_getspec_ut, $
            inherits spd_tests_with_img_ut}
end
