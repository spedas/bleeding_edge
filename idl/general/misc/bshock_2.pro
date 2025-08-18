;+
; PROCEDURE:
;     bowshock_2
;
; PURPOSE:
;     This subroutine calculates the bow shock (X,Y) locations based on
;     the Fairfield model (JGR, 1971 Vol 76 Oct-Dec p.6700). 
;     Aberation of 4 degrees is assumed
;
; INPUT:
;     xmp:   spacecraft position, x component
;     ymp:   spacecraft position, y component
;            gse or gsm does not matter because mpause assumed
;            rotationally symmetric
;
; OUTPUT:
;     It outputs the location of the bow shock down to a very large distance (xmp_max=-300 Re)
;
; AUTHOR:
;     S. Frey
;     
; MODIFICATION: 
;     Calculates ysh for given xsh and returns only abs(ysh)
;
; NOTE:
;     This provides flexibility with xsh_max
;-
pro bshock_2,xsh,ysh ,ysh_west=ysh_west,short=short,xsh_max=xsh_max

if not keyword_set(xsh_max) then xsh_max=14.3 ; Should have been 10.8 according to Fairfield paper
xsh_min=-300
npoints=1000
aberangle=4.5
if not keyword_set(short) then short=0 else short=1

if n_elements(xsh) eq 0 then $
  xsh=xsh_min+float(indgen(npoints))*(xsh_max-xsh_min)/(npoints-1)
;
; coefficients
a1=0.2164
b1=-0.0986
c1=-4.26
d1=44.916
e1=-623.77

beta=a1*xsh+c1
gamma=b1*(xsh)^2+d1*xsh+e1
delta=beta^2-4*gamma

ysh_east=(-beta-sqrt(delta))/2.
ysh_west=(-beta+sqrt(delta))/2.

if not short then begin

 ysh=ysh_east
 ireverse=n_elements(xsh)-indgen(n_elements(xsh))-1
 xsh=[xsh,xsh(ireverse)]
 ysh=[ysh_east,ysh_west(ireverse)]
endif else ysh=ysh_east

end

