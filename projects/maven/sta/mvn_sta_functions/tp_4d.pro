;+
;FUNCTION:	tp_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;
;PURPOSE:
;	Returns the perp temperature of a beam from APID C8 in units of eV 
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;
;CREATED BY:
;	J.McFadden	2014-03-12
;LAST MODIFICATION:
;		20190808  factor of 2 error corrected, vth^2= 2.*sigma^2: tp=2.*total((v*sth - v0#replicate(1.,nth))^2*data)/(total(data)>1.e-20
;-
function tp_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

temp = 0.

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, temp
endif

if (dat2.quality_flag and 195) gt 0 then return,-1

if dat2.data_name ne 'c8 32e16d' and dat2.data_name ne 'c8e 64e16d' then begin
	print,'Invalid Data: Data must be Maven APID c8 or c8e'
	return, 0
endif













dat = conv_units(dat2,"counts")		; initially use counts
nth = dat.ndef
n_e = dat.nenergy
n_m = dat.nmass

mass_amu = dat.mass_arr


data = dat.cnts 
bkg = dat.bkg
energy = dat.energy
dead = dat.dead

;kk2=mvn_sta_get_kk2(dat.time)
;corr = exp((kk2/energy)^2) < 30.

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=1.e-20
	if count ne 0 then bkg[ind]=0.
endif

;if keyword_set(mincnt) then if total(data) lt mincnt then return,0
if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, !Values.F_NAN
if total(data-bkg) lt 1 then return, !Values.F_NAN

;	data = ((data-bkg)>0.)*corr*dead
	data = ((data-bkg)>0.)*dead





























charge=dat.charge
if keyword_set(q) then charge=q
;energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy
energy=dat.energy						; should we ignore s/c potential for this calculation?

v = energy^.5
sth = sin(dat.theta/!radeg)
v0 = total(v*sth*data,2)/(total(data,2)>1.e-20)
tp = 2.*total((v*sth - v0#replicate(1.,nth))^2*data)/(total(data)>1.e-20)

return, tp							; eV

end