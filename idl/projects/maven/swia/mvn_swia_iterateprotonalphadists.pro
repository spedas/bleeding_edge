;+
;PROCEDURE: 
;	MVN_SWIA_ITERATEPROTONALPHADISTS
;PURPOSE: 
;	Routine to compute approximately the proton and alpha moments from fine 
;	distributions, using a fit routine based on the SWIA energy/angle response.
; 	Intended to be appropriate for use when distributions are hot.  This routine 
;	is still very experimental and should be used with caution. Currently working to
;	adapt it to use simulated instrument response.
;	Currently deconvolution in energy/theta is working, but there is also blurring
;	in phi at high deflection angles that is not properly accounted for. 
; 
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_ITERATEPROTONALPHADISTS, TRANGE = TRANGE
;INPUTS:
;KEYWORDS:
;	TRANGE: Time Range to Compute Moments
;	ARCHIVE: Use Archive data instead of Survey (default)
;	NREPS: Number of iterations (default 4)
;	DPATH: path to model results used for deconvolution
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-01-02 11:31:48 -0800 (Fri, 02 Jan 2015) $
; $LastChangedRevision: 16563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_iterateprotonalphadists.pro $
;
;-

@mvn_swia_protonalphamoms

pro mvn_swia_protonalphadist, dat, ndat, protonparams = protonparams, alphaparams = alphaparams, dpath = dpath

if not keyword_set(dpath) then dpath = '~jsh/work/Research/SWIA/mdl/'

restore,dpath+'allgresparr.sav'

compile_opt idl2

dat = conv_units(dat,'eflux')

if not keyword_set(protonparams) then begin
	mvn_swia_protonalphamom, dat = dat, n1, t1, v1, n2, t2, v2
	protonparams = [n1,v1,t1]
	alphaparams = [n2,v2,t2]
endif

kb = 1.38d-23
mi = 1.67d-27
ee = 1.6d-19

np = protonparams[0]*1e6
na = alphaparams[0]*1e6

vpdx = protonparams[1]*1e3
vpdy = protonparams[2]*1e3
vpdz = protonparams[3]*1e3

vadx = alphaparams[1]*1e3
vady = alphaparams[2]*1e3
vadz = alphaparams[3]*1e3

tpx = protonparams[4]*ee/kb 
tpy = protonparams[5]*ee/kb
tpz = protonparams[6]*ee/kb

tax = alphaparams[4]*ee/kb 
tay = alphaparams[5]*ee/kb
taz = alphaparams[6]*ee/kb


vpthx = (2*kb*tpx/mi)^.5
vpthy = (2*kb*tpy/mi)^.5
vpthz = (2*kb*tpz/mi)^.5

vathx = (2*kb*tax/mi/4)^.5
vathy = (2*kb*tay/mi/4)^.5
vathz = (2*kb*taz/mi/4)^.5


erange = [min(dat.energy),max(dat.energy)]
nen = round((erange[1]-erange[0])/10) + 10
ebase = erange[0] -50 + 10*findgen(nen)

thrange = [min(dat.theta),max(dat.theta)]
nth = round((thrange[1]-thrange[0])/1.5) + 5
thbase = thrange[0]-3.75 + findgen(nth)*1.5

phbase = 158.25 + findgen(30)*1.5 


energy = fltarr(nen,nth,30)
for i = 0,nen-1 do energy[i,*,*] = ebase[i]
phi = fltarr(nen,nth,30)
for i = 0,29 do phi[*,*,i] = phbase[i]
theta = fltarr(nen,nth,30)
for i = 0,nth-1 do theta[*,i,*] = thbase[i]



f0p=np*((mi)/(2.*!pi*kb))^1.5/(tpx*tpy*tpz)^.5
f0a=na*((mi*4)/(2.*!pi*kb))^1.5/(tax*tay*taz)^.5

vpx=((2*energy*ee/mi))^.5*cos(theta/!radeg)*cos(phi/!radeg)
vpy=((2*energy*ee/mi))^.5*cos(theta/!radeg)*sin(phi/!radeg)
vpz=((2*energy*ee/mi))^.5*sin(theta/!radeg)

vax=((2*2*energy*ee/mi/4))^.5*cos(theta/!radeg)*cos(phi/!radeg)
vay=((2*2*energy*ee/mi/4))^.5*cos(theta/!radeg)*sin(phi/!radeg)
vaz=((2*2*energy*ee/mi/4))^.5*sin(theta/!radeg)

datap=f0p*exp(-(vpx-vpdx)^2./vpthx^2.)*exp(-(vpy-vpdy)^2./vpthy^2.)*exp(-(vpz-vpdz)^2./vpthz^2.)
dataa=f0a*exp(-(vax-vadx)^2./vathx^2.)*exp(-(vay-vady)^2./vathy^2.)*exp(-(vaz-vadz)^2./vathz^2.)


datap = datap*2*energy*ee/(mi^2)
dataa = dataa*2*2*energy*ee/((4*mi)^2)

datap = datap*energy*ee
dataa = dataa*2*energy*ee

datap = datap*1e-4
dataa = dataa*1e-4

tdata = dataa + datap

;blur in phi
for i = 0,nen-1 do for j = 0,nth-1 do tdata[i,j,*] = smooth(tdata[i,j,*],3,/nan,/edge_truncate)

tdata = rebin(tdata,nen,nth,10)

ndat = dat


ang = 10*!pi/180
ck = 7.8
sigk = ck*0.022

for i = 0,dat.nenergy-1 do begin
	for j = 0,dat.nbins-1 do begin
		emult = 7.8/dat.energy[i,j]
		thbin = j mod 12
		cth = dat.theta[i,j]
		phbin = floor(j/12)

		mindth = min(abs(cth-allx[20,*]),minthi)

		rth = allx[*,minthi]
		re = ally[*,minthi]/emult
		rg = allg[*,*,minthi]

		indx = interpol(indgen(41),rth,theta[*,*,phbin])
		indy = interpol(indgen(51),re,energy[*,*,phbin])
		resp = interpolate(rg,indx,indy,missing=0)
		ndat.data[i,j] = total(resp*tdata[*,*,phbin],/nan)/total(resp,/nan)

	endfor
endfor

ndat.data = ndat.data*total(dat.data,/nan)/total(ndat.data,/nan)

end


pro mvn_swia_iterateprotonalphadist, nreps = nreps, dat = dat, archive = archive, plot = plot, rpparams, raparams, dpath = dpath

compile_opt idl2

if not keyword_set(nreps) then nreps = 4

if not keyword_set(dat) then begin
	ctime,t,npoints = 1
	dat = mvn_swia_get_3df(t,archive = archive)
endif


mvn_swia_protonalphamom,dat = dat,n1,t1,v1,n2,t2,v2, plot = plot
pparams = [n1,v1,t1]
aparams = [n2,v2,t2]
rpparams = pparams
raparams = aparams

for i = 0,nreps-1 do begin
	mvn_swia_protonalphadist,dat,ndat,protonparams = rpparams,alphaparams=raparams, dpath = dpath
	mvn_swia_protonalphamom,dat = ndat,n1n,t1n,v1n,n2n,t2n,v2n, plot = plot
	npparams = [n1n,v1n,t1n]
	naparams = [n2n,v2n,t2n]
	
	rpparams = rpparams - (npparams-pparams)*0.7
	raparams = raparams - (naparams-aparams)*0.7
	
endfor

if keyword_set(plot) then begin
	print,rpparams
	print,raparams
endif

end
	
	
pro mvn_swia_iterateprotonalphadists, nreps = nreps, archive = archive, trange = trange, dpath = dpath


compile_opt idl2

common mvn_swia_data

if keyword_set(archive) then time = swifa.time_unix else time = swifs.time_unix

if keyword_set(trange) then time = time[where(time ge trange[0] and time le trange[1])]

nt = n_elements(time)

dens0 = fltarr(nt)
temp0 = fltarr(nt,3)
vel0 = fltarr(nt,3)
dens1 = fltarr(nt)
temp1 = fltarr(nt,3)
vel1 = fltarr(nt,3)

for i = 0,nt-1 do begin
	print,i,' / ',nt
	dat = mvn_swia_get_3df(archive = archive,time[i])
	
	mvn_swia_iterateprotonalphadist,nreps=nreps,dat = dat, rpparams, raparams, dpath = dpath

	dens0[i] = rpparams[0]
	vel0[i,*] = rpparams[1:3]
	temp0[i,*] = rpparams[4:6]
	
	dens1[i] = raparams[0]
	vel1[i,*] = raparams[1:3]
	temp1[i,*] = raparams[4:6]
	
endfor

store_data,'nproton_it',data = {x:time+2.0,y:dens0}
store_data,'vproton_it',data = {x:time+2.0,y:vel0,v:[0,1,2]}
store_data,'tproton_it',data = {x:time+2.0,y:temp0,v:[0,1,2]}

store_data,'nalpha_it',data = {x:time+2.0,y:dens1}
store_data,'valpha_it',data = {x:time+2.0,y:vel1,v:[0,1,2]}
store_data,'talpha_it',data = {x:time+2.0,y:temp1,v:[0,1,2]}

end
