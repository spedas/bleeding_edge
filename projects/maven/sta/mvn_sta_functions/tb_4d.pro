;+
;FUNCTION:	tb_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;	Returns the temperature of a beam in units of eV, assumes no s/c charging 
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
;-
function tb_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

temp = 0.

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, !Values.F_NAN
endif

if (dat2.quality_flag and 195) gt 0 then return,-1

if keyword_set(mi) and keyword_set(en) then begin
	if mi le 5. and max(en) le 200. and dat2.att_ind ge 2 then return, !Values.F_NAN
endif

dat = conv_units(dat2,"counts")		; initially use counts
dat = omni4d(dat)
n_e = dat.nenergy

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy






if n_e eq 64 then nne=5 
if n_e eq 32 then nne=3
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

; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements
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
	if total(data) lt .75*total(data2) then return,!Values.F_NAN

; treat low energy outliers with only one count as noise 

	ind = where(data eq 1 and energy lt 0.6*en_peak,count)
	if count gt 0 then data[ind]=0
	if count gt 0 then bkg[ind]=0

; don't correct for ion suppression

	data = (data-bkg)>0.



; print,en_peak,en_min,en_max

if keyword_set(mincnt) then if total(data) lt mincnt then return,!Values.F_NAN
if en_peak lt 1.5*en_min or en_peak gt en_max/1.5 then return,!Values.F_NAN

charge=dat.charge
if keyword_set(q) then charge=q
sc_pot=dat.sc_pot



;if sc_pot eq 0. and keyword_set(mi) then if mi lt 5. then sc_pot = -1.1*energy[mind+1,0]  
;if keyword_set(mi) then if mi lt 5. then sc_pot = -1.1*energy[mind+1,0]  
energy=(dat.energy+charge*sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

; Note - we don't need to divide by mass

v = (2.*energy*charge)^.5		; ESA measures energy/charge


v = v>0.001

; Notes	f ~ Counts/v^4 = C/v^4 

; 	dv/v = constant for logrithmic sweep
;	vd = integral(fv v^2dv)/integral(f v^2dv) = sum(C/v^4 * v^4 *dv/v)/sum(C/v^4 * v^3 *dv/v) = sum(C)/sum(C/v)
;	T/m = integral(f(v-vd)^2 v^2dv)/integral(f v^2dv) = sum(C/v^4 * (v-vd)^2 * v^3 *dv/v)/sum(C/v^4 * v^3 *dv/v) = sum(C/v * (v-vd)^2)/sum(C/v)

if keyword_set(ms) then begin
	vd = total(data)/(total(data/v)>1.e-20)
;	if keyword_set(mi) then if mi lt 5. then vd=0				; not sure about how this is affected by lack of sc_pot
	tm  = total((v-vd)^2*data/v)/(total(data/v)>1.e-20)
endif else begin
	vd = total(data,1)/(total(data/v,1)>1.e-20)
	vd = replicate(1.,n_e)#reform(vd,n_elements(vd))
	tm  = total((v-vd)^2*data/v,1)/(total(data/v,1)>1.e-20)
endelse

return, tm				; Ti (eV) = integral(.5mv^2 f d3v)/integral(f d3v);   vth^2 = 2T/m ; Eavg=1/2T

end

