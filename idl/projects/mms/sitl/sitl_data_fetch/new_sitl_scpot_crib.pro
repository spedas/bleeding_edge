; load some MMS sitl data to stackplot magnetometers
; 

mms_init;, local_data_dir='/Volumes/MMS/data/mms/'

Re = 6378.137

timespan, '2015-08-28/10:00:00', 8, /hour

;mms_sitl_get_afg, sc_id=['mms1','mms2','mms3','mms4']
;
;mms_sitl_get_dfg, sc_id=['mms1','mms2','mms3','mms4']

mms_sitl_get_edp, sc_id = ['mms4'], data_rate = 'fast', level='l2', datatype='scpot'

mms_sitl_get_fpi_basic, sc_id = 'mms4'

tplot, ['mms4_edp_fast_scpot','mms4_fpi_DISnumberDensity']


end