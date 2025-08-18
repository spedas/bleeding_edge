;+
;NAME:
; fa_esa_pa
;PURPOSE:
; creates a pitch angle array for FAST ESA data;
;CALLING SEQUENCE:
; pa = fa_esa_pa(theta, theta_shift, mode_ind)
;INPUT:
; theta = an array of (96, 64, 2 or 3) of angle values
; theta_shift = an array of (ntimes) values for the offset to get
;               pitch angle from theta, PA = theta+theta_shift
; mode = 0, 1 (or 2) the mode index used to get the correct value of
;               theta_shift to apply for each time interval
;KEYWORDS:
;HISTORY:
; 2015-08-28, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-04-12 10:54:43 -0700 (Tue, 12 Apr 2016) $
; $LastChangedRevision: 20786 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_pa.pro $
;-
Function fa_esa_pa, theta, theta_shift, mode_ind

  ntimes = n_elements(mode_ind)
  If(n_elements(theta_shift) Ne ntimes) Then Return, -1
  theta_out = fltarr(96, 64, ntimes) & theta_out[*] = !values.f_nan
  
  mode0 = where(mode_ind Eq 0, nmode0)
  If(nmode0 Gt 0) Then Begin
     For j = 0, nmode0-1 Do theta_out[0, 0, mode0[j]] = theta[*, *, 0]+theta_shift[mode0[j]]
  Endif
  mode1 = where(mode_ind Eq 1, nmode1)
  If(nmode1 Gt 0) Then Begin
     For j = 0, nmode1-1 Do theta_out[0, 0, mode1[j]] = theta[*, *, 1]+theta_shift[mode1[j]]
  Endif
  mode2 = where(mode_ind Eq 2, nmode2)
  If(nmode2 Gt 0) Then Begin
     For j = 0, nmode2-1 Do theta_out[0, 0, mode2[j]] = theta[*, *, 2]+theta_shift[mode2[j]]
  Endif

;oops, pitch angle can be both Gt 360 and negative too
  xxx = where(theta_out Gt 360.0, nxxx)
  If(nxxx gt 0) Then theta_out[xxx] = theta_out[xxx] Mod 360.0

  yyy = where(theta_out Lt 0.0, nyyy)
  If(nyyy Gt 0) Then theta_out[yyy] = theta_out[yyy]+360.0

  Return, theta_out
End

