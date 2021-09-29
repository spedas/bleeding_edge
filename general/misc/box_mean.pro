;+
;PROCEDURE:   box_mean
;PURPOSE:
;  Calculates the mean, median, and standard deviation of a 1-D array
;  in a running boxcar.
;
;USAGE:
;  box_mean, var, result=dat
;
;INPUTS:
;       var:     Tplot structure or variable name/number.  Can also
;                simply be an array of numbers.
;
;OUTPUT:         If var is a tplot variable name/number, then the result
;                is stored as a new tplot variable.  Otherwise, the 
;                result is returned via keyword (see below).
;
;KEYWORDS:
;       WIDTH:   Boxcar half-width for calculating mean and sdev.
;                Default = 20 points.  The boxcar is truncated at
;                the beginning and end of the array.
;
;       OUTLIER: Discard points more than this many standard deviations
;                from the mean.  Default = 10.
;
;       RESULT:  Named variable to hold the result.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-09-07 12:20:50 -0700 (Mon, 07 Sep 2020) $
; $LastChangedRevision: 29119 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/box_mean.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro box_mean, var, width=width, outlier=outlier, result=dat
  
  if not keyword_set(width) then width = 20L
  if not keyword_set(outlier) then outlier = 10.

; Make sure variable exists and can be interpreted

  tndx = 0
  if (n_elements(var) eq 1) then begin
    if (size(var,/type) ne 8) then begin
      get_data, var, data=dat, alim=lim, index=tndx
      if (tndx eq 0) then begin
        print,'Input variable not defined'
        return
      endif
    endif else dat = var
    str_element, dat, 'x', success=ok
    if (not ok) then begin
      print,'Cannot interpret input variable'
      return
    endif
    str_element, dat, 'y', success=ok
    if (not ok) then begin
      print,'Cannot interpret input variable'
      return
    endif
    if ((size(dat.y))[0] gt 1) then begin
      print,'Only works for 1-D variables'
      return
    endif
  endif else dat = {x:0, y:var}

; Calculate the mean and standard deviation

  npts = n_elements(dat.y)
  rmed = fltarr(npts)
  ravg = rmed
  rrms = rmed
  rpts = lonarr(npts)
  rbad = rpts

  for i=0L,(npts-1L) do begin
    imin = (i - width) > 0L
    imax = (i + width) < (npts-1L)
    y = dat.y[imin:imax]
    mom = moment(y, maxmoment=2, mean=avg, sdev=rms, /nan)
    med = median(y)
    indx = where(abs(y - avg) gt (outlier*rms), count)
    nbad = 0L
    while (count gt 0L) do begin
      nbad += count
      y[indx] = !values.f_nan
      mom = moment(y, maxmoment=2, mean=avg, sdev=rms, /nan)
      med = median(y)
      indx = where(abs(y - avg) gt (outlier*rms), count)
    endwhile
    indx = where(finite(y), count)
    rmed[i] = med
    ravg[i] = avg
    rrms[i] = rms
    rpts[i] = count
    rbad[i] = nbad
  endfor

; Package the result

  str_element, dat, 'median' , rmed   , /add
  str_element, dat, 'mean'   , ravg   , /add
  str_element, dat, 'stddev' , rrms   , /add
  str_element, dat, 'npts'   , rpts   , /add
  str_element, dat, 'nbad'   , rbad   , /add
  str_element, dat, 'width'  , width  , /add
  str_element, dat, 'outlier', outlier, /add

; Make a TPLOT variable

  if (tndx gt 0) then begin
    tplot_names, var, name=vname
    vname += '_box_mean'

    y = fltarr(npts,3)
    y[*,0] = ravg - rrms
    y[*,1] = ravg
    y[*,2] = ravg + rrms
    store_data, vname, data={x:dat.x, y:y, v:[0,1,2]}
    options, vname, 'colors', [2,6,2]
    str_element, lim, 'ytitle', ytitle, success=ok
    if (ok) then options, vname, 'ytitle', (ytitle + '!cbox mean')
  endif

  return

end
