;+
;FUNCTION:	e_sec_eff(Te)
;INPUT:	
;	Te:	flt,fltarr		electron temperature
;KEYWORDS
;	pot	flt,fltarr		if fltarr, then n_elements(pot)=n_elements(te), default pot=0
;	tmax	flt			algorithm parameter, default tmax = 2.283
;	aa	flt			algorithm parameter, default aa = 1.35
;	emax	flt			algorithm parameter, default emax = 325
;	kk	flt			algorithm parameter, default kk = 2.2
;	sec_max	flt			algorithm parameter, default sec_max=2.
;	te_sec	flt			algorithm parameter, default te_sec=2.
;					
;PURPOSE:
;	Returns the fractional secondary electron flux with energy > pot
;NOTES:	
;
;CREATED BY:
;	J.McFadden	09-05-31	
;LAST MODIFICATION:
;-
function e_sec_eff,Te,pot=pot,tmax=tmax,aa=aa,emax=emax,kk=kk,sec_max=sec_max

; Make electron secondary energy efficiency array 
;	formula is an offshoot of the following MCP efficiency formula
; 	REF: Relative electron detection efficiency of microchannel plates from 0-3 keV
; 	R.R. Goruganthu and W. G. Wilson, Rev. Sci. Instrum. Vol. 55, No. 12 Dec 1984

	if not keyword_set(pot) then pot = 0
	if not keyword_set(tmax) then tmax = 2.283
	if not keyword_set(aa) then aa = 1.35
	if not keyword_set(emax) then emax = 325.  ;  325 eV
	if not keyword_set(kk) then kk = 2.2
	if not keyword_set(sec_max) then sec_max=2.
	if not keyword_set(te_sec) then te_sec=2.
	delta = ((Te+(pot>0.))/emax)^(1-aa)*(1-exp(-tmax*((Te+(pot>0.))/emax)^aa))/(1-exp(-tmax))
	en_eff = exp(-20./Te)/exp(-20./emax)*exp(-(pot>0.)/te_sec)*exp((pot<0.)/Te)*sec_max*(1-exp(-kk*delta))/(1-exp(-kk))

return, en_eff

end

