;+
;FUNCTION:	vp_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;PURPOSE:
;	Returns the perpendicular velocity of a beam in units of km/s for apid C8
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
;-
function vp_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt




if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, !Values.F_NAN
endif

if (dat2.quality_flag and 195) gt 0 then return,!Values.F_NAN

if dat2.apid ne 'c8' and dat2.apid ne 'ca' then begin
	print,'Invalid Data: Data must be Maven APID c8 or ca'
	return, !Values.F_NAN
endif

dat = conv_units(dat2,"counts")		; initially use counts
n_e = dat.nenergy
n_m = dat.nmass
mass_amu = dat.mass_arr

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy
if dat2.apid eq 'ca' then data = total(reform(data,16,4,16),2)
if dat2.apid eq 'ca' then bkg = total(reform(bkg,16,4,16),2)
if dat2.apid eq 'ca' then energy = total(reform(energy,16,4,16),2)/4.

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
endif

if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, !Values.F_NAN
if total(data-bkg) lt 1 then return, !Values.F_NAN

charge=dat.charge
if keyword_set(q) then charge=q
energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if keyword_set(ms) then mass_amu = ms
mass = dat.mass*mass_amu
; the following kluge is only for the electrostatic attenuator
; it assumes the beam is centered on an anode and accounts for energy-angle response variation across an anode
; for beams centered on an anode, the offset is ~3 deg, for beams centered between anodes the offset is -3 deg
; this could be improved by using apid ca to determine where the beam is centered
if (dat.att_ind eq 1 or dat.att_ind eq 3) then offset=3. else offset=0. 

v = (2.*energy/mass)^.5								; km/s  note - mass=mass/charge, energy=energy/charge, charge cancels
if dat2.apid eq 'ca' then begin
	phi = total(reform(dat.phi,16,4,16),2)/4.
	sth = sin(phi/!radeg) 
endif else sth = sin((dat.theta+offset)/!radeg)

vp = v*sth									; km/s

vperp = total(vp*((data-bkg)>0.))/total((data-bkg)>0.)

return, vperp									; km/s

end

