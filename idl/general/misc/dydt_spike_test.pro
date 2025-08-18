;+
;NAME:
; dydt_spike_test
;PURPOSE:
; This function checks an array for spikes based on its time
; derivative. This is designed mostly for THEMIS GMAG spikes that
; persist over multiple data points, but should work on single data
; point spikes too.
;CALLING SEQUENCE:
; flag = dydt_spike_test(t0, y0, dydt_lim = dydt_lim, $
;                        sigma_y = sigma_y, nsig = nsig, $
;                        no_degap = no_degap, pad=pad, $
;                        degap_margin = degap_margin, $
;                        degap_dt = degap_dt, _extra = _extra)
;INPUT:
; t0 = a time array
; y0 = a data aray, same number of elements as t0
;OUTPUT:
; flag = a bytarr(n_elements(t0)), set to 1 for spikes, 0 for ok data,
;        note that NaN values are automatically set to 1
;KEYWORDS:
; dydt_lim =  a value for the max. allowed derivative, the default is
;             to calculate a limiting value from the uncertainty in
;             the data. 
; sigma_y = if known, an estimate of the standard deviation in y0
;           values. The default is to use sqrt(y), as if you have a
;           photon count for data. If you do not know
;           this uncertainty in Y, it might be a good idea to use
;           dydt_lim.
; nsig = the number of uncertainties in dydt that will be used to
;        obtain the limit value at each data point.
; pad = pad the spike flag on either side by this many data points.
; no_degap = By default, the program calls xdegap and xdeflag routines
;            to deal with gaps in the data. Set this keyword to avoid
;            this.
;DEGAP KEYWORDS:
; nowarning = if set, suppresses warnings
; maxgap = the maximum gap size filled, in seconds
; degap_dt = a time_interval for the degap process, the default is to
;            use the minimum of the time resolutions in the data,
;            i.e., min(t0[1:*]-t0)
; degap_margin = a margin value for the degap call, the default is to
;                use the minimum of the time resolutions in the data,
;                i.e., min(t0[1:*]-t0)
;                
;HISTORY:
; 7-apr-2008, jmm, jimm@ssl.berkeley.edu
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2013-03-13 12:57:13 -0700 (Wed, 13 Mar 2013) $
;$LastChangedRevision: 11796 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/dydt_spike_test.pro $
;-
Function dydt_spike_test, t0, y0, dydt_lim = dydt_lim, $
                          sigma_y = sigma_y, nsig = nsig, $
                          no_degap = no_degap, $
                          degap_dt = degap_dt, $
                          degap_margin = degap_margin, $
                          _extra = _extra

  nt = n_elements(t0) & ny = n_elements(y0)
  flag = bytarr(nt)
  If(nt Ne ny) Then Begin
    dprint, dlevel=1, 'Array mismatch'
    return, flag
  Endif
;care needs to be taken with NaN values, because these will affect
;adjacent points
  ok = where(finite(y0), nok)
  not_ok = where(finite(y0) Eq 0, nnot_ok)
  If(nnot_ok Gt 0) Then flag[not_ok] = 1
  If(nok Lt 3) Then Begin
    dprint, dlevel=1, 'Not enough good data'
    return, flag
  Endif
  t_in = t0[ok]
  t_in = t_in-t_in[0]
  y_in = y0[ok]
  f_in = bytarr(nok)
;Degap if not told not to
  If(Not Keyword_set(no_degap)) Then Begin
    dt0 = min(t_in[1:*]-t_in)          ;use the smallest dt value for gaps
    If(dt0 Eq 0) Then Begin
      dprint, dlevel=1, 'Warning: Duplicate time values.'
      dtt = t_in[1:*]-t_in
      xtt = where(dtt Gt 0)
      If(xtt[0] Ne -1) Then Begin
        dt0 = min(dtt[xtt])
      Endif Else Begin
        dprint, dlevel=1, 'No Nonzero dt values, returning'
        Return, flag
      Endelse
    Endif
    If(keyword_set(degap_margin)) Then margin = degap_margin $
    Else margin = dt0
    If(keyword_set(degap_dt)) Then dt = degap_dt Else dt = dt0
    dtmed = median(t_in[1:*]-t_in)    ;try a median test here..
    If(dt Lt 5*dtmed) Then dt = 5.0*dtmed
    xdegap, dt, margin, t_in, y_in, t, y, iindices = ii, _extra = _extra, /onenanpergap
    If(t[0] Eq -1) Then Goto, didnt_degap ;No degapping happened
    xdeflag, 'repeat', t, y, _extra = _extra
    nok = n_elements(t)         ;all of this data is ok....
    f = bytarr(nok)
  Endif Else Begin
    didnt_degap:
    t = t_in & y = y_in & f = f_in & ii = lindgen(n_elements(t_in))
  Endelse
  dydt = deriv(t, y)
;The default is to check the derivative against nsigs*it's
;uncertainty, but the threshold can be set too
  If(keyword_set(dydt_lim)) Then Begin
    dydt0 = replicate(dydt_lim, nok)
  Endif Else Begin
    If(keyword_set(nsig)) Then nsg = nsig Else nsg = 10.0 ;we're talking spike removal
    If(keyword_set(sigma_y)) Then Begin
      sy = replicate(sigma_y[0], nok)
    Endif Else sy = sqrt(abs(y))
    dydt0 = abs(nsg*derivsig(t, y, 0.0, sy))
  Endelse
;A spike happens when the derivative is larger than the threshold
;value, it'll remain a spike until: a) the derivative passes through 0
;and then below the threshold, or b) the end of the array.
  c1 = abs(dydt) Gt dydt0
  ww = where(c1)
  If(ww[0] Eq -1) Then Begin
    flag[ok] = f[ii]            ;ii are the indices of the original data
    Return, flag
  Endif
  sgn = intarr(nok)
  z0d = where(dydt Ne 0.0)     ;there has to be something here by now
  sgn[z0d] = dydt[z0d]/abs(dydt[z0d])
  j = ww[0]
  loopx:                        ;maybe loop back here
  st_pt = j                     ;should never change
  dn = where(sgn[j:*] Ne sgn[j], ndn) ;sgn[j] isn't going to be zero
;Ok, two possibilities, 1) it never reaches a peak (or min), 2) it
;peaks and recovers. 
  If(ndn Eq 0) Then Begin       ;No peak, flag everything and return
    f[j:*] = 1
    flag[ok] = f[ii]
    Return, flag
  Endif Else Begin
;ok, now here you've passed the peak, and the derivative has changed
;signs, two things can happen: 1) the abs value of the derivative can
;be greater than the threshold value, or 2) not. The first is easy,
;you simply end the spike where the abs value of the derivative drops
;below the threshold. For the second, the best that you can do is end
;the spike where the derivative changes signs again.
    j0 = dn[0]+j                ;the turnaround or peak point
    j1 = dn[0]+j+1       ;this is the point *after* the peak pt.      
    If(j1 Lt nok-1) Then Begin
      back_up = where(sgn[j1:*] Eq sgn[j] Or sgn[j1:*] Eq 0, nback_up)+j1
      c2 = where(abs(dydt[j0:*]) Gt dydt0[j] And sgn[j0:*] Ne sgn[j], nc2)+j0
      If(nback_up Gt 0) Then Begin
        en_pt = back_up[0]      ;unless
        If(nc2 Gt 0) Then Begin
;find the last pt. of big derivative with the opposite sign of the original
;but happening before the first back_up point. This should be the most
;likely result
          test = where(c2 Lt back_up[0], ntest)
          If(ntest Gt 0) Then en_pt = max(c2[test])
        Endif
      Endif Else Begin       ;oh my, the derivative never gets back up
        If(nc2 Gt 0) Then Begin
;find the last pt. of big derivative with the opposite sign of the
;original, we'll still stop the spike if we can
          en_pt = max(c2)
        Endif Else Begin        ;everything is a spike, again
          f[j:*] = 1
          flag[ok] = f[ii]
          Return, flag
        Endelse
      Endelse
    Endif Else en_pt = nok-1
  Endelse
;If you are here, you have an end point, set the flag, and loop back
;up if necessary:
  If(keyword_set(pad)) Then Begin
    st_pt = (st_pt - pad) > 0
    en_pt = (en_pt + pad) < (nok-1)
  Endif Else en_pt = en_pt < (nok-1)
  f[st_pt:en_pt] = 1
  flag[ok] = f[ii]
;test for more spikes
  If(en_pt Lt nok-1) Then Begin
    c1 = abs(dydt[en_pt+1:*]) Gt dydt0[en_pt+1:*]
    ww = where(c1)
    If(ww[0] Ne -1) Then Begin
      j = en_pt+1+ww[0]
      Goto, loopx
    Endif
  Endif
;Done
  Return, flag
End
