;rbsp_efw_spec_crib
;
;Loads and plots RBSP (Van Allen probes) spectral data
;
;
; SPEC returns 7 channels, with nominal data selection:
;		SPEC0: E12AC
;		SPEC1: E56AC
;		SPEC2: SCMpar
;		SPEC3: SCMperp
;		SPEC4: SCMW
;		SPEC5: V1AC
;		SPEC6: V2AC
;
;
; Kris Kersten, UMN, June 2012
;			email: kris.kersten@gmail.com
; Modified by Aaron Breneman, UMN, Dec 2012
;			email: awbrenem@gmail.com




;initialize RBSP environment
	rbsp_efw_init
	!rbsp_efw.user_agent = ''


;set desired probe
	probe = 'a'


;set time of interest to a single day
	date = '2012-10-13'	; UTC.

	duration = 1	; days.

	timespan, date, duration



;set misc variables
	integration=0 ; for looking at integration data

	get_support_data = 0 ; include support data?   0=no, 1=yes

	bins = 64  ;For now just assume 64 bins

	suffix = ''

	type='calibrated' ; use ADC (raw) numbers or physical (calibrated) units?





; load data
	rbsp_load_efw_spec,$
		probe=probe,$
		type=type,$
		get_support_data=get_support_data,$
		integration=integration



;Get burst availability
	rbsp_load_efw_burst_times,probe=probe
	options,'rbsp'+probe+'_efw_vb1_available','colors',0	
	options,'rbsp'+probe+'_efw_vb2_available','colors',0	




;Optional: Add in fce lines to the spec. Need EMFISIS data for this
	speclist = tnames('*_spec*')

	rbsp_add_fce2spec,speclist,probe;,period=period

	suffix = '_fce'



;Set plot options
	tplot_options,'xmargin',[20.,15.]
	tplot_options,'ymargin',[3,6]
	tplot_options,'xticklen',0.08
	tplot_options,'yticklen',0.02
	tplot_options,'xthick',2
	tplot_options,'ythick',2
	tplot_options,'labflag',-1	





;Plot spec quantities

	tplot_options,'title','RBSP'+strupcase(probe)+' SPEC '+strtrim(bins,2)+' - '+date
	
	tplot,['rbsp'+probe+'_efw_64_spec0'+suffix,$
		   'rbsp'+probe+'_efw_64_spec1'+suffix,$
		   'rbsp'+probe+'_efw_64_spec2'+suffix,$
		   'rbsp'+probe+'_efw_64_spec3'+suffix,$
		   'rbsp'+probe+'_efw_64_spec4'+suffix,$
		   'rbsp'+probe+'_efw_64_spec5'+suffix,$
		   'rbsp'+probe+'_efw_64_spec6'+suffix,$
		   'rbsp'+probe+'_efw_vb1_available',$
		   'rbsp'+probe+'_efw_vb2_available']






;Example saving to PS

	; PostScript needs a different !p.charsize setting
	old_pcharsize=!p.charsize
	!p.charsize=0.6
	
	popen,'RBSP'+strupcase(probe)+'_SPEC_summary_'+strcompress(date,/remove_all),/port
		tplot_options,'title','RBSP'+strupcase(probe)+' SPEC '+strtrim(bins,2)+' - '+date

		tplot,['rbsp'+probe+'_efw_64_spec0'+suffix,$
			   'rbsp'+probe+'_efw_64_spec1'+suffix,$
			   'rbsp'+probe+'_efw_64_spec2'+suffix,$
			   'rbsp'+probe+'_efw_64_spec3'+suffix,$
			   'rbsp'+probe+'_efw_64_spec4'+suffix,$
			   'rbsp'+probe+'_efw_64_spec5'+suffix,$
			   'rbsp'+probe+'_efw_64_spec6'+suffix,$
			   'rbsp'+probe+'_efw_vb1_available',$
			   'rbsp'+probe+'_efw_vb2_available']

	pclose
	
	; now reset the charsize
	!p.charsize=old_pcharsize
	





	; delete all loaded quantities (this can be useful if you want to look at
	; an entirely different day)
	;store_data, '*', /delete



end




