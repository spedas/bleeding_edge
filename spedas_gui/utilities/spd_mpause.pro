;+
pro spd_mpause,xmp,ymp,ymp_west=ymp_west,short=short,xmp_max=xmp_max
;gse or gsm does not matter because mpause assumed 
;                     ;rotationally symmetric
;
; This subroutine calculates the magnetopause (X,Y) locations based on
; the Fairfield model (JGR, 1971). It outputs the location of the ma-
; gnetopause down to a very large distance (xmp_max=-300 Re)
; Aberation of 4 degrees is assumed
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-07-24 12:07:30 -0700 (Fri, 24 Jul 2015) $
; $LastChangedRevision: 18247 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_mpause.pro $
;-
xp=-15.
if not keyword_set(xmp_max) then xmp_max=10.78 ; Should have been 10.8 according to Fairfield paper
xmp_min=-300
npoints=1000
aberangle=4.5
if n_elements(xmp) eq 0 then $
xmp=xmp_min+float(indgen(npoints))*(xmp_max-xmp_min)/(npoints-1)
if not keyword_set(short) then short=0
;
; Ellipse coefficients
;
a1=0.0278
b1=0.3531
c1=-0.586
d1=17.866
e1=-233.67

ilt15=where((xmp lt xp),n_ilt15)
ige15=where((xmp ge xp),n_ige15)
ymp_east=xmp
ymp_west=xmp
if (n_ige15 gt 1) then begin

  beta=a1*xmp(ige15)+c1
  gamma=b1*(xmp(ige15))^2+d1*xmp(ige15)+e1
  delta=beta^2-4*gamma
  ymp_east(ige15)=(-beta-sqrt(delta))/2.
  ymp_west(ige15)=(-beta+sqrt(delta))/2.

  s_east=(ymp_east(ige15(1))-ymp_east(ige15(0)))/(xmp(ige15(1))-xmp(ige15(0)))
  s_west=(ymp_west(ige15(1))-ymp_west(ige15(0)))/(xmp(ige15(1))-xmp(ige15(0)))
  if n_ilt15 ne 0 then begin
   ymp_east(ilt15)=ymp_east(ige15(0))+s_east*(xmp(ilt15)-xmp(ige15(0)))
   ymp_west(ilt15)=ymp_west(ige15(0))+s_west*(xmp(ilt15)-xmp(ige15(0)))
  endif
endif
if not short then begin
 ymp=ymp_east
 ireverse=n_elements(xmp)-indgen(n_elements(xmp))-1
 xmp=[xmp,xmp(ireverse)]
 ymp=[ymp_east,ymp_west(ireverse)]
endif else ymp=ymp_east
return
end
