;+
;FUNCTION:	vb_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;	Returns the velocity of a beam in units of km/s
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
;-
function vb_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, !Values.F_NAN
endif

if (dat2.quality_flag and 195) gt 0 then return,!Values.F_NAN

dat = conv_units(dat2,"counts")		; initially use counts

dat = omni4d(dat)
n_e = dat.nenergy
if dat.nmass gt 1 then mass = dat.mass*dat.mass_arr else mass = dat.mass

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy	
if n_e eq 64 then nne=4 else nne=3
if n_e eq 48 then nne=5
if dat.mode eq 7 then nne=2*nne

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
endif

if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements
	if dat.time lt time_double('14-10-1') then begin
		tcnts = total(data,2)
		maxcnt = max(tcnts,mind)
		data[0:(mind-nne>0),*]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
		bkg[0:(mind-nne>0),*]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
	endif	
endif

; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements
if 0 then begin
if dat.nmass eq 1 then begin
	if dat.time lt time_double('14-10-1') then begin
		maxcnt = max(data,mind)
		data[0:(mind-nne>0)]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		bkg[0:(mind-nne>0)]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1)]=0.
	endif	
endif
endif

if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, !Values.F_NAN
if total(data-bkg) lt 1 then return, !Values.F_NAN

charge=dat.charge
if keyword_set(q) then charge=q

; this section was modified to set data[ind]=0 for ind that have energy<denergy
if 1 then begin
;	energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, problems for low energy steps - this screwed up for negative energies
	energy=(dat.energy+charge*dat.sc_pot/abs(charge))		; energy/charge analyzer
	ind99 = where(energy lt dat.denergy/2.,count)
	if count ge 1 then begin					; throw out any data where Energy+q*sc_pot is less than denergy/2.
		data[ind99]=0
		bkg[ind99]=0
	endif
	en_jitter = 0.00
	de = dat.denergy > en_jitter
	ind = where(energy lt de/2.,nind)
	if nind gt 0 then energy[ind] = (energy[ind]>0. + de[ind]/2.) > 0.	; this really

endif else begin
	energy=(dat.energy+charge*dat.sc_pot/abs(charge))		; energy/charge analyzer, require positive energy
	en_jitter = 0.00
	de = dat.denergy > en_jitter
	ind = where(energy lt de/2.,nind)
	if nind gt 0 then energy[ind] = (energy[ind] + de[ind]/2.) > 0.
endelse

if keyword_set(mi) then v = (2.*energy/(dat.mass*mi))^.5 else v = (2.*energy/mass)^.5	; km/s  note - mass=mass/charge, energy=energy/charge, charge cancels

v = v>.001			; eliminate values too close to zero

; Note 	f ~ Counts/v^4 = C/v^4 
; 	dv/v = constant for logrithmic sweep
;	vd = integral(fv v^2dv)/integral(f v^2dv) = sum(C/v^4 * v^4 *dv/v)/sum(C/v^4 * v^3 *dv/v) = sum(C)/sum(C/v)

;print,total(data)
;print,minmax(data/v)

if keyword_set(ms) then begin
	vd = total((data-bkg)>0.)/total((((data-bkg)>0.)/v)>1.e-20)
endif else begin
	vd = total((data-bkg)>0.,1)/total((((data-bkg)>0.)/v)>1.e-20,1)
endelse

return, vd

end

