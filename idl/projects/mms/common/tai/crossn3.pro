;	@(#)crossn3.pro	1.2	04/28/99
;+
; NAME: CROSSN3
;
; PURPOSE: Takes cross product of two time series vectors, both of
;          which must be N x 3 matrices. 
;
; CALLING SEQUENCE:
;
;
; 
; INPUTS: A, B - two N x 3 vectors
;
; OUTPUTS: C - an N x 3 vector, the cross product of A and B. 
;
; EXAMPLE: compute V cross B (motional electric field)
; help,b, v
; B               FLOAT     = Array[1000, 3]
; V               FLOAT     = Array[1000, 3]
; e_motional = crossn3(v, b)
;
; MODIFICATION HISTORY: ???
;
;-
function crossn3,a,b

sa = size(a)

ok = (sa[0] eq 2) and (sa[2] eq 3)

if not ok then begin
    message, 'not an N x 3 vector...',/continue
    return,!values.f_nan
endif

sb = size(b)

ok = (sb[0] eq 2) and (sb[2] eq 3)

if not ok then begin
    message, 'not an N x 3 vector...',/continue
    return,!values.f_nan
endif

c = a-a

c(*,0) = a(*,1)*b(*,2) - b(*,1)*a(*,2)
c(*,1) = a(*,2)*b(*,0) - b(*,2)*a(*,0)
c(*,2) = a(*,0)*b(*,1) - b(*,0)*a(*,1)

return,c
end

