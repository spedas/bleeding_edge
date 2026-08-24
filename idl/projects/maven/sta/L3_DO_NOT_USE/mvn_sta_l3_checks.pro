;+
;Routine for checking ephemeris data in STATIC L3 files, comparing values in the density and temperature files.
;Set timespan before running this:
;
;timespan, '2017-10-24', 2.
;mvn_sta_l3_checks
;
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_checks.pro   ;for testing only
;-
;

pro mvn_sta_l3_checks

@'qualcolors'

mvn_sta_l3_load

options, 'mvn_sta_l3_temperature_mvn_alt_iau', color=qualcolors.blue
options, 'mvn_sta_l3_temperature_mvn_sza', color=qualcolors.blue

store_data, 'alt_compare', data=['mvn_sta_l3_density_mvn_alt_iau', 'mvn_sta_l3_temperature_mvn_alt_iau']
store_data, 'sza_compare', data=['mvn_sta_l3_density_mvn_sza', 'mvn_sta_l3_temperature_mvn_sza']

tvars1 = ['mvn_sta_l3_density', 'mvn_sta_l3_temperature_o2+', 'alt_compare', 'sza_compare']

tplot, tvars1


end



