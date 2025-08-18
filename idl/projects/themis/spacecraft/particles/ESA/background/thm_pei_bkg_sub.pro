;+
;FUNCTION:	thm_pei_bkg_sub(dat,bkg=bkg)
;
;PURPOSE:
;	returns data structure with background subtracted, assumes dat.bkg in data structure, run thm_load_esa_bkg.pro first
;
;INPUT:	
;	dat:	themis pei data structure 
;KEYWORDS:
;	bkg:		flt		if set, uses this value in background subtraction					
;
;Assumptions
;	Program assumes no energy dependence for contamination
;	Program assumes dat.bkg is already computed
;	dat.bkg is added to structure by thm_load_esa_bkg.pro
;
;CREATED BY:
;	J.McFadden	08-12-29
;Modifications
;
;	Mcfadden	09-01-09	added relative bkg dependence as a function of anode 
;	mcfadden	09-01-30	changed dat.bkg to an array		 
; aflores   2016-06-30  minor changes to integrate with spedas
;-
function thm_pei_bkg_sub,dat2,bkg=bkg

  compile_opt strictarr, hidden

	dat=dat2
	
	mavg = total(dat2.bkg)/32.
	dat.data=dat2.data-dat2.bkg
	if keyword_set(bkg) then begin
		dat.data=dat2.data-dat2.bkg*bkg/mavg 
		mavg = bkg
	endif
	if not finite(mavg) then return,dat

;	dat.data=dat.data>0.
;	return,dat
; use the above line for simple subtraction
; one may consider customizing the following section to obtain a better background subtraction algorithm

;	elements of "norm" differ from 1 when energy steps are summed in a distribution.

	if ndimen(dat.data) gt 1 then datdim=1 else datdim=0
	if datdim then norm=total(dat.gf,2)/128. else norm=dat.gf/128.

; form an omnidirectional energy spectra of counts

	if datdim then odat=total(dat.data,2)/norm else odat=dat.data/norm

; zero the counts in dat.data(E,*) at energies "E" where odat(E) < one sigma above background

	ind = where(odat lt (mavg^.5 + 1.),count)
	if count ne 0 then dat.data[ind,*]=0.

; get rid of fractional counts in dat.data at energies  "E" where odat(E) < two sigma above background

	ind = where(odat lt (2.*mavg^.5 + 1.),count)
	if count ne 0 then dat.data[ind,*]=1.*fix(dat.data[ind,*])

; get rid of all counts in the lowest energy bins when background is high

	elow = (alog(mavg) > 0.) * 6.
	ind = where(dat.energy[*,0] lt elow,count)
	if count ne 0 then dat.data[ind,*]=0.
;	if count ne 0 then print,'low energy bin active now',time_string(dat.time),' ',count,' ',ind

; get rid of all counts in dat.data at energies  "E" where odat(E) < sigma above background

;	sigma = 2. - (1. > (mavg-4.)/4. > 0.)
;	ind = where(odat lt (sigma*mavg^.5 + 1.),count)
;	if count ne 0 then dat.data[ind,*]=0.

; zero out bins with negative values

	dat.data=dat.data>0.

; get rid of fractional counts in the energy bins <20 eV, assumes high energy to low energy sweep
; this section is probably not necessary

;	if datdim then odat=total(dat.data,2)/norm else odat=dat.data/norm
	

;	tmp=min(abs(dat2.energy-15.),ind3)
;	dat.data[ind3:dat2.nenergy-1,*]=1.*fix(dat.data[ind3:dat2.nenergy-1,*])

return,dat
end
