;+
;PROGRAM:	get_2dt_ts,funct,get_dat
;INPUT:	
;	funct:	function,	function that operates on structures generated 
;					by get_eesa_surv, get_eesa_burst, etc.
;				funct   = 'n_2d','j_2d','v_2d','p_2d','t_2d',
;					  'vth_2d','ec_2d', or 'je_2d'
;	get_dat:function,	function that returns 2d data structures
;				function name must be "get_"+"get_dat"+"_ts"  
;				get_dat = 'fa_ees' for get_fa_ees_ts, 
;				get_dat = 'fa_eeb' for get_fa_eeb_ts, etc.
;KEYWORDS
;	T1:	real or dbl	start time, seconds since 1970
;	T2:	real or dbl	end time, seconds since 1970		
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2),	optional, min,max pitch angle range for integration
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;	GAP_TIME: 		time gap big enough to signify a data gap 
;				(def 200 sec, 8 sec for FAST)
;	NO_DATA: 	returns 1 if no_data else returns 0
;	NAME:  		New name of the Data Quantity
;				Default: funct+'_'+get_dat
;	BKG:  		A 3d data structure containing the background counts.
;	FLOOR:  	Sets the minimum value of any data point to sqrt(bkg).
;	MISSING: 	value for bad data.
;					0,1=exclude,include
;	CALIB:		Calib keyword passed on to get_dat
;	n_get_pts: 	Number of points in the array of structures formed by get_"data_str"_ts, default=200.
;
;PURPOSE:
;	To generate time series data for "tplot.pro" 
;NOTES:	
;	Program names time series data to funct+"_"+get_dat if NAME keyword not set
;		See 'tplot_names.pro'.
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:  97/05/16
;MOD HISTORY:	
;		97/05/16	Variation on get_2dt.pro that uses get_*_ts.pro routines
;
;NOTES:	  
;	Current version only works for FAST
;-
pro get_2dt_ts,funct,get_dat, $
	T1=t1, $
	T2=t2, $
	ENERGY=en, $
	ERANGE=er, $
	EBINS=ebins, $
	ANGLE=an, $
	ARANGE=ar, $
	BINS=bins, $
	gap_time=gap_time, $ 
	no_data=no_data, $
        name  = name, $
	bkg = bkg, $
        missing = missing, $
        floor = floor, $
        CALIB = calib, $
        n_get_pts = n_get_pts

;	Time how long the routine takes
ex_start = systime(1)

if n_params() lt 2 then begin
	print,'Wrong Format, Use: get_2dt_ts,funct,get_dat,[t1=t1,t2=t2,...]'
	return
endif

n=0
max = 30000
trat = 1.0         ; Needed for bkg sub.

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

ytitle = funct+"_"+get_dat
last_time = (dat(0).time+dat(0).end_time)/2.

default_gap_time = 200
if dat(0).project_name eq 'FAST' then begin
	default_gap_time = 8.
endif
if not keyword_set(gap_time) then gap_time = default_gap_time

sum = call_function(funct,dat(0),ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
nargs = n_elements(sum)
time = dblarr(max)
data = fltarr(max,nargs)

if not keyword_set(missing) then missing = !values.f_nan

if keyword_set(t2) then tmax=t2 else tmax=1.e30

	data_idx=dat(0).st_index
	arr_idx=0
while (dat(arr_idx).valid ne 0) and (n lt max) do begin
if (dat(arr_idx).valid eq 1) then begin

	if abs((dat(arr_idx).time+dat(arr_idx).end_time)/2.-last_time) ge gap_time then begin
		if n ge 2 then dbadtime = time(n-1) - time(n-2) else dbadtime = gap_time/2.
		time(n) = (last_time) + dbadtime
		data(n,*) = missing
		n=n+1
		if (dat(arr_idx).time+dat(arr_idx).end_time)/2. gt time(n-1) + gap_time then begin
			time(n) = (dat(arr_idx).time+dat(arr_idx).end_time)/2. - dbadtime
			data(n,*) = missing
			n=n+1
		endif
	endif

	if keyword_set(bkg) then dat = sub3d(dat(arr_idx),bkg)

	sum = call_function(funct,dat(arr_idx),ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
	data(n,*) = sum
	time(n)   = (dat(arr_idx).time+dat(arr_idx).end_time)/2.
	last_time = time(n)
	n = n+1

endif else begin
	print,'Invalid packet, dat(arr_idx).valid ne 1, at: ',time_to_str(dat(arr_idx).time)
endelse

        arr_idx=arr_idx+1
        data_idx=data_idx+1

        ; get new data if beyond cache array

        if data_idx gt dat(0).en_index then begin
            dat = call_function(routine,CALIB=calib,idxst=data_idx,npts=n_get_pts)  
            arr_idx = 0
        endif

        ; If we are beyond the end of the cache here, or beyond the end time
        ; we're done.

        if dat(0).valid then $
          if (data_idx lt dat(0).en_index) and $
          (dat(arr_idx).time gt tmax) then dat(arr_idx).valid=0

endwhile

if not keyword_set(name) then name=ytitle else ytitle=name
data = data(0:n-1,*)
time = time(0:n-1)

if keyword_set(t1) then begin
	ind=where(time ge t1)
	time=time(ind)
	data=data(ind,*)
endif
if keyword_set(t2) then begin
	ind=where(time le t2)
	time=time(ind)
	data=data(ind,*)
endif

datastr = {x:time,y:data,ytitle:ytitle}
store_data,name,data=datastr

ex_time = systime(1) - ex_start
message,string(ex_time)+' seconds execution time.',/cont,/info
print,'Number of data points = ',n

return
end

