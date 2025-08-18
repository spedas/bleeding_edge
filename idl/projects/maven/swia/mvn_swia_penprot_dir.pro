;+
;PROCEDURE: 
;	MVN_SWIA_PENPROT_DIR
;PURPOSE: 
;	Routine to determine density and velocity of penetrating protons at periapsis
;	Uses directional spectra to better filter out penetrating proton population
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PENPROT_DIR, REG = REG, NPO = NPO, /ARCHIVE
;INPUTS:
;KEYWORDS:
;	REG: region structure from 'mvn_swia_regid'
;	NPO: number of determinations per orbit
;	ARCHIVE: use archive data
;	INVEC: Allows you to use a different set of spectra for computation
;		Assumed to be on the same energy scale
;	VFILT: Keep only points that agree with upstream solar wind velocity
;	VTHRESH: Percentage difference from upstream velocity to allow
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2017-01-04 13:27:52 -0800 (Wed, 04 Jan 2017) $
; $LastChangedRevision: 22491 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_penprot_dir.pro $
;
;-

pro mvn_swia_penprot_dir, reg = reg, npo = npo, archive = archive, attfilt = attfilt, invec = invec, vfilt = vfilt, vthresh = vthresh, minsamp = minsamp, swea = swea

if not keyword_set(minsamp) then minsamp = 3

mass = 0.0104389*1.6e-22
Const = (mass/(2.*1.6e-12))^0.5

if not keyword_set(npo) then npo = 1
if not keyword_set(vthresh) then vthresh = 0.15

common mvn_swia_data

if keyword_set(swea) then begin
	if keyword_set(archive) then begin
		get_data,'mvn_swe_et_3d_arc_anti_sun',data = data 
		denergy = data.v*0.117

		get_data,'mvn_swe_et_3d_arc_sun',data = pX
		get_data,'mvn_swe_et_3d_arc_dusk',data = pY
		get_data,'mvn_swe_et_3d_arc_dawn',data = mY
		get_data,'mvn_swe_et_3d_arc_north',data = pZ
		get_data,'mvn_swe_et_3d_arc_south',data = mZ
	endif else begin
		get_data,'mvn_swe_et_3d_svy_anti_sun',data = data 
		denergy = data.v*0.117	

		get_data,'mvn_swe_et_3d_svy_sun',data = pX
		get_data,'mvn_swe_et_3d_svy_dusk',data = pY
		get_data,'mvn_swe_et_3d_svy_dawn',data = mY
		get_data,'mvn_swe_et_3d_svy_north',data = pZ
		get_data,'mvn_swe_et_3d_svy_south',data = mZ

	endelse

endif else begin

	if keyword_set(archive) then begin
		get_data,'mvn_swica_en_eflux_MSO_mX',data = data 
		denergy = data.v*(info_str[swica.info_index].deovere_coarse#replicate(1,48))

		get_data,'mvn_swica_en_eflux_MSO_pX',data = pX
		get_data,'mvn_swica_en_eflux_MSO_pY',data = pY
		get_data,'mvn_swica_en_eflux_MSO_mY',data = mY
		get_data,'mvn_swica_en_eflux_MSO_pZ',data = pZ
		get_data,'mvn_swica_en_eflux_MSO_mZ',data = mZ
	endif else begin
		get_data,'mvn_swics_en_eflux_MSO_mX',data = data
		denergy = data.v*(info_str[swics.info_index].deovere_coarse#replicate(1,48))	

		get_data,'mvn_swics_en_eflux_MSO_pX',data = pX
		get_data,'mvn_swics_en_eflux_MSO_pY',data = pY
		get_data,'mvn_swics_en_eflux_MSO_mY',data = mY
		 get_data,'mvn_swics_en_eflux_MSO_pZ',data = pZ
		get_data,'mvn_swics_en_eflux_MSO_mZ',data = mZ
	endelse
endelse

w = where(1-finite(pX.y)) & if w(0) ne -1 then pX.y(w) = 0
w = where(1-finite(pY.y)) & if w(0) ne -1 then pY.y(w) = 0
w = where(1-finite(mY.y)) & if w(0) ne -1 then mY.y(w) = 0
w = where(1-finite(pZ.y)) & if w(0) ne -1 then pZ.y(w) = 0
w = where(1-finite(mZ.y)) & if w(0) ne -1 then mZ.y(w) = 0

if keyword_set(invec) then get_data,invec,data = data

if keyword_set(reg) then begin
	ureg = interpol(reg.y[*,0],reg.x,data.x)
	w = where(ureg eq 4)
	times = data.x[w]
	spectra = data.y[w,*]
	energies = data.v[w,*]
	denergies = denergy[w,*]

	bspectra = pX.y[w,*]*2.22 + pY.y[w,*]*2.22 + mY.y[w,*]*2.22 + pZ.y[w,*]*1.84 + mZ.y[w,*]*1.84

;	if keyword_set(swea) then spectra = (data.y[w,*]-pX.y[w,*]) > 0
endif else begin
	times = data.x
	spectra = data.y
	energies = data.v
	denergies = denergy

	bspectra = pX.y*2.22+pY.y*2.22+mY.y*2.22+pZ.y*1.84+mZ.y*1.84

;	if keyword_set(swea) then spectra = (data.y-pX.y) > 0
endelse


if keyword_set(attfilt) then begin
	if keyword_set(swea) then begin
		if keyword_set(archive) then get_data,'mvn_swica_MSO_Xvec',data = zvec else get_data,'mvn_swics_MSO_Xvec',data = zvec 
		zx = interpol(zvec.y[*,0],zvec.x,times)
	endif else begin
		if keyword_set(archive) then get_data,'mvn_swica_MSO_Zvec',data = zvec else get_data,'mvn_swics_MSO_Zvec',data = zvec 
		zx = interpol(zvec.y[*,0],zvec.x,times)
	endelse
endif else begin
	zx = replicate(0,n_elements(times))
endelse

orb = mvn_orbit_num(time = times)
orb = floor((orb+0.5)*npo)  ; deal with silly orbit convention

mino = min(orb)
maxo = max(orb)
norb = maxo-mino+1

nout = fltarr(norb)
nbout = fltarr(norb)
vout = fltarr(norb)
tout = dblarr(norb)
mmax = fltarr(norb)

for i = 0,norb-1 do begin
	if keyword_set(swea) then begin
		w = where(orb eq (mino+i) and abs(zx) lt 0.866,nw)
	endif else begin
		w = where(orb eq (mino+i) and abs(zx) lt 1/sqrt(2),nw)		
	endelse
	if nw gt (minsamp-1) then begin
		spec = total(spectra[w,*],1,/nan)/nw
		bspec = total(bspectra[w,*],1,/nan)/nw
		energy = total(energies[w,*],1,/nan)/nw
		denergy = total(denergies[w,*],1,/nan)/nw
		
		if keyword_set(swea) then begin
			wr = where(energy gt 600 and energy lt 4000)
		endif else begin
			wr = where(energy gt 200 and energy lt 4000)
		endelse
		spec = spec-min(spec[wr]) > 0
		bspec = bspec-min(bspec[wr]) > 0
		nout[i] = Const*!pi/sqrt(2)*total(denergy[wr]*energy[wr]^(-1.5)*spec[wr])
		nbout[i] = Const*total(denergy[wr]*energy[wr]^(-1.5)*bspec[wr])

		maxc = max(spec[wr],maxi)
		eout = energy(wr[maxi])
		vout[i] = sqrt(2*eout*1.6e-19/1.67e-27)/1e3
		tout[i] = mean(times[w],/double,/nan)
		mmax[i] = maxc/mean(spec[wr])
	endif
endfor

w = where(tout ne 0)

if keyword_set(vfilt) then begin
	get_data,'vsw',data = vsw
	cv = interpol(vsw.y,vsw.x,tout[w])
	ww = where(abs(vout[w]-cv)/cv lt vthresh)
	w = w[ww]
endif

store_data,'npen',data = {x:tout[w],y:nout[w]}
store_data,'nbpen',data = {x:tout[w],y:nbout[w]}
store_data,'vpen',data = {x:tout[w],y:vout[w]}
store_data,'mmax',data = {x:tout[w],y:mmax[w]}

end