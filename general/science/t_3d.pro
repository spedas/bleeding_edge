;+
;FUNCTION:	t_3d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
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
;	Returns the temperature, [Tx,Ty,Tz,Tavg], eV 
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	95-7-27
;LAST MODIFICATION:
;	96-7-6		J.McFadden
;-
function t_3d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

Tavg = 0.
Tx = 0.
Ty = 0.
Tz = 0.

if dat2.valid eq 0 then begin
	dprint, 'Invalid Data'
	return, [Tx,Ty,Tz,Tavg]
endif

press = p_3d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
density = n_3d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
if density ne 0. then begin
	Tavg = (press(0)+press(1)+press(2))/(density*3.)
	Tx = press(0)/(density)
	Ty = press(1)/(density)
	Tz = press(2)/(density)
endif

return, [Tx,Ty,Tz,Tavg]

end

