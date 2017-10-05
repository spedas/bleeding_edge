;+
;PROCEDURE:	mvn_sta_gen_ql,pathname=pathname,files=files,mag=mag,all=all
;PURPOSE:	
;	To generate quicklook data plots and a tplot save file, assumes "timespan" has been run
;INPUT:		
;
;KEYWORDS:
;	all		0/1		if not set, housekeeping and raw variables 'mvn_STA_*' are deleted from tplot after data is loaded
;	mag		0/1		if set, mag data is loaded
;
;CREATED BY:	J. McFadden	  13-05-07
;VERSION:	1
;LAST MODIFICATION:  14-03-17
;MOD HISTORY:
;
;NOTES:	  
;	
;-

pro mvn_sta_gen_ql,pathname=pathname,files=files,mag=mag,all=all,path_png=path_png

if not keyword_set(path_png) then path_png=''

mvn_sta_l0_load,pathname=pathname,files=files,mag=mag,all=all

	loadct2,43,previous_ct=previous_ct
	cols=get_colors()

		options,'mvn_sta_D8_R1_Time_ABCD',colors=[cols.blue,cols.green,cols.yellow,cols.red]
		options,'mvn_sta_D8_R1_Time_RST',colors=cols.black
		options,'mvn_sta_D8_R1_Time_NoStart',colors=cols.magenta
		options,'mvn_sta_D8_R1_Time_Unqual',colors=cols.red
		options,'mvn_sta_D8_R1_Time_Qual',colors=cols.green

	store_data,'mvn_sta_D8_R1_diag',data=['mvn_sta_D8_R1_Time_RST','mvn_sta_D8_R1_Time_NoStart','mvn_sta_D8_R1_Time_Unqual','mvn_sta_D8_R1_Time_Qual']
		ylim,'mvn_sta_D8_R1_diag',100.,1.e5,1
		options,'mvn_sta_D8_R1_diag',ytitle='sta!CDiagnostics!C!CCounts'
		ylim,'mvn_sta_D8_R1_Time_ABCD',10.,1.e5,1

	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
	if size(mvn_c6_dat,/type) eq 8 then begin
		get_4dt,'n_4d','mvn_sta_get_c6',mass=[.1,100],name='mvn_sta_density'
			options,'mvn_sta_density',ytitle='sta C6!CNi!C!C1/cm!U3'
			ylim,'mvn_sta_density',.1,2.e5,1
	endif

	If(!d.name NE 'Z') Then window,0,xsize=900,ysize=1000

	tt = timerange()
	tt_str = time_string(tt[0])
	date = strmid(tt_str,0,4)+strmid(tt_str,5,2)+strmid(tt_str,8,2)
	title = 'MAVEN STATIC Quicklook '+date
	options,'mvn_sta_mode',panel_size=.5
	ylim,'mvn_sta_mode',-1,7,0
	options,'mvn_sta_C0_att',panel_size=.5
	ylim,'mvn_sta_C0_P1A_tot',1,1.e5,1
	options,'mvn_sta_C0_P1A_tot',ytitle='sta!CP1A-C0!C!CCounts'
	zlim,'mvn_sta_C0_P1A_E',1,1000,1
	options,'mvn_sta_C0_P1A_E',ytitle='sta!CP1A-C0!C!CeV'
	zlim,'mvn_sta_C6_P1C_M',1,1000,1
	zlim,'mvn_sta_A',1,1000,1
	zlim,'mvn_sta_D',1,1000,1
	options,'mvn_sta_C0_att',ytitle='sta!C!CAtten!C'

tplot,[$
	'mvn_sta_mode','mvn_sta_C0_att'$
	,'mvn_sta_density'$
	,'mvn_sta_C0_P1A_tot','mvn_sta_C0_P1A_E','mvn_sta_C6_P1D_M','mvn_sta_A','mvn_sta_D'$				; eventually have this replace the next line
	,'mvn_sta_D8_R1_diag'$
	],title=title

makepng,path_png+'mvn_sta_ql_'+date

	loadct2,previous_ct


end