;+
; Function: time_average
;
; Calculates a bin based average over time series data
; Uses a histogram internally so it should be pretty quick
;
; Arguments:
;       time: the time array for the input timeseries
;       data: the data array for the input timeseries
;       newtime(optional): named variable in which to return the times
;              for each bin upon which an average is calculated
;       trange(optional): a time range over which the average is
;       performed
;       resolution(optional): the size of each bin in seconds
;       ret_total(optional): named variable in which totals for each
;       bin are returned
;       ret_min(optional): named variable in which mins for each bin 
;       are returned
;       ret_med(optional): named variable in which medians for each
;       bin are returned
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-24 09:39:41 -0800 (Tue, 24 Jan 2012) $
; $LastChangedRevision: 9596 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time_average.pro $
;-


function time_average,time,data,newtime=newtime, $
      trange=trange,resolution=resolution, $
      ret_total=ret_tot,ret_min=ret_min,ret_median=ret_median

if not keyword_set(data) then return,data

d = data[0] * !values.f_nan
dim = dimen(data)
   
if keyword_set(trange) then   tr = time_double(trange)
nd = size(/n_dimen,data)

if keyword_set(resolution) then begin
   if not keyword_set(tr) then $
        tr= (floor(minmax(time)/resolution)+[0,1]) * resolution
   index = floor( (time-tr[0])/resolution )
   nbins = round((tr[1]-tr[0])/resolution)
   w = where( index lt 0 or index ge nbins, c)
   if c ne 0 then index[w]=-1
   newtime = (dindgen(nbins)+.5)*resolution+tr[0]
   dim[0] = nbins
   newdata = make_array(value=d,dimen=dim)
   h = histogram(index,min=0,max=nbins-1,reverse=ri)
   whn0 = where(h ne 0,count)
   for j=0l,count-1 do begin
     i = whn0[j]
     ind = ri[ ri[i]: ri[i+1]-1 ]
     if n_elements(ind) ne h[i] then dprint ,'Histogram error'
     newdata[i,*,*] = average(data[ind,*,*],1,/nan,ret_total=ret_tot,ret_min=ret_min,ret_median=ret_median)  ;,stdev=s,nan=rnan)
;    std[i] = s
   endfor
   return,newdata
endif

if keyword_set(tr) then begin
   w =where(time lt tr[1] and time ge tr[0],c)
   if c eq 0 then begin
      newtime=0
      return,0
   endif
   newtime= time[w]
   newdata= data[w,*,*]
   return,newdata
endif

newtime = time
return,data

end
