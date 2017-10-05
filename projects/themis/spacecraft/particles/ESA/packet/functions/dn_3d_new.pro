;+
;FUNCTION:	dn_3d_new(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
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
;	Returns the density error due to statistics, dn, 1/cm^3, corrects for spacecraft potential if dat.sc_pot exists
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to 
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	10-03-09	
;LAST MODIFICATION:
;	
;	
;-
function dn_3d_new,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,_extra=_extra

density = 0.

if dat2.valid eq 0 then begin
  dprint, 'Invalid Data'
  return, density
endif

dat = dat2
dat1 = conv_units(dat,"counts",_extra=_extra)
dat1.data(*)=1.				; make an array with 1 count in each bin
dat = conv_units(dat,"df",_extra=_extra)		; Use distribution function
dat1 = conv_units(dat1,"df",_extra=_extra)		; Use distribution function
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
data1 = dat1.data*bins2
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
;domega = dat.domega
;	if ndimen(domega) eq 1 then domega=replicate(1.,dat.nenergy)#domega
mass = dat.mass 
Const = (mass)^(-1.5)*(2.)^(.5)
charge=1.
value=0 & str_element,dat,'charge',value
if value ne 0 then charge=dat.charge		
if ((value eq 0) and (dat.mass lt 0.00010438871)) then charge=-1.		; this line works for Wind which does not have dat.charge
value=0 & str_element,dat,'sc_pot',value
if value gt 0 or value lt 0 then energy=energy+(charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer

; the following 15 lines were added to prevent photoelectron contamination when in the plasmasheet
; this section assumes the ESA energy steps go from high energy to low energy
lin = 1				; this line determines whether the data is df or log(df) interpolated to low energy
if charge eq -1. then begin
;	scale=1.
	scale=.5
if dat.nbins eq 1 then begin
	ind=where(energy[*] lt scale*denergy[*],count) 
;	if count gt 0 and charge lt 0 then begin
	if count gt 0 then begin
		mind = min(ind)
		denergy[mind] = energy[mind]+denergy[mind]/2.
		energy[ind] = 0.
		energy[mind] = denergy[mind]/2.
if lin eq 1 then	data[mind] = data[mind-1] + (energy[mind-1]-energy[mind])*(data[mind-1]-data[mind-2])/(energy[mind-2]-energy[mind-1])
if lin eq 0 then	data[mind] = exp(alog(data[mind-1]) + (energy[mind-1]-energy[mind])*(alog(data[mind-1])-alog(data[mind-2]))/(energy[mind-2]-energy[mind-1]))
	endif else begin
		nrg=dat.nenergy-1
if lin eq 1 then	data[nrg]=data[nrg]+(data[nrg]-data[nrg-1])/(energy[nrg]-energy[nrg-1])*(-energy[nrg]/2.+denergy[nrg]/4.)
if lin eq 0 then	data[nrg]=exp(alog(data[nrg])+(alog(data[nrg])-alog(data[nrg-1]))/(energy[nrg]-energy[nrg-1])*(-energy[nrg]/2.+denergy[nrg]/4.))
		denergy[nrg]=denergy[nrg]/2.+energy[nrg]
		energy[nrg]=denergy[nrg]/2.
	endelse
endif else begin
	ind=where(energy[*,0] lt scale*denergy[*,0],count) 
;	if count gt 0 and charge lt 0 then begin
	if count gt 0 then begin
		mind=min(ind)
		denergy[mind,*] = energy[mind,*]+denergy[mind,*]/2.
		energy[ind,*] = 0.
		energy[mind,*] = denergy[mind,*]/2.
if lin eq 1 then	data[mind,*] = data[mind-1,*] + (energy[mind-1,*]-energy[mind,*])*(data[mind-1,*]-data[mind-2,*])/(energy[mind-2,*]-energy[mind-1,*])
if lin eq 0 then	data[mind,*] = exp(alog(data[mind-1,*]) + (energy[mind-1,*]-energy[mind,*])*(alog(data[mind-1,*])-alog(data[mind-2,*]))/(energy[mind-2,*]-energy[mind-1,*]))
	endif else begin
		nrg=dat.nenergy-1
if lin eq 1 then	data[nrg,*]=data[nrg,*]+(data[nrg,*]-data[nrg-1,*])/(energy[nrg,*]-energy[nrg-1,*])*(-energy[nrg,*]/2.+denergy[nrg,*]/4.)
if lin eq 0 then	data[nrg,*]=exp(alog(data[nrg,*])+(alog(data[nrg,*])-alog(data[nrg-1,*]))/(energy[nrg,*]-energy[nrg-1,*])*(-energy[nrg,*]/2.+denergy[nrg,*]/4.))
		denergy[nrg,*]=denergy[nrg,*]/2.+energy[nrg,*]
		energy[nrg,*]=denergy[nrg,*]/2.
	endelse
endelse
; this section throws away background counts in the lowest ion energy channels in low density plasmas as determined from sc_pot
endif else if charge eq +1. then begin
	if dat.sc_pot gt 20. then begin
		if dat.nbins eq 1 then begin
			ind=where(dat.energy lt dat.sc_pot/2.,count) 
			if count gt 0 then data[ind]=0.
		endif else begin
			ind=where(dat.energy[*,0] lt dat.sc_pot/2.,count) 
			if count gt 0 then data[ind,*]=0.
		endelse
	endif
endif

density = (Const^2*total(denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi*denergy*(energy^(.5))*data1*2.*cos(theta)*sin(dtheta/2.)*dphi))^.5






; units are 1/cm^3

return, density
end
