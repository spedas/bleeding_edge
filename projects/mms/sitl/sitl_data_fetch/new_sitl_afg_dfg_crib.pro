; load some MMS sitl data to stackplot magnetometers
; 

mms_init;, local_data_dir='/Volumes/MMS/data/mms/'

Re = 6378.137

timespan, '2015-08-28/10:00:00', 8, /hour

mms_sitl_get_afg, sc_id=['mms1','mms2','mms3','mms4']

mms_sitl_get_dfg, sc_id=['mms1','mms2','mms3','mms4']

stop

device, decomp = 0
loadct, 39

options, 'mms1_afg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
options, 'mms1_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']

options, 'mms2_afg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
options, 'mms2_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']

options, 'mms3_afg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
options, 'mms3_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']

options, 'mms4_afg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
options, 'mms4_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']

options, 'mms2_afg_srvy_gsm_dmpa', 'ytitle', 'AFG2 B, nT'
options, 'mms3_afg_srvy_gsm_dmpa', 'ytitle', 'AFG3 B, nT'
options, 'mms4_afg_srvy_gsm_dmpa', 'ytitle', 'AFG4 B, nT'

options, 'mms2_dfg_srvy_gsm_dmpa', 'ytitle', 'DFG2 B, nT'
options, 'mms3_dfg_srvy_gsm_dmpa', 'ytitle', 'DFG3 B, nT'
options, 'mms4_dfg_srvy_gsm_dmpa', 'ytitle', 'DFG4 B, nT'

get_data, 'mms2_ql_pos_gsm', data = mms2_ephem

;store_data, 'mms2_ql_pos_gsm_Re', data = {x: mms2_ephem.x, y: mms2_ephem.y/Re}
;options, 'mms2_ql_pos_gsm_Re', labels=['MMS2 X','MMS2 Y','MMS2 Z','MMS2 R']

ephem_times = mms2_ephem.x
mms2_x = mms2_ephem.y(*,0)/Re
mms2_y = mms2_ephem.y(*,1)/Re
mms2_z = mms2_ephem.y(*,2)/Re
mms2_r = sqrt(mms2_x^2 + mms2_y^2 + mms2_z^2)

store_data, 'mms2_x', data = {x:ephem_times, y:mms2_x}
options, 'mms2_x', 'ytitle', 'MMS2 X'
store_data, 'mms2_y', data = {x:ephem_times, y:mms2_y}
options, 'mms2_y', 'ytitle', 'MMS2 Y'
store_data, 'mms2_z', data = {x:ephem_times, y:mms2_z}
options, 'mms2_z', 'ytitle', 'MMS2 Z'
store_data, 'mms2_r', data = {x:ephem_times, y:mms2_r}
options, 'mms2_r', 'ytitle', 'R'

tplot, ['mms1_afg_srvy_gsm_dmpa','mms2_afg_srvy_gsm_dmpa', 'mms3_afg_srvy_gsm_dmpa', 'mms4_afg_srvy_gsm_dmpa'], var_label=['mms2_r','mms2_z','mms2_y','mms2_x']


;window, /free
;tplot, ['mms2_dfg_srvy_gsm_dmpa', 'mms3_dfg_srvy_gsm_dmpa', 'mms4_dfg_srvy_gsm_dmpa']


end