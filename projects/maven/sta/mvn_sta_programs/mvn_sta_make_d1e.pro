;+
;PROCEDURE:	mvn_sta_make_d1e
;PURPOSE:	
;	Makes common block structure mvn_d1e (64E-64S-8M) from d1 (32E-64S-8M) and c0 (64E-1S-2M) data products
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  16/04/04
;MOD HISTORY:
;
;NOTES:	  
;	The common block can be accessed via mvn_sta_get_d1e.pro to return a single data structure
;	Data structures can be operated on by programs like n_4d.pro, v_4d.pro
;	Or used in conjunction with iterative programs such as get_4dt.pro and get_en_spec4dt.pro
;-
pro mvn_sta_make_d1e

common mvn_d1,get_ind_d1,dat_d1
common mvn_c0,get_ind_c0,dat_c0

	mars_radius = 3386.
	ind_d1 = where(total(dat_d1.pos_sc_mso^2,2) lt (mars_radius +600.)^2,npts_d1)
	npts_d1 = npts_d1*1l

	print,'number of points in d1e',npts_d1,' out of ',n_elements(dat_d1.time)
	wait,1

	npts_c0 = n_elements(dat_c0.time)*1l

	ind_c0 = round(interp(lindgen(npts_c0),dat_c0.time,dat_d1.time[ind_d1])+.01) < (npts_c0-1)

	nenergy = 64
	nbins	= 64
	nmass	= 8
	natt	= 4

	swp_ind = dat_d1.swp_ind[ind_d1]
	eff_ind = dat_d1.eff_ind[ind_d1]
	att_ind = dat_d1.att_ind[ind_d1]

		nswp = dimen1(dat_d1.theta)
		neff = dimen1(dat_d1.eff)
		ntof = dimen1(dat_d1.tof_arr)
		nd0 = nswp*dat_d1.nenergy*nbins*nmass
		nd1 = neff*dat_d1.nenergy*nbins*nmass
		nd2 = ntof*dat_d1.nenergy*nbins*nmass
		nd3 = nswp*dat_d1.nenergy*nbins*natt


		valid = dat_d1.valid[ind_d1] and dat_c0.valid[ind_c0]
		quality_flag = dat_d1.quality_flag[ind_d1] and dat_c0.quality_flag[ind_c0]

		integ_t = dat_d1.integ_t[ind_d1]/2.

		theta = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.theta,[1,0,2,3]),nd0),64,nswp,64,8),[1,0,2,3])
		dtheta = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.dtheta,[1,0,2,3]),nd0),64,nswp,64,8),[1,0,2,3])

		phi = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.phi,[1,0,2,3]),nd0),64,nswp,64,8),[1,0,2,3])
		dphi = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.dphi,[1,0,2,3]),nd0),64,nswp,64,8),[1,0,2,3])
		domega = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.domega,[1,0,2,3]),nd0),64,nswp,64,8),[1,0,2,3])

		gf = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.gf,[1,0,2,3]),nd3),64,nswp,64,4),[1,0,2,3])
		eff = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.eff,[1,0,2,3]),nd1),64,neff,64,8),[1,0,2,3])

		mass_arr = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.mass_arr,[1,0,2,3]),nd0),64,nswp,64,8),[1,0,2,3])
		tof_arr = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.tof_arr,[1,0,2,3]),nd2),64,ntof,64,8),[1,0,2,3])
		twt_arr = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.twt_arr,[1,0,2,3]),nd2),64,ntof,64,8),[1,0,2,3])

		dead = transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.dead[ind_d1,*,*,*],[1,0,2,3]),npts_d1*32*64*8),64,npts_d1,64,8),[1,0,2,3])			; this is not the most accurate

		energy = reform(reform(dat_c0.energy[*,*,0],nswp*nenergy)#replicate(1.,512),nswp,64,64,8)
		denergy = reform(reform(dat_c0.denergy[*,*,0],nswp*nenergy)#replicate(1.,512),nswp,64,64,8)

		bkg = fltarr(npts_d1,64,64,8)
		cnts = fltarr(npts_d1,64,64,8)

;	mass bins 0-3

		nor_cnts0 = reform(reform(reform(dat_c0.data[ind_c0,*,0])/(.00001+reform(transpose(reform(reform(total(reform(reform(dat_c0.data[ind_c0,*,0]),npts_d1,2,32),2)$
			,npts_d1*32)#replicate(1.,2),npts_d1,32,2),[0,2,1]),npts_d1,64)),npts_d1*64)#replicate(1.,nbins*nmass),npts_d1,nenergy,nbins,nmass)
		nor_cnts0[*,*,*,4:7] = 0.
		nor_cnts1 = reform(reform(reform(dat_c0.data[ind_c0,*,1])/(.00001+reform(transpose(reform(reform(total(reform(reform(dat_c0.data[ind_c0,*,1]),npts_d1,2,32),2)$
			,npts_d1*32)#replicate(1.,2),npts_d1,32,2),[0,2,1]),npts_d1,64)),npts_d1*64)#replicate(1.,nbins*nmass),npts_d1,nenergy,nbins,nmass)
		nor_cnts1[*,*,*,0:3] = 0.
		cnts = (nor_cnts0 + nor_cnts1) * transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.data[ind_d1,*,*,*],[1,0,2,3]),npts_d1*32*nbins*nmass),nenergy,npts_d1,nbins,nmass),[1,0,2,3])

		nor_bkg0 = reform(reform(reform(dat_c0.bkg[ind_c0,*,0])/(.00001+reform(transpose(reform(reform(total(reform(reform(dat_c0.bkg[ind_c0,*,0]),npts_d1,2,32),2)$
			,npts_d1*32)#replicate(1.,2),npts_d1,32,2),[0,2,1]),npts_d1,64)),npts_d1*64)#replicate(1.,nbins*nmass),npts_d1,nenergy,nbins,nmass)
		nor_bkg0[*,*,*,4:7] = 0.
		nor_bkg1 = reform(reform(reform(dat_c0.bkg[ind_c0,*,1])/(.00001+reform(transpose(reform(reform(total(reform(reform(dat_c0.bkg[ind_c0,*,1]),npts_d1,2,32),2)$
			,npts_d1*32)#replicate(1.,2),npts_d1,32,2),[0,2,1]),npts_d1,64)),npts_d1*64)#replicate(1.,nbins*nmass),npts_d1,nenergy,nbins,nmass)
		nor_bkg1[*,*,*,0:3] = 0.
		bkg = (nor_bkg0 + nor_bkg1) * transpose(reform(replicate(1.,2)#reform(transpose(dat_d1.bkg[ind_d1,*,*,*],[1,0,2,3]),npts_d1*dat_d1.nenergy*nbins*nmass),nenergy,npts_d1,nbins,nmass),[1,0,2,3])

		gf1 = 	reform(gf[swp_ind,*,*,0])*((att_ind eq 0)#replicate(1.,nenergy*nbins)) +$
			reform(gf[swp_ind,*,*,1])*((att_ind eq 1)#replicate(1.,nenergy*nbins)) +$
			reform(gf[swp_ind,*,*,2])*((att_ind eq 2)#replicate(1.,nenergy*nbins)) +$
			reform(gf[swp_ind,*,*,3])*((att_ind eq 3)#replicate(1.,nenergy*nbins))

		gf2 = dat_d1.geom_factor*reform(reform(gf1,npts_d1*nenergy*nbins)#replicate(1.,nmass),npts_d1,nenergy,nbins,nmass)
		eff2 = eff[eff_ind,*,*,*]
		dt = float(integ_t#replicate(1.,1l*nenergy*nbins*nmass))

		eflux = ((cnts-bkg)*dead/(gf2*eff2*dt)) > 0.

dat = 		{project_name:		dat_d1.project_name,			$
		spacecraft:		dat_d1.spacecraft, 			$
		data_name:		'd1e 64e4d16a8m', 			$
		apid:			'd1 and c0',				$
		units_name: 		'counts', 				$
		units_procedure: 	dat_d1.units_procedure, 		$

		valid: 			valid, 					$
		quality_flag: 		quality_flag, 				$
		time: 			dat_d1.time[ind_d1], 			$
		met: 			dat_d1.met[ind_d1], 			$
		end_time: 		dat_d1.end_time[ind_d1], 		$
		delta_t: 		dat_d1.delta_t[ind_d1],			$
		integ_t: 		integ_t,				$
		eprom_ver:		dat_d1.eprom_ver[ind_d1],		$
		header:			dat_d1.header[ind_d1],			$
		mode:			dat_d1.mode[ind_d1],			$
		rate:			dat_d1.rate[ind_d1],			$
		swp_ind:		dat_d1.swp_ind[ind_d1],			$
		mlut_ind:		dat_d1.mlut_ind[ind_d1],		$
		eff_ind:		dat_d1.eff_ind[ind_d1],			$
		att_ind:		dat_d1.att_ind[ind_d1],			$

		nenergy: 		64, 					$
		energy: 		energy, 				$
		denergy: 		denergy, 				$

		nbins: 			dat_d1.nbins,	 			$
		bins: 			dat_d1.bins, 				$
		ndef:			dat_d1.ndef,				$
		nanode:			dat_d1.nanode,				$

		theta: 			theta,  				$
		dtheta: 		dtheta,  				$
		phi: 			phi,  					$
		dphi: 			dphi,					$
		domega: 		domega,  				$

		gf: 			gf,					$
		eff: 			eff,					$

		geom_factor: 		dat_d1.geom_factor, 			$
		dead1: 			dat_d1.dead1,				$
		dead2: 			dat_d1.dead2,				$
		dead3: 			dat_d1.dead3,				$

		nmass:			dat_d1.nmass,				$
		mass: 			dat_d1.mass, 				$
		mass_arr: 		mass_arr,				$
		tof_arr: 		tof_arr,				$
		twt_arr: 		twt_arr,				$

		charge: 		dat_d1.charge, 				$
		sc_pot: 		dat_d1.sc_pot[ind_d1], 			$
		magf:	 		dat_d1.magf[ind_d1,*], 			$
		quat_sc:	 	dat_d1.quat_sc[ind_d1,*], 		$
		quat_mso:	 	dat_d1.quat_mso[ind_d1,*], 		$
		bins_sc:		dat_d1.bins_sc[ind_d1,*],		$
		pos_sc_mso:		dat_d1.pos_sc_mso[ind_d1,*],		$

		bkg:	 		bkg,					$
		dead:	 		dead,					$
		data:	 		cnts,					$

		eflux: 			eflux}


common mvn_d1e,get_ind,dat_d1e	& dat_d1e=dat & get_ind=0

end
