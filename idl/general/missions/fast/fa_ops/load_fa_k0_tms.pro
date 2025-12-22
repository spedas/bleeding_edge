;+
;PROCEDURE:	load_fa_k0_tms
;PURPOSE:
;	Load summary data from the FAST TEAMS experiment into tplot structure.
;
;	Loads H+ 	Hydrogen Differential Energy Flux vs Energy, 0-360    deg pitch angle
;	Loads He+ 	Helium Differential Energy Flux vs Energy, 0-360    deg pitch angle
;	Loads O+	Oxygen   Differential Energy Flux vs Energy, 0-360  deg pitch angle
;	Loads H+_low	Hydrogen Differential Energy Flux vs Pitch Angle, .01-1 keV
;	Loads H+_high	Hydrogen Differential Energy Flux vs Pitch Angle, > 1 keV
;	Loads He+_low	Helium Differential Energy Flux vs Pitch Angle, .01-1 keV
;	Loads He+_high	Helium Differential Energy Flux vs Pitch Angle, > 1 keV
;	Loads O+_low	Oxygen   Differential Energy Flux vs Pitch Angle, .01-1 keV
;	Loads O+_high	Oxygen   Differential Energy Flux vs Pitch Angle, > 1 keV
;	Loads hm	MassSpectrum Counts Rate vs Mass, 1eV - 12keV, 4*Pi angles
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
;				Default = indexfiledir+'/fa_k0_tms_files'
;				indexfiledir = '$CDF_INDEX_DIR'
;	orbit		int, orbit for file load
;	var		strarr(n) of cdf variable names
;			default=['H+','He+','O+','H+_low','H+_high','He+_low',$
;				'He+_high','O+_low','O+_high']
;	dvar		strarr(n) of cdf dependent variable names
;			set dvar(n)='' if no dependent variable for variable
;			dvar must be same dimension as var
;			default=['H+_en','He+_en','O+_en','H+_low_pa',$
;				'H+_high_pa','He+_low_pa','He+_high_pa',$
;				'O+_low_pa','O+_high_pa']
;
;	tplot		if set, loads hm data from "filenames".tplot
;			*.tplot files are assumed to be in the cdf dir
;
;CREATED BY:	J. McFadden 96-10-6
;VERSION: 1.03
;LAST MODIFICATION:	97-06-04
;MODIFICATION HISTORY:
;		97-06-04	added He+ to cdf's
;		97-03-25	get_fa_orbit call changed
;		97-03-25	orbit keyword can be an array, version number check
;-

pro load_fa_k0_tms, $
	filenames=filenames, $
	dir = dir, $
	environvar = environvar, $
	trange = trange, $
	indexfile = indexfile, $
	orbit = orbit, $
	var=var, $
	dvar=dvar, $
        tplot=tplot, $
        no_orbit = no_orbit

if not keyword_set(filenames) then begin
	if not keyword_set(environvar) then environvar = 'FAST_CDF_HOME'
	if not keyword_set(dir) then dir = getenv(environvar)
	if not keyword_set(dir) then begin
		print, ' Using local directory'
		dir=''
	endif else dir=dir+'/tms/'
	if not keyword_set(orbit) and not keyword_set(trange) then begin
		print,'Must enter filenames, trange, or orbit keyword!!'
		return
	endif
	if keyword_set(orbit) then begin
		if dimen1(orbit) eq 1 then begin
			sorb = STRMID( STRCOMPRESS( orbit + 1000000, /RE), 2, 5)
			tmpnames = findfile(dir+'fa_k0_tms_'+sorb+'*.cdf',count=count)
			if count le 1 then filenames=tmpnames else begin
				print, ' Old versions of cdf files present, using latest version'
				filenames=tmpnames(count-1)
			endelse
		endif else begin
			filenames=strarr(dimen1(orbit))
			for a=0,dimen1(orbit)-1 do begin
				sorb = STRMID( STRCOMPRESS( orbit(a) + 1000000, /RE), 2, 5)
				tmpnames = findfile(dir+'fa_k0_tms_'+sorb+'*.cdf',count=count)
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
				mfile = indexfiledir+'/fa_k0_tms_files'
			endif else mfile = indexfile
			get_file_names,filenames,TIME_RANGE=trange,MASTERFILE=mfile
		endif
	endelse
endif else begin
	if keyword_set(dir) then filenames=dir+filenames
endelse

if not keyword_set(var) then begin
    first = 1
    for i=0, n_elements(filenames) - 1 do begin
        test_id=cdf_open(filenames(i))
        result = cdf_inquire(test_id)
        if first then begin
            nzvars = result.nzvars
            first = 0
        endif else if nzvars ne result.nzvars then begin
            print, 'load_fa_k0_tms.pro: The number of CDF variables must be the same for ' 
            print, '     all files given in the filenames keyword'
            print, '     First file contained: ', nzvars, ' variables'
            print, '     File: '+ filenames(i) + ' contains: ', $
              result.nzvars , ' variables'
            return
        endif

        if result.nzvars ge 14 then begin ; includes He+
            have_he_plus=1
            var=['H+','He+','O+','H+_low','H+_high','He+_low','He+_high',$
                 'O+_low','O+_high']
            dvar=['H+_en','He+_en','O+_en','H+_low_pa','H+_high_pa',$
                  'He+_low_pa','He+_high_pa','O+_low_pa','O+_high_pa']
        endif else begin        ; old file--H+ and O+ only
            have_he_plus=0
            var=['H+','O+','H+_low','H+_high','O+_low','O+_high']
            dvar=['H+_en','O+_en','H+_low_pa','H+_high_pa',$
                  'O+_low_pa','O+_high_pa']
        endelse
        cdf_close, test_id
    endfor

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
		loadcdf,filenames(d),'TIME',tmp
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
		print,dvar(n)
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
	endif else begin
		store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot}
	endelse

endfor

; Hydrogen, Helium, and Oxygen differential energy flux - energy spectrograms

	options,'H+','spec',1
	zlim,'H+',1e2,1e7,1
	ylim,'H+',1,10000,1
	options,'H+','ytitle','H+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
	options,'H+','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'H+','x_no_interp',1
	options,'H+','y_no_interp',1
	options,'H+','panel_size',2

        if  have_he_plus  then begin
            options,'He+','spec',1
            zlim,'He+',1e2,1e7,1
            ylim,'He+',1,10000,1
            options,'He+','ytitle','He+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
            options,'He+','ztitle','eV/cm!U2!N-s-sr-eV'
            options,'He+','x_no_interp',1
            options,'He+','y_no_interp',1
            options,'He+','panel_size',2
        endif 
        
	options,'O+','spec',1
	zlim,'O+',1e2,1e7,1
	ylim,'O+',1,10000,1
	options,'O+','ytitle','O+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
	options,'O+','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'O+','x_no_interp',1
	options,'O+','y_no_interp',1
	options,'O+','panel_size',2

; Hydrogen differential energy flux - angle spectrograms

	options,'H+_low','spec',1
	zlim,'H+_low',1e2,1e7,1
	ylim,'H+_low',-100,280,0
	options,'H+_low','ytitle','H+ .01-1keV !C!CPitch Angle'
	options,'H+_low','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'H+_low','x_no_interp',1
	options,'H+_low','y_no_interp',1
	options,'H+_low','panel_size',2

	options,'H+_high','spec',1
	zlim,'H+_high',1e2,1e7,1
	ylim,'H+_high',-100,280,0
	options,'H+_high','ytitle','H+ >1keV !C!CPitch Angle'
	options,'H+_high','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'H+_high','x_no_interp',1
	options,'H+_high','y_no_interp',1
	options,'H+_high','panel_size',2

; Helium differential energy flux - angle spectrograms

        if  have_he_plus  then begin
            options,'He+_low','spec',1
            zlim,'He+_low',1e2,1e7,1
            ylim,'He+_low',-100,280,0
            options,'He+_low','ytitle','He+ .01-1keV !C!CPitch Angle'
            options,'He+_low','ztitle','eV/cm!U2!N-s-sr-eV'
            options,'He+_low','x_no_interp',1
            options,'He+_low','y_no_interp',1
            options,'He+_low','panel_size',2
        
            options,'He+_high','spec',1
            zlim,'He+_high',1e2,1e7,1
            ylim,'He+_high',-100,280,0
            options,'He+_high','ytitle','He+ >1keV !C!CPitch Angle'
            options,'He+_high','ztitle','eV/cm!U2!N-s-sr-eV'
            options,'He+_high','x_no_interp',1
            options,'He+_high','y_no_interp',1
            options,'He+_high','panel_size',2
        endif

; Oxygen differential energy flux - angle spectrograms

	options,'O+_low','spec',1
	zlim,'O+_low',1e2,1e7,1
	ylim,'O+_low',-100,280,0
	options,'O+_low','ytitle','O+ .01-1keV !C!CPitch Angle'
	options,'O+_low','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'O+_low','x_no_interp',1
	options,'O+_low','y_no_interp',1
	options,'O+_low','panel_size',2

	options,'O+_high','spec',1
	zlim,'O+_high',1e2,1e7,1
	ylim,'O+_high',-100,280,0
	options,'O+_high','ytitle','O+ >1keV !C!CPitch Angle'
	options,'O+_high','ztitle','eV/cm!U2!N-s-sr-eV'
	options,'O+_high','x_no_interp',1
	options,'O+_high','y_no_interp',1
	options,'O+_high','panel_size',2


if keyword_set(tplot) and keyword_set(orbit) then begin

	tplotfile_environvar = 'FAST_TPLOTFILE_HOME'
	dir_tplotfile = getenv(tplotfile_environvar)
	if not keyword_set(dir_tplotfile) then dir_tplotfile='./' $
		else dir_tplotfile = dir_tplotfile + '/tms'
	if dimen1(orbit) eq 1 then begin
		output=fa_output_path(dir_tplotfile,'k0','hm',orbit,'','tplot')
	endif else begin
		output=strarr(dimen1(orbit))
		for a=0,dimen1(orbit)-1 do begin
			output(a)=fa_output_path(dir_tplotfile,'k0','hm',orbit(a),'','tplot')
		endfor
	endelse
;	tplot_file.pro needs to be modified to allow appending of data
;	the following will only store the last orbit's "hm" data
	tplot_file,'hm',output,/restore
	options,'hm','spec',1
	zlim,'hm',1e-2,1e5,1
;	ylim,'hm',0,75,0
	ylim,'hm',.5,65.,1
	options,'hm','ztitle', 'counts/sec'
	options,'hm','ytitle', 'mass (mass unit)'
	options,'hm','x_no_interp',1
	options,'hm','y_no_interp',1

endif

; Get the orbit data

	get_data,'H+',data=tmp
	orbit_file=fa_almanac_dir()+'/orbit/predicted'
        if not keyword_set(no_orbit) then  $
          get_fa_orbit,tmp.x,/time_array,orbit_file=orbit_file,/all

; Zero the time range

	tplot_options,trange=[0,0]

return
end
