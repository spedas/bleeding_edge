;+
;FUNCTION:	ec_2d_new((dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
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
;	Returns the characteristic energy, Ec, eV
;NOTES:	
;	Function calls j_2d.pro and je_2d.pro
;	Function normally called by "get_2dt.pro" to generate 
;	time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	04-10-22
;LAST MODIFICATION:
;	04-10-22		J.McFadden
;-
function ec_2d_new,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

Ec = 0.

if dat2.valid ne 1 then begin
	print,'Invalid Data'
	return, Ec
endif

flux = j_2d_new(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
eflux = je_2d_new(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)

if (abs(flux) gt 1.) then Ec = abs(eflux/(flux*1.6e-12))

; units are eV

return, Ec

end

