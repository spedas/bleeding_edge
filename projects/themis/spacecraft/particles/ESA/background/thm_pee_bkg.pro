;+
;FUNCTION:	thm_pee_bkg(dat)
;INPUT:	
;	dat:	data structure (n,3)	vector arrays dimension (n,3) or (3)
;PURPOSE:
;	returns estimates of background determined from lowest counts in dat.data angle averaged array
;CREATED BY:
;	J.McFadden	10-04-06
;Modifications
;	J.McFadden	10-04-06		 
; aflores   2016-06-30  minor changes to integrate with spedas
;-
function thm_pee_bkg,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

  compile_opt strictarr, hidden

; most keywords included to make compatible with thm_get_2dt.pro

; first make an omni directional distribution normalized by integration time

	dat=dat2
	if ndimen(dat.data) gt 1 then datdim=1 else datdim=0
	nenergy=dat.nenergy
	if datdim then norm=total(dat.gf,2)/128. else norm=dat.gf/128.
	if datdim then odat=total(dat.data,2)/norm else odat=dat.data/norm

;	if datdim then energy=reform(dat.energy(*,0)) else energy=dat.energy

; find the two lowest count rate bins, and average to form mavg

	min1=min(odat,ind1)
	return,min1


; the below is probably not needed for electrons

	odat[ind1]=odat[ind1]+10000.
	min2=min(odat,ind2)
	mavg=(1.*min1+min2)/2.>1.
	odat[ind1]=odat[ind1]-10000.
;	print,'min1,min2= ',min1,min2

; find all bins within 2 sigma of mavg

	ind = where(odat le mavg+2.*mavg^.5)
;	print,ind
;	print,'mavg, mavg+2sig= ',mavg,mavg+2.*mavg^.5
;	print,'odat',odat

; assume background rate is the average rate of the above bins

	mavg=total(odat[ind])/n_elements(ind)
;	print,'new mavg= ',mavg

return,mavg
end
