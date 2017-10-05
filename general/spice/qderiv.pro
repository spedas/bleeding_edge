;+
;Function: qderiv
;  gets derivative of quaternion - assumes sign ambiguity has been fixed
;
;Purpose: ;
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
function qderiv,t,q
dq_dt = q
for i=0,3 do dq_dt[*,i] = deriv(t,q[*,i])
return,dq_dt
end
