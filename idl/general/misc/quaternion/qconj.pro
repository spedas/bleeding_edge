;+
;Function: qconj,q
;
;Purpose: calculate the conjugate a quaternion or an array of quaternions
;
;Inputs: q: a 4 element array, or an Nx4 element array, representing quaternion(s)
;
;Returns: q*
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qconj.pro $
;-

function qconj,q

compile_opt idl2

;this is to avoid mutating the input variable
qi = q

;check to make sure input has the correct dimensions
qi = qvalidate(qi,'q','qconj')

if(size(qi,/n_dim) eq 0 && qi[0] eq -1) then return,qi

;the actual conjugation
qtmp0 = qi[*,0]
qtmp1 = -qi[*,1]
qtmp2 = -qi[*,2]
qtmp3 = -qi[*,3]

qout = [[qtmp0],[qtmp1],[qtmp2],[qtmp3]]

if(size(q,/n_dim) eq 1) then qout = reform(qout)

return,qout

end


