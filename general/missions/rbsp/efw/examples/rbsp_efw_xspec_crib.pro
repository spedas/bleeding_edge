;rbsp_efw_xspec_crib
;
;Loads and plots RBSP (Van Allen probes) cross-spectral data
;
; Kris Kersten, UMN, June 2012
;			email: kris.kersten@gmail.com
;
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


;Set other quantities
	integration=0 ; for looking at integration data
	get_support_data = 0 ; include support data? 0=no, 1=yes
	suffix = ''
	
	type='calibrated' ;use ADC (raw) numbers or physical (calibrated) units?



;Load the data
	rbsp_load_efw_xspec,$
		probe=probe,$
		type=type,$
		get_support_data=get_support_data,$
		integration=integration


;Get burst availability
	rbsp_load_efw_burst_times,probe=probe
	options,'rbsp'+probe+'_efw_vb1_available','colors',0	
	options,'rbsp'+probe+'_efw_vb2_available','colors',0	



;Optional: Add in fce lines to the spec. Need EMFISIS data for this
	speclist = tnames('*_xspec*')

	rbsp_add_fce2spec,speclist,probe,period=period

	suffix = '_fce'




;For now use the default value of 64 spectral bins per fft
	bins = '64'



;Plot options
	charsz_plot = 0.8  ;character size for plots
	charsz_win = 1.2  
	!p.charsize = charsz_win
	tplot_options,'xmargin',[20.,15.]
	tplot_options,'ymargin',[3,6]
	tplot_options,'xticklen',0.08
	tplot_options,'yticklen',0.02
	tplot_options,'xthick',2
	tplot_options,'ythick',2
	tplot_options,'labflag',-1	




;Plot xspec quantities
	
	
	tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
	tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_src1'+suffix,$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_src2'+suffix,$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_phase'+suffix,$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_coh'+suffix,$
   		   'rbsp'+probe+'_efw_vb1_available',$
		   'rbsp'+probe+'_efw_vb2_available']




	tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
	tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec1_src1'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec1_src2'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec1_phase'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec1_coh'+suffix,$
   		   'rbsp'+probe+'_efw_vb1_available',$
		   'rbsp'+probe+'_efw_vb2_available']



	tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
	tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec2_src1'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec2_src2'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec2_phase'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec2_coh'+suffix,$
   		   'rbsp'+probe+'_efw_vb1_available',$
		   'rbsp'+probe+'_efw_vb2_available']



	tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
	tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec3_src1'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec3_src2'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec3_phase'+suffix,$
		   'rbsp'+probe+'_efw_xspec_'+bins+'_xspec3_coh'+suffix,$
   		   'rbsp'+probe+'_efw_vb1_available',$
		   'rbsp'+probe+'_efw_vb2_available']







;Example saving plot to .PS

; PostScript needs a different !p.charsize setting
old_pcharsize=!p.charsize
!p.charsize=0.6


popen,'RBSP'+strupcase(probe)+'_XSPEC_summary_'+strcompress(date,/remove_all),/port

	tplot_options,'title','rbsp'+probe +' Xspec - ' + date+mess
	tplot,['rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_src1',$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_src2',$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_phase',$
	       'rbsp'+probe+'_efw_xspec_'+bins+'_xspec0_coh']+suffix

pclose


; now reset the charsize
!p.charsize=old_pcharsize




; delete all loaded quantities (this can be useful if you want to look at
; an entirely different day)
;store_data, '*', /delete











;anames=''
;nna=''
;anames=tnames('rbspa_efw_xspec_*')
;if strlen(anames[0]) ne 0 then nna=strmid(anames[0],16,1)
;if nna eq '3' then abins='36' $
;	else if nna eq '6' then abins='64' $
;	else if nna eq '1' then abins='112' $
;	else abins='0'

;bnames=''
;nnb=''
;bnames=tnames('rbspb_efw_xspec_*')
;if strlen(bnames[0]) ne 0 then nnb=strmid(bnames[0],16,1)
;if nnb eq '3' then bbins='36' $
;	else if nnb eq '6' then bbins='64' $
;	else if nnb eq '1' then bbins='112' $
;	else bbins='0'



end
