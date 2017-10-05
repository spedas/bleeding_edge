; example for fetching edp sitl data
; 
; Note - we haven't added checks for whether or not data is despun yet, so use at your own risk. These checks are coming soon.


mms_init

timespan, '2016-03-15/00:00:00', 24, /hour

;timespan, '2015-05-07/00:00:00', 12, /hour

sc_id = ['mms3']

mms_sitl_get_edp, sc_id = sc_id, level = 'sitl'

;mms_data_fetch, flist, lflag, dlflag, sc_id='mms3', level='l1b', optional_descriptor='dcecomm', mode='comm', instrument_id='edp'

options, sc_id + '_edp_fast_dce_sitl', 'ytitle', 'E, mV/m'
options, sc_id + '_edp_fast_dce_sitl', labels=['X','Y','Z']
options, sc_id + '_edp_fast_dce_sitl', 'labflag', -1
ylim, sc_id + '_edp_fast_dce_sitl', -20, 20
tplot, sc_id + '_edp_fast_dce_sitl'

end