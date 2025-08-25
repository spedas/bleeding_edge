;+
;Function: qdiv,q1,q2
;
;Purpose: divide q1 by q2, in other words returns a quaternion q3
;s.t. q3*q2 = q1
;
;Inputs: q1: a 4 element array, or an Nx4 element array, representing quaternion(s)
;        q2: a 4 element array, or an Nx4 element array, representing quaternion(s)
;
;Returns: q1/q2, or -1 on failure
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
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qdiv.pro $
;-

function qdiv,q1,q2

compile_opt idl2

;this is to avoid mutating the input variables
q1i = q1
q2i = q2

if(size(/n_dim,q1i) ne size(/n_dim,q2i)) then begin
   dprint,'Number of dimensions in quaternion q1 and quaternion q2 do not match'
   return,-1
endif

;check to make sure input has the correct dimensions
q1i = qvalidate(q1i,'q1','qmult')
q2i = qvalidate(q2i,'q2','qmult')

if(size(q1i,/n_dim) eq 0 && q1i[0] eq -1) then return,q1i

if(size(q2i,/n_dim) eq 0 && q2i[0] eq -1) then return,q2i

;make sure elements match
if(n_elements(q1i) ne n_elements(q2i)) then begin
   dprint,'Number of elements in quaternion q1 and quaternion q2 do not match'
   return,-1
endif

q2inv = qinv(q2i)

if ((size(/n_dim,q2inv) eq 0) and (q2inv[0] eq -1)) then begin
   message,'failed to invert quaternion 2'
   return,-1L
endif

qout = qmult(q2inv,q1)

if((size(/n_dim,qout) eq 0) and (qout[0] eq -1)) then begin
   message,'failed to multiply q2 inverse by q1'
   return,-1L
endif

return, reform(qout)

end
