; Script to load MMS data from various instruments and plot a subset of parameters. Specfiy plot formats etc...

; created by Jim Burch, July, 2015.
; updated by Tai Phan: August 5, 2015

; to run this script, in IDL session, type: .r crib_master_v2 (or click the run button)


; To change the font size of plot labels, use "!p.charsize= 1 or 0.5 or ...". 1 is the default. 

i_load=1 ; =1 if data has not been loaded, =0 of data has already been loaded (no need to load again in this IDL session)

; To create a poscript file of the plot, select i_print=1 below

i_print=1 ; = 1 to generate a postscript file of plot (default name is 'plot.ps')

; to zoom in and out, use tlimit (various options in tlimit: 'tlimit,/last', 'tlimit,/full', 'tlimit,time1, time2')

timespan,'2015-07-31/00:00', 24, /hour ; (other often-used options are /day or /min)

;timespan,'2015-06-22/00:00', 24, /hour ; (other often-used options are /day or /min)

sc_id='mms1' ; specify spacecraft

level = 'sitl' ; (current options are 'sitl' or 'l1b' for HPCA, more to come...)

;level = 'l1b' ; (current options are 'sitl' or 'l1b' for HPCA, more to come...)

; To change the font size of plot labels, use "!p.charsize= 1 or 0.5 or ...". 1 is the default. 
!p.charsize=1

if i_load eq 1 then begin

; loading FPI, HPCA, DFG, and FEEPS data

mms_sitl_get_fpi_basic, sc_id=sc_id

mms_sitl_get_hpca_basic, sc_id=sc_id  , level = level

mms_sitl_get_hpca_moments, sc_id=sc_id , level = level

mms_sitl_get_dfg, sc_id=sc_id

mms_load_epd_feeps,sc=sc_id

endif; i_load



;*********************************************************
; Orbits
;*********************************************************

get_data, sc_id+'_ql_pos_gsm', data = mms_ephem

ephem_times = mms_ephem.x

Re = 6378.137
mms_x = mms_ephem.y(*,0)/Re
mms_y = mms_ephem.y(*,1)/Re
mms_z = mms_ephem.y(*,2)/Re
mms_r = sqrt(mms_x^2 + mms_y^2 + mms_z^2)

store_data, sc_id+'_x', data = {x:ephem_times, y:mms_x}
options, sc_id+'_x', 'ytitle', sc_id+' X'
store_data, sc_id+'_y', data = {x:ephem_times, y:mms_y}
options, sc_id+'_y', 'ytitle', sc_id+' Y'
store_data, sc_id+'_z', data = {x:ephem_times, y:mms_z}
options, sc_id+'_z', 'ytitle', sc_id+' Z'
store_data, sc_id+'_r', data = {x:ephem_times, y:mms_r}
options, sc_id+'_r', 'ytitle', sc_id+' R'


;*********************************************************
; FPI: define plot formats, limits, and labels, etc...
;*********************************************************

  options, sc_id+'_fpi_iEnergySpectr_omni', 'spec', 1 ; 1= spectrogram, 0= line plot
  options, sc_id+'_fpi_iEnergySpectr_omni', 'no_interp', 1
  options, sc_id+'_fpi_iEnergySpectr_omni', 'ytitle', 'ion E, eV' ; define y label. tplot name used if not defined.

; define y axis limits (optional)
  ylim, sc_id+'_fpi_iEnergySpectr_omni', 10, 26000,1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear y axis
; define color range limits (optional)
  zlim, sc_id+'_fpi_iEnergySpectr_omni', .1, 2000, 1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear

  options, sc_id+'_fpi_eEnergySpectr_omni', 'spec', 1
  options, sc_id+'_fpi_eEnergySpectr_omni', 'no_interp', 1
  options, sc_id+'_fpi_eEnergySpectr_omni', 'ytitle', 'Electron E, eV'
  ylim, sc_id+'_fpi_eEnergySpectr_omni', 10, 26000, 1 ; the 3rd number specifies log (1) or linear (0) scale
  zlim, sc_id+'_fpi_eEnergySpectr_omni', .1, 2000, 1 ; the 3rd number specifies log (1) or linear (0) scale

;*********************************************************
; HPCA
;*********************************************************

options, sc_id+'_hpca_hplus_RF_corrected','spec',1 
options, sc_id+'_hpca_hplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_hplus_RF_corrected','ytitle','H!U+!N(eV)'
options, sc_id+'_hpca_hplus_RF_corrected','ztitle',' '
ylim,    sc_id+'_hpca_hplus_RF_corrected', 1, 40000.,1 ; the 3rd number specifies log (1) or linear (0) scale
zlim,    sc_id+'_hpca_hplus_RF_corrected', .1, 1000.,1 ; the 3rd number specifies log (1) or linear (0) scale

;    data quality
;ylim,  sc_id+'_hpca_hplus_data_quality',0, 255.
;options,  sc_id+'_hpca_hplus_data_quality','ytitle','Data Quality'

options,sc_id+'_hpca_heplusplus_RF_corrected','spec',1 
options, sc_id+'_hpca_heplusplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_heplusplus_RF_corrected','ytitle','He!U++!N(eV)'
options, sc_id+'_hpca_heplusplus_RF_corrected','ztitle','normalized energy flux'
ylim,    sc_id+'_hpca_heplusplus_RF_corrected', 1, 40000.,1
zlim,    sc_id+'_hpca_heplusplus_RF_corrected', .1, 1000.,1

options,sc_id+'_hpca_oplus_RF_corrected','spec',1 
options, sc_id+'_hpca_oplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_oplus_RF_corrected','ytitle','O!U+!N(eV)'
options, sc_id+'_hpca_oplus_RF_corrected','ztitle',' '
ylim,    sc_id+'_hpca_oplus_RF_corrected', 1, 40000.,1
zlim,    sc_id+'_hpca_oplus_RF_corrected', .1, 1000.,1

ylim, sc_id+'_hpca_hplusoplus_number_densities', 1, 50, 1
options, sc_id+'_hpca_hplusoplus_number_densities', colors = [2,4]
options, sc_id+'_hpca_hplusoplus_number_densities', 'ytitle', 'cm!U-3!N'
options, sc_id+'_hpca_hplusoplus_number_densities', labels=['h!U+!N', 'o!U+!N']
options, sc_id+'_hpca_hplusoplus_number_densities','labflag',-1

ylim, sc_id+'_hpca_hplus_bulk_velocity', -100, 100,0
options, sc_id+'_hpca_hplus_bulk_velocity', colors = [6,4,2]
options, sc_id+'_hpca_hplus_bulk_velocity', 'ytitle', 'h!U+!N km s!U-1!N'
options, sc_id+'_hpca_hplus_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, sc_id+'_hpca_hplus_bulk_velocity','labflag',-1

ylim, sc_id+'_hpca_oplus_bulk_velocity', -100, 100, 0
options, sc_id+'_hpca_oplus_bulk_velocity', colors = [6,4,2]
options, sc_id+'_hpca_oplus_bulk_velocity', 'ytitle', 'o!U+!N km s!U-1!N'
options, sc_id+'_hpca_oplus_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, sc_id+'_hpca_oplus_bulk_velocity','labflag',-1

ylim, sc_id+'_hpca_hplusoplus_scalar_temperatures', 1000, 10000, 1
options, sc_id+'_hpca_hplusoplus_scalar_temperatures', colors = [2,4]
options, sc_id+'_hpca_hplusoplus_scalar_temperatures', 'ytitle', 'eV'
options, sc_id+'_hpca_hplusoplus_scalar_temperatures', labels=['h!U+!N', 'o!U+!N']
options, sc_id+'_hpca_hplusoplus_scalar_temperatures','labflag',-1

;*********************************************************
; FGM
;*********************************************************

; limit fgm to +-200 nT
get_data,sc_id+'_dfg_srvy_gsm_dmpa',data=d
index=where(d.y gt 200 or d.y lt -200)
if (index(0) ne -1) then d.y(index)=float('NaN')
store_data,sc_id+'_dfg_srvy_gsm_dmpa_limited',data=d

options, sc_id+'_dfg_srvy_gsm_dmpa_limited', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
options, sc_id+'_dfg_srvy_gsm_dmpa_limited', 'labflag',-1

;*********************************************************
; group tplot variables for plotting (grouping not required but better aesthetically)
;*********************************************************

name_hpca=[sc_id+'_hpca_hplus_RF_corrected', sc_id+'_hpca_heplusplus_RF_corrected',$
  sc_id+'_hpca_oplus_RF_corrected', sc_id+'_hpca_hplusoplus_number_densities', $
  sc_id+'_hpca_hplus_bulk_velocity', sc_id+'_hpca_oplus_bulk_velocity', $
  sc_id+'_hpca_hplusoplus_scalar_temperatures']

name_dfg=[sc_id+'_dfg_srvy_gsm_dmpa_limited']

name_fpi=[sc_id+'_fpi_iEnergySpectr_omni',sc_id+'_fpi_eEnergySpectr_omni',sc_id+'_fpi_DISnumberDensity', sc_id+'_fpi_iBulkV_DSC']

name_feeps=[sc_id+'_epd_feeps_BOTTOM_quality_sensorID_12']

tplot_options,'ygap',0.3 ; set vertical gap size between panels (the default gap is often too large with multi panels)

;plotting

tplot,[name_dfg,name_fpi,name_hpca,name_feeps],var_label=[sc_id+'_z',sc_id+'_y',sc_id+'_x']

;create postscript file
if i_print eq 1 then begin
!p.charsize=0.6
popen,land=1 ; a plot.ps file will be created (popen,land=1,filename='filename' creates filename.ps)
tplot
pclose
!p.charsize=1; resetting the font size to default
tplot ; back to screen mode
endif


stop

end

