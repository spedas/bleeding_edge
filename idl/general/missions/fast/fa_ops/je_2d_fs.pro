;+
;FUNCTION:	je_2d_fs(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_fa_ees, get_fa_ies, etc.
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
;	Returns the field aligned energy flux, JEz, ergs/cm^2-sec, assumes a narrow (< 5 deg) field aligned beam
;NOTES:	
;	Same as je_2d_b.pro, accept separates 64 angle fast survey data 
;		for FAST to do a more accurated calculation.
;	Function normally called by "get_2dt.pro" to generate 
;		time series data for "tplot.pro".
;	Note that the EBINS, ARANGE, and BINS keywords below may not work 
;		properly since their meaning changes with 32 or 64 angle bins.
;
;CREATED BY:
;	J.McFadden	97-8-13		Treats FAST fast survey narrow beams correctly, calls je_2d_b.pro
;LAST MODIFICATION:
;	97-8-13		J.McFadden
;-
function je_2d_fs,dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins

if dat.valid eq 0 then begin
	print,'Invalid Data'
	eflux3dz = 0.
	return, eflux3dz
endif

if dat.nbins eq 32 or dat.project_name ne 'FAST' then begin
	return, je_2d_b(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
endif

ind1=findgen(32)*2
ind2=ind1+1
if ndimen(dat.geom) eq 1 then begin
	geom1=dat.geom(ind1) 
	geom2=dat.geom(ind2) 
endif else begin
	geom1=dat.geom(*,ind1)
	geom2=dat.geom(*,ind2)
endelse
if ndimen(dat.dtheta) eq 1 then begin
	dtheta1=dat.dtheta(ind1)*2. 
	dtheta2=dat.dtheta(ind2)*2. 
endif else begin
	dtheta1=dat.dtheta(*,ind1)*2.
	dtheta2=dat.dtheta(*,ind2)*2.
endelse

dat1 = 		{data_name:		dat.data_name, 			$
		valid: 			1, 				$
		project_name:		dat.project_name, 		$
		units_name: 		dat.units_name, 		$
		units_procedure: 	dat.units_procedure, 		$
		time: 			dat.time, 			$
		end_time: 		dat.end_time, 			$
		integ_t: 		dat.integ_t,			$
		nbins: 			32, 				$
		nenergy: 		dat.nenergy, 			$
		data: 			dat.data(*,ind1), 		$
		energy: 		dat.energy(*,ind1), 		$
		theta: 			dat.theta(*,ind1),  		$
		geom: 			geom1, 	 			$
		denergy: 		dat.denergy(*,ind1),       	$
		dtheta: 		dtheta1, 			$
		eff: 			dat.eff,	 		$
		mass: 			dat.mass, 			$
		geomfactor: 		dat.geomfactor, 		$
		header_bytes: 		dat.header_bytes}


dat2 = 		{data_name:		dat.data_name, 			$
		valid: 			1, 				$
		project_name:		dat.project_name, 		$
		units_name: 		dat.units_name, 		$
		units_procedure: 	dat.units_procedure, 		$
		time: 			dat.time, 			$
		end_time: 		dat.end_time, 			$
		integ_t: 		dat.integ_t,			$
		nbins: 			32, 				$
		nenergy: 		dat.nenergy, 			$
		data: 			dat.data(*,ind2), 		$
		energy: 		dat.energy(*,ind2), 		$
		theta: 			dat.theta(*,ind2),  		$
		geom: 			geom2, 	 			$
		denergy: 		dat.denergy(*,ind2),       	$
		dtheta: 		dtheta2, 			$
		eff: 			dat.eff,	 		$
		mass: 			dat.mass, 			$
		geomfactor: 		dat.geomfactor, 		$
		header_bytes: 		dat.header_bytes}


;	Note that the EBINS, ARANGE, and BINS keywords below may not work properly.

j1=je_2d_b(dat1,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)
j2=je_2d_b(dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins)

;print,'j1=',j1
;print,'j2=',j2
j_avg=(j1+j2)/2.

return,j_avg

; units are ergs/cm^2-sec

end

