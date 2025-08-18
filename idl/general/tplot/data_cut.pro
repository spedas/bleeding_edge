;+
;FUNCTION: A = data_cut(name, t)
;PURPOSE:  Interpolates data from a data structure.
;INPUT:
;  name:  Either a data structure or a string that can be associated with
;      a data structure.  (see "get_data" routine)
;      the data structure must contain the element tags:  "x" and "y"
;      the y array may be multi dimensional.
;  t:   (scalar or array)  x-values for interpolated quantities.
;RETURN VALUE:
;  a data array: the first dimension is the dimension of t
;                the second dimension is the dimension of name
;
; NOTE!!  keyword options have been temporarily removed!!!!
;
;KEYWORDS:
;  EXTRAPOLATE:  Controls interpolation of the ends of the data. Effects:
;                0:  Default action.  Set new y data to NAN or to MISSING.
;                1:  Extend the endpoints horizontally.
;                2:  Extrapolate the ends.  If the range of 't' is
;                    significantly larger than the old time range, the ends
;                    are likely to blow up.
;  INTERP_GAP:   Determines if points should be interpolated between data gaps,
;                together with the GAP_DIST.  IF the data gap > GAP_DIST,
;                follow the action of INTERP_GAP
;                0:  Default action.  Set y data to MISSING.
;                1:  Interpolate gaps
;  GAP_DIST:     Determines the size of a data gap above which interpolation
;                is regulated by INTERP_GAP.
;                Default value is 5, in units of the average time interval:
;                delta_t = (t(end)-t(start)/number of data points)
;  MISSING:      Value to set the new y data to for data gaps.  Default is NAN.
;  LAST_VALUE:  Set this keyword to return the last value of y array:  y[index]    (no interpolation performed)
;
;CREATED BY:	 Davin Larson
;LAST MODIFICATION:     @(#)data_cut.pro	1.19 02/04/17
;                Added the four keywords. (fvm 9/27/95)
;-
FUNCTION data_cut,name,t, $
   COUNT=count, $
   EXTRAPOLATE=EXTRAPOLATE,INTERP_GAP=INTERP_GAP,gap_thresh=gap_thresh,$
   GAP_DIST=GAP_DIST,MISSING=MISSING,LAST_VALUE=LAST_VALUE

if size(/type,name) eq 7 or size(/type,name) eq 2 or size(/type,name) eq 3 then begin
  get_data,name,data=dat,index=h
  if h eq 0 then begin
    count = 0
    return,0
  endif
endif


if size(/type,name) eq 8 then dat=name

if n_elements(MISSING) eq 0    then MISSING     = !values.f_nan

if keyword_set(INTERP_GAP) then begin
   trange = minmax(dat.x)
   dt = (trange[1]-trange[0])  / n_elements(dat.x)
   gap_thresh = dt * (keyword_set(GAP_DIST) ? GAP_DIST : 5.0)
endif


nt = dimen1(t)
count = nt
nd1 = dimen1(dat.y)
nd2 = dimen2(dat.y)
if n_elements(dat.x) le 1 then return,0

if 1 then begin
  y = interp( dat.y, dat.x, t, interp_thr=gap_thresh, last_value=last_value  )
endif else begin      
  dprint,'  This old method was very sloppy and lost precision by forcing floating point precision'
  y = fltarr(nt,nd2)
  ;do the interpolation, including the gaps and ends
  for i=0,nd2-1 do begin
    y[*,i] = interp(double(dat.y[*,i]),dat.x,t,interp_thr = gap_thresh,last_value=last_value)
  endfor  
endelse

if not keyword_set(EXTRAPOLATE) then begin
  tlim = minmax(dat.x)
  dt = (tlim[1]-tlim[0]) / (n_elements(dat.x)-1)
  tlim = tlim + [-dt,dt]
  outside = where( (t lt tlim[0]) or (t gt tlim[1]) ,c)
  if c ne 0 then y[outside,*] = MISSING
endif

if (ndimen(t) eq 0) and (ndimen(dat.y) eq 1) then return,y[0] $
else return,reform(y)

end
