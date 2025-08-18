; created by Jim Burch, July, 2015.
; to run it, in IDL session, type: .r crib_master

i_read=1



timespan,'2015-06-22/00:00', 24, /hour



if i_read eq 1 then begin

mms_sitl_get_fpi_basic, sc_id='mms2'

mms_sitl_get_hpca_basic, sc_id='mms1'

mms_sitl_get_hpca_moments, sc_id='mms1'

mms_sitl_get_dfg, sc_id='mms1'

mms_load_epd_feeps,sc='mms3'

endif; i_read

Re = 6378.137

;*********************************************************
; Orbits
;*********************************************************

get_data, 'mms1_ql_pos_gsm', data = mms1_ephem

ephem_times = mms1_ephem.x
mms1_x = mms1_ephem.y(*,0)/Re
mms1_y = mms1_ephem.y(*,1)/Re
mms1_z = mms1_ephem.y(*,2)/Re
mms1_r = sqrt(mms1_x^2 + mms1_y^2 + mms1_z^2)

store_data, 'mms1_x', data = {x:ephem_times, y:mms1_x}
options, 'mms1_x', 'ytitle', 'MMS1 X'
store_data, 'mms1_y', data = {x:ephem_times, y:mms1_y}
options, 'mms1_y', 'ytitle', 'MMS1 Y'
store_data, 'mms1_z', data = {x:ephem_times, y:mms1_z}
options, 'mms1_z', 'ytitle', 'MMS1 Z'
store_data, 'mms1_r', data = {x:ephem_times, y:mms1_r}
options, 'mms1_r', 'ytitle', 'R'

;*********************************************************
; FPI
;*********************************************************

  options, 'mms1_fpi_iEnergySpectr_omni', 'spec', 1
  options, 'mms1_fpi_iEnergySpectr_omni', 'ylog', 1
  options, 'mms1_fpi_iEnergySpectr_omni', 'zlog', 1
  options, 'mms1_fpi_iEnergySpectr_omni', 'no_interp', 1
  options, 'mms1_fpi_iEnergySpectr_omni', 'ytitle', 'ion E, eV'
  ylim, 'mms1_fpi_iEnergySpectr_omni', 10, 26000
  zlim, 'mms1_fpi_iEnergySpectr_omni', .1, 2000

  options, 'mms1_fpi_eEnergySpectr_omni', 'spec', 1
  options, 'mms1_fpi_eEnergySpectr_omni', 'ylog', 1
  options, 'mms1_fpi_eEnergySpectr_omni', 'zlog', 1
  options, 'mms1_fpi_eEnergySpectr_omni', 'no_interp', 1
  options, 'mms1_fpi_eEnergySpectr_omni', 'ytitle', 'Electron E, eV'
  ylim, 'mms1_fpi_eEnergySpectr_omni', 10, 26000
 zlim, 'mms1_fpi_eEnergySpectr_omni', .1, 2000

;*********************************************************
; HPCA
;*********************************************************

;=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%=%
;      H+
;    flux
options,'mms1_hpca_hplus_RF_corrected','spec',1 
options, 'mms1_hpca_hplus_RF_corrected','ylog',1
options, 'mms1_hpca_hplus_RF_corrected','zlog',1
options, 'mms1_hpca_hplus_RF_corrected','no_interp',1
options, 'mms1_hpca_hplus_RF_corrected','ytitle','H+ (eV)'
options, 'mms1_hpca_hplus_RF_corrected','ztitle','counts'
ylim,    'mms1_hpca_hplus_RF_corrected', 1, 40000.
zlim,    'mms1_hpca_hplus_RF_corrected', .1, 2000.

options,'mms1_hpca_heplusplus_RF_corrected','spec',1 
options, 'mms1_hpca_heplusplus_RF_corrected','ylog',1
options, 'mms1_hpca_heplusplus_RF_corrected','zlog',1
options, 'mms1_hpca_heplusplus_RF_corrected','no_interp',1
options, 'mms1_hpca_heplusplus_RF_corrected','ytitle','He++ (eV)'
options, 'mms1_hpca_heplusplus_RF_corrected','ztitle','counts'
ylim,    'mms1_hpca_heplusplus_RF_corrected', 1, 40000.
zlim,    'mms1_hpca_heplusplus_RF_corrected', .1, 2000.

options,'mms1_hpca_oplus_RF_corrected','spec',1 
options, 'mms1_hpca_oplus_RF_corrected','ylog',1
options, 'mms1_hpca_oplus_RF_corrected','zlog',1
options, 'mms1_hpca_oplus_RF_corrected','no_interp',1
options, 'mms1_hpca_oplus_RF_corrected','ytitle','O+ (eV)'
options, 'mms1_hpca_oplus_RF_corrected','ztitle','counts'
ylim,    'mms1_hpca_oplus_RF_corrected', 1, 40000.
zlim,    'mms1_hpca_oplus_RF_corrected', .1, 2000.

;*********************************************************
; FGM
;*********************************************************

; limit fgm to +-200 nT
get_data,'mms1_dfg_srvy_gsm_dmpa',data=d
index=where(d.y gt 200 or d.y lt -200)
if (index(0) ne -1) then d.y(index)=float('NaN')
store_data,'mms1_dfg_srvy_gsm_dmpa_limited',data=d


tplot,['mms1_dfg_srvy_gsm_dmpa_limited','mms1_fpi_iEnergySpectr_omni','mms1_fpi_eEnergySpectr_omni','mms1_fpi_DISnumberDensity', 'mms1_fpi_iBulkV_DSC','mms1_hpca_hplus_RF_corrected','mms1_hpca_heplusplus_RF_corrected','mms1_hpca_oplus_RF_corrected', 'mms1_hpca_hplusoplus_number_densities','mms1_hpca_hplus_bulk_velocity','mms1_hpca_oplus_bulk_velocity','mms3_epd_feeps_BOTTOM_quality_sensorID_12'],var_label=['mms1_z','mms1_y','mms1_x']


end

