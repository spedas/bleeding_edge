;+
;FUNCTION:   rotate_mag_to_swe
;PURPOSE:
;  Rotates input vectors from MAG instrument coordinates to
;  SWEA FSW coordinates.
;
;USAGE:
;  v_out = rotate_mag_to_swe(v_in)
;
;INPUTS:
;       v_in:     Input vectors with dimensions of N x 3.  The result
;                 will have the same dimensions.
;
;KEYWORDS:
;
;       MAGU:     Identifies the MAG sensor unit: 1 or 2.  Default is 1.
;                 (MAG1 is used for on-board pitch angle mapping.)
;
;       STOW:     Calculate the transformation for a stowed SWEA boom.
;                 Default assumes a deployed boom.
;
;       PAYLOAD:  Input vectors are in payload coordinates.
;
;       INVERSE:  Reverse the rotation: swe to mag coordinates.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/rotate_mag_to_swe.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
function rotate_mag_to_swe, v_in, magu=magu, stow=stow, inverse=inverse, payload=payload
  
  if (size(v_in,/type) eq 0) then begin
    print,"You must specify an N x 3 input array."
    return, 0
  endif
  
  npts = dimen(v_in)
  if (n_elements(npts) gt 2) then begin
    print,"Input array dimensions must be N x 3."
    return, 0
  endif
  if ((reverse(npts))[0] ne 3) then begin
    print,"Input array dimensions must be N x 3."
    return, 0
  endif
  
  if not keyword_set(magu) then magu = 1
  if keyword_set(stow) then stow = 1 else stow = 0
  if keyword_set(payload) then pl = 1 else pl = 0

; MAG-1 is the located at the end of the +Y solar panel.  +X_mag1 is aligned with
; +X_sc.  There is a -20 degree rotation about X_mag1 to transform MAG1 coordinates
; to spacecraft coordinates.
;
; MAG-2 is the located at the end of the -Y solar panel.  +X_mag2 is aligned with
; -X_sc.  There is a -20 degree rotation about X_mag2 to align +Y_mag2 with -Y_sc 
; and +Z_mag2 with +Z_sc.  Then a 180-deg rotation about Z_mag2 transforms MAG2
; coordinates to spacecraft coordinates.
;
; SWEA is located at the end of a 1.5-meter boom.  When deployed, SWEA coordinates are
; aligned with spacecraft coordinates: +X_swea = +X_sc, +Y_swea = +Y_sc, +Zswea = +Z_sc.
; The SWEA +X axis is aligned with the purge port axis.

; Rotate by +140 degrees about Z_sc to align +X_sc with +X_fsw (Anode 15-0 boundary).

  alpha = 140.*!dtor

  rot1 = fltarr(3,3)
  rot1[*,0] = [ cos(alpha),  sin(alpha),          0. ]
  rot1[*,1] = [-sin(alpha),  cos(alpha),          0. ]
  rot1[*,2] = [         0.,          0.,          1. ]

; If the SWEA boom is stowed, rotate by +135 degrees about Y_sc to align Z_sc with Z_fsw

  if (stow) then gamma = 135.*!dtor else gamma = 0.
  
  rot2 = fltarr(3,3)
  rot2[*,0] = [ cos(gamma),          0., -sin(gamma) ]
  rot2[*,1] = [         0.,          1.,          0. ]
  rot2[*,2] = [ sin(gamma),          0.,  cos(gamma) ]

; Rotate by 180 degrees about Zmag2 = Z_sc to transform MAG2 coordinates to spacecraft
; coordinates: X -> -X ; Y -> -Y.  Skip this rotation for MAG1.

  if ((magu eq 2) and (pl eq 0)) then delta = 180.*!dtor else delta = 0.

  rot3 = fltarr(3,3)
  rot3[*,0] = [ cos(delta),  sin(delta),          0. ]
  rot3[*,1] = [-sin(delta),  cos(delta),          0. ]
  rot3[*,2] = [         0.,          0.,          1. ]

; Rotate about X_mag by -20 degrees (angle between inner and outer solar panels
; to form "gull wing")

  if (pl) then beta = 0. else beta = -20.*!dtor
  
  rot4 = fltarr(3,3)
  rot4[*,0] = [         1.,          0.,          0. ]
  rot4[*,1] = [         0.,   cos(beta),   sin(beta) ]
  rot4[*,2] = [         0.,  -sin(beta),   cos(beta) ]

; Combine the rotations and apply to the input array

  mtx = (rot1 ## (rot2 ## (rot3 ## rot4)))
  
  if keyword_set(inverse) then mtx = transpose(mtx)

  return, mtx ## v_in

end
