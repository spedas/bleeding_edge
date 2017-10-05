;+
;FUNCTION:	p_3d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2,2),	optional, angle range for integration
;				theta min,max (0,0),(1,0) -90<theta<90 
;				phi   min,max (0,1),(1,1)   0<phi<360 
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;PURPOSE:
;	Returns the pressure tensor, [Pxx,Pyy,Pzz,Pxy,Pxz,Pyz], eV/cm^3 
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	95-7-27
;LAST MODIFICATION:
;	96-7-6		J.McFadden
;-
function p_3d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

p3dxx = 0.
p3dyy = 0.
p3dzz = 0.
p3dxy = 0.
p3dxz = 0.
p3dyz = 0.

if dat2.valid eq 0 then begin
  dprint, 'Invalid Data'
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
	if ndimen(an) ne 2 then begin
		dprint, 'Error - angle keyword must be (2,2)'
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
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
mass = dat.mass * 1.6e-22
Const = (mass/(2.*1.6e-12))^(-.5)

;  Use the following lines until Davin gets  WIND "denergy" correct
if dat.project_name eq 'Wind 3D Plasma' then begin
	for a=0,na-1 do begin
		if a eq 0 then denergy(a,*) = abs(energy(a,*)-energy(a+1,*)) else $
		if a eq na-1 then denergy(a,*) = abs(energy(a-1,*)-energy(a,*)) else $
		denergy(a,*) = .5*abs(energy(a-1,*)-energy(a+1,*))
	endfor
endif

str_element,dat,"domega",value=domega,index=ind
if ind ge 0 then begin
	if ndimen(domega) eq 1 then domega=replicate(1.,na)#domega
endif else begin
	if ndimen(dtheta) eq 1 then dtheta=replicate(1.,na)#dtheta
	if ndimen(dphi) eq 1 then dphi=replicate(1.,na)#dphi
	domega=2.*dphi*sin(theta)*sin(.5*dtheta)
endelse

cth = cos(theta)
sth = sin(theta)
cph = cos(phi)
sph = sin(phi)
cth2 = cth^2
cthsth = cth*sth
sumxx = total(data*cph*cph*domega*cth2,2)
sumyy = total(data*sph*sph*domega*cth2,2)
sumzz = total(data*domega*sth*sth,2)
sumxy = total(data*cph*sph*domega*cth2,2)
sumxz = total(data*cph*domega*cthsth,2)
sumyz = total(data*sph*domega*cthsth,2)

dnrg = Const*denergy*(energy^(-.5))
p3dxx = total(dnrg*sumxx)
p3dyy = total(dnrg*sumyy)
p3dzz = total(dnrg*sumzz)
p3dxy = total(dnrg*sumxy)
p3dxz = total(dnrg*sumxz)
p3dyz = total(dnrg*sumyz)

flux=[0.,0.,0.]
;flux = j_3d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
sumdatax = total(data*cph*domega*cth,2)
sumdatay = total(data*sph*domega*cth,2)
sumdataz = total(data*domega*sth,2)
dnrg=denergy*(energy^(-1))
flux(0) = total(dnrg*sumdatax)
flux(1) = total(dnrg*sumdatay)
flux(2) = total(dnrg*sumdataz)

;density = n_3d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
sumdata = total(data*domega,2)
density = ((mass/(2.*1.6e-12))^(.5))*total(denergy*(energy^(-1.5))*sumdata)

if density eq 0. then begin
	vel=[0.,0.,0.]
endif else begin
	vel = flux/density
endelse
p3dxx = mass*(p3dxx-vel(0)*flux(0))/1.6e-12
p3dyy = mass*(p3dyy-vel(1)*flux(1))/1.6e-12
p3dzz = mass*(p3dzz-vel(2)*flux(2))/1.6e-12
p3dxy = mass*(p3dxy-vel(0)*flux(1))/1.6e-12
p3dxz = mass*(p3dxz-vel(0)*flux(2))/1.6e-12
p3dyz = mass*(p3dyz-vel(1)*flux(2))/1.6e-12

;	Pressure is in units of eV/cm**3

if keyword_set(diag) then begin
dprint,  " This section not tested yet!!!!!"
if diag eq "diag" then begin

	p = [[p3dxx,p3dxy,p3dxz],[p3dxy,p3dyy,p3dyz],[p3dxz,p3dyz,p3dzz]]
	nr_tred2,p,d,e
	nr_tqli,d,e,p
	dprint, "d =",d
	dprint, "p =",p(0,0),p(1,1),p(2,2),p(0,1),p(0,2),p(1,2)

endif
endif

return, [p3dxx,p3dyy,p3dzz,p3dxy,p3dxz,p3dyz]
end

