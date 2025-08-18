;+
;PROCEDURE:   dangle
;PURPOSE:
;  Determines the angle between two vectors in tplot.  Operates on
;  variables in Cartesian coordinates, where X is an N-element time
;  array, and Y is an N x 3 array of vectors.  Two time ranges are
;  input by the cursor, and the mean vector [<x>, <y>, <z>] is 
;  determined in each range.  The angle between these two vectors is
;  the result.  Only makes sense when the vectors are steady in both
;  ranges.
;
;  This routine continues in a loop.  Press the right mouse button
;  at any time to exit.
;
;USAGE:
;   dangle, var
;
;INPUTS:
;   var    :     Tplot variable name or number.  The X tag is an 
;                N-element time array, and the Y tag is an N x 3
;                array of Cartesian vectors.  Required.
;
;KEYWORDS:
;   RESULT :     Named variable to hold the results (units = deg).
;
;   TBAR:        Plot time bars for the two time ranges.  These are
;                transient and disappear whenever a new set of time
;                ranges is selected or when the routine exits.
;                Default = 1.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-10-09 10:17:00 -0700 (Mon, 09 Oct 2023) $
; $LastChangedRevision: 32177 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/dangle.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro dangle, var, result=result, tbar=tbar

; Make sure input variable exists and has the correct tags and dimensions

  if (n_elements(var) eq 0) then begin
    print, "You must specify a tplot variable name or number."
    return
  endif

  get_data, var, data=dat, index=i
  if (i eq 0) then begin
    print, "Tplot variable not found: ", var
    return
  endif

  if (size(dat,/type) ne 8) then begin
    print, "Tplot variable must be a structure."
    return
  endif

  str_element, dat, 'y', success=ok
  if (not ok) then begin
    print, "Tplot variable does not have the standard tags."
    return
  endif

  ndim = size(dat.y)
  if (ndim[0] eq 2) then if (ndim[2] eq 3) then ok = 1 else ok = 0
  if (not ok) then begin
    print,"Tplot variable must have Y dimensions of N x 3."
    return
  endif

  undefine, dat, result
  result_str = [{trange1:[0D,0D], phi1:0., the1:0., trange2:[0D,0D], phi2:0., the2:0., angle:0.}]
  tbar = size(tbar,/type) gt 0 ? keyword_set(tbar) : 1

  times = [time_double('1879-03-14')]
  if (tbar) then timebar, times, /line, /transient
  first = 1

  while (1) do begin

    if (~first) then print, '---------------------------------------------'

; Get the first vector

    print, 'Choose a time range for the first vector', format='(/,a)'
    ctime, tsp1, npoints=2, /silent
    cursor,cx,cy,/norm,/up  ; Make sure mouse button released
    if (n_elements(tsp1 ne 2)) then begin
      if (tbar) then timebar, times, /line, /transient
      return
    endif

    tmean, var, trange=tsp1, ind=0, minpts=1, result=dat, /silent
    x = dat.mean
    tmean, var, trange=tsp1, ind=1, minpts=1, result=dat, /silent
    y = dat.mean
    tmean, var, trange=tsp1, ind=2, minpts=1, result=dat, /silent
    z = dat.mean

    r = sqrt(x*x + y*y + z*z)
    phi1 = atan(y,x)
    if (phi1 lt 0.) then phi1 += 2.*!pi
    the1 = asin(z/r)
    print, "Direction 1 (phi, the): ", phi1*!radeg, the1*!radeg, format='(a,f5.1,2x,f5.1)'

; Get the second vector

    print, 'Choose a time range for the second vector', format='(/,a)'
    ctime, tsp2, npoints=2, /silent
    cursor,cx,cy,/norm,/up  ; Make sure mouse button released
    if (n_elements(tsp2 ne 2)) then begin
      if (tbar) then timebar, times, /line, /transient
      return
    endif

    tmean, var, trange=tsp2, ind=0, minpts=1, result=dat, /silent
    x = dat.mean
    tmean, var, trange=tsp2, ind=1, minpts=1, result=dat, /silent
    y = dat.mean
    tmean, var, trange=tsp2, ind=2, minpts=1, result=dat, /silent
    z = dat.mean

    r = sqrt(x*x + y*y + z*z)
    phi2 = atan(y,x)
    if (phi2 lt 0.) then phi2 += 2.*!pi
    the2 = asin(z/r)
    print, "Direction 2 (phi, the): ", phi2*!radeg, the2*!radeg, format='(a,f5.1,2x,f5.1)'

    if (tbar) then begin
      timebar, times, /line, /transient
      times = [tsp1, tsp2]
      timebar, times, /line, /transient
    endif

; Calculate the angle between the vectors

    angle = acos(cos(phi2 - phi1)*cos(the1)*cos(the2) + sin(the1)*sin(the2))*!radeg

    print, "Angle between directions 1 and 2: ", angle, format='(/,a,f5.1,/)'

    result_str.trange1 = tsp1
    result_str.phi1 = phi1*!radeg
    result_str.the1 = the1*!radeg
    result_str.trange2 = tsp2
    result_str.phi2 = phi2*!radeg
    result_str.the2 = the2*!radeg
    result_str.angle = angle

    if (first) then result = result_str else result = [result, result_str]

    first = 0

  endwhile

end
