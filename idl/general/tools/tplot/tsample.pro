;+
; $LastChangedBy: ali $
; $LastChangedDate: 2025-10-14 18:20:42 -0700 (Tue, 14 Oct 2025) $
; $LastChangedRevision: 33757 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/tsample.pro $
;
;FUNCTION:
;  dat = tsample([var,trange],[times=t])
;PURPOSE:
;  Returns a vector (or array) of tplot data values.
;USAGE:
;  dat = tsample()               ;Use cursor to select a subset of data.
;  dat = tsample('Np',[t0,t1])   ;extract all 'Np' data in the given time range
;KEYWORDS:
;  AVERAGE:  if set the time average of the variable is returned
;  STDEV:  named value to return the standard deviation (only works if AVERAGE is set)
;  TIMES:  time values returned through this (named) variable keyword.
;  VALUES: values returned through this named variable keyword.
;  DY :  dy values returned through this named variable keyword.
;-

function tsample,var,t,times=times,values=vals,noshow=noshow,index=w $
  ,average=aver,nan=nan,dy=dy,stdev=stdev,silent=silent,total=tot,count=c,np=np

  if n_elements(nan) eq 0 then nan=1

  if keyword_set(t) eq 0 then begin
    print,'Select time range'+ (size(/type,var) eq 7 ? ' for variable "'+var+'".' : '.')
    if ~keyword_set(np) then np=2
    ctime,t,np=np,vnam=vars,noshow=noshow,silent=silent
  endif
  if not keyword_set(var) then var=vars[0] else var=(tnames(var,/all))[0]
  get_data,var,data=d
  c = 1
  w = -1
  val = !values.f_nan
  if not keyword_set(t) then return,val
  if size(/type,d) ne 8 then return,val
  td = time_double(t)
  if n_elements(td) eq 2 then w = where(d.x ge td[0] and d.x lt td[1],c)
  if n_elements(td) eq 1 then begin
    dt = d.x-td[0]
    w = where(finite(dt) eq 0,nw)
    if nw ne 0 then dt[w] = 1e13
    dummy = min(abs(dt),w)
  endif
  if c ne 0 then begin
    nd = size(/n_dimen,d.y)
    case nd of
      1:  val=d.y[w]
      2:  val=d.y[w,*]
      3:  val=d.y[w,*,*]
    endcase
    ;   val=d.y(w,*)
    times=d.x[w]
    str_element,d,'v',vals
    if ndimen(vals) eq 2 then vals= vals[w,*]
    str_element,d,'dy',dy
    if keyword_set(dy) then dy = dy[w,*]
  endif
  if keyword_set(aver) then begin
    val = average(val,1,nan=nan,stdev=stdev)
    if ndimen(vals) eq 2 then vals= average(vals,1,nan=nan)
    if keyword_set(dy) then dy = average(dy,1,nan=nan)
  endif
  if keyword_set(tot) then begin
    val = total(val,1,nan=nan)
    ;  if ndimen(vals) eq 2 then vals= total(vals,1,nan=nan)
    ;  if keyword_set(dy) then dy = (dy,1,nan=nan)
  endif
  return,val
end

