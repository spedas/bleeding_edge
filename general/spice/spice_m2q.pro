;+
;Function: spice_m2q
;Purpose: Convert rotation matrix (matrices) to quaternion(s)
;
;  Note: time is in the last dimension  (not like tplot storage)
; ;
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
function spice_m2q,mat,baserot=baserot,fix_qsign=fix_qsign
dim = size(/dimen,mat)
if array_equal(dim[[0,1]], [3,3]) eq 0 then message,'bad dimensions'
ndim = size(/n_dimen,mat) 
if ndim gt 3 then message,'Too many dimensions'
np = ndim eq 2 ? 1 : dim[2]
multiq = replicate(!values.d_nan,4,np)
for i=0L,np-1 do begin
   m = mat[*,*,i]
   if total(finite(m) eq 0) gt 0 then continue
   if keyword_set(baserot) then m = baserot ## m
   cspice_m2q,m,q
   if (n_elements(fix_qsign) eq 0) || (fix_qsign ne 0) then begin
     if ~keyword_set(ql) then ql=q 
     if total(q * ql) lt 0 then q=-q               ; get rid of sign ambiguity and make it smooth
     if finite(total(q) ) ne 0 then ql = q
   endif
   multiq[*,i] = q
endfor
return,multiq
end

