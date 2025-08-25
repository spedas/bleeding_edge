;+
;Function: qang,q
;
;Purpose: calculate the angle of a unit quaternion or an array of unit
;quaternions
;
;Inputs: q: a 4 element array, or an Nx4 element array, representing quaternion(s)
;
;Returns: phi where q = [cos(phi/2),V*sin(phi/2)]
;         throws error of failure, because negative one could be
;         an acceptable return value
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
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qang.pro $
;-

function qang,q

compile_opt idl2

;this is to avoid mutating the input variable
qi = q

;check to make sure input has the correct dimensions
qi = qvalidate(qi,'q','qang')

if(size(qi,/n_dim) eq 0 && qi[0] eq -1) then message,'invalid quaternion passed into qang.pro'

qn = qnorm(qi)

id = where(abs(qn-1D) gt 1e-9)

if(size(id,/n_dim) ne 0) then begin
   message,'can only calculate rotation angle of unit quaternions'
endif

out = atan(sqrt(total(qi[*,1:3]^2,0)),(qi[*,0])[*])*2

if(size(q,/n_dim) eq 1) then out = out[0]

return,out

end
