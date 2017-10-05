;+
;NAME:
; thm_esa_dist2scpot
;CALLING SEQUENCE:
; scpot = thm_esa_dist2scpot(data)
;PURPOSE:
; Estimates the SC potential from an electron sepctrum, by comparing
; the slope of the electron energy distribution with the slope that
; would be expected from secondary electrons.
;INPUT:
; data = 3d data structure filled by themis routines get_th?_p???
;KEYWORDS:
; pr_slope = if set, show some diagnostics prints of the slope of the
;            distribution
; noise_threshold = values below Noise_threshold*max(flux) are
;                   considered to be in noise, if there is a positive 
;                   slope, it is ignored. The default is 1.0e-3
; photoelectron_threshold = Only test for photoelctrons if the flux
;                           is above this value, The default is 1.0e7
;HISTORY:
; Hacked from spec3d.pro, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-10-02 11:19:09 -0700 (Mon, 02 Oct 2017) $
; $LastChangedRevision: 24078 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_dist2scpot.pro $
;
;-
Function thm_esa_dist2scpot, tempdat, pr_slope = pr_slope, $
                             noise_threshold = noise_threshold, $
                             photoelectron_threshold = photoelectron_threshold, $
                             _extra=_extra

  If(~is_struct(tempdat) || tempdat.valid eq 0) Then Begin
     dprint, 'Invalid Data'
     Return, -1
  Endif

  If(Keyword_set(noise_threshold)) Then nvalue = noise_threshold Else nvalue = 1.0e-3
  If(Keyword_set(photoelectron_threshold)) Then pvalue = photoelectron_threshold $
  Else pvalue = 3.0e7

  data3d = conv_units(tempdat,'Eflux')
  data3d.data = data3d.data*data3d.denergy/(data3d.denergy+.00001)
  If(ndimen(data3d.data) Eq ndimen(data3d.bins)) Then data3d.data=data3d.data*data3d.bins

  nb = data3d.nbins

;Estimate potential by grabbing the highest energy with a slope Gt M,
;where M is 2 at the low energy end, say 8 eV to 6 at 50 eV, to pick
;up photoelectrons.  The lower limit to the potential is the lowest
;energy, the upper limit will be 100 V

  nenergy = data3d.nenergy
  If(data3d.nbins Eq 1) Then odat2 = data3d Else odat2 = omni3d(data3d)
  energy = rotate(odat2.energy, 2)
  dist = rotate(odat2.data, 2)

;Dump zero values
  ok = where(finite(dist) And (dist Gt 0), nok)
  If(nok Lt 5) Then Begin
     dprint, 'Invalid Data'
     Return, -1
  Endif
  energy = energy[ok] & dist = dist[ok]
  nenergy = n_elements(energy)

  slope = alog10(dist[1:*]/dist[0:nenergy-2])/alog10(energy[1:*]/energy[0:nenergy-2])
;Add a restriction that the slope should go positive at some point
;beyond the negative slope, and there should be a reasonable non-noise
;value of the distribution too,
  nen1 = n_elements(slope)
  pflag = bytarr(nen1)
  For j = 0, nen1-2 Do Begin
     pflj = where(slope[j:*] Gt 0 And $
                  dist[j+1:*] Gt nvalue*max(dist), npflj)
     If(npflj Gt 0) Then Begin 
        pflag[j] = 1
     Endif
  Endfor

;and also the flux below the low energy part of the given slope should be
;greater than some threshold, say 5.0e7
  threshold_flag = dist[0:nenergy-2] Gt pvalue
  For j = 0, nenergy-2 Do Begin
     yes = where(dist[0:j] gt pvalue, nj)
     If(nj Gt 0) Then threshold_flag[j] = 1b
  Endfor
  
;Note that these numbers are empirical, except for the lower linit,
;which is determined by the slope of the secondary electrons.
  yy0 = 2.0 & yy1 = 4.0
  xx0 = 8.0 & xx1 = 50.0
;  zz0 = 0.10                    ;test for positive slope
  bm = (yy0-yy1)/(xx0-xx1)
  am = yy0 - bm*xx0
  m = (am + bm * energy) > 2.0
;The magic slope is -m
  If(keyword_set(pr_slope)) Then print, slope, -m, energy, dist
  sltest = where(slope Lt -m and pflag Gt 0 and threshold_flag, nsltest)

  If(nsltest Eq 0 || (min(energy[sltest]) Gt 100.0)) Then Begin
     sc_pot_est = energy[0]
  Endif Else Begin
     i = sltest[0]
     While (slope[i] Lt -m[i] and energy[i] Lt 100.0) Do Begin
        i = i+1
     Endwhile
;     print, -m[0:i], slope[0:i], energy[0:i]
     sc_pot_est = energy[i]
;Here we estimate the fractional difference in energy band, to
;unquantize the sc_pot value. The steeper the slope, the closer to the
;full value you get. ALso the slope really refers to the midpoint
;between energies i and i-1
     If(i Gt 0) Then Begin
        delta_e = energy[i]-energy[i-1]
;since slope[i-1] < -1.0 , de is positive but less than delta_e
        de = delta_e*(1.0-slope[i-1]/2.0)/(1.0-slope[i-1])
        sc_pot_est_0 = sc_pot_est
        sc_pot_est = energy[i-1]+de
        If(keyword_set(pr_slope)) Then print, sc_pot_est_0, sc_pot_est
     Endif
  Endelse

  Return, sc_pot_est

End
