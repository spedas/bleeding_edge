;+
;Function: qnorm,q
;
;Purpose: calculate the norm a quaternion or an array of quaternions
;
;Inputs: q: a 4 element array, or an Nx4 element array, representing quaternion(s)
;
;Returns: norm(q): sqrt(a^2+b^2+c^2+d^2) or -1L on fail
;                  will be a single element or an N length array
;         
;
;Notes: Implementation largely copied from the euve c library for
;quaternions
;Represention has q[0] = scalar component
;                 q[1] = vector x
;                 q[2] = vector y
;                 q[3] = vector z
;
;The vector component of the quaternion can also be thought of as
;an eigenvalue of the rotation the quaterion performs
;
;This implementation of norm does not apply the squareroot sometimes
;applied to a norm.  If required the sqrt can easily be applied by the user
;
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qnorm.pro $
;-

function qnorm,q

;this is to avoid mutating the input variable
qi = q

;check to make sure input has the correct dimensions
qi = qvalidate(qi,'q','qnorm')

if(size(qi,/n_dim) eq 0 && qi[0] eq -1) then return,qi

;the actual norm

dotp = qdotp(qi, qi)

if(size(dotp,/n_dim) eq 0 && dotp[0] eq -1) then begin

  dprint, 'failed to calculate the dot product of q.q'

  return, -1L

endif

out = sqrt(dotp)

if(size(q,/n_dim) eq 1) then out = out[0]

return,out

end
