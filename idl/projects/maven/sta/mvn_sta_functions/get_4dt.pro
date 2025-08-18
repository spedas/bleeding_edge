;+
;PROGRAM:	get_4dt,funct,routine
;INPUT:	
;	funct:	function,	function that operates on structures generated 
;					by mvn_sta_get_??
;				funct   = 'n_4d','j_4d','v_4d','p_4d','t_4d', ...
;					  
;	routine, 	a string that defines the 'routine' that returns a 4D data structure
;				routine = mvn_sta_get_??
;
;KEYWORDS
;	T1:	real or dbl	start time, seconds since 1970
;	T2:	real or dbl	end time, seconds since 1970		
;	ENERGY:	fltarr(2),	min,max energy range to be passed to "funct"
;	ERANGE:	fltarr(2),	min,max energy bin numbers to be passed to "funct"
;	EBINS:	bytarr(na),	energy bins array to be passed to "funct"
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2),	min,max pitch angle range to be passed to "funct"
;	ARANGE:	fltarr(2),	min,max angle bin numbers to be passed to "funct"
;	BINS:	bytarr(nb),	angle bins array to be passed to "funct"
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	EBINS:	bytarr(na,nb),	energy/angle bins array to be passed to "funct"
;	MASS:	fltarr(2)		min,max mass range to be passed to "funct" 
;	M_INT:	0/1		keyword to integerize mass to nearest AMU, passed to "funct"
;	Q	integer		particle charge passed to "funct" to be used instead of charge returned by "routine" 
;	GAP_TIME: 		time gap big enough to signify a data gap 
;				(def 200 sec, 8 sec for FAST)
;	NO_DATA: 		returns 1 if no_data else returns 0
;	NAME:  			New name of the Data Quantity
;				Default: funct+'_'+routine
;	BKG:  	string		name of routine that calculates bkg_data for background subtractions: dat.data=dat.data-bkg_data
;	FLOOR:  0/1		Sets the minimum value of any data point to sqrt(bkg).
;	MISSING: 		value for bad data. 	0,1=exclude,include
;
;	
;
;PURPOSE:
;	To generate time series data for "tplot.pro" 
;NOTES:	
;	Program names time series data to funct+"_"+routine if NAME keyword not set
;		See 'tplot_names.pro'.
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:  14/03/17		developed from get_2dt.pro
;LAST MODIFICATION:  20/06/04		line 96, if dat.valid eq 0 then return
;MOD HISTORY:	
;
;NOTES:	  
;	Current version only works for MAVEN
;-
pro get_4dt,funct,routine, $
	T1=t1, $
	T2=t2, $
	ENERGY=en, $
	ERANGE=er, $
	EBINS=ebins, $
	BINS=bins, $
	ANGLE=an, $
	ARANGE=ar, $
	MASS=ms, $
	M_INT=mi, $
	q=q, $
	mincnt=mincnt, $
	gap_time=gap_time, $ 
	no_data=no_data, $
        name  = name, $
	bkg = bkg, $
        missing = missing, $
        floor = floor, $
	verbose = verbose

;	Time how long the routine takes
ex_start = systime(1)

if n_params() lt 2 then begin
	print,'Wrong Format, Use: get_4dt,funct,routine'
	return
endif

n=0l

times = call_function(routine,/times) 
maxind = n_elements(times)-1l

if keyword_set(t1) then tmpmax=min(abs(times-time_double(t1)),idx) else idx=0l
if keyword_set(t2) then tmpmax=min(abs(times-time_double(t2)),idxmax) else idxmax=maxind

	dat = call_function(routine,t,index=idx)
	while (dat.valid eq 0 and idx lt idxmax) do begin
		idx = idx + 1
		dat = call_function(routine,t,index=idx)
	endwhile
	if dat.valid eq 0 then return

ytitle = funct+"_"+routine
last_time = (dat.time+dat.end_time)/2.

default_gap_time = 500.
if not keyword_set(gap_time) then gap_time = default_gap_time

maxpts = idxmax-idx+1000 < 300000l			; this limits a tplot str to < 10 days
time = dblarr(maxpts)

sum = call_function(funct,dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
nargs = n_elements(sum)
data = fltarr(maxpts,nargs)


if not keyword_set(missing) then missing = !values.f_nan

while (idx lt idxmax) and (n lt maxpts) do begin

if (dat.valid eq 1) then begin

;	if abs((dat.time+dat.end_time)/2.-last_time) ge gap_time then begin
	if abs((dat.time+dat.end_time)/2.-last_time) ge gap_time and (n lt maxpts) then begin
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

	sum = call_function(funct,dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
	data(n,*) = sum
	time(n)   = (dat.time+dat.end_time)/2.
	last_time = time(n)
	n = n+1

endif else begin
;	print,'Invalid packet, dat.valid ne 1, at: ',time_to_str(dat.time)
	if keyword_set(verbose) then print,'Invalid packet, dat.valid ne 1, at: ',time_string(last_time)
endelse
	idx=idx+1

	dat = call_function(routine,t,index=idx)
	if keyword_set(bkg) then dat.data=dat.data-dat.bkg

; old code to be deleted later
;	if keyword_set(bkg) then begin 
;		type = size(bkg,/type)
;		if type eq 7 then begin
;			bkg_data = call_function(bkg,dat)
;			if keyword_set(floor) then dat.data=(dat.data-bkg_data)>bkg_data^.5 else dat.data=(dat.data-bkg_data)
;		endif else if type eq 2 then begin
;			if keyword_set(floor) then dat.data=(dat.data-dat.bkg)>dat.bkg^.5 else dat.data=(dat.data-dat.bkg)
;		endif
;
;		if dat.data_name eq 'C6 Energy-Mass' then begin
;			bg = fltarr(32,64)
;			bb = total(dat.data[*,0:6],2)/total(dat.twt_arr[*,0:6],2)
;			maxt = max(bb,ind)
;			ind = ind>2						; handles bb[*]=0
;			for ii=8,63 do bg[*,ii] = bb * dat.data[ind,ii]/(bb[ind]>1.e-10)
;			cc = total(dat.data[*,9:13],2)/total(dat.twt_arr[*,9:13],2)
;			for ii=15,63 do bg[*,ii] = bg[*,ii] + cc * dat.data[ind-2,ii]/(cc[ind-2]>1.e-10)
;			dat.data=dat.data-bg>0
;		endif else begin
;			if keyword_set(floor) then dat.data=(dat.data-dat.bkg)>dat.bkg^.5 else dat.data=(dat.data-dat.bkg)
;		endelse
;	endif
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

