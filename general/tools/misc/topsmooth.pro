function topfilter, y, npts=npts, frac=frac, bottom=bottom

  if (n_elements(npts) eq 0) then npts = 16 else npts = round(npts[0])
  if (size(frac,/type) eq 0) then frac = 0.5 else frac = float(frac[0])
  bflg = keyword_set(bottom)
  if (bflg) then frac = 1. - frac

  delta = 2L*npts
  dndx = lindgen(delta)
  imin = 0L
  imax = n_elements(y) - 1L
  f = replicate(1B, imax+1L)

  while (imin lt imax) do begin
    indx = (imin + dndx) < imax
    indx = indx[uniq(indx)]
    jndx = sort(y[indx])
    mpts = round(float(n_elements(jndx))*frac)
    f[indx[jndx[0L:(mpts-1L)]]] = 0B
    imin += delta
  endwhile

  indx = where(f, complement=jndx)

  if (bflg) then return, jndx else return, indx

end

;+
;PROCEDURE:   topsmooth
;PURPOSE:
;  Calculate a smooth curve through the upper envelope of a tplot variable.
;
;USAGE:
;  topsmooth, var
;
;INPUTS:
;       var:     Variable name or number.
;
;KEYWORDS:
;       NPTS:    Half-width of boxcar.  Default = 16.
;
;       FRAC:    Fraction of points to ignore in average or interpolates.
;                Default = 0.5.
;
;       INTERP:  Interpolate using data that pass through topfilter.
;
;       SIGMA:   Spline sigma.  Default = 1.
;
;       LAMBDA:  Spline smooth lambda.  Default = 1.
;
;       SILENT:  Shh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-06-23 12:31:58 -0700 (Fri, 23 Jun 2023) $
; $LastChangedRevision: 31907 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/topsmooth.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro topsmooth, var, npts=npts, frac=frac, interp=interp, sigma=sigma, lambda=lambda, silent=silent

  if (n_elements(npts) eq 0) then npts = 16 else npts = round(npts[0])
  if (n_elements(frac) eq 0) then frac = 0.5 else frac = frac[0]
  if (n_elements(sigma) eq 0) then sigma = 1. else sigma = float(sigma[0])
  if (n_elements(lambda) eq 0) then lambda = 1D else lambda = double(lambda[0])
  interp = keyword_set(interp)
  blab = ~keyword_set(silent)

; Make sure variable exists and can be interpreted properly

  get_data, var, data=dat, alim=lim, index=i
  if (i eq 0) then begin
    print,'Variable not defined: ',var
    return
  endif
  str_element, dat, 'x', value=x, success=ok
  if (not ok) then begin
    print,'Cannot interpret variable: ',var
    return
  endif
  str_element, dat, 'y', value=y, success=ok
  if (not ok) then begin
    print,'Cannot interpret variable: ',var
    return
  endif
  str_element, dat, 'dy', value=dy, success=ok
  if (ok) then dody = 1 else dody = 0
  if ((size(y))[0] gt 1) then begin
    print,'Only works for 1-D variables: ',var
    return
  endif
  dat = 0

  tplot_names, names=names, /silent
  var = names[i-1]

; Boxcar smooth after throwing out lowliers

  ys = y
  imax = n_elements(x) - 1L

  if (~interp) then begin
    for i=0L,imax do begin
      jmin = (i - npts) > 0L
      jmax = (i + npts) < imax
      mpts = round(float(jmax - jmin + 1L)*(1. - frac))
      z = y[jmin:jmax]
      z = z[reverse(sort(z))]
      ys[i] = mean(z[0L:(mpts-1L)],/nan)
    endfor
  endif

; Interpolate across gaps and spline smooth the result

  if (interp) then begin
    indx = topfilter(y, npts=npts, frac=frac)
    dat = {x:x[indx], y:y[indx]}
    if (dody) then str_element, dat, 'dy', dy[indx], /add
    store_data,'n1d_gud',data=dat
    options,'n1d_gud','colors',[4]
    options,'n1d_gud','psym',3
    yi = interp(y[indx], x[indx], x)
    ys = spline_smooth(x,yi,lambda=lambda)
  endif

; Store result as a new tplot variable

  vname = var + '_topsmooth'
  store_data,vname,data={x:x, y:ys}
  options,vname,'psym',3

  return

end
