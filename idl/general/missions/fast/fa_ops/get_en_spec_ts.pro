;+
;PROCEDURE:	get_en_spec_ts
;PURPOSE:	
;	Generates energy-time spectrogram data structures for tplot
;INPUT:		
;	get_dat, 	a string (either 'fa_ees','fa_eeb', ...)
;			where get_'string'_ts returns a 2D or 3D 
;			array of data structures
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
;	NAME:  		New name of the Data Quantity
;	BKG:  		A 3d data structure containing the background counts.
;	FLOOR:  	Sets the minimum value of any data point to sqrt(bkg).
;	MISSING: 	value for bad data.
;	RETRACE: 	Set to number of retrace energy steps to be eliminated starting at energy step 0
;	CALIB:		Calib keyword passed on to get_"get_dat"_ts
;	n_get_pts: 	Number of points in the array of structures formed by get_"get_dat"_ts, default=200.
;
;CREATED BY:	J.McFadden
;VERSION:	1
;LAST MODIFICATION:  97/05/15
;MOD HISTORY:
;		97/05/15	Variation on get_en_spec.pro with help from J.Loran
;
;NOTES:	  
;	Current version only works for FAST
;-

pro get_en_spec_ts,get_dat,  $
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
        n_get_pts = n_get_pts


;	Time how long the routine takes
ex_start = systime(1)

;	Set defaults for keywords, etc.

n = 0
max = 70000        ; this could be improved
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

ytitle = get_dat + '_en_spec'
last_time = (dat(0).time+dat(0).end_time)/2.
nbins = dat(0).nbins
nmaxvar = dat(0).nenergy

default_gap_time = 200.
if dat(0).project_name eq 'FAST' then begin
	nmaxvar=96
	default_gap_time = 8.
endif
if not keyword_set(gap_time) then gap_time = default_gap_time

time   = dblarr(max)
data   = fltarr(max,nmaxvar)
var   = fltarr(max,nmaxvar)
nvar = dat(0).nenergy
nmax=nvar

if not keyword_set(units) then units = 'Counts'
if not keyword_set(missing) then missing = !values.f_nan

;	Collect the data - Main Loop

if keyword_set(t2) then tmax=t2 else tmax=1.e30

	data_idx=dat(0).st_index
	arr_idx=0
while (dat(arr_idx).valid ne 0) and (n lt max) do begin
if (dat(arr_idx).valid eq 1) then begin

	count = dat(arr_idx).nbins

	if keyword_set(an) then bins=angle_to_bins(dat(arr_idx),an)
	if keyword_set(ar) then begin
		nb=dat(arr_idx).nbins
		bins=bytarr(nb)
		if ar(0) gt ar(1) then begin
			bins(ar(0):nb-1)=1
			bins(0:ar(1))=1
		endif else begin
			bins(ar(0):ar(1))=1
		endelse
	endif
; Set the "count" to the number of bins summed over
	if not keyword_set(bins) then ind=indgen(dat(arr_idx).nbins) else ind=where(bins,count)

	if units eq 'Counts' then norm = 1 else norm = count


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

	nvar = dat(arr_idx).nenergy
	if nvar gt nmax then nmax = nvar
	time(n)   = (dat(arr_idx).time+dat(arr_idx).end_time)/2.
	if ind(0) ne -1 then begin
		data(n,0:nvar-1) = total( dat(arr_idx).data(*,ind), 2)/norm
		var(n,0:nvar-1) = total( dat(arr_idx).energy(*,ind), 2)/count
	endif else begin
		data(n,0:nvar-1) = 0
		var(n,0:nvar-1) = total( dat(arr_idx).energy(*,0), 2)
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
	print,'Invalid packet, dat(arr_idx).valid ne 1, at: ',time_to_str(dat(arr_idx).time)
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

	if count ne nbins then ytitle = ytitle+'_'+strtrim(count,2)
	if keyword_set(name) eq 0 then name=ytitle else ytitle = name
	ytitle = ytitle+' ('+units+')'

if not keyword_set(retrace) then begin
;	If you want to plot the retrace, set the retrace flag to 1.
	data = data(0:n-1,0:nmax-1)
	var = var(0:n-1,0:nmax-1)
endif else begin
	data = data(0:n-1,retrace:nmax-1)
	var = var(0:n-1,retrace:nmax-1)
endelse

print,'all_same=',all_same
;labels=''

; The following has be removed so that FAST summary cdf files contain both arrays
;if all_same then begin
;	var = reform(var(0,*))
;	labels = strtrim( round(var) ,2)+ ' eV'
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
;    ylog:1,panel_size:2.}
datastr = {x:time,y:data,v:var}
store_data,name,data=datastr

ex_time = systime(1) - ex_start
message,string(ex_time)+' seconds execution time.',/cont,/info
print,'Number of data points = ',n

return

end
