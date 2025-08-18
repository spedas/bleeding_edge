;+
;FUNCTION:	vc_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;	Returns the normalized velocity unit vector, [Vx,Vy,Vz]/Vmag, km/s for each mass bin 
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	14-02-26	
;LAST MODIFICATION:
;-
function vc_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

vel = [0.,0.,0.]

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, vel
endif

if (dat2.quality_flag and 195) gt 0 then return,vel

if dat2.nbins eq 1 then return,vel

dat = conv_units(dat2,"counts")		; initially use counts

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy
theta = dat.theta/!radeg
phi = dat.phi/!radeg

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
endif
if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
endif

if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return,[0.,0.,0.]
if total(data-bkg) lt 1 then return, [0.,0.,0.]

dat.cnts=data
dat.bkg=bkg
dat = conv_units(dat2,"eflux")		; Use energy flux
data=dat.data

if dat.nmass gt 1 then begin
	an_arr = total(total(data,3),1)
	max_an = max(an_arr,ind)
	vx = cos(theta[0,ind,0])*cos(phi[0,ind,0])
	vy = cos(theta[0,ind,0])*sin(phi[0,ind,0])
	vz = sin(theta[0,ind,0])
endif else begin
	an_arr = total(data,1)
	max_an = max(an_arr,ind)
	vx = cos(theta[0,ind])*cos(phi[0,ind])
	vy = cos(theta[0,ind])*sin(phi[0,ind])
	vz = sin(theta[0,ind])

endelse

return,[vx,vy,vz]		; unit vector

end

