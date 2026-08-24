;+
;PROCEDURE:	mvn_sta_make_c6_avg
;PURPOSE:	
;	Makes common block structure mvn_c6_avg 
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  17/05/30
;MOD HISTORY:
;
;NOTES:	  
;-
pro mvn_sta_make_c6_avg,avg=avg,verbose=verbose

common mvn_c6,get_ind_c6,dat_c6

	if not keyword_set(avg) then avg=5
	off = (avg-1)/2
	mode = dat_c6.mode
	iswp = dat_c6.swp_ind
	iatt = dat_c6.att_ind
	ieff = dat_c6.eff_ind
	time = dat_c6.time
	etim = dat_c6.end_time
	
	npts= n_elements(mode)
	
	valid_sum = dat_c6.valid

	for ii=-off,off do begin
		valid_sum = (valid_sum and shift(dat_c6.valid,ii))
	endfor
	if off ne 0 then valid_sum[0:off-1]=0
	if off ne 0 then valid_sum[npts-off:npts-1]=0

	vind = where( 	(abs(time-shift(time,off)-4.*off) gt 1.) 	$
		or 	(abs(etim-shift(etim,-off)+4.*off) gt 1.)	$
		or	(mode ne shift(mode,off)) 			$
		or 	(mode ne shift(mode,-off))			$
		or	(iswp ne shift(iswp,off)) 			$
		or 	(iswp ne shift(iswp,-off))			$
		or	(iatt ne shift(iatt,off)) 			$
		or 	(iatt ne shift(iatt,-off))			$
		,count) 

if count gt 0 then valid_sum[vind]=0

if keyword_set(verbose) then print,minmax(valid_sum),total(valid_sum),npts

; average the mag field
	magf  = dat_c6.magf
	magf_sum = magf 
	magf_sum[*]=0
	for ii=-off,off do begin
		magf_sum = magf_sum + shift(magf,ii,0)
	endfor
	magf_sum = magf_sum/avg

; average the sc_pot
	pot  = dat_c6.sc_pot
	pot_sum = pot 
	pot_sum[*]=0
	for ii=-off,off do begin
		pot_sum = pot_sum + shift(pot,ii)
	endfor
	pot_sum = pot_sum/avg

; sum the bkg
	bkg  = dat_c6.bkg
	bkg_sum = bkg 
	bkg_sum[*]=0
	for ii=-off,off do begin
		bkg_sum = bkg_sum + shift(bkg,ii,0,0)
	endfor

; sum the cnts
	cnts  = dat_c6.data
	cnts_sum = cnts 
	cnts_sum[*]=0
	for ii=-off,off do begin
		cnts_sum = cnts_sum + shift(cnts,ii,0,0)
	endfor

; average the eflux

	str_element,dat_c6,'eflux',eflx,success=success
	if not success then begin						; this is needed when loading l0 data
		npts = n_elements(dat_c6.time)
		iswp = dat_c6.swp_ind
		ieff = dat_c6.eff_ind
		iatt = dat_c6.att_ind
		mlut = dat_c6.mlut_ind
		twt  = dat_c6.twt_arr[mlut,*,*]
		nenergy = dat_c6.nenergy
		nmass = dat_c6.nmass
			data = dat_c6.data
			bkg = dat_c6.bkg
			dead = dat_c6.dead
			gf = reform(dat_c6.gf[iswp,*,0]*((iatt eq 0)#replicate(1.,nenergy)) +$
		            dat_c6.gf[iswp,*,1]*((iatt eq 1)#replicate(1.,nenergy)) +$
		            dat_c6.gf[iswp,*,2]*((iatt eq 2)#replicate(1.,nenergy)) +$
		            dat_c6.gf[iswp,*,3]*((iatt eq 3)#replicate(1.,nenergy)), npts*nenergy)#replicate(1.,nmass)
			gf = dat_c6.geom_factor*reform(gf,npts,nenergy,nmass)
			eff = dat_c6.eff[ieff,*,*]
			dt = float(dat_c6.integ_t#replicate(1.,nenergy*nmass))
			eflx = (data-bkg)*dead/(gf*eff*dt)
	endif 
	eflx_sum = eflx 
	eflx_sum[*]=0
	for ii=-off,off do begin
		eflx_sum = eflx_sum + shift(eflx,ii,0,0)
	endfor
	eflx_sum = eflx_sum/avg

; calculate the dead-time correction
	gf = fltarr(npts,32,64)
	for ii=0,npts-1 do gf[ii,*,*] = reform(dat_c6.gf[iswp[ii],*,iatt[ii]])#replicate(1.,64)
	eff = dat_c6.eff[ieff,*,*]
	dead   = 1. > eff*gf*dat_c6.geom_factor*avg*reform((dat_c6.integ_t#replicate(1.,32*64)),npts,32,64)*eflx_sum/(cnts_sum+.00001)
	dead2  = 1. > eff*gf*dat_c6.geom_factor*    reform((dat_c6.integ_t#replicate(1.,32*64)),npts,32,64)*eflx/(cnts+.00001)

ind = where(valid_sum eq 0,count)

if count gt 0 then begin
	dead[ind,*,*] = 1.
	eflx_sum[ind,*,*] = 0.
	cnts_sum[ind,*,*] = 0.
	bkg_sum[ind,*,*] = 0.
endif

; the following allows this to work with l0 data w/0 'met' elements
	str_element,dat_c6,'met',met,success=success & if not success then met=0

if keyword_set(verbose) then print,minmax(dead),minmax(dead2)
if keyword_set(verbose) then print,minmax(avg*eflx_sum/(cnts_sum+.00001)),minmax(eflx/(cnts+.00001))
if keyword_set(verbose) then print,max(eflx_sum),max(cnts),max(eflx),max(dat_c6.dead)


dat = 		{project_name:		dat_c6.project_name,			$
		spacecraft:		dat_c6.spacecraft, 			$
		data_name:		'c6 avg 32e64m', 			$
		apid:			'c6 avg',				$
		units_name: 		'counts', 				$
		units_procedure: 	dat_c6.units_procedure, 		$

		valid: 			valid_sum, 					$
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
		magf:	 		magf_sum, 				$
		quat_sc:	 	dat_c6.quat_sc, 			$
		quat_mso:	 	dat_c6.quat_mso, 			$
		bins_sc:		dat_c6.bins_sc,				$
		pos_sc_mso:		dat_c6.pos_sc_mso,			$

		bkg:	 		bkg_sum,				$
		dead:	 		dead,					$
		data:	 		cnts_sum,				$

		eflux: 			eflx_sum}

;help,dat,/st

common mvn_c6_avg,get_ind,dat_c6_avg	& dat_c6_avg=dat & get_ind=0

end
