; Script to load MMS data from various instruments and plot a subset of parameters. Specfiy plot formats etc...

; created by Jim Burch, July, 2015.
; updated by Tai Phan: August 31, 2015
; updated by Eric Grimes: January 4, 2016

; to run this script, in IDL session, type: .r crib_master_v3 (or click the run button)


; To change the font size of plot labels, use "!p.charsize= 1 or 0.5 or ...". 1 is the default. 

i_load=1 ; =1 if data has not been loaded, =0 of data has already been loaded (no need to load again in this IDL session)

; To create a poscript file of the plot, select i_print=1 below

i_print=1 ; = 1 to generate a postscript file of plot (default name is 'plot.ps')

; to zoom in and out, use tlimit (various options in tlimit: 'tlimit,/last', 'tlimit,/full', 'tlimit,time1, time2')

timespan,'2015-11-15/11:45', 4.2, /hour ; (other often-used options are /day or /min)

;timespan,'2015-08-28/11:00', 8.2, /hour ; (other often-used options are /day or /min)


sc_id='mms4' ; specify spacecraft

probe_id=strmid(sc_id,3,1) ; extract the spacecrfat number out of the sc_id string


level = 'sitl' ; (current options are 'sitl' or 'l1b' for HPCA, more to come...)

;level = 'l1b' ; (current options are 'sitl' or 'l1b' for HPCA, more to come...)

; To change the font size of plot labels, use "!p.charsize= 1 or 0.5 or ...". 1 is the default. 
!p.charsize=1

if i_load eq 1 then begin

; loading FPI, HPCA, DFG, and FEEPS data

mms_load_fpi, probes=probe_id,level=level,data_rate='fast'
;mms_sitl_get_fpi_basic, sc_id=sc_id

; Load E

mms_load_edp, probes = probe_id, level='ql', data_rate='fast', datatype='dce'

; NOW DSP...
; Efield
mms_load_data, instrument='dsp',probes=probe_id, datatype='epsd', level='l2', data_rate='fast'
; now download the SCM spectral density
mms_load_data, instrument='dsp',probes=probe_id, datatype='bpsd', level='l2', data_rate='fast'

; now EPD
;mms_load_eis, probes=probe_id, datatype='extof'
;mms_load_eis, probes=probe_id, datatype='phxtof'

;DFG
mms_sitl_get_dfg, sc_id=sc_id

;HPCA
mms_load_hpca, probes=probe_id, datatype='rf_corr', level=level, data_rate='srvy'
; calculate the spectra for the full field of view
mms_hpca_calc_anodes, fov=[0, 360], probe=probe_id
mms_load_hpca, probes=probe_id, datatype='moments', data_rate='srvy', level=level


;mms_load_epd_feeps,sc=sc_id

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

;create omni spectra


if sc_id eq 'mms1' then begin

calc, ' "mms1_fpi_iEnergySpectr_omni" = ("mms1_fpi_iEnergySpectr_mX" + "mms1_fpi_iEnergySpectr_mY" + "mms1_fpi_iEnergySpectr_mZ"+"mms1_fpi_iEnergySpectr_pX" + "mms1_fpi_iEnergySpectr_pY" + "mms1_fpi_iEnergySpectr_pZ")/6. '

calc, ' "mms1_fpi_eEnergySpectr_omni" = ("mms1_fpi_eEnergySpectr_mX" + "mms1_fpi_eEnergySpectr_mY" + "mms1_fpi_eEnergySpectr_mZ"+"mms1_fpi_eEnergySpectr_pX" + "mms1_fpi_eEnergySpectr_pY" + "mms1_fpi_eEnergySpectr_pZ")/6. '

endif

if sc_id eq 'mms2' then begin

calc, ' "mms2_fpi_iEnergySpectr_omni" = ("mms2_fpi_iEnergySpectr_mX" + "mms2_fpi_iEnergySpectr_mY" + "mms2_fpi_iEnergySpectr_mZ"+"mms2_fpi_iEnergySpectr_pX" + "mms2_fpi_iEnergySpectr_pY" + "mms2_fpi_iEnergySpectr_pZ")/6. '

calc, ' "mms2_fpi_eEnergySpectr_omni" = ("mms2_fpi_eEnergySpectr_mX" + "mms2_fpi_eEnergySpectr_mY" + "mms2_fpi_eEnergySpectr_mZ"+"mms2_fpi_eEnergySpectr_pX" + "mms2_fpi_eEnergySpectr_pY" + "mms1_fpi_eEnergySpectr_pZ")/6. '

endif

if sc_id eq 'mms3' then begin

calc, ' "mms3_fpi_iEnergySpectr_omni" = ("mms3_fpi_iEnergySpectr_mX" + "mms3_fpi_iEnergySpectr_mY" + "mms3_fpi_iEnergySpectr_mZ"+"mms3_fpi_iEnergySpectr_pX" + "mms3_fpi_iEnergySpectr_pY" + "mms3_fpi_iEnergySpectr_pZ")/6. '

calc, ' "mms3_fpi_eEnergySpectr_omni" = ("mms3_fpi_eEnergySpectr_mX" + "mms3_fpi_eEnergySpectr_mY" + "mms3_fpi_eEnergySpectr_mZ"+"mms3_fpi_eEnergySpectr_pX" + "mms3_fpi_eEnergySpectr_pY" + "mms3_fpi_eEnergySpectr_pZ")/6. '

endif

if sc_id eq 'mms4' then begin

calc, ' "mms4_fpi_iEnergySpectr_omni" = ("mms4_fpi_iEnergySpectr_mX" + "mms4_fpi_iEnergySpectr_mY" + "mms4_fpi_iEnergySpectr_mZ"+"mms4_fpi_iEnergySpectr_pX" + "mms4_fpi_iEnergySpectr_pY" + "mms4_fpi_iEnergySpectr_pZ")/6. '

calc, ' "mms4_fpi_eEnergySpectr_omni" = ("mms4_fpi_eEnergySpectr_mX" + "mms4_fpi_eEnergySpectr_mY" + "mms4_fpi_eEnergySpectr_mZ"+"mms4_fpi_eEnergySpectr_pX" + "mms4_fpi_eEnergySpectr_pY" + "mms4_fpi_eEnergySpectr_pZ")/6. '

endif


  options, sc_id+'_fpi_iEnergySpectr_omni', 'spec', 1 ; 1= spectrogram, 0= line plot
  options, sc_id+'_fpi_iEnergySpectr_omni', 'no_interp', 1
  options, sc_id+'_fpi_iEnergySpectr_omni', 'ytitle', 'ion E, eV' ; define y label. tplot name used if not defined.

; define y axis limits (optional)
  ylim, sc_id+'_fpi_iEnergySpectr_omni', 10, 26000,1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear y axis
; define color range limits (optional)
  zlim, sc_id+'_fpi_iEnergySpectr_omni', 0, 0, 1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear
;  zlim, sc_id+'_fpi_iEnergySpectr_omni', .1, 2000, 1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear
  options, sc_id+'_fpi_eEnergySpectr_omni', 'spec', 1
  options, sc_id+'_fpi_eEnergySpectr_omni', 'no_interp', 1
  options, sc_id+'_fpi_eEnergySpectr_omni', 'ytitle', 'Electron E, eV'
  ylim, sc_id+'_fpi_eEnergySpectr_omni', 10, 26000, 1 ; the 3rd number specifies log (1) or linear (0) scale
  zlim, sc_id+'_fpi_eEnergySpectr_omni', 0,0, 1 ; the 3rd number specifies log (1) or linear (0) scale
;  zlim, sc_id+'_fpi_eEnergySpectr_omni', .1, 2000, 1 ; the 3rd number specifies log (1) or linear (0) scale

; combine the bulk ion velocity into a single tplot variable
join_vec, [sc_id+'_fpi_iBulkV_X_DSC', sc_id+'_fpi_iBulkV_Y_DSC', $
           sc_id+'_fpi_iBulkV_Z_DSC'], sc_id+'_fpi_iBulkV_DSC'
; set some options for pretty plots
options, sc_id+'_fpi_iBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz']
options, sc_id+'_fpi_iBulkV_DSC', 'labflag', -1
options, sc_id+'_fpi_iBulkV_DSC', 'colors', [2, 4, 6]

; combine the perp and parallel temperatures into a single tplot variable
join_vec,  [sc_id+'_fpi_DEStempPara', $
        sc_id+'_fpi_DEStempPerp'], sc_id+'_fpi_DEStemp'

options, sc_id+'_fpi_DEStemp', 'labels', ['Te_par', 'Te_per']
options, sc_id+'_fpi_DEStemp', 'labflag', -1
options, sc_id+'_fpi_DEStemp', 'colors', [6,2]
ylim,sc_id+'_fpi_DEStemp',0,0,1

; combine the perp and parallel temperatures into a single tplot variable
join_vec,  [sc_id+'_fpi_DIStempPara', $
        sc_id+'_fpi_DIStempPerp'], sc_id+'_fpi_DIStemp'

options, sc_id+'_fpi_DIStemp', 'labels', ['Ti_par', 'Ti_per']
options, sc_id+'_fpi_DIStemp', 'labflag', -1
options, sc_id+'_fpi_DIStemp', 'colors', [6,2]
ylim,sc_id+'_fpi_DIStemp',0,0,1

;*********************************************************
; HPCA
;*********************************************************

;stop


options, sc_id+'_hpca_hplus_RF_corrected','spec',1 
options, sc_id+'_hpca_hplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_hplus_RF_corrected','ytitle','H!U+!N(eV)'
options, sc_id+'_hpca_hplus_RF_corrected','ztitle','counts'
ylim,    sc_id+'_hpca_hplus_RF_corrected', 1, 40000.,1 ; the 3rd number specifies log (1) or linear (0) scale
zlim,    sc_id+'_hpca_hplus_RF_corrected', .1, 1000.,1 ; the 3rd number specifies log (1) or linear (0) scale

;    data quality
;ylim,  sc_id+'_hpca_hplus_data_quality',0, 255.
;options,  sc_id+'_hpca_hplus_data_quality','ytitle','Data Quality'

options,sc_id+'_hpca_heplusplus_RF_corrected','spec',1 
options, sc_id+'_hpca_heplusplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_heplusplus_RF_corrected','ytitle','He!U++!N(eV)'
options, sc_id+'_hpca_heplusplus_RF_corrected','ztitle','counts'
ylim,    sc_id+'_hpca_heplusplus_RF_corrected', 1, 40000.,1
zlim,    sc_id+'_hpca_heplusplus_RF_corrected', .1, 1000.,1

options,sc_id+'_hpca_oplus_RF_corrected','spec',1 
options, sc_id+'_hpca_oplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_oplus_RF_corrected','ytitle','O!U+!N(eV)'
options, sc_id+'_hpca_oplus_RF_corrected','ztitle','counts'
ylim,    sc_id+'_hpca_oplus_RF_corrected', 1, 40000.,1
zlim,    sc_id+'_hpca_oplus_RF_corrected', .1, 1000.,1

ylim, sc_id+'_hpca_hplus_number_density', 0,0,0
options, sc_id+'_hpca_hplus_number_density'
options, sc_id+'_hpca_hplus_number_density', 'ytitle', 'cm!U-3!N'
options, sc_id+'_hpca_hplus_number_density', labels=['h!U+!N', 'o!U+!N']
options, sc_id+'_hpca_hplus_number_density','labflag',-1


ylim, sc_id+'_hpca_hplus_ion_bulk_velocity', 0, 0,0
options, sc_id+'_hpca_hplus_ion_bulk_velocity', colors = [2,4,6]
options, sc_id+'_hpca_hplus_ion_bulk_velocity', 'ytitle', 'H!U+!N km s!U-1!N'
options, sc_id+'_hpca_hplus_ion_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, sc_id+'_hpca_hplus_ion_bulk_velocity','labflag',-1

ylim, sc_id+'_hpca_oplus_ion_bulk_velocity', 0, 0, 0
options, sc_id+'_hpca_oplus_ion_bulk_velocity', colors = [2,4,6]
options, sc_id+'_hpca_oplus_ion_bulk_velocity', 'ytitle', 'O!U+!N km s!U-1!N'
options, sc_id+'_hpca_oplus_ion_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, sc_id+'_hpca_oplus_ion_bulk_velocity','labflag',-1

ylim, sc_id+'_hpca_hplus_scalar_temperature', 0,0, 1
options, sc_id+'_hpca_hplus_scalar_temperature', colors = [2,4]
options, sc_id+'_hpca_hplus_scalar_temperature', 'ytitle', 'T H!U+!N '
options, sc_id+'_hpca_hplus_scalar_temperature', labels=['h!U+!N', 'o!U+!N']
options, sc_id+'_hpca_hplus_scalar_temperature','labflag',-1



;*********************************************************
; FGM
;*********************************************************

; limit fgm to +-200 nT
get_data,sc_id+'_dfg_srvy_gsm_dmpa',data=d
store_data,sc_id+'_dfg_srvy_mag',data={x:d.x,y:sqrt(d.y(*,0)^2+d.y(*,1)^2+d.y(*,2)^2)}

options, sc_id+'_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
options, sc_id+'_dfg_srvy_gsm_dmpa', 'labflag',-1

;*********************************************************
; E field: EDP
;*********************************************************

options,sc_id+'_edp_fast_dce_dsl', $
            labels=['EX','EY','EZ'],ytitle=sc_id+'!CEDP!Cfast',ysubtitle='[mV/m]',$
            colors=[2,4,6],labflag=-1,yrange=[-20,20],constant=0

;*********************************************************
; DSP
;*********************************************************

ylim,sc_id+'_dsp_epsd_omni',3e1,1.3e5,1
zlim,sc_id+'_dsp_epsd_omni',1e-13,1e-11,1
ylim,sc_id+'_dsp_bpsd_omni',3e1,1.8e3,1
zlim,sc_id+'_dsp_bpsd_omni',1e-8,1e-4,1


;*********************************************************
; group tplot variables for plotting (grouping not required but better aesthetically)
;*********************************************************
name_hpca=[sc_id+'_hpca_hplus_RF_corrected_elev_0-360', sc_id+'_hpca_heplusplus_RF_corrected_elev_0-360',$
  sc_id+'_hpca_oplus_RF_corrected_elev_0-360', sc_id+'_hpca_hplus_number_density', $
  sc_id+'_hpca_hplus_ion_bulk_velocity', sc_id+'_hpca_oplus_ion_bulk_velocity', $
  sc_id+'_hpca_hplus_scalar_temperature']

name_edp= sc_id+'_edp_fast_dce_dsl'

name_dfg=[sc_id+'_dfg_srvy_mag',sc_id+'_dfg_srvy_gsm_dmpa']

name_fpi=[sc_id+'_fpi_iEnergySpectr_omni',sc_id+'_fpi_eEnergySpectr_omni',sc_id+'_fpi_DISnumberDensity', sc_id+'_fpi_iBulkV_DSC',sc_id+'_fpi_DIStemp',sc_id+'_fpi_DEStemp']

name_dsp = [sc_id+'_dsp_epsd_omni',sc_id+'_dsp_bpsd_omni']

;name_eis=[sc_id+'_epd_eis_alltof_proton_flux_av']

name_feeps=[sc_id+'_epd_feeps_BOTTOM_quality_sensorID_12']

tplot_options,'ygap',0.3 ; set vertical gap size between panels (the default gap is often too large with multi panels)

;plotting

tplot,[name_dfg,name_fpi,name_hpca,name_edp,name_dsp,name_feeps],var_label=[sc_id+'_z',sc_id+'_y',sc_id+'_x']

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

