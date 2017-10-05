;+
; NAME:
;     avsig
; PURPOSE:
;     Average and dispersion of an array, zeros can be not included,
;     handles NaN values correctly
; CALLING SEQUENCE:
;     xbar = Avsig(x, sigma = sigma, no_zeros = no_zeros, $
;                sig_mean = sig_mean, dimension = dimension, $
;                fractional = fractional, median = median, $
;                _extra = _extra)
; INPUT:
;     x = an array
; OUTPUT:
;     xbar = mean, total(x)/n_elements(x)
; KEYWORDS:
;     no_zeros= if set, strip out zeros
;     get_sigma = if set, calculate the standard deviation
;     sigma = standard deviation, sqrt(total((x-xbar)^2/(nx-1)))
;     sig_mean = if set return sigma/sqrt(nx), the standard deviation of the
;                mean of the array, 
;     dimension = the dimension of the array to find the mean in,
;                 passed into the total command, it must be a scalar.
;     fractional = if set, the fractional error is passed out as sigma,
;                  don't use this if zero is a valid value of xbar...
;     median = if set, use the median instead of the mean for xbar, it
;              is not recommended fo sigma calculations
; HISTORY:
;     12-9-94, jmm, jimm@ssl.berkeley.edu
;     2-13-95, jmm, added dimension keyword, switched from ok_zeros to no_zeros
;     5-sep-1996, jmm, switched to double precision
;     7-oct-2008, jmm, ignores NaN values, added median keyword
;-
FUNCTION Avsig, x0, get_sigma = get_sigma, sigma = sigma, $
                no_zeros = no_zeros, sig_mean = sig_mean, $
                dimension = dimension, fractional = fractional, $
                median = median, _extra = _extra

  IF(KEYWORD_SET(get_sigma) OR KEYWORD_SET(sig_mean) OR $
     KEYWORD_SET(fractional)) THEN BEGIN
    gsig = 1b
    IF(KEYWORD_SET(median)) THEN BEGIN
      dprint, 'Warning: '
      ;message,/info, 'Warning: '
      dprint,print, 'Unpredictable results may occur '
      dprint,print, 'for sigma calculation when /median is set'
    ENDIF
  ENDIF ELSE gsig = 0b
  x = double(x0)
;N-elements needs to account for NaN values
  xmask = finite(x)
  IF(KEYWORD_SET(no_zeros)) THEN BEGIN ;set zero values to NaN
    zv = where(x Eq 0 Or xmask Eq 0, nzv)
    IF(nzv GT 0) THEN x[zv] = !values.d_nan
  ENDIF
  xmask = finite(x)             ;reset
  IF(KEYWORD_SET(dimension)) THEN BEGIN
;get the size of the array, if it's only 1d, goto the else part
    size_x = size(x)
    IF(size_x[0] LE 1) THEN GOTO, its_a_vector
;Ok, now be sure that the given dimension exists
    d0 = long(dimension[0])
    IF(d0 GT size_x[0]) THEN BEGIN
      dprint, 'NOT ENOUGH DIMENSIONS IN ARRAY, RETURNING FULL MATRIX VALUE', dlevel=2 
      ;message,'NOT ENOUGH DIMENSIONS IN ARRAY, RETURNING FULL MATRIX VALUE',/info
      GOTO, its_a_vector
    ENDIF
;use the dimension in the total commands
    nx = total(xmask, d0)
    IF(KEYWORD_SET(median)) THEN BEGIN
      xbar = median(x, dimension = d0, /even)
    ENDIF ELSE BEGIN
      xbar = total(x, d0, /nan)/nx ;where nx is zero, xbar will be bad
      nx0 = where(nx Eq 0)
      IF(nx0[0] Ne -1) Then xbar[nx0] = 0.0 ;returning 0's for bad values
    ENDELSE
    IF(gsig) THEN BEGIN
      sigma = total(x^2, d0, /nan) ;two sums
      nx1 = where(nx GT 1.0)
      IF(nx1[0] NE -1) THEN BEGIN
        sigma[nx1] = sqrt((sigma[nx1]-nx[nx1]*xbar[nx1]^2)/(nx[nx1]-1.0))
        IF(KEYWORD_SET(sig_mean)) THEN sigma[nx1] = sigma[nx1]/nx[nx1]
        nx1_not = where(nx LE 1.0)
        IF(nx1_not[0] NE -1) THEN sigma[nx1_not] = 0.0
      ENDIF ELSE sigma[*] = 0.0
    ENDIF
  ENDIF ELSE BEGIN
    its_a_vector:
    nx = total(xmask)
    IF(nx GT 0) THEN BEGIN
      IF(KEYWORD_SET(median)) THEN xbar = median(x, /even) $
      ELSE xbar = total(x, /nan)/nx
      IF(gsig) THEN BEGIN
        IF(nx GT 1) THEN sigma = sqrt(total((x-xbar)^2, /nan)/(nx-1.0)) $
        ELSE sigma = 0.0
        IF(KEYWORD_SET(sig_mean)) THEN sigma = sigma/sqrt(nx)
      ENDIF
    ENDIF ELSE BEGIN
      xbar = 0.0d0
      IF(gsig) THEN sigma = xbar
    ENDELSE
  ENDELSE

  IF(KEYWORD_SET(fractional)) THEN BEGIN
    xxx = where(xbar NE 0.0)
    IF(xxx[0] NE -1) THEN BEGIN
      sigma[xxx] = sigma[xxx]/xbar[xxx]
    ENDIF
  ENDIF

  RETURN, xbar
END
;+
;NAME:
; tsub_average
;PURPOSE:
; Subtracts average or median values from the data in a tplot
; variable, returns a new variable, only one at a time for now
;CALLING SEQUENCE:
; tsub_average, varname, out_name, new_name=new_name,median=median
;INPUT:
; varname =  a tplot variable name
;OUTPUT:
; out_name = variable name of the output tplot variable
;KEYWORDS:
; new_name = can be used to input the new variable name, if not input
;            the default is to add a '-d' to the input name (or '-m' for median
;            subtraction) and the name is passed out in this variable
; display_object = Object reference to be passed to dprint for output.
; 
;HISTORY:
; 18-jul-2007, jmm, jimm@ssl.berkeley.edu
; 02-nov-2007, jmm, Fixed bug for variables with no data.
; 06-may-2008, jmm, Fixed problem, by changing non-float and
;                   non-double datatypes to floats
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;-
Pro tsub_average, varname0, nn, new_name = new_name, median = median, $
                     display_object=display_object, _extra = _extra

  varname = tnames(varname0)
  If(keyword_set(new_name)) Then nn = new_name Else Begin
    If(keyword_set(median)) Then nn = varname+'-m'$
    Else nn = varname+'-d'
  Endelse
  get_data, varname, data = d, limits = lim, dlimits = dlim
  If(is_struct(d)) Then Begin
    ytmp = d.y
    szsv = size(ytmp)
    typv = size(ytmp, /type)
    If(typv Ne 4 And typv Ne 5) Then ytmp = float(ytmp) ;for subtraction purposes
    svalue = avsig(ytmp, dimension = 1, median = median)
    If(szsv[0] Le 2) Then Begin
      ytmp = ytmp-(replicate(1, n_elements(d.x))#svalue)
    Endif Else If(szsv[0] Eq 3) Then Begin
      tdata = rebin(svalue, szsv[2], szsv[3], n_elements(d.x))
      tdata = transpose(tdata, [2, 0, 1])
      ytmp = ytmp-temporary(tdata)
    Endif Else Begin            ;use a loop here
      For i = 0, n_elements(x)-1 Do $
        ytmp[i, *] = reform(ytmp[i, *])-svalue
    Endelse
    str_element, d, 'y', temporary(ytmp), /add_replace
    store_data, nn, data = temporary(d), limits = temporary(lim), $
      dlimits = temporary(dlim)
  Endif Else Begin
    dprint, 'No data structure associated with variable: '+varname, display_object=display_object
    nn = ''
  Endelse
  new_name = nn
  Return
End


