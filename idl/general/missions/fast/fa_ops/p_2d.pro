;+
;FUNCTION:	p_2d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
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
;	Returns the pressure tensor, [Pxx,Pyy,Pzz,Pxy,Pxz,Pyz], eV/cm^3
;NOTES:	
;	Function calls j_2d.pro and n_2d.pro
;	Function normally called by "get_2dt.pro" to generate 
;	time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:
;	96-7-5		J.McFadden
;-
function p_2d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

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
if keyword_set(an) then begin
	if ndimen(an) ne 1 or dimen1(an) ne 2 then begin
		print,'Error - angle keyword must be fltarr(2)'
	endif else begin
		bins2=angle_to_bins(dat,an)
	endelse
endif
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
theta = dat.theta/!radeg
dtheta = dat.dtheta/!radeg
mass = dat.mass * 1.6e-22
Const = (mass/(2.*1.6e-12))^(-.5)

if (theta(0,0) eq theta(na-1,0)) then nna=0 else nna=na-1
domegac2 = theta
domegas2 = theta
for a=0,nna do begin
for b=0,nb-1 do begin
	if (abs(theta(a,b)-!pi) lt dtheta(b)/2.) then begin 
		domegac2(a,b)=!pi*(2.+(cos(theta(a,b)-dtheta(b)/2.))^3+(cos(theta(a,b)+dtheta(b)/2.))^3)/3.
		domegas2(a,b)=!pi*(2.+cos(theta(a,b)-dtheta(b)/2.)+cos(theta(a,b)+dtheta(b)/2.))-domegac2(a,b)
	endif else if (abs(theta(a,b)-2*!pi) lt dtheta(b)/2.) then begin
		domegac2(a,b)=!pi*(2.-(cos(theta(a,b)-dtheta(b)/2.))^3-(cos(theta(a,b)+dtheta(b)/2.))^3)/3.
		domegas2(a,b)=!pi*(2.-cos(theta(a,b)-dtheta(b)/2.)-cos(theta(a,b)+dtheta(b)/2.))-domegac2(a,b)
	endif else if (abs(theta(a,b)) lt dtheta(b)/2.) then begin
		domegac2(a,b)=!pi*(2.-(cos(theta(a,b)-dtheta(b)/2.))^3-(cos(theta(a,b)+dtheta(b)/2.))^3)/3.
		domegas2(a,b)=!pi*(2.-cos(theta(a,b)-dtheta(b)/2.)-cos(theta(a,b)+dtheta(b)/2.))-domegac2(a,b)
	endif else begin
		domegac2(a,b)=!pi*abs((cos(theta(a,b)-dtheta(b)/2.))^3-(cos(theta(a,b)+dtheta(b)/2.))^3)/3.
		domegas2(a,b)=!pi*abs(cos(theta(a,b)-dtheta(b)/2.)-cos(theta(a,b)+dtheta(b)/2.))-domegac2(a,b)
	endelse
endfor
endfor
if (nna eq 0) then for a=1,na-1 do domegac2(a,*)=domegac2(0,*)
if (nna eq 0) then for a=1,na-1 do domegas2(a,*)=domegas2(0,*)
domegas2=domegas2/2.

;print,total(domegac2),total(domegas2)

sumxx = total(data*domegas2,2)
sumyy = sumxx
sumzz = total(data*domegac2,2)
sumxy = 0.
sumxz = 0.
sumyz = 0.
;print,total(sumzz),total(sumxx)

p3dxx = Const*total(denergy*energy^(-.5)*sumxx)
p3dyy = p3dxx
p3dzz = Const*total(denergy*energy^(-.5)*sumzz)
p3dxy = 0.
p3dxz = 0.
p3dyz = 0.
;print,total(p3dzz),total(p3dxx)

flux = j_2d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
density = n_2d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
vel = flux/density
;print,flux,density,vel
;print,p3dzz,vel*flux,p3dzz-vel*flux,p3dxx
p3dxx = mass*(p3dxx)/1.6e-12
p3dyy = mass*(p3dyy)/1.6e-12
p3dzz = mass*(p3dzz-vel*flux)/1.6e-12 > 0.
p3dxy = 0
p3dxz = 0
p3dyz = 0

;	Pressure is in units of eV/cm**3

return, [p3dxx,p3dyy,p3dzz,p3dxy,p3dxz,p3dyz]
end

