;+
;Function: qinv,q
;
;Purpose: calculate the inverse of a quaternion or an array of quaternions
;
;Inputs: q: a 4 element array, or an Nx4 element array, representing quaternion(s)
;
;Returns: q^-1
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
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-10-14 11:01:12 -0700 (Fri, 14 Oct 2016) $
; $LastChangedRevision: 22098 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qinv.pro $
;-

function qinv,q

compile_opt idl2

;this is to avoid mutating the input variable
qi = q

;check to make sure input has the correct dimensions
qi = qvalidate(qi,'q','qinv')

if(size(qi,/n_dim) eq 0 && qi[0] eq -1) then return,qi

qc = qconj(qi)

;if conjugation fails
if(size(qc,/n_dim) eq 0 && qc[0] eq -1) then return,qi

qn = qnorm(qi)

;if norm fails
if(size(qn,/n_dim) eq 0 && qn[0] eq -1) then return,qi

if total(qn eq 0) gt 0 then begin
   dprint,'0 length quaternion has no inverse'
   return,-1
endif

qn2=qn*qn

qtmp0 = qc[*,0]/qn2
qtmp1 = qc[*,1]/qn2
qtmp2 = qc[*,2]/qn2
qtmp3 = qc[*,3]/qn2

qout = [[qtmp0],[qtmp1],[qtmp2],[qtmp3]]

return,reform(qout)

end
