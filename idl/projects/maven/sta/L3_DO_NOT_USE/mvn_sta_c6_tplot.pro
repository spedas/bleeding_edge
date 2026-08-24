;+
;PROCEDURE:	mvn_sta_c6_tplot
;PURPOSE:	
;	Creates energy-time spectrograms for tplot from the c6 STATIC common blocks with limited mass ranges
;INPUT:		
;
;KEYWORDS:
;					allows new dead time or background subtraction routines to be run with recalculations of eflux 
;
;CREATED BY:	J. McFadden	2016/08/23
;VERSION:	1
;LAST MODIFICATION:  2016/08/23
;MOD HISTORY:
;
;
;-
pro mvn_sta_c6_tplot

cols=get_colors()

;declare all the common block arrays

	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
		npts = n_elements(mvn_c6_dat.time)
		mode = mvn_c6_dat.mode
		rate = mvn_c6_dat.rate
		iswp = mvn_c6_dat.swp_ind
		ieff = mvn_c6_dat.eff_ind
		iatt = mvn_c6_dat.att_ind
		mlut = mvn_c6_dat.mlut_ind
		twt  = mvn_c6_dat.twt_arr[mlut,*,*]
		nenergy = mvn_c6_dat.nenergy
		nmass = mvn_c6_dat.nmass
		eprom_ver = mvn_c6_dat.eprom_ver
		scpot = mvn_c6_dat.sc_pot
		qf = (mvn_c6_dat.quality_flag and 128)/128 or (mvn_c6_dat.quality_flag and 64)/64

		time = (mvn_c6_dat.time + mvn_c6_dat.end_time)/2.
		data = mvn_c6_dat.data
		energy = reform(mvn_c6_dat.energy[iswp,*,0])
		mass = total(mvn_c6_dat.mass_arr[iswp,*,*],2)/nenergy
		str_element,mvn_c6_dat,'eflux',eflux,success=success

		cnt_low_nrg=fltarr(npts)
		for i=0l,npts-1 do begin
			ind = where(energy[i,*] le 10.,count)
			if count ge 1 then cnt_low_nrg[i] = total(data[i,ind,*])
		endfor

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_c6_dat.bkg
			dead = mvn_c6_dat.dead
			gf = reform(mvn_c6_dat.gf[iswp,*,0]*((iatt eq 0)#replicate(1.,nenergy)) +$
		            mvn_c6_dat.gf[iswp,*,1]*((iatt eq 1)#replicate(1.,nenergy)) +$
		            mvn_c6_dat.gf[iswp,*,2]*((iatt eq 2)#replicate(1.,nenergy)) +$
		            mvn_c6_dat.gf[iswp,*,3]*((iatt eq 3)#replicate(1.,nenergy)), npts*nenergy)#replicate(1.,nmass)
			gf = mvn_c6_dat.geom_factor*reform(gf,npts,nenergy,nmass)
			eff = mvn_c6_dat.eff[ieff,*,*]
			dt = float(mvn_c6_dat.integ_t#replicate(1.,nenergy*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/(eflux>.01))) gt 0. then print,'Error in CDF c6 eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*]=0.
			if count gt 0 then eflux[ind,*,*]=0.

		if keyword_set(test) then begin
			store_data,'mvn_sta_c6_gf30_att',data={x:time,y:reform(mvn_c6_dat.gf[iswp,30,*])}
				ylim,'mvn_sta_c6_gf30_att',.01,20,1
				options,'mvn_sta_c6_gf30_att',colors=[cols.blue,cols.green,cols.red,cols.black]
			store_data,'mvn_sta_c6_gf30',data={x:time,y:reform(gf[*,30,1])/mvn_c6_dat.geom_factor}
				ylim,'mvn_sta_c6_gf30',.01,20,1
			store_data,'mvn_sta_c6_iswp',data={x:time,y:iswp}
			store_data,'mvn_sta_c6_iatt',data={x:time,y:[[iatt eq 0],[iatt eq 1],[iatt eq 2],[iatt eq 3]]}
				options,'mvn_sta_c6_iatt',colors=[cols.blue,cols.green,cols.red,cols.black]
				ylim,'mvn_sta_c6_iatt',-1,2,0
		endif


		store_data,'mvn_sta_c6_P1D_E_m01',data={x:time,y:total(data[*,*,0:7],3),v:energy}
		store_data,'mvn_sta_c6_P1D_E_m02',data={x:time,y:total(data[*,*,9:12],3),v:energy}
		store_data,'mvn_sta_c6_P1D_E_m03',data={x:time,y:total(data[*,*,14:17],3),v:energy}
		store_data,'mvn_sta_c6_P1D_E_m04',data={x:time,y:total(data[*,*,17:20],3),v:energy}
		store_data,'mvn_sta_c6_P1D_E_m12',data={x:time,y:total(data[*,*,29:31],3),v:energy}
		store_data,'mvn_sta_c6_P1D_E_m16',data={x:time,y:total(data[*,*,33:38],3),v:energy}
		store_data,'mvn_sta_c6_P1D_E_m32',data={x:time,y:total(data[*,*,41:52],3),v:energy}

		store_data,'mvn_sta_c6_E_m01',data={x:time,y:total(eflux[*,*,0:7],3),v:energy}
		store_data,'mvn_sta_c6_E_m02',data={x:time,y:total(eflux[*,*,9:12],3),v:energy}
		store_data,'mvn_sta_c6_E_m03',data={x:time,y:total(eflux[*,*,14:16],3),v:energy}
		store_data,'mvn_sta_c6_E_m04',data={x:time,y:total(eflux[*,*,18:20],3),v:energy}
		store_data,'mvn_sta_c6_E_m12',data={x:time,y:total(eflux[*,*,29:31],3),v:energy}
		store_data,'mvn_sta_c6_E_m16',data={x:time,y:total(eflux[*,*,33:38],3),v:energy}
		store_data,'mvn_sta_c6_E_m32',data={x:time,y:total(eflux[*,*,41:52],3),v:energy}


			ylim,'mvn_sta_c6_P1D_E_m*',.1,100.,1
			ylim,'mvn_sta_c6_E_m*',.1,100.,1

			zlim,'mvn_sta_c6_P1D_E_m*',1,1.e4,1
			zlim,'mvn_sta_c6_E_m*',1.e3,1.e9,1

			datagap=7.
			options,'mvn_sta_c6_P1D_E_m*',datagap=datagap
			options,'mvn_sta_c6_E_m*',datagap=datagap

			options,'mvn_sta_c6_P1D_E_m*','spec',1
			options,'mvn_sta_c6_E_m*','spec',1

			options,'mvn_sta_c6_*E_m01',ytitle='sta c6!Cm=1!C!CEnergy!CeV'
			options,'mvn_sta_c6_*E_m02',ytitle='sta c6!Cm=2!C!CEnergy!CeV'
			options,'mvn_sta_c6_*E_m03',ytitle='sta c6!Cm=3!C!CEnergy!CeV'
			options,'mvn_sta_c6_*E_m04',ytitle='sta c6!Cm=4!C!CEnergy!CeV'
			options,'mvn_sta_c6_*E_m12',ytitle='sta c6!Cm=12!C!CEnergy!CeV'
			options,'mvn_sta_c6_*E_m16',ytitle='sta c6!Cm=16!C!CEnergy!CeV'
			options,'mvn_sta_c6_*E_m32',ytitle='sta c6!Cm=32!C!CEnergy!CeV'

			options,'mvn_sta_c6_P1D_E_m*',ztitle='counts'
			options,'mvn_sta_c6_E_m*',ztitle='eflux'

			options,'mvn_sta_c6_P1D_E_m*',no_interp=1
			options,'mvn_sta_c6_E_m*',no_interp=1

		store_data,'mvn_sta_c6_P1D_E_m01_pot',data=['mvn_sta_c6_E_m01','mvn_sta_c6_neg_scpot']
			ylim,'mvn_sta_c6_P1D_E_m01_pot',.1,30.,1

end