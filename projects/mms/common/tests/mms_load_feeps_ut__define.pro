;+
;
; Unit tests for mms_load_feeps
;
; To run:
;     IDL> mgunit, 'mms_load_feeps_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-04-02 17:54:46 -0700 (Tue, 02 Apr 2019) $
; $LastChangedRevision: 26936 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_feeps_ut__define.pro $
;-

function mms_load_feeps_ut::test_tt2000
  del_data, '*'
  mms_load_feeps, trange=['2015-12-15', '2015-12-16'], /tt2000
  get_data, 'mms1_epd_feeps_srvy_l2_electron_intensity_omni', data=d
  assert, array_equal(d.X[0:10], [503409669135695872, 503409671556367872, 503409673977072128, 503409676397760000, 503409678818464000, 503409681239136000, 503409683659840000, 503409686080544000, 503409688501216000, 503409690921920000, 503409693342592000]), 'Problem with FEEPS TT2000 test'
  return, 1
end

function mms_load_feeps_ut::test_active_eyes_sitl_before_updates
  eye_table_e = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 1, 'srvy', 'electron', 'sitl')
  assert, array_equal(eye_table_e['top'], [5, 11, 12]), 'Problem with active eyes (SITL) test'
  assert, eye_table_e['bottom'] eq !NULL, 'Problem with active eyes (SITL) test'
  eye_table_e = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 2, 'srvy', 'electron', 'sitl')
  assert, array_equal(eye_table_e['top'], [5, 11, 12]), 'Problem with active eyes (SITL) test'
  assert, eye_table_e['bottom'] eq !NULL, 'Problem with active eyes (SITL) test'
  eye_table_e = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 3, 'srvy', 'electron', 'sitl')
  assert, array_equal(eye_table_e['top'], [5, 11, 12]), 'Problem with active eyes (SITL) test'
  assert, eye_table_e['bottom'] eq !NULL, 'Problem with active eyes (SITL) test'
  eye_table_e = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 4, 'srvy', 'electron', 'sitl')
  assert, array_equal(eye_table_e['top'], [5, 11, 12]), 'Problem with active eyes (SITL) test'
  assert, eye_table_e['bottom'] eq !NULL, 'Problem with active eyes (SITL) test'
  return, 1
end

function mms_load_feeps_ut::test_active_eyes_sitl_after_updates
  eye_table_e = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 1, 'srvy', 'electron', 'sitl')
  assert, array_equal(eye_table_e['top'], [5, 12]), 'Problem with active eyes (SITL) test'
  assert, eye_table_e['bottom'] eq !NULL, 'Problem with active eyes (SITL) test'
  eye_table_e = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 2, 'srvy', 'electron', 'sitl')
  assert, array_equal(eye_table_e['top'], [5, 11]), 'Problem with active eyes (SITL) test'
  assert, eye_table_e['bottom'] eq !NULL, 'Problem with active eyes (SITL) test'
  eye_table_e = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 3, 'srvy', 'electron', 'sitl')
  assert, array_equal(eye_table_e['top'], [5, 12]), 'Problem with active eyes (SITL) test'
  assert, eye_table_e['bottom'] eq !NULL, 'Problem with active eyes (SITL) test'
  eye_table_e = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 4, 'srvy', 'electron', 'sitl')
  assert, array_equal(eye_table_e['top'], [5, 11]), 'Problem with active eyes (SITL) test'
  assert, eye_table_e['bottom'] eq !NULL, 'Problem with active eyes (SITL) test'
  return, 1
end

function mms_load_feeps_ut::test_active_eyes_brst
  eye_table_e = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 1, 'brst', 'electron', 'l2')
  eye_table_i = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 1, 'brst', 'ion', 'l2')
  assert, array_equal(eye_table_e['bottom'], [1, 2, 3, 4, 5, 9, 10, 11, 12]), 'Problem with active eyes function (brst)
  assert, array_equal(eye_table_e['top'], [1, 2, 3, 4, 5, 9, 10, 11, 12]), 'Problem with active eyes function (brst)
  assert, array_equal(eye_table_i['bottom'], [6, 7, 8]), 'Problem with active eyes function (brst)
  assert, array_equal(eye_table_i['top'], [6, 7, 8]), 'Problem with active eyes function (brst)
  return, 1
end

function mms_load_feeps_ut::test_active_eyes_after_update
  eye_table = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 1, 'srvy', 'electron', 'l2')
  assert, array_equal(eye_table['bottom'], [2, 4, 5, 9, 10]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [3, 5, 9, 10, 12]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2017-08-20', '2017-08-21'], 2, 'srvy', 'ion', 'l2')
  assert, array_equal(eye_table['bottom'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [6, 8]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 2, 'srvy', 'electron', 'l2')
  assert, array_equal(eye_table['bottom'], [1, 4, 5, 9, 11]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [1, 2, 3, 5, 10, 11]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 2, 'srvy', 'ion', 'l2')
  assert, array_equal(eye_table['bottom'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [6, 8]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 3, 'srvy', 'electron', 'l2')
  assert, array_equal(eye_table['bottom'], [1, 2, 3, 9, 10]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [3, 5, 9, 10, 12]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 3, 'srvy', 'ion', 'l2')
  assert, array_equal(eye_table['bottom'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 4, 'srvy', 'electron', 'l2')
  assert, array_equal(eye_table['bottom'], [3, 5, 9, 10, 12]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [3, 4, 5, 9, 10, 11]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2017-12-15', '2017-12-16'], 4, 'srvy', 'ion', 'l2')
  assert, array_equal(eye_table['bottom'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [6, 8]), 'Problem with FEEPS active eyes function'
  return, 1
end

function mms_load_feeps_ut::test_active_eyes_before_update
  eye_table = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 1, 'srvy', 'electron', 'l2')
  assert, array_equal(eye_table['bottom'], [3, 4, 5, 11, 12]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [3, 4, 5, 11, 12]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 1, 'srvy', 'ion', 'l2')
  assert, array_equal(eye_table['bottom'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 2, 'srvy', 'electron', 'l2')
  assert, array_equal(eye_table['bottom'], [3, 4, 5, 11, 12]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [3, 4, 5, 11, 12]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 2, 'srvy', 'ion', 'l2')
  assert, array_equal(eye_table['bottom'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 3, 'srvy', 'electron', 'l2')
  assert, array_equal(eye_table['bottom'], [3, 4, 5, 11, 12]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [3, 4, 5, 11, 12]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 3, 'srvy', 'ion', 'l2')
  assert, array_equal(eye_table['bottom'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 4, 'srvy', 'electron', 'l2')
  assert, array_equal(eye_table['bottom'], [3, 4, 5, 11, 12]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [3, 4, 5, 11, 12]), 'Problem with FEEPS active eyes function'
  eye_table = mms_feeps_active_eyes(['2015-12-15', '2015-12-16'], 4, 'srvy', 'ion', 'l2')
  assert, array_equal(eye_table['bottom'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  assert, array_equal(eye_table['top'], [6, 7, 8]), 'Problem with FEEPS active eyes function'
  return, 1
end

function mms_load_feeps_ut::test_time_dependent_sun_masks
  mask_sectors = mms_read_feeps_sector_masks_csv(trange=['2015-12-15', '2015-12-16'])
  assert, array_equal(mask_sectors['mms2imaskt1'], [32, 33, 34]), 'Problem with sun masks'
  mask_sectors = mms_read_feeps_sector_masks_csv(trange=['2016-12-15', '2016-12-16'])
  assert, array_equal(mask_sectors['mms1imaskt1'], [2, 3, 4, 5, 6]), 'Problem with sun masks'
  mask_sectors = mms_read_feeps_sector_masks_csv(trange=['2017-5-15', '2017-5-16'])
  assert, array_equal(mask_sectors['mms2imaskt1'], [32, 33]), 'Problem with sun masks'
  mask_sectors = mms_read_feeps_sector_masks_csv(trange=['2016-4-15', '2016-3-16'])
  assert, array_equal(mask_sectors['mms2imaskt1'], [32, 33, 34]), 'Problem with sun masks'
  return, 1
end

function mms_load_feeps_ut::test_omni_not_replacing_0s_with_nans
  mms_load_feeps, probe=1
  get_data, 'mms1_epd_feeps_srvy_l2_electron_intensity_omni', data=d
  ; bug was replacing 0s with NaNs; the first time here should have 1 zero, no NaNs
  assert, ~array_contains(d.Y[0, *], !values.d_nan), 'Regression in mms_feeps_omni??' 
  assert, array_contains(d.Y[0, *], 0d), 'Regression in mms_feeps_omni??'
  return, 1
end

; the following is a regression test for a bug in the FEEPS
; omni-directional code that was fixed 3/29/17
function mms_load_feeps_ut::test_omni_offbyone_err
  mms_load_feeps, probe=1
  get_data, 'mms1_epd_feeps_srvy_l2_electron_intensity_omni', data=d
  assert, total(d.Y[0, *], /nan) lt 100., 'Regression in mms_feeps_omni??' ; bug was causing this to be a large #, > 3k
  return, 1
end

; the following is a regression test for the FEEPS PAD bug
; where the last bin was always left off due to a -1 error
function mms_load_feeps_ut::test_last_pad_bin
  mms_load_feeps, probe=2
  mms_feeps_pad, probe=2
  get_data, 'mms2_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad', data=d
  assert, total(d.Y[*, 10], /nan) ne 0, 'Problem with last bin in FEEPS PAD'
  return, 1
end

function mms_load_feeps_ut::test_varformat_brst_count_rate
  mms_load_feeps, data_rate='brst', probe=4, varformat='*count_rate*'
  assert, spd_data_exists('mms4_epd_feeps_brst_l2_electron_count_rate_omni mms4_epd_feeps_brst_l2_electron_count_rate_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem with varformat keyword in mms_load_feeps'
  assert, ~spd_data_exists('mms4_epd_feeps_brst_l2_electron_intensity_omni mms4_epd_feeps_brst_l2_electron_intensity_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem with varformat keyword in mms_load_feeps'
  return, 1
end

function mms_load_feeps_ut::test_varformat_brst_intensity
  mms_load_feeps, data_rate='brst', probe=4, varformat='*intensity*'
  assert, spd_data_exists('mms4_epd_feeps_brst_l2_electron_intensity_omni mms4_epd_feeps_brst_l2_electron_intensity_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem with varformat keyword in mms_load_feeps'
  assert, ~spd_data_exists('mms4_epd_feeps_brst_l2_electron_count_rate_omni mms4_epd_feeps_brst_l2_electron_count_rate_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem with varformat keyword in mms_load_feeps'
  return, 1
end

function mms_load_feeps_ut::test_ion_bad_eyes_brst
  mms_load_feeps, data_rate='brst', probe=2, datatype='ion', level='l2'
  get_data, 'mms2_epd_feeps_brst_l2_ion_top_intensity_sensorid_7_clean_sun_removed', data=top
  get_data, 'mms2_epd_feeps_brst_l2_ion_bottom_intensity_sensorid_7_clean_sun_removed', data=bottom
  wheretop = where(finite(top.Y) eq 1, topcount)
  wherebot = where(finite(bottom.Y) eq 1, botcount)
  assert, topcount eq 0 and botcount eq 0, 'Problem removing bad eyes for L2 ions (brst)'
  return, 1
end

function mms_load_feeps_ut::test_ion_bad_eyes_srvy
  mms_load_feeps, probe=4, data_rate='srvy', datatype='ion'
  get_data, 'mms4_epd_feeps_srvy_l2_ion_top_intensity_sensorid_7_clean_sun_removed', data=top
  wheretop = where(finite(top.Y) eq 1, topcount)
  assert, topcount eq 0, 'Problem removing bad eyes for L2 ions (srvy)'
  return, 1
end

function mms_load_feeps_ut::test_flatfield_corrections_l1b
  mms_load_feeps, data_rate='brst', probe=4, suffix='_with_flatfield_correction', datatype='ion', level='l1b'
  mms_load_feeps, data_rate='brst', probe=4, datatype='ion', /no_flatfield_corrections, level='l1b'
  get_data, 'mms4_epd_feeps_brst_l1b_ion_top_intensity_sensorid_6_clean_sun_removed_with_flatfield_correction', data=corr
  get_data, 'mms4_epd_feeps_brst_l1b_ion_top_intensity_sensorid_6_clean_sun_removed', data=d
  factor = corr.Y[2000, 1]/d.Y[2000, 1]
  assert, factor eq 0.8, 'Problem applying flat field corrections to ions (L1b)'
  return, 1
end

function mms_load_feeps_ut::test_flatfield_corrections_l2
  mms_load_feeps, data_rate='brst', probe=4, suffix='_with_flatfield_correction', datatype='ion'
  mms_load_feeps, data_rate='brst', probe=4, datatype='ion', /no_flatfield_corrections
  get_data, 'mms4_epd_feeps_brst_l2_ion_top_intensity_sensorid_6_clean_sun_removed_with_flatfield_correction', data=corr
  get_data, 'mms4_epd_feeps_brst_l2_ion_top_intensity_sensorid_6_clean_sun_removed', data=d
  factor = corr.Y[2000, 1]/d.Y[2000, 1]
  assert, factor eq 0.8, 'Problem applying flat field corrections to ions (L2)'
  return, 1
end

; regression test, previously failed due to incorrect sensor head type in mms_feeps_flat_field_corrections
function mms_load_feeps_ut::test_flatfield_corrections_l2_bottom
  mms_load_feeps, data_rate='brst', probe=4, suffix='_with_flatfield_correction', datatype='ion'
  mms_load_feeps, data_rate='brst', probe=4, datatype='ion', /no_flatfield_corrections
  get_data, 'mms4_epd_feeps_brst_l2_ion_bottom_intensity_sensorid_7_clean_sun_removed_with_flatfield_correction', data=corr
  get_data, 'mms4_epd_feeps_brst_l2_ion_bottom_intensity_sensorid_7_clean_sun_removed', data=d
  factor = corr.Y[6305, 2]/d.Y[6305, 2]
  assert, factor eq 0.6, 'Problem applying flat field corrections to ions (L2) - bottom sensor head'
  return, 1
end

function mms_load_feeps_ut::test_bad_lower_channels_brst_l1b
  mms_load_feeps, data_rate='brst', probes=[1, 2, 3, 4], level='l1b'
  ; MMS1: Bottom Eyes: 2, 3, 4, 5, 9, 11, 12
  get_data, 'mms1_epd_feeps_brst_l1b_electron_bottom_intensity_sensorid_2_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (L1b)'

  ; MMS2: Bottom Eyes: 1, 2, 3, 4, 5, 9, 10, 11, 12
  get_data, 'mms2_epd_feeps_brst_l1b_electron_bottom_intensity_sensorid_4_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (L1b)'

  ; MMS3: Bottom Eyes: 1, 9, 10, 11
  get_data, 'mms3_epd_feeps_brst_l1b_electron_bottom_intensity_sensorid_9_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (L1b)'

  ; MMS4: Bottom Eyes: 1, 3, 9, 12
  get_data, 'mms4_epd_feeps_brst_l1b_electron_bottom_intensity_sensorid_3_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (L1b)'

  return, 1
end

function mms_load_feeps_ut::test_bad_lower_channels_srvy_sitl
  mms_load_feeps, probes=[1, 2, 3, 4], level='sitl', trange=['2016-11-01', '2016-11-02']

  get_data, 'mms2_epd_feeps_srvy_sitl_electron_top_intensity_sensorid_12_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (sitl)'

  get_data, 'mms3_epd_feeps_srvy_sitl_electron_top_intensity_sensorid_12_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (sitl)'

  return, 1
end

function mms_load_feeps_ut::test_bad_lower_channels_brst_suffix
  mms_load_feeps, data_rate='brst', probes=[1, 2, 3, 4], suffix='_suffixtest'
  ; MMS1: Bottom Eyes: 2, 3, 4, 5, 9, 11, 12
  get_data, 'mms1_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_2_clean_sun_removed_suffixtest', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (with suffix)'

  ; MMS2: Bottom Eyes: 1, 2, 3, 4, 5, 9, 10, 11, 12
  get_data, 'mms2_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_4_clean_sun_removed_suffixtest', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (with suffix)'

  ; MMS3: Bottom Eyes: 1, 9, 10, 11
  get_data, 'mms3_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_9_clean_sun_removed_suffixtest', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (with suffix)'

  ; MMS4: Bottom Eyes: 1, 3, 9, 12
  get_data, 'mms4_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_3_clean_sun_removed_suffixtest', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels! (with suffix)'

  return, 1
end

function mms_load_feeps_ut::test_bad_lower_channels_brst
  mms_load_feeps, data_rate='brst', probes=[1, 2, 3, 4]
  ; MMS1: Bottom Eyes: 2, 3, 4, 5, 9, 11, 12
  get_data, 'mms1_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_2_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels!'
  
  ; MMS2: Bottom Eyes: 1, 2, 3, 4, 5, 9, 10, 11, 12
  get_data, 'mms2_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_4_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels!'
  
  ; MMS3: Bottom Eyes: 1, 9, 10, 11
  get_data, 'mms3_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_9_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels!'

  ; MMS4: Bottom Eyes: 1, 3, 9, 12
  get_data, 'mms4_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_3_clean_sun_removed', data=d
  assert, ~finite(d.Y[101, 0]), 'Problem removing bad lower energy channels!'

  return, 1
end

function mms_load_feeps_ut::test_bad_eyes_brst_probe1
  mms_load_feeps, data_rate='brst', probe=1
  ; the following should be NaNs; bottom sensor 1 is bad for MMS1
  get_data, 'mms1_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_1_clean_sun_removed', data=d
  w = where(finite(d.Y) ne 0, wherecount)
  assert, wherecount eq 0, 'Problem removing bad bottom sensor data for probe 1'
  return, 1
end

function mms_load_feeps_ut::test_bad_eyes_brst_probe2
  mms_load_feeps, data_rate='brst', probe=2
  ; the following should be NaNs; top sensor 5 is bad for MMS2
  get_data, 'mms2_epd_feeps_brst_l2_electron_top_intensity_sensorid_5_clean_sun_removed', data=d
  w = where(finite(d.Y) ne 0, wherecount)
  assert, wherecount eq 0, 'Problem removing bad top sensor data for probe 2'
  return, 1
end

function mms_load_feeps_ut::test_bad_eyes_brst_probe3
  mms_load_feeps, data_rate='brst', probe=3
  ; the following should be NaNs; top sensor 12 is bad for MMS3
  get_data, 'mms3_epd_feeps_brst_l2_electron_top_intensity_sensorid_12_clean_sun_removed', data=d
  w = where(finite(d.Y) ne 0, wherecount)
  assert, wherecount eq 0, 'Problem removing bad top sensor data for probe 3'
  return, 1
end

function mms_load_feeps_ut::test_bad_eyes_brst_probe4
  mms_load_feeps, data_rate='brst', probe=4
  ; the following should be NaNs; top sensor 10 is bad for MMS4
  get_data, 'mms4_epd_feeps_brst_l2_electron_bottom_intensity_sensorid_10_clean_sun_removed', data=d
  w = where(finite(d.Y) ne 0, wherecount)
  assert, wherecount eq 0, 'Problem removing bad bottom sensor data for probe 4'
  return, 1
end

function mms_load_feeps_ut::test_bad_eyes_srvy_probe2
  mms_load_feeps, data_rate='srvy', probe=2
  ; the following should be NaNs; top sensor 5 is bad for MMS2
  get_data, 'mms2_epd_feeps_srvy_l2_electron_top_intensity_sensorid_5_clean_sun_removed', data=d
  w = where(finite(d.Y) ne 0, wherecount)
  assert, wherecount eq 0, 'Problem removing bad top sensor data for probe 2'
  return, 1
end

function mms_load_feeps_ut::test_bad_eyes_srvy_probe3
  mms_load_feeps, data_rate='srvy', probe=3
  ; the following should be NaNs; top sensor 12 is bad for MMS3
  get_data, 'mms3_epd_feeps_srvy_l2_electron_top_intensity_sensorid_12_clean_sun_removed', data=d
  w = where(finite(d.Y) ne 0, wherecount)
  assert, wherecount eq 0, 'Problem removing bad top sensor data for probe 3'
  return, 1
end

function mms_load_feeps_ut::test_bad_eyes_srvy_probe4
  mms_load_feeps, data_rate='srvy', probe=4
  ; the following should be NaNs; bottom sensor 4 is bad for MMS4
  get_data, 'mms4_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_4_clean_sun_removed', data=d
  w = where(finite(d.Y) ne 0, wherecount)
  assert, wherecount eq 0, 'Problem removing bad bottom sensor data for probe 4'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_brst_probe1_suffix
  mms_load_feeps, data_rate='brst', probe=1, suffix='_shouldworkwithsuffix'
  get_data, 'mms1_epd_feeps_brst_l2_electron_top_intensity_sensorid_1_clean_sun_removed_shouldworkwithsuffix', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]+14d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (brst, MMS1, with suffix)'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_brst_probe1
  mms_load_feeps, data_rate='brst', probe=1
  get_data, 'mms1_epd_feeps_brst_l2_electron_top_intensity_sensorid_1_clean_sun_removed', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]+14d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (brst, MMS1)'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_brst_probe2
  mms_load_feeps, data_rate='brst', probe=2
  get_data, 'mms2_epd_feeps_brst_l2_electron_top_intensity_sensorid_1_clean_sun_removed', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]-1d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (brst, MMS2)'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_brst_probe3
  mms_load_feeps, data_rate='brst', probe=3
  get_data, 'mms3_epd_feeps_brst_l2_electron_top_intensity_sensorid_5_clean_sun_removed', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]-5d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (brst, MMS3)'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_brst_probe4
  mms_load_feeps, data_rate='brst', probe=4
  get_data, 'mms4_epd_feeps_brst_l2_electron_top_intensity_sensorid_11_clean_sun_removed', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]-6d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (brst, MMS4)'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_srvy_probe1
  mms_load_feeps, data_rate='srvy', probe=1
  get_data, 'mms1_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_4_clean_sun_removed', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]+13d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (srvy, MMS1)'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_srvy_probe2
  mms_load_feeps, data_rate='srvy', probe=2
  get_data, 'mms2_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_5_clean_sun_removed', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]-2d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (srvy, MMS2)'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_srvy_probe3
  mms_load_feeps, data_rate='srvy', probe=3
  get_data, 'mms3_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_12_clean_sun_removed', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]-3d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (srvy, MMS3)'
  return, 1
end

function mms_load_feeps_ut::test_energy_channel_srvy_probe4
  mms_load_feeps, data_rate='srvy', probe=4
  get_data, 'mms4_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_12_clean_sun_removed', data=d
  mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
    200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]-4d
  assert, array_equal(d.V, mms_energies), 'Problem with energy table in omni-directional intensity variable (srvy, MMS4)'
  return, 1
end

function mms_load_feeps_ut::test_pad_low_en
  mms_load_feeps
  mms_feeps_pad, energy=[30, 50]
  ; the previous call shouldn't have created a PAD variable
  assert, ~spd_data_exists('*keV_pad', '2015-12-15', '2015-12-16'), 'FEEPS PAD code is allowing energies less than 70 keV!'
  return, 1
end

function mms_load_feeps_ut::test_load_sitl_omni
  mms_load_feeps, probe=[2, 4], level='sitl', trange=['2016-09-15', '2016-09-16']
  assert, spd_data_exists('mms4_epd_feeps_srvy_sitl_electron_count_rate_omni mms4_epd_feeps_srvy_sitl_electron_count_rate_omni_spin mms4_epd_feeps_srvy_sitl_electron_intensity_omni mms4_epd_feeps_srvy_sitl_electron_intensity_omni_spin', '2016-09-15', '2016-09-16'), $
    'Problem loading omni-directional FEEPS spectra using SITL files'
  return, 1
end

function mms_load_feeps_ut::test_load_l1a_multi_datatypes
  mms_load_feeps, probes=4, level='l1a', datatype=['ion-top', 'electron-top']
  assert, spd_data_exists('mms4_epd_feeps_srvy_l1a_ion_top_sensor_counts_sensorid_6 mms4_epd_feeps_srvy_l1a_ion_top_sensor_counts_sensorid_7 mms4_epd_feeps_srvy_l1a_electron_top_sensor_counts_sensorid_3 mms4_epd_feeps_srvy_l1a_electron_top_sensor_counts_sensorid_4', '2015-12-15', '2015-12-16'), $
    'Problem loading FEEPS L1a data with multiple datatypes specified'
  return, 1
end

function mms_load_feeps_ut::test_load_l2_multi_datatypes
  mms_load_feeps, probe=2, level='l2', datatype=['ion', 'electron']
  assert, spd_data_exists('mms2_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_3_clean_sun_removed mms2_epd_feeps_srvy_l2_electron_top_count_rate_sensorid_11_clean_sun_removed mms2_epd_feeps_srvy_l2_electron_bottom_count_rate_sensorid_3_clean_sun_removed mms2_epd_feeps_srvy_l2_electron_bottom_intensity_sensorid_3_clean_sun_removed', '2015-12-15', '2015-12-16'), $
    'Problem with loading L2 FEEPS data with multiple datatypes'
  return, 1
end

function mms_load_feeps_ut::test_load_l1a_set_good_datatype
  mms_load_feeps, probes=3, level='l1a', datatype='ion-top'
  assert, spd_data_exists('mms3_epd_feeps_srvy_l1a_ion_top_sensor_counts_sensorid_6 mms3_epd_feeps_srvy_l1a_ion_top_sensor_counts_sensorid_7 mms3_epd_feeps_srvy_l1a_ion_top_sensor_counts_sensorid_8', '2015-12-15', '2015-12-16'), $
    'Problem loading FEEPS L1a data with valid datatype'
  assert, ~spd_data_exists('mms3_epd_feeps_srvy_l1a_ion_bottom_sensor_counts_sensorid_6 mms3_epd_feeps_srvy_l1a_ion_bottom_sensor_counts_sensorid_7 mms3_epd_feeps_srvy_l1a_ion_bottom_sensor_counts_sensorid_8', '2015-12-15', '2015-12-16'), $
    'Problem loading FEEPS L1a data with valid datatype'
  return, 1
end

function mms_load_feeps_ut::test_load_l1a_set_bad_datatype
  mms_load_feeps, probes=3, level='l1a', datatype='ion' ; ion isn't valid for L1a data, should load all
  assert, spd_data_exists('mms3_epd_feeps_srvy_l1a_electron_bottom_sensor_counts_sensorid_3 mms3_epd_feeps_srvy_l1a_electron_top_sensor_counts_sensorid_3 mms3_epd_feeps_srvy_l1a_ion_top_sensor_counts_sensorid_6 mms3_epd_feeps_srvy_l1a_ion_bottom_sensor_counts_sensorid_8', '2015-12-15', '2015-12-16'), $
    'Problem loading FEEPS L1a data with invalid datatype'
  return, 1
end

function mms_load_feeps_ut::test_load_l1a_data
  mms_load_feeps, probes=3, level='l1a'
  assert, spd_data_exists('mms3_epd_feeps_srvy_l1a_electron_bottom_sensor_counts_sensorid_3 mms3_epd_feeps_srvy_l1a_electron_bottom_sensor_counts_sensorid_12 mms3_epd_feeps_srvy_l1a_ion_top_sensor_counts_sensorid_7 mms3_epd_feeps_srvy_l1a_ion_bottom_sensor_counts_sensorid_7', '2015-12-15', '2015-12-16'), $
    'Problem loading FEEPS L1a data'
  return, 1
end

function mms_load_feeps_ut::test_load_multi_probe
  mms_load_feeps, probes=[1, 2, '3', 4], level='l2'
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_omni mms2_epd_feeps_srvy_l2_electron_intensity_omni mms3_epd_feeps_srvy_l2_electron_intensity_omni mms4_epd_feeps_srvy_l2_electron_intensity_omni', '2015-12-15', '2015-12-16'), 'Problem with feeps multi probe'
  return, 1
end

function mms_load_feeps_ut::test_smooth
  mms_load_feeps, num_smooth=3.0, level='l2'
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_omni_smth', '2015-12-15', '2015-12-16'), 'Problem with creating smooted spectra'
  return, 1
end

function mms_load_feeps_ut::test_load_ion
  mms_load_feeps, datatype='ion', level='l2'
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_ion_intensity_omni', '2015-12-15', '2015-12-16'), $
    'Problem with loading ion data'
  return, 1
end

function mms_load_feeps_ut::test_load_ion_brst
  mms_load_feeps, datatype='ion', data_rate='brst', level='l2'
  assert, spd_data_exists('mms1_epd_feeps_brst_l2_ion_intensity_omni', '2015-12-15', '2015-12-16'), $
    'Problem with loading ion burst data'
  return, 1
end

function mms_load_feeps_ut::test_suffix
  mms_load_feeps, level='l2', suffix='_test'
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_omni_test', '2015-12-15', '2015-12-16'), 'Problem with suffix'
  return, 1
end

function mms_load_feeps_ut::test_pad_limited_en
  mms_feeps_pad, probe=1, energy=[200, 400]
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_200-400keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS limited energy range PAD'
  return, 1
end

function mms_load_feeps_ut::test_pad_bad_en
  mms_feeps_pad, probe=1, energy=[700, 800]
  assert, ~spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_700-800keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS bad energy range PAD'
  return, 1
end

function mms_load_feeps_ut::test_brst_caps_pad
  mms_load_feeps, data_rate='BRST', level='l2'
  mms_feeps_pad, probe=1, data_rate='BRST'
  assert, spd_data_exists('mms1_epd_feeps_brst_l2_electron_intensity_70-600keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS full energy range PAD (BRST)'
  return, 1
end

function mms_load_feeps_ut::test_brst_pad
  mms_load_feeps, data_rate='brst', level='l2'
  mms_feeps_pad, probe=1, data_rate='brst'
  assert, spd_data_exists('mms1_epd_feeps_brst_l2_electron_intensity_70-600keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS full energy range PAD (brst)'
  return, 1
end

function mms_load_feeps_ut::test_pad
  mms_load_feeps, probe=4
  mms_feeps_pad, probe=4
  assert, spd_data_exists('mms4_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS full energy range PAD'
  return, 1
end

function mms_load_feeps_ut::test_pad_angles_from_bfield
  mms_load_feeps, probe=1, data_rate='brst'
  mms_feeps_pad, probe=1, data_rate='brst'
  assert, ~spd_data_exists('mms1_fgm_b_gse_srvy_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem with /angles_from_bfield?'
  mms_feeps_pad, probe=1, data_rate='brst', /angles_from_bfield
  assert, spd_data_exists('mms1_fgm_b_gse_srvy_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem with /angles_from_bfield?'
  assert, spd_data_exists('mms1_epd_feeps_brst_l2_electron_intensity_70-600keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS full energy range PAD'
  return, 1
end

function mms_load_feeps_ut::test_load_spdf
  del_data,'*'
  mms_load_feeps, /spdf
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', '2015-12-15', '2015-12-16'), 'Problem loading L2 FEEPS data (SPDF)'
  return, 1
end

function mms_load_feeps_ut::test_load_l2
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', '2015-12-15', '2015-12-16'), 'Problem loading L2 FEEPS data'
  return, 1
end

function mms_load_feeps_ut::test_load_l1b
  del_data, '*'
  mms_load_feeps, level='l1b'
  assert, spd_data_exists('mms1_epd_feeps_srvy_l1b_electron_intensity_omni mms1_epd_feeps_srvy_l1b_electron_intensity_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading L1b FEEPS data'
  return, 1
end

function mms_load_feeps_ut::test_load_l1b_ion
  del_data, '*'
  mms_load_feeps, level='l1b', datatype='ion'
  assert, spd_data_exists('mms1_epd_feeps_srvy_l1b_ion_intensity_omni mms1_epd_feeps_srvy_l1b_ion_intensity_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading L1b FEEPS ion data'
  return, 1
end

function mms_load_feeps_ut::test_load_l1b_pad
  del_data, '*'
  mms_load_feeps, level='l1b', data_rate='Brst'
  mms_feeps_pad, level='l1B', data_rate='Brst'
  assert, spd_data_exists('mms1_epd_feeps_brst_l1b_electron_intensity_70-600keV_pad_spin mms1_epd_feeps_brst_l1b_electron_intensity_70-600keV_pad', '2015-12-15', '2015-12-16'), $
    'Problem loading burst mode FEEPS PAD for L1b data'
  return, 1
end

function mms_load_feeps_ut::test_load_l1b_pad_ion
  del_data, '*'
  mms_load_feeps, level='l1b', data_rate='Brst', datatype='Ion'
  mms_feeps_pad, level='l1B', data_rate='Brst', datatype='Ion'
  
  assert, spd_data_exists('mms1_epd_feeps_brst_l1b_ion_intensity_omni_spin mms1_epd_feeps_brst_l1b_ion_intensity_omni', '2015-12-15', '2015-12-16'), $
    'Problem loading burst mode FEEPS PAD for L1b data'
  return, 1
end

function mms_load_feeps_ut::test_load_suffix_pad
  del_data, '*'
  mms_load_feeps, level='l2', suffix='suffix_test'
  mms_feeps_pad, level='l2', suffix='suffix_test'
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_padsuffix_test mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad_spinsuffix_test', '2015-12-15', '2015-12-16'), $
    'Problem with suffix test in FEEPS PAD'
  return, 1
end

function mms_load_feeps_ut::test_load_timeclip
  del_data, '*'
  mms_load_feeps, level='l2', trange=['2015-12-15/11:00', '2015-12-15/12:00'], /time_clip
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_count_rate_omni_spin', '2015-12-15/11:00', '2015-12-15/12:00'), $
    'Problem with FEEPS time clipping'
  assert, ~spd_data_exists('mms1_epd_feeps_srvy_l2_electron_count_rate_omni_spin', '2015-12-15/10:00', '2015-12-15/11:00'), $
    'Problem with FEEPS time clipping'
  assert, ~spd_data_exists('mms1_epd_feeps_srvy_l2_electron_count_rate_omni_spin', '2015-12-15/12:00', '2015-12-15/13:00'), $
    'Problem with FEEPS time clipping'
  return, 1
end

function mms_load_feeps_ut::test_smooth_pad
  mms_load_feeps, num_smooth=30.0, level='l2'
  mms_feeps_pad, level='l2', num_smooth=30.0
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad_smth', '2015-12-15', '2015-12-16'), 'Problem with creating smooted PAD'
  return, 1
end

function mms_load_feeps_ut::test_pad_binsize
  mms_load_feeps, level='l2'
  mms_feeps_pad, bin_size=3
  get_data, 'mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad_spin', data=d
  assert, n_elements(d.V) eq 61, 'Problem with bin_size keyword in FEEPS PAD' 
  return, 1
end

pro mms_load_feeps_ut::setup
  del_data, '*'
  timespan, '2015-12-15/00:00', 1, /day
  mms_load_feeps, probe=1, level='L2'
end

function mms_load_feeps_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_feeps', 'mms_feeps_omni', $
                            'mms_feeps_pad_spinavg', 'mms_feeps_pad', $
                            'mms_feeps_remove_sun', 'mms_feeps_smooth', $
                            'mms_feeps_spin_avg', 'mms_feeps_split_integral_ch', $
                            'mms_feeps_correct_energies', 'mms_feeps_flat_field_corrections', $
                            'mms_feeps_pitch_angles', 'mms_feeps_remove_bad_data']
  self->addTestingRoutine, ['mms_read_feeps_sector_masks_csv', 'mms_feeps_energy_table', 'mms_feeps_active_eyes'], /is_function
  return, 1
end

pro mms_load_feeps_ut__define

  define = { mms_load_feeps_ut, inherits MGutTestCase }
end