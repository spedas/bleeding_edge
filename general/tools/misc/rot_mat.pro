; +
;FUNCTION:      rot_mat(v1,v2)
;INPUT: 
;       v1:     3 component vector,             
;       v2:     3 component vector,             
;PURPOSE:
;       Returns a rotation matrix that rotates v1,v2 to the x-z plane
;       v1 is rotated to the z'-axis and v2 into the x'-z' plane
;NOTES: 
;
;CREATED BY:
;       Davin Larson
;   $LastChangedBy: $
;   $LastChangedDate: $
;   $LastChangedRevision: $
;   $URL: $
; -

function rot_mat,v1,v2

a  = reform(v1/SQRT(TOTAL(v1^2,/NAN,/DOUBLE)))  ;; need to normalize for orthonormal basis
;a=v1/(total(v1^2))^.5
if not keyword_set(v2) then v2 = [1d0,0d0,0d0]
;if not keyword_set(v2) then v2 = [1.d,0.d,0.d]

b  = CROSSP(a,v2)
b  = b/SQRT(TOTAL(b^2,/NAN,/DOUBLE))  ;; need to normalize for orthonormal basis
;b=crossp(a,v2)
;b=b/sqrt(total(b^2))

c  = CROSSP(b,a)
c  = c/SQRT(TOTAL(c^2,/NAN,/DOUBLE))  ;; need to normalize for orthonormal basis
;c=crossp(b,a)

;;  Define rotation to new orthonormal basis
rmat = [[c],[b],[a]]
;rot = [[c],[b],[a]]

return, rmat
;return, rot
end

