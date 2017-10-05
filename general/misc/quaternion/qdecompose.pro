;+
;Function: qdecompose,q
;
;Purpose: decompose quaternions into axes and angeles
;
;Inputs: q:  a 4 element quaternion or an Nx4 element array of quaternions
;
;Returns: a 4 element array with a[0] = angle, and a[1:3] = axis, or
;an Nx4 element array or -1L on failure
;
;;Notes: Implementation largely copied from the euve c library for
;quaternions
;Represention has q[0] = scalar component
;                 q[1] = vector x
;                 q[2] = vector y
;                 q[3] = vector z
;
;The vector component of the quaternion can also be thought of as
;an eigenvalue of the rotation the quaterion performs
;
;As per the euve implementation, if q[0] is outside of the range of
;acos...[-1,1] the value of the quaternion will be turned into an
;identity quaternion...in other words clipped, this seems suspect,
;a better solution may be to wrap the value back into range using
;modular arithmatic, future modifiers of this routine should consider
;adding this.
;
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-10-14 11:01:12 -0700 (Fri, 14 Oct 2016) $
; $LastChangedRevision: 22098 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qdecompose.pro $
;-

function qdecompose,q


EPSILON = 1.0e-20  ;Where sin(theta) is close enough to theta

compile_opt idl2

;this is to avoid mutating the input variable
qi = q

;check to make sure input has the correct dimensions
qi = qvalidate(qi,'q','qdecompose')

if(size(qi,/n_dim) eq 0 && qi[0] eq -1) then return,qi

qdims = size(qi,/dimensions)

aout = make_array(qdims,/double)

;the following code will clip into range
idx = where(qi[*,0] ge 1.0D)

if(idx[0] ne -1) then begin

   aout[idx,0] = 0.0D
   aout[idx,1] = 1.0D
   aout[idx,2:3] = 0.0D

endif

idx = where(qi[*,0] le -1.0D)

if(idx[0] ne -1) then begin

   aout[idx,0] = 2*!DPI
   aout[idx,1] = 1.0D
   aout[idx,2:3] = 0.0D

endif

idx = where(qi[*,0] gt -1.0D and qi[*,0] lt 1.0D)

if(idx[0] ne -1) then begin

   theta2 = acos(qi[idx,0])

   aout[idx,0] = 2 * theta2

   idx2 = where(theta2 lt EPSILON)

   if(idx2[0] ne -1) then begin

      aout[idx[idx2],1] = 1.0D
      aout[idx[idx2],2:3] = 0.0D

   endif

   idx2 = where(theta2 ge EPSILON)

   if(idx2[0] ne -1) then begin

      aout[idx[idx2],1] = qi[idx[idx2],1] / sin(theta2[idx2])
      aout[idx[idx2],2] = qi[idx[idx2],2] / sin(theta2[idx2])
      aout[idx[idx2],3] = qi[idx[idx2],3] / sin(theta2[idx2])

   endif

endif

return,reform(aout)

end
