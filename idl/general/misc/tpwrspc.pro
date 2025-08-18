;+
;NAME:
; tpwrspc
;PURPOSE:
; wrapper for pwrspc.pro allowing input of a tplot variable name.
;    A Hanning window is applied to
;    the input data, and its power is divided out of the returned
;    spectrum. A straight line is subtracted from the data to
;    reduce spurius power due to sawtooth behavior of a background.
;    UNITS ARE (UNITS)^2 WHERE UNITS ARE THE UNITS OF quantity. freq
;    is in 1/timeunits.
;    THUS THE OUTPUT REPRESENTS THE MEAN SQUARED AMPLITUDE OF THE SIGNAL
;       AT EACH SPECIFIC FREQUENCY. THE TOTAL (SUM) POWER UNDER THE CURVE IS
;       EQUAL TO THE MEAN (OVER TIME) POWER OF THE OSCILLATION IN TIME DOMAIN.

;CALLING SEQUENCE:
; 
;CALLING SEQUENCE:
; tpwrspc, varnames, newname=newname,_extra=_extra
;INPUT:
; varname = one tplot variable name
;OUTPUTS:
; freq_out=freq_out(optional): output frequency abcissas, in a 1-d array
; power_out = power_out(optional) : output powers at frequency abcissas, in a 1-d array 
;
;KEYWORDS:
; newname = if set,give this name to the new data, the
;           default is to append '_pwrspc' to the input name and
;           pass out the name in the newname variable,
;           Unless /overwrite is set
; overwrite = if set, write the new data back to the old tplot
;             variable, do not set this with newname
; noline = if set, no straight line is subtracted
; nohanning = if set, then no hanning window is applied to the input
; bin = a binsize for binning of the frequency data, the default is 3
; notperhz = if set, the output units are simply the square of the
;            input units 
; err_msg = named variable that contains any error message that might occur 
; 
; NOTES: 1. IF KEYWORD notperhz IS SET, THEN POWER IS IN UNITS^2. If notset
;           power is (as normal) in UNITS^2/Hz.
;        2. Inputs must be 1-dimensional.   For example, if you try to
;            call this on a 3-d vector like fgs data, it will not work.
;            call 'split_vec' first, to split the quantity into its components.        
;      
; 27-mar-2007, jmm, jimm.ssl.berkeley.edu
; 
;HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2023-12-15 14:11:08 -0800 (Fri, 15 Dec 2023) $
;$LastChangedRevision: 32290 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/tpwrspc.pro $
;-
Pro tpwrspc, varname, newname = newname, $
             trange = trange,$
             freq_out=f,$
             power_out=p,$
              _extra = _extra
             

;First extract the data
  If(keyword_set(newname)) Then begin
    If(keyword_set(overwrite)) Then begin
      dprint, 'Do not set both the newname and overwrite keywords',dlevel=2
     ; message,/info,'Do not set both the newname and overwrite keywords'
      return
    Endif
    nvn = newname
  Endif Else nvn = varname+'_pwrspc'
;Now do the power spectrum
  get_data, varname, data = d, dlim = dlim, lim = lim
  
  ; Remove NaN points from data
  If(is_struct(d)) Then Begin
    t_nan = where((finite(d.x) eq 0) or (finite(d.y) eq 0), nancount, COMPLEMENT=goodpoints, NCOMPLEMENT=goodcount)
    IF goodcount GT 0 THEN begin
       d.x =  d.x[goodpoints]
       d.y =  d.y[goodpoints]
       dprint, 'NaN points were removed, count=' + string(nancount), dlevel=2
    endif
  endif
  
  If(is_struct(d)) Then Begin
    y = d.y
    t = (d.x-d.x[0])
    tav = average(d.x)
    If(n_elements(trange) Eq 2) Then Begin
      tr = time_double(trange)
      ok = where(d.x Ge tr[0] And d.x Lt tr[1], nok)
      If(nok Eq 0) Then Begin
        dprint, 'No data in time range',dlevel=2
        ;message,/info, 'No data in time range'
        dprint,  time_string(tr),dlevel=2
        dprint, 'No Power spectrum for: '+varname,dlevel=2
       ; message,/info,'No Power spectrum for: '+varname
        Return
      Endif Else Begin
        t = t[ok] & y = y[ok]
      Endelse
    Endif
    t00 = d.x[0]
    pwrspc, t, y, f, p, _extra = _extra
;hard to put this into a tplot variable, will use two time points
;spanning the time range
;    nf = n_elements(f)
;    f = rebin(transpose(temporary(f)), 2, nf)
;    p = rebin(transpose(temporary(p)), 2, nf)
;    tpf = minmax(t)+t00
;    d = {x:temporary(tpf), v:temporary(f), y:temporary(p)}
;    p = rebin(transpose(temporary(p)), 2, nf)
;At Vassilis's request, using single midpoint,instead of two points
;pcruce 2013-10-08

    d = {x:tav,v:reform(f,1,n_elements(f)),y:reform(p,1,n_elements(p))}

    If(keyword_set(overwrite)) Then newname = varname $
    Else newname = nvn
    str_element, dlim, 'data_type', 'power_spectrum', /add
    str_element, dlim, 'spec', 1, /add
    str_element, dlim, 'log', 1, /add
    store_data, newname, data = d, dlim = dlim, lim = lim
   Endif Else Begin
    dprint, 'No Power spectrum for: '+varname,dlevel=2
    ;message,/info, 'No Power spectrum for: '+varname
  Endelse
  newname = nvn
  Return
End

