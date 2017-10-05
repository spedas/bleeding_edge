;+
;NAME:
; fa_esa_energy
;PURPOSE:
; creates an energy angle array for FAST ESA data;
;CALLING SEQUENCE:
; pa = fa_esa_energy_array(energy, mode_ind)
;INPUT:
; energy = an array of (96, 64, 2 or 3) of energies
; mode = 0, 1 (or 2) the mode index used to get the correct value of
;               energy to apply for each time interval
;KEYWORDS:
;HISTORY:
; 2015-08-28, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-02-09 13:24:52 -0800 (Tue, 09 Feb 2016) $
; $LastChangedRevision: 19916 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_energy.pro $
;-
Function fa_esa_energy, energy, mode_ind

  ntimes = n_elements(mode_ind)
  fv = !values.f_nan
  energy_out = fltarr(96, 64, ntimes) & energy_out[*] = fv
  mode0 = where(mode_ind Eq 0, nmode0)
  If(nmode0 Gt 0) Then Begin
     For j = 0, nmode0-1 Do energy_out[0, 0, mode0[j]] = energy[*, *, 0]
  Endif
  mode1 = where(mode_ind Eq 1, nmode1)
  If(nmode1 Gt 0) Then Begin
     For j = 0, nmode1-1 Do energy_out[0, 0, mode1[j]] = energy[*, *, 1]
  Endif
  mode2 = where(mode_ind Eq 2, nmode2)
  If(nmode2 Gt 0) Then Begin
     For j = 0, nmode2-1 Do energy_out[0, 0, mode2[j]] = energy[*, *, 2]
  Endif
  Return, energy_out
End
