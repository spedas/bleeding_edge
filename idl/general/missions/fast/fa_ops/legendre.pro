;	@(#)legendre.pro	1.2	09/24/97
;+
; returns the Legendre polynomials in SVDFIT ready form.
;-
function legendre,x,nsvd

if (max(x) gt 1) or (min(x) lt -1) then begin
    message,'X has values outside the range where Legendre polynomials ' + $
      'are orthogonal!',/continue
endif

n = nsvd-1L
nx = n_elements(x)
leg = dblarr(nx,nsvd)

if n ge 0 then leg(*,0) = 1.d
if n ge 1 then leg(*,1) = x

if n ge 2 then begin
    twox = 2.d*x
    f2 = x
    d = 1.d
    for i=2L,long(n) do begin
        f1 = d
        f2 = f2+twox
        d = d + 1.d
        leg(*,i) = (f2*leg(*,i-1L)-f1*leg(*,i-2L))/d
    endfor
endif

return,leg
end
