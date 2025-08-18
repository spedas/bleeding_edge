;+
;Function: q_angular_velocity
;  av = q_angular_velocity(t,q)
;Purpose: Computer angular velocity of a rotation quaternion
;
;Reference:  http://www.euclideanspace.com/physics/kinematics/angularvelocity/QuaternionDifferentiation2.pdf
;
; Author: Davin Larson  
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-05-16 13:14:07 -0700 (Thu, 16 May 2019) $
; $LastChangedRevision: 27244 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/q_angular_velocity.pro $
;-
function q_angular_velocity, t,q,moving=moving
dq_dt = qderiv(t,q)
if keyword_set(moving) then omega =  qmult(qconj(q),dq_dt) *2    $ ; moving
else                        omega =  qmult(dq_dt,qconj(q)) *2   ; unmoving
return,omega
end


