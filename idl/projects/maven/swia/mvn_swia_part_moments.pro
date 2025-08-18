;+
;PROCEDURE: 
;	MVN_SWIA_PART_MOMENTS
;PURPOSE: 
;	Make tplot variables with moments from SWIA 3d data (coarse and/or fine), 
;	including average energy flux spectra
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	MVN_SWIA_PART_MOMENTS, TYPE = TYPE
;KEYWORDS:
;	TYPE: Array of types to calculate moments for, out of ['CS','CA','FS','FA','S']
;		(Coarse survey/archive, Fine survey/archive) - Defaults to all types
;	PHRANGE: Phi range to produce moments for (default 0-360)
;	THRANGE: Theta range to produce moments for (default -50 - 50)
;	ERANGE: Energy range to produce moments for (default 0-30000)
;	MAGT3: Produce temperature in magnetic field coordinates (you need to have run 'mvn_swia_add_magf' first)
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2017-07-13 06:50:10 -0700 (Thu, 13 Jul 2017) $
; $LastChangedRevision: 23595 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_part_moments.pro $
;
;-

pro mvn_swia_part_moments, type = type, phrange = phrange, thrange =thrange, erange = erange,verbose = verbose, magt3 = magt3

compile_opt idl2

common mvn_swia_data

if not keyword_set(type) then type = ['ca','cs','fa','fs','s']
if not keyword_set(phrange) then phrange = [0,360]
if not keyword_set(thrange) then thrange = [-50,50]
if not keyword_set(erange) then erange = [0,30000]


w = where(strupcase(type) eq 'FS',nw)

if nw gt 0 and n_elements(swifs) gt 1 then begin
	ctime = swifs.time_unix + 2.0
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)
		velocities = fltarr(nt,3)
		pressures = fltarr(nt,6)
		temperatures = fltarr(nt,4)
		heatfluxes = fltarr(nt,3)
		if keyword_set(magt3) then t3ds = fltarr(nt,4)
		if keyword_set(magt3) then p3ds = fltarr(nt,6)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3df(index = i, start = start)
			
			dat = conv_units(dat,'eflux')

			excl = where(dat.phi lt phrange[0] or dat.phi gt phrange[1] or dat.theta lt thrange[0] or dat.theta gt thrange[1] or dat.energy lt erange[0] or dat.energy gt erange[1],nexcl)
			if nexcl gt 0 then dat.data[excl] = 0
			if keyword_set(verbose) then print,'Excluding ',nexcl

			energies[i,*] = total(dat.energy*dat.domega,2)/total(dat.domega,2)
			efluxes[i,*] = total(dat.data*dat.domega,2)/total(dat.domega,2)

			densities[i] = n_3d(dat)
			velocities[i,*] = v_3d(dat)
			pressures[i,*] = p_3d(dat)
			temperatures[i,*] = t_3d(dat)
			heatfluxes[i,*] = je_3d(dat)
			if keyword_set(magt3) then t3ds[i,*] = t_3d_new(dat)
			if keyword_set(magt3) then p3ds[i,*] = p_3d_new(dat)
		endfor

		store_data,'mvn_swifs_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e5,1e9], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swifs_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

		store_data,'mvn_swifs_velocity',data = {x:ctime,y:velocities,v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swifs_pressure',data = {x:ctime,y:pressures, v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swifs_temperature', data = {x:ctime,y:temperatures, v:[0,1,2,3], labels: ['Tx','Ty','Tz','Tmag'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

		store_data,'mvn_swifs_heatflux', data = {x:ctime,y:heatfluxes, v:[0,1,2], labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}

		if keyword_set(magt3) then store_data,'mvn_swifs_magt3',data = {x:ctime,y:t3ds,v:[0,1,2,3], labels: ['Tperp1','Tperp2','Tpar','Tmag'],labflag:1,ytitle: 'SWIA!cTemperature!c[eV]'}

		if keyword_set(magt3) then store_data,'mvn_swifs_magp3',data = {x:ctime,y:p3ds,v:[0,1,2,3,4,5], labels: ['Pperp1','Pperp2','Ppar','Pod1','Pod2','Pod3'],labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}


	endif
endif

w = where(strupcase(type) eq 'FA',nw)

if nw gt 0 and n_elements(swifa) gt 1 then begin
	ctime = swifa.time_unix + 2.0
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)
		velocities = fltarr(nt,3)
		pressures = fltarr(nt,6)
		temperatures = fltarr(nt,4)
		heatfluxes = fltarr(nt,3)
		if keyword_set(magt3) then t3ds = fltarr(nt,4)
		if keyword_set(magt3) then p3ds = fltarr(nt,6)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0

			dat = mvn_swia_get_3df(index = i,/archive, start = start)
			
			dat = conv_units(dat,'eflux')
			excl = where(dat.phi lt phrange[0] or dat.phi gt phrange[1] or dat.theta lt thrange[0] or dat.theta gt thrange[1] or dat.energy lt erange[0] or dat.energy gt erange[1],nexcl)
			if nexcl gt 0 then dat.data[excl] = 0
			if keyword_set(verbose) then print,'Excluding ',nexcl

			energies[i,*] = total(dat.energy*dat.domega,2)/total(dat.domega,2)
			efluxes[i,*] = total(dat.data*dat.domega,2)/total(dat.domega,2)

			densities[i] = n_3d(dat)
			velocities[i,*] = v_3d(dat)
			pressures[i,*] = p_3d(dat)
			temperatures[i,*] = t_3d(dat)
			heatfluxes[i,*] = je_3d(dat)
			if keyword_set(magt3) then t3ds[i,*] = t_3d_new(dat)
			if keyword_set(magt3) then p3ds[i,*] = p_3d_new(dat)
		endfor

		store_data,'mvn_swifa_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e5,1e9], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swifa_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

		store_data,'mvn_swifa_velocity',data = {x:ctime,y:velocities,v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swifa_pressure',data = {x:ctime,y:pressures, v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swifa_temperature', data = {x:ctime,y:temperatures, v:[0,1,2,3], labels: ['Tx','Ty','Tz','Tmag'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

		store_data,'mvn_swifa_heatflux', data = {x:ctime,y:heatfluxes, v:[0,1,2], labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}

		if keyword_set(magt3) then store_data,'mvn_swifa_magt3',data = {x:ctime,y:t3ds,v:[0,1,2,3], labels: ['Tperp1','Tperp2','Tpar','Tmag'],labflag:1,ytitle: 'SWIA!cTemperature!c[eV]'}

		if keyword_set(magt3) then store_data,'mvn_swifa_magp3',data = {x:ctime,y:p3ds,v:[0,1,2,3,4,5], labels: ['Pperp1','Pperp2','Ppar','Pod1','Pod2','Pod3'],labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}
	endif
endif


w = where(strupcase(type) eq 'CS',nw)

if nw gt 0 and n_elements(swics) gt 1 then begin
	ctime = swics.time_unix + 4.0*swics.num_accum/2
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)
		velocities = fltarr(nt,3)
		pressures = fltarr(nt,6)
		temperatures = fltarr(nt,4)
		heatfluxes = fltarr(nt,3)
		if keyword_set(magt3) then t3ds = fltarr(nt,4)
		if keyword_set(magt3) then p3ds = fltarr(nt,6)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3dc(index = i, start = start)
			
			dat = conv_units(dat,'eflux')

			excl = where(dat.phi lt phrange[0] or dat.phi gt phrange[1] or dat.theta lt thrange[0] or dat.theta gt thrange[1] or dat.energy lt erange[0] or dat.energy gt erange[1],nexcl)
			if nexcl gt 0 then dat.data[excl] = 0
			if keyword_set(verbose) then print,'Excluding ',nexcl

			energies[i,*] = total(dat.energy*dat.domega,2)/total(dat.domega,2)
			efluxes[i,*] = total(dat.data*dat.domega,2)/total(dat.domega,2)

			densities[i] = n_3d(dat)
			velocities[i,*] = v_3d(dat)
			pressures[i,*] = p_3d(dat)
			temperatures[i,*] = t_3d(dat)
			heatfluxes[i,*] = je_3d(dat)
			if keyword_set(magt3) then t3ds[i,*] = t_3d_new(dat)
			if keyword_set(magt3) then p3ds[i,*] = p_3d_new(dat)
		endfor

		store_data,'mvn_swics_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e4,1e8], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swics_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

		store_data,'mvn_swics_velocity',data = {x:ctime,y:velocities,v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swics_pressure',data = {x:ctime,y:pressures, v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swics_temperature', data = {x:ctime,y:temperatures, v:[0,1,2,3], labels: ['Tx','Ty','Tz','Tmag'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

		store_data,'mvn_swics_heatflux', data = {x:ctime,y:heatfluxes, v:[0,1,2], labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}

		if keyword_set(magt3) then store_data,'mvn_swics_magt3',data = {x:ctime,y:t3ds,v:[0,1,2,3], labels: ['Tperp1','Tperp2','Tpar','Tmag'],labflag:1,ytitle: 'SWIA!cTemperature!c[eV]'}

		if keyword_set(magt3) then store_data,'mvn_swics_magp3',data = {x:ctime,y:p3ds,v:[0,1,2,3,4,5], labels: ['Pperp1','Pperp2','Ppar','Pod1','Pod2','Pod3'],labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}
	endif
endif

w = where(strupcase(type) eq 'CA',nw)

if nw gt 0 and n_elements(swica) gt 1 then begin
	ctime = swica.time_unix + 4.0*swica.num_accum/2
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)
		velocities = fltarr(nt,3)
		pressures = fltarr(nt,6)
		temperatures = fltarr(nt,4)
		heatfluxes = fltarr(nt,3)
		if keyword_set(magt3) then t3ds = fltarr(nt,4)
		if keyword_set(magt3) then p3ds = fltarr(nt,6)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3dc(index = i,/archive, start = start)
			
			dat = conv_units(dat,'eflux')

			excl = where(dat.phi lt phrange[0] or dat.phi gt phrange[1] or dat.theta lt thrange[0] or dat.theta gt thrange[1] or dat.energy lt erange[0] or dat.energy gt erange[1],nexcl)
			if nexcl gt 0 then dat.data[excl] = 0
			if keyword_set(verbose) then print,'Excluding ',nexcl

			energies[i,*] = total(dat.energy*dat.domega,2)/total(dat.domega,2)
			efluxes[i,*] = total(dat.data*dat.domega,2)/total(dat.domega,2)

			densities[i] = n_3d(dat)
			velocities[i,*] = v_3d(dat)
			pressures[i,*] = p_3d(dat)
			temperatures[i,*] = t_3d(dat)
			heatfluxes[i,*] = je_3d(dat)
			if keyword_set(magt3) then t3ds[i,*] = t_3d_new(dat)
			if keyword_set(magt3) then p3ds[i,*] = p_3d_new(dat)
		endfor

		store_data,'mvn_swica_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e4,1e8], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swica_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

		store_data,'mvn_swica_velocity',data = {x:ctime,y:velocities,v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swica_pressure',data = {x:ctime,y:pressures, v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swica_temperature', data = {x:ctime,y:temperatures, v:[0,1,2,3], labels: ['Tx','Ty','Tz','Tmag'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

		store_data,'mvn_swica_heatflux', data = {x:ctime,y:heatfluxes, v:[0,1,2], labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}

		if keyword_set(magt3) then store_data,'mvn_swica_magt3',data = {x:ctime,y:t3ds,v:[0,1,2,3], labels: ['Tperp1','Tperp2','Tpar','Tmag'],labflag:1,ytitle: 'SWIA!cTemperature!c[eV]'}

		if keyword_set(magt3) then store_data,'mvn_swica_magp3',data = {x:ctime,y:p3ds,v:[0,1,2,3,4,5], labels: ['Pperp1','Pperp2','Ppar','Pod1','Pod2','Pod3'],labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}
	endif
endif



w = where(strupcase(type) eq 'S',nw)

; Note that the moments from the spectra are not great with the attenuator in if the 
; count rate is not relatively uniform in phi. The convolution of non-uniform geometric
; factor and non-uniform count rate can't really be captured in the spectra. I put in an
; correction with the assumption that if the attenuator is in, this implies we're in the
; solar wind and all the counts are in the attenuated direction, which should be pretty 
; good for most realistic cases.  

if nw gt 0 and n_elements(swis) gt 1 then begin
	ctime = swis.time_unix + 4.0*swis.num_accum/2
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3ds(index = i, start = start)
			
			dat = conv_units(dat,'eflux')
			excl = where(dat.energy lt erange[0] or dat.energy gt erange[1],nexcl)
			if nexcl gt 0 then dat.data[excl] = 0
			if keyword_set(verbose) then print,'Excluding ',nexcl

			energies[i,*] = dat.energy
			efluxes[i,*] = dat.data

			densities[i] = n_3d_new(dat)
		endfor

		store_data,'mvn_swis_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e4,1e8], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swis_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

	endif
endif

end