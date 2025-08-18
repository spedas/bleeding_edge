;+
;PROCEDURE:	get_spec
;PURPOSE:
;  Creates "TPLOT" variable by summing 3D data over selected angle bins.
;
;INPUT:		data_str, a string(either 'eh','el','ph','pl','sf',or 'so' at
;		this point) telling which data to get.
;
;KEYWORDS:	bins: a keyword telling which bins to sum over
;		gap_time: time gap big enough to signify a data gap (def 200)
;		no_data: returns 1 if no_data else returns 0
;		units:	convert to these units if included
;               NAME:  New name of the Data Quantity
;               BKG:  A 3d data structure containing the background counts.
;               FLOOR:  Sets the minimum value of any data point to sqrt(bkg).
;               MISSING: value for bad data.
;		KEV: If set, energy array and energy labels are put in keV.
;		     The default is to put energy in eV.
;
;CREATED BY:	Jasper Halekas
;FILE:  get_spec.pro
;VERSION:  1.48
;LAST MODIFICATION:  02/04/17
;MOD HISTORY:
;   95/10/5 by REE (added bkg subtraction)
;   96/4/9 by JML now use index feature of get_* to walk through the data
;   96/5/6  Mods plus clean up.
;
;NOTES:	  "LOAD_3DP_DATA" must be called first to load up WIND data.
;-

pro get_spec,data_str,  $
        bins=bins, $       
        gap_time=gap_time, $ 
        no_data=no_data, $
        units = units,  $
        name  = name, $
        bkg = bkg, $
        missing = missing, $
        trange=trange, $
        floor = floor, $
        kev = kev, $
        _extra = e

ex_start = systime(1)

routine = 'get_'+data_str
dat = call_function(routine,index=0,_extra=e)

ytitle = data_str + 'spec'

n_e = dat.nenergy
nbins = dat.nbins
if keyword_set(bins) eq 0 then str_element,dat,'bins',bins

if n_elements(bins) eq (nbins*n_e) then begin
	bins = total(bins,1) gt 0
	binsindx = where(bins eq 0,binscnt)
	if binscnt eq 0 then bins = 0
endif


times = call_function(routine,/times,_extra=e)
if n_elements(times) eq 1 and times(0) eq 0 then begin
        print,'No valid data in timerange.'
        store_data,ytitle,dat=0
        return
endif

firstvalid = -1
if dat.valid eq 1 then firstvalid = 0
i = 0
while firstvalid eq -1 do begin
	if i eq n_elements(times) then begin
		print,'No valid data in timerange.'
		store_data,ytitle,dat=0
		return
	endif
	dat=call_function(routine,index=i,_extra=e)
	if dat.valid eq 1 then firstvalid = i
	i = i + 1
endwhile

nenergy = dat.nenergy

max = n_elements(times)
istart = 0
if keyword_set(trange) then begin
   irange = fix(interp(findgen(max),times,gettime(trange)))
print,irange
   irange = (irange < (max-1)) > 0
   irange = minmax(irange)
   istart = irange(0)
   times = times(istart:irange(1))
   print,'Index range: ',irange
   max = n_elements(times)
endif


data   = fltarr(max,nenergy)
energy   = fltarr(max,nenergy)

if not keyword_set(units) then units = 'Eflux'
dat=conv_units(dat,units)

count = dat.nbins
if not keyword_set(bins) then ind=indgen(dat.nbins) else ind=where(bins,count)
if count ne dat.nbins then ytitle = ytitle+'_'+strtrim(count,2)
if keyword_set(bkg) then ytitle = ytitle+'b'
if keyword_set(name) eq 0 then name=ytitle else ytitle = name
ytitle = ytitle+' ('+units+')'

if units eq 'Counts' then norm = 1 else norm = count

if not keyword_set(missing) then missing = !values.f_nan

mid_times = times
for i=0l,max-1 do begin
   dat = call_function(routine,index=i+istart,_extra=e)
   if dat.valid ne 0 then begin
     nfindx = where(finite(dat.data) ne 1,cnt)
     if cnt ne 0 then dat.data(nfindx) = 0.
     if times(i) ne dat.time then print,time_string(dat.time),dat.time-times(i)
     if keyword_set(bkg) then   dat = sub3d(dat,bkg)
     dat = conv_units(dat,units)
     data(i,*) = total( dat.data(*,ind), 2)/norm
     energy(i,*) = total( dat.energy(*,ind), 2)/count
     mid_times(i) = dat.time + (dat.end_time - dat.time)/2d
   endif else begin
     data(i,*) = missing
     energy(i,*) = missing
   endelse
endfor

if keyword_set(kev) then begin
	energy = energy/1e3
	nrgs = reform(energy(firstvalid,*))
	labels = strtrim( round(nrgs), 2)+' keV'
endif else begin
	nrgs = reform(energy(firstvalid,*))
	labels = strtrim( round(nrgs) ,2)+' eV'
endelse

delta = energy - shift(energy,1,0)
w = where(delta,c)
if c eq 0 then energy = nrgs

;message,/info,'Not running smoothspikes'
;smoothspikes,times

datastr = {x:mid_times,y:data,v:energy};,  $
;    ylog:1,labels:labels,panel_size:2.}

store_data,name,data=datastr,dlim={ylog:1,labels:labels,panel_size:2.,comment:'Units: '+units}

ex_time = systime(1) - ex_start
message,string(ex_time)+' seconds execution time.',/cont,/info

return

end
