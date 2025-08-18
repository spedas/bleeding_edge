;+
;FUNCTION:	vth_3d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
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
;	Returns the thermal velocity, [Vthx,Vthy,Vthz,Vthavg], km/s 
;NOTES:	
;	Function normally called by "get_3dt" or "get_2dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	95-7-27
;LAST MODIFICATION:
;	96-7-6		J.McFadden
;-
function vth_3d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

vth = 0.
vthx = 0.
vthy = 0.
vthz = 0.

if dat2.valid eq 0 then begin
	dprint, 'Invalid Data'
	return, [vthx,vthy,vthz,vth]
endif

mass = dat2.mass * 1.6e-22
press = p_3d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
density = n_3d(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
if density ne 0. then begin
	Tavg = (press(0)+press(1)+press(2))/(density*6.)
	Tx = press(0)/(density*2.)
	Ty = press(1)/(density*2.)
	Tz = press(2)/(density*2.)
	vth = 1.e-5*(2.*Tavg*1.6e-12/mass)^.5
	vthx = 1.e-5*(2.*Tx*1.6e-12/mass)^.5
	vthy = 1.e-5*(2.*Ty*1.6e-12/mass)^.5
	vthz = 1.e-5*(2.*Tz*1.6e-12/mass)^.5
endif

return, [vthx,vthy,vthz,vth]

end

