;+
;FUNCTION:	p_2d_b(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2),	optional, min,max pitch angle range for integration
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;PURPOSE:
;	Returns the pressure tensor, [Pxx,Pyy,Pzz,Pxy,Pxz,Pyz], eV/cm^3, z along B, off diagonal terms are zero
;		assumes a narrow (< 5 deg) field aligned beam
;NOTES:	
;	Similar to p_2d.pro, treats the anodes within 5 deg of the magnetic field differently.
;	Function calls j_2d_b.pro and n_2d_b.pro
;	Function normally called by "get_2dt.pro" to generate 
;	time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	97-8-19		Created from n_2d_b.pro and p_2d.pro
;					Treats narrow beams correctly, no do loops
;LAST MODIFICATION:
;	97-8-19		J.McFadden
;-
function p_2d_b,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

p3dxx = 0.
p3dyy = 0.
p3dzz = 0.
p3dxy = 0.
p3dxz = 0.
p3dyz = 0.

if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, [p3dxx,p3dyy,p3dzz,p3dxy,p3dxz,p3dyz]
endif

dat = conv_units(dat2,"eflux")		; Use Energy Flux
na = dat.nenergy
nb = dat.nbins
	
ebins2=replicate(1b,na)
if keyword_set(en) then begin
	ebins2(*)=0
	er2=[energy_to_ebin(dat,en)]
	if er2(0) gt er2(1) then er2=reverse(er2)
	ebins2(er2(0):er2(1))=1
endif
if keyword_set(er) then begin
	ebins2(*)=0
	er2=er
	if er2(0) gt er2(1) then er2=reverse(er2)
	ebins2(er2(0):er2(1))=1
endif
if keyword_set(ebins) then ebins2=ebins

bins2=replicate(1b,nb)

if keyword_set(ar) then begin
	bins2(*)=0
	if ar(0) gt ar(1) then begin
		bins2(ar(0):nb-1)=1
		bins2(0:ar(1))=1
	endif else begin
		bins2(ar(0):ar(1))=1
	endelse
endif
if keyword_set(bins) then bins2=bins

if ndimen(bins2) ne 2 then bins2=ebins2#bins2

data = dat.data*bins2
energy = dat.energy
denergy = dat.denergy
theta = dat.theta
dtheta = dat.dtheta
	if ndimen(dtheta) eq 1 then dtheta=replicate(1.,na)#dtheta
mass = dat.mass * 1.6e-22
Const = (mass/(2.*1.6e-12))^(-.5)
esa_dth = 5. < !pi*min(dtheta)/4.
	esa_drad = esa_dth/!radeg

minvar = min(theta(0,*),indminvar)
if indminvar gt 1 then begin
	an_shift = theta(0,0) lt theta(0,1)
endif else an_shift = theta(0,2) lt theta(0,3)
an_shift = 2*an_shift-1

if keyword_set(an) then begin
	ann = (360.*(an/360.-floor(an/360.)))
	if an(1) eq 360. then ann(1)=360.
endif else ann=[0.,360.]
if ann(0) gt ann(1) then begin
	ann=reverse(ann) 
	tfrev=1
endif else tfrev=0

; Calculate solid angle for 0.<th<180.

th2_tmp = theta + dtheta/2.
th2_tmp = (360.*(th2_tmp/360.-floor(th2_tmp/360.)))
th1_tmp = th2_tmp - dtheta
th1 = th1_tmp > ann(0) < ann(1)
th1 = th1 > 0. < 180.
th2 = th2_tmp > ann(0) < ann(1)
th2 = th2 > 0. < 180.
th_plus = (th1 lt esa_dth) and (th1 ne th2)
th_minus = (th2 gt 180.-esa_dth) and (th1 ne th2)
th_other = 1 - th_plus - th_minus

th1 = th1/!radeg
th2 = th2/!radeg
domega_zz = !pi*((cos(th1))^3 - (cos(th2))^3)/3.
domega_xx = !pi*((cos(th1)) - (cos(th2))) - domega_zz
other_zz = th_other*domega_zz
;other_xx = th_other*domega_xx

;plus_zz = th_plus*((esa_drad*(th2-th1)-esa_drad^3*(th2-th1)/3.-esa_drad*(th2-th1)^3/3.) < abs(domega_zz))
plus_zz = th_plus*((esa_drad*(th2-th1)) < abs(domega_zz))
plus_zz_shift = shift(th_plus*domega_zz - plus_zz,0,an_shift)
;plus_xx = th_plus*(esa_drad^3*(th2-th1)/3.+esa_drad*(th2-th1)^3/3. < abs(domega_xx))
;plus_xx_shift = shift(th_plus*domega_xx - plus_xx,0,an_shift)

;minus_zz = th_minus*((esa_drad*(th2-th1)-esa_drad^3*(th2-th1)/3.-esa_drad*(th2-th1)^3/3.) < abs(domega_zz))
minus_zz = th_minus*((esa_drad*(th2-th1)) < abs(domega_zz))
minus_zz_shift = shift(th_minus*domega_zz - minus_zz,0,-an_shift)
;minus_xx = th_minus*(esa_drad^3*(th2-th1)/3.+esa_drad*(th2-th1)^3/3. < abs(domega_xx))
;minus_xx_shift = shift(th_minus*domega_xx - minus_xx,0,-an_shift)

domega1_zz = other_zz+plus_zz+plus_zz_shift+minus_zz+minus_zz_shift
;domega1_xx = other_xx+plus_xx+plus_xx_shift+minus_xx+minus_xx_shift
domega1_xx = domega_xx

if tfrev then begin
	tth1 = th1_tmp > 0. < 180.
	tth2 = th2_tmp > 0. < 180.
	th_plus = (tth1 lt esa_dth) and (tth1 ne tth2)
	th_minus = (tth2 gt 180.-esa_dth) and (tth1 ne tth2)
	th_other = 1 - th_plus - th_minus

	th1 = tth1/!radeg
	th2 = tth2/!radeg
	domega_zz = !pi*((cos(th1))^3 - (cos(th2))^3)/3.
	domega_xx = !pi*((cos(th1)) - (cos(th2))) - domega_zz
	other_zz = th_other*domega_zz
;	other_xx = th_other*domega_xx

;	plus_zz = th_plus*((esa_drad*(th2-th1)-esa_drad^3*(th2-th1)/3.-esa_drad*(th2-th1)^3/3.) < abs(domega_zz))
	plus_zz = th_plus*((esa_drad*(th2-th1)) < abs(domega_zz))
	plus_zz_shift = shift(th_plus*domega_zz - plus_zz,0,an_shift)
;	plus_xx = th_plus*(esa_drad^3*(th2-th1)/3.+esa_drad*(th2-th1)^3/3. < abs(domega_xx))
;	plus_xx_shift = shift(th_plus*domega_xx - plus_xx,0,an_shift)

;	minus_zz = th_minus*((esa_drad*(th2-th1)-esa_drad^3*(th2-th1)/3.-esa_drad*(th2-th1)^3/3.) < abs(domega_zz))
	minus_zz = th_minus*((esa_drad*(th2-th1)) < abs(domega_zz))
	minus_zz_shift = shift(th_minus*domega_zz - minus_zz,0,-an_shift)
;	minus_xx = th_minus*(esa_drad^3*(th2-th1)/3.+esa_drad*(th2-th1)^3/3. < abs(domega_xx))
;	minus_xx_shift = shift(th_minus*domega_xx - minus_xx,0,-an_shift)

	domega1_zz = other_zz+plus_zz+plus_zz_shift+minus_zz+minus_zz_shift - domega1_zz
;	domega1_xx = other_xx+plus_xx+plus_xx_shift+minus_xx+minus_xx_shift - domega1_xx
	domega1_xx = domega_xx - domega1_xx

endif

; Calculate solid angle for 180.<th<360.

th3_tmp = theta - dtheta/2.
th3_tmp = (360.*(th3_tmp/360.-floor(th3_tmp/360.)))
th4_tmp = th3_tmp + dtheta
th3 = th3_tmp > ann(0) < ann(1)
th3 = th3 > 180. < 360.
th4 = th4_tmp > ann(0) < ann(1)
th4 = th4 > 180. < 360.
th_plus = (th4 gt 360.-esa_dth) and (th4 ne th3)
th_minus = (th3 lt 180.+esa_dth) and (th4 ne th3)
th_other = 1 - th_plus - th_minus

th1 = th3/!radeg
th2 = th4/!radeg
domega_zz = !pi*((cos(th2))^3 - (cos(th1))^3)/3.
domega_xx = !pi*((cos(th2)) - (cos(th1))) - domega_zz
other_zz = th_other*domega_zz
;other_xx = th_other*domega_xx

;plus_zz = th_plus*((esa_drad*(th2-th1)-esa_drad^3*(th2-th1)/3.-esa_drad*(th2-th1)^3/3.) < abs(domega_zz))
plus_zz = th_plus*((esa_drad*(th2-th1)) < abs(domega_zz))
plus_zz_shift = shift(th_plus*domega_zz - plus_zz,0,-an_shift)
;plus_xx = th_plus*(esa_drad^3*(th2-th1)/3.+esa_drad*(th2-th1)^3/3. < abs(domega_xx))
;plus_xx_shift = shift(th_plus*domega_xx - plus_xx,0,an_shift)

;minus_zz = th_minus*((esa_drad*(th2-th1)-esa_drad^3*(th2-th1)/3.-esa_drad*(th2-th1)^3/3.) < abs(domega_zz))
minus_zz = th_minus*((esa_drad*(th2-th1)) < abs(domega_zz))
minus_zz_shift = shift(th_minus*domega_zz - minus_zz,0,an_shift)
;minus_xx = th_minus*(esa_drad^3*(th2-th1)/3.+esa_drad*(th2-th1)^3/3. < abs(domega_xx))
;minus_xx_shift = shift(th_minus*domega_xx - minus_xx,0,-an_shift)

domega2_zz = other_zz+plus_zz+plus_zz_shift+minus_zz+minus_zz_shift
;domega2_xx = other_xx+plus_xx+plus_xx_shift+minus_xx+minus_xx_shift
domega2_xx = domega_xx

if tfrev then begin
	tth3 = th3_tmp > 180. < 360.
	tth4 = th4_tmp > 180. < 360.
	th_plus = (tth4 gt 360.-esa_dth) and (tth4 ne tth3)
	th_minus = (tth3 lt 180.+esa_dth) and (tth4 ne tth3)
	th_other = 1 - th_plus - th_minus

	th1 = tth3/!radeg
	th2 = tth4/!radeg
	domega_zz = !pi*((cos(th2))^3 - (cos(th1))^3)/3.
	domega_xx = !pi*((cos(th2)) - (cos(th1))) - domega_zz
	other_zz = th_other*domega_zz
;	other_xx = th_other*domega_xx

;	plus_zz = th_plus*((esa_drad*(th2-th1)-esa_drad^3*(th2-th1)/3.-esa_drad*(th2-th1)^3/3.) < abs(domega_zz))
	plus_zz = th_plus*((esa_drad*(th2-th1)) < abs(domega_zz))
	plus_zz_shift = shift(th_plus*domega_zz - plus_zz,0,-an_shift)
;	plus_xx = th_plus*(esa_drad^3*(th2-th1)/3.+esa_drad*(th2-th1)^3/3. < abs(domega_xx))
;	plus_xx_shift = shift(th_plus*domega_xx - plus_xx,0,an_shift)

;	minus_zz = th_minus*((esa_drad*(th2-th1)-esa_drad^3*(th2-th1)/3.-esa_drad*(th2-th1)^3/3.) < abs(domega_zz))
	minus_zz = th_minus*((esa_drad*(th2-th1)) < abs(domega_zz))
	minus_zz_shift = shift(th_minus*domega_zz - minus_zz,0,an_shift)
;	minus_xx = th_minus*(esa_drad^3*(th2-th1)/3.+esa_drad*(th2-th1)^3/3. < abs(domega_xx))
;	minus_xx_shift = shift(th_minus*domega_xx - minus_xx,0,-an_shift)

	domega2_zz = other_zz+plus_zz+plus_zz_shift+minus_zz+minus_zz_shift - domega2_zz
;	domega2_xx = other_xx+plus_xx+plus_xx_shift+minus_xx+minus_xx_shift - domega2_xx
	domega2_xx = domega_xx - domega2_xx
endif

domega_zz = domega1_zz + domega2_zz
domega_xx = .5*(domega1_xx + domega2_xx)

sumxx = total(data*domega_xx,2)
sumyy = sumxx
sumzz = total(data*domega_zz,2)
sumxy = 0.
sumxz = 0.
sumyz = 0.

p3dxx = Const*total(denergy*energy^(-.5)*sumxx)
p3dyy = p3dxx
p3dzz = Const*total(denergy*energy^(-.5)*sumzz)
p3dxy = 0.
p3dxz = 0.
p3dyz = 0.


flux = j_2d_b(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
density = n_2d_b(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
vel = flux/density
p3dxx = mass*(p3dxx)/1.6e-12
p3dyy = mass*(p3dyy)/1.6e-12
p3dzz = mass*(p3dzz-vel*flux)/1.6e-12 > 0.
p3dxy = 0
p3dxz = 0
p3dyz = 0

;	Pressure is in units of eV/cm**3, z is along the magnetic field

return, [p3dxx,p3dyy,p3dzz,p3dxy,p3dxz,p3dyz]
end
