;+
;PROCEDURE:	load_fa_k0_ees_day
;PURPOSE:	
;	Load daily summary data from the FAST electron experiment into tplot structure.
;
;		Loads el_0	electon energy spectrogram, 0-30 pitch angle 
;		Loads el_90	electon energy spectrogram, 60-120 pitch angle 
;		Loads el_180	electon energy spectrogram, 150-180 pitch angle 
;		Loads el_low	electon pitch angle spectrogram, .1-1 keV energy 
;		Loads el_high	electon pitch angle spectrogram, > 1 keV energy 
;		Loads JEe	electon energy flux - mapped to 100 km, positive earthward 
;		Loads Je	electon particle flux  - mapped to 100 km, positive earthward
;
;		Loads Attitude and Orbit data from the cdf file
;	
;INPUT:	
;	filename	string, filename of daily cdf file to be loaded
;				File is obtained from "dir" if dir is set, 
;				otherwise file obtained from local dir.
;KEYWORDS:
;	dir		string, directory where filename can be found
;	var		strarr(n) of cdf variable names
;			default=['el_0','el_90','el_180','el_low','el_high','JEe','Je']
;	dvar		strarr(n) of cdf dependent variable names
;			set dvar(n)='' if no dependent variable for variable
;			dvar must be same dimension as var
;			default=['el_en','el_en','el_en','el_low_pa','el_high_pa','','']
;
;CREATED BY:	J. McFadden 97-04-18
;LAST MODIFICATION:  97-04-18
;MOD HISTORY:
;-

pro load_fa_k0_ees_day,filename, $
	dir = dir, $
	var=var, $
	dvar=dvar

if keyword_set(dir) then filename=dir+filename
filename=findfile(filename)
filename=filename(0)
if filename eq '' then begin
	print,' File does not exist!'
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

; Get time
	if cdf_var_exists(filename,'unix_time') then begin
		loadcdf,filename,'unix_time',tmp
	endif else begin
		print,'ERROR: cdf structure element for time is missing!'
		nodata=1
		return
	endelse
	time=tmp 

for n=0,nvar-1 do begin

	loadcdf,filename,var(n),tmp_tot
	if dvar(n) ne '' then loadcdf,filename,dvar(n),tmpv_tot
	tmp_tot(where(tmp_tot eq -1.e31)) = !values.f_nan
	
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
			options,'JEe','ytitle','e- >25eV!C!Cergs/cm!U2!N-s'
			options,'JEe','tplot_routine','pmplot'
		endif else begin
			ylim,'Je',1.e6,1.e10,1
			options,'Je','ytitle','e- >25eV!C!C1/cm!U2!N-s'
			options,'Je','tplot_routine','pmplot'
		endelse
	endelse

endfor

; Label 'JEe' and 'Je' plots 

	options,'Je','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
	options,'Je','labflag',3
	options,'Je','labpos',[3.e9,6.e8]
	options,'JEe','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
	options,'JEe','labflag',3
	options,'JEe','labpos',[30.,4.]


; Get the orbit data and other cdf quantities

loadcdf,filename,'quality_flag',var
;	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'quality_flag',x:time,y:var}
store_data,'quality_flag',data=tmp
ylim,'quality_flag',-1,2,0

loadcdf,filename,'post_gap_flag',var
;	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'post_gap_flag',x:time,y:var}
store_data,'post_gap_flag',data=tmp
ylim,'post_gap_flag',-1,2,0

loadcdf,filename,'fa_spin_ra',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'fa_spin_ra',x:time,y:var}
store_data,'fa_spin_ra',data=tmp
ylim,'fa_spin_ra',0,360,0

loadcdf,filename,'fa_spin_dec',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'fa_spin_dec',x:time,y:var}
store_data,'fa_spin_dec',data=tmp
ylim,'fa_spin_dec',-90,90,0

loadcdf,filename,'r',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'r GEI (km)',x:time,y:var}
store_data,'r',data=tmp
ylim,'r',-12000,12000,0

loadcdf,filename,'v',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'v GEI (km/s)',x:time,y:var}
store_data,'v',data=tmp
ylim,'v',-12,12,0

loadcdf,filename,'alt',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'ALT',x:time,y:var}
store_data,'ALT',data=tmp
ylim,'ALT',0,5000,0

loadcdf,filename,'flat',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'FLAT',x:time,y:var}
store_data,'FLAT',data=tmp
ylim,'FLAT',-90,90,0

loadcdf,filename,'flng',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'FLNG',x:time,y:var}
store_data,'FLNG',data=tmp
ylim,'FLNG',-180,180,0

loadcdf,filename,'mlt',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'MLT',x:time,y:var}
store_data,'MLT',data=tmp
ylim,'MLT',0,24,0

loadcdf,filename,'ilat',var
	var(where(var eq -1.e31)) = !values.f_nan
tmp={ytitle:'ILAT',x:time,y:var}
store_data,'ILAT',data=tmp
ylim,'ILAT',-90,90,0

loadcdf,filename,'orbit',var
	outofrange = min(var)
	var(where(var eq outofrange)) = !values.f_nan
tmp={ytitle:'ORBIT',x:time,y:var}
store_data,'ORBIT',data=tmp
ylim,'ORBIT',0,10000,0

; Zero the time range

	tplot_options,trange=[0,0]

return
end
