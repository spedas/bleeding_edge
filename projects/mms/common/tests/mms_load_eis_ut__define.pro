;+
;
; Unit tests for mms_load_eis
;
; To run:
;     IDL> mgunit, 'mms_load_eis_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-10-05 12:20:19 -0700 (Fri, 05 Oct 2018) $
; $LastChangedRevision: 25920 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_eis_ut__define.pro $
;-

function mms_load_eis_ut::test_combined_datatypes_pad_suffix
  mms_load_eis, probes=1, datatype=['extof', 'phxtof'], trange=['2015-12-15', '2015-12-16'], suffix='_asuffix'
  mms_eis_pad, probe=1, energy=[30, 800], suffix='_asuffix'
  assert, spd_data_exists('mms1_epd_eis_combined_35-535keV_proton_flux_omni_asuffix_pad mms1_epd_eis_combined_35-535keV_proton_flux_omni_asuffix_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with combined datatypes suffix test'
  return, 1
end

function mms_load_eis_ut::test_combined_datatypes_burst_pad
  mms_load_eis, probes=4, datatype=['extof', 'phxtof'], trange=['2015-12-15', '2015-12-16'], data_rate='brst'
  mms_eis_pad, probe=4, energy=[30, 800], data_rate='brst', datatype=['extof', 'phxtof']
  assert, spd_data_exists('mms4_epd_eis_brst_combined_30-724keV_proton_flux_omni_pad mms4_epd_eis_brst_combined_30-724keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with combined datatypes (burst) PAD'
  return, 1
end

function mms_load_eis_ut::test_combined_datatypes_pad_cps
  mms_load_eis, probes=1, datatype=['extof', 'phxtof'], trange=['2015-12-15', '2015-12-16'], data_units='cps'
  mms_eis_pad, probe=1, energy=[30, 800], data_units='cps'
  ; shouldn't pass because coming PHxTOF and ExTOF data products is only recommended for flux data
  assert, ~spd_data_exists('mms1_epd_eis_combined_proton_cps_omni_pads mms1_epd_eis_combined_30-800keV_proton_cps_omni_pad mms1_epd_eis_combined_30-800keV_proton_cps_omni_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with combined datatypes PAD (cps)'
  return, 1
end

function mms_load_eis_ut::test_combined_datatypes_pad
  mms_load_eis, probes=1, datatype=['extof', 'phxtof'], trange=['2015-12-15', '2015-12-16']
  mms_eis_pad, probe=1, energy=[30, 800]
  assert, spd_data_exists('mms1_epd_eis_combined_proton_flux_omni_pads mms1_epd_eis_combined_35-535keV_proton_flux_omni_pad mms1_epd_eis_combined_35-535keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with combined datatypes PAD'
  return, 1
end

function mms_load_eis_ut::test_multi_probe_pad_suffix
  mms_load_eis, probes=[1, 2, 3, 4], suffix='_thisisasuffix'
  mms_eis_pad, probes=[1, 2, 3, 4], suffix='_thisisasuffix'
  assert, spd_data_exists('mms1-4_epd_eis_extof_proton_flux_omni_thisisasuffix_pads', '2015-12-15', '2015-12-16'), 'Problem with multi-probe PAD test with suffix'
  return, 1
end

function mms_load_eis_ut::test_multi_probe_pad_burst_suffix
  mms_load_eis, probes=[1, 2, 3, 4], suffix='_thisisasuffix', data_rate='brst'
  mms_eis_pad, probes=[1, 2, 3, 4], suffix='_thisisasuffix', data_rate='brst'
  assert, spd_data_exists('mms1-4_epd_eis_brst_extof_proton_flux_omni_thisisasuffix_pads', '2015-12-15', '2015-12-16'), 'Problem with multi-probe PAD test with suffix'
  return, 1
end

function mms_load_eis_ut::test_multi_probe_pad_burst
  mms_load_eis, data_rate='brst', probes=[1, 2, 3, 4]
  mms_eis_pad, data_rate='brst', probes=[1, 2, 3, 4]
  assert, spd_data_exists('mms1-4_epd_eis_brst_extof_proton_flux_omni_pads mms1-4_epd_eis_brst_extof_58-679keV_proton_flux_omni_pad', '2015-12-15', '2015-12-16'), 'Problem with multi-probe EIS PAD with burst data'
  return, 1
end

function mms_load_eis_ut::test_mult_probe_pad_cps
  mms_load_eis, probes=[1, 2, 3, 4], data_units='cps', trange=['2015-12-15', '2015-12-16']
  mms_eis_pad, probes=[1, 2, 3, 4], data_units='cps'
  assert, spd_data_exists('mms1-4_epd_eis_extof_proton_cps_omni_pads', '2015-12-15', '2015-12-16'), 'Problem with multi-probe counts/s test'
  return, 1
end

function mms_load_eis_ut::test_multi_probe_pad
  mms_load_eis, probes=[1, 2, 3, 4]
  mms_eis_pad, probes=[1, 2, 3, 4]
  assert, spd_data_exists('mms1-4_epd_eis_extof_proton_flux_omni_pads mms1-4_epd_eis_extof_74-469keV_proton_flux_omni_pad', '2015-12-15', '2015-12-16'), 'Problem with multi-probe EIS PAD'
  return, 1
end

function mms_load_eis_ut::test_num_smooth_pad
  mms_load_eis, level='l2'
  mms_eis_pad, num_smooth=20.0
  assert, spd_data_exists('mms1_epd_eis_extof_56-535keV_proton_flux_omni_pad mms1_epd_eis_extof_56-535keV_proton_flux_omni_pad_spin mms1_epd_eis_extof_56-535keV_proton_flux_omni_pad_smth', '2015-12-15', '2015-12-16'), 'Problem with creating smoothed PAD (EIS)'
  return, 1
end

function mms_load_eis_ut::test_ang_ang_energychan
  eis_ang_ang, energy_chan=[1, 2]
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni mms1_epd_eis_extof_oxygen_flux_omni', '2015-12-15', '2015-12-16'), 'Problem with EIS angle-angle energy_chan keyword'
  return, 1
end

function mms_load_eis_ut::test_ang_ang_datatype_electron
  eis_ang_ang, datatype='electronenergy', probe=4
  assert, spd_data_exists('mms4_epd_eis_electronenergy_electron_flux_omni', '2015-12-15', '2015-12-16'), 'Problem with EIS angle-angle with datatype electronenergy'
  return, 1
end

function mms_load_eis_ut::test_ang_ang_datatype_phxtof
  eis_ang_ang, datatype='phxtof', probe=3
  assert, spd_data_exists('mms3_epd_eis_phxtof_proton_flux_omni', '2015-12-15', '2015-12-16'), 'Problem with EIS angle-angle datatype PHxTOF'
  return, 1
end

function mms_load_eis_ut::test_ang_ang_data_rate
  eis_ang_ang, data_rate='brst', trange=['2015-10-16/13:00', '2015-10-16/13:10']
  assert, spd_data_exists('mms1_epd_eis_brst_extof_proton_flux_omni', '2015-10-16/13:00', '2015-10-16/13:10'), 'Problem with EIS angle-angle burst mode?'
  return, 1
end

function mms_load_eis_ut::test_ang_ang_data_units
  eis_ang_ang, data_units='cps'
  assert, spd_data_exists('mms1_epd_eis_extof_proton_cps_omni', '2015-12-15', '2015-12-16'), 'Problem with EIS angle-angle data_units keyword'
  return, 1
end

function mms_load_eis_ut::test_ang_ang_extof_helium
  eis_ang_ang, datatype='extof', species='helium'
  assert, spd_data_exists('mms1_epd_eis_extof_alpha_flux_omni', '2015-12-15', '2015-12-16'), 'Problem with EIS angle-angle with ExTOF oxygen'
  return, 1
end

function mms_load_eis_ut::test_ang_ang_extof_oxygen
  eis_ang_ang, datatype='extof', species='oxygen'
  assert, spd_data_exists('mms1_epd_eis_extof_oxygen_flux_omni', '2015-12-15', '2015-12-16'), 'Problem with EIS angle-angle with ExTOF oxygen'
  return, 1
end

function mms_load_eis_ut::test_ang_ang_diffprobe
  eis_ang_ang, probe=3
  assert, spd_data_exists('mms3_epd_eis_extof_proton_flux_omni', '2015-12-15', '2015-12-16'), 'Problem with EIS angle-angle when probe is set'
  return, 1
end

function mms_load_eis_ut::test_angle_angle_load_simple
  eis_ang_ang, trange=['2015-12-15', '2015-12-16']
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni mms1_epd_eis_extof_alpha_flux_omni mms1_epd_eis_extof_oxygen_flux_omni', '2015-12-15', '2015-12-16'), 'Problem with EIS angle-angle?'
  return, 1
end

function mms_load_eis_ut::test_yrange_of_spectra
  mms_load_eis, datatype='phxtof', level='l2', probe=1
  get_data, 'mms1_epd_eis_phxtof_proton_flux_omni_spin', limits=l
  assert, array_equal(l.yrange, [14, 45]), 'Problem with yrange of L2 PHxTOF proton variable'
  
  mms_load_eis, datatype='extof', level='l2', probe=1
  get_data, 'mms1_epd_eis_extof_proton_flux_omni_spin', limits=proton_l
  get_data, 'mms1_epd_eis_extof_alpha_flux_omni_spin', limits=alpha_l
  get_data, 'mms1_epd_eis_extof_oxygen_flux_omni_spin', limits=oxygen_l
  assert, array_equal(proton_l.yrange, [55, 1000]), 'Problem with yrange of L2 ExTOF proton variable'
  assert, array_equal(alpha_l.yrange, [80, 650]), 'Problem with yrange of L2 ExTOF alpha variable'
  assert, array_equal(oxygen_l.yrange, [145, 950]), 'Problem with yrange of L2 ExTOF oxygen variable'
  
  mms_load_eis, datatype='electronenergy', level='l2', probe=1
  get_data, 'mms1_epd_eis_electronenergy_electron_flux_omni_spin', limits=electrons_l
  assert, array_equal(electrons_l.yrange, [40, 660]), 'Problem with yrange of L2 electronenergy variable'
  
  del_data, '*'
  
  ; the following will break when the L1b files are updated to v3
  mms_load_eis, datatype='phxtof', level='l1b', probe=1
  get_data, 'mms1_epd_eis_phxtof_proton_flux_omni_spin', limits=l1b_l
  assert, array_equal(l1b_l.yrange, [10, 28]), 'Problem with yrange of L1b PHxTOF proton variable'
  
  return, 1
end

function mms_load_eis_ut::test_yrange_of_spectra_brst
  mms_load_eis, datatype='phxtof', level='l2', probe=1, data_rate='brst'
  get_data, 'mms1_epd_eis_brst_phxtof_proton_flux_omni_spin', limits=l
  assert, array_equal(l.yrange, [14, 45]), 'Problem with yrange of L2 PHxTOF proton variable (brst)'

  mms_load_eis, datatype='extof', level='l2', probe=1, data_rate='brst'
  get_data, 'mms1_epd_eis_brst_extof_proton_flux_omni_spin', limits=proton_l
  get_data, 'mms1_epd_eis_brst_extof_alpha_flux_omni_spin', limits=alpha_l
  get_data, 'mms1_epd_eis_brst_extof_oxygen_flux_omni_spin', limits=oxygen_l
  assert, array_equal(proton_l.yrange, [55, 1000]), 'Problem with yrange of L2 ExTOF proton variable (brst)'
  assert, array_equal(alpha_l.yrange, [80, 650]), 'Problem with yrange of L2 ExTOF alpha variable (brst)'
  assert, array_equal(oxygen_l.yrange, [145, 950]), 'Problem with yrange of L2 ExTOF oxygen variable (brst)'

  del_data, '*'

  ; the following will break when the L1b files are updated to v3
  mms_load_eis, datatype='phxtof', level='l1b', probe=1, data_rate='brst'
  get_data, 'mms1_epd_eis_brst_phxtof_proton_flux_omni_spin', limits=l1b_l
  assert, array_equal(l1b_l.yrange, [10, 28]), 'Problem with yrange of L1b PHxTOF proton variable (brst)'

  return, 1
end
function mms_load_eis_ut::test_load_pad_suffix
  mms_load_eis, datatype='phxtof', level='l2', probe=3, suffix='_p'
  mms_eis_pad, datatype='phxtof', suffix='_p', probe=3
  assert, spd_data_exists('mms3_epd_eis_phxtof_58-58keV_proton_flux_omni_p_pad_spin mms3_epd_eis_phxtof_58-58keV_proton_flux_omni_p_pad', '2015-12-15', '2015-12-16'), $
    'Problem loading EIS PAD with suffix keyword'
  return, 1
end

function mms_load_eis_ut::test_load_with_suffix
  mms_load_eis, datatype='phxtof', level='l2', probe=4, suffix='_s'
  assert, spd_data_exists('mms4_epd_eis_phxtof_proton_flux_omni_s_spin mms4_epd_eis_phxtof_oxygen_flux_omni_s_spin mms4_epd_eis_phxtof_proton_flux_omni_s mms4_epd_eis_phxtof_oxygen_flux_omni_s mms4_epd_eis_phxtof_proton_P3_flux_t5_s_spin mms4_epd_eis_phxtof_pitch_angle_t0_s', '2015-12-15', '2015-12-16'), $
    'Problem loading EIS PHxTOF data with a suffix'
  return, 1
end

function mms_load_eis_ut::test_phxtof_omni_spec_load
  mms_load_eis, datatype='phxtof', level='l2', probe=1
  assert, spd_data_exists('mms1_epd_eis_phxtof_proton_flux_omni mms1_epd_eis_phxtof_oxygen_flux_omni', '2015-12-15', '2015-12-16'), $
    'Problem loading non-spin averaged omni-directional spectra (phxtof)'
  return, 1
end

function mms_load_eis_ut::test_electron_omni_spec_load
  mms_load_eis, datatype='electronenergy', level='l2', probe=1
  assert, spd_data_exists('mms1_epd_eis_electronenergy_electron_flux_omni', '2015-12-15', '2015-12-16'), $
    'Problem loading non-spin averaged omni-directional spectra (electronenergy)'
  return, 1
end

function mms_load_eis_ut::test_extof_omni_spec_load
  mms_load_eis, datatype='extof', level='l2', probe=1
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni mms1_epd_eis_extof_alpha_flux_omni mms1_epd_eis_extof_oxygen_flux_omni', '2015-12-15', '2015-12-16'), $
    'Problem loading non-spin averaged omni-directional spectra (extof)'
  return, 1
end

function mms_load_eis_ut::test_load_wrong_en
  mms_load_eis, datatype='phxtof', level='l2'
  mms_eis_pad, energy=[200, 300], datatype='phxtof'
  assert, ~spd_data_exists('mms1_epd_eis_phxtof_200-300keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS bad energy range test (PAD)'
  return, 1
end

function mms_load_eis_ut::test_load_phxtof_baden
  mms_load_eis, datatype='phxtof', level='l2'
  mms_eis_pad, energy=[50, 40]
  assert, ~spd_data_exists('mms1_epd_eis_phxtof_50-40keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS bad energy range test (PAD)'
  return, 1
end

function mms_load_eis_ut::test_load_phxtof
  mms_load_eis, datatype='phxtof', level='l2'
  assert, spd_data_exists('mms1_epd_eis_phxtof_proton_flux_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 EIS PHxTOF data'
  return, 1
end

function mms_load_eis_ut::test_load_electron_pad
  del_data, '*'
  mms_load_eis, datatype='electronenergy', level='l2'
  mms_eis_pad, datatype='electronenergy'
  assert, spd_data_exists('mms1_epd_eis_electronenergy_69-661keV_electron_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading EIS electron PAD'
  return, 1
end

function mms_load_eis_ut::test_load_electron
  del_data, '*'
  mms_load_eis, datatype='electronenergy', level='l2'
  assert, spd_data_exists('mms1_epd_eis_electronenergy_electron_flux_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading EIS electron data'
  return, 1
end

function mms_load_eis_ut::test_pad_limited_en
  mms_eis_pad, energy=[300, 400]
  assert, spd_data_exists('mms1_epd_eis_extof_318-318keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS PAD (limited energy range)'
  return, 1
end

function mms_load_eis_ut::test_brst_caps_pad
  del_data, '*'
  mms_load_eis, data_rate='BRST', level='l2'
  mms_eis_pad, data_rate='BRST'
  assert, spd_data_exists('mms1_epd_eis_brst_extof_56-740keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS burst mode PAD (caps)'
  return, 1
end

function mms_load_eis_ut::test_brst_pad
  del_data, '*'
  mms_load_eis, data_rate='brst', level='l2'
  mms_eis_pad, data_rate='brst'
  assert, spd_data_exists('mms1_epd_eis_brst_extof_56-740keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS burst mode PAD'
  return, 1
end

function mms_load_eis_ut::test_pad
  mms_eis_pad
  assert, spd_data_exists('mms1_epd_eis_extof_56-535keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS PAD'
  return, 1
end

function mms_load_eis_ut::test_load_l2_spdf
  del_data, '*'
  mms_load_eis, probe=1, level='L2', /spdf
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 EIS data (SPDF)'
  return, 1
end

function mms_load_eis_ut::test_load_l2
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 EIS data'
  return, 1
end

function mms_load_eis_ut::test_load_timeclip
  del_data, '*'
  mms_load_eis, trange=['2015-12-15/11:00', '2015-12-15/12:00'], /time_clip
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15/11:00', '2015-12-15/12:00'), $
    'Problem loading L2 EIS data with time clipping'
  assert, ~spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15/10:00', '2015-12-15/11:00'), $
    'Problem loading L2 EIS data with time clipping'
  assert, ~spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15/12:00', '2015-12-15/13:00'), $
    'Problem loading L2 EIS data with time clipping'
  return, 1
end

function mms_load_eis_ut::test_pad_binsize
  mms_eis_pad, size_pabin=3
  get_data, 'mms1_epd_eis_extof_56-535keV_proton_flux_omni_pad_spin', data=d
  assert, n_elements(d.V) eq 60, 'Problem with bin_size keyword in mms_eis_pad'
  return, 1
end

pro mms_load_eis_ut::setup
  del_data, '*'
  timespan, '2015-12-15/00:00', 1, /day
  mms_load_eis, probe=1, level='L2'
end

function mms_load_eis_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_eis', 'mms_eis_omni', $
    'mms_eis_pad_spinavg', 'mms_eis_pad', 'mms_eis_set_metadata', $
    'mms_eis_spin_avg', 'eis_ang_ang']
  return, 1
end

pro mms_load_eis_ut__define

  define = { mms_load_eis_ut, inherits MGutTestCase }
end