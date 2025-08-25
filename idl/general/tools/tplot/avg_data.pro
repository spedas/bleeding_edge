;+
;PROCEDURE: avg_data, name, res
;PURPOSE:
;   Creates a new tplot variable that is the time average of original.
;INPUT: name  tplot variable names (strings)
;KEYWORDS:
; newname = new name for the variable
; append = append this suffix to the variable
; trange = time range, can be used to alter start and end times, the
;          default is minmax(data.x)
; day = return values /per day
; display_object = Object reference to be passed to dprint for output.
; do_stdev = if set create a variable for the standard deviation. with
;            suffix "_stdev"
;Modified by O. Le Contel, LPP, Feb. 19, 2016
; in order to deal with L64 integer
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/avg_data.pro $
;-

function average_bins,data,ind,d,do_stdev=do_stdev,stdev=sdat
if d ne 1 then message ,'not working yet!'
dim  = dimen(data)
nd   = ndimen(data)
if nd eq 1 then d=1
mx = max(ind)+1
dim[d-1] = mx
val = !values.f_nan
rdat = make_array(val=val,dim=dim)
if keyword_set(do_stdev) then sdat = rdat else sdat=-1

nan=1
case nd of

1:begin
for i=0l,mx-1 do begin
   w = where(ind eq i,c)
   if keyword_set(do_stdev) then begin
      if c eq 1 then rdat[i] = data[w] ;sdat[i] will stay at zero
      if c gt 1 then begin
         rdat[i] = average(data[w],/do_stdev,stdev=sdati,nan=nan)
         sdat[i] = sdati
      endif
   endif else begin
      if c eq 1 then rdat[i] = data[w]
      if c gt 1 then rdat[i] = average(data[w],nan=nan)
   endelse
endfor
end
2:begin
for i=0l,mx-1 do begin
   w = where(ind eq i,c)
   if keyword_set(do_stdev) then begin
      if c eq 1 then rdat[i,*] = data[w,*]
      if c gt 1 then begin
         rdat[i,*] = average(data[w,*],d,/do_stdev,stdev=sdati,nan=nan)
         sdat[i,*] = sdati
      endif
   endif else begin
      if c eq 1 then rdat[i,*] = data[w,*]
      if c gt 1 then rdat[i,*] = average(data[w,*],d,nan=nan)
   endelse
endfor
end

3:begin
for i=0l,mx-1 do begin
   w = where(ind eq i,c)
   if keyword_set(do_stdev) then begin
      if c eq 1 then rdat[i,*,*] = data[w,*,*]
      if c gt 1 then begin
         rdat[i,*,*] = average(data[w,*,*],d,/do_stdev,stdev=sdati,nan=nan)
         sdat[i,*,*] = sdati
      endif
   endif else begin
      if c eq 1 then rdat[i,*,*] = data[w,*,*]
      if c gt 1 then rdat[i,*,*] = average(data[w,*,*],d,nan=nan)
      if c le 1 then help,c,w,i
   endelse
endfor
end
endcase

return,rdat
end

PRO avg_data,name,res,newname=newname,append=append,trange=trange,day=day,$
             do_stdev=do_stdev, display_object=display_object

get_data,name,ptr=p1,dlim=dlim,lim=lim

if not keyword_set(p1) then begin
   dprint, 'data not defined!', display_object=display_object
   return
endif

if not keyword_set(append) then append = '_avg'
if not keyword_set(newname) then newname = name+append
if keyword_set(do_stdev) then newname_stdev = newname+'_stdev'
if not keyword_set(res) then res = 60d   ; 1 minute resolution
res = double(res)

time = *p1.x

if keyword_set(day) then trange=(round(average(time,/nan)/86400d -day/2.)+[0,day])*86400d

if not keyword_set(trange) then trange= (floor(minmax(time)/res,/L64)+[0,1]) * res $
  else trange = [time_double(trange[0]),time_double(trange[1])]

;check for data in this time range
time_test = where(time Ge trange[0] And time Lt trange[1], ntimes_ok,/L64)

If(ntimes_ok Eq 0) Then Begin
  dprint, 'No data in input time range', display_object=display_object
  return
Endif

ind = floor( (time-trange[0])/res,/L64 )
max = round((trange[1]-trange[0])/res,/L64)
w = where( ind lt 0 or ind ge max, c,/L64)
if c ne 0 then ind[w]=-1
mx = max(ind)+1
newtime = (dindgen(mx)+.5)*res+trange[0]

;n = n_elements(time)
;ind = floor(time / res)
;start = min(ind)
;ind = ind - start

;max = max(ind)+1
;if max gt 1 then  newtime = (dindgen(max)+.5+start)*res  $
;else newtime = (start+.5)*res

if keyword_set(do_stdev) then begin ;only do the y variable stdev
   y = average_bins(*p1.y,ind,1,/do_stdev,stdev=sy)
   sdat = {x:newtime,y:sy}
endif else y = average_bins(*p1.y,ind,1)
dat = {x:newtime,y:y}

v=0
str_element,p1,'v',v
if keyword_set(v) then begin
  if ndimen(*v) gt 0 then str_element,/add,dat,'v',average_bins(*v,ind,1) $
  else str_element,/add,dat,'v',*v
  if keyword_set(do_stdev) then begin
     if ndimen(*v) gt 0 then str_element,/add,sdat,'v',average_bins(*v,ind,1) $
     else str_element,/add,sdat,'v',*v
  endif
endif

v=0
str_element,p1,'v1',v
if keyword_set(v) then begin
  if ndimen(*v) gt 0 then str_element,/add,dat,'v1',average_bins(*v,ind,1) $
  else str_element,/add,dat,'v1',*v
  if keyword_set(do_stdev) then begin
     if ndimen(*v) gt 0 then str_element,/add,sdat,'v1',average_bins(*v,ind,1) $
     else str_element,/add,sdat,'v1',*v
  endif
endif

v=0
str_element,p1,'v2',v
if keyword_set(v) then begin
  if ndimen(*v) gt 0 then str_element,/add,dat,'v2',average_bins(*v,ind,1) $
  else str_element,/add,dat,'v2',*v
  if keyword_set(do_stdev) then begin
     if ndimen(*v) gt 0 then str_element,/add,sdat,'v2',average_bins(*v,ind,1) $
     else str_element,/add,sdat,'v2',*v
  endif
endif

store_data,newname,data=dat,dlim=dlim,lim=lim
if keyword_set(do_stdev) then store_data,newname_stdev,data=sdat,dlim=dlim,lim=lim
return
end
