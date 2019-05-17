;+
;Function: qderiv
;  gets derivative of quaternion - assumes sign ambiguity has been fixed
;
;Purpose: ;
; Author: Davin Larson  
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-05-16 13:14:07 -0700 (Thu, 16 May 2019) $
; $LastChangedRevision: 27244 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/qderiv.pro $
;-
function qderiv,t,q
dq_dt = q
for i=0,3 do dq_dt[*,i] = deriv(t,q[*,i])
return,dq_dt
end
