;+
;FUNCTION:	t_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
;INPUT:	
;	dat:	structure,	4d data structure filled by themis routines mvn_sta_c6.pro, mvn_sta_d0.pro, etc.
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
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
;-
function t_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

Tavg = 0.
Tx = 0.
Ty = 0.
Tz = 0.

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, [Tx,Ty,Tz,Tavg]
endif

if (dat2.quality_flag and 195) gt 0 then return,[Tx,Ty,Tz,Tavg]

dat=dat2

if dat.nbins eq 1 then return,tb_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q)

press   = p_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
density = n_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)

if keyword_set(ms) then begin
	Tavg = reform(press[0]+press[1]+press[2])/((density+1.e-10)*3.)
	Tx = reform(press[0])/(density+1.e-10)
	Ty = reform(press[1])/(density+1.e-10)
	Tz = reform(press[2])/(density+1.e-10)
endif else begin
	Tavg = reform(press[0,*]+press[1,*]+press[2,*])/((density+1.e-10)*3.)
	Tx = reform(press[0,*])/(density+1.e-10)
	Ty = reform(press[1,*])/(density+1.e-10)
	Tz = reform(press[2,*])/(density+1.e-10)
endelse

return, transpose([[Tx],[Ty],[Tz],[Tavg]])

end

