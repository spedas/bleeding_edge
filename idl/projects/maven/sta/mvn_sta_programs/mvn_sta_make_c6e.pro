;+
;PROCEDURE:	mvn_sta_make_c6e
;PURPOSE:	
;	Makes common block structure mvn_c6e (64E-64M) from c6 (32E-64M) and c0 (64E-2M) data products
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  16/04/04
;MOD HISTORY:
;
;NOTES:	  
;	The common block can be accessed via mvn_sta_get_c6e.pro to return a single data structure
;	Data structures can be operated on by programs like n_4d.pro, v_4d.pro
;	Or used in conjunction with iterative programs such as get_4dt.pro and get_en_spec4dt.pro
;-
pro mvn_sta_make_c6e,lite=lite

common mvn_c6,get_ind_c6,dat_c6
common mvn_c0,get_ind_c0,dat_c0

	mars_radius = 3386.
	ind_c6 = where(total(dat_c6.pos_sc_mso^2,2) lt (mars_radius +600.)^2,npts_c6)
	npts_c6 = npts_c6*1l

	print,'number of points in c6e',npts_c6,' out of ',n_elements(dat_c6.time)
	wait,1

	npts_c0 = n_elements(dat_c0.time)*1l
print,npts_c6,npts_c0

	ind_c0 = round(interp(lindgen(npts_c0),dat_c0.time,dat_c6.time[ind_c6])+.01) < (npts_c0-1)


	nenergy = 64
	nbins   = 1
	nmass	= 64
	natt	= 4

	swp_ind = dat_c6.swp_ind[ind_c6]
	eff_ind = dat_c6.eff_ind[ind_c6]
	att_ind = dat_c6.att_ind[ind_c6]

		nswp = dimen1(dat_c6.theta)
		neff = dimen1(dat_c6.eff)
		ntof = dimen1(dat_c6.tof_arr)
		nd0 = nswp*dat_c6.nenergy*nbins*nmass
		nd1 = neff*dat_c6.nenergy*nbins*nmass
		nd2 = ntof*dat_c6.nenergy*nbins*nmass
		nd3 = nswp*dat_c6.nenergy*nbins*natt


		valid = dat_c6.valid[ind_c6] and dat_c0.valid[ind_c0]
		quality_flag = dat_c6.quality_flag[ind_c6] and dat_c0.quality_flag[ind_c0]

		integ_t = dat_c6.integ_t[ind_c6]/2.

		theta = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.theta,[1,0,2]),nd0),64,nswp,64),[1,0,2])
		dtheta = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.dtheta,[1,0,2]),nd0),64,nswp,64),[1,0,2])

		phi = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.phi,[1,0,2]),nd0),64,nswp,64),[1,0,2])
		dphi = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.dphi,[1,0,2]),nd0),64,nswp,64),[1,0,2])
		domega = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.domega,[1,0,2]),nd0),64,nswp,64),[1,0,2])

		gf = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.gf,[1,0,2]),nd3),64,nswp,4),[1,0,2])
		eff = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.eff,[1,0,2]),nd1),64,neff,64),[1,0,2])

		mass_arr = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.mass_arr,[1,0,2]),nd0),64,nswp,64),[1,0,2])
		tof_arr = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.tof_arr,[1,0,2]),nd2),64,ntof,64),[1,0,2])
		twt_arr = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.twt_arr,[1,0,2]),nd2),64,ntof,64),[1,0,2])

		dead = transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.dead[ind_c6,*,*],[1,0,2]),npts_c6*32*64),64,npts_c6,64),[1,0,2])	; this is not the most accurate

		energy = reform(reform(dat_c0.energy[*,*,0],nswp*nenergy)#replicate(1.,64),nswp,64,64)
		denergy = reform(reform(dat_c0.denergy[*,*,0],nswp*nenergy)#replicate(1.,64),nswp,64,64)

		bkg = fltarr(npts_c6,64,64)
		cnts = fltarr(npts_c6,64,64)

;	mass bins 0-3

		nor_cnts0 = reform(reform(reform(dat_c0.data[ind_c0,*,0])/(.00001+reform(transpose(reform(reform(total(reform(reform(dat_c0.data[ind_c0,*,0]),npts_c6,2,32),2)$
			,npts_c6*32)#replicate(1.,2),npts_c6,32,2),[0,2,1]),npts_c6,64)),npts_c6*64)#replicate(1.,nmass),npts_c6,nenergy,nmass)
		nor_cnts0[*,*,32:63] = 0.
		nor_cnts1 = reform(reform(reform(dat_c0.data[ind_c0,*,1])/(.00001+reform(transpose(reform(reform(total(reform(reform(dat_c0.data[ind_c0,*,1]),npts_c6,2,32),2)$
			,npts_c6*32)#replicate(1.,2),npts_c6,32,2),[0,2,1]),npts_c6,64)),npts_c6*64)#replicate(1.,nmass),npts_c6,nenergy,nmass)
		nor_cnts1[*,*,0:31] = 0.

		cnts = (nor_cnts0 + nor_cnts1) * transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.data[ind_c6,*,*],[1,0,2]),npts_c6*32*nmass),nenergy,npts_c6,nmass),[1,0,2])


		nor_bkg0 = reform(reform(reform(dat_c0.bkg[ind_c0,*,0])/(.00001+reform(transpose(reform(reform(total(reform(reform(dat_c0.bkg[ind_c0,*,0]),npts_c6,2,32),2)$
			,npts_c6*32)#replicate(1.,2),npts_c6,32,2),[0,2,1]),npts_c6,64)),npts_c6*64)#replicate(1.,nmass),npts_c6,nenergy,nmass)
		nor_bkg0[*,*,32:63] = 0.
		nor_bkg1 = reform(reform(reform(dat_c0.bkg[ind_c0,*,1])/(.00001+reform(transpose(reform(reform(total(reform(reform(dat_c0.bkg[ind_c0,*,1]),npts_c6,2,32),2)$
			,npts_c6*32)#replicate(1.,2),npts_c6,32,2),[0,2,1]),npts_c6,64)),npts_c6*64)#replicate(1.,nmass),npts_c6,nenergy,nmass)
		nor_bkg1[*,*,0:31] = 0.

		bkg = (nor_bkg0 + nor_bkg1) * transpose(reform(replicate(1.,2)#reform(transpose(dat_c6.bkg[ind_c6,*,*],[1,0,2]),npts_c6*32*nmass),nenergy,npts_c6,nmass),[1,0,2])

	if keyword_set(lite) then begin
		eflux=0
	endif else begin
		gf1 = 	reform(gf[swp_ind,*,0])*((att_ind eq 0)#replicate(1.,nenergy)) +$
			reform(gf[swp_ind,*,1])*((att_ind eq 1)#replicate(1.,nenergy)) +$
			reform(gf[swp_ind,*,2])*((att_ind eq 2)#replicate(1.,nenergy)) +$
			reform(gf[swp_ind,*,3])*((att_ind eq 3)#replicate(1.,nenergy))

		gf2 = dat_c6.geom_factor*reform(reform(gf1,npts_c6*nenergy)#replicate(1.,nmass),npts_c6,nenergy,nmass)
		eff2 = eff[eff_ind,*,*]
		dt = float(integ_t#replicate(1.,1l*nenergy*nmass))

		eflux = ((cnts-bkg)*dead/(gf2*eff2*dt)) > 0.
	endelse

dat = 		{project_name:		dat_c6.project_name,			$
		spacecraft:		dat_c6.spacecraft, 			$
		data_name:		'c6e 64e64m', 			$
		apid:			'c6 and c0',				$
		units_name: 		'counts', 				$
		units_procedure: 	dat_c6.units_procedure, 		$

		valid: 			valid, 					$
		quality_flag: 		quality_flag, 				$
		time: 			dat_c6.time[ind_c6], 			$
		met: 			dat_c6.met[ind_c6], 			$
		end_time: 		dat_c6.end_time[ind_c6], 		$
		delta_t: 		dat_c6.delta_t[ind_c6],			$
		integ_t: 		integ_t,				$
		eprom_ver:		dat_c6.eprom_ver[ind_c6],		$
		header:			dat_c6.header[ind_c6],			$
		mode:			dat_c6.mode[ind_c6],			$
		rate:			dat_c6.rate[ind_c6],			$
		swp_ind:		dat_c6.swp_ind[ind_c6],			$
		mlut_ind:		dat_c6.mlut_ind[ind_c6],		$
		eff_ind:		dat_c6.eff_ind[ind_c6],			$
		att_ind:		dat_c6.att_ind[ind_c6],			$

		nenergy: 		64, 					$
		energy: 		energy, 				$
		denergy: 		denergy, 				$

		nbins: 			dat_c6.nbins,	 			$
		bins: 			dat_c6.bins, 				$
		ndef:			dat_c6.ndef,				$
		nanode:			dat_c6.nanode,				$

		theta: 			theta,  				$
		dtheta: 		dtheta,  				$
		phi: 			phi,  					$
		dphi: 			dphi,					$
		domega: 		domega,  				$

		gf: 			gf,					$
		eff: 			eff,					$

		geom_factor: 		dat_c6.geom_factor, 			$
		dead1: 			dat_c6.dead1,				$
		dead2: 			dat_c6.dead2,				$
		dead3: 			dat_c6.dead3,				$

		nmass:			dat_c6.nmass,				$
		mass: 			dat_c6.mass, 				$
		mass_arr: 		mass_arr,				$
		tof_arr: 		tof_arr,				$
		twt_arr: 		twt_arr,				$

		charge: 		dat_c6.charge, 				$
		sc_pot: 		dat_c6.sc_pot[ind_c6], 			$
		magf:	 		dat_c6.magf[ind_c6,*], 			$
		quat_sc:	 	dat_c6.quat_sc[ind_c6,*], 		$
		quat_mso:	 	dat_c6.quat_mso[ind_c6,*], 		$
		bins_sc:		dat_c6.bins_sc[ind_c6,*],		$
		pos_sc_mso:		dat_c6.pos_sc_mso[ind_c6,*],		$

		bkg:	 		bkg,					$
		dead:	 		dead,					$
		data:	 		cnts,					$

		eflux: 			eflux}


common mvn_c6e,get_ind,dat_c6e	& dat_c6e=dat & get_ind=0

end
