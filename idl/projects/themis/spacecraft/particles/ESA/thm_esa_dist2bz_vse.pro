;+
;NAME:
; thm_esa_dist2bz_vse
;CALLING SEQUENCE:
; otp = thm_esa_dist2bz_vse(data)
;PURPOSE:
; Finds a pitch angle for an electron distribution, by calculating
; eigenvectors and eigenvalues for the distribution, using the pressure
; tensor.
; The idea here is that for the pressure tensor, there will be two very
; similar eigenvalues (p_parallel), and one dissimilar (p_perp). If
; p_par >> p_perp, then electron "cigar" distribution, if p_par <<
; p_perp, then "pancake" distribution. This will give us an angle,
; theta, for the field relative to the Z axis, and then Bz =
; tan(theta)*sqrt(Bx^2+By^2)/ Spin period resolution is needed to
; average out the azimuthal effects.
;INPUT:
; data = 3d data structure filled by themis routines get_th?_p???
;KEYWORDS:
; channel_range = the energy channels to use, the default is all
;                 channels
; sim_threshold = If the two most similar eigenvalues are more than
;                 this value apart, then discard this energy range
;                 for this time interval. Default is 0.10 (10%)
; ani_threshold = If the most dissimilar eigenvaule is less than this
;                 value different than the other two, then discard this
;                 energy range for this time interval. Default is 0.20
;                 (20%)
;HISTORY:
; Hacked from thm_dist2scpot.pro, 2024-06-04, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;
;-
Function thm_esa_dist2bz_vse, tempdat, eva, $
                              channel_range = channel_range, $ ;goes into moments_3d
                              sim_threshold = sim_threshold, $
                              ani_threshold = ani_threshold, $
                              _extra=_extra

  If(~is_struct(tempdat) || tempdat.valid Eq 0) Then Begin
     dprint, 'Invalid Data'
     Return, -1
  Endif

  If(Keyword_set(sim_threshold)) Then svalue = sim_threshold Else svalue = 0.10
  If(Keyword_set(ani_threshold)) Then pvalue = ani_threshold Else avalue = 0.20

  data3d = conv_units(tempdat,'Eflux')
  
  If(~keyword_set(channel_range)) Then chan = [0, data3d.nenergy-1] $ ;all channels, but maybe energy range
  Else chan = channel_range

;Call moments_3d for this channel range
  mom = moments_3d(data3d, /no_unit_conversion, erange = chan)

  If(~is_struct(mom) || mom.valid Eq 0) Then Begin
     dprint, 'Invalid Moments'
     Return, -1
  Endif
  
;Here I presumably have a pressure tensor, in 6 elements
;[pxx,pyy,pzz,pxy,pxz,pyz]
  map3x3 = [[0,3,4],[3,1,5],[4,5,2]] ;used to convert the 6 element ptens to 3x3
  mapt   = [0,4,8,1,2,5]             ;used to convert 3x3 ptens back to 6 elements
  pt3x3 = double(mom.ptens[map3x3])
  a = pt3x3
;Here use trired, triql to get eigenvalues and eigenvectors, d are
;values and a are vectors, so that
; pt3x3#a[*,j] = d[j]*a[*,j]
  trired, a, d, e
  triql, d, e, a
;check for a 'good approximation, so that the max (or min) value is far
;from the other two, which are close together. Check max value first
  ss = sort(d)
  eva = d[ss]
  evec = a[*,ss]
;The max value is eva[2]
;There are two options for which we will find the anisotropic
;distribution, max value > (1+ani_threshold)*mean(other_two) and
;diff(other_two) < sim_threshold*mean(other_two) Or min_value <
;(1-ani_threshold)*mean(other_two) and diff(other_two) <
;sim_threshold*mean(other_two)
;Are two values close together?
  mean01 = 0.5*(eva[0]+eva[1])  ;to compare with max value
  diff01 = abs(eva[0]-eva[1])
  If(diff01 Le svalue*abs(mean01)) Then ok_close_01 = 1b Else ok_close_01 = 0b
  mean12 = 0.5*(eva[1]+eva[2]) ;to compare with min value
  diff12 = abs(eva[1]-eva[2])
  If(diff12 Le svalue*abs(mean12)) Then ok_close_12 = 1b Else ok_close_12 = 0b
  If(~ok_close_01 And ~ok_close_12) Then Begin
;     print, 'No close values'
;     print, eva
     Return, -1                 ;no deal
  Endif
  If(ok_close_01) Then Begin    ;here the max value must be larger than the other two
     If(abs(eva[2]) Ge (1+avalue)*abs(mean01)) Then Begin ;success
;get the theta angle from the eigenvector
        cart_to_sphere,evec[0,2],evec[1,2],evec[2,2],r,theta,phi
        Return, {eva:eva[2], evec:evec[*,2], theta:theta}
     Endif Else Begin
;        print, 'Max value too close'
;        print, eva
        Return, -1
     Endelse
  Endif
  If(ok_close_12) Then Begin    ;here the min value must be smaller than the other two
     If(abs(eva[0]) Le (1-avalue)*abs(mean12)) Then Begin ;success
        cart_to_sphere,evec[0,0],evec[1,0],evec[2,0],r,theta,phi
        Return, {eva:eva[0], evec:evec[*,0], theta:theta}
     Endif Else Begin
;        print, 'Min value too close'
;        print, eva
        Return, -1
     Endelse
  Endif
;You should never get here
  Return, -1
End
