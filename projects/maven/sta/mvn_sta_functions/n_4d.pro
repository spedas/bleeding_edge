;+
;FUNCTION:	n_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
;INPUT:	
;	dat:	structure,	4d data structure filled by themis routines mvn_sta_c6.pro, mvn_sta_d0.pro, etc.
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
;	MASS:	intarr(nm)	optional, 
;PURPOSE:
;	Returns the density array, n, 1/cm^3, corrects for spacecraft potential if dat.sc_pot exists
;NOTES:	
;	Function normally called by "get_4dt" to 
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	13-11-13	
;LAST MODIFICATION:
;-
function n_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

def_density = 0. 
;def_density = !Values.F_NAN


if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, density
endif

if (dat2.quality_flag and 195) gt 0 then return,def_density


dat = conv_units(dat2,"counts")		; initially use counts
na = dat.nenergy
nb = dat.nbins
nm = dat.nmass

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
domega = dat.domega
	if ndimen(domega) eq 0 then domega=replicate(1.,dat.nenergy)#domega
mass = dat.mass*dat.mass_arr 
pot = dat.sc_pot

if keyword_set(bins) and nb gt 1 then begin
	bins2 = transpose(reform(bins#replicate(1.,na*nm),nb,nm,na),[2,0,1])
	data=data*bins2
	bkg = bkg*bins2
endif

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
endif
if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
endif

if keyword_set(mi) then begin
	dat.mass_arr[*]=mi 
endif else begin
	if keyword_set(ms) then dat.mass_arr[*]=(ms[0]+ms[1])/2. else $
	dat.mass_arr[*]=round(dat.mass_arr-.1)>1. 			; the minus 0.1 helps account for straggling at low mass
endelse

mass=dat.mass*dat.mass_arr 

;if keyword_set(mincnt) then if total(data) lt mincnt then return,0
if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, def_density
if total(data-bkg) lt 1 then return, def_density

dat.cnts=data
dat.bkg=bkg
dat = conv_units(dat,"df")		; Use distribution function
data=dat.data

Const = (mass)^(-1.5)*(2.)^(.5)
charge=dat.charge
if keyword_set(q) then charge=q
if finite(pot) then energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0. else energy=dat.energy		; energy/charge analyzer, require positive energy

if dat.nbins eq 1 then begin
	density = total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,1)
endif else begin	
	density = total(total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,1),1)
endelse	

if keyword_set(ms) then density=total(density)

; units are 1/cm^3

return, density
end
