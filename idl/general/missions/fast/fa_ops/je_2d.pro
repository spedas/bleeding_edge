;+
;FUNCTION:	je_2d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
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
;	Returns the field aligned energy flux, JEz, ergs/cm^2-sec
;NOTES:	
;	Function normally called by "get_2dt.pro" to generate 
;	time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:
;	96-4-22		J.McFadden
;-
function je_2d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

eflux3dz = 0.

if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, eflux3dz
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
Const = 1.6e-12

if (theta(0,0) eq theta(na-1,0)) then nna=0 else nna=na-1
if ndimen(dtheta) eq 1 then dtheta=replicate(1.,na)#dtheta
domega = theta
for a=0,nna do begin
for b=0,nb-1 do begin
	if (abs(theta(a,b)-!pi) lt dtheta(a,b)/2.) then begin 
		th1 = (!pi+theta(a,b)-dtheta(a,b)/2.)/2.
		dth1 = (!pi-th1)
		th2 = (!pi+theta(a,b)+dtheta(a,b)/2.)/2.
		dth2 = (th2-!pi)
		domega(a,b)=2.*!pi*(abs(sin(th1))*sin(dth1)*cos(th1)*cos(dth1) + abs(sin(th2))*sin(dth2)*cos(th1)*cos(dth2)) 
	endif else if (abs(theta(a,b)-2*!pi) lt dtheta(a,b)/2.) then begin
		th1 = (2.*!pi+theta(a,b)-dtheta(a,b)/2.)/2.
		dth1 = (2.*!pi-th1)
		th2 = (2.*!pi+theta(a,b)+dtheta(a,b)/2.)/2.
		dth2 = (th2-2.*!pi)
		domega(a,b)=2.*!pi*(abs(sin(th1))*sin(dth1)*cos(th1)*cos(dth1) + abs(sin(th2))*sin(dth2)*cos(th1)*cos(dth2)) 
	endif else if (abs(theta(a,b)) lt dtheta(a,b)/2.) then begin
		th1 = (theta(a,b)-dtheta(a,b)/2.)/2.
		dth1 = abs(th1)
		th2 = (theta(a,b)+dtheta(a,b)/2.)/2.
		dth2 = (th2)
		domega(a,b)=2.*!pi*(abs(sin(th1))*sin(dth1)*cos(th1)*cos(dth1) + abs(sin(th2))*sin(dth2)*cos(th1)*cos(dth2)) 
	endif else begin
		th1 = theta(a,b)
		dth1 = dtheta(a,b)/2.
		domega(a,b)=2.*!pi*abs(sin(th1))*sin(dth1)*(cos(th1)*cos(dth1))
	endelse
endfor
endfor
if (nna eq 0) then for a=1,na-1 do domega(a,*)=domega(0,*)

sumdataz = total(data*domega,2)

eflux3dz = Const*total(denergy*sumdataz)

; units are ergs/cm^2-sec

return, eflux3dz
end

