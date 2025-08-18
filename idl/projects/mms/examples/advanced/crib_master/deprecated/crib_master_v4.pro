; Script to load MMS data from various instruments and plot a subset of parameters. Specifiy plot formats etc...

; created by Jim Burch, July, 2015.
; updated by Tai Phan: August 31, 2015
; updated by Eric Grimes: January 4, 2016
; updated to v4 by Eric Grimes, 4/1/2016 (now works for public access, uses L2 data)
; updated to include omni-directional FEEPS electron data by Eric Grimes, April 12, 2016
; updated variable name for omni-directional FEEPS electron data by Eric Grimes, July 26, 2016

; to run this script, in IDL session, type: .r crib_master_v4 (or click the run button)


; To change the font size of plot labels, use "!p.charsize= 1 or 0.5 or ...". 1 is the default. 

i_load=1 ; =1 if data has not been loaded, =0 of data has already been loaded (no need to load again in this IDL session)

; To create a postscript file of the plot, select i_print=1 below

i_print=0 ; = 1 to generate a postscript file of plot (default name is 'plot.ps')

; to zoom in and out, use tlimit (various options in tlimit: 'tlimit,/last', 'tlimit,/full', 'tlimit,time1, time2')

timespan,'2015-10-16/13:00', 1, /hour ; (other often-used options are /day or /min)

;timespan,'2015-08-28/11:00', 8.2, /hour ; (other often-used options are /day or /min)


sc_id='mms4' ; specify spacecraft

probe_id=strmid(sc_id,3,1) ; extract the spacecraft number out of the sc_id string


level = 'l2' ; (current options are 'l2', 'sitl' or 'l1b' for HPCA)

;level = 'l1b' ; (current options are 'l2', 'sitl' or 'l1b' for HPCA)

; To change the font size of plot labels, use "!p.charsize= 1 or 0.5 or ...". 1 is the default. 
!p.charsize=1

; To change the plot size, change the xsize, ysize options in the call to window
window, xsize=800, ysize=1024

if i_load eq 1 then begin

; loading FPI, HPCA, FGM, and FEEPS data
mms_load_fpi, probes=probe_id,level=level,data_rate='fast', datatype=['des-moms', 'dis-moms']

; Load E
mms_load_edp, probes = probe_id, level='l2', data_rate='fast', datatype='dce'

; NOW DSP...
; Efield / SCM spectral density
mms_load_dsp, probes=probe_id, datatype=['epsd', 'bpsd'], level='l2', data_rate='fast'

; now EPD
;mms_load_eis, probes=probe_id, datatype='extof'
;mms_load_eis, probes=probe_id, datatype='phxtof'

;FGM
mms_load_fgm, probe=probe_id

;HPCA
mms_load_hpca, probes=probe_id, datatype='ion', level=level, data_rate='srvy'
; calculate the spectra for the full field of view
mms_hpca_calc_anodes, fov=[0, 360], probe=probe_id
mms_load_hpca, probes=probe_id, datatype='moments', data_rate='srvy', level=level

; MEC
mms_load_mec, probes=probe_id, data_rate='srvy', level=level

mms_load_feeps, probes=probe_id, level='l2'

endif; i_load



;*********************************************************
; Orbits
;*********************************************************

get_data, sc_id+'_mec_r_gsm', data = mms_ephem

ephem_times = mms_ephem.x

Re = 6378.137
mms_x = mms_ephem.y[*,0]/Re
mms_y = mms_ephem.y[*,1]/Re
mms_z = mms_ephem.y[*,2]/Re
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

;  options, sc_id+'_fpi_iEnergySpectr_omni', 'spec', 1 ; 1= spectrogram, 0= line plot
options, sc_id+'_dis_energyspectr_omni_avg', 'no_interp', 1
options, sc_id+'_dis_energyspectr_omni_avg', 'ytitle', 'ion E' ; define y label. tplot name used if not defined.
options, sc_id+'_dis_energyspectr_omni_avg', 'ysubtitle', '[eV]'

; define y axis limits (optional)
ylim, sc_id+'_dis_energyspectr_omni_avg', 10, 26000,1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear y axis
; define color range limits (optional)
zlim, sc_id+'_dis_energyspectr_omni_avg', 0, 0, 1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear
;  zlim, sc_id+'_dis_energyspectr_omni_avg', .1, 2000, 1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear


options, sc_id+'_des_energyspectr_omni_avg', 'spec', 1
options, sc_id+'_des_energyspectr_omni_avg', 'no_interp', 1
options, sc_id+'_des_energyspectr_omni_avg', 'ytitle', 'Electron E'
options, sc_id+'_des_energyspectr_omni_avg', 'ysubtitle', '[eV]'
ylim, sc_id+'_des_energyspectr_omni_avg', 10, 26000, 1 ; the 3rd number specifies log (1) or linear (0) scale
zlim, sc_id+'_des_energyspectr_omni_avg', 0,0, 1 ; the 3rd number specifies log (1) or linear (0) scale
;  zlim, sc_id+'_fpi_eEnergySpectr_omni', .1, 2000, 1 ; the 3rd number specifies log (1) or linear (0) scale
;
;; combine the bulk ion velocity into a single tplot variable
;join_vec, [sc_id+'_fpi_iBulkV_X_DSC', sc_id+'_fpi_iBulkV_Y_DSC', $
;           sc_id+'_fpi_iBulkV_Z_DSC'], sc_id+'_fpi_iBulkV_DSC'
;; set some options for pretty plots
;options, sc_id+'_fpi_iBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz']
;options, sc_id+'_fpi_iBulkV_DSC', 'labflag', -1
;options, sc_id+'_fpi_iBulkV_DSC', 'colors', [2, 4, 6]
;
;; combine the perp and parallel temperatures into a single tplot variable
;join_vec,  [sc_id+'_fpi_DEStempPara', $
;        sc_id+'_fpi_DEStempPerp'], sc_id+'_fpi_DEStemp'
;
;options, sc_id+'_fpi_DEStemp', 'labels', ['Te_par', 'Te_per']
;options, sc_id+'_fpi_DEStemp', 'labflag', -1
;options, sc_id+'_fpi_DEStemp', 'colors', [6,2]
;ylim,sc_id+'_fpi_DEStemp',0,0,1
;
;; combine the perp and parallel temperatures into a single tplot variable
;join_vec,  [sc_id+'_fpi_DIStempPara', $
;        sc_id+'_fpi_DIStempPerp'], sc_id+'_fpi_DIStemp'
;
;options, sc_id+'_fpi_DIStemp', 'labels', ['Ti_par', 'Ti_per']
;options, sc_id+'_fpi_DIStemp', 'labflag', -1
;options, sc_id+'_fpi_DIStemp', 'colors', [6,2]
;ylim,sc_id+'_fpi_DIStemp',0,0,1

join_vec, sc_id+'_dis_bulk'+['x', 'y', 'z']+'_dbcs_fast',  sc_id+'_dis_bulkv_dbcs_fast'
;*********************************************************
; HPCA
;*********************************************************

;stop


;options, sc_id+'_hpca_hplus_RF_corrected','spec',1 
;options, sc_id+'_hpca_hplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_hplus_flux_elev_0-360','ytitle','H!U+!N'
options, sc_id+'_hpca_hplus_flux_elev_0-360','ysubtitle','[eV]'
;options, sc_id+'_hpca_hplus_RF_corrected','ztitle','counts'
;ylim,    sc_id+'_hpca_hplus_RF_corrected', 1, 40000.,1 ; the 3rd number specifies log (1) or linear (0) scale
;zlim,    sc_id+'_hpca_hplus_RF_corrected', .1, 1000.,1 ; the 3rd number specifies log (1) or linear (0) scale
;
;;    data quality
;;ylim,  sc_id+'_hpca_hplus_data_quality',0, 255.
;;options,  sc_id+'_hpca_hplus_data_quality','ytitle','Data Quality'
;
;options,sc_id+'_hpca_heplusplus_RF_corrected','spec',1 
;options, sc_id+'_hpca_heplusplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_heplusplus_flux_elev_0-360','ytitle','He!U++!N'
options, sc_id+'_hpca_heplusplus_flux_elev_0-360','ysubtitle','[eV]'
;options, sc_id+'_hpca_heplusplus_RF_corrected','ztitle','counts'
;ylim,    sc_id+'_hpca_heplusplus_RF_corrected', 1, 40000.,1
;zlim,    sc_id+'_hpca_heplusplus_RF_corrected', .1, 1000.,1
;
;options,sc_id+'_hpca_oplus_RF_corrected','spec',1 
;options, sc_id+'_hpca_oplus_RF_corrected','no_interp',1
options, sc_id+'_hpca_oplus_flux_elev_0-360','ytitle','O!U+!N'
options, sc_id+'_hpca_oplus_flux_elev_0-360','ysubtitle','[eV]'
;options, sc_id+'_hpca_oplus_RF_corrected','ztitle','counts'
;ylim,    sc_id+'_hpca_oplus_RF_corrected', 1, 40000.,1
;zlim,    sc_id+'_hpca_oplus_RF_corrected', .1, 1000.,1
;
ylim, sc_id+'_hpca_hplus_number_density', 0,0,0
options, sc_id+'_hpca_hplus_number_density','ytitle','H!U+!N Density'
options, sc_id+'_hpca_hplus_number_density', 'ysubtitle', '[cm!U-3!N]'
options, sc_id+'_hpca_hplus_number_density', labels='n (H!U+!N)'
options, sc_id+'_hpca_hplus_number_density','labflag',-1
;
;
;ylim, sc_id+'_hpca_hplus_ion_bulk_velocity', 0, 0,0
;options, sc_id+'_hpca_hplus_ion_bulk_velocity', colors = [2,4,6]
;options, sc_id+'_hpca_hplus_ion_bulk_velocity', 'ytitle', 'H!U+!N km s!U-1!N'
;options, sc_id+'_hpca_hplus_ion_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
;options, sc_id+'_hpca_hplus_ion_bulk_velocity','labflag',-1
;
;ylim, sc_id+'_hpca_oplus_ion_bulk_velocity', 0, 0, 0
;options, sc_id+'_hpca_oplus_ion_bulk_velocity', colors = [2,4,6]
;options, sc_id+'_hpca_oplus_ion_bulk_velocity', 'ytitle', 'O!U+!N km s!U-1!N'
;options, sc_id+'_hpca_oplus_ion_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
;options, sc_id+'_hpca_oplus_ion_bulk_velocity','labflag',-1
;
;ylim, sc_id+'_hpca_hplus_scalar_temperature', 0,0, 1
;options, sc_id+'_hpca_hplus_scalar_temperature', colors = [2,4]
;options, sc_id+'_hpca_hplus_scalar_temperature', 'ytitle', 'T H!U+!N '
;options, sc_id+'_hpca_hplus_scalar_temperature', labels=['h!U+!N', 'o!U+!N']
;options, sc_id+'_hpca_hplus_scalar_temperature','labflag',-1



;*********************************************************
; FGM
;*********************************************************

; limit fgm to +-200 nT
split_vec, sc_id+'_fgm_b_gsm_srvy_l2_bvec'

tclip, sc_id+'_fgm_b_gsm_srvy_l2_bvec_?', -200, 200, /overwrite
tclip, sc_id+'_fgm_b_gsm_srvy_l2_btot', -200, 200, /overwrite
store_data, sc_id+'_fgm_b_gsm_srvy_clipped', data=sc_id+['_fgm_b_gsm_srvy_l2_bvec_'+['x', 'y', 'z']]
options, sc_id+'_fgm_b_gsm_srvy_clipped', 'labflag',-1

;get_data,sc_id+'_dfg_srvy_gsm_dmpa',data=d
;store_data,sc_id+'_dfg_srvy_mag',data={x:d.x,y:sqrt(d.y(*,0)^2+d.y(*,1)^2+d.y(*,2)^2)}

;options, sc_id+'_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
;options, sc_id+'_dfg_srvy_gsm_dmpa', 'labflag',-1

;*********************************************************
; E field: EDP
;*********************************************************

options,sc_id+'_edp_dce_gse_fast_l2', $
            labels=['EX','EY','EZ'],ytitle=sc_id+'!CEDP!Cfast',ysubtitle='[mV/m]',$
            colors=[2,4,6],labflag=-1,yrange=[-20,20],constant=0

;*********************************************************
; DSP
;*********************************************************

ylim,sc_id+'_dsp_epsd_omni',3e1,1.3e5,1
zlim,sc_id+'_dsp_epsd_omni',1e-13,1e-11,1
ylim,sc_id+'_dsp_bpsd_omni_fast_l2',3e1,1.8e3,1
zlim,sc_id+'_dsp_bpsd_omni_fast_l2',1e-8,1e-4,1

;*********************************************************
; group tplot variables for plotting (grouping not required but better aesthetically)
;*********************************************************
name_hpca=[sc_id+'_hpca_hplus_flux_elev_0-360', sc_id+'_hpca_heplusplus_flux_elev_0-360',$
  sc_id+'_hpca_oplus_flux_elev_0-360', sc_id+'_hpca_hplus_number_density', $
  sc_id+'_hpca_hplus_ion_bulk_velocity_GSM', sc_id+'_hpca_oplus_ion_bulk_velocity_GSM', $
  sc_id+'_hpca_hplus_scalar_temperature']

name_edp= sc_id+'_edp_dce_gse_fast_l2'

name_dfg=[sc_id+'_fgm_b_gsm_srvy_l2_btot',sc_id+'_fgm_b_gsm_srvy_clipped']

;name_fpi=[sc_id+'_dis_energyspectr_omni_avg',sc_id+'_des_energyspectr_omni_avg',sc_id+'_dis_numberdensity_dbcs_fast', sc_id+'_dis_bulkv_dbcs_fast ',sc_id+'_fpi_DIStemp',sc_id+'_fpi_DEStemp']
name_fpi=[sc_id+'_dis_energyspectr_omni_avg',sc_id+'_des_energyspectr_omni_avg',sc_id+'_dis_numberdensity_dbcs_fast', sc_id+'_dis_bulkv_dbcs_fast']

name_dsp = [sc_id+'_dsp_epsd_omni',sc_id+'_dsp_bpsd_omni_fast_l2']

;name_eis=[sc_id+'_epd_eis_alltof_proton_flux_av']

name_feeps=[sc_id+'_epd_feeps_srvy_l2_electron_intensity_omni']

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

