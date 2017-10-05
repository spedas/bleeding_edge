;+
;Function: q_angular_velocity
;  av = q_angular_velocity(t,q)
;Purpose: Computer angular velocity of a rotation quaternion
;
;Reference:  http://www.euclideanspace.com/physics/kinematics/angularvelocity/QuaternionDifferentiation2.pdf
;
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
function q_angular_velocity, t,q,moving=moving
dq_dt = qderiv(t,q)
if keyword_set(moving) then omega =  qmult(qconj(q),dq_dt) *2    $ ; moving
else                        omega =  qmult(dq_dt,qconj(q)) *2   ; unmoving
return,omega
end


