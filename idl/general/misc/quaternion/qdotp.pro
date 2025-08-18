;+
;Function: qdotp,q1,q2
;
;Purpose: calculate the dot product of two quaternions or two arrays of quaternions
;
;Inputs: q1: a 4 element array, or an Nx4 element array, representing quaternion(s)
;        q2: a 4 element array, or an Nx4 element array, representing quaternion(s)
;
;Returns: q1.q2, or -1 on failure
;
;;Notes: 
;Represention has q[0] = scalar component
;                 q[1] = vector x
;                 q[2] = vector y
;                 q[3] = vector z
;
;The vector component of the quaternion can also be thought of as
;an eigenvalue of the rotation the quaterion performs
;
;The scalar component can be thought of as the amount of rotation that
;the quaternion performs
;
;like any vector the if t = the angle between q1 and q2 in 4-space
;the q1.q2 = ||q1||*||q2||*cos(t) where || denotes the norm(length) of
;the quaternion in 4-space
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-23 16:50:12 -0800 (Mon, 23 Jan 2012) $
; $LastChangedRevision: 9593 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qdotp.pro $
;-

function qdotp,q1,q2

compile_opt idl2

;this is to avoid mutating the input variables
q1i = q1
q2i = q2

if(size(/n_dim,q1i) ne size(/n_dim,q2i)) then begin
   dprint,'Number of dimensions in quaternion q1 and quaternion q2 do not match'
   return,-1
endif

;check to make sure input has the correct dimensions
q1i = qvalidate(q1i,'q1','qdotp')
q2i = qvalidate(q2i,'q2','qdotp')

if(size(q1i,/n_dim) eq 0 && q1i[0] eq -1) then return,q1i

if(size(q2i,/n_dim) eq 0 && q2i[0] eq -1) then return,q2i

;make sure elements match
if(n_elements(q1i) ne n_elements(q2i)) then begin
   dprint,'Number of elements in quaternion q1 and quaternion q2 do not match'
   return,-1
endif

qout = total(q1i*q2i, 2)

if(size(q1,/n_dim) eq 1) then qout = qout[0]

return,reform(qout)

end
