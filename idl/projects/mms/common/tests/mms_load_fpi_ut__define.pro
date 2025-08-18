;+
;
; Unit tests for mms_load_fpi
;
; To run:
;     IDL> mgunit, 'mms_load_fpi_ut'
;
; warning: ACR tests in test_integration_time_get_dist require special, non-public CDFs
; to work / expect this test to fail if you don't have those files
; 
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2023-10-26 15:20:30 -0700 (Thu, 26 Oct 2023) $
; $LastChangedRevision: 32208 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_fpi_ut__define.pro $
;-

function mms_load_fpi_ut::test_dis_partmoms
  mms_load_fpi, trange=['2017-12-15', '2017-12-15/2'], probe=1, datatype='dis-partmoms'
  assert, spd_data_exists('mms1_dis_numberdensity_part_fast mms1_dis_bulkv_part_gse_fast', '2017-12-15', '2017-12-15/2'), 'Problem with DIS partial moments files'
  return, 1
end

function mms_load_fpi_ut::test_des_partmoms
  mms_load_fpi, trange=['2017-12-15', '2017-12-15/2'], probe=1, datatype='des-partmoms'
  assert, spd_data_exists('mms1_des_numberdensity_part_fast mms1_des_bulkv_part_gse_fast', '2017-12-15', '2017-12-15/2'), 'Problem with DES partial moments files'
  return, 1
end

function mms_load_fpi_ut::test_pseudo_moms_l3pre_files
  mms_load_fpi, data_rate='brst', trange=['2015-10-16', '2015-10-17'], level='l3pre', probe=1, datatype='dis-pseudomoms', cdf_filenames=fn
  assert, spd_data_exists('mms1_dis_pseudo_numberdensity_brst', '2015-10-16', '2015-10-17'), 'Problem with l3pre pseudo moments files'
  return, 1
end

;; the following are tests for moka_mms_pad_fpi
function mms_load_fpi_ut::test_moka_mms_pad_fpi_df_suberr
  mms_load_fpi, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='des-dist', probe=1
  mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1
  dist = mms_get_dist('mms1_des_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], /subtract_err, error='mms1_des_disterr_brst')
  df =  moka_mms_pad_fpi(dist, time='2015-10-16/13:06:30', samples=1, units='df_km', mag_data='mms1_fgm_b_dmpa_srvy_l2_bvec')
  return, 1
end

function mms_load_fpi_ut::test_moka_mms_pad_fpi_eflux_suberr
  mms_load_fpi, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='des-dist', probe=1
  mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1
  dist = mms_get_dist('mms1_des_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], /subtract_err, error='mms1_des_disterr_brst')
  eflux =  moka_mms_pad_fpi(dist, time='2015-10-16/13:06:30', samples=1, units='eflux', mag_data='mms1_fgm_b_dmpa_srvy_l2_bvec')
  return, 1
end

function mms_load_fpi_ut::test_moka_mms_pad_fpi_time_window
  mms_load_fpi, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='des-dist', probe=1
  mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1, data_rate='brst'
  dist = mms_get_dist('mms1_des_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], /subtract_err, error='mms1_des_disterr_brst')
  df =  moka_mms_pad_fpi(dist, time='2015-10-16/13:06:30', window=6, units='df_km', mag_data='mms1_fgm_b_dmpa_brst_l2_bvec')
  assert, array_equal(time_string(df.trange), ['2015-10-16/13:06:30', '2015-10-16/13:06:36']), 'Regression with time/windw in PAD code'
  return, 1
end

function mms_load_fpi_ut::test_moka_mms_pad_fpi_trange
  mms_load_fpi, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='des-dist', probe=1
  mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1, data_rate='brst'
  dist = mms_get_dist('mms1_des_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], /subtract_err, error='mms1_des_disterr_brst')
  df =  moka_mms_pad_fpi(dist, trange=['2015-10-16/13:06:30', '2015-10-16/13:06:38'], mag_data='mms1_fgm_b_dmpa_brst_l2_bvec')
  assert, array_equal(time_string(df.trange), ['2015-10-16/13:06:30', '2015-10-16/13:06:38']), 'Regression with trange in PAD code'
  return, 1
end

function mms_load_fpi_ut::test_moka_mms_pad_fpi_time_samples
  mms_load_fpi, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='des-dist', probe=1
  mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1, data_rate='brst'
  dist = mms_get_dist('mms1_des_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], /subtract_err, error='mms1_des_disterr_brst')
  df =  moka_mms_pad_fpi(dist, time='2015-10-16/13:06:30', samples=14, units='df_km', mag_data='mms1_fgm_b_dmpa_brst_l2_bvec')
  assert, array_equal(time_string(df.trange, tformat='YYYY-MM-DD/hh:mm:ss.fff'), ['2015-10-16/13:06:29.775', '2015-10-16/13:06:30.195']), 'Regression with time/samples in PAD code'
  return, 1
end

function mms_load_fpi_ut::test_moka_mms_pad_fpi_window_centered
  mms_load_fpi, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='des-dist', probe=1
  mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1, data_rate='brst'
  dist = mms_get_dist('mms1_des_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], /subtract_err, error='mms1_des_disterr_brst')
  df =  moka_mms_pad_fpi(/center_time, dist, time='2015-10-16/13:06:30', window=9, units='df_km', mag_data='mms1_fgm_b_dmpa_brst_l2_bvec')
  assert, array_equal(time_string(df.trange, tformat='YYYY-MM-DD/hh:mm:ss.fff'), ['2015-10-16/13:06:25.500', '2015-10-16/13:06:34.500']), 'Regression with time/window (centered) in PAD code'
  return, 1
end

function mms_load_fpi_ut::test_moka_mms_pad_fpi_nbin
  mms_load_fpi, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='des-dist', probe=1
  mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1, data_rate='brst'
  dist = mms_get_dist('mms1_des_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], /subtract_err, error='mms1_des_disterr_brst')
  df =  moka_mms_pad_fpi(nbin=33, dist, trange=['2015-10-16/13:06:30', '2015-10-16/13:06:38'], mag_data='mms1_fgm_b_dmpa_brst_l2_bvec')
  assert, n_elements(df.pa) eq 35, 'Regression with nbins in PAD code'
  return, 1
end

function mms_load_fpi_ut::test_moka_mms_pad_fpi_norm
  mms_load_fpi, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='des-dist', probe=1
  mms_load_fgm, trange=['2015-10-16/13:06', '2015-10-16/13:07'], probe=1, data_rate='brst'
  dist = mms_get_dist('mms1_des_dist_brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'], /subtract_err, error='mms1_des_disterr_brst')
  df =  moka_mms_pad_fpi(/norm, dist, trange=['2015-10-16/13:06:30', '2015-10-16/13:06:38'], mag_data='mms1_fgm_b_dmpa_brst_l2_bvec')
  assert, array_equal(minmax(df.data), [0.0, 1.0]), 'Regression with /norm keyword in PAD code'
  return, 1
end
;; end moka_mms_pad_fpi tests

function mms_load_fpi_ut::test_subtract_disterr
  mms_load_fpi, trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', datatype='des-dist', probe=1, /time_clip
  dist = mms_get_fpi_dist('mms1_des_dist_brst')
  dist_data = *dist
  disterr = mms_get_fpi_dist('mms1_des_disterr_brst')
  disterr_data = *disterr
  distSub = mms_get_fpi_dist('mms1_des_dist_brst', error='mms1_des_disterr_brst', /subtract_error)
  distsub_data = *distSub
  assert, array_equal(dist_data.data-disterr_data.data, distsub_data.data), 'Problem with disterr subtraction in mms_get_fpi_dist'
  return, 1
end

; regression tests ---------->
; problems with qd[ei]s-moms files that have depend_3 but not depend_2 or depend_1
function mms_load_fpi_ut::test_qmoms_brst
  mms_load_fpi, datatype='dis-pmoms', data_rate='brst', level='l1b', trange=['2017-07-11/22:33:20', '2017-07-11/22:33:24']
  get_data, 'mms3_dis_bulkv_part_gse_brst', data=d
  assert, n_elements(d.v[0, *]) eq 32, 'Problem loading dis-qmoms files (brst)'
  get_data, 'mms3_dis_prestensor_part_gse_brst', data=d
  assert, n_elements(d.v[0, *]) eq 32, 'Problem loading dis-qmoms files (brst)'
  return, 1
end

function mms_load_fpi_ut::test_qmoms_fast
  mms_load_fpi, datatype='dis-partmoms', data_rate='fast', level='l2', trange=['2018-05-02/10:00', '2018-05-02/14:00']
  get_data, 'mms3_dis_bulkv_part_gse_fast', data=d
  assert, n_elements(d.v[0, *]) eq 32, 'Problem loading dis-qmoms files'
  get_data, 'mms3_dis_prestensor_part_gse_fast', data=d
  assert, n_elements(d.v[0, *]) eq 32, 'Problem loading dis-qmoms files'
  return, 1
end

; problem / crash with compressionloss variable for fast survey data
function mms_load_fpi_ut::test_fast_compressionloss
  tr_load  = time_double('2017-07-17/'+['14:05:00','16:00:00'])
  mms_load_fpi,trange=tr_load,probe='3',data_rate='fast',level='l2', datatype=['des-dist']
  get_data, 'mms3_des_compressionloss_fast_dist', data=d
  assert, n_elements(d.X) eq n_elements(d.Y), 'Problem with FPI fast survey compressionloss variable'
  return, 1
end

; FPI distribution error data
function mms_load_fpi_ut::test_get_fpi_dist_err
  mms_load_fpi, datatype='des-dist', trange=['2015-12-15', '2015-12-16'], probe=1
  fpi_err_dist = mms_get_dist('mms1_des_disterr_fast')
  assert, is_struct(*fpi_err_dist), 'Problem with FPI distribution error regression in mms_get_dist'
  return, 1
end

; same as below, except using mms_get_dist
function mms_load_fpi_ut::test_integration_time_get_dist
  mms_load_fpi, trange=['2015-10-16/13:00', '2015-10-16/13:10'], datatype=['dis-dist', 'des-dist'], data_rate='brst'
 ; mms_load_fpi, trange=['2016-12-09', '2016-12-10'], datatype=['dis-qdist', 'des-qdist'], data_rate='brst', suffix='acr', probe=1
  mms_load_fpi, trange=['2015-10-16/13:00', '2015-10-16/13:10'], datatype=['dis-dist', 'des-dist'], data_rate='fast'
 ; fpi_dist = mms_get_dist('mms1_dis_dist_brstacr',trange=time_double(['2016-12-09', '2016-12-10']), probe = 1, species = 'i')
 ; assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-0.0375)/0.0375d lt 0.001, 'Problem with integration time returned by mms_get_dist (ions, brst, ACR)'
 ; fpi_dist = mms_get_dist('mms1_des_dist_brstacr',trange=time_double(['2016-12-09', '2016-12-10']), probe = 1, species = 'e')
 ; assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-0.0075)/0.0075d lt 0.001, 'Problem with integration time returned by mms_get_dist (electrons, brst, ACR)'
 
  fpi_dist = mms_get_dist('mms3_dis_dist_brst',trange=time_double(['2015-10-16/13:00', '2015-10-16/13:10']), probe = 3, species = 'i')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-0.15)/0.15d lt 0.001, 'Problem with integration time returned by mms_get_dist (ions, brst)'
  fpi_dist = mms_get_dist('mms3_des_dist_brst',trange=time_double(['2015-10-16/13:00', '2015-10-16/13:10']), probe = 3, species = 'e')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-0.03)/0.03d lt 0.001, 'Problem with integration time returned by mms_get_dist (electrons, brst)'
  fpi_dist = mms_get_dist('mms3_dis_dist_fast',trange=time_double(['2015-10-16/13:00', '2015-10-16/13:10']), probe = 3, species = 'i')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-4.5)/4.5d lt 0.001, 'Problem with integration time returned by mms_get_dist (ions, fast)'
  fpi_dist = mms_get_dist('mms3_des_dist_fast',trange=time_double(['2015-10-16/13:00', '2015-10-16/13:10']), probe = 3, species = 'e')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-4.5)/4.5d lt 0.001, 'Problem with integration time returned by mms_get_dist (electrons, fast)'
  return, 1
end

function mms_load_fpi_ut::test_integration_time_get_i_dist_slow
  mms_load_fpi, trange=['2015-10-16', '2015-10-17'], datatype='dis-dist', data_rate='slow', level='l1b', probe=4
  fpi_dist = mms_get_fpi_dist('mms4_dis_dist_slow',trange=time_double(['2015-10-16', '2015-10-17']), probe = 4, species = 'i')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-59)/59d lt 0.02, 'Problem with integration time returned by mms_get_fpi_dist'
  return, 1
end

function mms_load_fpi_ut::test_integration_time_get_e_dist_slow
  mms_load_fpi, trange=['2015-10-16', '2015-10-17'], datatype='des-dist', data_rate='slow', level='l1b', probe=4
  fpi_dist = mms_get_fpi_dist('mms4_des_dist_slow',trange=time_double(['2015-10-16', '2015-10-17']), probe = 4, species = 'e')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-59)/59d lt 0.02, 'Problem with integration time returned by mms_get_fpi_dist'
  return, 1
end

function mms_load_fpi_ut::test_integration_time_get_i_dist_brst
  mms_load_fpi, trange=['2015-10-16/13:00', '2015-10-16/13:10'], datatype='dis-dist', data_rate='brst'
  fpi_dist = mms_get_fpi_dist('mms3_dis_dist_brst',trange=time_double(['2015-10-16/13:00', '2015-10-16/13:10']), probe = 3, species = 'i')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-0.15)/0.15d lt 0.001, 'Problem with integration time returned by mms_get_fpi_dist'
  return, 1
end

function mms_load_fpi_ut::test_integration_time_get_e_dist_brst
  mms_load_fpi, trange=['2015-10-16/13:00', '2015-10-16/13:10'], datatype='des-dist', data_rate='brst'
  fpi_dist = mms_get_fpi_dist('mms3_des_dist_brst',trange=time_double(['2015-10-16/13:00', '2015-10-16/13:10']), probe = 3, species = 'e')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-0.03)/0.03d lt 0.001, 'Problem with integration time returned by mms_get_fpi_dist'
  return, 1
end

function mms_load_fpi_ut::test_integration_time_get_i_dist_fast
  mms_load_fpi, trange=['2015-10-16/13:00', '2015-10-16/13:10'], datatype='dis-dist', data_rate='fast'
  fpi_dist = mms_get_fpi_dist('mms3_dis_dist_fast',trange=time_double(['2015-10-16/13:00', '2015-10-16/13:10']), probe = 3, species = 'i')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-4.5)/4.5d lt 0.001, 'Problem with integration time returned by mms_get_fpi_dist'
  return, 1
end

function mms_load_fpi_ut::test_integration_time_get_e_dist_fast
  mms_load_fpi, trange=['2015-10-16/13:00', '2015-10-16/13:10'], datatype='des-dist', data_rate='fast'
  fpi_dist = mms_get_fpi_dist('mms3_des_dist_fast',trange=time_double(['2015-10-16/13:00', '2015-10-16/13:10']), probe = 3, species = 'e')
  assert, abs(((*fpi_dist)[0].end_time-(*fpi_dist)[0].time)-4.5)/4.5d lt 0.001, 'Problem with integration time returned by mms_get_fpi_dist'
  return, 1
end

; tplotnames regressions
function mms_load_fpi_ut::test_loading_tplotnames_desmoms
  mms_load_fpi, trange=['2015-10-15', '2015-10-16'], datatype='des-moms', tplotnames = tplotnames
  assert, n_elements(tplotnames) eq 41, '(potential) Problem with number of tplotnames returned from mms_load_fpi'
  return, 1
end

function mms_load_fpi_ut::test_loading_tplotnames_desdist
  mms_load_fpi, trange=['2015-10-15', '2015-10-16'], datatype='des-dist', tplotnames = tplotnames
  assert, n_elements(tplotnames) eq 12, '(potential) Problem with number of tplotnames returned from mms_load_fpi'
  return, 1
end

function mms_load_fpi_ut::test_loading_tplotnames_des
  mms_load_fpi, trange=['2015-10-15', '2015-10-16'], datatype=['des-moms', 'des-dist'], tplotnames = tplotnames
  assert, n_elements(tplotnames) eq 51, '(potential) Problem with number of tplotnames returned from mms_load_fpi'
  return, 1
end

; user requests a few seconds after file start time
function mms_load_fpi_ut::test_seconds_after_file_start_spdf
  mms_load_fpi, trange=['2015-10-15/6:45:21', '2015-10-15/6:51:21'], data_rate='brst', level='l2', /spdf
  assert, spd_data_exists('mms3_dis_bulkv_dbcs_brst','2015-10-15/06:47:23','2015-10-15/06:54:59'), $
    'Error! Not grabbing the correct data from the SPDF??? (1)'
  return, 1
end

; user requests a few seconds after file end time
function mms_load_fpi_ut::test_seconds_after_file_end_spdf
  mms_load_fpi, trange=['2015-10-15/6:49:21', '2015-10-15/6:54:01'], data_rate='brst', level='l2', /spdf
  assert, spd_data_exists('mms3_dis_bulkv_dbcs_brst','2015-10-15/06:47:23','2015-10-15/06:54:59'), $
    'Error! Not grabbing the correct data from the SPDF??? (2)'
  return, 1
end

; user requests a time interval without any CDF files inside
function mms_load_fpi_ut::test_empty_interval_spdf
  mms_load_fpi, trange=['2015-10-15/6:46:21', '2015-10-15/6:49:01'], data_rate='brst', level='l2', /spdf
  assert, spd_data_exists('mms3_dis_bulkv_dbcs_brst','2015-10-15/06:47:23','2015-10-15/06:49:59'), $
    'Error! Not grabbing the correct data from the SPDF??? (3)'
  return, 1
end

; user requests a time interval just beyond start time (but inside the interval)
; of last burst-mode file for the day
function mms_load_fpi_ut::test_weird_fpi_case_spdf
  mms_load_fpi, trange=['2015-10-16/13:07', '2015-10-16/13:09'], data_rate='brst', level='l2', /spdf
  assert, spd_data_exists('mms3_dis_bulkv_dbcs_brst','2015-10-16/13:07','2015-10-16/13:09'), $
    'Error! Not grabbing the correct data from the SPDF??? (4)'
  return, 1
end

; user downloads data, then tries to load the data using /no_update
function mms_load_fpi_ut::test_noupdate_actually_works_spdf
  ; load the data from the web
  mms_load_fpi, trange=['2015-10-15', '2015-10-18'], level='l2', probe=1, datatype='dis-moms', cdf_filenames=fn_sdc, /spdf
  del_data, '*'

  ; load the data locally
  mms_load_fpi, trange=['2015-10-15', '2015-10-18'], level='l2', probe=1, datatype='dis-moms', cdf_filenames=fn_local, /no_update, /spdf
  assert, spd_data_exists('mms1_dis_energyspectr_omni_fast', '2015-10-15', '2015-10-18'), $
    'Problem loading data from local drive'
  assert, array_equal(fn_sdc, fn_local), $
    'Problem loading data from local drive (different CDF filenames)'
  return, 1
end

; check that loading from local data doesn't load all data for the day
function mms_load_fpi_ut::test_noupdate_mem_spdf
  ; load the data from the web
  mms_load_fpi, trange=['2015-10-16/13:06:00', '2015-10-16/13:08:00'], level='l2', probe=1, datatype='dis-moms', cdf_filenames=fn_sdc, /spdf
  del_data, '*'

  ; load the data locally
  mms_load_fpi, trange=['2015-10-16/13:06:00', '2015-10-16/13:08:00'], level='l2', probe=1, datatype='dis-moms', cdf_filenames=fn_local, /no_update, /spdf
  assert, array_equal(fn_sdc, fn_local), $
    'Problem loading data from local drive (different CDF filenames)'
  return, 1
end

; user requests a few seconds after file start time
function mms_load_fpi_ut::test_seconds_after_file_start
  mms_load_fpi, trange=['2015-10-15/6:45:21', '2015-10-15/6:51:21'], data_rate='brst', level='l2'
  assert, spd_data_exists('mms3_dis_bulkv_dbcs_brst','2015-10-15/06:47:23','2015-10-15/06:54:59'), $
    'Error! Not grabbing the correct data from the SDC???'
  return, 1
end

; user requests a few seconds after file end time
function mms_load_fpi_ut::test_seconds_after_file_end
  mms_load_fpi, trange=['2015-10-15/6:49:21', '2015-10-15/6:54:01'], data_rate='brst', level='l2'
  assert, spd_data_exists('mms3_dis_bulkv_dbcs_brst','2015-10-15/06:47:23','2015-10-15/06:54:59'), $
    'Error! Not grabbing the correct data from the SDC???'
  return, 1
end

; user requests a time interval without any CDF files inside
function mms_load_fpi_ut::test_empty_interval
  mms_load_fpi, trange=['2015-10-15/6:46:21', '2015-10-15/6:49:01'], data_rate='brst', level='l2'
  assert, spd_data_exists('mms3_dis_bulkv_dbcs_brst','2015-10-15/06:47:23','2015-10-15/06:49:59'), $
    'Error! Not grabbing the correct data from the SDC???'
  return, 1
end

; user requests a time interval just beyond start time (but inside the interval)
; of last burst-mode file for the day
function mms_load_fpi_ut::test_weird_fpi_case
  mms_load_fpi, trange=['2015-10-16/13:07', '2015-10-16/13:09'], data_rate='brst', level='l2'
  assert, spd_data_exists('mms3_dis_bulkv_dbcs_brst','2015-10-16/13:07','2015-10-16/13:09'), $
    'Error! Not grabbing the correct data from the SDC???'
  return, 1
end

; user downloads data, then tries to load the data using /no_update
function mms_load_fpi_ut::test_noupdate_actually_works
  ; load the data from the web
  mms_load_fpi, trange=['2015-10-15', '2015-10-18'], level='l2', probe=1, datatype='dis-moms', cdf_filenames=fn_sdc, /latest
  del_data, '*'
  
  ; load the data locally
  mms_load_fpi, trange=['2015-10-15', '2015-10-18'], level='l2', probe=1, datatype='dis-moms', cdf_filenames=fn_local, /no_update, /latest
  assert, spd_data_exists('mms1_dis_energyspectr_omni_fast', '2015-10-15', '2015-10-18'), $
    'Problem loading data from local drive'
  assert, array_equal(strlowcase(fn_sdc), strlowcase(fn_local)), $
    'Problem loading data from local drive (different CDF filenames)'
  return, 1
end

; check that loading from local data doesn't load all data for the day
function mms_load_fpi_ut::test_noupdate_mem
  ; load the data from the web
  mms_load_fpi, trange=['2015-10-16/13:06:00', '2015-10-16/13:08:00'], level='l2', probe=1, datatype='dis-moms', cdf_filenames=fn_sdc
  del_data, '*'
  
  ; load the data locally
  mms_load_fpi, trange=['2015-10-16/13:06:00', '2015-10-16/13:08:00'], level='l2', probe=1, datatype='dis-moms', cdf_filenames=fn_local, /no_update
  assert, array_equal(strlowcase(fn_sdc), strlowcase(fn_local)), $
    'Problem loading data from local drive (different CDF filenames)'
  return, 1
end

; check that the errorflags variable can be loaded without being overwritten
; when the user requests datatype=['d?s-dist', 'd?s-moms']
function mms_load_fpi_ut::test_load_errorflags_moms_and_dist
  mms_load_fpi, datatype=['dis-moms', 'dis-dist'], data_rate='fast', trange=['2015-12-15', '2015-12-16'], probe=3
  assert, spd_data_exists('mms3_dis_errorflags_fast_moms mms3_dis_errorflags_fast_dist', '2015-12-15', '2015-12-16'), 'Problem loading errorflags variables'
  get_data, 'mms3_dis_errorflags_fast_moms', data=a
  get_data, 'mms3_dis_errorflags_fast_dist', data=b
  
  assert, ~array_equal(a.Y, b.Y), 'Problem loading errorflags variables'
  
  mms_load_fpi, datatype=['des-moms', 'des-dist'], data_rate='fast', trange=['2015-12-15', '2015-12-16'], probe=3
  assert, spd_data_exists('mms3_des_errorflags_fast_moms mms3_des_errorflags_fast_dist', '2015-12-15', '2015-12-16'), 'Problem loading errorflags variables'
  get_data, 'mms3_des_errorflags_fast_moms', data=a
  get_data, 'mms3_des_errorflags_fast_dist', data=b

  assert, ~array_equal(a.Y, b.Y), 'Problem loading errorflags variables'
  return, 1
end

; check that the above works with the suffix keyword
function mms_load_fpi_ut::test_load_errorflags_moms_and_dist_suffix
  mms_load_fpi, datatype=['dis-moms', 'dis-dist'], data_rate='fast', trange=['2015-12-15', '2015-12-16'], probe=3, suffix='TESTSUFFIX'
  assert, spd_data_exists('mms3_dis_errorflags_fastTESTSUFFIX_moms mms3_dis_errorflags_fastTESTSUFFIX_dist', '2015-12-15', '2015-12-16'), 'Problem loading errorflags variables'
  get_data, 'mms3_dis_errorflags_fastTESTSUFFIX_moms', data=a
  get_data, 'mms3_dis_errorflags_fastTESTSUFFIX_dist', data=b

  assert, ~array_equal(a.Y, b.Y), 'Problem loading errorflags variables'

  mms_load_fpi, datatype=['des-moms', 'des-dist'], data_rate='fast', trange=['2015-12-15', '2015-12-16'], probe=3, suffix='TESTSUFFIX2'
  assert, spd_data_exists('mms3_des_errorflags_fastTESTSUFFIX2_moms mms3_des_errorflags_fastTESTSUFFIX2_dist', '2015-12-15', '2015-12-16'), 'Problem loading errorflags variables'
  get_data, 'mms3_des_errorflags_fastTESTSUFFIX2_moms', data=a
  get_data, 'mms3_des_errorflags_fastTESTSUFFIX2_dist', data=b

  assert, ~array_equal(a.Y, b.Y), 'Problem loading errorflags variables'
  return, 1
end

; check that we don't crash when the version # isn't valid
function mms_load_fpi_ut::test_load_local_file_badversion
  mms_load_fpi, datatype='des-moms', trange=['2015-12-5', '2015-12-6'], cdf_version='2.32.0', /no_update
  return, 1
end

; the following tests loading the ACR burst mode data 
; and tests /center_measurement functionality
; 3May2018: doesn't work because of incorrect metadata on the CDF files; should be re-enabled when fixed
;function mms_load_fpi_ut::test_acr_brst_data
;  mms_load_fpi, level='l2', trange=['2016-12-09', '2016-12-10'], probe=1, data_rate='brst', datatype='des-qmoms'
;  mms_load_fpi, level='l2', trange=['2016-12-09', '2016-12-10'], probe=1, data_rate='brst', suffix='centered', /center_measurement, datatype='des-qmoms'
;  get_data, 'mms1_des_bulkv_dbcs_brst', data=d
;  get_data, 'mms1_des_bulkv_dbcs_brstcentered', data=c
;  assert, spd_data_exists('mms1_des_bulkv_dbcs_brst mms1_des_bulkv_dbcs_brstcentered', '2016-12-09', '2016-12-10'), 'Problem checking /center_measurement with ACR brst files'
;  assert, time_string(c.X[0], tformat='YYYY-MM-DD/hh:mm:ss.fff') eq '2016-12-09/08:58:54.110', 'Problem checking /center_measurement with ACR brst files'
;  assert, time_string(d.X[0], tformat='YYYY-MM-DD/hh:mm:ss.fff') eq '2016-12-09/08:58:54.005', 'Problem checking /center_measurement with ACR brst files'
;  return, 1
;end

; the following tests for a regression when the user runs
; mms_get_fpi_dist on a burst interval with gaps
function mms_load_fpi_ut::test_dist_burst_with_gaps
  mms_load_fpi, trange=['2015-12-15/11:18', '2015-12-15/11:36'], data_rate='brst', /time_clip, datatype='des-dist'
  return, 1
end

; load data from v3.3 and v3.2 CDF files
;function mms_load_fpi_ut::test_moms_errorflags_updates
;  mms_load_fpi, level='l1b', trange=['2015-10-16', '2015-10-17'], data_rate='brst', cdf_version='3.3', datatype='dis-moms', suffix='_new'
;  mms_load_fpi, level='l1b', trange=['2015-10-16', '2015-10-17'], data_rate='brst', cdf_version='3.2', datatype='dis-moms', suffix='_old'
;  get_data, 'mms3_dis_errorflags_brst_new_moms_flagbars_full', data=newdata
;  get_data, 'mms3_dis_errorflags_brst_old_moms_flagbars_full', data=olddata
;  assert, round(total(olddata.Y[0, *]*10, /nan)) eq 15, 'Problem with v3.2 -> v3.3 regression'
;  assert, round(total(newdata.Y[0, *]*10, /nan)) eq 13, 'Problem with v3.2 -> v3.3 regression'
;  return, 1
;end

; end of regression tests <------

; check multiple data rates
;function mms_load_fpi_ut::test_load_datarate_array
;  mms_load_fpi, probe=3, data_rate=['fast', 'brst'], level='l2'
;  assert, spd_data_exists('', '2015-12-15', '2015-12-16'), $
;    'Problem loading FPI data with multiple data rates specified'
;  return, 1
;end

function mms_load_fpi_ut::test_ang_ang_elec
  @error_is_pass
  mms_fpi_ang_ang, '2015-10-15/13:06:30', species='elec',/png
  return, 1
end

function mms_load_fpi_ut::test_ang_ang_e
  mms_fpi_ang_ang, '2015-10-15/13:06:30', species='e',/png
  return, 1
end

function mms_load_fpi_ut::test_load
  mms_load_fpi, probe=4, level='l2', datatype='des-moms'
  assert, spd_data_exists('mms4_des_energyspectr_omni_fast mms4_des_pitchangdist_avg mms4_des_energyspectr_px_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data'
  return, 1
end

function mms_load_fpi_ut::test_load_multi_probes
  mms_load_fpi, probe=['1', '4'], level='l2', datatype='des-moms'
  assert, spd_data_exists('mms1_des_energyspectr_omni_fast mms4_des_pitchangdist_avg mms1_des_energyspectr_pz_fast', '2015-12-15', '2015-12-16'), 'Problem loading multiple probe fpi data'
  return, 1
end

function mms_load_fpi_ut::test_load_mixed_probe_type
  mms_load_fpi, probes=['1', 4], level='l2', datatype='des-moms'
  assert, spd_data_exists('mms1_des_energyspectr_omni_fast mms4_des_pitchangdist_avg mms1_des_energyspectr_pz_fast', '2015-12-15', '2015-12-16'), 'Problem loading mixed probe type fpi data'
  return, 1
end

function mms_load_fpi_ut::test_load_level_ql
  mms_load_fpi, probe=1, level='ql', min_version='3.0.0'
  assert, spd_data_exists('mms1_des_energyspectr_omni_fast mms1_des_energyspectr_py_fast','2015-12-15', '2015-12-16'), 'Problem loading quicklook fpi data'
  assert, ~spd_data_exists('mms2_dis_TempYY_err','2015-12-15', '2015-12-16'), 'Problem loading quicklook fpi data'
  return, 1
end

function mms_load_fpi_ut::test_load_level_sitl
  mms_load_fpi, probes=[4], level='sitl'
  assert, spd_data_exists('mms4_fpi_ePitchAngDist_avg', '2015-12-15', '2015-12-16'), 'Problem loading fpi data of type sitl'
  return, 1
end

function mms_load_fpi_ut::test_load_data_rate
  mms_load_fpi, probes=1, data_rate='fast', datatype='des-moms'
  assert, spd_data_exists('mms1_des_energyspectr_mz_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data rate'
  return, 1
end

function mms_load_fpi_ut::test_load_data_rate_caps
  mms_load_fpi, probes='1', data_rate='FAST', datatype='des-moms'
  assert, spd_data_exists('mms1_des_energyspectr_mz_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data rate with CAPS'
  return, 1
end

function mms_load_fpi_ut::test_load_data_rate_invalid
  mms_load_fpi, probes=['1'], datatype=1234
  assert, ~spd_data_exists('mms1_des_energyspectr_mz_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with invalid data rate'
  return, 1
end

function mms_load_fpi_ut::test_load_dtypes
  mms_load_fpi, probe=1, datatype=['des-moms']
  assert, spd_data_exists('mms1_des_energyspectr_anti_fast mms1_des_pitchangdist_lowen_fast mms1_des_prestensor_gse_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data using data type'
  return, 1
end

function mms_load_fpi_ut::test_load_dtypes_multi
  mms_load_fpi, probe=1, datatype=['des-moms', 'dis-dist']
  assert, spd_data_exists('mms1_des_energyspectr_mx_fast mms1_des_pitchangdist_miden_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data type using multiple data types'
  return, 1
end

function mms_load_fpi_ut::test_load_dtypes_caps
  mms_load_fpi, probe=1, datatype='DIS', level='ql', min_version='3.0.0'
  assert, spd_data_exists('mms1_dis_startdelphi_angle_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data types in CAPS (1)'
  assert, ~spd_data_exists('mms1_DIS_startdelphi_angle_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data types in CAPS (2)'
  return, 1
end

function mms_load_fpi_ut::test_load_dtypes_star
  mms_load_fpi, probe=1, datatype='*'
  assert, spd_data_exists('mms1_des_pitchangdist_avg', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data types with star (1)'
  assert, ~spd_data_exists('mms3_des_pitchangdist_avg', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data types with star (2)'
  return, 1
end

function mms_load_fpi_ut::test_load_suffix
  mms_load_fpi, probe=4, level=['sitl'], suffix='_test'
  assert, spd_data_exists('mms4_fpi_startDelPhi_count_test mms4_fpi_eEnergySpectr_pY_test', '2015-12-15', '2015-12-16'), 'Problem loading fpi data using suffix keyword'
  assert, ~spd_data_exists('mms4_fpi_eEnergySpectr_pY', '2015-12-15', '2015-12-16'), 'Problem loading fpi data using suffix keyword'
  return, 1
end

function mms_load_fpi_ut::test_load_time_clip
  mms_load_fpi, probe=1, datatype='DIS', level='ql', trange=['2015-12-15 00:04:00', '2015-12-15 00:12:00'], /time_clip
  assert, spd_data_exists('mms1_dis_startdelphi_angle_fast', '2015-12-15/00:04:00', '2015-12-15/00:12:00'), 'Problem loading fpi data with time_clip'
  assert, ~spd_data_exists('mms1_dis_startdelphi_angle_fast', '2015-12-15/00:00:00', '2015-12-15/00:4:00'), 'Problem loading fpi data with time_clip'
  assert, ~spd_data_exists('mms1_dis_startdelphi_angle_fast', '2015-12-15/00:12:00', '2015-12-15/00:14:00'), 'Problem loading fpi data with time_clip'
  return, 1
end

function mms_load_fpi_ut::test_load_spdf
  mms_load_fpi, probe=1, datatype=['des-moms'], /spdf
  assert, spd_data_exists('mms1_des_energyspectr_mx_fast mms1_des_pitchangdist_miden_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data type using spdf'
  assert, ~spd_data_exists('mms2_des_energyspectr_mx_fast mms3_des_pitchangdist_miden_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data type using spdf'
  return, 1
end

function mms_load_fpi_ut::test_load_trange
  trange=timerange()
  mms_load_fpi, trange=trange, probe=1, datatype=['des-moms'], /spdf
  assert, spd_data_exists('mms1_des_energyspectr_mx_fast mms1_des_pitchangdist_miden_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data type using trange'
  return, 1
end

function mms_load_fpi_ut::test_load_future_time
  start_date = systime(/seconds) + 86400.*10.
  stop_date = start_date + 86400.
  mms_load_fpi, trange=[start_date, stop_date], probe=1, datatype=['des-moms']
  assert, ~spd_data_exists('mms1_*', '2040-07-30', '2040-07-31'), 'Problem loading fpi data for date in future'
  return, 1
end

; regression test for bug fixed by updated CDFs (v3)
function mms_load_fpi_ut::test_load_energies_no_support
  mms_load_fpi, datatype='des-moms', varformat='*energys*', probe=1
  get_data, 'mms1_des_energyspectr_mx_fast', data=d
  assert, n_elements(d.V[0, *]) eq 32 and d.V[0, 31] ne 31, 'Problem with energy table in FPI energy spectra variables'
  return, 1
end

pro mms_load_fpi_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
  ; create a connection to the SDC (as a team member); ignore the 'FGM' part
  mms_load_data, login_info='test_auth_info_team.sav', instrument='fgm'
end

function mms_load_fpi_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_fpi', 'mms_load_fpi_fix_spectra', 'mms_load_fpi_fix_dist', 'mms_load_fpi_fix_angles', $
      'mms_load_fpi_calc_omni', 'mms_load_fpi_calc_pad', 'mms_fpi_fix_metadata']
  return, 1
end

pro mms_load_fpi_ut__define
  define = { mms_load_fpi_ut, inherits MGutTestCase }
end