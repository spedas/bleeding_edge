

mms_init, local_data_dir='/Users/jburch/data/mms/'
;mms_init;, local_data_dir='/Volumes/MMS/data/mms/'


Re = 6378.137


;timespan, '2015-05-11/00:00:00', 24, /hour

timespan, '2015-07-30/13:41:03', 24, /hour
;timespan, '2015-06-22/16:00:00', 6, /hour

sc_id='mms2'

level = 'sitl'
;level = 'l1b'

mms_sitl_get_hpca_basic, sc_id=sc_id, level = level 

;mms_sitl_get_hpca_moments, sc_id=sc_id, level = level

;mms_sitl_get_dfg, sc_id=sc_id;['mms1','mms2','mms3','mms4']

;get_data, 'mms1_ql_pos_gsm', data = mms1_ephem
;get_data, 'mms2_ql_pos_gsm', data = mms2_ephem
;get_data, 'mms3_ql_pos_gsm', data = mms3_ephem
;get_data, 'mms4_ql_pos_gsm', data = mms4_ephem


;ephem_times = mms1_ephem.x
;mms1_x = mms1_ephem.y(*,0)/Re
;mms1_y = mms1_ephem.y(*,1)/Re
;mms1_z = mms1_ephem.y(*,2)/Re
;mms1_r = sqrt(mms1_x^2 + mms1_y^2 + mms1_z^2)

;ephem_times = mms2_ephem.x
;mms2_x = mms2_ephem.y(*,0)/Re
;mms2_y = mms2_ephem.y(*,1)/Re
;mms2_z = mms2_ephem.y(*,2)/Re
;mms2_r = sqrt(mms2_x^2 + mms2_y^2 + mms2_z^2)

;ephem_times = mms3_ephem.x
;mms3_x = mms3_ephem.y(*,0)/Re
;mms3_y = mms3_ephem.y(*,1)/Re
;mms3_z = mms3_ephem.y(*,2)/Re
;mms3_r = sqrt(mms3_x^2 + mms3_y^2 + mms3_z^2)

;ephem_times = mms4_ephem.x
;mms4_x = mms4_ephem.y(*,0)/Re
;mms4_y = mms4_ephem.y(*,1)/Re
;mms4_z = mms4_ephem.y(*,2)/Re
;mms4_r = sqrt(mms4_x^2 + mms4_y^2 + mms4_z^2)

;store_data, 'mms1_x', data = {x:ephem_times, y:mms1_x}
;options, 'mms1_x', 'ytitle', 'MMS1 X'
;store_data, 'mms1_y', data = {x:ephem_times, y:mms1_y}
;options, 'mms1_y', 'ytitle', 'MMS1 Y'
;store_data, 'mms1_z', data = {x:ephem_times, y:mms1_z}
;options, 'mms1_z', 'ytitle', 'MMS1 Z'
;store_data, 'mms1_r', data = {x:ephem_times, y:mms1_r}
;options, 'mms1_r', 'ytitle', 'R'

;store_data, 'mms2_x', data = {x:ephem_times, y:mms2_x}
;options, 'mms2_x', 'ytitle', 'MMS2 X'
;store_data, 'mms2_y', data = {x:ephem_times, y:mms2_y}
;options, 'mms2_y', 'ytitle', 'MMS2 Y'
;store_data, 'mms2_z', data = {x:ephem_times, y:mms2_z}
;options, 'mms2_z', 'ytitle', 'MMS2 Z'
;store_data, 'mms2_r', data = {x:ephem_times, y:mms2_r}
;options, 'mms2_r', 'ytitle', 'R'

;store_data, 'mms3_x', data = {x:ephem_times, y:mms3_x}
;options, 'mms3_x', 'ytitle', 'MMS3 X'
;store_data, 'mms3_y', data = {x:ephem_times, y:mms3_y}
;options, 'mms3_y', 'ytitle', 'MMS3 Y'
;store_data, 'mms3_z', data = {x:ephem_times, y:mms3_z}
;options, 'mms3_z', 'ytitle', 'MMS3 Z'
;store_data, 'mms3_r', data = {x:ephem_times, y:mms3_r}
;options, 'mms3_r', 'ytitle', 'R'

;store_data, 'mms4_x', data = {x:ephem_times, y:mms4_x}
;options, 'mms4_x', 'ytitle', 'MMS4 X'
;store_data, 'mms4_y', data = {x:ephem_times, y:mms1_y}
;options, 'mms4_y', 'ytitle', 'MMS4 Y'
;store_data, 'mms4_z', data = {x:ephem_times, y:mms1_z}
;options, 'mms4_z', 'ytitle', 'MMS4 Z'
;store_data, 'mms4_r', data = {x:ephem_times, y:mms1_r}
;options, 'mms4_r', 'ytitle', 'R'




;print,'Stop1' & stop  

;=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%
;      H+
;    flux
options, sc_id+'_hpca_hplus_RF_corrected','spec',1 
options, sc_id+'_hpca_hplus_RF_corrected','ylog',1
options, sc_id+'_hpca_hplus_RF_corrected','zlog',1
options, sc_id+'_hpca_hplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_hplus_RF_corrected','ytitle','H!U+!N(eV)'
options, sc_id+'_hpca_hplus_RF_corrected','ztitle',' '
ylim,    sc_id+'_hpca_hplus_RF_corrected', 1, 40000.
;zlim,    sc_id+'_hpca_hplus_RF_corrected', .1, 1000.

;    data quality
;ylim, 'mms1_hpca_hplus_data_quality',0, 255.
;options, 'mms1_hpca_hplus_data_quality','ytitle','Data Quality'

options,sc_id+'_hpca_heplusplus_RF_corrected','spec',1 
options, sc_id+'_hpca_heplusplus_RF_corrected','ylog',1
options, sc_id+'_hpca_heplusplus_RF_corrected','zlog',1
options, sc_id+'_hpca_heplusplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_heplusplus_RF_corrected','ytitle','He!U++!N(eV)'
options, sc_id+'_hpca_heplusplus_RF_corrected','ztitle','normalized energy flux'
ylim,    sc_id+'_hpca_heplusplus_RF_corrected', 1, 40000.
;zlim,    sc_id+'_hpca_heplusplus_RF_corrected', .1, 1000.


options,sc_id+'_hpca_oplus_RF_corrected','spec',1 
options, sc_id+'_hpca_oplus_RF_corrected','ylog',1
options, sc_id+'_hpca_oplus_RF_corrected','zlog',1
options, sc_id+'_hpca_oplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_oplus_RF_corrected','ytitle','O!U+!N(eV)'
options, sc_id+'_hpca_oplus_RF_corrected','ztitle',' '
ylim,    sc_id+'_hpca_oplus_RF_corrected', 1, 40000.
;zlim,    sc_id+'_hpca_oplus_RF_corrected', .1, 1000.

ylim, sc_id+'_hpca_hplusoplus_number_densities', 1, 50
options, sc_id+'_hpca_hplusoplus_number_densities', 'ylog', 1
options, sc_id+'_hpca_hplusoplus_number_densities', colors = [2,4]
options, sc_id+'_hpca_hplusoplus_number_densities', 'ytitle', 'cm!U-3!N'
options, sc_id+'_hpca_hplusoplus_number_densities', labels=['h!U+!N', 'o!U+!N']
options, sc_id+'_hpca_hplusoplus_number_densities','labflag',-1

ylim, sc_id+'_hpca_hplus_bulk_velocity', -100, 100
options, sc_id+'_hpca_hplus_bulk_velocity', 'ylog', 0
options, sc_id+'_hpca_hplus_bulk_velocity', colors = [2,4,6]
options, sc_id+'_hpca_hplus_bulk_velocity', 'ytitle', 'h!U+!N km s!U-1!N'
options, sc_id+'_hpca_hplus_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, sc_id+'_hpca_hplus_bulk_velocity','labflag',-1

ylim, sc_id+'_hpca_oplus_bulk_velocity', -100, 100
options, sc_id+'_hpca_oplus_bulk_velocity', 'ylog', 0
options, sc_id+'_hpca_oplus_bulk_velocity', colors = [2,4,6]
options, sc_id+'_hpca_oplus_bulk_velocity', 'ytitle', 'o!U+!N km s!U-1!N'
options, sc_id+'_hpca_oplus_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, sc_id+'_hpca_oplus_bulk_velocity','labflag',-1

ylim, sc_id+'_hpca_hplusoplus_scalar_temperatures', 1000, 10000
options, sc_id+'_hpca_hplusoplus_scalar_temperatures', 'ylog', 1
options, sc_id+'_hpca_hplusoplus_scalar_temperatures', colors = [2,4]
options, sc_id+'_hpca_hplusoplus_scalar_temperatures', 'ytitle', 'eV'
options, sc_id+'_hpca_hplusoplus_scalar_temperatures', labels=['h!U+!N', 'o!U+!N']
options, sc_id+'_hpca_hplusoplus_scalar_temperatures','labflag',-1


;options, sc_id+'_dfg_srvy_gsm_dmpa', -80, 80
;options, sc_id+'_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
;options, sc_id+'_dfg_srvy_gsm_dmpa', 'labflag',-1


tplot, [sc_id+'_hpca_hplus_RF_corrected', sc_id+'_hpca_heplusplus_RF_corrected',$
  sc_id+'_hpca_oplus_RF_corrected', sc_id+'_hpca_hplusoplus_number_densities', $
  sc_id+'_hpca_hplus_bulk_velocity', sc_id+'_hpca_oplus_bulk_velocity', $
  sc_id+'_hpca_hplusoplus_scalar_temperatures'];, $
    ;var_label=[sc_id+'_r',sc_id+'_z',sc_id+'_y',sc_id+'_x']



end

