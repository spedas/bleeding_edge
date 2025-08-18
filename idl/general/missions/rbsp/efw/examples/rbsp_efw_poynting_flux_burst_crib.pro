;WARNING!!! THIS CALCULATION IS VERY PRELIMINARY. DO NOT PUBLISH OR PRESENT
;RESULTS WITHOUT FIRST CONSULTING THE EFW PI JOHN WYGANT wygan001@umn.edu

;+
; NAME: rbsp_efw_poynting_flux_crib.pro
; SYNTAX:
; PURPOSE: Crib sheet for calling rbsp_poynting_flux.pro, which creates
;					 Poynting flux tplot variables (including spectra) from EFW
;					 and EMFISIS data in various coord systems. Plots results
; INPUT:
; OUTPUT:
; KEYWORDS:
;	PROCEDURE: load EMFISIS data in GSE.
;			Transform EMFISIS GSE -> MGSE
;			Load EFW despun waveform data in MGSE
;			Call Poynting flux program
; HISTORY: Created by Aaron W Breneman, UMN awbrenem@gmail.com
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2020-09-11 13:39:04 -0700 (Fri, 11 Sep 2020) $
;   $LastChangedRevision: 29141 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_poynting_flux_burst_crib.pro $
;-


rbsp_efw_init

date = '2014-05-12'     ;chorus
t0 = time_double(date + '/10:00')
t1 = time_double(date + '/12:30')
probe = 'b'

timespan,date
rbspx = 'rbsp'+probe

bt = '1'

;--------------------------------------------------------------------------------
;Find the GSE coordinates of the sc spin axis. This will be used to transform the
;Mag data from GSE -> MGSE coordinates
;--------------------------------------------------------------------------------

;Get antenna pointing direction and stuff
rbsp_efw_position_velocity_crib,/noplot
;rbsp_load_state,probe=probe,/no_spice_load,datatype=['spinper','spinphase','mat_dsc','Lvec']
get_data,rbspx+'_spinaxis_direction_gse',data=wsc_GSE


;------------------------------------------------------
;Get EMFISIS mag data in GSE
;------------------------------------------------------

;Load EMFISIS data
rbsp_load_emfisis,probe=probe,coord='gse',cadence='hires',level='l3'
;rbsp_load_emfisis,probe=probe,coord='gse',cadence='4sec',level='l3'


;Transform the Mag data to MGSE coordinates
get_data,rbspx+'_emfisis_l3_hires_gse_Mag',data=tmpp
;get_data,rbspx+'_emfisis_l3_4sec_gse_Mag',data=tmpp

wsc_GSE_tmp = [[interpol(wsc_GSE.y[*,0],wsc_GSE.x,tmpp.x)],$
			   [interpol(wsc_GSE.y[*,1],wsc_GSE.x,tmpp.x)],$
			   [interpol(wsc_GSE.y[*,2],wsc_GSE.x,tmpp.x)]]

rbsp_gse2mgse,rbspx+'_emfisis_l3_hires_gse_Mag',reform(wsc_GSE_tmp),newname=rbspx+'_Mag_mgse'
;rbsp_gse2mgse,rbspx+'_emfisis_l3_4sec_gse_Mag',reform(wsc_GSE_tmp),newname=rbspx+'_Mag_mgse'


;----------------------------------------------------------
;Get Esvy data in MGSE
;----------------------------------------------------------

;Load Esvy data in MGSE
rbsp_load_efw_esvy_mgse,probe=probe,/no_spice_load
;Load searchcoil burst data
rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['mscb'+bt]
;Load antenna potential burst data
rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['vb'+bt]


;---------------------------------------------------------
;Reduce the data to reasonable times
;---------------------------------------------------------

m1 = tsample(rbspx+'_Mag_mgse',[t0,t1],times=tm)
store_data,rbspx+'_Mag_mgse_r',data={x:tm,y:m1}
m1 = tsample(rbspx+'_efw_esvy_mgse',[t0,t1],times=tm)
store_data,rbspx+'_efw_esvy_mgse_r',data={x:tm,y:m1}


;----------------------------------------------------------
;Get Poynting flux
;----------------------------------------------------------

Tlong = 60.*20.  ;seconds
Tshort = 60.*0.3

;EMIC waves
;Tlong = 1.  	   ;0.1 Hz
;Tshort = 0.125       ;8 Hz

;EMIC waves
;	Tlong = 2.  ;seconds
;	Tshort = 0.2


rbsp_detrend,[rbspx+'_Mag_mgse_r',rbspx+'_efw_esvy_mgse_r'],60.*30.

;Calculate Poynting flux
rbsp_poynting_flux,rbspx+'_Mag_mgse_r_detrend',rbspx+'_efw_esvy_mgse_r_detrend',Tshort,Tlong

copy_data,'pflux_nospinaxis_perp',rbspx+'_pflux_nospinaxis_perp'
copy_data,'pflux_nospinaxis_para',rbspx+'_pflux_nospinaxis_para'
copy_data,'pflux_p1',rbspx+'_pflux_p1'
copy_data,'pflux_p2',rbspx+'_pflux_p2'
copy_data,'pflux_Bo',rbspx+'_pflux_Bo'
copy_data,'Bw_pflux_p3',rbspx+'_Bw_pflux_p3'
copy_data,'Bw_pflux_p2',rbspx+'_Bw_pflux_p2'
copy_data,'Mag_mgse_DC_interp',rbspx+'_Mag_mgse_DC_interp'
store_data,['pflux_nospinaxis_perp','pflux_nospinaxis_para','pflux_p1','pflux_p2','pflux_Bo','Bw_pflux_p3','Bw_pflux_p2','Mag_mgse_DC_interp'],/delete



;----------------------------------------------------------
;Plot various quantities
;----------------------------------------------------------

;Compare pure to mixed pflux
tplot,rbspx+'_'+['pflux_nospinaxis_perp','pflux_nospinaxis_para','pflux_p1','pflux_p2','pflux_Bo']


;Compare E and B to pflux

;Perp to field component
ylim,rbspx+'_pflux_nospinaxis_perp',-0.005,0.005
ylim,rbspx+'_pflux_nospinaxis_para',-0.005,0.005
ylim,[rbspx+'_Ew_pflux_p1',rbspx+'_Bw_pflux_p3',rbspx+'_Mag_mgse_DC_interp'],0,0
tplot,[rbspx+'_pflux_nospinaxis_perp',rbspx+'_Ew_pflux_p1',rbspx+'_Bw_pflux_p3',rbspx+'_Mag_mgse_DC_interp']

;Field aligned component
tplot,[rbspx+'_pflux_nospinaxis_para',rbspx+'_Ew_pflux_p1',rbspx+'_Bw_pflux_p2',rbspx+'_Mag_mgse_DC_interp']
tplot,[rbspx+'_pflux_nospinaxis_para',rbspx+'_pflux_nospinaxis_perp']




;------------------------------------------
;Get spectra of Poynting flux
;------------------------------------------
stop
tplot_save,'*',filename='~/Desktop/pflux_test'
rbsp_efw_poynting_spec,'pflux_Ew','pflux_Bw'

tmpy = where(ppara_specp.y gt minv)
if tmpy[0] ne -1 then ppara_specp.y[tmpy] = 2


;------------------------------
;Red = upwards Pflux
;Blue = downwards Pflux
;Green = could be either upwards or downwards
;------------------------------

tmpy = where(ppara_specn.y gt minv)
if tmpy[0] ne -1 then ppara_specn.y[tmpy] = 1

;Combine the upwards and downwards parallel spectra
;pparab = ppara_specp.y > ppara_specn.y
pparab = ppara_specp.y + ppara_specn.y


store_data,'pparab',data={x:time_index2,y:pparab,v:freq_bins2}
options,'pparab','spec',1
ylim,'pparab',10.,4000.,0
ylim,'rbsp'+probe+'_pflux_nospinaxis_para',0,0
ylim,['rbsp'+probe+'_pflux_nospinaxis_para_SPEC'],10.,4000.,0
zlim,['rbsp'+probe+'_pflux_nospinaxis_para_SPEC'],maxs/10d^5,maxs,1
zlim,'pparab',0,3
options,'rbsp'+probe+'_pflux_nospinaxis_para_SPEC','spec',1


;Red = upwards Pflux; Blue = downwards; Green = either upwards or downwards
tplot,['pparab',$
       'rbsp'+probe+'_pflux_nospinaxis_para',$
       'rbsp'+probe+'_pflux_nospinaxis_para_SPEC',$
       'rbsp'+probe+'_efw_mscb'+bt+'_mgse',$
       'rbsp'+probe+'_efw_eb'+bt+'_mgse']


end
