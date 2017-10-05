;rbsp_efw_fbk_crib
;
;Loads and plots RBSP (Van Allen probes) filterbank data
;
;note: Source selects for the Filter Bank:
;		0=E12DC
;		1=E34DC
;		2=E56DC
;		3=E12AC
;		4=E34AC
;		5=E56AC
;		6=SCMU
;		7=SCMV
;		8=SCMW
;		9=(V1DC+V2DC+V3DC+V4DC)/4
;		(default is 0)
;
;
;KEY: fbk7 bin width (Hz):
;	0.8-1.5, 3-6, 12-25, 50-100, 200-400, 800-1.6k, 3.2-6.5k
;
;KEY: fbk13 bin width (Hz):
;	0.8-1.5, 1.5-3, 3-6, 6-12, 12-25, 25-50, 50-100, 100-200,
;	200-400, 400-800, 800-1.6k, 1.6k-3.2k, 3.2-6.5k
;
;
;Kris Kersten, UMN, June 2012
;		email: kris.kersten@gmail.com
;Modified by Aaron Breneman, UNN, Dec 2012
;		email: awbrenem@gmail.com


;pro rbsp_efw_fbk_crib,no_spice_load=no_spice_load,noplot=noplot



; initialize RBSP environment
	rbsp_efw_init
	!rbsp_efw.user_agent = ''


; set desired probe
	probe = 'a'


; set time of interest to a single day
	date = '2012-10-13'	; UTC.
	duration = 1 ; days.
	timespan, date, duration



;load data
	rbsp_load_efw_fbk,probe=probe


;Get burst availability
	rbsp_load_efw_burst_times,probe=probe
	options,'rbsp'+probe+'_efw_vb1_available','colors',0	
	options,'rbsp'+probe+'_efw_vb2_available','colors',0	



;remove excess tplot variables
	store_data,['rbsp'+probe+'_efw_fbk_13_ccsds_data_BEB_config',$
				'rbsp'+probe+'_efw_fbk_13_ccsds_data_DFB_config'],/delete




;Split up the FBK data into separate tplot variables for each channel
	rbsp_split_fbk,probe,/combine



;Set plot options
	tplot_options,'xmargin',[20.,15.]
	tplot_options,'ymargin',[3,6]
	tplot_options,'xticklen',0.08
	tplot_options,'yticklen',0.02
	tplot_options,'xthick',2
	tplot_options,'ythick',2
	tplot_options,'labflag',-1	








;Plot filterbank spectral quantities


	tplot_options,'title','RBSP'+probe +' filterbank 1 spec- ' + date
	tplot,['rbsp'+probe +'_efw_fbk_13_fb1_pk',$
		   'rbsp'+probe +'_efw_fbk_13_fb1_av',$
		   'rbsp'+probe+'_efw_vb1_available',$
		   'rbsp'+probe+'_efw_vb2_available']


	tplot_options,'title','RBSP'+probe +' filterbank 2 spec- ' + date
	tplot,['rbsp'+probe +'_efw_fbk_13_fb2_pk',$
		   'rbsp'+probe +'_efw_fbk_13_fb2_av',$
		   'rbsp'+probe+'_efw_vb1_available',$
		   'rbsp'+probe+'_efw_vb2_available']




;Plot combined peak and average quantities separated by bin

	tplot_options,'title','RBSP'+probe +' filterbank 1 combined peak-avg- ' + date
	tplot,['rbsp'+probe +'_fbk1_13comb_12',$
		   'rbsp'+probe +'_fbk1_13comb_11',$
		   'rbsp'+probe +'_fbk1_13comb_10',$
		   'rbsp'+probe +'_fbk1_13comb_9',$
		   'rbsp'+probe +'_fbk1_13comb_8',$
		   'rbsp'+probe +'_fbk1_13comb_7',$
		   'rbsp'+probe +'_fbk1_13comb_6',$
		   'rbsp'+probe +'_fbk1_13comb_5',$
		   'rbsp'+probe +'_fbk1_13comb_4',$
		   'rbsp'+probe +'_fbk1_13comb_3',$
		   'rbsp'+probe +'_fbk1_13comb_2',$
		   'rbsp'+probe +'_fbk1_13comb_1',$
		   'rbsp'+probe +'_fbk1_13comb_0']


	tplot_options,'title','RBSP'+probe +' filterbank 2 combined peak-avg- ' + date
	tplot,['rbsp'+probe +'_fbk2_13comb_12',$
		   'rbsp'+probe +'_fbk2_13comb_11',$
		   'rbsp'+probe +'_fbk2_13comb_10',$
		   'rbsp'+probe +'_fbk2_13comb_9',$
		   'rbsp'+probe +'_fbk2_13comb_8',$
		   'rbsp'+probe +'_fbk2_13comb_7',$
		   'rbsp'+probe +'_fbk2_13comb_6',$
		   'rbsp'+probe +'_fbk2_13comb_5',$
		   'rbsp'+probe +'_fbk2_13comb_4',$
		   'rbsp'+probe +'_fbk2_13comb_3',$
		   'rbsp'+probe +'_fbk2_13comb_2',$
		   'rbsp'+probe +'_fbk2_13comb_1',$
		   'rbsp'+probe +'_fbk2_13comb_0']





; dump summary plots to PostScript using popen, pclose

	; PostScript needs a different !p.charsize setting
	old_pcharsize=!p.charsize
	!p.charsize=0.7
	
	; RBSPA FBK summary
	popen,'RBSPA_FBK_summary_'+strcompress(date,/remove_all),/port
		tplot_options,'title','RBSP'+probe +' filterbank 1 spec- ' + date
		tplot,['rbsp'+probe +'_efw_fbk_13_fb1_pk',$
			   'rbsp'+probe +'_efw_fbk_13_fb1_av',$
			   'rbsp'+probe+'_efw_vb1_available',$
			   'rbsp'+probe+'_efw_vb2_available']
	pclose


	!p.charsize=old_pcharsize


; delete all loaded quantities (this can be useful if you want to look at
; an entirely different day)
;store_data, '*', /delete


end




