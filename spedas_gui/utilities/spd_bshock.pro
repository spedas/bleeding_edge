;+
pro spd_bshock,xsh,ysh ,ysh_west=ysh_west,short=short,xsh_max=xsh_max


;gse or gsm does not matter because bow shock is  assumed  to be
;                     ;rotationally symmetric
;
; This subroutine calculates the bow shock (X,Y) locations based on
; the Fairfield model (JGR, 1971 Vol 76 Oct-Dec p.6700). It outputs the location of the bow
; shock down to a very large distance (xmp_max=-300 Re)
; Aberration of 4 degrees is assumed
; Modification: calculates ysh for given xsh and returns only abs(ysh)
;               Note, this provides flexibility with xsh_max
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-07-24 12:07:30 -0700 (Fri, 24 Jul 2015) $
; $LastChangedRevision: 18247 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_bshock.pro $
;-

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

