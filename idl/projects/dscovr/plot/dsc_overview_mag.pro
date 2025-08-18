;+
;NAME: DSC_OVERVIEW_MAG
;
;DESCRIPTION:
; Multi-panel plot of DSCOVR Magnetic Field data using TPLOT calls (direct graphics).  
; Vector components are shown in GSE coordinates.   
;
;INPUTS:
; DATE: Date of interest. String, in the form 'YYYY-MM-DD/HH:MM:SS' (as accepted by 'timespan')  
;         Will plot 1 full day.  
;         If this argument is not passed it will look for the TRANGE keyword.
;
;KEYWORDS: (Optional)
; IMPORT_ONLY: Set when replaying GUI overviews. We only want it to import data since the window/panel
;                structure is already a serialized xml tgd document
; GUI:         Set to create the plot inside the SPD_GUI (uses TPLOT_GUI calls)
; SAVE:        Set to save a .png copy of the generated plot(s) in the !dsc.save_plots_dir/mag/ directory
; SPLITS:	     Set to split the time range into quarters and create 4 consecutive
;                plots in addition to the overview of the whole time range.
; TRANGE=:     Set this to the time range of interest.  This keyword will be ignored if
;                DATE argument is passed.  The routine will return without plotting if neither
;                DATE nor TRANGE is set. (2-element array of	doubles (as output by timerange()) 
;                or strings (as accepted by timerange()))
; VERBOSE=:    Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
; 					
;KEYWORD OUTPUTS:
; ERROR=: Returns 1 on error
; WREF=:	Array of integer id(s) of direct graphics window(s) created with this call. (long)
; 
;EXAMPLES:
;		dsc_overview_mag,'2017-02-13',/splits,wref=wr
;		dsc_overview_mag,trange=timerange(),/save
;	
;		trg = timerange(['2017-05-21/13:00:00','2017-05-21/18:30:00'])
;		dsc_overview_mag,trange=trg,/splits,/save
;		dsc_overview_mag,trange=['2017-01-01','2017-01-02/06:00:00']
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/plot/dsc_overview_mag.pro $
;-
PRO DSC_OVERVIEW_MAG,DATE,TRANGE=trg,SPLITS=splits,SAVE=save,VERBOSE=verbose,WREF=wr, $
	ERROR=error,GUI=gui,IMPORT_ONLY=import_only
	
COMPILE_OPT IDL2

dsc_init
rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose
error = 0
tn_before = [tnames('*',create_time=cn_before)]

catch,err
if err ne 0 then begin
	dprint,dlevel=1,verbose=verbose,rname+': You must supply a date or timerange: ('+rname.toLower()+',''YYYY-MM-DD'') or ('+rname.toLower()+',trange=[t1,t2])'
	error = 1
	return
endif

date_err_msg = 'Date Input Error'
if isa(date,'undefined') then begin
	 if (~isa(trg,/float,/array) and ~isa(trg,/string,/array))  then message,date_err_msg 
	 trg = timerange(trg)
endif else begin
	if (~isa(date,/string,/scalar)) then message,date_err_msg
	timespan,date,1,/day
	trg = timerange()
endelse
catch,/cancel

mindate = timerange('2015-02-11')
foreach time,trg do begin
	if time lt mindate[0] then begin
		dprint,dlevel=1,verbose=verbose,rname+': Please supply a date after launch (2015-02-11)'
		error = 1
		return
	endif
endforeach
wr = []

dsc_load_mag,trange=trg

var = ['b','bz','btheta','bphi']
tn = dsc_ezname(var)

; make sure the data was loaded
dsc_data_loaded = tnames(tn)

if n_elements(dsc_data_loaded) eq n_elements(tn) then begin
	dsc_clearopts,tn
	options,tn,title='',labels=''

	foreach n,tn do begin
		dsc_get_ylimits,n,limstr,trg,/inc,/buff
		options,n,yrange=limstr.yrange,ystyle=1
	endforeach
	tstr = time_string(trg)
				
	; Command line plotting
	if isa(gui,'undefined') then begin
		options,tn[0],colors='k'
		options,tn[1],colors='r',labels=''
		options,tn[2:3],colors=250

		dm = GET_SCREEN_SIZE()
		xsize=0.7*dm[0]
		ysize=0.8*dm[1]
		
		spd_graphics_config
		
		wtitle = 'DSCOVR MAG: ('+tstr[0]+' - '+tstr[1]+')'
		window,/free,title=wtitle,xsize=xsize,ysize=ysize
		w = !d.window
		tplot,tn,trange=trg,window=w,title='DSCOVR Magnetic Field 1 second resolution'
		
		if keyword_set(splits) then begin
			trgs = dindgen(5,start=trg[0],increment=.25*(trg[1]-trg[0]))
			tstrs = time_string(trgs)
		
			wtitle = 'DSCOVR MAG 1/4: ('+tstrs[0]+' - '+tstrs[1]+')'
			window,/free,title=wtitle,xsize=xsize,ysize=ysize
			w1 = !d.window
			
			wtitle = 'DSCOVR MAG 2/4: ('+tstrs[1]+' - '+tstrs[2]+')'
			window,/free,title=wtitle,xsize=xsize,ysize=ysize
			w2 = !d.window
			
			wtitle = 'DSCOVR MAG 3/4: ('+tstrs[2]+' - '+tstrs[3]+')'
			window,/free,title=wtitle,xsize=xsize,ysize=ysize
			w3 = !d.window
			
			wtitle = 'DSCOVR MAG 4/4: ('+tstrs[3]+' - '+tstrs[4]+')'
			window,/free,title=wtitle,xsize=xsize,ysize=ysize
			w4 = !d.window			
			
			foreach n,tn do begin
				dsc_get_ylimits,n,limstr,trgs[0:1],/include_err,/buff
				options,n,yrange=limstr.yrange,ystyle=1
			endforeach
			tplot,tn,trange=trgs[0:1],title='DSCOVR Magnetic Field 1 second resolution - Split 1 of 4',window=w1
			
			foreach n,tn do begin
				dsc_get_ylimits,n,limstr,trgs[1:2],/include_err,/buff
				options,n,yrange=limstr.yrange,ystyle=1
			endforeach
			tplot,tn,trange=trgs[1:2],title='DSCOVR Magnetic Field 1 second resolution - Split 2 of 4',window=w2
			
			foreach n,tn do begin
				dsc_get_ylimits,n,limstr,trgs[2:3],/include_err,/buff
				options,n,yrange=limstr.yrange,ystyle=1
			endforeach
			tplot,tn,trange=trgs[2:3],title='DSCOVR Magnetic Field 1 second resolution - Split 3 of 4',window=w3
			
			foreach n,tn do begin
				dsc_get_ylimits,n,limstr,trgs[3:4],/include_err,/buff
				options,n,yrange=limstr.yrange,ystyle=1
			endforeach
			tplot,tn,trange=trgs[3:4],title='DSCOVR Magnetic Field 1 second resolution - Split 4 of 4',window=w4
			wr = [w1,w2,w3,w4]
		endif
		
		if keyword_set(save) then begin
			dprint,dlevel=2,verbose=verbose,rname+':Saving DSCOVR Magnetic Field Overview Plots'
			dir = !dsc.save_plots_dir+'mag/'
			prefix = 'dsc_mag_tplotoverview_'
			
			; full overview
			tstr = time_string(trg,format=6)
			makepng,dir+prefix+tstr[0]+'_'+tstr[1],/mkdir,window=w
			
			; 1/4 time splits
			if keyword_set(splits) then begin
				tstr = time_string(trgs,format=6)
				foreach wndw,wr,i do makepng,dir+prefix+tstr[i]+'_'+tstr[i+1],/mkdir,window=wndw
			endif
		endif
		wr = [w,wr]
		dsc_clearopts,tn
		
	; Plotting in the GUI
	endif else begin
		tplot_options, title='DSCOVR MAG Overview ('+tstr[0]+' - '+tstr[1]+')'
		fsize=8
		foreach name,tn do store_data,name,newname='GUIOV_'+name
		tn = 'GUIOV_'+tn
		options,tn[0],colors=252
		options,tn[1],colors='r'
		options,tn[2:3],colors=210
		spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
		tplot_gui, trange=trg, /no_verify, /add_panel, tn, import_only=import_only

		activeWindow = !spedas.windowStorage->GetActive()
		activeWindow->GetProperty, panels = panelsObj
		panels = panelsObj->get(/all)

		for i = 0,n_elements(panels)-1 do begin
			panels[i].getProperty,yaxis=yobj,tracesettings=trobj
			if tn[i].Matches('PHI') then begin
				yobj.setProperty,majortickauto=0,firsttickat=0,majortickevery=90,nummajorticks=5,majortickunits=0
			endif else if tn[i].Matches('THETA') then begin
				yobj.setProperty,majortickauto=0,firsttickat=-90,majortickevery=45,nummajorticks=5,majortickunits=0
			endif

			; Don't connect gaps
			numtraces = trobj.count()
			if numtraces gt 0 then begin
				lines = trobj.get(/all)
				foreach line,lines do begin
					line.setProperty,drawbetweenpts=1,separatedby=5.0,separatedunits=1
				endforeach
			endif	else begin
				dprint,dlevel=1,verbose=verbose,rname+': No data in panel '+(i+1).toString()
				error = 1
				return
			endelse

			yobj.setProperty,lineatzero=0
			yobj.getproperty,titleobj=ytitleObj
			yobj.getproperty,subtitleobj=ysubtitleObj
			yobj.getproperty,annotatetextobj=atextObj
			ytitleObj.setProperty,size=fsize+1
			ysubtitleObj.setProperty,size=fsize
			atextObj.setProperty,size=fsize
			ytitleObj.getProperty,value=ytitle

			; Nicer legend names
			if numtraces eq 1 then begin
				newlgd = {panel: i+1, numtraces: 1 , tracenames: [ytitle]}
			endif else begin
				dprint,dlevel=1,verbose=verbose,rname+': Unexpected number of traces in panel '+(i+1).toString()
				error = 1
				return
			endelse

			panels[i].getProperty,legendsettings=lgd
			lgd.UpdateTraces,newlgd
		endfor
		panels[-1].getProperty,xaxis=xobj
		xobj.getproperty,annotatetextobj=atext
		atext.setProperty,size=fsize
		
		if n_elements(to_delete) gt 0 && is_string(to_delete) then begin
			store_data,to_delete,/delete
		endif
	endelse	
endif else begin
	dprint, dlevel = 1, 'Error creating DSCOVR MAG overview plot - no data loaded for ' + time_string(trg)
	error = 1
endelse
END