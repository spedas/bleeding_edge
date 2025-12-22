;+
;PROCEDURE:	fast_elec_summary.pro
;PURPOSE:
;	Generates a summary plot of FAST electron data for tplot.
;
;	Plot 1: Electron Differential Energy Flux vs Energy, 0-45    deg pitch angle 
;	Plot 2: Electron Differential Energy Flux vs Energy, 45-135  deg pitch angle 
;	Plot 3: Electron Differential Energy Flux vs Energy, 135-180 deg pitch angle 
;	Plot 4: Electron Differential Energy Flux vs Pitch Angle, < 1 keV  
;	Plot 5: Electron Differential Energy Flux vs Pitch Angle, > 1 keV  
;	Plot 6: Electron Energy Flux  
;	Plot 7: Electron Flux  
;
;CREATED BY:	J.McFadden
;VERSION:	1
;LAST MODIFICATION:  96/06/20
;MOD HISTORY:
;-
;fast_elec_summary.pro

pro fast_elec_summary

; May need to add the following line
; @startup

;ESA Summary Plot

; Use test orbit 515 for sdt
; Data collection for each plot can take up to 5 min on a sparc ultra
;	Thus the entire plot may take 30 minutes
;	There may be some things that can speed the plotting up.

; Data collection for tplot

; Electron differential energy flux - energy spectrograms

	get_en_spec,"fa_ees_sp",units='eflux',name='el_0',angle=[315,45]
	options,'el_0','spec',1	
	zlim,'el_0',1e4,1e8,1
	ylim,'el_0',1,40000,1
	options,'el_0','ytitle','0!Uo!N e- (eV)'
	options,'el_0','x_no_interp',1
	options,'el_0','y_no_interp',1

	get_en_spec,"fa_ees_sp",units='eflux',name='el_90',angle=[45,135]
	options,'el_90','spec',1	
	zlim,'el_90',1e4,1e8,1
	ylim,'el_90',1,40000,1
	options,'el_90','ytitle','90!Uo!N e- (eV)'
	options,'el_90','x_no_interp',1
	options,'el_90','y_no_interp',1

	get_en_spec,"fa_ees_sp",units='eflux',name='el_180',angle=[135,225]
	options,'el_180','spec',1	
	zlim,'el_180',1e4,1e8,1
	ylim,'el_180',1,40000,1
	options,'el_180','ytitle','180!Uo!N e- (eV)'
	options,'el_180','x_no_interp',1
	options,'el_180','y_no_interp',1

; Electron differential energy flux - angle spectrograms

	get_pa_spec,"fa_ees_sp",units='eflux',name='el_low',energy=[0,1000]
	options,'el_low','spec',1	
	zlim,'el_low',1e4,1e8,1
	ylim,'el_low',-20,380,0
	options,'el_low','ytitle','<1 keV e- (deg)'
	options,'el_low','x_no_interp',1
	options,'el_low','y_no_interp',1

	get_pa_spec,"fa_ees_sp",units='eflux',name='el_high',energy=[1000,40000]
	options,'el_high','spec',1	
	zlim,'el_high',1e4,1e8,1
	ylim,'el_high',-20,380,0
	options,'el_high','ytitle','>1 keV e- (deg)'
	options,'el_high','x_no_interp',1
	options,'el_high','y_no_interp',1

; Electron energy flux - line plot

	get_2dt,'je_2d','fa_ees_sp',name='JEe'
	ylim,'JEe',.001,100,1
	options,'JEe','ytitle','e- (ergs/cm!U2!N-s)'
	
; Electron flux - line plot

	get_2dt,'j_2d','fa_ees_sp',name='Je'
	ylim,'Je',1.e6,1.e10,1
	options,'Je','ytitle','e- (#/cm!U2!N-s)'

; Get the orbit data

	get_data,'el_0',data=tmp
	t1=min(tmp.x)
	t2=max(tmp.x)
	get_fa_orbit,t1,t2
	get_data,'ORBIT',data=tmp
	orbit_num=strcompress(string(tmp.y(0)),/remove_all)

; Save the data to a cdf file  
; This line will eventually get replaced with a save to cdf format file

	tplot_file,/all,/save

; Generate postscript and gif files for 20 minute intervals prior and post the
;	highest invariant latitudes

	get_data,'ILAT',data=ilat
	maxilat = max(ilat.y,max_sub)
	minilat = min(ilat.y,min_sub)

	if maxilat gt 60 then begin

		t1 = ilat.x(max_sub)
		t2 = t1 - 1200

		timespan,t2,20,/minutes
		popen,'fa_ees_'+orbit_num+'_IN',ct=39,/port,/color
		tplot,['el_0','el_90','el_180','el_low','el_high','JEe','Je'] $
		,var_label=['MLT','ALT','ILAT'],title='FAST Electrons  Orbit '+orbit_num
		pclose

		gopen,'fa_ees_'+orbit_num+'_IN.gif',ctable=39,/color
		tplot
		gclose


;		set_plot,'z'
;		tplot
;		im = tvrd()
;		tvlct,/get,r,g,b
;		write_gif,'fa_ees_'+orbit_num+'_IN.gif',im,r,g,b

		timespan,t1,20,/minutes
		popen,'fa_ees_'+orbit_num+'_ON',ct=39,/port,/color
		tplot,['el_0','el_90','el_180','el_low','el_high','JEe','Je'] $
		,var_label=['MLT','ALT','ILAT'],title='FAST Electrons  Orbit '+orbit_num
		pclose

		gopen,'fa_ees_'+orbit_num+'_ON.gif',ctable=39,/color
		tplot
		gclose

;		set_plot,'z'
;		tplot
;		im = tvrd()
;		tvlct,/get,r,g,b
;		write_gif,'fa_ees_'+orbit_num+'_ON.gif',im,r,g,b

	endif

	if minilat lt -60 then begin

		t1 = ilat.x(min_sub)
		t2 = t1 - 1200

		timespan,t2,20,/minutes
		popen,'fa_ees_'+orbit_num+'_IS',ct=39,/port,/color
		tplot,['el_0','el_90','el_180','el_low','el_high','JEe','Je'] $
		,var_label=['MLT','ALT','ILAT'],title='FAST Electrons  Orbit '+orbit_num
		pclose

		gopen,'fa_ees_'+orbit_num+'_IS.gif',ctable=39,/color
		tplot
		gclose

;		set_plot,'z'
;		tplot
;		im = tvrd()
;		tvlct,/get,r,g,b
;		write_gif,'fa_ees_'+orbit_num+'_IS.gif',im,r,g,b

		timespan,t1,20,/minutes
		popen,'fa_ees_'+orbit_num+'_OS',ct=39,/port,/color
		tplot,['el_0','el_90','el_180','el_low','el_high','JEe','Je'] $
		,var_label=['MLT','ALT','ILAT'],title='FAST Electrons  Orbit '+orbit_num
		pclose

		gopen,'fa_ees_'+orbit_num+'_OS.gif',ctable=39,/color
		tplot
		gclose

;		set_plot,'z'
;		tplot
;		im = tvrd()
;		tvlct,/get,r,g,b
;		write_gif,'fa_ees_'+orbit_num+'_OS.gif',im,r,g,b

	endif


return
end

; The following are additional info about using the above routine
;
;	Plot the data
;
;	timespan,'96-12-31/8:20',.6	; Change this line to the correct time span for the orbit
;	orbit_num='515'			; Change this line to the selected orbit number
;	tplot,['el_0','el_90','el_180','el_low','el_high','JEe','Je'],title='FAST Electrons  Orbit '+orbit_num
;	
; The following line should be executed before tplot to set the time span 
;
;	timespan,'96-12-31/3:50',.7	; for orbit 513		
;	timespan,'96-12-31/8:20',.6	; for orbit 515		
;	timespan,'96-12-31/10:30',.6	; for orbit 516		
;	timespan,'96-12-31/21:00',1.	; for orbit 521		
;	timespan,'97-1-1/6:00',1.	; for orbit 525
;	timespan,'97-1-1/17:20',.6	; for orbit 530
;
; The following is to save and restore tplot files 
;
;	tplot_file,/all,/save
;	tplot_file,/all,/restore
;
