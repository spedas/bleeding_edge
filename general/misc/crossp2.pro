;+
;FUNCTION:	crossp2(a,b)
;INPUT:	
;	a,b:	real(n,3)	vector arrays dimension (n,3) or (3)
;PURPOSE:
;	performs cross product on arrays
;CREATED BY:
;	J.McFadden	97-3-14
;Modifications
;	J.McFadden	05-2-7 changed first if to "if ndimen(a) eq 1 and ndimen(b) eq 1" 
;-
function crossp2,a,b

c=0
if n_params() ne 2 then begin
	dprint, ' Wrong format, Use: crossp2(a,b)'
	return,c
endif

if ndimen(a) eq 1 and ndimen(b) eq 1 then begin
	return,crossp(a,b)
endif

if ndimen(a) eq 2 and ndimen(b) eq 2 then begin
	c=a
	c[*,0]=a[*,1]*b[*,2]-a[*,2]*b[*,1]
	c[*,1]=a[*,2]*b[*,0]-a[*,0]*b[*,2]
	c[*,2]=a[*,0]*b[*,1]-a[*,1]*b[*,0]
endif else if ndimen(a) eq 1 and ndimen(b) eq 2 then begin
	c=b
	c[*,0]=a[1]*b[*,2]-a[2]*b[*,1]
	c[*,1]=a[2]*b[*,0]-a[0]*b[*,2]
	c[*,2]=a[0]*b[*,1]-a[1]*b[*,0]
endif else if ndimen(a) eq 2 and ndimen(b) eq 1 then begin
	c=a
	c[*,0]=a[*,1]*b[2]-a[*,2]*b[1]
	c[*,1]=a[*,2]*b[0]-a[*,0]*b[2]
	c[*,2]=a[*,0]*b[1]-a[*,1]*b[0]
endif

return,c
end
