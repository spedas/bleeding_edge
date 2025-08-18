;+
;PROCEDURE:	get_pa_spec3d
;PURPOSE:	
;	Generates pitch angle vs. time spectrogram data structures for tplot
;INPUT:		
;	get_dat, 	a string that defines the 'routine' that returns a 2D or 3D data structure
;			if 'probe' keyword set, assumes routine = get_dat
;			if 'probe' keyword is not set, assumes routine = 'get_'+ get_dat
;				unless get_dat already includes 'get_', in which case routine = get_dat
;			for example, get_dat='thc_peir' then routine = 'get_thc_peir'
;			for example, get_dat='thm_sst_pser' then routine = 'thm_sst_pser'
;
;KEYWORDS:		
;	T1:		start time, seconds since 1970
;	T2:		end time, seconds since 1970		
;	ENERGY:		fltarr(2)		energy range to sum over
;	ERANGE:		intarr(2)		energy bin range to sum over
;	EBINS:		bytarr(dat.nenergy)	energy bins to sum over
;	gap_time: 	time gap big enough to signify a data gap 
;			(default 200 sec, 8 sec for FAST)
;	NO_DATA: 	returns 1 if no_data else returns 0
;	UNITS:		convert to these units if included
;	NAME:  		New name of the Data Quantity
;	BKG:  		A 3d data structure containing the background counts.
;	FLOOR:  	Sets the minimum value of any data point to sqrt(bkg).
;	MISSING: 	Value for bad data.
;	RETRACE: 	Set to number of retrace energy steps to be eliminated starting at energy step 0
;	CALIB:		Calib keyword passed on to get_"get_dat"_ts
;	EWEIGHT		Weights the energy bin average by bin energy width.
;	SHIFT90		If set true, pitch angle range is -90 to 270
;
;CREATED BY:	J.McFadden	  08-07-07
;VERSION:	1
;LAST MODIFICATION:  09-01-
;MOD HISTORY:
;		09-01-08	bkg keyword changed to work for Themis electron sst
;		09-01-08	probe keyword added for themis sst routines
;		09-01-08	changed loop to use index to allow for dat.valid=0 data in stored data
;		09-01-08	calib keyword no longer passed to routine
;
;NOTES:	  
;	Modified from get_pa_spec.pro used for 2-D data structures for FAST or Cluster/PEACE
;	get_pa_spec3d.pro converts 3-D data structures two 2D pitch angle data
;-

pro get_pa_spec3d,get_dat,  $
	T1=t1, $
	T2=t2, $
	ENERGY=en, $
	ERANGE=er, $
	EBINS=ebins, $
;	ANGLE=an, $
;	ARANGE=ar, $
;	BINS=bins, $
	gap_time=gap_time, $ 
	no_data=no_data, $
	units = units,  $
        name  = name, $
	bkg = bkg, $
        missing = missing, $
        floor = floor, $
        retrace = retrace, $
        CALIB = calib, $
	eweight = eweight, $
	shift90 = shift90, $
	_extra=_extra

;	Time how long the routine takes
ex_start = systime(1)

;	Set defaults for keywords, etc.

n = 0
all_same = 1

if strlowcase(strmid(get_dat,0,4)) eq 'get_' then begin
	routine = get_dat
	get_dat = strlowcase(strmid(get_dat,4,strlen(get_dat)))
endif else if keyword_set(probe) then begin
	routine = get_dat
endif else routine = 'get_'+get_dat 

if keyword_set(probe) then times = call_function(routine,probe=probe,/times) else times = call_function(routine,/times)
maxind = n_elements(times)-1

if keyword_set(t1) then tmpmax=min(abs(times-time_double(t1)),idx) else idx=1l
if keyword_set(t2) then tmpmax=min(abs(times-time_double(t2)),idxmax) else idxmax=maxind

if keyword_set(probe) then begin
	dat = call_function(routine,probe=probe,index=idx) 
	while (dat.valid eq 0 and idx lt idxmax) do begin
		idx = idx + 1
		dat = call_function(routine,probe=probe,index=idx)
	endwhile
endif else begin
	dat = call_function(routine,index=idx)
	while (dat.valid eq 0 and idx lt idxmax) do begin
		idx = idx + 1
		dat = call_function(routine,index=idx)
	endwhile
endelse

;if keyword_set(t1) then begin
;	t=t1
;	dat = call_function(routine,t,CALIB=calib)
;endif else begin
;	t = 1000             ; get first sample
;	dat = call_function(routine,t,CALIB=calib, /start)
;endelse
if dat.valid eq 0 then begin no_data = 1 & return & end $
else no_data = 0


ytitle = get_dat + '_pa_spec'
last_time = (dat.time+dat.end_time)/2.
nenergy = dat.nenergy
nmaxvar = dat.nbins

default_gap_time = 200
if dat.project_name eq 'FAST' then begin
	nmaxvar=64
	default_gap_time = 8.
endif
if strupcase(strmid(dat.project_name,0,6)) eq 'THEMIS' then begin
	nmaxvar=88
	default_gap_time = 13.
endif
if not keyword_set(gap_time) then gap_time = default_gap_time

maxpts = idxmax-idx+1000 < 300000l			; this limits a tplot str to < 77 MBytes
time   = dblarr(maxpts)
data   = fltarr(maxpts,nmaxvar)
var   = fltarr(maxpts,nmaxvar)
nvar = dat.nbins
nmax=nvar

if not keyword_set(units) then units = 'Counts'
if not keyword_set(missing) then missing = !values.f_nan



;	Collect the data - Main Loop
 
; May want to use the following lines when "index" is operational in FAST get* routines    
;times = call_function(routine,t,CALIB=calib, /times)
;for idx=0,n_elements(times)-1 do begin
;    if (dat.valid eq 0) or (n ge max) then  goto, continue  ; goto YUCK!


;while (dat.valid ne 0) and (n lt max) do begin
while (idx lt idxmax) and (n lt maxpts) do begin

if (dat.valid eq 1) then begin

	count = dat.nenergy

	if keyword_set(en) then begin
		er=thm_energy_to_ebin(dat,en-dat.charge*1.15*(dat.sc_pot-1.))
	endif
	if keyword_set(er) then begin
		ebins=bytarr(dat.nenergy)
		if er(0) gt er(1) then er=reverse(er)
		ebins(er(0):er(1))=1
	endif
	if not keyword_set(ebins) then begin
		ebins=bytarr(dat.nenergy)
		ebins(*)=1
	endif

	if keyword_set(retrace) then ebins(0:retrace-1)=0
	ind=where(ebins,count)

	if units eq 'Counts' then norm = 1 else norm = count
	if ind(0) ne -1 and keyword_set(eweight) then norm = total(dat.denergy(ind,0),1)

	if abs((dat.time+dat.end_time)/2.-last_time) ge gap_time then begin
		if n ge 2 then dbadtime = time(n-1) - time(n-2) else dbadtime = gap_time/2.
		time(n) = (last_time) + dbadtime
		data(n,*) = missing
		var(n,*) = missing
		n=n+1
		if (dat.time+dat.end_time)/2. gt time(n-1) + gap_time then begin
			time(n) = (dat.time+dat.end_time)/2. - dbadtime
			data(n,*) = missing
			var(n,*) = missing
			n=n+1
		endif
	endif

	if keyword_set(bkg) then dat = sub3d(dat,bkg)
	if keyword_set(units) then dat = conv_units(dat,units,_extra=_extra)


; calculate pitch angles
	if ind(0) ne -1 then begin
		cind = fix((max(ind)+min(ind))/2)
		th=reform(dat.theta(cind,*)/!radeg)
		ph=reform(dat.phi(cind,*)/!radeg)
		xx=cos(ph)*cos(th)
		yy=sin(ph)*cos(th)
		zz=sin(th)
		Bmag=(dat.magf(0)^2+dat.magf(1)^2+dat.magf(2)^2)^.5
		pitch=acos((dat.magf(0)*xx+dat.magf(1)*yy+dat.magf(2)*zz)/Bmag)*!radeg
;			if an(0) gt an(1) then an=reverse(an)
;			bins= pitch gt an(0) and pitch lt an(1)
;			if total(bins) eq 0 then begin
;				tmp=min(abs(pitch-(an(0)+an(1))/2.),ind)
;				bins(ind)=1
;			endif
	endif

	nvar = dat.nbins
	if nvar gt nmax then nmax = nvar
	time(n)   = (dat.time+dat.end_time)/2.
	if ind(0) eq -1 then begin
		tmpdata = total( dat.data(0,*), 1)
		tmpdata(*) = 0
		tmpvar = total( dat.theta(0,*), 1)
;		if keyword_set(shift90) then tmpvar = $
;		((360.*(tmpvar/360.-floor(tmpvar/360.)) + 90.) mod 360.) -90.
	endif else begin
		if keyword_set(eweight) then begin
			tmpdata = total( dat.data(ind,*)*dat.denergy(ind,*), 1)/norm
		endif else begin
			tmpdata = total( dat.data(ind,*), 1)/norm
		endelse
		sortind = sort(pitch)
		tmpvar = pitch(sortind)
		tmpdata = tmpdata(sortind)
;		if keyword_set(shift90) then tmpvar = $
;		((360.*(tmpvar/360.-floor(tmpvar/360.)) + 90.) mod 360.) -90.
	endelse
; Shift the angle array so that angles increase monotonicly with index 
; -- needed for tplot
	minvar = min(tmpvar,indminvar)
	if (indminvar gt 1) then begin
		if tmpvar(0) gt tmpvar(1) then begin
			tmpvar=reverse(shift(tmpvar,-indminvar-1))
			tmpdata=reverse(shift(tmpdata,-indminvar-1))
		endif else begin
			tmpvar=shift(tmpvar,-indminvar)
			tmpdata=shift(tmpdata,-indminvar)
		endelse
	endif else begin
		if tmpvar(2) gt tmpvar(3) then begin
			tmpvar=reverse(shift(tmpvar,-indminvar-1))
			tmpdata=reverse(shift(tmpdata,-indminvar-1))
		endif else begin
			tmpvar=shift(tmpvar,-indminvar)
			tmpdata=shift(tmpdata,-indminvar)
		endelse
	endelse
	var(n,0:nvar-1) = tmpvar
	data(n,0:nvar-1) = tmpdata

; test the following lines, the 96-6-19 version of tplot did not work with !values.f_nan
;	if nvar lt nmaxvar then data(n,nvar:nmaxvar-1) = !values.f_nan
;	if nvar lt nmaxvar then var(n,nvar:nmaxvar-1) = !values.f_nan
	if nvar lt nmaxvar then data(n,nvar:nmaxvar-1) = data(n,nvar-1)
	if nvar lt nmaxvar then var(n,nvar:nmaxvar-1) = 1.5*var(n,nvar-1)-.5*var(n,nvar-2)

	if (all_same eq 1) then begin
		if dimen1(where(var(n,0:nvar-1) ne var(0,0:nvar-1))) gt 1 then all_same = 0
	endif
	last_time = time(n)
	n=n+1

endif else begin
	dprint, 'Invalid packet, dat.valid ne 1, at: ',time_to_str(dat.time)
endelse
	idx=idx+1
	if keyword_set(probe) then dat = call_function(routine,probe=probe,index=idx) else dat = call_function(routine,index=idx)
	
;	dat = call_function(routine,t,CALIB=calib,/ad)
;	dat = call_function(routine,t,CALIB=calib,index=idx)
;	if dat.valid ne 0 then if dat.time gt tmax then dat.valid=0



	
endwhile
;endfor
;continue:






;	Store the data

	if count ne nenergy then ytitle = ytitle+'_'+strtrim(count,2)
	if keyword_set(name) eq 0 then name=ytitle else ytitle = name
	ytitle = ytitle+' ('+units+')'

data = data(0:n-1,0:nmax-1)
var = var(0:n-1,0:nmax-1)







dprint, 'all_same=',all_same
;labels =''
; The following has be removed so that FAST summary cdf files contain both arrays
;if all_same then begin
;	var = reform(var(0,*))
;	labels = strtrim( round(var) ,2)+ ' deg'
;endif

time = time(0:n-1)

if keyword_set(t1) then begin
	ind=where(time ge t1)
	time=time(ind)
	data=data(ind,*)
	var=var(ind,*)
endif
if keyword_set(t2) then begin
	ind=where(time le t2)
	time=time(ind)
	data=data(ind,*)
	var=var(ind,*)
endif

;datastr = {ztitle:units,x:time,y:data,v:var,  $
;	labels:labels,	$
;    ylog:0,panel_size:2.}
datastr = {x:time,y:data,v:var}
store_data,name,data=datastr

ex_time = systime(1) - ex_start
dprint,string(ex_time)+' seconds execution time.'
dprint, 'Number of data points = ',n

return

end
