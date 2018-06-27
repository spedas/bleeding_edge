;+
;FUNCTION:	m_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;	Returns the components of the momentum tensor, corrects for spacecraft potential if dat.sc_pot exists
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	2014-02-27	
;LAST MODIFICATION:
;-
function m_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt

mom_ten = [0.,0.,0.,0.,0.,0.]

if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, mom_ten
endif

if (dat2.quality_flag and 195) gt 0 then return,mom_ten

if dat2.nbins eq 1 then return,mom_ten

dat = conv_units(dat2,"counts")		; initially use counts
na = dat.nenergy
nb = dat.nbins
nm = dat.nmass

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
domega = dat.domega
	if ndimen(domega) eq 0 then domega=replicate(1.,dat.nenergy)#domega
mass = dat.mass*dat.mass_arr 
pot = dat.sc_pot

if keyword_set(bins) and nb gt 1 then begin
	bins2 = transpose(reform(bins#replicate(1.,na*nm),nb,nm,na),[2,0,1])
	data=data*bins2
	bkg = bkg*bins2
endif

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

if keyword_set(mi) then begin
	dat.mass_arr[*]=mi 
endif else begin
	if keyword_set(ms) then dat.mass_arr=(ms[0]+ms[1])/2. else $
	dat.mass_arr[*]=round(dat.mass_arr-.1)>1. 			; the minus 0.1 helps account for straggling at low mass
endelse

mass=dat.mass*dat.mass_arr 

;if keyword_set(mincnt) then if total(data) lt mincnt then return,mom_ten
if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, mom_ten
if total(data-bkg) lt 1 then return, mom_ten

dat.cnts=data
dat.bkg=bkg
dat = conv_units(dat,"df")		; Use distribution function
data=dat.data

Const = (1.d*mass)^(-1.5)*(2.)^1.5
charge=dat.charge
if keyword_set(q) then charge=q
energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

th1=theta-dtheta/2.
th2=theta+dtheta/2.
ph1=phi-dphi/2.
ph2=phi+dphi/2.
cth1 = cos(th1)
cth2 = cos(th2)
sth1 = sin(th1)
sth2 = sin(th2)
cph1 = cos(ph1)
cph2 = cos(ph2)
sph1 = sin(ph1)
sph2 = sin(ph2)
s_2ph1 = sin(2.*ph1)
s_2ph2 = sin(2.*ph2)
s2_ph1 = sph1^2
s2_ph2 = sph2^2
s3_th1 = sth1^3
s3_th2 = sth2^3 
c3_th1 = cth1^3
c3_th2 = cth2^3 

if dat.nbins eq 1 then begin

	m4dxx = total(Const*denergy*(energy^(1.5))*data*((ph2-ph1)/2.+(s_2ph2-s_2ph1)/4.)*(sth2-sth1-(s3_th2-s3_th1)/3.),1)
	m4dyy = total(Const*denergy*(energy^(1.5))*data*((ph2-ph1)/2.-(s_2ph2-s_2ph1)/4.)*(sth2-sth1-(s3_th2-s3_th1)/3.),1)
	m4dzz = total(Const*denergy*(energy^(1.5))*data*dphi*(s3_th2-s3_th1)/3.,1)
	m4dxy = total(Const*denergy*(energy^(1.5))*data*((s2_ph2-s2_ph1)/2.)*(sth2-sth1-(s3_th2-s3_th1)/3.),1)
	m4dxz = total(Const*denergy*(energy^(1.5))*data*(sph2-sph1)*((c3_th1-c3_th2)/3.),1)
	m4dyz = total(Const*denergy*(energy^(1.5))*data*(cph1-cph2)*((c3_th1-c3_th2)/3.),1)

endif else begin	

	m4dxx = total(total(Const*denergy*(energy^(1.5))*data*((ph2-ph1)/2.+(s_2ph2-s_2ph1)/4.)*(sth2-sth1-(s3_th2-s3_th1)/3.),1),1)
	m4dyy = total(total(Const*denergy*(energy^(1.5))*data*((ph2-ph1)/2.-(s_2ph2-s_2ph1)/4.)*(sth2-sth1-(s3_th2-s3_th1)/3.),1),1)
	m4dzz = total(total(Const*denergy*(energy^(1.5))*data*dphi*(s3_th2-s3_th1)/3.,1),1)
	m4dxy = total(total(Const*denergy*(energy^(1.5))*data*((s2_ph2-s2_ph1)/2.)*(sth2-sth1-(s3_th2-s3_th1)/3.),1),1)
	m4dxz = total(total(Const*denergy*(energy^(1.5))*data*(sph2-sph1)*((c3_th1-c3_th2)/3.),1),1)
	m4dyz = total(total(Const*denergy*(energy^(1.5))*data*(cph1-cph2)*((c3_th1-c3_th2)/3.),1),1)

endelse	

if keyword_set(ms) then begin
	m4dxx = total(m4dxx)
	m4dyy = total(m4dyy)
	m4dzz = total(m4dzz)
	m4dxy = total(m4dxy)
	m4dxz = total(m4dxz)
	m4dyz = total(m4dyz)
endif

;	Momentum tensor M is in units of eV/cm^3, Pressure P = M - mass*vel*flux/1.e10

return, transpose([[m4dxx],[m4dyy],[m4dzz],[m4dxy],[m4dxz],[m4dyz]])

end
