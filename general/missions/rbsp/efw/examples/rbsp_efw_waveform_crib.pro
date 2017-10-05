;rbsp_efw_waveform_crib
;
;Loads and plots RBSP (Van Allen probes) waveform data
;
;
; Kris Kersten, UMN, June 2012
;			email: kris.kersten@gmail.com
;
; Modified by Aaron Breneman, UMN, Dec 2012
;		    email: awbrenem@gmail.com
;



;initialize RBSP environment
	rbsp_efw_init
	!rbsp_efw.user_agent = ''


;set desired probe
	probe = 'a'


;set time of interest to a single day
	date = '2012-10-13'	; UTC.
	duration = 1	; days.
	timespan, date, duration



;more stuff to set
	integration=0 ; for looking at integration data
	get_support_data = 0  ; include support data?

	type='calibrated' 	;use raw ADC numbers (raw) or physical units (calibrated)?



;What types of data do we wish to load?

	;Possible datatypes are 'esvy','vsvy','magsvy','eb1','vb1','mscb1','eb2','vb2','mscb2'
	;Note: The high time-resolution b1 and b2 quantities can be slow to load and consume 
	;significant memory when loaded, so it's best to specify just the *svy variables when 
	;looking at surveys over long intervals.

	datatype = ['esvy',$
			    'vsvy',$
			    'magsvy']




;load data
	rbsp_load_efw_waveform,probe=probe,$
						   datatype=datatype,$
						   type=type,$
						   get_support_data=get_support_data,$
						   coord='uvw';,/noclean


;load burst times
	rbsp_load_efw_burst_times,probe=sc


;load despun Esvy data in MGSE
;Requires SPICE to work
	rbsp_load_efw_esvy_mgse,probe=probe




;Remove unnecessary tplot variables
	store_data,['*ccsds_data*'],/delete



;Downsample the data. Useful for daily survey type plots.
;Skip for full resolution
	rbsp_downsample,'rbsp'+probe+'_efw_vsvy',1/(6*11.),/nochange	

	rbsp_downsample,'rbsp'+probe+'_efw_esvy_mgse',1/(6*11.),/nochange







; break the combined variables into individual waveforms
	split_vec, 'rbsp?_efw_esvy', suffix='_'+['E12', 'E34', 'E56']
	split_vec, 'rbsp?_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']
	split_vec, 'rbsp?_efw_magsvy', suffix='_'+['U', 'V', 'W']
	split_vec, 'rbsp?_efw_eb1', suffix='_'+['E12', 'E34', 'E56']
	split_vec, 'rbsp?_efw_vb1', suffix='_V'+['1','2','3','4','5','6']
	split_vec, 'rbsp?_efw_mscb1', suffix='_'+['U', 'V', 'W']
	split_vec, 'rbsp?_efw_eb2', suffix='_'+['E12DC', 'E34DC', 'E56DC', 'E12AC', $
					'E34AC', 'E56AC', 'EDCpar', 'EDCprp', 'EACpar', 'EACprp']
	split_vec, 'rbsp?_efw_vb2', suffix='_V'+['1','2','3','4','5','6']
	split_vec, 'rbsp?_efw_mscb2', suffix='_'+['U', 'V', 'W', 'par', 'perp']	
	split_vec,'rbsp'+probe+'_efw_esvy_mgse'







;Fix labels

	options,['rbsp'+probe+'_efw_vsvy_V*','rbsp'+probe+'_efw_esvy_mgse*'],'ysubtitle',''
	options,'rbsp'+probe+'_efw_vsvy_V*','labels',''
	
	options,'rbsp'+probe+'_efw_esvy_mgse*',labflag=0
	options,'rbsp'+probe+'_efw_vsvy_V*',labflag=0
	
	
	options,'rbsp'+probe+'_efw_esvy_mgse_x','ytitle','RBSP-'+strupcase(probe)+'!CEsvy!CX MGSE!C[mV/m]'
	options,'rbsp'+probe+'_efw_esvy_mgse_y','ytitle','RBSP-'+strupcase(probe)+'!CEsvy!CY MGSE!C[mV/m]'
	options,'rbsp'+probe+'_efw_esvy_mgse_z','ytitle','RBSP-'+strupcase(probe)+'!CEsvy!CZ MGSE!C[mV/m]'
	
	options,'rbsp'+probe+'_efw_vsvy_V1','ytitle','RBSP-'+strupcase(probe)+'!CVsvy!CV1!C[volts]'
	options,'rbsp'+probe+'_efw_vsvy_V2','ytitle','RBSP-'+strupcase(probe)+'!CVsvy!CV2!C[volts]'
	options,'rbsp'+probe+'_efw_vsvy_V3','ytitle','RBSP-'+strupcase(probe)+'!CVsvy!CV3!C[volts]'
	options,'rbsp'+probe+'_efw_vsvy_V4','ytitle','RBSP-'+strupcase(probe)+'!CVsvy!CV4!C[volts]'
	options,'rbsp'+probe+'_efw_vsvy_V5','ytitle','RBSP-'+strupcase(probe)+'!CVsvy!CV5!C[volts]'
	options,'rbsp'+probe+'_efw_vsvy_V6','ytitle','RBSP-'+strupcase(probe)+'!CVsvy!CV6!C[volts]'
	
	
	options,'rbsp'+probe+'_efw_esvy_mgse_*','ztitle','RBSP'+probe+'!CEFW'
	options,'rbsp'+probe+'_efw_vsvy_V*','ztitle','RBSP'+probe+'!CEFW'
	
	
	options,['rbsp'+probe+'_efw_vb1_available','rbsp'+probe+'_efw_vb2_available'],'colors',0
	
	
	



;Set up plot options

	charsz_plot = 0.8  ;character size for plots
	charsz_win = 1.2  
	!p.charsize = charsz_win
	tplot_options,'xmargin',[20.,15.]
	tplot_options,'ymargin',[3,6]
	tplot_options,'xticklen',0.08
	tplot_options,'yticklen',0.02
	tplot_options,'xthick',2
	tplot_options,'ythick',2	
	
	; spread out the labels and reverse their order
	tplot_options,'labflag',1	
	




;Plot combined quantities


	;waveform summary plots
	tplot_options,'title','RBSP'+strupcase(probe)+' voltages summary - ' + date
	tplot,['rbsp'+probe+'_efw_*svy']




;Plot split quantities

	;Single-ended voltages
	tplot_options,'title','RBSP'+strupcase(probe)+' single-ended waveform summary - ' + date
	tplot,'rbsp'+probe+'_efw_vsvy_V*'


	;Esvy quantities
	tplot_options,'title','RBSP'+strupcase(probe)+' Esvy waveform summary - ' + date
	tplot,'rbsp'+probe+'_efw_esvy_E*'


	;plot MGSE Esvy quantities
	tplot_options,'title','RBSP'+strupcase(probe)+' Esvy MGSE summary - ' + date
	tplot,['rbsp'+probe+'_efw_esvy_mgse_y',$
			'rbsp'+probe+'_efw_esvy_mgse_z']


	;Mag survey quantities
	tplot,'rbsp'+probe+'_efw_magsvy_*' ;  MAG survey, split line plots



;Plot burst quantities

	tplot_options,'title','RBSP'+strupcase(probe)+' Burst quanities - ' + date
	tplot,'rbsp'+probe+'_efw_*b1'
	tplot,'rbsp'+probe+'_efw_*b2'

	tplot,'rbsp'+probe+'_efw_eb1_*' ;  E B1, split line plots
	tplot,'rbsp'+probe+'_efw_vb1_V*' ;  V B1, split line plots
	tplot,'rbsp'+probe+'_efw_mscb1_*' ;  MSC B1, split line plots

	tplot,'rbsp'+probe+'_efw_eb2_*' ;  E survey, split line plots
	tplot,'rbsp'+probe+'_efw_vb2_V*' ;  V survey, split line plots
	tplot,'rbsp'+probe+'_efw_mscb2_*' ;  MSC B2, split line plots






;Example plotting as postscript

	;Postscript needs a different !p.charsize setting
	old_pcharsize=!p.charsize
	!p.charsize=0.7

	popen,'RBSP'+strupcase(probe)+'_waveform_summary_'+strcompress(date,/remove_all),/port
		tplot_options,'title','RBSP'+strupcase(probe)+' waveform summary - ' + date
		tplot,['rbsp'+probe+'_efw_*svy',$
			   'rbsp'+probe+'_efw_*b1',$
			   'rbsp'+probe+'_efw_*b2'] ; RBSPA
	pclose


	; now reset the charsize
	!p.charsize=old_pcharsize






end