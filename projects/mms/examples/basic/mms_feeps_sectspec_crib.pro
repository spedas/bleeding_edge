;+
;
;     mms_feeps_sectspec_crib
;     
;     
;     This crib sheet shows how to create sector spectrograms of FEEPS data
;     for checking effectiveness of sunlight masking/removal
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-05-21 10:06:13 -0700 (Tue, 21 May 2019) $
; $LastChangedRevision: 27269 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_feeps_sectspec_crib.pro $
;-

;trange = ['2016-1-20/19:50', '2016-1-20/19:55']
trange = ['2015-10-16/13:00', '2015-10-16/13:10']

data_rate = 'brst'
probe = '1'
level = 'l2'
datatype='electron'

; load the FEEPS data
mms_load_feeps, datatype=datatype, probe = probe, trange = trange, data_rate = data_rate, level=level, /time_clip

; generate the sector-time spectrograms, no sun contamination removed
mms_feeps_sector_spec, probe = probe, data_rate = data_rate, level = level, datatype=datatype

stop

; electrons, no sun contamination removed
tplot, ['mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_3_sectspec', $
        'mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_4_sectspec', $
        'mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_5_sectspec', $
        'mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_10_sectspec', $
        'mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_11_sectspec']

stop

; generate the sector-time spectrograms with sun contamination removed
mms_feeps_sector_spec, probe = probe, data_rate = data_rate, /remove_sun, datatype=datatype

window, 1
tplot, window=1, ['mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_3_sectspec_sun_removed', $
  'mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_4_sectspec_sun_removed', $
  'mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_5_sectspec_sun_removed', $
  'mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_10_sectspec_sun_removed', $
  'mms1_epd_feeps_brst_l2_'+datatype+'_bottom_count_rate_sensorid_11_sectspec_sun_removed']
stop
end