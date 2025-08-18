;+
;PROGRAM:	get_2dt,funct,get_dat
;INPUT:	
;	funct:	function,	function that operates on structures generated 
;					by get_eesa_surv, get_eesa_burst, etc.
;				funct   = 'n_2d','j_2d','v_2d','p_2d','t_2d',
;					  'vth_2d','ec_2d', or 'je_2d'
;	get_dat, 	a string that defines the 'routine' that returns a 2D or 3D data structure
;			if 'probe' keyword set, assumes routine = get_dat
;			if 'probe' keyword is not set, assumes routine = 'get_'+ get_dat
;				unless get_dat already includes 'get_', in which case routine = get_dat
;			for example, get_dat='thc_peir' then routine = 'get_thc_peir'
;			for example, get_dat='thm_sst_pser' then routine = 'thm_sst_pser'
;
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
;	CALIB:		Calib keyword passed on to get_dat -- no longer used
;	PROBE:		probe keyword passed on to get_dat -- used by themis sst routines
;
;PURPOSE:
;	To generate time series data for "tplot.pro" 
;NOTES:	
;	Program names time series data to funct+"_"+get_dat if NAME keyword not set
;		See 'tplot_names.pro'.
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:  97/03/04
;MOD HISTORY:	
;		97/03/04	T1,T2 keywords added
;		08/07/10	bkg keyword changed to work for Themis ion ESA
;		08/12/31	bkg keyword changed to work for Themis electron sst
;		08/12/31	added probe keyword for themis sst calls
;		09/01/05	changed loop to use index to allow for dat.valid=0 data in stored data
;		09/01/05	calib keyword no longer passed to routine
;		09/04/16	bkg keyword removed for Themis electron sst, assume bkg removal is part of get_th?_pse?
;
;NOTES:	  
;	Current version only works for FAST
;-
pro get_2dt,funct,get_dat, $
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
	probe = probe

;	Time how long the routine takes
ex_start = systime(1)

if n_params() lt 2 then begin
	print,'Wrong Format, Use: get_2dt,funct,get_dat,[t1=t1,t2=t2,...]'
	return
endif

n=0l

if strlowcase(strmid(get_dat,0,4)) eq 'get_' then begin
	routine = get_dat
	get_dat = strlowcase(strmid(get_dat,4,strlen(get_dat)))
endif else if keyword_set(probe) then begin
	routine = get_dat
endif else routine = 'get_'+get_dat 

if keyword_set(probe) then times = call_function(routine,probe=probe,/times) else times = call_function(routine,/times)
maxind = n_elements(times)-1

if keyword_set(t1) then tmpmax=min(abs(times-time_double(t1)),idx) else idx=0l
if keyword_set(t2) then tmpmax=min(abs(times-time_double(t2)),idxmax) else idxmax=maxind

if keyword_set(probe) then begin
	dat = call_function(routine,t,probe=probe,index=idx) 
	while (dat.valid eq 0 and idx lt idxmax) do begin
		idx = idx + 1
		dat = call_function(routine,t,probe=probe,index=idx)
	endwhile
endif else begin
	dat = call_function(routine,t,index=idx)
	while (dat.valid eq 0 and idx lt idxmax) do begin
		idx = idx + 1
		dat = call_function(routine,t,index=idx)
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


ytitle = funct+"_"+get_dat
last_time = (dat.time+dat.end_time)/2.



default_gap_time = 200
if dat.project_name eq 'FAST' then default_gap_time = 8.
if dat.project_name eq 'THEMIS I&T' then default_gap_time = 50.
if strupcase(strmid(dat.project_name,0,6)) eq 'THEMIS' then default_gap_time = 13.





if not keyword_set(gap_time) then gap_time = default_gap_time

maxpts = idxmax-idx+1000 < 300000l			; this limits a tplot str to < 10 days
time = dblarr(maxpts)

sum = call_function(funct,dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
nargs = n_elements(sum)
data = fltarr(maxpts,nargs)


if not keyword_set(missing) then missing = !values.f_nan












;while (dat.valid ne 0) and (n lt maxpts) do begin
while (idx lt idxmax) and (n lt maxpts) do begin

if (dat.valid eq 1) then begin

	if abs((dat.time+dat.end_time)/2.-last_time) ge gap_time then begin
		if n ge 2 then dbadtime = time(n-1) - time(n-2) else dbadtime = gap_time/2.
		time(n) = (last_time) + dbadtime
		data(n,*) = missing
		n=n+1
		if (dat.time+dat.end_time)/2. gt time(n-1) + gap_time then begin
			time(n) = (dat.time+dat.end_time)/2. - dbadtime
			data(n,*) = missing
			n=n+1
		endif
	endif

	if keyword_set(bkg) then begin
; sub3d requires bkg to be the subtraction array -- sub3d is a general routine and works similar to the pse routine
		if ndimen(bkg) ne 0 then dat = sub3d(dat,bkg) $
;		else if dat.UNITS_PROCEDURE eq 'thm_convert_esa_units' then dat=thm_esa_bgnd_sub(dat) $ ; old routine
		else if dat.UNITS_PROCEDURE eq 'thm_convert_esa_units' and dat.charge gt 0. then dat=thm_pei_bkg_sub(dat) $
		else if dat.UNITS_PROCEDURE eq 'thm_convert_esa_units' and dat.charge lt 0. then dat=thm_pee_bkg_sub(dat) 
;		else if dat.UNITS_PROCEDURE eq 'thm_sst_convert_units' then dat=thm_pse_bkg_sub(dat)   	; this is now part of get_routine
	endif

	sum = call_function(funct,dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
	data(n,*) = sum
	time(n)   = (dat.time+dat.end_time)/2.
	last_time = time(n)
	n = n+1

endif else begin
	print,'Invalid packet, dat.valid ne 1, at: ',time_to_str(dat.time)
endelse
	idx=idx+1
	if keyword_set(probe) then dat = call_function(routine,t,probe=probe,index=idx) else dat = call_function(routine,t,index=idx)

;	if keyword_set(probe) then idx=idx+1
;	if keyword_set(calib) then dat = call_function(routine,t,CALIB=calib,/ad) $
;		else if keyword_set(probe) then dat = call_function(routine,probe=probe,index=idx) $
;		else dat = call_function(routine,t,/ad)
;	if dat.valid ne 0 then if dat.time gt tmax then dat.valid=0

endwhile

if not keyword_set(name) then name=ytitle else ytitle=name
data = data(0l:n-1,*)
time = time(0l:n-1)

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

