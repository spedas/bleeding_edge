;+
;PROCEDURE:	mvn_sta_make_c6_avg_v2
;PURPOSE:	
;	Makes common block structure mvn_c6_avg 
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  17/05/30
;MOD HISTORY:
;
;NOTES:	  this code assumes the dat_c6.eff is NOT mass dependent - as is currently coded.
;-
pro mvn_sta_make_c6_avg_v2,avg=avg,verbose=verbose

common mvn_c6,get_ind_c6,dat_c6

	if not keyword_set(avg) then avg=5
	off = (avg-1)/2
	navg = 2*off+1

	nenergy = dat_c6.nenergy
	nmass = dat_c6.nmass
	mode = dat_c6.mode
	iatt = dat_c6.att_ind
;	ieff = dat_c6.eff_ind			; for now this is not needed
	valid = dat_c6.valid
	time = dat_c6.time
	
	npts= n_elements(mode)
	xavg = intarr(npts,navg)

; xavg determines which elements can be averaged -- must be in time sequence and have same mode/iatt state
	for i=0,navg-1 do begin
		xavg[*,i]  = shift(valid,i-off) and (shift(mode,i-off) eq mode) and (shift(iatt,i-off) eq iatt) and (abs(shift(time,i-off)-time+(i-off)*4.) lt 1.) and valid 
;		xavg[*,i]  = shift(valid,i-off) and (shift(mode,i-off) eq mode) and (shift(iatt,i-off) eq iatt) and valid 
	endfor
	for i=0,off-1 do xavg[i,0:off-1-i]=0
	for i=0,off-1 do xavg[navg-1-i,navg-1-off-1+i:navg-1]=0
		
	cnts = dat_c6.data 
	eflx = dat_c6.eflux 
	bkg  = dat_c6.bkg
	dead = dat_c6.dead

	cnts_sum = cnts & cnts_sum[*] = 0.
	bkg_sum  = cnts_sum  
	eflx_sum = cnts_sum 
	dead_sum = cnts_sum 

	pot = dat_c6.sc_pot
	pot_sum = pot  & pot_sum[*]=0.
	mag = dat_c6.magf
	mag_sum = mag  & mag_sum[*]=0.

	for i=0,navg-1 do begin
		val = (reform(xavg[*,i])#replicate(1,nenergy*nmass))
		cnts_sum  = cnts_sum + shift(cnts,i-off,0,0)*val + cnts*(1-val)
		eflx_sum  = eflx_sum + shift(eflx,i-off,0,0)*val + eflx*(1-val)
		bkg_sum   =  bkg_sum + shift( bkg,i-off,0,0)*val +  bkg*(1-val)
		pot_sum   =  pot_sum + shift( pot,i-off)*val     +  pot*(1-val)
		mag_sum   =  mag_sum + shift( mag,i-off,0)*val   +  mag*(1-val)
		dead_sum  = dead_sum + shift(dead*cnts,i-off,0,0)*val + dead*cnts*(1-val)

	endfor
	
	eflx_sum = eflx_sum/navg
	 pot_sum =  pot_sum/navg
	 mag_sum =  mag_sum/navg

	dead_tmp = total(dead_sum,3)/(total(cnts_sum,3)+.0001)
	dead_sum = reform(reform(dead_tmp,npts*nenergy*1l)#replicate(1.,nmass),npts,nenergy,nmass) >1.

; the following allows this to work with l0 data w/0 'met' elements
	str_element,dat_c6,'met',met,success=success & if not success then met=0

if keyword_set(verbose) then print,minmax(dead)
if keyword_set(verbose) then print,minmax(dead_sum)
if keyword_set(verbose) then print,minmax(eflx_sum)
if keyword_set(verbose) then print,minmax(cnts_sum)
if keyword_set(verbose) then print,minmax(cnts)


dat = 		{project_name:		dat_c6.project_name,			$
		spacecraft:		dat_c6.spacecraft, 			$
		data_name:		'c6 avg 32e64m', 			$
		apid:			'c6 avg',				$
		units_name: 		'counts', 				$
		units_procedure: 	dat_c6.units_procedure, 		$

		valid: 			valid, 					$
		quality_flag: 		dat_c6.quality_flag, 			$
		time: 			dat_c6.time-off*4., 			$
		met: 			met, 					$
		end_time: 		dat_c6.end_time+off*4., 		$
		delta_t: 		dat_c6.delta_t*avg,			$
		integ_t: 		dat_c6.integ_t*avg,			$
		eprom_ver:		dat_c6.eprom_ver,			$
		header:			dat_c6.header,				$
		mode:			dat_c6.mode,				$
		rate:			dat_c6.rate,				$
		swp_ind:		dat_c6.swp_ind,				$
		mlut_ind:		dat_c6.mlut_ind,			$
		eff_ind:		dat_c6.eff_ind,				$
		att_ind:		dat_c6.att_ind,				$

		nenergy: 		dat_c6.nenergy, 			$
		energy: 		dat_c6.energy, 				$
		denergy: 		dat_c6.denergy, 			$

		nbins: 			dat_c6.nbins,	 			$
		bins: 			dat_c6.bins, 				$
		ndef:			dat_c6.ndef,				$
		nanode:			dat_c6.nanode,				$

		theta: 			dat_c6.theta,  				$
		dtheta: 		dat_c6.dtheta,  			$
		phi: 			dat_c6.phi,  				$
		dphi: 			dat_c6.dphi,				$
		domega: 		dat_c6.domega,  			$

		gf: 			dat_c6.gf,				$
		eff: 			dat_c6.eff,				$

		geom_factor: 		dat_c6.geom_factor, 			$
		dead1: 			dat_c6.dead1,				$
		dead2: 			dat_c6.dead2,				$
		dead3: 			dat_c6.dead3,				$

		nmass:			dat_c6.nmass,				$
		mass: 			dat_c6.mass, 				$
		mass_arr: 		dat_c6.mass_arr,			$
		tof_arr: 		dat_c6.tof_arr,				$
		twt_arr: 		dat_c6.twt_arr,				$

		charge: 		dat_c6.charge, 				$
		sc_pot: 		pot_sum, 				$
		magf:	 		mag_sum, 				$
		quat_sc:	 	dat_c6.quat_sc, 			$
		quat_mso:	 	dat_c6.quat_mso, 			$
		bins_sc:		dat_c6.bins_sc,				$
		pos_sc_mso:		dat_c6.pos_sc_mso,			$

		bkg:	 		bkg_sum,				$
		dead:	 		dead_sum,				$
		data:	 		cnts_sum,				$

		eflux: 			eflx_sum}

;help,dat,/st

common mvn_c6_avg,get_ind,dat_c6_avg	& dat_c6_avg=dat & get_ind=0

end
