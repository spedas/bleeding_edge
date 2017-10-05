;+
;Procedure:
;  qham
;
;Purpose:
;  Calculate the Hamilton product of two quaternions
;
;Calling Sequence:
;  p = qham(q1,q2)
;
;Input:
;  q1: a 4 element array, or an Nx4 element array, representing quaternion(s)
;  q2: a 4 element array, or an Nx4 element array, representing quaternion(s)
;
;Output:
;  Returns Hamilton product (q1)(q2) or -1 on failure
;
;Notes:
;  General routine format copied from qdotp
;  Represention has q[0] = scalar component
;                   q[1] = vector x
;                   q[2] = vector y
;                   q[3] = vector z
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-11 18:04:52 -0800 (Thu, 11 Feb 2016) $
;$LastChangedRevision: 19966 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qham.pro $
;-

function qham,q1i,q2i

  compile_opt idl2, hidden

;this is to avoid mutating the input variables
q1 = q1i
q2 = q2i

if(size(/n_dim,q1) ne size(/n_dim,q2)) then begin
   dprint,'Number of dimensions in quaternion q1 and quaternion q2 do not match'
   return,-1
endif

;check to make sure input has the correct dimensions
q1 = qvalidate(q1,'q1','qham')
q2 = qvalidate(q2,'q2','qham')

if(size(q1,/n_dim) eq 0 && q1[0] eq -1) then return,q1

if(size(q2,/n_dim) eq 0 && q2[0] eq -1) then return,q2

;make sure elements match
if(n_elements(q1) ne n_elements(q2)) then begin
   dprint,'Number of elements in quaternion q1 and quaternion q2 do not match'
   return,-1
endif

qout = [  [ q1[*,0]*q2[*,0] - q1[*,1]*q2[*,1] - q1[*,2]*q2[*,2] - q1[*,3]*q2[*,3] ], $
          [ q1[*,0]*q2[*,1] + q1[*,1]*q2[*,0] + q1[*,2]*q2[*,3] - q1[*,3]*q2[*,2] ], $
          [ q1[*,0]*q2[*,2] - q1[*,1]*q2[*,3] + q1[*,2]*q2[*,0] + q1[*,3]*q2[*,1] ], $
          [ q1[*,0]*q2[*,3] + q1[*,1]*q2[*,2] - q1[*,2]*q2[*,1] + q1[*,3]*q2[*,0] ]  ] 


if(size(q1i,/n_dim) eq 1) then qout = qout[0]

return,reform(qout)

end
