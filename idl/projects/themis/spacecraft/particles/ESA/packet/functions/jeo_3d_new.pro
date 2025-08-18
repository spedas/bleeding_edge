;+
;FUNCTION:	jeo_3d_new(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
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
;	Returns the omin directional energy flux,  eV/(cm^2-s) 
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	09-06-11
;LAST MODIFICATION:
;	J.McFadden	09-06-18	calculates domega, no longer requires dat.domega to exist
;-
function jeo_3d_new,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra

flux=0.

if dat2.valid eq 0 then begin
  dprint, 'Invalid Data'
  return, flux
endif

dat = conv_units(dat2,"df",_extra=_extra)		; Use distribution function
na = dat.nenergy
nb = dat.nbins
	
ebins2=replicate(1b,na)
if keyword_set(en) then begin
	ebins2(*)=0
	er2=[thm_energy_to_ebin(dat,en)]
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
;if keyword_set(an) then begin
;	if ndimen(an) ne 2 then begin
;		print,'Error - angle keyword must be (2,2)'
;	endif else begin
;		bins2=angle_to_bins(dat,an)
;	endelse
;endif
	if keyword_set(an) then begin
;		str_element,dat,'PHI',INDEX=tf_phi
		if ndimen(an) eq 2 then bins=angle_to_bins(dat,an)
		if ndimen(an) ne 2 then begin
			th=reform(dat.theta(0,*)/!radeg)
			ph=reform(dat.phi(fix(dat.nenergy/2),*)/!radeg)
			xx=cos(ph)*cos(th)
			yy=sin(ph)*cos(th)
			zz=sin(th)
			Bmag=(dat.magf(0)^2+dat.magf(1)^2+dat.magf(2)^2)^.5
			pitch=acos((dat.magf(0)*xx+dat.magf(1)*yy+dat.magf(2)*zz)/Bmag)*!radeg
			if an(0) gt an(1) then an=reverse(an)
			bins= pitch gt an(0) and pitch lt an(1)
			if total(bins) eq 0 then begin
				tmp=min(abs(pitch-(an(0)+an(1))/2.),ind)
				bins(ind)=1
			endif
		endif
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
;domega = dat.domega
domega=2.*cos(theta)*sin(dtheta/2.)*dphi
	if ndimen(domega) eq 1 then domega=replicate(1.,dat.nenergy)#domega
mass = dat.mass
Const = 2./mass/mass*1e5
charge=1.
value=0 & str_element,dat,'charge',value
if value ne 0 then charge=dat.charge		
if ((value eq 0) and (dat.mass lt 0.00010438871)) then charge=-1.		; this line works for Wind which does not have dat.charge
value=0 & str_element,dat,'sc_pot',value
if value gt 0 or value lt 0 then energy=energy+(charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer

solid_angle_corr=4.*!pi/total(domega(0,*))	; this should be correct in the structure
if (solid_angle_corr lt .99 or solid_angle_corr gt 1.01) and max(theta) gt 1.2 then begin
	dprint, 'Error in dat.domega'
	domega=domega*solid_angle_corr
endif

denergy=denergy<energy
;eflux = Const*total(energy*denergy*(energy)*data*domega)
eflux = Const*total(energy*denergy*(energy+dat.sc_pot)*(energy/(energy+dat.sc_pot)<3.)^2*data*domega)

; units are eV/cm^2-s

return, eflux
end
