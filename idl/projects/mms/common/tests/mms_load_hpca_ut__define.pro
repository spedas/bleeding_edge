;+
;
; Unit tests for mms_load_hpca
;
; To run:
;     IDL> mgunit, 'mms_load_hpca_ut'
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2023-10-26 15:20:30 -0700 (Thu, 26 Oct 2023) $
; $LastChangedRevision: 32208 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_hpca_ut__define.pro $
;-

function mms_load_hpca_ut::test_hpca_spin_sum_suffix
  mms_load_hpca, probes=2, trange=['2016-08-09/09:10', '2016-08-09/10:10:00'], datatype='ion', level='l2', data_rate='brst',suffix = '_brst'
  mms_hpca_calc_anodes, fov=[0, 360], probe=2, suffix='_brst'
  mms_hpca_spin_sum, probe=2, /avg, suffix='_brst'
  assert, spd_data_exists('mms2_hpca_hplus_flux_brst_elev_0-360_spin mms2_hpca_heplus_flux_brst_elev_0-360_spin mms2_hpca_heplusplus_flux_brst_elev_0-360_spin mms2_hpca_oplus_flux_brst_elev_0-360_spin', '2016-08-09/09:10', '2016-08-09/10:10:00'), 'regression spin-summing with a suffix'
  return, 1
end

function mms_load_hpca_ut::test_hpca_angle_angle_hplus
  mms_hpca_ang_ang, '2015-10-16/13:06:43', species='hplus', data_rate='brst',/png
  return, 1
end

function mms_load_hpca_ut::test_sitl_combined
  mms_load_hpca, level='sitl', datatype='combined', trange=['2019-02-01', '2019-02-02']
  assert, spd_data_exists('mms1_hpca_hplus_omni_flux mms1_hpca_heplusplus_omni_flux mms1_hpca_oplus_omni_flux mms1_hpca_hplus_number_density mms1_hpca_heplusplus_number_density mms1_hpca_oplus_number_density mms1_hpca_hplus_ion_bulk_velocity mms1_hpca_heplusplus_ion_bulk_velocity mms1_hpca_oplus_ion_bulk_velocity', '2019-02-01', '2019-02-02'), 'Problem with HPCA SITL combined datatype'
  return, 1
end

function mms_load_hpca_ut::test_varformat_string
  mms_load_hpca, varformat='*velocity* *tparallel', trange=['2017-10-15', '2017-10-16']
  assert, (tnames('mms1_hpca_ion_energy'))[0] ne '', 'Varformat string regression'
  assert, spd_data_exists('mms1_hpca_heplusplus_tparallel mms1_hpca_hplus_ion_bulk_velocity mms1_hpca_oplus_ion_bulk_velocity', '2017-10-15', '2017-10-16'), $
    'Varformat string regression'
   return, 1
end

function mms_load_hpca_ut::test_varformat_array
  mms_load_hpca, varformat=['*velocity*', '*tparallel'],  trange=['2017-10-15', '2017-10-16']
  assert, (tnames('mms1_hpca_ion_energy'))[0] ne '', 'Varformat array regression'
  assert, spd_data_exists('mms1_hpca_heplusplus_tparallel mms1_hpca_hplus_ion_bulk_velocity mms1_hpca_oplus_ion_bulk_velocity', '2017-10-15', '2017-10-16'), $
    'Varformat array regression'
  return, 1
end

function mms_load_hpca_ut::test_center_burst_dist_spdf
  mms_load_hpca, data_rate='brst', level='l2', datatype='ion', /center, suffix='_centered', /SPDF
  mms_load_hpca, data_rate='brst', level='l2', datatype='ion', /SPDF
  get_data, 'mms1_hpca_hplus_flux_centered', data=centered
  get_data, 'mms1_hpca_hplus_flux', data=not_centered
  assert, centered.X[2]-not_centered.X[2] eq 0.3125, 'Problem centering HPCA burst mode dist data'
  return, 1
end

function mms_load_hpca_ut::test_center_burst_spdf
  mms_load_hpca, data_rate='brst', level='l2', datatype='moments', /center, suffix='_centered', /spdf
  mms_load_hpca, data_rate='brst', level='l2', datatype='moments', /spdf
  get_data, 'mms1_hpca_hplus_ion_bulk_velocity', data=not_centered ; not centered
  get_data, 'mms1_hpca_hplus_ion_bulk_velocity_centered', data=centered ; centered
  ; centering adjusts by ~5 seconds
  assert, round(centered.X[2]-not_centered.X[2]) eq 5, 'Problem centering HPCA burst mode moments data (SPDF)'
  return, 1
end

function mms_load_hpca_ut::test_center_burst
  mms_load_hpca, data_rate='brst', level='l2', datatype='moments', /center, suffix='_centered'
  mms_load_hpca, data_rate='brst', level='l2', datatype='moments'
  get_data, 'mms1_hpca_hplus_ion_bulk_velocity', data=not_centered ; not centered
  get_data, 'mms1_hpca_hplus_ion_bulk_velocity_centered', data=centered ; centered
  ; centering adjusts by ~5 seconds
  assert, round(centered.X[2]-not_centered.X[2]) eq 5, 'Problem centering HPCA burst mode moments data'
  return, 1
end

function mms_load_hpca_ut::test_center_burst_dist
  mms_load_hpca, data_rate='brst', level='l2', datatype='ion', /center, suffix='_centered'
  mms_load_hpca, data_rate='brst', level='l2', datatype='ion'
  get_data, 'mms1_hpca_hplus_flux_centered', data=centered
  get_data, 'mms1_hpca_hplus_flux', data=not_centered
  assert, centered.X[2]-not_centered.X[2] eq 0.3125, 'Problem centering HPCA burst mode dist data'
  return, 1
end

function mms_load_hpca_ut::test_load_spdf_burst
  mms_load_hpca, /spdf, trange=['2015-12-15', '2015-12-16'], level='l2', datatype='moments', data_rate='brst'
  assert, spd_data_exists('mms1_hpca_hplus_number_density mms1_hpca_heplus_scalar_temperature mms1_hpca_hplus_vperp', '2015-12-15', '2015-12-16'), $
    'Problem loading burst mode data from SPDF'
  return, 1
end

function mms_load_hpca_ut::test_load_spdf_srvy
  mms_load_hpca, /spdf, trange=['2017-10-15', '2017-10-16'], level='l2', datatype='moments', data_rate='srvy'
  assert, spd_data_exists('mms1_hpca_hplus_number_density mms1_hpca_heplus_scalar_temperature mms1_hpca_hplus_vperp', '2017-10-15', '2017-10-16'), $
    'Problem loading srvy mode data from SPDF'
  return, 1
end
function mms_load_hpca_ut::test_multi_probe
  mms_load_hpca, probes=[1, '2', 3, 4], trange=['2016-12-15', '2016-12-16'], datatype='moments'
  assert, spd_data_exists('mms4_hpca_hplus_number_density mms3_hpca_hplus_number_density mms2_hpca_hplus_number_density mms1_hpca_hplus_number_density', '2016-12-15', '2016-12-16'), $
    'Problem loading HPCA data with multiple probes requested'
  return, 1
end

function mms_load_hpca_ut::test_load_bad_entable
  mms_load_hpca, probe=1, level='l2', trange=['2015-9-1', '2015-9-2'], datatype='flux'
  get_data, 'mms1_hpca_hplus_flux', data=d
  assert, d.V2[0] eq 1.355, 'Problem with energy table (regression?)
  return, 1
end

function mms_load_hpca_ut::test_burst_caps
  mms_load_hpca, probe=1, level='L2', trange=['2015-12-15', '2015-12-16'], data_rate='BRST'
  assert, spd_data_exists('mms1_hpca_heplus_ion_bulk_velocity mms1_hpca_heplus_ion_pressure mms1_hpca_oplus_temperature_tensor', '2015-12-15', '2015-12-16'), $
    'Problem loading burst mode HPCA moment data (caps)'
  return, 1
end

function mms_load_hpca_ut::test_center_keyword_varformat
  mms_load_hpca, varformat='*hplus*', probe=1, level='l2', datatype='moments', trange=['2017-10-15', '2017-10-16'], /center_measurement, suffix='_centered'
  mms_load_hpca, varformat='*hplus*', probe=1, level='l2', datatype='moments', trange=['2017-10-15', '2017-10-16']
  get_data, 'mms1_hpca_hplus_ion_bulk_velocity', data=not_centered ; not centered
  get_data, 'mms1_hpca_hplus_ion_bulk_velocity_centered', data=centered ; centered
  ; centering adjusts by ~5 seconds
  assert, round(centered.X[2]-not_centered.X[2]) eq 5, 'Problem centering HPCA moments data'
  return, 1
end

function mms_load_hpca_ut::test_center_keyword
  mms_load_hpca, probe=1, level='l2', datatype='moments', trange=['2017-10-15', '2017-10-16'], /center_measurement, suffix='_centered'
  mms_load_hpca, probe=1, level='l2', datatype='moments', trange=['2017-10-15', '2017-10-16']
  get_data, 'mms1_hpca_hplus_ion_bulk_velocity', data=not_centered ; not centered
  get_data, 'mms1_hpca_hplus_ion_bulk_velocity_centered', data=centered ; centered
  ; centering adjusts by ~5 seconds
  assert, round(centered.X[2]-not_centered.X[2]) eq 5, 'Problem centering HPCA moments data'
  return, 1
end

function mms_load_hpca_ut::test_count_rate_l1b
  mms_load_hpca, probe=1, level='l1b', datatype='count_rate', trange=['2015-12-15', '2015-12-16']
  mms_hpca_calc_anodes, fov=[0, 180]
  mms_hpca_calc_anodes, fov=[180, 360]
  assert, spd_data_exists('mms1_hpca_oplusplus_count_rate_elev_0-180 mms1_hpca_hplus_count_rate_elev_0-180 mms1_hpca_heplus_count_rate_elev_0-180 mms1_hpca_oplusplus_count_rate_elev_180-360 mms1_hpca_hplus_count_rate_elev_180-360 mms1_hpca_heplusplus_count_rate_elev_180-360', '2015-12-15', '2015-12-16'), $
    'Problem loading HPCA L1b count rate data'
  return, 1
end

function mms_load_hpca_ut::test_rf_corr_l1b
  mms_load_hpca, probe=4, level='l1b', datatype='rf_corr', trange=['2015-12-15', '2015-12-16']
  mms_hpca_calc_anodes, fov=[0, 360]
  assert, spd_data_exists('mms4_hpca_oplusplus_RF_corrected_elev_0-360 mms4_hpca_hplus_RF_corrected_elev_0-360 mms4_hpca_heplus_RF_corrected_elev_0-360 mms4_hpca_oplus_RF_corrected_elev_0-360', '2015-12-15', '2015-12-16'), $
    'Problem loading HPCA RF corrected counts (L1b)'
  return, 1
end

function mms_load_hpca_ut::test_flux_anodes
  mms_load_hpca, probe=3, level='l2', datatype='ion'
  mms_hpca_calc_anodes, anodes=[5, 7, 10]
  assert, spd_data_exists('mms3_hpca_hplus_flux_anodes_5_7_10 mms3_hpca_heplus_flux_anodes_5_7_10 mms3_hpca_heplusplus_flux_anodes_5_7_10 mms3_hpca_oplus_flux_anodes_5_7_10', '2017-9-22/11:08', '2017-9-22/11:13'), $
    'Problem with HPCA flux anodes calculation'
  return, 1
end

function mms_load_hpca_ut::test_flux_anodes_suffix
  mms_load_hpca, probe=3, level='l2', datatype='ion', suffix='_anodessuffix'
  mms_hpca_calc_anodes, anodes=[5, 7, 10], suffix='_anodessuffix'
  assert, spd_data_exists('mms3_hpca_hplus_flux_anodessuffix_anodes_5_7_10 mms3_hpca_heplus_flux_anodessuffix_anodes_5_7_10 mms3_hpca_heplusplus_flux_anodessuffix_anodes_5_7_10 mms3_hpca_oplus_flux_anodessuffix_anodes_5_7_10', '2017-9-22/11:08', '2017-9-22/11:13'), $
    'Problem with HPCA flux anodes calculation'
  return, 1
end

function mms_load_hpca_ut::test_load_burst_moms
  mms_load_hpca, probe=1, level='l2', data_rate='brst'
  assert, spd_data_exists('mms1_hpca_hplus_scalar_temperature mms1_hpca_oplus_scalar_temperature mms1_hpca_heplus_ion_bulk_velocity_GSM', '2017-9-22/11:08', '2017-9-22/11:13'), $
    'Problem loading L2 burst mode HPCA data'
  return, 1
end

function mms_load_hpca_ut::test_load_burst_flux
  mms_load_hpca, probe=2, level='l2', data_rate='brst', datatype='ion', trange=['2015-12-15', '2015-12-16']
  mms_hpca_calc_anodes, fov=[0, 360]
  assert, spd_data_exists('mms2_hpca_hplus_flux_elev_0-360 mms2_hpca_heplus_flux_elev_0-360 mms2_hpca_oplus_flux_elev_0-360 mms2_hpca_heplusplus_flux_elev_0-360', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 burst mode HPCA flux'
  return, 1
end

function mms_load_hpca_ut::test_load_burst_flux_suffix
  mms_load_hpca, probe=2, level='l2', data_rate='brst', datatype='ion', suffix='_testsuffix', trange=['2015-12-15', '2015-12-16']
  mms_hpca_calc_anodes, fov=[0, 360], suffix='_testsuffix'
  assert, spd_data_exists('mms2_hpca_hplus_flux_testsuffix_elev_0-360 mms2_hpca_heplus_flux_testsuffix_elev_0-360 mms2_hpca_oplus_flux_testsuffix_elev_0-360 mms2_hpca_heplusplus_flux_testsuffix_elev_0-360', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 burst mode HPCA flux with suffix'
  return, 1
end

; regression test for bug reported by Karlheinz Trattner, 3/23/2016
function mms_load_hpca_ut::test_load_startaz
    ; load the data
    mms_load_hpca, probes=probes, datatype='flux', level='l1b', data_rate='srvy',/get_support_data
    mms_hpca_calc_anodes, fov=[0, 360], probe=probes
    mms_hpca_spin_sum, probe=probes, species='hplus',fov=[0,360],datatype='flux'
    assert, spd_data_exists('mms1_hpca_start_azimuth mms1_hpca_hplus_flux_elev_0-360 mms1_hpca_hplus_flux_elev_0-360_spin', '2017-9-22/11:08', '2017-9-22/11:13'), 'Problem loading HPCA data (startaz regression?)'
    return, 1
end

function mms_load_hpca_ut::test_load_startaz_nosupp
  ; load the data
  mms_load_hpca, probes=probes, datatype='flux', level='l1b', data_rate='srvy'
  mms_hpca_calc_anodes, fov=[0, 360], probe=probes
  mms_hpca_spin_sum, probe=probes, species='hplus',fov=[0,360],datatype='flux'
  assert, spd_data_exists('mms1_hpca_start_azimuth mms1_hpca_hplus_flux_elev_0-360 mms1_hpca_hplus_flux_elev_0-360_spin', '2017-9-22/11:08', '2017-9-22/11:13'), 'Problem loading HPCA data (startaz regression?)'
  return, 1
end

function mms_load_hpca_ut::test_load_startaz_nosupp_l2
  ; load the data
  mms_load_hpca, probes=probes, datatype='flux', level='l2', data_rate='srvy'
  mms_hpca_calc_anodes, fov=[0, 360], probe=probes
  mms_hpca_spin_sum, probe=probes, species='hplus',fov=[0,360],datatype='flux'
  assert, spd_data_exists('mms1_hpca_start_azimuth mms1_hpca_hplus_flux_elev_0-360 mms1_hpca_hplus_flux_elev_0-360_spin', '2017-9-22/11:08', '2017-9-22/11:13'), 'Problem loading HPCA data (startaz regression?)'
  return, 1
end

function mms_load_hpca_ut::test_load_caps_datatype
  mms_load_hpca, probes=1, datatype='ION', level='l2', data_rate='srvy'
  mms_hpca_calc_anodes, fov=[0, 360], probe=1
  assert, spd_data_exists('mms1_hpca_oplus_flux_elev_0-360 mms1_hpca_hplus_flux_elev_0-360', '2017-9-22/11:08', '2017-9-22/11:13'), 'Problem loading HPCA data (startaz regression?)'
  return, 1
end

function mms_load_hpca_ut::test_loading_tplotnames_ion
  mms_load_hpca, probes=2, datatype='ion', level='l2', data_rate='srvy', tplotnames=tpnames
  assert, n_elements(tpnames) eq 31, '(potential) Problem with number of tplotnames returned by mms_load_hpca (ion)'
  return, 1
end

function mms_load_hpca_ut::test_loading_tplotames_moments
  mms_load_hpca, probe=3, datatype='moments', level='l2', data_rate='srvy', tplotnames=tpnames
  assert, n_elements(tpnames) eq 56, '(potential) Problem with number of tplotnames returned by mms_load_hpca (moments)'
  return, 1
end

function mms_load_hpca_ut::test_loading_invalid_datarate
  mms_load_hpca, probe=3, datatype='moments', data_rate='notvalid'
  assert, ~spd_data_exists('mms3_hpca_hplus_number_density', '2017-9-22/11:08', '2017-9-22/11:13'), $
    'Was able to load data without a valid data rate in mms_load_hpca??'
  return, 1
end

function mms_load_hpca_ut::test_load_with_timeclip
  mms_load_hpca, probe=4, datatype='moments', /time_clip, trange=['2017-10-22/06:02', '2017-10-22/06:04']
  assert, spd_data_exists('mms4_hpca_hplus_number_density mms4_hpca_hplus_scalar_temperature mms4_hpca_oplus_ion_bulk_velocity', '2017-10-22/06:02', '2017-10-22/06:04'), $
    'Problem with time clip in mms_load_hpca'
  assert, ~spd_data_exists('mms4_hpca_hplus_number_density mms4_hpca_hplus_scalar_temperature mms4_hpca_oplus_ion_bulk_velocity', '2017-10-22/06:00', '2017-10-22/06:02'), $
    'Problem with time clip in mms_load_hpca'
  assert, ~spd_data_exists('mms4_hpca_hplus_number_density mms4_hpca_hplus_scalar_temperature mms4_hpca_oplus_ion_bulk_velocity', '2017-10-22/06:04', '2017-10-22/06:06'), $
    'Problem with time clip in mms_load_hpca'
  return, 1
end

function mms_load_hpca_ut::test_multiple_datatypes
  mms_load_hpca, trange=['2016-12-15', '2016-12-15/4'], datatype=['ion', 'moments'], probe=1
  assert, spd_data_exists('mms1_hpca_hplus_number_density mms1_hpca_hplus_flux mms1_hpca_oplus_flux', '2016-12-15', '2016-12-15/4'), 'regression with datatypes keyword!!1!one'
  return, 1
end

pro mms_load_hpca_ut::setup
    del_data, '*'
    timespan, '2017-9-22/11:08', 5., /minutes 
end

function mms_load_hpca_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_hpca', 'mms_hpca_calc_anodes', 'mms_hpca_set_metadata', 'mms_hpca_spin_sum']
  self->addTestingRoutine, ['mms_hpca_sum_fov', 'mms_hpca_avg_fov', 'mms_hpca_anodes', 'mms_hpca_energies', 'mms_hpca_elevations'], /is_function
  return, 1
end

pro mms_load_hpca_ut__define
    define = { mms_load_hpca_ut, inherits MGutTestCase }
end