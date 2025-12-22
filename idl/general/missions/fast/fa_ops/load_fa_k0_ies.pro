;+
;PROCEDURE:	load_fa_k0_ies
;PURPOSE:	
;	Load summary data from the FAST ion experiment into tplot structure.
;
;		Loads ion_0	ion energy spectrogram, 0-30 pitch angle 
;		Loads ion_90	ion energy spectrogram, 40-140 pitch angle 
;		Loads ion_180	ion energy spectrogram, 150-180 pitch angle 
;		Loads ion_low	ion pitch angle spectrogram, .05-1 keV energy 
;		Loads ion_high	ion pitch angle spectrogram, > 1 keV energy 
;		Loads JEi	ion energy flux - mapped to 100 km, positive earthward 
;		Loads Ji	ion particle flux - mapped to 100 km, positive earthward 
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
;				Default = indexfiledir+'/fa_k0_ies_files'
;				indexfiledir = '$CDF_INDEX_DIR' 
;	orbit		int, intarr, orbit(s) for file load
;	var		strarr(n) of cdf variable names
;			default=['ion_0','ion_90','ion_180','ion_low','ion_high','JEi','Ji']
;	dvar		strarr(n) of cdf dependent variable names
;			set dvar(n)='' if no dependent variable for variable
;			dvar must be same dimension as var
;			default=['ion_en','ion_en','ion_en','ion_low_pa','ion_high_pa','','']
;
;CREATED BY:	J. McFadden 96-9-8
;LAST MODIFICATION:	97-04-03
;MOD HISTORY:
;		96-09-24	corrections
;		97-03-04	get_fa_orbit call changed
;		97-03-13	orbit keyword can be an array, version number check
;		97-03-25	added label to Ji,JEi
;		97-04-03	can load daily cdf files with "unix_time" rather than "TIME"
;-

pro load_fa_k0_ies, $
	filenames=filenames, $
	dir = dir, $
	environvar = environvar, $
	trange = trange, $
	indexfile = indexfile, $
	orbit = orbit, $
	var=var, $
        dvar=dvar,  $
        no_orbit = no_orbit

if not keyword_set(filenames) then begin
	if not keyword_set(environvar) then environvar = 'FAST_CDF_HOME'
	if not keyword_set(dir) then dir = getenv(environvar)
	if not keyword_set(dir) then begin
		print, ' Using local directory'
		dir=''
	endif else dir=dir+'/ies/'
	if not keyword_set(orbit) and not keyword_set(trange) then begin
		print,'Must enter filenames, trange, or orbit keyword!!'
		return	
	endif
	if keyword_set(orbit) then begin
		if dimen1(orbit) eq 1 then begin
			sorb = STRMID( STRCOMPRESS( orbit + 1000000, /RE), 2, 5)
			tmpnames = findfile(dir+'fa_k0_ies_'+sorb+'*.cdf',count=count)
			if count le 1 then filenames=tmpnames else begin
				print, ' Old versions of cdf files present, using latest version'
				filenames=tmpnames(count-1)
			endelse
		endif else begin
			filenames=strarr(dimen1(orbit))
			for a=0,dimen1(orbit)-1 do begin
				sorb = STRMID( STRCOMPRESS( orbit(a) + 1000000, /RE), 2, 5)
				tmpnames = findfile(dir+'fa_k0_ies_'+sorb+'*.cdf',count=count)
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
				mfile = indexfiledir+'/fa_k0_ies_files'
			endif else mfile = indexfile
			get_file_names,filenames,TIME_RANGE=trange,MASTERFILE=mfile
		endif 
	endelse
endif else begin
	if keyword_set(dir) then filenames=dir+filenames
endelse

if not keyword_set(var) then begin
	var=['ion_0','ion_90','ion_180','ion_low','ion_high','JEi','Ji']
	dvar=['ion_en','ion_en','ion_en','ion_low_pa','ion_high_pa','','']
endif 
nvar=dimen1(var)
if not keyword_set(dvar) then dvar=strarr(nvar)
if dimen1(dvar) ne nvar then begin 
	print,' dvar and var must be same dimension'
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
		zlim,var(n),1e4,1e8,1
		options,var(n),'ztitle','eV/cm!U2!N-s-sr-eV'
		if var(n) eq 'ion_low' or var(n) eq 'ion_high' then begin
			ylim,var(n),-100,280,0
			if var(n) eq 'ion_low' then begin
				options,var(n),'ytitle','ions .05-1 keV!C!C Pitch Angle'
			endif else begin
				options,var(n),'ytitle','ions >1 keV!C!C Pitch Angle'
			endelse
		endif else begin
			ylim,var(n),3,40000,1
			if var(n) eq 'ion_0' then begin
				options,var(n),'ytitle','ions 0!Uo!N-30!Uo!N!C!CEnergy (eV)'
			endif else begin
			if var(n) eq 'ion_90' then begin
				options,var(n),'ytitle','ions 40!Uo!N-140!Uo!N!C!CEnergy (eV)'
			endif else begin
				options,var(n),'ytitle','ions 150!Uo!N-180!Uo!N!C!CEnergy (eV)'
			endelse
			endelse
		endelse
		options,var(n),'x_no_interp',1
		options,var(n),'y_no_interp',1
	endif else begin
		store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot}
		if var(n) eq 'JEi' then begin
			ylim,'JEi',1.e-5,1,1
			options,'JEi','ytitle','ions!C!Cergs/cm!U2!N-s'
			options,'JEi','tplot_routine','pmplot'
		endif else begin
			ylim,'Ji',1.e5,1.e9,1
			options,'Ji','ytitle','ions!C!C1/cm!U2!N-s'
			options,'Ji','tplot_routine','pmplot'
		endelse
	endelse

endfor

; Label 'JEi' and 'Ji' plots and check version number
	ver=0
		options,'Ji','labflag',1
		options,'JEi','labflag',1
		options,'Ji','labels',['','']
		options,'JEi','labels',['','']
	for d=0,nfiles-1 do begin
		lastver=ver
		pos=strpos(filenames(d),'.cdf')
		ver=fix(strmid(filenames(d),pos-2,2))
		if ver ne lastver and lastver ne 0 then begin
			print,'Error: Incompatible versions of cdf files being appended!!!'
			options,'Ji','labels',['','Incompatible!C  Versions!C  Appended']
			options,'JEi','labels',['','Incompatible!C  Versions!C  Appended']
			ver=-1
		endif
	endfor
	if ver ge 2 then begin
		options,'Ji','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'Ji','labflag',3
		options,'Ji','labpos',[3.e8,6.e7]
		options,'JEi','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'JEi','labflag',3
		options,'JEi','labpos',[.30,.04]
	endif
	if ver ge 3 then begin
			options,'JEi','ytitle','i+ >20eV!C!Cergs/cm!U2!N-s'
			options,'Ji','ytitle','i+ >20eV!C!C1/cm!U2!N-s'
	endif

; Get the orbit data

	get_data,'ion_0',data=tmp
	orbit_file=fa_almanac_dir()+'/orbit/predicted'
        if not keyword_set(no_orbit) then begin
            get_fa_orbit,tmp.x,/time_array,orbit_file=orbit_file,/all
        endif

; Zero the time range

	tplot_options,trange=[0,0]

return
end


