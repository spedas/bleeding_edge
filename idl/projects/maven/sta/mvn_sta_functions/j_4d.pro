;+
;FUNCTION:	j_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;	J.McFadden	2014-02-26	
;LAST MODIFICATION:
;-
function j_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt


if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, [0.,0.,0.]
endif

if dat2.nbins eq 1 then flux=0. else flux = [0.,0.,0.]

if (dat2.quality_flag and 195) gt 0 then return,flux

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
	dat.mass_arr[*]=mi & mass=dat.mass*dat.mass_arr 
endif else begin
	dat.mass_arr[*]=round(dat.mass_arr-.1)>1. & mass=dat.mass*dat.mass_arr	; the minus 0.1 helps account for straggling at low mass
endelse

;if keyword_set(mincnt) then if total(data) lt mincnt then return,flux
if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, flux
if total(data-bkg) lt 1 then return, flux

dat.cnts=data
dat.bkg=bkg
dat = conv_units(dat,"df")		; Use distribution function
data=dat.data

Const = 2./mass/mass*1e5
charge=dat.charge
if keyword_set(q) then charge=q
energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if dat.nbins eq 1 then begin
	; assume you want the omni-directional flux and put it in the x-direction
	if keyword_set(ms) then return,total(Const*denergy*(energy)*data) else return,total(Const*denergy*(energy)*data,1)
endif else begin	
	flux3dx = total(total(Const*denergy*(energy)*data*(dtheta/2.+cos(2*theta)*sin(dtheta)/2.)*(2.*sin(dphi/2.)*cos(phi)),1),1)
	flux3dy = total(total(Const*denergy*(energy)*data*(dtheta/2.+cos(2*theta)*sin(dtheta)/2.)*(2.*sin(dphi/2.)*sin(phi)),1),1)
	flux3dz = total(total(Const*denergy*(energy)*data*(2.*sin(theta)*cos(theta)*sin(dtheta/2.)*cos(dtheta/2.))*dphi,1),1)
endelse	

if keyword_set(ms) then begin
	flux3dx = total(flux3dx)
	flux3dy = total(flux3dy)
	flux3dz = total(flux3dz)
endif

; units are 1/cm^2-s

return, transpose([[flux3dx],[flux3dy],[flux3dz]])

end
