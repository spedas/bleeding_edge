;+
;FUNCTION:	nb_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;	Returns the density of a beam in units of km/s
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-05-2
;LAST MODIFICATION:
;-
function nb_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

;def_den = !Values.F_NAN
def_den = 0.

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, def_den
endif

if (dat2.quality_flag and 195) gt 0 then return, def_den

if keyword_set(mi) and keyword_set(en) then begin
	if mi le 5. and max(en) le 200. and dat2.att_ind ge 2 then return, -1
endif

dat = omni4d(dat2)
n_e = dat.nenergy

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
domega = dat.domega
;	if ndimen(domega) eq 0 then domega=replicate(1.,dat.nenergy)#domega
if n_e eq 64 then nne=8 
if n_e eq 32 then nne=4
if n_e le 16 then nne=2
if n_e eq 48 then nne=6		; when does this happen? is this for swia?
if dat.mode eq 7 then nne=2*nne

en_min = min(energy)
en_max = max(energy)
if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
	en_min = en_min > en[0]
	en_max = en_max < en[1]
endif
if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
; 		the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements
;	if dat.time lt time_double('14-10-1') then begin
;		tcnts = total(data,2)
;		maxcnt = max(tcnts,mind)
;		data[0:(mind-nne>0),*]=0.
;		data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
;	endif	
endif

; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements of apid c0
if dat.nmass eq 1 then begin
	if dat.time lt time_double('14-10-1') then begin
		maxcnt = max(data,mind)
		if n_e eq 64 then nnne=4 else nnne=nne
		data[0:(mind-nnne>0)]=0.
		data[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
		bkg[0:(mind-nnne>0)]=0.
		bkg[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
	endif	
endif

; limit the energy range to near the peak
	data2 = data
	if ndimen(data) eq 2 then begin
		maxcnt = max(total(data,2),mind) 
		data[0:(mind-nne>0),*]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
		bkg[0:(mind-nne>0),*]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
		en_peak=energy[mind,0]
	endif else begin
		maxcnt = max(data,mind)
		data[0:(mind-nne>0)]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		bkg[0:(mind-nne>0)]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		en_peak=energy[mind]
	endelse

; if the number of counts near the peak is less than 75% of total counts in the energy range, then it is not a beam
	if total(data) lt .75*total(data2) then return,def_den

if dat.nmass gt 1 then begin
	if keyword_set(mi) then begin
		dat.mass_arr[*]=mi & mass=dat.mass*dat.mass_arr 
	endif else begin
		dat.mass_arr[*]=round(dat.mass_arr-.1)>1. & mass=dat.mass*dat.mass_arr	; the minus 0.1 helps account for straggling at low mass
	endelse
endif else mass = dat.mass

;if keyword_set(mincnt) then if total(data) lt mincnt then return,def_den
if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, def_den
if total(data-bkg) lt 1 then return, def_den

; the following was changed 20201225
if 0 then begin
	if en_peak lt 1.5*en_min or en_peak gt en_max/1.5 then return,def_den
endif else begin
	minval = min(abs(energy-en_min),min_ind)
	minval = min(abs(energy-en_max),max_ind)
	minval = min(abs(energy-en_peak),pk_ind)
	cnt_min = total(dat.data[min_ind,*])
	cnt_max = total(dat.data[max_ind,*])
	cnt_pk = total(dat.data[pk_ind,*])
	if (en_peak lt 1.5*en_min and cnt_min gt .1*cnt_pk) or (en_peak gt en_max/1.5 and cnt_max gt .1*cnt_pk) then return,def_den
endelse

dat.cnts=data
dat.bkg=bkg
dat = conv_units(dat,"df")		; Use distribution function
data=dat.data

Const = (mass)^(-1.5)*(2.)^(.5)
charge=dat.charge
if keyword_set(q) then charge=q
energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if keyword_set(ms) then begin
	density = total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi)
endif else begin
	density = total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,1)
endelse

return, density

end

