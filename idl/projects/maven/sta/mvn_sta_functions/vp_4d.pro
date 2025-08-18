;+
;FUNCTION:	vp_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
;INPUT:	
;	dat:	structure,	4d data structure filled by themis routines mvn_sta_get_c8.pro
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
;	Modified to use tplot structure 'mvn_sta_o2+_c6_ec'
;	Only valid <500 km altitude
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
;	J.McFadden	2018-09-18
;-
function vp_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

common mvn_sta_offset2,efoldoffset,e0,scale1,offset1

tt=timerange()
if (size(efoldoffset,/type)) ne 4 or (dat2.time lt tt[0]-100.) or (dat2.end_time gt tt[1]+100.)  then begin
	mvn_sta_set_th_offset2,(tt[0]+tt[1])/2.
	print,'Running mvn_sta_set_th_offset2'
endif 

def = !Values.F_NAN
if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, def
endif

if (dat2.quality_flag and 195) gt 0 then return,def

if dat2.apid ne 'c8' then begin
	print,'Invalid Data: Data must be Maven APID c8'
	return, def
endif

; the following attempts to restrict use of this program to below 500 km

orb_rad = total(dat2.pos_sc_mso^2)^.5
if orb_rad gt (3386.+500.) then return,def
if orb_rad eq 0. then begin
	get_data,'alt',data=tmp95
	if size(tmp95,/type) eq 8 then begin
		alt = interp(tmp95.y,tmp95.x,dat2.time+2.)
		if alt gt 500. then return,def
	endif
endif

dat = conv_units(dat2,"counts")		; initially use counts
n_e = dat.nenergy
n_m = dat.nmass
mass_amu = dat.mass_arr
pot = dat.sc_pot

; the following is not used at present, but might be used in the future
common mvn_sta_kk3,kk3
if size(kk3,/type) eq 4 then kk = kk3[dat.att_ind] else kk=0

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy
theta = dat.theta

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
endif

; code only includes +/-22 deg of deflection unless common block thmax_def is set
; 22. is a good default due to scattered ions backstreaming at theta>22 theta 
; may want to set thmax_def to 50. if the APP is off-pointing as during NGIMS wind measurements

common sta_c8_th_vperp_default,thmax_def
if keyword_set(thmax_def) then thmax=thmax_def else thmax=22.

; assume a O2+ beam if dat2.apid eq 'c8' - only include 3 energies centered on peak

offset_time=0.
if dat2.apid eq 'c8' then begin
	ind = where(abs(theta) ge thmax,count)
	if count gt 0 then data[ind] = 0.
	spec = total(data,2)
	pk_spec = max(spec,ind2)
	peak=energy[ind2,0]
	get_data,'mvn_sta_o2+_c6_ec',data=tmp97
	if size(tmp97,/type) eq 8 then begin
;		peak = interp(tmp97.y,tmp97.x,dat2.time+2.)
		min_tim = min(abs(tmp97.x-dat2.time-2.),ind97)
		peak = tmp97.y[ind97]
	endif
	if keyword_set(en) then peak2 = en[0] > peak < en[1] else peak2=peak
	closest = min(abs(reform(energy[*,0])-peak2),ind2)
	peak2=energy[ind2,0]
	nne=2
	if dat.mode eq 7 then nne=nne*2
	data[0:((ind2-nne)>0),*]=0.
	data[((ind2+nne)<31):31,*]=0.
	offset_time = (ind2-15.5)*2./16.	; this accounts for the actual time of measurement -- needed for ngims wind APP nods 
endif 

; use the debye length and characteristic energy to correct for deflections by s/c potentials caused by surface geometry relative to particle direction

	get_data,'mvn_sta_o2+_o+_c6_density3',data=tmp98
	if size(tmp98,/type) eq 8 then begin
		min_tim = min(abs(tmp98.x-dat2.time-2.),ind98)
		den98 = tmp98.y[ind98]
		debye = 740.*(0.1/den98)^.5		; cm, debye length
		radii = 5.				; cm, characteristic dimension of analyzer
;		scale2 = radii/(debye+radii)		; original guess
		scale2 = (debye/4.+radii)/(debye+radii)	; scale2->1 as debye->0, scale2-> ~1/4 at debye>>radii, 1/4 is a guess
		pot2 = pot*scale2			; the amount of potential acceleration normal to analyzer surface
	endif else begin
; may want to modify this 
		den98 = nb_4d(dat)
		debye = 740.*(0.1/den98)^.5		; cm, debye length
		radii = 5.				; cm, characteristic dimension of analyzer
;		scale2 = radii/(debye+radii)		; original guess
		scale2 = (debye/4.+radii)/(debye+radii)	; scale2->1 as debye->0, scale2-> ~1/4 at debye>>radii, 1/4 is a guess
		pot2 = pot*scale2			; the amount of potential acceleration normal to analyzer surface
;		pot2=0
	endelse

if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return,def
if total(data-bkg) lt 1 then return,def

if keyword_set(mi) then mass = dat.mass*mi else mass=dat.mass*32.			; assume O2+ if not set

; the following offsets account for aberations in the electrostatic analyzer
; it assumes the beam is centered on an anode 
; offset0 and offset 1 could be improved by using apid ca to determine where the beam is centered and its width

; offset0 is due to the attenuator, determined by discontinuities in center theta
; offset1 is due to is an overall alignment offset
; offset2 is due to ion suppression and therefore is energy dependent - use ram-horizontal to determine this or scenario 1
; offset3 is due to APP not pointing in RAM direction - requires 'Vthe_MAVEN_APP' tplot data loaded

if (dat.att_ind eq 3) then offset0=1.5				; 1.5	0
if (dat.att_ind eq 2) then offset0=0.0				; 0.0	0
;if (dat.att_ind eq 1) then offset0=1.0				; 1.0	1
;if (dat.att_ind eq 0) then offset0=0.0				; 0.0	0

; changed 20190204 empirically determined on nightside
; offsets for non-mech-att states are larger than originally estimated
; offsets are determined at attenuator state changes
; may need to check for scpot of variation of these offsets - these work for low scpot>-1V
if (dat.att_ind eq 1) then offset0=2.0				; 
if (dat.att_ind eq 0) then offset0=1.0				; 

; offset2,offset1 uses inputs from common mvn_sta_offset2					

offset2=efoldoffset*(1.-erf((energy-e0)/(scale1*(e0+.01))))

;offset2=0.						; for testing purposes

	get_data,'V_sc_APP_The',data=tmp99
	if size(tmp99,/type) eq 8 then begin
;		ind_t = min(abs(dat2.time+2. - tmp99.x),ind99)
;		offset3 = -tmp99.y[ind99]
		offset3 = interp(-tmp99.y,tmp99.x,dat2.time+2.+offset_time)
	endif else offset3=0.

offset=offset0+offset1+offset2+offset3

; not sure which of the following is correct - for density>1.e4, debye length is small (1-2 cm) and scpot does not impact vperp 
; there may be lower density cases where debye length is 10 cm where this breaks down.

v = (2.*(energy+pot)/mass)^.5 > 0.					;       use scpot corrected energy for large debye length
;v = (2.*energy/mass)^.5						; don't use scpot corrected energy for small debye length

sth = sin((dat.theta+offset)/!radeg)
vp = v*sth							; km/s

;corr = exp((kk/dat.energy)^2)					; don't weight by sensitivity - use highest counts for statistics.
corr = 1.
data2 = ((data-bkg)>0.)*corr					; we assume no contribution for energies>11eV for att=1,3, so no need to use eflux

;vperp = total(vp*((data-bkg)>0.))/total((data-bkg)>0.)
;vperp = total(vp*data2)/total(data2)
th1 = total(dat.theta*data2)/total(data2)					; th1 is the measured beam center w/o corrections
th2 = total(offset*data2)/total(data2)						; th2 is the APP pointing ram direction plus instrument internal offsets, not used anymore

th3 = total((dat.theta+offset0+offset1+offset2)*data2)/total(data2)		; th3 is the measured beam center minus internal instrument offsets
th4 = -offset3									; th4 is the APP pointing direction
;th5 = !radeg*atan ((peak2/(peak2+pot2))^.5*tan(th3/!radeg))			; th5 blue  is the th3 angle corrected for external deflections caused by s/c charging
; def_const should be 1 for a planar surface, 0 for spherical
def_const=1.00									; determined imperically during APP nods 20171008 - might need to be debye length dependent
th5 = !radeg*atan ((peak2/(peak2+def_const*pot2))^.5*tan(th3/!radeg))		; th5 is the th3 angle corrected for external deflections caused by s/c charging

;print,th5,peak2,def_const,pot2

vperp = total(v*data2)/total(data2)*sin((th5-th4)/!radeg)			; vperp is the velocity perpendicular to the "th4" ram direction
return, vperp									; km/s

end
