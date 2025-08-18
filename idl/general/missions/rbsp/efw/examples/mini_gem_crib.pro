;+
; NAME: mini_gem_crib.pro
; SYNTAX:
; PURPOSE: EFW crib sheet for the mini-GEM meeting at Fall AGU 2012.
;					 Loads a bunch of useful data products
; KEYWORDS:
; HISTORY: Aaron Breneman, UMN, Dec 2012 (awbrenem@gmail.com)
;
;-


	date = '2013-03-17'
	timespan,date,1
	sc = 'a'

	rbx = 'rbsp'+sc


	;...stuff to make plots pretty
	rbsp_efw_init
	!p.charsize = 1.2
	tplot_options,'xmargin',[20.,15.]
	tplot_options,'ymargin',[3,6]
	tplot_options,'xticklen',0.08
	tplot_options,'yticklen',0.02
	tplot_options,'xthick',2
	tplot_options,'ythick',2



	;Get B1 and B2 availability
	rbsp_load_efw_burst_times,probe=sc
	options,['rbsp'+sc+'_efw_vb2_available','rbsp'+sc+'_efw_vb1_available'],'colors',0

	;Load waveform data
	rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy'
	split_vec, 'rbsp'+sc+'_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']


	;Plot antenna potentials
	tplot_options,'title','Single-ended potential'
	tplot,['rbsp'+sc+'_efw_vsvy_V1',$
		'rbsp'+sc+'_efw_vsvy_V2',$
		'rbsp'+sc+'_efw_vb2_available',$
		'rbsp'+sc+'_efw_vb1_available']




;-------------------------------------------------------------------------------------
;CREATE DENSITY PROXY (V1 + V2)/2
;-------------------------------------------------------------------------------------


	get_data,'rbsp'+sc +'_efw_vsvy_V1',data=d1
	get_data,'rbsp'+sc +'_efw_vsvy_V2',data=d2

	datt = d1
	sum = (d1.y + d2.y)/2.

	datt.y = sum
	store_data,'density_proxy',data=datt
	options,'density_proxy','ytitle','(V1+V2)/2!C[volts]'

	rbsp_detrend,['density_proxy'],60.*5.

	tplot_options,'title','Density proxy'
	tplot,['rbsp'+sc+'_efw_vsvy_V1',$
		'rbsp'+sc+'_efw_vsvy_V2',$
		 'density_proxy',$
		 'density_proxy_detrend',$
		 'rbsp'+sc+'_efw_vb2_available',$
		 'rbsp'+sc+'_efw_vb1_available']



;-----------------------------------------------
;  Load L2 vsvy-hires and e-spinfit-mgse
;-----------------------------------------------

	rbsp_load_efw_waveform_l2,probe=sc

	options,'*_efw_e-spinfit-mgse_e12_spinfit_mgse','colors',[2,4,6]
	options,'*_efw_e-spinfit-mgse_e12_spinfit_mgse','labels',['X','Y','Z']
	options,'*_efw_e-spinfit-mgse_e12_spinfit_mgse','labflag',1
	options,'*_efw_e-spinfit-mgse_vxb_spinfit_mgse','colors',[2,4,6]
	options,'*_efw_e-spinfit-mgse_vxb_spinfit_mgse','labels',['X','Y','Z']
	options,'*_efw_e-spinfit-mgse_vxb_spinfit_mgse','labflag',1

	split_vec, 'rbsp'+sc+'_efw_e-spinfit-mgse_e12_spinfit_mgse'
	split_vec, 'rbsp'+sc+'_efw_e-spinfit-mgse_vxb_spinfit_mgse'
	split_vec, 'rbsp'+sc+'_efw_vsvy-hires_vsvy', suffix='_V'+['1','2','3','4','5','6']

	tplot_options, 'title', string( strupcase( rbx), format='(A,X,"EFW L2 Products")')

	tplot,rbx+'_'+[ 'efw_e-spinfit-mgse_e12_spinfit_mgse', $
		'efw_e-spinfit-mgse_vxb_spinfit_mgse']

	tplot,rbx+'_'+[ 'efw_vsvy-hires_vsvy_V?'],/add




;-----------------------------------------------
;Load and despin the electric field data
;-----------------------------------------------


	;Load the Esvy data, despin it and transform it to MGSE
	rbsp_load_efw_esvy_mgse,probe=sc,/no_spice_load
	split_vec,'rbsp'+sc+'_efw_esvy_mgse'

	options,'rbsp'+sc+'_efw_esvy_mgse_y','colors',0


	;Modified-GSE three components of Efield
	;	x = spin axis
	tplot_options,'title','Esvy MGSE'
	tplot,['rbsp'+sc+'_efw_esvy_mgse_y',$
		   'rbsp'+sc+'_efw_esvy_mgse_z',$
		   'rbsp'+sc+'_efw_vb2_available',$
		   'rbsp'+sc+'_efw_vb1_available']



;--------------------------------------------------------------------
;The Esvy data are now in MGSE. Let's put the Bsvy data from EMFISIS into
;MGSE. Then we can do the vxB subtraction
;--------------------------------------------------------------------


	;Get antenna pointing direction and stuff
	rbsp_load_state,probe=probe,/no_spice_load,datatype=['spinper','spinphase','mat_dsc','Lvec']
	rbsp_efw_position_velocity_crib,/no_spice_load,/noplot
	get_data,rbspx+'_spinaxis_direction_gse',data=wsc_GSE


	;load EMFISIS 4sec GSE L3 data
	rbsp_load_emfisis,probe=sc,coord='gse',cadence='4sec',level='l3'  ;load this for the mag model subtract
	copy_data,'rbsp'+sc+'_emfisis_l3_4sec_gse_Mag','Mag_gse'


	;Interpolate spin-axis pointing direction to cadence of EMFISIS data
	get_data,'Mag_gse',data=tmp
	wsc_GSE_tmp = [[interpol(wsc_GSE.y[*,0],wsc_GSE.x,tmp.x)],$
		[interpol(wsc_GSE.y[*,1],wsc_GSE.x,tmp.x)],$
		[interpol(wsc_GSE.y[*,2],wsc_GSE.x,tmp.x)]]


	;Transform EMFISIS survey data to MGSE
	rbsp_gse2mgse,'Mag_gse',wsc_GSE_tmp,newname='Mag_mgse'


	;Transform sc velocity data to MGSE
	copy_data'rbsp'+sc+'_state_vel_gse','vel_mgse'


	;Remove the vxB component of the electric field
	rbsp_vxb_subtract,'vel_mgse','Mag_mgse','rbsp'+sc+'_efw_esvy_mgse'


	split_vec,'Esvy_mgse_vxb_removed'
	options,['Esvy_mgse_vxb_removed_x'],'ytitle','Ex!Cmgse!Cvxb!Cremoved!C[mV/m]'
	options,['Esvy_mgse_vxb_removed_y'],'ytitle','Ey!Cmgse!Cvxb!Cremoved!C[mV/m]'
	options,['Esvy_mgse_vxb_removed_z'],'ytitle','Ez!Cmgse!Cvxb!Cremoved!C[mV/m]'
	options,'rbsp'+sc+'_radius','panel_size',0.6
	options,'rbsp'+sc+'_radius','ytitle','Rad!C[RE]'



	tplot_options,'title','Esvy vxB removed'
	tplot,['rbsp'+sc+'_efw_esvy_mgse_y',$
		'Esvy_mgse_vxb_removed_y',$
		'rbsp'+sc+'_radius',$
		'rbsp'+sc+'_efw_vb2_available','rbsp'+sc+'_efw_vb1_available']



;----------------------------------------
;Load spectral data
;----------------------------------------


	rbsp_load_efw_spec, probe=sc, type='calibrated'


	tplot,['rbsp'+sc +'_efw_64_spec0',$
		'rbsp'+sc +'_efw_64_spec4','radius']




;-----------------------------------------
;Load filterbank data
;-----------------------------------------


	rbsp_load_efw_fbk, probe=sc, type='calibrated'

	rbsp_split_fbk,sc,/combine


	!p.charsize = 0.9
	tplot_options,'title','Filterbank'
	tplot,['rbsp'+sc +'_fbk1_13comb_12',$
		'rbsp'+sc +'_fbk1_13comb_11',$
		'rbsp'+sc +'_fbk1_13comb_10',$
		'rbsp'+sc +'_fbk1_13comb_9',$
		'rbsp'+sc +'_fbk1_13comb_8',$
		'rbsp'+sc +'_fbk1_13comb_7',$
		'rbsp'+sc +'_fbk1_13comb_6',$
		'rbsp'+sc +'_fbk1_13comb_5',$
		'rbsp'+sc +'_fbk1_13comb_4',$
		'rbsp'+sc +'_fbk1_13comb_3',$
		'rbsp'+sc +'_fbk1_13comb_2',$
		'rbsp'+sc +'_fbk1_13comb_1',$
		'rbsp'+sc +'_fbk1_13comb_0',$
		'radius','rbsp'+sc +'_efw_64_spec0']


;-------------------------------------
;Load Xspec data
;-------------------------------------

	rbsp_load_efw_xspec, probe=sc,type='calibrated'

	!p.charsize = 1.2
	tplot_options,'title','Xspec'
	tplot,['rbsp'+sc+'_efw_xspec_64_xspec0_src1',$
		'rbsp'+sc+'_efw_xspec_64_xspec0_src2',$
		'rbsp'+sc+'_efw_xspec_64_xspec0_phase',$
		'rbsp'+sc+'_efw_xspec_64_xspec0_coh','radius',$
		'rbsp'+sc+'_efw_vb2_available','rbsp'+sc+'_efw_vb1_available']
