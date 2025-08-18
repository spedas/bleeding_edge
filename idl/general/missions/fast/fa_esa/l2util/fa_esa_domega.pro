;+
;NAME:
; fa_esa_domega
;PURPOSE:
; creates a pitch angle array for FAST ESA data;
;CALLING SEQUENCE:
; pa = fa_esa_domega(theta, theta_shift, mode_ind)
;INPUT:
; theta = an array of (96, 64, 2 or 3) of angle values
; dtheta = an array of (96, 64, 2 or 3) of dtheta values
; mode = 0, 1 (or 2) the mode index used to get the correct value of
;               dtheta to apply for each time interval
;KEYWORDS:
; domega_modes = the solid angle, domega for the different modes, this
;                will have the same dimensions as the input dtheta.
;HISTORY:
; 2015-02-09, hacked from fa_esa_pa, p_2d_new, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-02-09 14:01:24 -0800 (Tue, 09 Feb 2016) $
; $LastChangedRevision: 19919 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_domega.pro $
;-
Function fa_esa_domega, theta_in, dtheta_in, mode_ind, domega_modes = domega

  ntimes = n_elements(mode_ind)
; fill value is NaN
  domega_out = fltarr(96, 64, ntimes) & domega_out[*] = !values.f_nan
  theta = theta_in/!radeg
  dtheta = dtheta_in/!radeg

; For FAST data, pitch-angles wrap around past 180 (to 360). Since
; they do, then calculate an appropriate domega.
  nna = n_elements(theta[*, 0, 0])
  nb = n_elements(theta[0, *, 0])
  nmodes = n_elements(theta[0, 0, *])
  domega = dtheta
  For j = 0, nmodes-1 Do For a = 0, nna-1 Do For b = 0, nb-1 Do Begin
     If(abs(theta[a, b, j]-!pi) Lt dtheta[a, b, j]/2.) Then Begin
        th1 = (!pi+theta[a, b, j]-dtheta[a, b, j]/2.)/2.
        dth1 = (!pi-th1)
        th2 = (!pi+theta[a, b, j]+dtheta[a, b, j]/2.)/2.
        dth2 = (th2-!pi)
        domega[a, b, j] = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2))
     Endif Else If (abs(theta[a, b, j]-2*!pi) lt dtheta[a, b, j]/2.) Then Begin
        th1 = (2.*!pi+theta[a, b, j]-dtheta[a, b, j]/2.)/2.
        dth1 = (2.*!pi-th1)
        th2 = (2.*!pi+theta[a, b, j]+dtheta[a, b, j]/2.)/2.
        dth2 = (th2-2.*!pi)
        domega[a, b, j] = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2))
     Endif Else If(abs(theta[a, b, j]) Lt dtheta[a, b, j]/2.) Then Begin
        th1 = (theta[a, b, j]-dtheta[a, b, j]/2.)/2.
        dth1 = abs(th1)
        th2 = (theta[a, b, j]+dtheta[a, b, j]/2.)/2.
        dth2 = (th2)
        domega[a, b, j] = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2))
     Endif Else Begin
        th1 = theta[a, b, j]
        dth1 = dtheta[a, b, j]/2.
        domega[a, b, j] = 2.*!pi*abs(sin(th1))*sin(dth1)
     Endelse
  Endfor
;Now you have domega for each mode, get the full array  
  mode0 = where(mode_ind Eq 0, nmode0)
  If(nmode0 Gt 0) Then Begin
     For j = 0, nmode0-1 Do domega_out[0, 0, mode0[j]] = domega[*, *, 0]
  Endif
  mode1 = where(mode_ind Eq 1, nmode1)
  If(nmode1 Gt 0) Then Begin
     For j = 0, nmode1-1 Do domega_out[0, 0, mode1[j]] = domega[*, *, 1]
  Endif
  mode2 = where(mode_ind Eq 2, nmode2)
  If(nmode2 Gt 0) Then Begin
     For j = 0, nmode2-1 Do domega_out[0, 0, mode2[j]] = domega[*, *, 2]
  Endif

  Return, domega_out
End

