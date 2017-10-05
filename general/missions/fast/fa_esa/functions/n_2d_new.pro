;+
;FUNCTION:	n_2d_new(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2),	optional, min,max pitch angle range for integration
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;PURPOSE:
;	Returns the density, n, 1/cm^3, corrects for spacecraft potential if dat.sc_pot exists
;NOTES:	
;	Function normally called by "get_2dt.pro" to generate 
;	time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:
;	96-4-22		J.McFadden
;	June 4, 2003	L.M.Peticolas
;	03-07-30	J.McFadden  
;	03-08-13	J.McFadden 	s/c pot calculated from e- spectra when dat.sc_pot>65. 
;	04-08-12	J.McFadden 	modified s/c pot calculated from e- spectra when dat.sc_pot>65. 
;	04-10-12	J.McFadden 	modified s/c pot calculated from e- spectra when dat.sc_pot>65. 
;	04-12-23	J.McFadden 	modified s/c pot calculated from e- spectra when dat.sc_pot>66. 
;	06-03-04	J.McFadden 	modified s/c pot to sc_pot*1.2 +1.
;	07-10-23	J.McFadden 	modified s/c pot to (sc_pot+offset)*scale with default scale=1.2,offset=+1.
;	10-12-22	J.McFadden	modified to work for omni.pro generated distributions
;-
function n_2d_new,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

common last_pot,pot
if not keyword_set(pot) then pot=0.

density = 0.

if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, density
endif

dat = conv_units(dat2,"df")		; Use distribution function
na = dat.nenergy
nb = dat.nbins

;  Correct for spacecraft potential
scale=1.0 & offset=1.05
charge=1.  ; charge of species
value=0 & str_element,dat,'charge',value
if value le 0 or value ge 0 then value=value else value=0
if value ne 0 then charge=dat.charge		
if ((value eq 0) and (dat.mass lt 0.00010438871)) then charge=-1.			; this line works for Wind which does not have dat.charge
value=0 & str_element,dat,'sc_pot',value
if value eq 0 then begin
	if value le 0 or value ge 0 then value=value else value=0
	sc_pot = (value+offset)*scale
	if value eq 0 then sc_pot=pot
	if sc_pot gt 66.*scale and charge eq -1. then begin
		peak_e=cold_peak_2d(dat,energy=[66.*scale,1000.])
		ind = where(dat.energy(*,0) eq peak_e)
		ind1 = ind
		maxcnt=max(dat.data(ind1,*),ind2)
		d0=dat.data(ind1,ind2)
		e0=dat.energy(ind1,ind2)
		dm=dat.data(ind1-1,ind2)
		em=dat.energy(ind1-1,ind2)
		dp=dat.data(ind1+1,ind2)
		ep=dat.energy(ind1+1,ind2)
		if dm ge dp then sc_pot=(dm*em+d0*e0)/(dm+d0)
		if dm lt dp then sc_pot=(dp*ep+d0*e0)/(dp+d0)
	endif
	if ndimen(sc_pot) eq 1 then sc_pot=sc_pot(0)
	if value ne 0 then pot=sc_pot

; The following rotates the measurement in angle to partly account 
;	for s/c potential deflection of low energy electrons
;if dat.data_name ne 'HSPAD' and dat.energy(0)-dat.denergy(0) lt dat.sc_pot then begin
if dat.data_name ne 'HSPAD' and dat.energy(0)-dat.denergy(0) lt sc_pot then begin
	tmpmin=min(abs(dat.energy(*,0)-sc_pot),ind1)
	tmpmax=max(dat.data(ind1,*),ind2)
		th=dat.theta(ind1,ind2)
		tmpavg=total(dat.data(ind1,*))/dat.nbins
		if (sc_pot gt 20. and th ne 0. and th ne 180. and tmpmax gt 3.*tmpavg) then begin
			if th le 65. then begin
				rot_ind=-fix(th/15.)
				print,'rotating cold beam to field line ',rot_ind
				if dat.data(ind1,ind2-1) lt dat.data(ind1,ind2+1) then rot_ind=rot_ind-1
				dat3=dat
				dat3.data=shift(dat3.data,0,rot_ind)
				dat.data(ind1-2:ind1+1,*)=dat3.data(ind1-2:ind1+1,*)
			endif
			if th gt 115. then begin
				rot_ind=fix((180-th)/15.)
				print,'rotating cold beam to field line ',rot_ind
				if dat.data(ind1,ind2-1) gt dat.data(ind1,ind2+1) then rot_ind=rot_ind+1
				dat3=dat
				dat3.data=shift(dat3.data,0,rot_ind)
				dat.data(ind1-2:ind1+1,*)=dat3.data(ind1-2:ind1+1,*)
			endif
		endif
endif
endif else sc_pot=(value+offset)*scale
	
energy=dat.energy+(charge*(sc_pot)/abs(charge))	
emin=energy-dat.denergy/2.>0.				
emax=energy+dat.denergy/2.>0.				
dat.energy=(emin+emax)/2.
dat.denergy=(emax-emin)

;ind=where(abs(dat.denergy-dat2.denergy) gt .01 and dat.denergy gt 0.01)
	;if n_elements(ind) gt 1 then dat.data(ind)=0.
	;if n_elements(ind) gt 1 then dat.data(ind)=dat.data(ind)*dat2.denergy(ind)/dat.denergy(ind)
	;if n_elements(ind) gt 1 then bgnd=0.7*dat.data(ind-1)*(dat2.denergy(ind)-dat.denergy(ind))/dat2.denergy(ind)
;if n_elements(ind) gt 1 then bgnd=dat.data(ind-1)*(dat2.denergy(ind)-dat.denergy(ind))/dat2.denergy(ind)
;if n_elements(ind) gt 1 then dat.data(ind)=((dat.data(ind)-bgnd)>0.)*dat2.denergy(ind)/dat.denergy(ind)
	;print,dat.energy(*,0)
	;print,dat.denergy(*,0)
	
ebins2=replicate(1b,na)
if keyword_set(en) then begin
	ebins2(*)=0
	er2=[energy_to_ebin(dat,en)]
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
;print,en,er2,ebins2

bins2=replicate(1b,nb)
if keyword_set(an) then begin
	if ndimen(an) ne 1 or dimen1(an) ne 2 then begin
		print,'Error - angle keyword must be fltarr(2)'
	endif else begin
		bins2=angle_to_bins(dat,an)
	endelse
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
dtheta = dat.dtheta/!radeg
mass = dat.mass     
value=0 & str_element,dat,'domega',value
if n_elements(value) ne 1 then domega = dat.domega
Const = (mass)^(-1.5)*(2.)^(.5)

; check to see if pitch-angles wrap around past 180 (to 360)
; (e.g. FAST data) or not. If they do, then calculate an appropriate
; domega. 

; This section for FAST
if max(dat.theta) gt 200. or dat.PROJECT_NAME eq 'FAST' then begin
 if na gt 1 then begin
  if (theta(0, 0) eq theta(na-1, 0)) then nna = 0 else nna = na-1
  if ndimen(dtheta) eq 1 then dtheta = replicate(1., na)#dtheta
  domega = theta
  for a = 0, nna do begin
    for b = 0, nb-1 do begin
      if (abs(theta(a, b)-!pi) lt dtheta(a, b)/2.) then begin 
        th1 = (!pi+theta(a, b)-dtheta(a, b)/2.)/2.
        dth1 = (!pi-th1)
        th2 = (!pi+theta(a, b)+dtheta(a, b)/2.)/2.
        dth2 = (th2-!pi)
        domega(a, b) = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2)) 
      endif else if (abs(theta(a, b)-2*!pi) lt dtheta(a, b)/2.) then begin
        th1 = (2.*!pi+theta(a, b)-dtheta(a, b)/2.)/2.
        dth1 = (2.*!pi-th1)
        th2 = (2.*!pi+theta(a, b)+dtheta(a, b)/2.)/2.
        dth2 = (th2-2.*!pi)
        domega(a, b) = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2)) 
      endif else if (abs(theta(a, b)) lt dtheta(a, b)/2.) then begin
        th1 = (theta(a, b)-dtheta(a, b)/2.)/2.
        dth1 = abs(th1)
        th2 = (theta(a, b)+dtheta(a, b)/2.)/2.
        dth2 = (th2)
        domega(a, b) = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2)) 
      endif else begin
        th1 = theta(a, b)
        dth1 = dtheta(a, b)/2.
        domega(a, b) = 2.*!pi*abs(sin(th1))*sin(dth1)
      endelse
    endfor
  endfor
  if (nna eq 0) then for a = 1, na-1 do domega(a, *) = domega(0, *)

; this section is for an angle distribution w/ only one energy
 endif else begin
  domega = theta
    for b = 0, nb-1 do begin
      if (abs(theta[b]-!pi) lt dtheta[b]/2.) then begin 
        th1 = (!pi+theta[b]-dtheta[b]/2.)/2.
        dth1 = (!pi-th1)
        th2 = (!pi+theta[b]+dtheta[b]/2.)/2.
        dth2 = (th2-!pi)
        domega[b] = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2)) 
      endif else if (abs(theta[b]-2*!pi) lt dtheta[b]/2.) then begin
        th1 = (2.*!pi+theta[b]-dtheta[b]/2.)/2.
        dth1 = (2.*!pi-th1)
        th2 = (2.*!pi+theta[b]+dtheta[b]/2.)/2.
        dth2 = (th2-2.*!pi)
        domega[b] = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2)) 
      endif else if (abs(theta[b]) lt dtheta[b]/2.) then begin
        th1 = (theta[b]-dtheta[b]/2.)/2.
        dth1 = abs(th1)
        th2 = (theta[b]+dtheta[b]/2.)/2.
        dth2 = (th2)
        domega[b] = 2.*!pi*(abs(sin(th1))*sin(dth1)+abs(sin(th2))*sin(dth2)) 
      endif else begin
        th1 = theta[b]
        dth1 = dtheta[b]/2.
        domega[b] = 2.*!pi*abs(sin(th1))*sin(dth1)
      endelse
    endfor
 endelse
endif



if na eq 1 and ndimen(dat.theta) eq 1 then solid_angle_corr=4.*!pi/total(domega) else $
solid_angle_corr=4.*!pi/total(domega[0,*])	; this should be correct in the structure
if (solid_angle_corr lt .99 or solid_angle_corr gt 1.01) and max(theta) gt 1.2 then print,'Error in dat.domega.  Solid angle = ', solid_angle_corr   

;print,Const*total(denergy*(energy^(0.5))*data*domega,2)

density = Const*total(denergy*(energy^(0.5))*data*domega)

; units are 1/cm^3

return, density
end

