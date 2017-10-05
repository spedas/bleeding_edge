;+
;FUNCTION:	j_3d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
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
;	Returns the flux, [Jx,Jy,Jz], 1/(cm^2-s) 
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	95-7-27
;LAST MODIFICATION:
;	96-7-6		J.McFadden
;-
function j_3d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

flux3dx = 0.
flux3dy = 0.
flux3dz = 0.

if dat2.valid eq 0 then begin
  dprint, 'Invalid Data'
  return, [flux3dx,flux3dy,flux3dz]
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
Const = 1.

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

sumdatax = total(data*cos(phi)*domega*cos(theta),2)
sumdatay = total(data*sin(phi)*domega*cos(theta),2)
sumdataz = total(data*domega*sin(theta),2)

dnrg=Const*denergy*(energy^(-1))
flux3dx = total(dnrg*sumdatax)
flux3dy = total(dnrg*sumdatay)
flux3dz = total(dnrg*sumdataz)

return, [flux3dx,flux3dy,flux3dz]
end

