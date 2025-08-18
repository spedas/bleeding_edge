;+
;PROCEDURE: 
;	MVN_SWIA_SWINDAVE
;PURPOSE: 
;	Routine to determine density and velocity of undisturbed upstream solar wind
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_SWINDAVE, REG = REG, IMF = IMF
;INPUTS:
;KEYWORDS:
;	REG: region structure from 'mvn_swia_regid'
;	NPO: number of determinations per orbit
;	IMF: if set, calculate upstream IMF
;	ALPHAPROTON: if set, calculate alpha/proton quantities
;
; $LastChangedBy: hara $
; $LastChangedDate: 2015-09-10 15:18:07 -0700 (Thu, 10 Sep 2015) $
; $LastChangedRevision: 18762 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_swindave.pro $
;
;-

pro mvn_swia_swindave, reg = reg, npo = npo, imf = imf, alphaproton = alphaproton, bdata = bdata

common mvn_swia_data

if not keyword_set(bdata) then bdata = 'mvn_B_1sec_MAVEN_MSO'
if not keyword_set(npo) then npo = 1

if keyword_set(reg) then begin
	ureg = interpol(reg.y[*,0],reg.x,swim.time_unix+2.0)
	w = where(ureg eq 1)
	uswim = swim[w]
endif else begin
	uswim = swim
endelse

times = uswim.time_unix+2.0 ; centered time
vels = sqrt(total(uswim.velocity*uswim.velocity,1))
densities = uswim.density

if keyword_set(imf) then begin
	get_data,bdata,data = bvec
	bx = interpol(bvec.y[*,0],bvec.x,times)
	by = interpol(bvec.y[*,1],bvec.x,times)
	bz = interpol(bvec.y[*,2],bvec.x,times)
endif
if keyword_set(alphaproton) then begin
	get_data,'nproton',data = nproton
	np = interpol(nproton.y,nproton.x,times)
	get_data,'nalpha',data = nalpha
	na = interpol(nalpha.y,nalpha.x,times)
	get_data,'vproton',data = vproton
	vp = interpol(sqrt(total(vproton.y*vproton.y,2)),vproton.x,times)
	get_data,'valpha',data = valpha
	va = interpol(sqrt(total(valpha.y*valpha.y,2)),valpha.x,times)
	get_data,'tproton',data = tproton
	tpx = interpol(tproton.y[*,0],tproton.x,times)
	tpy = interpol(tproton.y[*,1],tproton.x,times)
	tpz = interpol(tproton.y[*,2],tproton.x,times)
	get_data,'talpha',data = talpha
	tax = interpol(talpha.y[*,0],talpha.x,times)
	tay = interpol(talpha.y[*,1],talpha.x,times)
	taz = interpol(talpha.y[*,2],talpha.x,times)
endif

orb = mvn_orbit_num(time = times)
orb = floor(orb*npo)

mino = min(orb)
maxo = max(orb)
norb = maxo-mino+1

nout = fltarr(norb)
vout = fltarr(norb)
tout = dblarr(norb)
nstd = fltarr(norb)
vstd = fltarr(norb)

if keyword_set(imf) then begin
	bxout = fltarr(norb)
	byout = fltarr(norb)
	bzout = fltarr(norb)
	bxstd = fltarr(norb)
	bystd = fltarr(norb)
	bzstd = fltarr(norb)
endif

if keyword_set(alphaproton) then begin
	npout = fltarr(norb)
	naout = fltarr(norb)
	vpout = fltarr(norb)
	vaout = fltarr(norb)
	tpxout = fltarr(norb)
	tpyout = fltarr(norb)
	tpzout = fltarr(norb)
	taxout = fltarr(norb)
	tayout = fltarr(norb)
	tazout = fltarr(norb)
endif

for i = 0,norb-1 do begin
	w = where(orb eq (mino+i),nw)
	if nw gt 10 then begin
		nout[i] = mean(densities[w],/nan)
		nstd[i] = stddev(densities[w],/nan)
		vout[i] = mean(vels[w],/nan)
		vstd[i] = stddev(vels[w],/nan)
		tout[i] = mean(times[w],/double,/nan)
		

		if keyword_set(imf) then begin
			bxout[i] = mean(bx[w],/nan)
			byout[i] = mean(by[w],/nan)
			bzout[i] = mean(bz[w],/nan)
			bxstd[i] = stddev(bx[w],/nan)
			bystd[i] = stddev(by[w],/nan)
			bzstd[i] = stddev(bz[w],/nan)
		endif

		if keyword_set(alphaproton) then begin
			npout[i] = mean(np[w],/nan)
			naout[i] = mean(na[w],/nan)
			vpout[i] = mean(vp[w],/nan)
			vaout[i] = mean(va[w],/nan)
			tpxout[i] = mean(tpx[w],/nan)
			tpyout[i] = mean(tpy[w],/nan)
			tpzout[i] = mean(tpz[w],/nan)
			taxout[i] = mean(tax[w],/nan)
			tayout[i] = mean(tay[w],/nan)
			tazout[i] = mean(taz[w],/nan)
		endif
	endif
endfor

w = where(tout ne 0)

store_data,'nsw',data = {x:tout[w],y:nout[w]}
store_data,'vsw',data = {x:tout[w],y:vout[w]}
store_data,'nswstd',data = {x:tout[w],y:nstd[w]}
store_data,'vswstd',data = {x:tout[w],y:vstd[w]}

if keyword_set(imf) then begin
	store_data,'bsw',data = {x:tout[w],y:[[bxout[w]],[byout[w]],[bzout[w]]],v:[0,1,2]}
	store_data,'bswstd',data = {x:tout[w],y:[[bxstd[w]],[bystd[w]],[bzstd[w]]],v:[0,1,2]}
endif

if keyword_set(alphaproton) then begin
	store_data,'npsw',data = {x:tout[w],y:npout[w]}
	store_data,'nasw',data = {x:tout[w],y:naout[w]}
	store_data,'vpsw',data = {x:tout[w],y:vpout[w]}
	store_data,'vasw',data = {x:tout[w],y:vaout[w]}
	store_data,'tpsw',data = {x:tout[w],y:[[tpxout[w]],[tpyout[w]],[tpzout[w]]],v:[0,1,2]}
	store_data,'tasw',data = {x:tout[w],y:[[taxout[w]],[tayout[w]],[tazout[w]]],v:[0,1,2]}
endif

end
