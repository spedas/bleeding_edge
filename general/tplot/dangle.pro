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
;USAGE:
;   dangle, var
;
;INPUTS:
;   var    :     Tplot variable name or number.  The X tag is an 
;                N-element time array, and the Y tag is an N x 3
;                array of Cartesian vectors.
;
;KEYWORDS:
;   RESULT :     Named variable to hold the result (units = deg).
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-09-19 08:45:43 -0700 (Tue, 19 Sep 2023) $
; $LastChangedRevision: 32104 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/dangle.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro dangle, var, result=angle

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

; Get the first vector

  print, 'Choose a time range for the first vector', format='(/,a)'
  ctime, tsp1, npoints=2, /silent
  cursor,cx,cy,/norm,/up  ; Make sure mouse button released
  if (n_elements(tsp1 ne 2)) then return

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
  if (n_elements(tsp2 ne 2)) then return

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

; Calculate the angle between the vectors

  angle = acos(cos(phi2 - phi1)*cos(the1)*cos(the2) + sin(the1)*sin(the2))*!radeg

  print, "Angle between directions 1 and 2: ", angle, format='(/,a,f5.1,/)'

end
