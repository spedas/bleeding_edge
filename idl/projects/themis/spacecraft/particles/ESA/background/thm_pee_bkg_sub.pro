;+
;FUNCTION:	thm_pee_bkg_sub(dat,bkg=bkg)
;
;PURPOSE:
;	calculates secondary background from primary. Returns data structure with secondaries, photo-e, and Bremsstrahlung (dat.bkg) subtracted
;
;INPUT:	
;	dat:	themis pee data structure 
;KEYWORDS:
;
;Assumptions
; Secondary electron spectral shape determined from a fit to TH-B on 08-03-05 in shadow (see first results paper)
; 	Secondary spectra for this day fits ~ 1./(1.+(E/5.4)^3), where E is the secondary energy
;	sec ~ 1./(1.+(E/5.4)^3)
;	5.4 was determined empirically from the fit
;
;CREATED BY:
;	J.McFadden	09-11-18
;Modifications
;	J.McFadden	10-04-06	Changed to allow dat2.bkg subtraction of Bremstrahlung X-rays and seconda
; aflores   2016-06-30  minor changes to integrate with spedas
;-
function thm_pee_bkg_sub,dat2,plot=plot

  compile_opt strictarr, hidden

	cols=get_colors()
	dat = conv_units(dat2,'eflux')
	nenergy=dat.nenergy
	nbins=dat.nbins

; calculate secondaries and subtract them
	sec_spec=dat.data & sec_spec[*]=0.
	if nbins eq 1 then $
		for k=1,nenergy-2 do sec_spec[k:nenergy-1]=sec_spec[k:nenergy-1]+dat.data[k]*0.8d*(dat.energy[k]/10.)^.15/(50.+dat.energy[k:nenergy-1]^2.25) $
	else $
		for k=1,nenergy-2 do sec_spec[k:nenergy-1,*]=sec_spec[k:nenergy-1,*]+replicate(1.,nenergy-k)#reform(dat.data[k,*])*0.8d*(replicate(1.,nenergy-k)#reform(dat.energy[k,*])/10.)^.15/(50.+dat.energy[k:nenergy-1,*]^2.25)

;	for i=0,nbins-1 do begin
;	for k=1,nenergy-2 do sec_spec(k:nenergy-1,i)=sec_spec(k:nenergy-1,i)+dat.data(k,i)*0.8d*(dat.energy(k,i)/10.)^.15/(50.+dat.energy(k:nenergy-1,i)^2.25)
;	endfor

; average sec_spec for fixed values of phi
	if nbins gt 6 then begin
		avg_spec=sec_spec 
		phi=reform(dat.phi[0,*])
		dphi=reform(dat.dphi[0,*])
		for j=0,nbins-1 do begin
			ind = where(abs(phi - phi[j]) le dphi[j]/1.99, count)
			avg_spec[*,j] = total(sec_spec[*,ind],2)/count
		endfor
		sec_spec=avg_spec
	endif

	sec_dat=dat
	sec_dat.data=sec_spec
	dat.data=dat.data-sec_spec>0.

; subtract off photoelectron contamination of bins just above s/c potential - contamination from langmuir probes
; this contamination is modulated at 4 times the spin when the booms have maximum illumination
;	at 1V below s/c potential, eflux=1.e8, scattered photoelectron flux falls off as exp[-E/pot] with cos(phi) dependence
;	the max probe flux, 2.e7, may need to depend on the probe bias current scheme
		max_scat = 1.5e7
		pot=dat.sc_pot
;		pho_spec = max_scat*exp(-dat.energy/(1.*dat.sc_pot))*(1.+cos((dat.phi-180.)/4./!radeg))
		max_scat = 1.0e8
		pho_spec = max_scat*((dat.energy+pot*.15)/(1.*pot))^(-8)*(0.5+abs(cos((dat.phi)/2./!radeg)))
		pho_dat=dat
		pho_dat.data=pho_spec
		dat.data=dat.data-pho_spec>0.

; remove photo-electrons from the axial bins
;	nrg=dat2.energy
skip=1
if not skip then begin
	if nbins gt 1 then begin
		nrg=reform(dat2.energy[*,0])
		pot = dat2.sc_pot
		bins=where(abs(dat2.theta[0,*])+dat2.dtheta[0,*]/2. gt 70.)
		minval1 = min(abs(nrg-pot-3.),k2)
		minval2 = min(abs(nrg-pot),k1)
		if k1 eq k2 and k1 eq nenergy-1 then begin
			if minval2 lt 3. then dat.data[k1,bins]=dat.data[k1-1,bins]+(dat.data[k1-1,bins]-dat.data[k1-2,bins])*(nrg[k1]-nrg[k1-1])/(nrg[k1-1]-nrg[k1-2])
		endif else if k1 eq k2 then begin
			dat.data[k1,bins]=dat.data[k1-1,bins]+(dat.data[k1-1,bins]-dat.data[k1-2,bins])*(nrg[k1]-nrg[k1-1])/(nrg[k1-1]-nrg[k1-2])
		endif else begin
			for kk=k2,k1 do dat.data[kk,bins]=dat.data[k2-1,bins]+(dat.data[k2-1,bins]-dat.data[k2-2,bins])*(nrg[kk]-nrg[k2-1])/(nrg[k2-1]-nrg[k2-2])
		endelse
	endif
endif

; change back to initial units and add the bkg element to the structure

	dat = conv_units(dat,dat2.units_name)
	sec = conv_units(sec_dat,dat2.units_name)
	pho = conv_units(pho_dat,dat2.units_name)
	str_element,dat,'sec',sec.data,/add
	str_element,dat,'pho',pho.data,/add
	if keyword_set(plot) then begin
		window,1
		spec3d,dat2,/pot
		for i=0,nbins-1 do oplot,dat2.energy[*,i],sec_spec[*,i]
		for i=0,nbins-1 do oplot,dat2.energy[*,i],pho_spec[*,i],color=cols.red
		oplot,dat2.energy[*,0],replicate(1.e7,nenergy),psym=1
		window,2
		spec3d,dat,/pot
		oplot,dat2.energy[*,0],replicate(1.e7,nenergy),psym=1
		print,n_3d_new(dat2),n_3d_new(dat)
	endif

	if dat2.units_name eq 'counts' then dat.data=dat2.data-dat2.bkg > 0.

return,dat
end
