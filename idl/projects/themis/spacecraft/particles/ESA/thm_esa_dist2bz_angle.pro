;+
;NAME:
; thm_esa_dist2bz_angle
;CALLING SEQUENCE:
; bz = thm_esa_dist2bz(data)
;PURPOSE:
; Estimates the angle between the direction of the electron
; distribution, and the Z (spin axis) axis sepctrum, by comparing the
; parallel and perpendicular values of pressure tensor eigenvalues.
; This function calls the function thm_esa_dist2bz_vse for different
; energy ranges.
;INPUT:
; data = 3d data structure filled by themis routines get_th?_p???
;KEYWORDS:
; theta_threshold = Only use energy bands for which the theta value is
;                   closer to the median than this value, default is
;                   3.0 degrees.
; nband_min = If there are fewer than this ok energy bands, thne no
;             solution, the default is 3.
; sim_threshold = If the two most similar eigenvalues are more than
;                 this value apart, then discard this energy range
;                 for this time interval. Default is 0.10 (10%)
; ani_threshold = If the most dissimilar eigenvaule is less than this
;                 value different than the other two, then discard this
;                 energy range for this time interval. Default is 0.20
;                 (20%)
; av_theta = the average value of theta for the Ok energy bands, the
;            output will be slightly different, and will be the value
;            of theta calculated from the average of the eigenvectors
;            for the ok energy bands.
; The idea here is that for the pressure tensor, there will be two very
; similar eigenvalues (p_parallel), and one dissimilar (p_perp). If
; p_par >> p_perp, then electron "cigar" distribution, if p_par <<
; p_perp, then "pancake" distribution. This will give us an angle,
; theta, for the field relative to the Z axis, and then Bz =
; tan(theta)*sqrt(Bx^2+By^2)/ Spin period resolution is needed to
; average out the azimuthat effects.
;HISTORY:
; Hacked from thm_dist2scpot.pro, 2024-06-04, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;
;-
Function thm_esa_dist2bz_angle, tempdat, theta_threshold = theta_threshold, $
                                nband_min = nband_min, av_theta = av_theta, $
                                _extra=_extra

  otp = -1 & theta_av = -1
  If(~is_struct(tempdat) || tempdat.valid Eq 0) Then Begin
     dprint, 'Invalid Data'
     Return, otp
  Endif

  nn = tempdat.nenergy
  eva_all = fltarr(nn-2)+!values.f_nan ;No values for the top and bottom energies
  evec_all = fltarr(3, nn-2)+!values.f_nan
  theta_all = fltarr(nn-2)+!values.f_nan
  energy_mid = fltarr(nn-2)
  okj = bytarr(nn-2)
;For each energy band, get eigenvectors, and values, each band
;contains 3 energy channels, for channels 1 to nn-2
  eva_vse = fltarr(3, nn-2)
  For j = 0, nn-3 Do Begin
     energy_mid[j] = tempdat.energy[j+1,0]
     x1j = thm_esa_dist2bz_vse(tempdat, evaj, channel_range=[j,j+2])
     eva_vse[*, j] = evaj
     If(is_Struct(x1j)) Then Begin
        okj[j] = 1
        eva_all[j] = x1j.eva
        evec_all[*, j] = x1j.evec
        theta_all[j] = x1j.theta
     Endif
  Endfor
;Apply thresholds, there must be nmin values within thth degrees of
;the median theta value
  If(keyword_set(theta_threshold)) Then thth = theta_threshold Else thth = 3.0
  If(keyword_set(nband_min)) Then nmin = nband_min Else nmin = 3
  ss_ok = where(okj Eq 1, nok)
  If(nok Lt nmin) Then Return, otp ;Not enough good values
  keep_theta = where(okj Eq 1 And abs(theta_all-median(theta_all[ss_ok])) Lt thth, nkeep)
  If(nkeep Lt nmin) Then Return, otp ;Not enough good values
;get average of theta and eigenvector
  av_theta = mean(theta_all[keep_theta])
  x = mean(evec_all[*, keep_theta],dimension=2)
  cart_to_sphere,x[0],x[1],x[2],r,theta,phi
  otp = {r:r, theta:theta, phi:phi}

  Return, otp
End


