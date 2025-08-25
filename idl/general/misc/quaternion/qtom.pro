;+
;Function: qtom
;
;Purpose: transforms quaternions into rotation matrices
;WARNING!!! It appears that this routine returns the transpose (inverse) of the rotation matrix!
;It differs from the CSPICE library and Wikipedia
;
;Inputs: a 4 element array representing a quaternion or an Nx4 element
;array representing an array of quaternions
;
;Returns: a 3x3 matrix or an Nx3x3 array
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qtom.pro $
;-


;this function was stolen from the euve quaternion
;library...incidentally the comment in the
;euve library indicates that this function was stolen from
;make_as(), in ~markh/gascan/progs/anc.incl
;lol

function qtom,q

compile_opt idl2

;this is to avoid mutating the input variable
qi = q

;check to make sure input has the correct dimensions
qi = qvalidate(qi,'q','qtom')

if(size(qi,/n_dim) eq 0 && qi[0] eq -1) then return,qi

e00 = qi[*,0] * qi[*,0]
e11 = qi[*,1] * qi[*,1]
e22 = qi[*,2] * qi[*,2]
e33 = qi[*,3] * qi[*,3]
e01 = 2 * qi[*,0] * qi[*,1]
e02 = 2 * qi[*,0] * qi[*,2]
e03 = 2 * qi[*,0] * qi[*,3]
e12 = 2 * qi[*,1] * qi[*,2]
e13 = 2 * qi[*,1] * qi[*,3]
e23 = 2 * qi[*,2] * qi[*,3]

mout = dblarr(n_elements(e00),3,3)

mout[*,0,0] = e00 + e11 - e22 - e33
mout[*,1,0] = e12 + e03
mout[*,2,0] = e13 - e02
mout[*,0,1] = e12 - e03
mout[*,1,1] = e00 - e11 + e22 - e33
mout[*,2,1] = e23 + e01
mout[*,1,2] = e23 - e01
mout[*,0,2] = e13 + e02
mout[*,2,2] = e00 - e11 - e22 + e33

return, reform(mout)

end
