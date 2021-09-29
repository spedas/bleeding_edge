;+
;PROCEDURE:   timebox_mean
;PURPOSE:
;  Calculates the mean, median, and standard deviation of a 1-D array
;  for the input time resolution.
;
;USAGE:
;  timebox_mean, var, resolution = resolution, result=dat
;
;INPUTS:
;       var:     Tplot-like data structure {x:unix time, y:data} 
;                or variable name/number.
;
;OUTPUT:         If var is a tplot variable name/number, then the result
;                is stored as a new tplot variable.  Otherwise, the 
;                result is returned via keyword (see below).
;
;KEYWORDS:
;       RESOLUTON: time resolution of average in seconds, the default
;                  is one day. 86400.0 seconds
;
;       OUTLIER: Discard points more than this many standard deviations
;                from the mean.  Default = 10.
;
;       RESULT:  Named variable to hold the result.
;       TIME_RANGE: the input time range, the default is
;                   to obtain the time range from the data
;       TIME_BINS_IN: Use these bins for input, either a 2Xnbins array
;                     or 1D array of Nbins+1, The 2Xnbins array option
;                     allows for discontinuous binning.
;HISTORY:
;       Hacked from box_mean.pro, jmm, jimm@ssl.berkeley.eud
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-10-16 14:04:32 -0700 (Wed, 16 Oct 2019) $
; $LastChangedRevision: 27880 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/timebox_mean.pro $
;
;-
pro timebox_mean, var, resolution=resolution, outlier=outlier, result=dat, $
                  time_range = time_range, time_bins_in = time_bins_in
  
  if not keyword_set(resolution) then resolution = 86400.0d0
  if not keyword_set(outlier) then outlier = 10.
; Make sure variable exists and can be interpreted

  tndx = 0
  if (n_elements(var) eq 1) then begin
    if (size(var,/type) ne 8) then begin
      get_data, var, data=dat, alim=lim, index=tndx
      if (tndx eq 0) then begin
        dprint,'Input variable not defined'
        return
      endif
    endif else dat = var
    str_element, dat, 'x', success=ok
    if (not ok) then begin
      dprint,'Cannot interpret input variable'
      return
    endif
    str_element, dat, 'y', success=ok
    if (not ok) then begin
      dprint,'Cannot interpret input variable'
      return
    endif
    if ((size(dat.y))[0] gt 1) then begin
      dprint,'Only works for 1-D variables'
      return
    endif
  endif else begin
     dat = {x:0, y:var}
     dprint,'Only works for single 1-D variables'
     return
  endelse

; get time bins
  If(keyword_set(time_bins_in)) Then Begin
     tbins = time_double(time_bins_in)
     If(size(tbins, /n_dimen) Eq 1) Then Begin;convert 1d to 2d
        npts = n_elements(tbins)-1
        tbins2 = dblarr(2, npts)
        tbins2[0, *] = tbins[0:npts-1]
        tbins2[1, *] = tbins[1:npts]
     Endif Else If(size(tbins, /n_dimen) Eq 2) Then Begin
        tbins2 = tbins
     Endif Else Begin
        dprint, 'Bad time_bins_in input'
        Return
     Endelse
  Endif Else Begin
     If(keyword_set(time_range) && n_elements(time_range) Eq 2) Then Begin
        trange = time_double(time_range)
     Endif Else trange = minmax(dat.x)
     npts = ceil((trange[1]-trange[0])/resolution)
     tbins = trange[0]+dindgen(npts+1)*resolution
     tbins2 = dblarr(2, npts)
     tbins2[0, *] = tbins[0:npts-1]
     tbins2[1, *] = tbins[1:npts]
  Endelse
  tbins = temporary(tbins2)     ;rename back to tbins
; Calculate the mean and standard deviation, for each bin
  npts = n_elements(tbins[0, *])
  rmed = fltarr(npts)
  ravg = rmed
  rrms = rmed
  rpts = lonarr(npts)
  for i=0L,(npts-1L) do begin
     ssi = where(dat.x Ge tbins[0, i] And dat.x Lt tbins[1, i], nssi)
     If(nssi Gt 0) Then Begin
        y = dat.y[ssi]
        mom = moment(y, maxmoment=2, mean=avg, sdev=rms, /nan)
        If(nssi Gt 1) Then Begin
           med = median(y) 
           indx = where(abs(y - avg) gt (outlier*rms), count)
           while (count gt 0L) do begin
              y[indx] = !values.f_nan
              mom = moment(y, maxmoment=2, mean=avg, sdev=rms, /nan)
              med = median(y)
              indx = where(abs(y - avg) gt (outlier*rms), count)
           endwhile
        Endif Else Begin
           med = y[0]
           count = 0L
        Endelse
        indx = where(finite(y), count)
        rmed[i] = med
        ravg[i] = avg
        rrms[i] = rms
        rpts[i] = count
     Endif
  endfor

; Package the result
  str_element, dat, 'median' , rmed   , /add
  str_element, dat, 'mean'   , ravg   , /add
  str_element, dat, 'stddev' , rrms   , /add
  str_element, dat, 'npts'   , rpts   , /add
  str_element, dat, 'width'  , width  , /add
  str_element, dat, 'outlier', outlier, /add

; Make a TPLOT variable
  if (tndx gt 0) then begin
    tplot_names, var, name=vname
    vname += '_timebox_mean'

    y = fltarr(npts,3)
    y[*,0] = ravg - rrms
    y[*,1] = ravg
    y[*,2] = ravg + rrms
    x = 0.5*(reform(tbins[0, *]+tbins[1, *]))
    store_data, vname, data={x:x, y:y, v:[0,1,2]}
    options, vname, 'colors', [2,6,2]
    str_element, lim, 'ytitle', ytitle, success=ok
    if (ok) then options, vname, 'ytitle', (ytitle + '!ctimebox mean')
  endif

  return

end
