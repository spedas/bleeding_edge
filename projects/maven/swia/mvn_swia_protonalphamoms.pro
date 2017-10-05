;+
;PROCEDURE: 
;	MVN_SWIA_PROTONALPHAMOMS
;PURPOSE: 
;	Routine to compute approximately the proton and alpha moments from fine 
;	distributions. Does not work if distribution is too hot and they overlap. 
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PROTONALPHAMOMS, TRANGE = TRANGE
;INPUTS:
;KEYWORDS:
;	TRANGE: Time Range to Compute Moments
;	ARCHIVE: Use Archive data instead of Survey (default)
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-06-17 12:09:07 -0700 (Tue, 17 Jun 2014) $
; $LastChangedRevision: 15394 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_protonalphamoms.pro $
;
;-

pro mvn_swia_protonalphamom, dat = dat, n1, t1, v1, n2, t2, v2, plot = plot, archive = archive

compile_opt idl2

if not keyword_set(dat) then begin
	ctime,t,npoints = 1
	dat = mvn_swia_get_3df(t, archive = archive)
endif

n0 = n_3d(dat)
t0 = t_3d(dat)
v0 = v_3d(dat)

e0 = 0.5*1.67e-27*total(v0*v0)*1e6/1.6e-19
ecut = e0*1.5

if keyword_set(plot) then begin
	print,n0
	print,t0
	print,v0
	print,e0
	print,ecut
endif


dat0 = dat
dat1 = dat

w = where(dat0.energy gt ecut)
dat0.data[w] = 0

n1 = n_3d(dat0)
t1 = t_3d(dat0)
v1 = v_3d(dat0)

if keyword_set(plot) then begin
	print,n1
	print,t1
	print,v1
endif

w = where(dat1.energy lt ecut)
dat1.data[w] = 0

dat1.mass = dat1.mass*4.0
dat1.energy = 2*dat1.energy
dat1.denergy = 2*dat1.denergy

n2 = n_3d(dat1)
t2 = t_3d(dat1)
v2 = v_3d(dat1)

if keyword_set(plot) then begin
	print,n2
	print,t2
	print,v2
endif

end


pro mvn_swia_protonalphamoms, archive = archive, trange = trange

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
	if i mod 1000 eq 0 then print,i,'/',nt,',    ', time_string(time[i])
	dat = mvn_swia_get_3df(time[i],archive = archive)
	
	mvn_swia_protonalphamom,dat = dat, n1,t1,v1, n2, t2, v2
	dens0[i] = n1
	temp0[i,*] = t1[0:2]
	vel0[i,*] = v1
	dens1[i] = n2
	temp1[i,*] = t2[0:2]
	vel1[i,*] = v2
	
endfor


store_data,'nproton',data = {x:time+2.0,y:dens0}
store_data,'tproton',data = {x:time+2.0,y:temp0,v:[0,1,2]}
store_data,'vproton',data = {x:time+2.0,y:vel0,v:[0,1,2]}

store_data,'nalpha',data = {x:time+2.0,y:dens1}
store_data,'talpha',data = {x:time+2.0,y:temp1,v:[0,1,2]}
store_data,'valpha',data = {x:time+2.0,y:vel1,v:[0,1,2]}

end
