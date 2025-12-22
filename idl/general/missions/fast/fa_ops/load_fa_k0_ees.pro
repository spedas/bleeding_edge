;+
;PROCEDURE:	load_fa_k0_ees
;PURPOSE:	
;	Load summary data from the FAST electron experiment into tplot structure.
;
;		Loads el_0	electon energy spectrogram, 0-30 pitch angle 
;		Loads el_90	electon energy spectrogram, 60-120 pitch angle 
;		Loads el_180	electon energy spectrogram, 150-180 pitch angle 
;		Loads el_low	electon pitch angle spectrogram, .1-1 keV energy 
;		Loads el_high	electon pitch angle spectrogram, > 1 keV energy 
;		Loads JEe	electon energy flux - mapped to 100 km, positive earthward 
;		Loads Je	electon particle flux  - mapped to 100 km, positive earthward
;	
;INPUT:	
;	none 
;KEYWORDS:
;	filenames	strarr(m), string array of filenames of cdf files to be entered
;				Files are obtained from "dir" if dir is set, 
;					otherwise files obtained from local dir.
;				If filenames not set, then orbit or trange keyword must
;					be set.
;	dir		string, directory where filenames can be found
;				If dir not set, default is "environvar" or local directory
;	environvar	string, name of environment variable to set "dir"
;				Used if filenames not set
;				Default environvar = '$FAST_CDF_HOME'
;	trange		trange[2], time range used to get files from index list
;	indexfile	string, complete path name for indexfile of times and filenames
;				Used if trange is set.
;				Default = indexfiledir+'/fa_k0_ees_files'
;				indexfiledir = '$CDF_INDEX_DIR' 
;	orbit		int, intarr, orbit(s) for file load
;	var		strarr(n) of cdf variable names
;			default=['el_0','el_90','el_180','el_low','el_high','JEe','Je']
;	dvar		strarr(n) of cdf dependent variable names
;			set dvar(n)='' if no dependent variable for variable
;			dvar must be same dimension as var
;			default=['el_en','el_en','el_en','el_low_pa','el_high_pa','','']
;	nodata		returns 1 if no data is found
;
;CREATED BY:	J. McFadden 96-9-8
;LAST MODIFICATION:  97-04-03
;MOD HISTORY:
;		96-09-24	corrections
;		97-03-04	get_fa_orbit call changed
;		97-03-13	orbit keyword can be an array, version number check
;		97-03-25	added label to Je,JEe
;		97-04-03	can load daily cdf files with "unix_time" rather than "TIME"
;		97-04-15	added no_orbit, nodata keywords; loads "MODEBAR"
;				
;-

pro load_fa_k0_ees, $
	filenames=filenames, $
	dir = dir, $
	environvar = environvar, $
	trange = trange, $
	indexfile = indexfile, $
	orbit = orbit, $
	var=var, $
	dvar=dvar, $
	nodata=nodata, $
        no_orbit = no_orbit                    

if not keyword_set(filenames) then begin
	if not keyword_set(environvar) then environvar = 'FAST_CDF_HOME'
	if not keyword_set(dir) then dir = getenv(environvar)
	if not keyword_set(dir) then begin
		print, ' Using local directory'
		dir=''
	endif else dir=dir+'/ees/'
	if not keyword_set(orbit) and not keyword_set(trange) then begin
		print,'Must enter filenames, trange, or orbit keyword!!'
		nodata=1
		return
	endif
	if keyword_set(orbit) then begin
		if dimen1(orbit) eq 1 then begin
			sorb = STRMID( STRCOMPRESS( orbit + 1000000, /RE), 2, 5)
			tmpnames = findfile(dir+'fa_k0_ees_'+sorb+'*.cdf',count=count)
			if count le 1 then filenames=tmpnames else begin
				print, ' Old versions of cdf files present, using latest version'
				filenames=tmpnames(count-1)
			endelse
		endif else begin
			filenames=strarr(dimen1(orbit))
			for a=0,dimen1(orbit)-1 do begin
				sorb = STRMID( STRCOMPRESS( orbit(a) + 1000000, /RE), 2, 5)
				tmpnames = findfile(dir+'fa_k0_ees_'+sorb+'*.cdf',count=count)
				if count le 1 then filenames(a)=tmpnames else begin
					print, ' Old versions of cdf files present, using latest version'
					filenames(a)=tmpnames(count-1)
				endelse
			endfor
		endelse
	endif else begin
		if keyword_set(trange) then begin
			if not keyword_set(indexfile) then begin
				indexfiledir = getenv('CDF_INDEX_DIR')	
				mfile = indexfiledir+'/fa_k0_ees_files'
			endif else mfile = indexfile
			get_file_names,filenames,TIME_RANGE=trange,MASTERFILE=mfile
		endif 
	endelse
endif else begin
	if keyword_set(dir) then filenames=dir+filenames
endelse

filenames=files_exist(filenames)
if filenames(0) eq '' then begin
	print,' Files do not exist!'
	nodata=1
	return
endif
	
if not keyword_set(var) then begin
	var=['el_0','el_90','el_180','el_low','el_high','JEe','Je']
	dvar=['el_en','el_en','el_en','el_low_pa','el_high_pa','','']
endif 
nvar=dimen1(var)
if not keyword_set(dvar) then dvar=strarr(nvar)
if dimen1(dvar) ne nvar then begin 
	print,' dvar and var must be same dimension'
	nodata=1
	return
endif

nfiles = dimen1(filenames)
	for d=0,nfiles-1 do begin
		print,'Loading file: ',filenames(d),'...'
		if cdf_var_exists(filenames(d),'TIME') then begin
			loadcdf,filenames(d),'TIME',tmp
		endif else if cdf_var_exists(filenames(d),'unix_time') then begin
			loadcdf,filenames(d),'unix_time',tmp
		endif else begin
			print,'ERROR: cdf structure element for time is missing!'
			nodata=1
			return
		endelse
		if d eq 0 then begin
			time=tmp 
		endif else begin
			ntime=dimen1(time)
			gaptime1=2.*time(ntime-1) - time(ntime-2)
			gaptime2=2*tmp(0) - tmp(1)
			time=[time,gaptime1,gaptime2,tmp]
		endelse
	endfor

for n=0,nvar-1 do begin

	for d=0,nfiles-1 do begin
		loadcdf,filenames(d),var(n),tmp
		if dvar(n) ne '' then loadcdf,filenames(d),dvar(n),tmpv
		if d eq 0 then begin
			tmp_tot  = tmp
			if dvar(n) ne '' then tmpv_tot = tmpv
		endif else begin
			gapdata=tmp_tot(0:1,*)
			gapdata(*,*)=!values.f_nan
			tmp_tot  = [tmp_tot,gapdata,tmp]
			if dvar(n) ne '' then tmpv_tot = [tmpv_tot,gapdata,tmpv]
		endelse
	endfor

	if dvar(n) ne '' then begin
		store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot,v:tmpv_tot}
		options,var(n),'spec',1	
		options,var(n),'panel_size',2
		zlim,var(n),1e6,1e9,1
		options,var(n),'ztitle','eV/cm!U2!N-s-sr-eV'
		if var(n) eq 'el_low' or var(n) eq 'el_high' then begin
			ylim,var(n),-100,280,0
			if var(n) eq 'el_low' then begin
				options,var(n),'ytitle','e- .1-1 keV!C!C Pitch Angle'
			endif else begin
				options,var(n),'ytitle','e- >1 keV!C!C Pitch Angle'
			endelse
		endif else begin
			ylim,var(n),3,40000,1
			if var(n) eq 'el_0' then begin
				options,var(n),'ytitle','e- 0!Uo!N-30!Uo!N!C!CEnergy (eV)'
			endif else begin
			if var(n) eq 'el_90' then begin
				options,var(n),'ytitle','e- 60!Uo!N-120!Uo!N!C!CEnergy (eV)'
			endif else begin
				options,var(n),'ytitle','e- 150!Uo!N-180!Uo!N!C!CEnergy (eV)'
			endelse
			endelse
		endelse
		options,var(n),'x_no_interp',1
		options,var(n),'y_no_interp',1
	endif else begin
		store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot}
		if var(n) eq 'JEe' then begin
			ylim,'JEe',.001,100,1
			options,'JEe','ytitle','e-!C!Cergs/cm!U2!N-s'
			options,'JEe','tplot_routine','pmplot'
		endif else begin
			ylim,'Je',1.e6,1.e10,1
			options,'Je','ytitle','e-!C!C1/cm!U2!N-s'
			options,'Je','tplot_routine','pmplot'
		endelse
	endelse

endfor

; Label 'JEe' and 'Je' plots and check version number
	ver=0
		options,'Je','labflag',1
		options,'JEe','labflag',1
		options,'Je','labels',['','']
		options,'JEe','labels',['','']
	for d=0,nfiles-1 do begin
		lastver=ver
		pos=strpos(filenames(d),'.cdf')
		ver=fix(strmid(filenames(d),pos-2,2))
		if ver ne lastver and lastver ne 0 then begin
			print,'Error: Incompatible versions of cdf files being appended!!!'
			options,'Je','labels',['','Incompatible!C  Versions!C  Appended']
			options,'JEe','labels',['','Incompatible!C  Versions!C  Appended']
			ver=-1
		endif
	endfor
	if ver ge 2 then begin
		options,'Je','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'Je','labflag',3
		options,'Je','labpos',[3.e9,6.e8]
		options,'JEe','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'JEe','labflag',3
		options,'JEe','labpos',[30.,4.]
	endif
	if ver ge 3 then begin
			options,'JEe','ytitle','e- >25eV!C!Cergs/cm!U2!N-s'
			options,'Je','ytitle','e- >25eV!C!C1/cm!U2!N-s'
	endif

; Get the orbit data


        get_data,'el_0',data=tmp
        orbit_file=fa_almanac_dir()+'/orbit/predicted'
        if not keyword_set(no_orbit) then begin
            get_fa_orbit,tmp.x,/time_array,orbit_file=orbit_file,/all
        endif
        
; Get modebar data if it exists

;	mbar4particles,orbit=orbit

; Zero the time range

	tplot_options,trange=[0,0]

nodata=0
return
end

