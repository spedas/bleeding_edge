;+
;FUNCTION:	dn_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=mass,m_int=mi,q=q,mincnt=mincnt)
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
;	MASS:	intarr(nm)	optional, 
;PURPOSE:
;	Returns the density array, n, 1/cm^3, corrects for spacecraft potential if dat.sc_pot exists
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;	This routine does not work - its only a placeholder 
;
;CREATED BY:
;	J.McFadden	13-11-13	
;LAST MODIFICATION:
;-
function dn_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt,nn=nn,print=print,seed=seed

density = 0.

if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, density
endif

dat = conv_units(dat2,"counts")		; initially use counts
na = dat.nenergy
nb = dat.nbins
nm = dat.nmass

; cnt=total(dat.data)/!pi			; start with a random number
if not keyword_set(nn) then nn = 20 
dnavg=0
den = n_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
;if not keyword_set(seed) then seed = total(dat.data)/!pi	
for i=0,nn-1 do begin
	tmp = dat
	tmp.data = dat.data + dat.data^.5*randomn(seed,na,nb,nm)
	tmp.cnts = tmp.data 
	tmp_den = n_4d(tmp,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
	dnavg = dnavg + abs(den - tmp_den)
;	seed=total(tmp.data)/!pi
;	seed=total(tmp.data*(i+7))/!pi
if keyword_set(print) then help,seed
if keyword_set(print) then print,den,tmp_den,dnavg,minmax(randomn(seed,na,nb,nm))
;	cnt = total(tmp.data)/!pi 
endfor
ddensity = dnavg/nn

; units are 1/cm^3

return, ddensity
end
