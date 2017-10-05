;+
;PROCEDURE:	get_en_spec
;PURPOSE:	
;	Generates energy-time spectrogram data structures for tplot
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
;	ANGLE:		fltarr(2),fltarr(4)	angle range to sum over
;	ARANGE:		intarr(2)		bin range to sum over
;	BINS:		bytarr(dat.nbins)	bins to sum over
;	gap_time: 	time gap big enough to signify a data gap 
;			(default 200 sec, 8 sec for FAST)
;	NO_DATA: 	returns 1 if no_data else returns 0
;	UNITS:		convert to these units if included
;	NAME:  		New name of the Data Quantity, default = get_dat + '_en_spec'
;	BKG:  		A 3d data structure containing the background counts 
;			If bkg=1, it will run themis background subtraction routine
;	FLOOR:  	Sets the minimum value of any data point to sqrt(bkg).
;	MISSING: 	value for bad data.
;	RETRACE: 	Set to number of retrace energy steps to be eliminated starting at energy step 0
;	CALIB:		Calib keyword passed on to get_dat -- no longer used
;	PROBE:		probe keyword passed on to get_dat -- used by themis sst routines
;
;
;
;CREATED BY:	J.McFadden
;VERSION:	1
;LAST MODIFICATION:  97/03/04
;MOD HISTORY:
;		97/03/04	T1,T2 keywords added
;		97/05/22	CALIB keyword added
;		08/07/10	bkg keyword changed to work for Themis ion ESA
;		08/07/10	averaging routine changed to weight different angle bins by dat.gf 
;		08/12/31	bkg keyword changed to work for Themis electron sst
;		08/12/31	probe keyword added for themis sst routines
;		09/01/05	changed loop to use index to allow for dat.valid=0 data in stored data
;		09/01/05	calib keyword no longer passed to routine
;		09/04/16	bkg keyword removed for Themis electron sst, assume bkg removal is part of get_th?_pse?
;
;
;NOTES:	  
;	Current version only works for FAST and THEMIS
;-

pro get_en_spec,get_dat,  $
	T1=t1, $
	T2=t2, $
;	ENERGY=en, $
;	ERANGE=er, $
;	EBINS=ebins, $
	ANGLE=an, $
	ARANGE=ar, $
	BINS=bins, $
	gap_time=gap_time, $ 
	no_data=no_data, $
	units = units,  $
        name  = name, $
	bkg = bkg, $
        missing = missing, $
        floor = floor, $
        retrace = retrace, $
        CALIB = calib, $
	probe = probe



;	Time how long the routine takes
ex_start = systime(1)

;	Set defaults for keywords, etc.

n = 0l
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
;	if keyword_set(calib) then dat = call_function(routine,t,CALIB=calib) $
;		else if keyword_set(probe) then dat = call_function(routine,t,probe=probe,index=idx) $
;		else if routine eq 'get_fa_sebs' then dat = call_function(routine,t,/first) $
;		else dat = call_function(routine,t)
;endif else begin
;	t = 1000             ; get first sample
;	idx=0
;	if keyword_set(calib) then dat = call_function(routine,t,CALIB=calib,/start) $
;		else if keyword_set(probe) then dat = call_function(routine,probe=probe,index=idx) $
;		else if routine eq 'get_fa_sebs' then dat = call_function(routine,t,/first) $
;		else dat = call_function(routine,t,/start)
;endelse
;if dat.valid eq 0 then begin no_data = 1 & return & end $
;else no_data = 0


ytitle = get_dat + '_en_spec'
last_time = (dat.time+dat.end_time)/2.
nbins = dat.nbins
nmaxvar = dat.nenergy

default_gap_time = 200.
if dat.project_name eq 'FAST' then begin
	nmaxvar=96
	default_gap_time = 8.
endif
if strupcase(strmid(dat.project_name,0,6)) eq 'THEMIS' then begin
	nmaxvar=32
	default_gap_time = 13.
endif
if not keyword_set(gap_time) then gap_time = default_gap_time

maxpts = idxmax-idx+1000 < 300000l			; this limits a tplot str to < 77 MBytes
time   = dblarr(maxpts)
data   = fltarr(maxpts,nmaxvar)
var   = fltarr(maxpts,nmaxvar)
nvar = dat.nenergy
nmax=nvar

if not keyword_set(units) then units = 'Counts'
if not keyword_set(missing) then missing = !values.f_nan



;	Collect the data - Main Loop
    
; May want to use the following lines when "index" is operational in FAST get* routines    
;times = call_function(routine,t,CALIB=calib, /times)
;for idx=0,n_elements(times)-1 do begin
;    if (dat.valid eq 0) or (n ge maxpts) then  goto, continue  ; goto YUCK!


;while (dat.valid ne 0) and (n lt maxpts) do begin
while (idx lt idxmax) and (n lt maxpts) do begin

if (dat.valid eq 1) then begin

	if ndimen(dat.data) eq ndimen(dat.bins) then dat.data=dat.data*dat.bins
	count = dat.nbins
	if keyword_set(an) then begin
		str_element,dat,'PHI',INDEX=tf_phi
		if tf_phi lt 0 then bins=angle_to_bins(dat,an)
		if tf_phi gt 0 then begin
			th=reform(dat.theta(0,*)/!radeg)
			ph=reform(dat.phi(fix(dat.nenergy/2),*)/!radeg)
			xx=cos(ph)*cos(th)
			yy=sin(ph)*cos(th)
			zz=sin(th)
			Bmag=(dat.magf(0)^2+dat.magf(1)^2+dat.magf(2)^2)^.5
			pitch=acos((dat.magf(0)*xx+dat.magf(1)*yy+dat.magf(2)*zz)/Bmag)*!radeg
			if an(0) gt an(1) then an=reverse(an)
			bins= pitch gt an(0) and pitch lt an(1)
			if total(bins) eq 0 then begin
				tmp=min(abs(pitch-(an(0)+an(1))/2.),ind)
				bins(ind)=1
			endif
		endif
	endif
	if keyword_set(ar) then begin
		nb=dat.nbins
		bins=bytarr(nb)
		if ar(0) gt ar(1) then begin
			bins(ar(0):nb-1)=1
			bins(0:ar(1))=1
		endif else begin
			bins(ar(0):ar(1))=1
		endelse
	endif
; Set the "count" to the number of bins summed over

	if not keyword_set(bins) then ind=indgen(dat.nbins) else ind=where(bins,count)
	if max(ind) gt dat.nbins-1 then ind=-1
	if units eq 'Counts' or units eq 'counts' then norm = 1 else norm = count

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

	if keyword_set(bkg) then begin
; sub3d requires bkg to be the subtraction array -- sub3d is a general routine and works similar to the pse routine
		if ndimen(bkg) ne 0 then dat = sub3d(dat,bkg) $
;		else if dat.UNITS_PROCEDURE eq 'thm_convert_esa_units' then dat=thm_esa_bgnd_sub(dat) $ ; old routine
		else if dat.UNITS_PROCEDURE eq 'thm_convert_esa_units' and dat.charge gt 0. then dat=thm_pei_bkg_sub(dat) $ 
		else if dat.UNITS_PROCEDURE eq 'thm_convert_esa_units' and dat.charge lt 0. then dat=thm_pee_bkg_sub(dat) 
;		else if strmid(dat.DATA_NAME,0,12) eq 'SST Electron' then dat=thm_pse_bkg_sub(dat) ; added to get_routine
	endif
	if keyword_set(units) then dat = conv_units(dat,units)

	nvar = dat.nenergy
	if nvar gt nmax then nmax = nvar
	time(n)   = (dat.time+dat.end_time)/2.
	if ind(0) ne -1 then begin
		if ndimen(dat.data) gt 1 and n_elements(ind) gt 1 then begin
			if units eq 'Counts' or units eq 'counts' then begin
				data(n,0:nvar-1) = total( dat.data(*,ind), 2)/norm
				var(n,0:nvar-1) = total( dat.energy(*,ind), 2)/count
			endif else begin
				data(n,0:nvar-1) = total( dat.data(*,ind)*dat.gf(*,ind), 2)/total(dat.gf(*,ind),2)
				var(n,0:nvar-1) = total( dat.energy(*,ind), 2)/count
			endelse
		endif else if ndimen(dat.data) gt 1 then begin
			data(n,0:nvar-1) = dat.data(*,ind)/norm
			var(n,0:nvar-1) = dat.energy(*,ind)/count
		endif else begin
			data(n,0:nvar-1) = dat.data(*)
			var(n,0:nvar-1) = dat.energy(*)
		endelse
	endif else begin
		data(n,0:nvar-1) = 0
		var(n,0:nvar-1) =  dat.energy(*,0)
	endelse

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
	print,'Invalid packet, dat.valid ne 1, at: ',time_to_str(dat.time)
endelse
	idx=idx+1
	if keyword_set(probe) then dat = call_function(routine,probe=probe,index=idx) else dat = call_function(routine,index=idx)

;	if keyword_set(probe) then idx=idx+1
;	if keyword_set(calib) then dat = call_function(routine,t,CALIB=calib,/ad) $
;		else if keyword_set(probe) then dat = call_function(routine,probe=probe,index=idx) $
;		else dat = call_function(routine,t,/ad)
;;	dat = call_function(routine,t,CALIB=calib,index=idx)
;	if dat.valid ne 0 then if dat.time gt tmax then dat.valid=0

endwhile
;endfor
;continue:






;	Store the data

	if count ne nbins then ytitle = ytitle+'_'+strtrim(count,2)
	if keyword_set(name) eq 0 then name=ytitle else ytitle = name
	ytitle = ytitle+' ('+units+')'

if not keyword_set(retrace) then begin
;	If you want to plot the retrace, set the retrace flag to 1.
	data = data(0l:n-1,0:nmax-1)
	var = var(0l:n-1,0:nmax-1)
endif else begin
	data = data(0l:n-1,retrace:nmax-1)
	var = var(0l:n-1,retrace:nmax-1)
endelse


if not all_same then print,'all_same=',all_same
;labels=''
; The following has be removed so that FAST summary cdf files contain both arrays
;if all_same then begin
;	var = reform(var(0,*))
;	labels = strtrim( round(var) ,2)+ ' eV'
;endif

time = time(0l:n-1)

print,'get_en_spec time range = ',time_string(minmax(time))
;if keyword_set(t1) then begin
;	ind=where(time ge t1,count)
;	print,count
;	if count ne 0 then begin
;		time=time(ind) 
;		data=data(ind,*)
;		var=var(ind,*)
;	endif else return
;endif
;if keyword_set(t2) then begin
;	ind=where(time le t2,count)
;	print,count
;	if count ne 0 then begin
;		time=time(ind)
;		data=data(ind,*)
;		var=var(ind,*)
;	endif else return
;endif

; remove any negative values caused by background subtractions
	data=data>0.

;datastr = {ztitle:units,x:time,y:data,v:var,  $
;	labels:labels,	$
;    ylog:1,panel_size:2.}
datastr = {x:time,y:data,v:var}
store_data,name,data=datastr

ex_time = systime(1) - ex_start
message,string(ex_time)+' seconds execution time.',/cont,/info
print,'Number of data points = ',n

return

end
