;+
;PROCEDURE:	get_pa_spec_ts
;PURPOSE:	
;	Generates pitch angle vs. time spectrogram data structures for tplot
;INPUT:		
;	get_dat, 	a string (either 'fa_ees','fa_eeb', ...)
;			where get_'string'_ts returns a 2D or 3D 
;			array of data structures
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
;	EWEIGHT		Weights the energy bin average by bin energy width.
;	SHIFT90		If set true, pitch angle range is -90 to 270
;	CALIB:		Calib keyword passed on to get_"get_dat"_ts
;	n_get_pts: 	Number of points in the array of structures formed by get_"get_dat"_ts, default=200.
;
;CREATED BY:	J.McFadden
;VERSION:	1
;LAST MODIFICATION:  97/05/21
;MOD HISTORY:
;		97/05/15	Variation on get_pa_spec.pro 
;		97/07/23	fixed bug - ind1=fix((max(ind)+min(ind))/2) 
;
;NOTES:	  
;	Current version only works for FAST
;-

pro get_pa_spec_ts,get_dat,  $
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
	eweight = eweight, $
	shift90 = shift90, $
        CALIB = calib, $
        n_get_pts = n_get_pts


;	Time how long the routine takes
ex_start = systime(1)

;	Set defaults for keywords, etc.

n = 0
max = 30000        ; this could be improved
all_same = 1

routine = 'get_'+get_dat+'_ts'

if not keyword_set(n_get_pts) then n_get_pts=200

if keyword_set(t1) then begin
	t=t1
	dat = call_function(routine,t,CALIB=calib,npts=n_get_pts)
endif else begin
	dat = call_function(routine,/st,CALIB=calib,npts=n_get_pts)
endelse

if dat(0).valid eq 0 then begin no_data = 1 & return & end $
else no_data = 0

ytitle = get_dat + '_pa_spec'
last_time = (dat(0).time+dat(0).end_time)/2.
nenergy = dat(0).nenergy
nmaxvar = dat(0).nbins

default_gap_time = 200
if dat(0).project_name eq 'FAST' then begin
	nmaxvar=64
	default_gap_time = 8.
endif
if not keyword_set(gap_time) then gap_time = default_gap_time

time   = dblarr(max)
data   = fltarr(max,nmaxvar)
var   = fltarr(max,nmaxvar)
nvar = dat(0).nbins
nmax=nvar

if not keyword_set(units) then units = 'Counts'
if not keyword_set(missing) then missing = !values.f_nan

;	Collect the data - Main Loop
 
if keyword_set(t2) then tmax=t2 else tmax=1.e30

	data_idx=dat(0).st_index
	arr_idx=0
while (dat(arr_idx).valid ne 0) and (n lt max) do begin
if (dat(arr_idx).valid eq 1) then begin

	count = dat(arr_idx).nenergy

	if keyword_set(en) then er=energy_to_ebin(dat(arr_idx),en)
	if keyword_set(er) then begin
		ebins=bytarr(dat(arr_idx).nenergy)
		if er(0) gt er(1) then er=reverse(er)
		ebins(er(0):er(1))=1
	endif
	if not keyword_set(ebins) then begin
		ebins=bytarr(dat(arr_idx).nenergy)
		ebins(*)=1
	endif

	if keyword_set(retrace) then ebins(0:retrace-1)=0
	ind=where(ebins,count)

	if units eq 'Counts' then norm = 1 else norm = count
	if ind(0) ne -1 and keyword_set(eweight) then norm = total(dat(arr_idx).denergy(ind,0),1)

	if abs((dat(arr_idx).time+dat(arr_idx).end_time)/2.-last_time) ge gap_time then begin
		if n ge 2 then dbadtime = time(n-1) - time(n-2) else dbadtime = gap_time/2.
		time(n) = (last_time) + dbadtime
		data(n,*) = missing
		var(n,*) = missing
		n=n+1
		if (dat(arr_idx).time+dat(arr_idx).end_time)/2. gt time(n-1) + gap_time then begin
			time(n) = (dat(arr_idx).time+dat(arr_idx).end_time)/2. - dbadtime
			data(n,*) = missing
			var(n,*) = missing
			n=n+1
		endif
	endif

	if keyword_set(bkg) then dat(arr_idx) = sub3d(dat(arr_idx),bkg)
	if keyword_set(units) then dat(arr_idx) = conv_units(dat(arr_idx),units)

	nvar = dat(arr_idx).nbins
	if nvar gt nmax then nmax = nvar
	time(n)   = (dat(arr_idx).time+dat(arr_idx).end_time)/2.
	if ind(0) eq -1 then begin
		tmpdata = total( dat(arr_idx).data(0,*), 1)
		tmpdata(*) = 0
		tmpvar = total( dat(arr_idx).theta(0,*), 1)
		if keyword_set(shift90) then tmpvar = $
		((360.*(tmpvar/360.-floor(tmpvar/360.)) + 90.) mod 360.) -90.
	endif else begin
		if keyword_set(eweight) then begin
			tmpdata = total( dat(arr_idx).data(ind,*)*dat(arr_idx).denergy(ind,*), 1)/norm
		endif else begin
			tmpdata = total( dat(arr_idx).data(ind,*), 1)/norm
		endelse
; The following line will need to change if theta depends upon the energy index
;  Some of this section could be cleaned up 
		ind1= fix((max(ind)+min(ind))/2)
		tmpvar = total( dat(arr_idx).theta(ind1,*), 1)
		if keyword_set(shift90) then tmpvar = $
		((360.*(tmpvar/360.-floor(tmpvar/360.)) + 90.) mod 360.) -90.
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
	print,'Invalid packet, dat(arr_idx).valid ne 1, at: ',time_to_str(dat.time)
endelse

        arr_idx=arr_idx+1
        data_idx=data_idx+1

        ; get new data if beyond cache array

        if data_idx gt dat(0).en_index then begin
            dat = call_function(routine,idxst=data_idx,CALIB=calib,npts=n_get_pts)  
            arr_idx = 0
        endif


        ; If we are beyond the end of the cache here, or beyond the end time
        ; we're done.

        if dat(0).valid then $
          if (data_idx lt dat(0).en_index) and $
          (dat(arr_idx).time gt tmax) then dat(arr_idx).valid=0

endwhile

;	Store the data

	if count ne nenergy then ytitle = ytitle+'_'+strtrim(count,2)
	if keyword_set(name) eq 0 then name=ytitle else ytitle = name
	ytitle = ytitle+' ('+units+')'

data = data(0:n-1,0:nmax-1)
var = var(0:n-1,0:nmax-1)

print,'all_same=',all_same
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
message,string(ex_time)+' seconds execution time.',/cont,/info
print,'Number of data points = ',n

return

end
