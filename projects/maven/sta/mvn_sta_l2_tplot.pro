;+
;PROCEDURE:	mvn_sta_l2_tplot,all=all,units=units,apids=apids,test=test,gf_nor=gf_nor
;PURPOSE:	
;	Creates tplot data from the STATIC common blocks
;INPUT:		
;
;KEYWORDS:
;	all	0/1		if not set, deletes all currently stored STATIC tplot structures (mvn_sta* and mvn_STA*) before generating new structures
;					generally this is only used for code diagnostics
;	units	string		select the units for generated tplot structures - not working yet
;	apids	strarr		if set, selectes subset of apids to generate tplot structures - not working yet
;	test	0/1		if set, diagnostic tplot structures (APIDs: 2A,d6,d7,d8,d9,da) are made
;					generates "rate" tplot structures for all APIDs, 
;						default only generates c6 rate tplot structures
;	gf_nor	0/1		if set, keyword for testing - not working yet
;	dead_c0 flt		not used -- only for testing
;	scale	flt		not used -- only for develpment testing for crude background subtraction for 'mvn_sta_c0_H_E'
;	replace 0/1		if set, replaces eflux with values calculated as this routine is run
;					allows new dead time or background subtraction routines to be run with recalculations of eflux 
;'mvn_sta_c0_H_E'
;
;CREATED BY:	J. McFadden	2014/03/14
;VERSION:	1
;LAST MODIFICATION:  2014/09/08
;MOD HISTORY:
;
;
;-
pro mvn_sta_l2_tplot,all=all,units=units,apids=apids,test=test,gf_nor=gf_nor,scale=scale,dead_c0=dead_c0,replace=replace

cols=get_colors()

; Note: mvn_sta_l0_load.pro  generates 'mvn_STA_*'    tplot structures - raw apids
;	mvn_sta_prod_cal.pro generates 'mvn_sta_XX_*  tplot structures where XX are capital letters
;	mvn_sta_l2_load.pro  generates 'mvn_sta_yy_*' tplot structures where yy are lower case letters
if not keyword_set(all) then begin
	store_data,delete='mvn_STA_*'
	store_data,delete='mvn_sta_*'
endif

;declare all the common block arrays

	common mvn_2a,mvn_2a_ind,mvn_2a_dat 

	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_c2,mvn_c2_ind,mvn_c2_dat 
	common mvn_c4,mvn_c4_ind,mvn_c4_dat 
	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
	common mvn_c8,mvn_c8_ind,mvn_c8_dat 
	common mvn_ca,mvn_ca_ind,mvn_ca_dat 
	common mvn_cc,mvn_cc_ind,mvn_cc_dat 
	common mvn_cd,mvn_cd_ind,mvn_cd_dat 
	common mvn_ce,mvn_ce_ind,mvn_ce_dat 
	common mvn_cf,mvn_cf_ind,mvn_cf_dat 
	common mvn_d0,mvn_d0_ind,mvn_d0_dat 
	common mvn_d1,mvn_d1_ind,mvn_d1_dat 

	common mvn_d2,mvn_d2_ind,mvn_d2_dat 
	common mvn_d3,mvn_d3_ind,mvn_d3_dat 
	common mvn_d4,mvn_d4_ind,mvn_d4_dat 
	common mvn_d6,mvn_d6_ind,mvn_d6_dat 
	common mvn_d7,mvn_d7_ind,mvn_d7_dat 
	common mvn_d8,mvn_d8_ind,mvn_d8_dat 
	common mvn_d9,mvn_d9_ind,mvn_d9_dat 
	common mvn_da,mvn_da_ind,mvn_da_dat 
	common mvn_db,mvn_db_ind,mvn_db_dat 

; 2A
	if size(mvn_2a_dat,/type) eq 8 and keyword_set(test) then begin

		for i=0,98 do begin
			label = strtrim(strcompress(mvn_2a_dat.hkp_labels[i]),1)
			name = 'mvn_sta_2a_'+ label
			store_data,name,data={x:mvn_2a_dat.time,y:reform(mvn_2a_dat.hkp[*,i])}
			options,name,ytitle=label
		endfor

		ylim,'mvn_sta_2a_Temp_Dig',0,60,0
		ylim,'mvn_sta_2a_Imon_ADC5V',30,36,0
		ylim,'mvn_sta_2a_+5V_D',4.9,5.2,0
		ylim,'mvn_sta_2a_+3.3V_D',3.2,3.4,0
		ylim,'mvn_sta_2a_+5V_A',4.9,5.2,0
		ylim,'mvn_sta_2a_-5V_A',-5.3,-5.0,0
		ylim,'mvn_sta_2a_+12V_A',11.9,12.3,0
		ylim,'mvn_sta_2a_+28V',24,30,0
		ylim,'mvn_sta_2a_Temp_FPGA',0,60,0
		ylim,'mvn_sta_2a_Temp_LVPS',0,60,0

		get_data,'mvn_sta_2a_Vmon_Swp',data=tmp
		store_data,'mvn_sta_2a_Vmon_Swp_minus',data={x:tmp.x,y:-tmp.y}
		ylim,'mvn_sta_2a_Vmon_Swp_minus',.1,10000.,1
		ylim,'mvn_sta_2a_Vmon_Def1',.1,10000.,1
		ylim,'mvn_sta_2a_Vmon_Def2',.1,10000.,1

		ylim,'mvn_sta_2a_R3Rate',-1,12,0
		ylim,'mvn_sta_2a_LUTADR*',-1,20,0

		options,'mvn_sta_2a*',datagap=100.

	endif

; C0
	if size(mvn_c0_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c0_dat.time)
		mode = mvn_c0_dat.mode
		rate = mvn_c0_dat.rate
		iswp = mvn_c0_dat.swp_ind
		ieff = mvn_c0_dat.eff_ind
		iatt = mvn_c0_dat.att_ind
		mlut = mvn_c0_dat.mlut_ind
		nenergy = mvn_c0_dat.nenergy
		nmass = mvn_c0_dat.nmass
		qf = (mvn_c0_dat.quality_flag and 128)/128 or (mvn_c0_dat.quality_flag and 64)/64

		time = (mvn_c0_dat.time + mvn_c0_dat.end_time)/2.
		data = mvn_c0_dat.data
		energy = reform(mvn_c0_dat.energy[iswp,*,0])
		mass = total(mvn_c0_dat.mass_arr[iswp,*,*],2)/nenergy
		str_element,mvn_c0_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_c0_dat.bkg
			dead = mvn_c0_dat.dead
			gf = reform(mvn_c0_dat.gf[iswp,*,0]*((iatt eq 0)#replicate(1.,nenergy)) +$
		            mvn_c0_dat.gf[iswp,*,1]*((iatt eq 1)#replicate(1.,nenergy)) +$
		            mvn_c0_dat.gf[iswp,*,2]*((iatt eq 2)#replicate(1.,nenergy)) +$
		            mvn_c0_dat.gf[iswp,*,3]*((iatt eq 3)#replicate(1.,nenergy)), npts*nenergy)#replicate(1.,nmass)
			gf = mvn_c0_dat.geom_factor*reform(gf,npts,nenergy,nmass)
			eff = mvn_c0_dat.eff[ieff,*,*]
			dt = float(mvn_c0_dat.integ_t#replicate(1.,nenergy*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/(eflux>.01))) gt 0. then print,'Error in CDF c0 eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count ge 1 then data[ind,*,*]=0.
			if count ge 1 then eflux[ind,*,*]=0.

		store_data,'mvn_sta_c0_P1A_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c0_P1A_H_E',data={x:time,y:reform( (data[*,*,1]-0.006*data[*,*,0]/(1.-(data[*,*,0]/1200.<.9))) >0.),v:energy}
;		store_data,'mvn_sta_c0_P1A_H_E',data={x:time,y:reform( (data[*,*,1]-scale*data[*,*,0]/(1.-(data[*,*,0]/dead_c0<.9))) >0.),v:energy}
		store_data,'mvn_sta_c0_P1A_L_E',data={x:time,y:reform(data[*,*,0]),v:energy}
		store_data,'mvn_sta_c0_P1A_M',data={x:time,y:total(data,2),v:mass}
		store_data,'mvn_sta_c0_E',data={x:time,y:total(eflux,3),v:energy}
		store_data,'mvn_sta_c0_H_E',data={x:time,y:reform((eflux[*,*,1]-0.006*eflux[*,*,0]/(1.-(data[*,*,0]/1200.<.9))) >0.),v:energy}
;		store_data,'mvn_sta_c0_H_E',data={x:time,y:reform((eflux[*,*,1]-scale*eflux[*,*,0]/(1.-(data[*,*,0]/dead_c0<.9))) >0.),v:energy}
		store_data,'mvn_sta_c0_L_E',data={x:time,y:reform(eflux[*,*,0]),v:energy}
		store_data,'mvn_sta_c0_M',data={x:time,y:total(eflux,2),v:mass}
		store_data,'mvn_sta_c0_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c0_att',data={x:time,y:iatt}
		store_data,'mvn_sta_c0_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_c0_rate',data={x:time,y:rate}

			ylim,'mvn_sta_c0_tot',0,0,1
			ylim,'mvn_sta_c0_P1A_E',.1,40000.,1
			ylim,'mvn_sta_c0_P1A_H_E',.1,40000.,1
			ylim,'mvn_sta_c0_P1A_L_E',.1,40000.,1
			ylim,'mvn_sta_c0_P1A_M',.5,100,1
			ylim,'mvn_sta_c0_E',.1,40000.,1
			ylim,'mvn_sta_c0_H_E',.1,40000.,1
			ylim,'mvn_sta_c0_L_E',.1,40000.,1
			ylim,'mvn_sta_c0_M',.5,100,1
			ylim,'mvn_sta_c0_att',-1,4,0

			zlim,'mvn_sta_c0_P1A_E',1,1.e4,1
			zlim,'mvn_sta_c0_P1A_H_E',1,1.e4,1
			zlim,'mvn_sta_c0_P1A_L_E',1,1.e4,1
			zlim,'mvn_sta_c0_P1A_M',1,1.e4,1
			zlim,'mvn_sta_c0_E',1.e3,1.e9,1
			zlim,'mvn_sta_c0_H_E',1.e3,1.e9,1
			zlim,'mvn_sta_c0_L_E',1.e3,1.e9,1
			zlim,'mvn_sta_c0_M',1.e3,1.e9,1

			options,'mvn_sta_c0*',datagap=7.
	
			options,'mvn_sta_c0_P1A_E','spec',1
			options,'mvn_sta_c0_P1A_H_E','spec',1
			options,'mvn_sta_c0_P1A_L_E','spec',1
			options,'mvn_sta_c0_P1A_M','spec',1
			options,'mvn_sta_c0_E','spec',1
			options,'mvn_sta_c0_H_E','spec',1
			options,'mvn_sta_c0_L_E','spec',1
			options,'mvn_sta_c0_M','spec',1

			options,'mvn_sta_c0_P1A_E',ytitle='sta!CP1A-c0!C!CEnergy!CeV'
			options,'mvn_sta_c0_P1A_H_E',ytitle='sta!CP1A-c0!CM>12amu!CEnergy!CeV'
			options,'mvn_sta_c0_P1A_L_E',ytitle='sta!CP1A-c0!CM<10amu!CEnergy!CeV'
			options,'mvn_sta_c0_P1A_M',ytitle='sta!CP1A-c0!C!CMass!Camu'
			options,'mvn_sta_c0_E',ytitle='sta!Cc0!C!CEnergy!CeV'
			options,'mvn_sta_c0_H_E',ytitle='sta c0!CM>12!CEnergy!CeV'
			options,'mvn_sta_c0_L_E',ytitle='sta c0!CM<10!CEnergy!CeV'
			options,'mvn_sta_c0_M',ytitle='sta!Cc0!C!CMass!Camu'
			options,'mvn_sta_c0_tot',ytitle='sta!Cc0!C!CCounts'
			options,'mvn_sta_c0_att',ytitle='sta!Cc0!C!CAttenuator'

			options,'mvn_sta_c0_E',ztitle='eflux'
			options,'mvn_sta_c0_H_E',ztitle='eflux'
			options,'mvn_sta_c0_L_E',ztitle='eflux'
			options,'mvn_sta_c0_M',ztitle='eflux'
	endif

; C2
	if size(mvn_c2_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c2_dat.time)
		mode = mvn_c2_dat.mode
		rate = mvn_c2_dat.rate
		iswp = mvn_c2_dat.swp_ind
		ieff = mvn_c2_dat.eff_ind
		iatt = mvn_c2_dat.att_ind
		mlut = mvn_c2_dat.mlut_ind
		nenergy = mvn_c2_dat.nenergy
		nmass = mvn_c2_dat.nmass
		qf = (mvn_c2_dat.quality_flag and 128)/128 or (mvn_c2_dat.quality_flag and 64)/64

		time = (mvn_c2_dat.time + mvn_c2_dat.end_time)/2.
		data = mvn_c2_dat.data
		energy = reform(mvn_c2_dat.energy[iswp,*,0])
		mass = total(mvn_c2_dat.mass_arr[iswp,*,*],2)/nenergy
		str_element,mvn_c2_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_c2_dat.bkg
			dead = mvn_c2_dat.dead
			gf = reform(mvn_c2_dat.gf[iswp,*,0]*((iatt eq 0)#replicate(1.,nenergy)) +$
		            mvn_c2_dat.gf[iswp,*,1]*((iatt eq 1)#replicate(1.,nenergy)) +$
		            mvn_c2_dat.gf[iswp,*,2]*((iatt eq 2)#replicate(1.,nenergy)) +$
		            mvn_c2_dat.gf[iswp,*,3]*((iatt eq 3)#replicate(1.,nenergy)), npts*nenergy)#replicate(1.,nmass)
			gf = mvn_c2_dat.geom_factor*reform(gf,npts,nenergy,nmass)
			eff = mvn_c2_dat.eff[ieff,*,*]
			dt = float(mvn_c2_dat.integ_t#replicate(1.,nenergy*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/(eflux>.01))) gt 0. then print,'Error in CDF c2 eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*]=0.
			if count gt 0 then eflux[ind,*,*]=0.

		store_data,'mvn_sta_c2_P1D_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c2_P1D_M',data={x:time,y:total(data,2),v:mass}
		store_data,'mvn_sta_c2_E',data={x:time,y:total(eflux,3),v:energy}
		store_data,'mvn_sta_c2_M',data={x:time,y:total(eflux,2),v:mass}
		store_data,'mvn_sta_c2_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c2_att',data={x:time,y:iatt}
		store_data,'mvn_sta_c2_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_c2_rate',data={x:time,y:rate}

			ylim,'mvn_sta_c2_tot',0,0,1
			ylim,'mvn_sta_c2_P1D_E',.1,40000.,1
			ylim,'mvn_sta_c2_P1D_M',.5,100.,1
			ylim,'mvn_sta_c2_E',.1,40000.,1
			ylim,'mvn_sta_c2_M',.5,100.,1
			ylim,'mvn_sta_c2_att',-1,4,0

			zlim,'mvn_sta_c2_P1D_E',1,1.e4,1
			zlim,'mvn_sta_c2_P1D_M',1,1.e4,1
			zlim,'mvn_sta_c2_E',1.e3,1.e9,1
			zlim,'mvn_sta_c2_M',1.e3,1.e9,1

			datagap=7.
			options,'mvn_sta_c2_P1D_E',datagap=datagap
			options,'mvn_sta_c2_P1D_M',datagap=datagap
			options,'mvn_sta_c2_E',datagap=datagap
			options,'mvn_sta_c2_M',datagap=datagap
			options,'mvn_sta_c2_tot',datagap=datagap
			options,'mvn_sta_c2_att',datagap=datagap

			options,'mvn_sta_c2_P1D_E','spec',1
			options,'mvn_sta_c2_P1D_M','spec',1
			options,'mvn_sta_c2_E','spec',1
			options,'mvn_sta_c2_M','spec',1

			options,'mvn_sta_c2_P1D_E',ytitle='sta!CP1D-c2!C!CEnergy!CeV'
			options,'mvn_sta_c2_P1D_M',ytitle='sta!CP1D-c2!C!CMass!Camu'
			options,'mvn_sta_c2_E',ytitle='sta!Cc2!C!CEnergy!CeV'
			options,'mvn_sta_c2_M',ytitle='sta!Cc2!C!CMass!Camu'
			options,'mvn_sta_c2_tot',ytitle='sta!Cc2!C!CCounts'
			options,'mvn_sta_c2_att',ytitle='sta!Cc2!C!CAttenuator'

			options,'mvn_sta_c2_E',ztitle='eflux'
			options,'mvn_sta_c2_M',ztitle='eflux'
	endif

; C4
	if size(mvn_c4_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c4_dat.time)
		mode = mvn_c4_dat.mode
		rate = mvn_c4_dat.rate
		iswp = mvn_c4_dat.swp_ind
		ieff = mvn_c4_dat.eff_ind
		iatt = mvn_c4_dat.att_ind
		mlut = mvn_c4_dat.mlut_ind
		nenergy = mvn_c4_dat.nenergy
		nmass = mvn_c4_dat.nmass
		qf = (mvn_c4_dat.quality_flag and 128)/128 or (mvn_c4_dat.quality_flag and 64)/64

		time = (mvn_c4_dat.time + mvn_c4_dat.end_time)/2.
		data = mvn_c4_dat.data
		energy = reform(mvn_c4_dat.energy[iswp,*,0])
		mass = total(mvn_c4_dat.mass_arr[iswp,*,*],2)/nenergy
		str_element,mvn_c4_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_c4_dat.bkg
			dead = mvn_c4_dat.dead
			gf = reform(mvn_c4_dat.gf[iswp,*,0]*((iatt eq 0)#replicate(1.,nenergy)) +$
		            mvn_c4_dat.gf[iswp,*,1]*((iatt eq 1)#replicate(1.,nenergy)) +$
		            mvn_c4_dat.gf[iswp,*,2]*((iatt eq 2)#replicate(1.,nenergy)) +$
		            mvn_c4_dat.gf[iswp,*,3]*((iatt eq 3)#replicate(1.,nenergy)), npts*nenergy)#replicate(1.,nmass)
			gf = mvn_c4_dat.geom_factor*reform(gf,npts,nenergy,nmass)
			eff = mvn_c4_dat.eff[ieff,*,*]
			dt = float(mvn_c4_dat.integ_t#replicate(1.,nenergy*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/(eflux>.01))) gt 0. then print,'Error in CDF c4 eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*]=0.
			if count gt 0 then eflux[ind,*,*]=0.

		store_data,'mvn_sta_c4_P1D_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c4_P1D_M',data={x:time,y:total(data,2),v:mass}
		store_data,'mvn_sta_c4_E',data={x:time,y:total(eflux,3),v:energy}
		store_data,'mvn_sta_c4_M',data={x:time,y:total(eflux,2),v:mass}
		store_data,'mvn_sta_c4_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c4_att',data={x:time,y:iatt}
		store_data,'mvn_sta_c4_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_c4_rate',data={x:time,y:rate}

			ylim,'mvn_sta_c4_tot',0,0,1
			ylim,'mvn_sta_c4_P1D_E',.1,40000.,1
			ylim,'mvn_sta_c4_P1D_M',.5,100.,1
			ylim,'mvn_sta_c4_E',.1,40000.,1
			ylim,'mvn_sta_c4_M',.5,100.,1
			ylim,'mvn_sta_c4_att',-1,4,0

			zlim,'mvn_sta_c4_P1D_E',1,1.e4,1
			zlim,'mvn_sta_c4_P1D_M',1,1.e4,1
			zlim,'mvn_sta_c4_E',1.e3,1.e9,1
			zlim,'mvn_sta_c4_M',1.e3,1.e9,1

			datagap=7.
			options,'mvn_sta_c4_P1D_E',datagap=datagap
			options,'mvn_sta_c4_P1D_M',datagap=datagap
			options,'mvn_sta_c4_E',datagap=datagap
			options,'mvn_sta_c4_M',datagap=datagap
			options,'mvn_sta_c4_tot',datagap=datagap
			options,'mvn_sta_c4_att',datagap=datagap

			options,'mvn_sta_c4_P1D_E','spec',1
			options,'mvn_sta_c4_P1D_M','spec',1
			options,'mvn_sta_c4_E','spec',1
			options,'mvn_sta_c4_M','spec',1

			options,'mvn_sta_c4_P1D_E',ytitle='sta!CP1D-c4!C!CEnergy!CeV'
			options,'mvn_sta_c4_P1D_M',ytitle='sta!CP1D-c4!C!CMass!Camu'
			options,'mvn_sta_c4_E',ytitle='sta!Cc4!C!CEnergy!CeV'
			options,'mvn_sta_c4_M',ytitle='sta!Cc4!C!CMass!Camu'
			options,'mvn_sta_c4_tot',ytitle='sta!Cc4!C!CCounts'
			options,'mvn_sta_c4_att',ytitle='sta!Cc4!C!CAttenuator'

			options,'mvn_sta_c4_E',ztitle='eflux'
			options,'mvn_sta_c4_M',ztitle='eflux'
	endif

; C6
	if size(mvn_c6_dat,/type) eq 8 then begin

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


		store_data,'mvn_sta_c6_P1D_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c6_P1D_M',data={x:time,y:total(data,2),v:mass}
		store_data,'mvn_sta_c6_E',data={x:time,y:total(eflux,3),v:energy}
		store_data,'mvn_sta_c6_M',data={x:time,y:total(eflux,2),v:mass}
		store_data,'mvn_sta_c6_M_twt',data={x:time,y:total(eflux/twt,2),v:mass}
		store_data,'mvn_sta_c6_tot',data={x:time,y:total(total(data,3),2)}
			store_data,'mvn_sta_c6_tot_le_10eV',data={x:time,y:cnt_low_nrg}
		store_data,'mvn_sta_c6_att',data={x:time,y:iatt}
			store_data,'mvn_sta_c6_mode',data={x:time,y:mode}
			store_data,'mvn_sta_c6_rate',data={x:time,y:rate}
			store_data,'mvn_sta_c6_quality_flag',data={x:time,y:mvn_c6_dat.quality_flag}
				options,'mvn_sta_c6_quality_flag',tplot_routine='bitplot',psym = 1,symsize=1
			store_data,'mvn_sta_c6_eprom_ver',data={x:time,y:eprom_ver}
				ylim,'mvn_sta_c6_eprom_ver',min(eprom_ver)-1,max(eprom_ver)+1,0				
			store_data,'mvn_sta_c6_scpot',data={x:time,y:scpot}
			store_data,'mvn_sta_c6_neg_scpot',data={x:time,y:-scpot}
				options,'mvn_sta_c6_neg_scpot',colors=cols.red

			ylim,'mvn_sta_c6_tot',0,0,1
				ylim,'mvn_sta_c6_tot_le_10eV',0,0,1
			ylim,'mvn_sta_c6_P1D_E',.1,40000.,1
			ylim,'mvn_sta_c6_P1D_M',.5,100.,1
			ylim,'mvn_sta_c6_E',.1,40000.,1
			ylim,'mvn_sta_c6_M',.5,100.,1
			ylim,'mvn_sta_c6_M_twt',.5,100.,1
			ylim,'mvn_sta_c6_att',-1,4,0
			ylim,'mvn_sta_c6_mode',-1,8,0
			ylim,'mvn_sta_c6_rate',-1,7,0
			ylim,'mvn_sta_c6_scpot',0,0,0
			ylim,'mvn_sta_c6_neg_scpot',.1,30,1

			zlim,'mvn_sta_c6_P1D_E',1,1.e4,1
			zlim,'mvn_sta_c6_P1D_M',1,1.e4,1
			zlim,'mvn_sta_c6_E',1.e3,1.e9,1
			zlim,'mvn_sta_c6_M',1.e3,1.e9,1
			zlim,'mvn_sta_c6_M_twt',1.e3,1.e9,1

			datagap=7.
			options,'mvn_sta_c6_P1D_E',datagap=datagap
			options,'mvn_sta_c6_P1D_M',datagap=datagap
			options,'mvn_sta_c6_E',datagap=datagap
			options,'mvn_sta_c6_M',datagap=datagap
			options,'mvn_sta_c6_M_twt',datagap=datagap
			options,'mvn_sta_c6_tot',datagap=datagap
				options,'mvn_sta_c6_tot_le_10eV',datagap=datagap
			options,'mvn_sta_c6_att',datagap=datagap
			options,'mvn_sta_c6_scpot',datagap=datagap
			options,'mvn_sta_c6_neg_scpot',datagap=datagap

			options,'mvn_sta_c6_P1D_E','spec',1
			options,'mvn_sta_c6_P1D_M','spec',1
			options,'mvn_sta_c6_E','spec',1
			options,'mvn_sta_c6_M','spec',1
			options,'mvn_sta_c6_M_twt','spec',1

			options,'mvn_sta_c6_P1D_E',ytitle='sta!CP1D-c6!C!CEnergy!CeV'
			options,'mvn_sta_c6_P1D_M',ytitle='sta!CP1D-c6!C!CMass!Camu'
			options,'mvn_sta_c6_E',ytitle='sta!Cc6!C!CEnergy!CeV'
			options,'mvn_sta_c6_M',ytitle='sta!Cc6!C!CMass!Camu'
			options,'mvn_sta_c6_M_twt',ytitle='sta!Cc6!C!CMass!Camu'
			options,'mvn_sta_c6_tot',ytitle='sta!Cc6!C!CCounts'
				options,'mvn_sta_c6_tot_le_10eV',ytitle='sta!Cc6!C!C<10eV Cnts'
			options,'mvn_sta_c6_att',ytitle='sta!Cc6!C!CAttenuator'
			options,'mvn_sta_c6_scpot',ytitle='sta!Cc6!C!Cscpot'
			options,'mvn_sta_c6_neg_scpot',ytitle='sta!Cc6!C!C-scpot'

			options,'mvn_sta_c6_E',ztitle='eflux'
			options,'mvn_sta_c6_M',ztitle='eflux'
			options,'mvn_sta_c6_M_twt',ztitle='eflux/tofbin'
	endif

; C8
	if size(mvn_c8_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c8_dat.time)
		mode = mvn_c8_dat.mode
		rate = mvn_c8_dat.rate
		iswp = mvn_c8_dat.swp_ind
		ieff = mvn_c8_dat.eff_ind
		iatt = mvn_c8_dat.att_ind
		mlut = mvn_c8_dat.mlut_ind
		nenergy = mvn_c8_dat.nenergy
		ndef = mvn_c8_dat.ndef
		qf = (mvn_c8_dat.quality_flag and 128)/128 or (mvn_c8_dat.quality_flag and 64)/64

		time = (mvn_c8_dat.time + mvn_c8_dat.end_time)/2.
		data = mvn_c8_dat.data
		energy = reform(mvn_c8_dat.energy[iswp,*,0])
		theta = reform(mvn_c8_dat.theta[iswp,nenergy-1,*])
		str_element,mvn_c8_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_c8_dat.bkg
			dead = mvn_c8_dat.dead
			gf = reform(mvn_c8_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*ndef)) +$
		            mvn_c8_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*ndef)) +$
		            mvn_c8_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*ndef)) +$
		            mvn_c8_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*ndef)), npts,nenergy,ndef)
			gf = mvn_c8_dat.geom_factor*gf
			eff = mvn_c8_dat.eff[ieff,*,*]
			dt = float(mvn_c8_dat.integ_t#replicate(1.,nenergy*ndef))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/(eflux>.01))) gt 0. then print,'Error in CDF c8 eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*]=0.
			if count gt 0 then eflux[ind,*,*]=0.

		store_data,'mvn_sta_c8_P2_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c8_P2_D',data={x:time,y:total(data,2),v:theta}
		store_data,'mvn_sta_c8_E',data={x:time,y:total(eflux,3)/ndef,v:energy}
		store_data,'mvn_sta_c8_D',data={x:time,y:total(eflux,2)/nenergy,v:theta}
		store_data,'mvn_sta_c8_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c8_att',data={x:time,y:iatt}
		store_data,'mvn_sta_c8_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_c8_rate',data={x:time,y:rate}

			ylim,'mvn_sta_c8_tot',0,0,1
			ylim,'mvn_sta_c8_P2_E',.1,40000.,1
			ylim,'mvn_sta_c8_P2_D',-50,50,0
			ylim,'mvn_sta_c8_E',.1,40000.,1
			ylim,'mvn_sta_c8_D',-50,50,0
			ylim,'mvn_sta_c8_att',-1,4,0

			zlim,'mvn_sta_c8_P2_E',1,1.e4,1
			zlim,'mvn_sta_c8_P2_D',1,1.e4,1
			zlim,'mvn_sta_c8_E',1.e3,1.e9,1
			zlim,'mvn_sta_c8_D',1.e3,1.e9,1

			datagap=7.
			options,'mvn_sta_c8_P2_E',datagap=datagap
			options,'mvn_sta_c8_P2_D',datagap=datagap
			options,'mvn_sta_c8_E',datagap=datagap
			options,'mvn_sta_c8_D',datagap=datagap
			options,'mvn_sta_c8_tot',datagap=datagap
	
			options,'mvn_sta_c8_P2_E','spec',1
			options,'mvn_sta_c8_P2_D','spec',1
			options,'mvn_sta_c8_E','spec',1
			options,'mvn_sta_c8_D','spec',1

			options,'mvn_sta_c8_P2_E',ytitle='sta!CP2-c8!C!CEnergy!CeV'
			options,'mvn_sta_c8_P2_D',ytitle='sta!CP2-c8!C!CTheta!Cdeg'
			options,'mvn_sta_c8_E',ytitle='sta!Cc8!C!CEnergy!CeV'
			options,'mvn_sta_c8_D',ytitle='sta!Cc8!C!CTheta!Cdeg'
			options,'mvn_sta_c8_tot',ytitle='sta!Cc8!C!CCounts'
			options,'mvn_sta_c8_att',ytitle='sta!Cc8!C!CAttenuator'

			options,'mvn_sta_c8_E',ztitle='eflux'
			options,'mvn_sta_c8_D',ztitle='eflux'
	endif

; CA
	if size(mvn_ca_dat,/type) eq 8 then begin

		npts = n_elements(mvn_ca_dat.time)
		mode = mvn_ca_dat.mode
		rate = mvn_ca_dat.rate
		iswp = mvn_ca_dat.swp_ind
		ieff = mvn_ca_dat.eff_ind
		iatt = mvn_ca_dat.att_ind
		nenergy = mvn_ca_dat.nenergy
		nbins = mvn_ca_dat.nbins
		ndef = mvn_ca_dat.ndef
		nanode = mvn_ca_dat.nanode
		qf = (mvn_ca_dat.quality_flag and 128)/128 or (mvn_ca_dat.quality_flag and 64)/64

		time = (mvn_ca_dat.time + mvn_ca_dat.end_time)/2.
		data = mvn_ca_dat.data
		energy = reform(mvn_ca_dat.energy[iswp,*,0])
		theta = total(reform(mvn_ca_dat.theta[iswp,nenergy-1,*],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_ca_dat.phi[iswp,nenergy-1,*],npts,ndef,nanode),2)/ndef
		str_element,mvn_ca_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_ca_dat.bkg
			dead = mvn_ca_dat.dead
			gf = reform(mvn_ca_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
		            mvn_ca_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
		            mvn_ca_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
		            mvn_ca_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts*nenergy*nbins)
			gf = mvn_ca_dat.geom_factor*reform(gf,npts,nenergy,nbins)
			eff = mvn_ca_dat.eff[ieff,*,*]
			dt = float(mvn_ca_dat.integ_t#replicate(1.,nenergy*nbins))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/(eflux>.01))) gt 0. then print,'Error in CDF ca eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*]=0.
			if count gt 0 then eflux[ind,*,*]=0.

		store_data,'mvn_sta_ca_P3_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_ca_P3_D',data={x:time,y:total(total(reform(data,npts,nenergy,ndef,nanode),4),2),v:theta}
		store_data,'mvn_sta_ca_P3_A',data={x:time,y:total(total(reform(data,npts,nenergy,ndef,nanode),3),2),v:phi}
		store_data,'mvn_sta_ca_tot',data={x:time,y:total(total(data,3),2)}

		store_data,'mvn_sta_ca_E',data={x:time,y:total(eflux,3)/nbins,v:energy}
		store_data,'mvn_sta_ca_D',data={x:time,y:total(total(reform(eflux,npts,nenergy,ndef,nanode),4),2)/nenergy/nanode,v:theta}
		store_data,'mvn_sta_ca_A',data={x:time,y:total(total(reform(eflux,npts,nenergy,ndef,nanode),3),2)/nenergy/ndef,v:phi}
		store_data,'mvn_sta_ca_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_ca_rate',data={x:time,y:rate}

			ylim,'mvn_sta_ca_P3_E',.1,40000.,1
			ylim,'mvn_sta_ca_P3_D',-50,50,0
			ylim,'mvn_sta_ca_P3_A',-180,200.,0
			ylim,'mvn_sta_ca_tot',0,0,1

			ylim,'mvn_sta_ca_E',.1,40000.,1
			ylim,'mvn_sta_ca_D',-50,50,0
			ylim,'mvn_sta_ca_A',-180,200.,0

			zlim,'mvn_sta_ca_P3_E',1,1.e4,1
			zlim,'mvn_sta_ca_P3_D',1,1.e4,1
			zlim,'mvn_sta_ca_P3_A',1,1.e4,1

			zlim,'mvn_sta_ca_E',1.e3,1.e9,1
			zlim,'mvn_sta_ca_D',1.e3,1.e9,1
			zlim,'mvn_sta_ca_A',1.e3,1.e9,1

			datagap=7.
			options,'mvn_sta_ca_P3_E',datagap=datagap
			options,'mvn_sta_ca_P3_D',datagap=datagap
			options,'mvn_sta_ca_P3_A',datagap=datagap
			options,'mvn_sta_ca_tot',datagap=datagap

			options,'mvn_sta_ca_E',datagap=datagap
			options,'mvn_sta_ca_D',datagap=datagap
			options,'mvn_sta_ca_A',datagap=datagap
	
			options,'mvn_sta_ca_P3_E','spec',1
			options,'mvn_sta_ca_P3_D','spec',1
			options,'mvn_sta_ca_P3_A','spec',1

			options,'mvn_sta_ca_E','spec',1
			options,'mvn_sta_ca_D','spec',1
			options,'mvn_sta_ca_A','spec',1

			options,'mvn_sta_ca_P3_E',ytitle='sta!CP3-ca!C!CEnergy!CeV'
			options,'mvn_sta_ca_P3_D',ytitle='sta!CP3-ca!C!CTheta!Cdeg'
			options,'mvn_sta_ca_P3_A',ytitle='sta!CP3-ca!C!CPhi!Cdeg'
			options,'mvn_sta_ca_tot',ytitle='sta!Cca!C!CCounts'

			options,'mvn_sta_ca_E',ytitle='sta!Cca!C!CEnergy!CeV'
			options,'mvn_sta_ca_D',ytitle='sta!Cca!C!CTheta!Cdeg'
			options,'mvn_sta_ca_A',ytitle='sta!Cca!C!CPhi!Cdeg'

			options,'mvn_sta_ca_E',ztitle='eflux'
			options,'mvn_sta_ca_D',ztitle='eflux'
			options,'mvn_sta_ca_A',ztitle='eflux'
	endif

; CC
	if size(mvn_cc_dat,/type) eq 8 then begin

		npts = n_elements(mvn_cc_dat.time)
		mode = mvn_cc_dat.mode
		rate = mvn_cc_dat.rate
		iswp = mvn_cc_dat.swp_ind
		ieff = mvn_cc_dat.eff_ind
		iatt = mvn_cc_dat.att_ind
		mlut = mvn_cc_dat.mlut_ind
		nenergy = mvn_cc_dat.nenergy
		nbins = mvn_cc_dat.nbins
		ndef = mvn_cc_dat.ndef
		nanode = mvn_cc_dat.nanode
		nmass = mvn_cc_dat.nmass
		qf = (mvn_cc_dat.quality_flag and 128)/128 or (mvn_cc_dat.quality_flag and 64)/64

		time = (mvn_cc_dat.time + mvn_cc_dat.end_time)/2.
		data = mvn_cc_dat.data
		energy = reform(mvn_cc_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_cc_dat.mass_arr[iswp,*,0,*],2)/nenergy)
		theta = total(reform(mvn_cc_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_cc_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef
		str_element,mvn_cc_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_cc_dat.bkg
			dead = mvn_cc_dat.dead
			gf = reform(mvn_cc_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
		            mvn_cc_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
		            mvn_cc_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
		            mvn_cc_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts*nenergy*nbins)$
				#replicate(1.,nmass)
			gf = mvn_cc_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
			eff = mvn_cc_dat.eff[ieff,*,*,*]
			dt = float(mvn_cc_dat.integ_t#replicate(1.,nenergy*nbins*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/(eflux>.01))) gt 0. then print,'Error in CDF cc eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*,*]=0.
			if count gt 0 then eflux[ind,*,*,*]=0.

		store_data,'mvn_sta_cc_P4B_E',data={x:time,y:total(total(data,4),3),v:energy}
		store_data,'mvn_sta_cc_P4B_D',data={x:time,y:total(total(data,4),2),v:theta}
		store_data,'mvn_sta_cc_P4B_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_cc_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_cc_D',data={x:time,y:total(total(eflux,4),2)/nenergy,v:theta}
		store_data,'mvn_sta_cc_M',data={x:time,y:total(total(eflux,3),2)/nenergy/nbins,v:mass}
		store_data,'mvn_sta_cc_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_cc_att',data={x:time,y:iatt}
		store_data,'mvn_sta_cc_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_cc_rate',data={x:time,y:rate}

			ylim,'mvn_sta_cc_tot',0,0,1
			ylim,'mvn_sta_cc_P4B_E',.1,40000.,1
			ylim,'mvn_sta_cc_P4B_D',-50,50,0
			ylim,'mvn_sta_cc_P4B_M',.5,100,1
			ylim,'mvn_sta_cc_E',.1,40000.,1
			ylim,'mvn_sta_cc_D',-50,50,0
			ylim,'mvn_sta_cc_M',.5,100,1
			ylim,'mvn_sta_cc_att',-1,4,0

			zlim,'mvn_sta_cc_P4B_E',10,1.e5,1
			zlim,'mvn_sta_cc_P4B_D',10,1.e5,1
			zlim,'mvn_sta_cc_P4B_M',10,1.e5,1
			zlim,'mvn_sta_cc_E',1.e3,1.e9,1
			zlim,'mvn_sta_cc_D',1.e3,1.e9,1
			zlim,'mvn_sta_cc_M',1.e3,1.e9,1

			datagap=600.
			options,'mvn_sta_cc_P4B_E',datagap=datagap
			options,'mvn_sta_cc_P4B_D',datagap=datagap
			options,'mvn_sta_cc_P4B_M',datagap=datagap
			options,'mvn_sta_cc_E',datagap=datagap
			options,'mvn_sta_cc_D',datagap=datagap
			options,'mvn_sta_cc_M',datagap=datagap
			options,'mvn_sta_cc_tot',datagap=datagap
	
			options,'mvn_sta_cc_P4B_E','spec',1
			options,'mvn_sta_cc_P4B_D','spec',1
			options,'mvn_sta_cc_P4B_M','spec',1
			options,'mvn_sta_cc_E','spec',1
			options,'mvn_sta_cc_D','spec',1
			options,'mvn_sta_cc_M','spec',1

			options,'mvn_sta_cc_P4B_E',ytitle='sta!CP4B-cc!C!CEnergy!CeV'
			options,'mvn_sta_cc_P4B_D',ytitle='sta!CP4B-cc!C!CTheta!Cdeg'
			options,'mvn_sta_cc_P4B_M',ytitle='sta!CP4B-cc!C!CMass!Camu'
			options,'mvn_sta_cc_E',ytitle='sta!Ccc!C!CEnergy!CeV'
			options,'mvn_sta_cc_D',ytitle='sta!Ccc!C!CTheta!Cdeg'
			options,'mvn_sta_cc_M',ytitle='sta!Ccc!C!CMass!Camu'
			options,'mvn_sta_cc_tot',ytitle='sta!Ccc!C!CCounts'
			options,'mvn_sta_cc_att',ytitle='sta!Ccc!C!CAttenuator'

			options,'mvn_sta_cc_E',ztitle='eflux'
			options,'mvn_sta_cc_D',ztitle='eflux'
			options,'mvn_sta_cc_M',ztitle='eflux'
	endif


; CD
	if size(mvn_cd_dat,/type) eq 8 then begin

		npts = n_elements(mvn_cd_dat.time)
		mode = mvn_cd_dat.mode
		rate = mvn_cd_dat.rate
		iswp = mvn_cd_dat.swp_ind
		ieff = mvn_cd_dat.eff_ind
		iatt = mvn_cd_dat.att_ind
		mlut = mvn_cd_dat.mlut_ind
		nenergy = mvn_cd_dat.nenergy
		nbins = mvn_cd_dat.nbins
		ndef = mvn_cd_dat.ndef
		nanode = mvn_cd_dat.nanode
		nmass = mvn_cd_dat.nmass
		qf = (mvn_cd_dat.quality_flag and 128)/128 or (mvn_cd_dat.quality_flag and 64)/64

		time = (mvn_cd_dat.time + mvn_cd_dat.end_time)/2.
		data = mvn_cd_dat.data
		energy = reform(mvn_cd_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_cd_dat.mass_arr[iswp,*,0,*],2)/nenergy)
		theta = total(reform(mvn_cd_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_cd_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef
		str_element,mvn_cd_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_cd_dat.bkg
			dead = mvn_cd_dat.dead
			gf = reform(mvn_cd_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
		            mvn_cd_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
		            mvn_cd_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
		            mvn_cd_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts*nenergy*nbins)$
				#replicate(1.,nmass)
			gf = mvn_cd_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
			eff = mvn_cd_dat.eff[ieff,*,*,*]
			dt = float(mvn_cd_dat.integ_t#replicate(1.,nenergy*nbins*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/(eflux>.01))) gt 0. then print,'Error in CDF cd eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*,*]=0.
			if count gt 0 then eflux[ind,*,*,*]=0.

		store_data,'mvn_sta_cd_P4B_E',data={x:time,y:total(total(data,4),3),v:energy}
		store_data,'mvn_sta_cd_P4B_D',data={x:time,y:total(total(data,4),2),v:theta}
		store_data,'mvn_sta_cd_P4B_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_cd_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_cd_D',data={x:time,y:total(total(eflux,4),2)/nenergy,v:theta}
		store_data,'mvn_sta_cd_M',data={x:time,y:total(total(eflux,3),2)/nenergy/nbins,v:mass}
		store_data,'mvn_sta_cd_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_cd_att',data={x:time,y:iatt}
		store_data,'mvn_sta_cd_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_cd_rate',data={x:time,y:rate}

			ylim,'mvn_sta_cd_tot',0,0,1
			ylim,'mvn_sta_cd_P4B_E',.1,40000.,1
			ylim,'mvn_sta_cd_P4B_D',-50,50,0
			ylim,'mvn_sta_cd_P4B_M',.5,100,1
			ylim,'mvn_sta_cd_E',.1,40000.,1
			ylim,'mvn_sta_cd_D',-50,50,0
			ylim,'mvn_sta_cd_M',.5,100,1
			ylim,'mvn_sta_cd_att',-1,4,0

			zlim,'mvn_sta_cd_P4B_E',10,1.e5,1
			zlim,'mvn_sta_cd_P4B_D',10,1.e5,1
			zlim,'mvn_sta_cd_P4B_M',10,1.e5,1
			zlim,'mvn_sta_cd_E',1.e3,1.e9,1
			zlim,'mvn_sta_cd_D',1.e3,1.e9,1
			zlim,'mvn_sta_cd_M',1.e3,1.e9,1

			datagap=600.
			options,'mvn_sta_cd_P4B_E',datagap=datagap
			options,'mvn_sta_cd_P4B_D',datagap=datagap
			options,'mvn_sta_cd_P4B_M',datagap=datagap
			options,'mvn_sta_cd_E',datagap=datagap
			options,'mvn_sta_cd_D',datagap=datagap
			options,'mvn_sta_cd_M',datagap=datagap
			options,'mvn_sta_cd_tot',datagap=datagap
	
			options,'mvn_sta_cd_P4B_E','spec',1
			options,'mvn_sta_cd_P4B_D','spec',1
			options,'mvn_sta_cd_P4B_M','spec',1
			options,'mvn_sta_cd_E','spec',1
			options,'mvn_sta_cd_D','spec',1
			options,'mvn_sta_cd_M','spec',1

			options,'mvn_sta_cd_P4B_E',ytitle='sta!CP4B-cd!C!CEnergy!CeV'
			options,'mvn_sta_cd_P4B_D',ytitle='sta!CP4B-cd!C!CTheta!Cdeg'
			options,'mvn_sta_cd_P4B_M',ytitle='sta!CP4B-cd!C!CMass!Camu'
			options,'mvn_sta_cd_E',ytitle='sta!Ccd!C!CEnergy!CeV'
			options,'mvn_sta_cd_D',ytitle='sta!Ccd!C!CTheta!Cdeg'
			options,'mvn_sta_cd_M',ytitle='sta!Ccd!C!CMass!Camu'
			options,'mvn_sta_cd_tot',ytitle='sta!Ccd!C!CCounts'
			options,'mvn_sta_cd_att',ytitle='sta!Ccd!C!CAttenuator'

			options,'mvn_sta_cd_E',ztitle='eflux'
			options,'mvn_sta_cd_D',ztitle='eflux'
			options,'mvn_sta_cd_M',ztitle='eflux'
	endif


; CE
	if size(mvn_ce_dat,/type) eq 8 then begin

		npts = n_elements(mvn_ce_dat.time)
		mode = mvn_ce_dat.mode
		rate = mvn_ce_dat.rate
		iswp = mvn_ce_dat.swp_ind
		ieff = mvn_ce_dat.eff_ind
		iatt = mvn_ce_dat.att_ind
		mlut = mvn_ce_dat.mlut_ind
		nenergy = mvn_ce_dat.nenergy
		nbins = mvn_ce_dat.nbins
		ndef = mvn_ce_dat.ndef
		nanode = mvn_ce_dat.nanode
		nmass = mvn_ce_dat.nmass
		qf = (mvn_ce_dat.quality_flag and 128)/128 or (mvn_ce_dat.quality_flag and 64)/64

		time = (mvn_ce_dat.time + mvn_ce_dat.end_time)/2.
		data = mvn_ce_dat.data
		energy = reform(mvn_ce_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_ce_dat.mass_arr[iswp,*,0,*],2)/nenergy)
		theta = total(reform(mvn_ce_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_ce_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef
		str_element,mvn_ce_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_ce_dat.bkg
			dead = mvn_ce_dat.dead
			gf = reform(mvn_ce_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
		            mvn_ce_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
		            mvn_ce_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
		            mvn_ce_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts*nenergy*nbins)$
				#replicate(1.,nmass)
			gf = mvn_ce_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
			eff = mvn_ce_dat.eff[ieff,*,*,*]
			dt = float(mvn_ce_dat.integ_t#replicate(1.,nenergy*nbins*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/eflux)) gt 0. then print,'Error in CDF ce eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*,*]=0.
			if count gt 0 then eflux[ind,*,*,*]=0.

		store_data,'mvn_sta_ce_P4B_E',data={x:time,y:total(total(data,4),3),v:energy}
		store_data,'mvn_sta_ce_P4B_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_ce_P4B_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_ce_P4B_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_ce_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_ce_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_ce_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_ce_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_ce_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_ce_att',data={x:time,y:iatt}
		store_data,'mvn_sta_ce_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_ce_rate',data={x:time,y:rate}

			ylim,'mvn_sta_ce_tot',0,0,1
			ylim,'mvn_sta_ce_P4B_E',.1,40000.,1
			ylim,'mvn_sta_ce_P4B_D',-50,50,0
			ylim,'mvn_sta_ce_P4B_A',-180,200.,0
			ylim,'mvn_sta_ce_P4B_M',.5,100,1
			ylim,'mvn_sta_ce_E',.1,40000.,1
			ylim,'mvn_sta_ce_D',-50,50,0
			ylim,'mvn_sta_ce_A',-180,200.,0
			ylim,'mvn_sta_ce_M',.5,100,1
			ylim,'mvn_sta_ce_att',-1,4,0

			zlim,'mvn_sta_ce_P4B_E',10,1.e5,1
			zlim,'mvn_sta_ce_P4B_D',10,1.e5,1
			zlim,'mvn_sta_ce_P4B_A',10,1.e5,1
			zlim,'mvn_sta_ce_P4B_M',10,1.e5,1
			zlim,'mvn_sta_ce_E',1.e3,1.e9,1
			zlim,'mvn_sta_ce_D',1.e3,1.e9,1
			zlim,'mvn_sta_ce_A',1.e3,1.e9,1
			zlim,'mvn_sta_ce_M',1.e3,1.e9,1

			datagap=600.
			options,'mvn_sta_ce_P4B_E',datagap=datagap
			options,'mvn_sta_ce_P4B_D',datagap=datagap
			options,'mvn_sta_ce_P4B_A',datagap=datagap
			options,'mvn_sta_ce_P4B_M',datagap=datagap
			options,'mvn_sta_ce_E',datagap=datagap
			options,'mvn_sta_ce_D',datagap=datagap
			options,'mvn_sta_ce_A',datagap=datagap
			options,'mvn_sta_ce_M',datagap=datagap
			options,'mvn_sta_ce_tot',datagap=datagap
	
			options,'mvn_sta_ce_P4B_E','spec',1
			options,'mvn_sta_ce_P4B_D','spec',1
			options,'mvn_sta_ce_P4B_A','spec',1
			options,'mvn_sta_ce_P4B_M','spec',1
			options,'mvn_sta_ce_E','spec',1
			options,'mvn_sta_ce_D','spec',1
			options,'mvn_sta_ce_A','spec',1
			options,'mvn_sta_ce_M','spec',1

			options,'mvn_sta_ce_P4B_E',ytitle='sta!CP4B-ce!C!CEnergy!CeV'
			options,'mvn_sta_ce_P4B_D',ytitle='sta!CP4B-ce!C!CTheta!Cdeg'
			options,'mvn_sta_ce_P4B_A',ytitle='sta!CP4B-ce!C!CPhi!Cdeg'
			options,'mvn_sta_ce_P4B_M',ytitle='sta!CP4B-ce!C!CMass!Camu'
			options,'mvn_sta_ce_E',ytitle='sta!Cce!C!CEnergy!CeV'
			options,'mvn_sta_ce_D',ytitle='sta!Cce!C!CTheta!Cdeg'
			options,'mvn_sta_ce_A',ytitle='sta!Cce!C!CPhi!Cdeg'
			options,'mvn_sta_ce_M',ytitle='sta!Cce!C!CMass!Camu'
			options,'mvn_sta_ce_tot',ytitle='sta!Cce!C!CCounts'
			options,'mvn_sta_ce_att',ytitle='sta!Cce!C!CAttenuator'

			options,'mvn_sta_ce_E',ztitle='eflux'
			options,'mvn_sta_ce_D',ztitle='eflux'
			options,'mvn_sta_ce_A',ztitle='eflux'
			options,'mvn_sta_ce_M',ztitle='eflux'
	endif

; CF
	if size(mvn_cf_dat,/type) eq 8 then begin

		npts = n_elements(mvn_cf_dat.time)
		mode = mvn_cf_dat.mode
		rate = mvn_cf_dat.rate
		iswp = mvn_cf_dat.swp_ind
		ieff = mvn_cf_dat.eff_ind
		iatt = mvn_cf_dat.att_ind
		mlut = mvn_cf_dat.mlut_ind
		nenergy = mvn_cf_dat.nenergy
		nbins = mvn_cf_dat.nbins
		ndef = mvn_cf_dat.ndef
		nanode = mvn_cf_dat.nanode
		nmass = mvn_cf_dat.nmass
		qf = (mvn_cf_dat.quality_flag and 128)/128 or (mvn_cf_dat.quality_flag and 64)/64

		time = (mvn_cf_dat.time + mvn_cf_dat.end_time)/2.
		data = mvn_cf_dat.data
		energy = reform(mvn_cf_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_cf_dat.mass_arr[iswp,*,0,*],2)/nenergy)
		theta = total(reform(mvn_cf_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_cf_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef
		str_element,mvn_cf_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_cf_dat.bkg
			dead = mvn_cf_dat.dead
			gf = reform(mvn_cf_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
		            mvn_cf_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
		            mvn_cf_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
		            mvn_cf_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts*nenergy*nbins)$
				#replicate(1.,nmass)
			gf = mvn_cf_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
			eff = mvn_cf_dat.eff[ieff,*,*,*]
			dt = float(mvn_cf_dat.integ_t#replicate(1.,nenergy*nbins*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/eflux)) gt 0. then print,'Error in CDF cf eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*,*]=0.
			if count gt 0 then eflux[ind,*,*,*]=0.

		store_data,'mvn_sta_cf_P4B_E',data={x:time,y:total(total(data,4),3),v:energy}
		store_data,'mvn_sta_cf_P4B_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_cf_P4B_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_cf_P4B_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_cf_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_cf_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_cf_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_cf_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_cf_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_cf_att',data={x:time,y:iatt}
		store_data,'mvn_sta_cf_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_cf_rate',data={x:time,y:rate}

			ylim,'mvn_sta_cf_tot',0,0,1
			ylim,'mvn_sta_cf_P4B_E',.1,40000.,1
			ylim,'mvn_sta_cf_P4B_D',-50,50,0
			ylim,'mvn_sta_cf_P4B_A',-180,200.,0
			ylim,'mvn_sta_cf_P4B_M',.5,100,1
			ylim,'mvn_sta_cf_E',.1,40000.,1
			ylim,'mvn_sta_cf_D',-50,50,0
			ylim,'mvn_sta_cf_A',-180,200.,0
			ylim,'mvn_sta_cf_M',.5,100,1
			ylim,'mvn_sta_cf_att',-1,4,0

			zlim,'mvn_sta_cf_P4B_E',10,1.e5,1
			zlim,'mvn_sta_cf_P4B_D',10,1.e5,1
			zlim,'mvn_sta_cf_P4B_A',10,1.e5,1
			zlim,'mvn_sta_cf_P4B_M',10,1.e5,1
			zlim,'mvn_sta_cf_E',1.e3,1.e9,1
			zlim,'mvn_sta_cf_D',1.e3,1.e9,1
			zlim,'mvn_sta_cf_A',1.e3,1.e9,1
			zlim,'mvn_sta_cf_M',1.e3,1.e9,1

			datagap=600.
			options,'mvn_sta_cf_P4B_E',datagap=datagap
			options,'mvn_sta_cf_P4B_D',datagap=datagap
			options,'mvn_sta_cf_P4B_A',datagap=datagap
			options,'mvn_sta_cf_P4B_M',datagap=datagap
			options,'mvn_sta_cf_E',datagap=datagap
			options,'mvn_sta_cf_D',datagap=datagap
			options,'mvn_sta_cf_A',datagap=datagap
			options,'mvn_sta_cf_M',datagap=datagap
			options,'mvn_sta_cf_tot',datagap=datagap
	
			options,'mvn_sta_cf_P4B_E','spec',1
			options,'mvn_sta_cf_P4B_D','spec',1
			options,'mvn_sta_cf_P4B_A','spec',1
			options,'mvn_sta_cf_P4B_M','spec',1
			options,'mvn_sta_cf_E','spec',1
			options,'mvn_sta_cf_D','spec',1
			options,'mvn_sta_cf_A','spec',1
			options,'mvn_sta_cf_M','spec',1

			options,'mvn_sta_cf_P4B_E',ytitle='sta!CP4B-cf!C!CEnergy!CeV'
			options,'mvn_sta_cf_P4B_D',ytitle='sta!CP4B-cf!C!CTheta!Cdeg'
			options,'mvn_sta_cf_P4B_A',ytitle='sta!CP4B-cf!C!CPhi!Cdeg'
			options,'mvn_sta_cf_P4B_M',ytitle='sta!CP4B-cf!C!CMass!Camu'
			options,'mvn_sta_cf_E',ytitle='sta!Ccf!C!CEnergy!CeV'
			options,'mvn_sta_cf_D',ytitle='sta!Ccf!C!CTheta!Cdeg'
			options,'mvn_sta_cf_A',ytitle='sta!Ccf!C!CPhi!Cdeg'
			options,'mvn_sta_cf_M',ytitle='sta!Ccf!C!CMass!Camu'
			options,'mvn_sta_cf_tot',ytitle='sta!Ccf!C!CCounts'
			options,'mvn_sta_cf_att',ytitle='sta!Ccf!C!CAttenuator'

			options,'mvn_sta_cf_E',ztitle='eflux'
			options,'mvn_sta_cf_D',ztitle='eflux'
			options,'mvn_sta_cf_A',ztitle='eflux'
			options,'mvn_sta_cf_M',ztitle='eflux'
	endif

; D0
	if size(mvn_d0_dat,/type) eq 8 then begin

		npts = n_elements(mvn_d0_dat.time)
		mode = mvn_d0_dat.mode
		rate = mvn_d0_dat.rate
		iswp = mvn_d0_dat.swp_ind
		ieff = mvn_d0_dat.eff_ind
		iatt = mvn_d0_dat.att_ind
		mlut = mvn_d0_dat.mlut_ind
		nenergy = mvn_d0_dat.nenergy
		nbins = mvn_d0_dat.nbins
		ndef = mvn_d0_dat.ndef
		nanode = mvn_d0_dat.nanode
		nmass = mvn_d0_dat.nmass
		qf = (mvn_d0_dat.quality_flag and 128)/128 or (mvn_d0_dat.quality_flag and 64)/64

		time = (mvn_d0_dat.time + mvn_d0_dat.end_time)/2.
		data = mvn_d0_dat.data
		energy = reform(mvn_d0_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_d0_dat.mass_arr[iswp,*,0,*],2)/nenergy)
		theta = total(reform(mvn_d0_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_d0_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef
		str_element,mvn_d0_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_d0_dat.bkg
			dead = mvn_d0_dat.dead
			gf = reform(mvn_d0_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
		            mvn_d0_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
		            mvn_d0_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
		            mvn_d0_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts*nenergy*nbins)$
				#replicate(1.,nmass)
			gf = mvn_d0_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
			eff = mvn_d0_dat.eff[ieff,*,*,*]
			dt = float(mvn_d0_dat.integ_t#replicate(1.,nenergy*nbins*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/eflux)) gt 0. then print,'Error in CDF d0 eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*,*]=0.
			if count gt 0 then eflux[ind,*,*,*]=0.

		store_data,'mvn_sta_d0_P4C_E',data={x:time,y:total(total(data,4),3),v:energy}
		store_data,'mvn_sta_d0_P4C_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d0_P4C_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d0_P4C_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_d0_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_d0_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d0_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d0_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_d0_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_d0_att',data={x:time,y:iatt}
		store_data,'mvn_sta_d0_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_d0_rate',data={x:time,y:rate}
		store_data,'mvn_sta_d0_H_E',data={x:time,y:total(total(eflux[*,*,*,4:7],4),3)/nbins,v:energy}
		store_data,'mvn_sta_d0_H_D',data={x:time,y:total(total(reform(total(eflux[*,*,*,4:7],4),npts,nenergy,ndef,nanode),4),2),v:theta}
		store_data,'mvn_sta_d0_H_A',data={x:time,y:total(total(reform(total(eflux[*,*,*,4:7],4),npts,nenergy,ndef,nanode),3),2),v:phi}
; this is for looking at pickup ions
		store_data,'mvn_sta_d0_P4C_H_D_kev',data={x:time,y:total(reform(total(total(data[*,0:9,*,4:7],4),2),npts,ndef,nanode),3),v:theta}
		store_data,'mvn_sta_d0_P4C_H_A_kev',data={x:time,y:total(reform(total(total(data[*,0:9,*,4:7],4),2),npts,ndef,nanode),2),v:phi}

			ylim,'mvn_sta_d0_tot',0,0,1
			ylim,'mvn_sta_d0_P4C_E',.1,40000.,1
			ylim,'mvn_sta_d0_P4C_D',-50,50,0
			ylim,'mvn_sta_d0_P4C_A',-180,200.,0
			ylim,'mvn_sta_d0_P4C_M',.5,100,1
			ylim,'mvn_sta_d0_E',.1,40000.,1
			ylim,'mvn_sta_d0_D',-50,50,0
			ylim,'mvn_sta_d0_A',-180,200.,0
			ylim,'mvn_sta_d0_M',.5,100,1
			ylim,'mvn_sta_d0_att',-1,4,0
			ylim,'mvn_sta_d0_H_E',.1,40000.,1
			ylim,'mvn_sta_d0_H_D',-50,50,0
			ylim,'mvn_sta_d0_H_A',-180,200.,0
			ylim,'mvn_sta_d0_P4C_H_D_kev',-50,50,0
			ylim,'mvn_sta_d0_P4C_H_A_kev',-180,200.,0

			zlim,'mvn_sta_d0_P4C_E',10,1.e5,1
			zlim,'mvn_sta_d0_P4C_D',10,1.e5,1
			zlim,'mvn_sta_d0_P4C_A',10,1.e5,1
			zlim,'mvn_sta_d0_P4C_M',10,1.e5,1
			zlim,'mvn_sta_d0_E',1.e3,1.e9,1
			zlim,'mvn_sta_d0_D',1.e3,1.e9,1
			zlim,'mvn_sta_d0_A',1.e3,1.e9,1
			zlim,'mvn_sta_d0_M',1.e3,1.e9,1
			zlim,'mvn_sta_d0_H_E',1.e3,1.e9,1
			zlim,'mvn_sta_d0_H_D',1.e3,1.e9,1
			zlim,'mvn_sta_d0_H_A',1.e3,1.e9,1
			zlim,'mvn_sta_d0_P4C_H_D_kev',1,1000,1
			zlim,'mvn_sta_d0_P4C_H_A_kev',1,1000,1

			datagap=600.
			options,'mvn_sta_d0*',datagap=datagap
;			options,'mvn_sta_d0_P4C_E',datagap=datagap
;			options,'mvn_sta_d0_P4C_D',datagap=datagap
;			options,'mvn_sta_d0_P4C_A',datagap=datagap
;			options,'mvn_sta_d0_P4C_M',datagap=datagap
;			options,'mvn_sta_d0_E',datagap=datagap
;			options,'mvn_sta_d0_D',datagap=datagap
;			options,'mvn_sta_d0_A',datagap=datagap
;			options,'mvn_sta_d0_M',datagap=datagap
;			options,'mvn_sta_d0_tot',datagap=datagap
	
			options,'mvn_sta_d0_P4C_E','spec',1
			options,'mvn_sta_d0_P4C_D','spec',1
			options,'mvn_sta_d0_P4C_A','spec',1
			options,'mvn_sta_d0_P4C_M','spec',1
			options,'mvn_sta_d0_E','spec',1
			options,'mvn_sta_d0_D','spec',1
			options,'mvn_sta_d0_A','spec',1
			options,'mvn_sta_d0_M','spec',1
			options,'mvn_sta_d0_H_E','spec',1
			options,'mvn_sta_d0_H_D','spec',1
			options,'mvn_sta_d0_H_A','spec',1
			options,'mvn_sta_d0_P4C_H_D_kev','spec',1
			options,'mvn_sta_d0_P4C_H_A_kev','spec',1

			options,'mvn_sta_d0_P4C_E',ytitle='sta!CP4C-d0!C!CEnergy!CeV'
			options,'mvn_sta_d0_P4C_D',ytitle='sta!CP4C-d0!C!CTheta!Cdeg'
			options,'mvn_sta_d0_P4C_A',ytitle='sta!CP4C-d0!C!CPhi!Cdeg'
			options,'mvn_sta_d0_P4C_M',ytitle='sta!CP4C-d0!C!CMass!Camu'
			options,'mvn_sta_d0_E',ytitle='sta!Cd0!C!CEnergy!CeV'
			options,'mvn_sta_d0_D',ytitle='sta!Cd0!C!CTheta!Cdeg'
			options,'mvn_sta_d0_A',ytitle='sta!Cd0!C!CPhi!Cdeg'
			options,'mvn_sta_d0_M',ytitle='sta!Cd0!C!CMass!Camu'
			options,'mvn_sta_d0_tot',ytitle='sta!Cd0!C!CCounts'
			options,'mvn_sta_d0_att',ytitle='sta!Cd0!C!CAttenuator'
			options,'mvn_sta_d0_H_E',ytitle='sta!Cd0!C!CEnergy!CeV'
			options,'mvn_sta_d0_H_D',ytitle='sta!Cd0!C!CTheta!Cdeg'
			options,'mvn_sta_d0_H_A',ytitle='sta!Cd0!C!CPhi!Cdeg'
			options,'mvn_sta_d0_P4C_H_D_kev',ytitle='sta d0!C>1keV!CO+ O2+!CTheta!Cdeg'
			options,'mvn_sta_d0_P4C_H_A_kev',ytitle='sta d0!C>1keV!CO+ O2+!CPhi!Cdeg'

			options,'mvn_sta_d0_E',ztitle='eflux'
			options,'mvn_sta_d0_D',ztitle='eflux'
			options,'mvn_sta_d0_A',ztitle='eflux'
			options,'mvn_sta_d0_M',ztitle='eflux'
			options,'mvn_sta_d0_H_E',ztitle='eflux'
			options,'mvn_sta_d0_H_D',ztitle='eflux'
			options,'mvn_sta_d0_H_A',ztitle='eflux'
			options,'mvn_sta_d0_P4C_H_D_kev',ztitle='counts'
			options,'mvn_sta_d0_P4C_H_A_kev',ztitle='counts'

	endif

; D1
	if size(mvn_d1_dat,/type) eq 8 then begin

		npts = n_elements(mvn_d1_dat.time)
		mode = mvn_d1_dat.mode
		rate = mvn_d1_dat.rate
		iswp = mvn_d1_dat.swp_ind
		ieff = mvn_d1_dat.eff_ind
		iatt = mvn_d1_dat.att_ind
		mlut = mvn_d1_dat.mlut_ind
		nenergy = mvn_d1_dat.nenergy
		nbins = mvn_d1_dat.nbins
		ndef = mvn_d1_dat.ndef
		nanode = mvn_d1_dat.nanode
		nmass = mvn_d1_dat.nmass
		qf = (mvn_d1_dat.quality_flag and 128)/128 or (mvn_d1_dat.quality_flag and 64)/64

		time = (mvn_d1_dat.time + mvn_d1_dat.end_time)/2.
		data = mvn_d1_dat.data
		energy = reform(mvn_d1_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_d1_dat.mass_arr[iswp,*,0,*],2)/nenergy)
		theta = total(reform(mvn_d1_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_d1_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef
		str_element,mvn_d1_dat,'eflux',eflux,success=success

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_d1_dat.bkg
			dead = mvn_d1_dat.dead
			gf = reform(mvn_d1_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nenergy*nbins)) +$
		            mvn_d1_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nenergy*nbins)) +$
		            mvn_d1_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nenergy*nbins)) +$
		            mvn_d1_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nenergy*nbins)), npts*nenergy*nbins)$
				#replicate(1.,nmass)
			gf = mvn_d1_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
			eff = mvn_d1_dat.eff[ieff,*,*,*]
			dt = float(mvn_d1_dat.integ_t#replicate(1.,nenergy*nbins*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/eflux)) gt 0. then print,'Error in CDF d1 eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*,*]=0.
			if count gt 0 then eflux[ind,*,*,*]=0.

		store_data,'mvn_sta_d1_P4C_E',data={x:time,y:total(total(data,4),3),v:energy}
		store_data,'mvn_sta_d1_P4C_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d1_P4C_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d1_P4C_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_d1_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_d1_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d1_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d1_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_d1_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_d1_att',data={x:time,y:iatt}
		store_data,'mvn_sta_d1_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_d1_rate',data={x:time,y:rate}

			ylim,'mvn_sta_d1_tot',0,0,1
			ylim,'mvn_sta_d1_P4C_E',.1,40000.,1
			ylim,'mvn_sta_d1_P4C_D',-50,50,0
			ylim,'mvn_sta_d1_P4C_A',-180,200.,0
			ylim,'mvn_sta_d1_P4C_M',.5,100,1
			ylim,'mvn_sta_d1_E',.1,40000.,1
			ylim,'mvn_sta_d1_D',-50,50,0
			ylim,'mvn_sta_d1_A',-180,200.,0
			ylim,'mvn_sta_d1_M',.5,100,1
			ylim,'mvn_sta_d1_att',-1,4,0

			zlim,'mvn_sta_d1_P4C_E',10,1.e5,1
			zlim,'mvn_sta_d1_P4C_D',10,1.e5,1
			zlim,'mvn_sta_d1_P4C_A',10,1.e5,1
			zlim,'mvn_sta_d1_P4C_M',10,1.e5,1
			zlim,'mvn_sta_d1_E',1.e3,1.e9,1
			zlim,'mvn_sta_d1_D',1.e3,1.e9,1
			zlim,'mvn_sta_d1_A',1.e3,1.e9,1
			zlim,'mvn_sta_d1_M',1.e3,1.e9,1

			datagap=600.
			options,'mvn_sta_d1_P4C_E',datagap=datagap
			options,'mvn_sta_d1_P4C_D',datagap=datagap
			options,'mvn_sta_d1_P4C_A',datagap=datagap
			options,'mvn_sta_d1_P4C_M',datagap=datagap
			options,'mvn_sta_d1_E',datagap=datagap
			options,'mvn_sta_d1_D',datagap=datagap
			options,'mvn_sta_d1_A',datagap=datagap
			options,'mvn_sta_d1_M',datagap=datagap
			options,'mvn_sta_d1_tot',datagap=datagap
	
			options,'mvn_sta_d1_P4C_E','spec',1
			options,'mvn_sta_d1_P4C_D','spec',1
			options,'mvn_sta_d1_P4C_A','spec',1
			options,'mvn_sta_d1_P4C_M','spec',1
			options,'mvn_sta_d1_E','spec',1
			options,'mvn_sta_d1_D','spec',1
			options,'mvn_sta_d1_A','spec',1
			options,'mvn_sta_d1_M','spec',1

			options,'mvn_sta_d1_P4C_E',ytitle='sta!CP4C-d1!C!CEnergy!CeV'
			options,'mvn_sta_d1_P4C_D',ytitle='sta!CP4C-d1!C!CTheta!Cdeg'
			options,'mvn_sta_d1_P4C_A',ytitle='sta!CP4C-d1!C!CPhi!Cdeg'
			options,'mvn_sta_d1_P4C_M',ytitle='sta!CP4C-d1!C!CMass!Camu'
			options,'mvn_sta_d1_E',ytitle='sta!Cd1!C!CEnergy!CeV'
			options,'mvn_sta_d1_D',ytitle='sta!Cd1!C!CTheta!Cdeg'
			options,'mvn_sta_d1_A',ytitle='sta!Cd1!C!CPhi!Cdeg'
			options,'mvn_sta_d1_M',ytitle='sta!Cd1!C!CMass!Camu'
			options,'mvn_sta_d1_tot',ytitle='sta!Cd1!C!CCounts'
			options,'mvn_sta_d1_att',ytitle='sta!Cd1!C!CAttenuator'

			options,'mvn_sta_d1_E',ztitle='eflux'
			options,'mvn_sta_d1_D',ztitle='eflux'
			options,'mvn_sta_d1_A',ztitle='eflux'
			options,'mvn_sta_d1_M',ztitle='eflux'
	endif

; D4
	if size(mvn_d4_dat,/type) eq 8 then begin

		npts = n_elements(mvn_d4_dat.time)
		mode = mvn_d4_dat.mode
		rate = mvn_d4_dat.rate
		iswp = mvn_d4_dat.swp_ind
		ieff = mvn_d4_dat.eff_ind
		iatt = mvn_d4_dat.att_ind
		mlut = mvn_d4_dat.mlut_ind
		nenergy = mvn_d4_dat.nenergy
		nbins = mvn_d4_dat.nbins
		ndef = mvn_d4_dat.ndef
		nanode = mvn_d4_dat.nanode
		nmass = mvn_d4_dat.nmass
		qf = (mvn_d4_dat.quality_flag and 128)/128 or (mvn_d4_dat.quality_flag and 64)/64

		time = (mvn_d4_dat.time + mvn_d4_dat.end_time)/2.
		data = mvn_d4_dat.data
		mass = reform(total(mvn_d4_dat.mass_arr[iswp,*,0,*],2)/nenergy)
		theta = total(reform(mvn_d4_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_d4_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef
		str_element,mvn_d4_dat,'eflux',eflux,success=success
;		eflux = mvn_d4_dat.eflux

;		this section needed because eflux in the CDFs got screwed up
			bkg = mvn_d4_dat.bkg
			dead = mvn_d4_dat.dead
			gf = reform(mvn_d4_dat.gf[iswp,*,*,0]*((iatt eq 0)#replicate(1.,nbins)) +$
		            mvn_d4_dat.gf[iswp,*,*,1]*((iatt eq 1)#replicate(1.,nbins)) +$
		            mvn_d4_dat.gf[iswp,*,*,2]*((iatt eq 2)#replicate(1.,nbins)) +$
		            mvn_d4_dat.gf[iswp,*,*,3]*((iatt eq 3)#replicate(1.,nbins)), npts*nbins)$
				#replicate(1.,nmass)
			gf = mvn_d4_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
			eff = mvn_d4_dat.eff[ieff,*,*,*]
			dt = float(mvn_d4_dat.integ_t#replicate(1.,nenergy*nbins*nmass))
			eflux2 = (data-bkg)*dead/(gf*eff*dt)
			if success and keyword_set(test) then if max(abs((eflux-eflux2)/eflux)) gt 0. then print,'Error in CDF d4 eflux ',max(abs((eflux-eflux2)/(eflux>.01)))
			if not success or keyword_set(replace) then eflux = eflux2
			ind = where(qf eq 1,count)
			if count gt 0 then data[ind,*,*,*]=0.
			if count gt 0 then eflux[ind,*,*,*]=0.

		store_data,'mvn_sta_d4_P4E_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d4_P4E_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d4_P4E_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_d4_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2)/nanode,v:theta}
		store_data,'mvn_sta_d4_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2)/ndef,v:phi}
		store_data,'mvn_sta_d4_H_A',data={x:time,y:total(total(reform(eflux[*,*,*,1],npts,nenergy,ndef,nanode),3),2)/ndef,v:phi}
		store_data,'mvn_sta_d4_L_A',data={x:time,y:total(total(reform(eflux[*,*,*,0],npts,nenergy,ndef,nanode),3),2)/ndef,v:phi}
		store_data,'mvn_sta_d4_H_D',data={x:time,y:total(total(reform(eflux[*,*,*,1],npts,nenergy,ndef,nanode),4),2)/nanode,v:theta}
		store_data,'mvn_sta_d4_L_D',data={x:time,y:total(total(reform(eflux[*,*,*,0],npts,nenergy,ndef,nanode),4),2)/nanode,v:theta}
		store_data,'mvn_sta_d4_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_d4_tot',data={x:time,y:total(total(data,4),3)}
		store_data,'mvn_sta_d4_att',data={x:time,y:iatt}
		store_data,'mvn_sta_d4_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_d4_rate',data={x:time,y:rate}

			ylim,'mvn_sta_d4_tot',0,0,1
			ylim,'mvn_sta_d4_P4E_D',-50,50,0
			ylim,'mvn_sta_d4_P4E_A',-180,200.,0
			ylim,'mvn_sta_d4_P4E_M',.5,100,1
			ylim,'mvn_sta_d4_D',-50,50,0
			ylim,'mvn_sta_d4_A',-180,200.,0
			ylim,'mvn_sta_d4_H_A',-180,200.,0
			ylim,'mvn_sta_d4_L_A',-180,200.,0
			ylim,'mvn_sta_d4_H_D',-50,50.,0
			ylim,'mvn_sta_d4_L_D',-50,50.,0
			ylim,'mvn_sta_d4_M',.5,100,1
			ylim,'mvn_sta_d4_att',-1,4,0

			zlim,'mvn_sta_d4_P4E_D',10,1.e5,1
			zlim,'mvn_sta_d4_P4E_A',10,1.e5,1
			zlim,'mvn_sta_d4_P4E_M',10,1.e5,1
			zlim,'mvn_sta_d4_D',1.e3,1.e9,1
			zlim,'mvn_sta_d4_A',1.e3,1.e9,1
			zlim,'mvn_sta_d4_H_A',1.e3,1.e9,1
			zlim,'mvn_sta_d4_L_A',1.e3,1.e9,1
			zlim,'mvn_sta_d4_H_D',1.e3,1.e9,1
			zlim,'mvn_sta_d4_L_D',1.e3,1.e9,1
			zlim,'mvn_sta_d4_M',1.e3,1.e9,1

			datagap=7.
			options,'mvn_sta_d4_P4E_D',datagap=datagap
			options,'mvn_sta_d4_P4E_A',datagap=datagap
			options,'mvn_sta_d4_P4E_M',datagap=datagap
			options,'mvn_sta_d4_D',datagap=datagap
			options,'mvn_sta_d4_A',datagap=datagap
			options,'mvn_sta_d4_H_A',datagap=datagap
			options,'mvn_sta_d4_L_A',datagap=datagap
			options,'mvn_sta_d4_H_D',datagap=datagap
			options,'mvn_sta_d4_L_D',datagap=datagap
			options,'mvn_sta_d4_M',datagap=datagap
			options,'mvn_sta_d4_tot',datagap=datagap
	
			options,'mvn_sta_d4_P4E_D','spec',1
			options,'mvn_sta_d4_P4E_A','spec',1
			options,'mvn_sta_d4_P4E_M','spec',1
			options,'mvn_sta_d4_D','spec',1
			options,'mvn_sta_d4_A','spec',1
			options,'mvn_sta_d4_H_A','spec',1
			options,'mvn_sta_d4_L_A','spec',1
			options,'mvn_sta_d4_H_D','spec',1
			options,'mvn_sta_d4_L_D','spec',1
			options,'mvn_sta_d4_M','spec',1

			options,'mvn_sta_d4_P4E_D',ytitle='sta!CP4E-d4!C!CTheta!Cdeg'
			options,'mvn_sta_d4_P4E_A',ytitle='sta!CP4E-d4!C!CPhi!Cdeg'
			options,'mvn_sta_d4_P4E_M',ytitle='sta!CP4E-d4!C!CMass!Camu'
			options,'mvn_sta_d4_D',ytitle='sta!Cd4!C!CTheta!Cdeg'
			options,'mvn_sta_d4_A',ytitle='sta!Cd4!C!CPhi!Cdeg'
			options,'mvn_sta_d4_H_A',ytitle='sta!Cd4!CM>12!CPhi!Cdeg'
			options,'mvn_sta_d4_L_A',ytitle='sta!Cd4!CM<12!CPhi!Cdeg'
			options,'mvn_sta_d4_H_D',ytitle='sta!Cd4!CM>12!CPhi!Cdeg'
			options,'mvn_sta_d4_L_D',ytitle='sta!Cd4!CM<12!CPhi!Cdeg'
			options,'mvn_sta_d4_M',ytitle='sta!Cd4!C!CMass!Camu'
			options,'mvn_sta_d4_tot',ytitle='sta!Cd4!C!CCounts'
			options,'mvn_sta_d4_att',ytitle='sta!Cd4!C!CAttenuator'

			options,'mvn_sta_d4_D',ztitle='eflux'
			options,'mvn_sta_d4_A',ztitle='eflux'
			options,'mvn_sta_d4_H_A',ztitle='eflux'
			options,'mvn_sta_d4_L_A',ztitle='eflux'
			options,'mvn_sta_d4_H_D',ztitle='eflux'
			options,'mvn_sta_d4_L_D',ztitle='eflux'
			options,'mvn_sta_d4_M',ztitle='eflux'
	endif

; D6
	if size(mvn_d6_dat,/type) eq 8 and keyword_set(test) then begin

		time = mvn_d6_dat.time

		tdc_1 = mvn_d6_dat.tdc_1	
		tdc_2 = mvn_d6_dat.tdc_2	
		tdc_3 = mvn_d6_dat.tdc_3	
		tdc_4 = mvn_d6_dat.tdc_4	
		event_code = mvn_d6_dat.event_code 
		cyclestep = mvn_d6_dat.cyclestep
		energy = mvn_d6_dat.energy

			ev1 = (event_code and 1)
			ev2 = (event_code and 2)
			ev3 = (event_code and 4)/4*3
			ev4 = (event_code and 8)/8*4
			ev5 = (event_code and 16)/16*5
			ev6 = (event_code and 32)/32*6
			ev_cd = [[ev1],[ev2],[ev3],[ev4],[ev5],[ev6]]
		store_data,'mvn_sta_d6_tdc1',data={x:time,y:tdc_1+1}
		store_data,'mvn_sta_d6_tdc2',data={x:time,y:tdc_2+1}
		store_data,'mvn_sta_d6_tdc3',data={x:time,y:tdc_3*(-2*ev1+1)}
		store_data,'mvn_sta_d6_tdc4',data={x:time,y:tdc_4*(-ev2+1)}
		store_data,'mvn_sta_d6_ev',data={x:time,y:ev_cd,v:[1,2,3,4,5,6]}
		store_data,'mvn_sta_d6_cy',data={x:time,y:cyclestep}
		store_data,'mvn_sta_d6_en',data={x:time,y:energy}

		ylim,'mvn_sta_d6_tdc1',.5,1024,1
		ylim,'mvn_sta_d6_tdc2',.5,1024,1
		ylim,'mvn_sta_d6_tdc3',-530,530,0
		ylim,'mvn_sta_d6_tdc4',-530,530,0
		ylim,'mvn_sta_d6_ev',-1,7,0
		ylim,'mvn_sta_d6_cy',-1,1024,0
		ylim,'mvn_sta_d6_en',.1,30000.,1
		options,'mvn_sta_d6_tdc1',psym=3
		options,'mvn_sta_d6_tdc2',psym=3
		options,'mvn_sta_d6_tdc3',psym=3
		options,'mvn_sta_d6_tdc4',psym=3
		options,'mvn_sta_d6_ev',psym=3
		options,'mvn_sta_d6_cy',psym=3
		options,'mvn_sta_d6_en',psym=3

	endif

; D7
	if size(mvn_d7_dat,/type) eq 8 and keyword_set(test) then begin

		time = mvn_d7_dat.time
		store_data,'mvn_sta_d7_data',data={x:time,y:1.*mvn_d7_dat.hkp_raw}
		store_data,'mvn_sta_d7_data_cal',data={x:time,y:mvn_d7_dat.hkp_calib}
		store_data,'mvn_sta_d7_data_mux',data={x:time,y:mvn_d7_dat.hkp_ind}
			options,'mvn_sta_d7_data_cal',datagap=1.
			options,'mvn_sta_d7_data_mux',datagap=1.
			options,'mvn_sta_d7_data',datagap=1.

	endif

; D8
	if size(mvn_d8_dat,/type) eq 8 and keyword_set(test) then begin

		time = (mvn_d8_dat.time + mvn_d8_dat.end_time)/2.
		data = mvn_d8_dat.rates

		store_data,'mvn_sta_d8_R1_tot',data={x:time,y:data[*,4]*4.}
		store_data,'mvn_sta_d8_R1_hz',data={x:time,y:data[*,4]}

		store_data,'mvn_sta_d8_R1_ABCD',data={x:time,y:data[*,0:3]}
		store_data,'mvn_sta_d8_R1_RST',data={x:time,y:data[*,4]}
		store_data,'mvn_sta_d8_R1_NoStart',data={x:time,y:data[*,5]}
		store_data,'mvn_sta_d8_R1_Unqual',data={x:time,y:data[*,6]}
		store_data,'mvn_sta_d8_R1_Qual',data={x:time,y:data[*,7]}
		store_data,'mvn_sta_d8_R1_AnRej',data={x:time,y:data[*,8]}
		store_data,'mvn_sta_d8_R1_MaRej',data={x:time,y:data[*,9]}
		store_data,'mvn_sta_d8_R1_A&B',data={x:time,y:data[*,10]}
		store_data,'mvn_sta_d8_R1_C&D',data={x:time,y:data[*,11]}

		store_data,'mvn_sta_d8_R1_eff_start',data={x:time,y:data[*,7]/data[*,11]}
		store_data,'mvn_sta_d8_R1_eff_stop',data={x:time,y:data[*,7]/data[*,10]}
		store_data,'mvn_sta_d8_R1_eff',data={x:time,y:data[*,7]*data[*,7]/data[*,11]/data[*,10]}
		store_data,'mvn_sta_d8_R1_eff_all',data=['mvn_sta_d8_R1_eff_start','mvn_sta_d8_R1_eff_stop','mvn_sta_d8_R1_eff']

			ylim,'mvn_sta_d8*',100,1.e5,1
			ylim,'mvn_sta_d8_R1_eff*',.01,1.1,1

			options,'mvn_sta_d8*',datagap=7.

			options,'mvn_sta_d8_R1_tot',ytitle='sta!Cd8!C!CCounts'
			options,'mvn_sta_d8_R1_hz',ytitle='sta!Cd8!C!CRate!CHz'

			options,'mvn_sta_d8_R1_ABCD',ytitle='sta!Cd8!C!CABCD!CHz'
			options,'mvn_sta_d8_R1_RST',ytitle='sta!Cd8!C!CRst!CHz'
			options,'mvn_sta_d8_R1_NoStart',ytitle='sta!Cd8!C!CNoStart!CHz'
			options,'mvn_sta_d8_R1_Unqual',ytitle='sta!Cd8!C!CUnQual!CHz'
			options,'mvn_sta_d8_R1_Qual',ytitle='sta!Cd8!C!CQual!CHz'
			options,'mvn_sta_d8_R1_AnRej',ytitle='sta!Cd8!C!CAnRej!CHz'
			options,'mvn_sta_d8_R1_MaRej',ytitle='sta!Cd8!C!CMaRej!CHz'
			options,'mvn_sta_d8_R1_A&B',ytitle='sta!Cd8!C!CA&B!CHz'
			options,'mvn_sta_d8_R1_C&D',ytitle='sta!Cd8!C!CC&D!CHz'

			options,'mvn_sta_d8_R1_eff_start',ytitle='sta!Cd8!C!CEff!CStart'
			options,'mvn_sta_d8_R1_eff_stop',ytitle='sta!Cd8!C!CEff!CStop'
			options,'mvn_sta_d8_R1_eff',ytitle='sta!Cd8!C!CEff'
			options,'mvn_sta_d8_R1_eff_all',ytitle='sta!Cd8!C!CEff'

			options,'mvn_sta_d8_R1_ABCD','colors',[cols.blue,cols.green,cols.yellow,cols.red]
			options,'mvn_sta_d8_R1_eff_start',colors=cols.green
			options,'mvn_sta_d8_R1_eff_stop',colors=cols.red

	endif

; D9
	if size(mvn_d9_dat,/type) eq 8 and keyword_set(test) then begin

		iswp = mvn_d9_dat.swp_ind

		time = (mvn_d9_dat.time + mvn_d9_dat.end_time)/2.
		delta_time = mvn_d9_dat.integ_t*64.
		energy = reform(mvn_d9_dat.energy[iswp,*])
		data = mvn_d9_dat.rates	
		npts = n_elements(time)

		peak_start_eff=fltarr(npts)
		peak_stop_eff=fltarr(npts)
		peak_eff=fltarr(npts)
		for jj=0l,npts-1 do begin
			dd = data[jj,4,*]/mvn_d9_dat.integ_t[jj]
			ind = where(dd gt 10000.,count)
			if count gt 0 then dd[ind]=0.
			max_en = max(dd,ind1)
			min_en = min(data[jj,4,*],ind2)
			peak_start_eff[jj]=(data[jj,7,ind1])/(data[jj,11,ind1]-data[jj,11,ind2])
			peak_stop_eff[jj]=(data[jj,7,ind1])/(data[jj,10,ind1]-data[jj,10,ind2])
			peak_eff[jj]=(data[jj,7,ind1])^2/(data[jj,10,ind1]-data[jj,10,ind2])/(data[jj,11,ind1]-data[jj,11,ind2])
		endfor					

		store_data,'mvn_sta_d9_R2',data={x:time,y:reform(data[*,4,*]),v:indgen(64)}
		store_data,'mvn_sta_d9_R2_E',data={x:time,y:reform(data[*,4,*]),v:energy}
		store_data,'mvn_sta_d9_R2_tot',data={x:time,y:total(reform(data[*,4,*]),2)/64*delta_time}
		store_data,'mvn_sta_d9_R2_hz',data={x:time,y:total(reform(data[*,4,*]),2)/64}

		store_data,'mvn_sta_d9_R2_ABCD',data={x:time,y:total(data[*,0:3,*],3)/64}
		store_data,'mvn_sta_d9_R2_RST',data={x:time,y:total(data[*,4,*],3)/64}
		store_data,'mvn_sta_d9_R2_NoStart',data={x:time,y:total(data[*,5,*],3)/64}
		store_data,'mvn_sta_d9_R2_Unqual',data={x:time,y:total(data[*,6,*],3)/64}
		store_data,'mvn_sta_d9_R2_Qual',data={x:time,y:total(data[*,7,*],3)/64}
		store_data,'mvn_sta_d9_R2_AnRej',data={x:time,y:total(data[*,8,*],3)/64}
		store_data,'mvn_sta_d9_R2_MaRej',data={x:time,y:total(data[*,9,*],3)/64}
		store_data,'mvn_sta_d9_R2_A&B',data={x:time,y:total(data[*,10,*],3)/64}
		store_data,'mvn_sta_d9_R2_C&D',data={x:time,y:total(data[*,11,*],3)/64}

		store_data,'mvn_sta_d9_R2_eff_start',data={x:time,y:total(data[*,7,*],3)/total(data[*,11,*],3)}
		store_data,'mvn_sta_d9_R2_eff_stop',data={x:time,y:total(data[*,7,*],3)/total(data[*,10,*],3)}
		store_data,'mvn_sta_d9_R2_eff',data={x:time,y:total(data[*,7,*],3)^2/total(data[*,11,*],3)/total(data[*,10,*],3)}
		store_data,'mvn_sta_d9_R2_eff_all',data=['mvn_sta_d9_R2_eff_start','mvn_sta_d9_R2_eff_stop','mvn_sta_d9_R2_eff']

		store_data,'mvn_sta_d9_R2_eff_peak_start',data={x:time,y:peak_start_eff}
		store_data,'mvn_sta_d9_R2_eff_peak_stop',data={x:time,y:peak_stop_eff}
		store_data,'mvn_sta_d9_R2_eff_peak',data={x:time,y:peak_eff}
		store_data,'mvn_sta_d9_R2_eff_peak_all',data=['mvn_sta_d9_R2_eff_peak_start','mvn_sta_d9_R2_eff_peak_stop','mvn_sta_d9_R2_eff_peak']

			ylim,'mvn_sta_d9_R2*',100,1.e5,1
			ylim,'mvn_sta_d9_R2_eff*',.1,1.0,1
			ylim,'mvn_sta_d9_R2',-1,64,0
			ylim,'mvn_sta_d9_R2_E',.5,30000.,1
			ylim,'mvn_sta_d9_R2_tot',1.e4,1.e7,1
			ylim,'mvn_sta_d9_R2_hz',1.e2,1.e5,1

			zlim,'mvn_sta_d9_R2',100.,1.e5,1	
			zlim,'mvn_sta_d9_R2_E',100.,1.e5,1

			options,'mvn_sta_d9_R2*',datagap=150.
	
			options,'mvn_sta_d9_R2','spec',1
			options,'mvn_sta_d9_R2_E','spec',1

			options,'mvn_sta_d9_R2',ytitle='sta!Cd9!C!CEnergy!Cbin'
			options,'mvn_sta_d9_R2_E',ytitle='sta!Cd9!C!CEnergy!CeV'
			options,'mvn_sta_d9_R2_tot',ytitle='sta!Cd9!C!CCounts'
			options,'mvn_sta_d9_R2_hz',ytitle='sta!Cd9!C!CRate!CHz'

			options,'mvn_sta_d9_R2',ztitle='rate'
			options,'mvn_sta_d9_R2_E',ztitle='rate'

			options,'mvn_sta_d9_R2_ABCD',ytitle='sta!Cd9!C!CABCD!CHz'
			options,'mvn_sta_d9_R2_RST',ytitle='sta!Cd9!C!CRst!CHz'
			options,'mvn_sta_d9_R2_NoStart',ytitle='sta!Cd9!C!CNoStart!CHz'
			options,'mvn_sta_d9_R2_Unqual',ytitle='sta!Cd9!C!CUnQual!CHz'
			options,'mvn_sta_d9_R2_Qual',ytitle='sta!Cd9!C!CQual!CHz'
			options,'mvn_sta_d9_R2_AnRej',ytitle='sta!Cd9!C!CAnRej!CHz'
			options,'mvn_sta_d9_R2_MaRej',ytitle='sta!Cd9!C!CMaRej!CHz'
			options,'mvn_sta_d9_R2_A&B',ytitle='sta!Cd9!C!CA&B!CHz'
			options,'mvn_sta_d9_R2_C&D',ytitle='sta!Cd9!C!CC&D!CHz'

			options,'mvn_sta_d9_R2_eff_start',ytitle='sta!Cd9!C!CEff!CStart'
			options,'mvn_sta_d9_R2_eff_stop',ytitle='sta!Cd9!C!CEff!CStop'
			options,'mvn_sta_d9_R2_eff',ytitle='sta!Cd9!C!CEff'
			options,'mvn_sta_d9_R2_eff_all',ytitle='sta!Cd9!C!CEff'
			options,'mvn_sta_d9_R2_eff_peak_start',ytitle='sta!Cd9!C!CPeak Eff!CStart'
			options,'mvn_sta_d9_R2_eff_peak_stop',ytitle='sta!Cd9!C!CPeak Eff!CStop'
			options,'mvn_sta_d9_R2_eff_peak',ytitle='sta!Cd9!C!CEff'
			options,'mvn_sta_d9_R2_eff_peak_all',ytitle='sta!Cd9!C!CPeak Eff'

			options,'mvn_sta_d9_R2_ABCD','colors',[cols.blue,cols.green,cols.yellow,cols.red]
			options,'mvn_sta_d9_R2_eff_start',colors=cols.green
			options,'mvn_sta_d9_R2_eff_stop',colors=cols.red
			options,'mvn_sta_d9_R2_ABCD','colors',[cols.blue,cols.green,cols.yellow,cols.red]
			options,'mvn_sta_d9_R2_eff_peak_start',colors=cols.green
			options,'mvn_sta_d9_R2_eff_peak_stop',colors=cols.red

	endif

; DA
	if size(mvn_da_dat,/type) eq 8 and keyword_set(test) then begin

		iswp = mvn_da_dat.swp_ind

		time = (mvn_da_dat.time + mvn_da_dat.end_time)/2.
		energy = reform(mvn_da_dat.energy[iswp,*])
		data = mvn_da_dat.rates	

		store_data,'mvn_sta_da_R3',data={x:time,y:data,v:indgen(64)}
		store_data,'mvn_sta_da_R3_E',data={x:time,y:data,v:energy}
		store_data,'mvn_sta_da_R3_tot',data={x:time,y:total(data,2)/16}
		store_data,'mvn_sta_da_R3_hz',data={x:time,y:total(data,2)/64}

			ylim,'mvn_sta_da_R3',-1,64,0
			ylim,'mvn_sta_da_R3_E',.1,40000.,1
			ylim,'mvn_sta_da_R3_tot',100,1.e5,1
			ylim,'mvn_sta_da_R3_hz',100,1.e5,1

			zlim,'mvn_sta_da_R3',100.,1.e5,1	
			zlim,'mvn_sta_da_R3_E',100.,1.e5,1

			options,'mvn_sta_da_*',datagap=7.
	
			options,'mvn_sta_da_R3','spec',1
			options,'mvn_sta_da_R3_E','spec',1

			options,'mvn_sta_da_R3',ytitle='sta!Cda!C!CEnergy!Cbin'
			options,'mvn_sta_da_R3_E',ytitle='sta!Cda!C!CEnergy!CeV'
			options,'mvn_sta_da_R3_tot',ytitle='sta!Cda!C!CCounts'
			options,'mvn_sta_da_R3_hz',ytitle='sta!Cda!C!CRate!CHz'

			options,'mvn_sta_da_R3',ztitle='rate'
			options,'mvn_sta_da_R3_E',ztitle='rate'

	endif

; DB
	if size(mvn_db_dat,/type) eq 8 then begin

		npts = n_elements(mvn_db_dat.time)
		mode = mvn_db_dat.mode
		rate = mvn_db_dat.rate
		iswp = mvn_db_dat.swp_ind
		tof = mvn_db_dat.tof

		time = (mvn_db_dat.time + mvn_db_dat.end_time)/2.
		data = mvn_db_dat.data
		energy = reform(mvn_db_dat.energy[iswp,*])
		erange = [energy[63],energy[0]]

		dt = float(mvn_db_dat.integ_t)

		store_data,'mvn_sta_db',data={x:time,y:data,v:indgen(1024)}
		store_data,'mvn_sta_db_tof',data={x:time,y:data,v:tof}

		store_data,'mvn_sta_db_tot',data={x:time,y:total(data,2)}
		store_data,'mvn_sta_db_mode',data={x:time,y:mode}
			if keyword_set(test) then store_data,'mvn_sta_db_rate',data={x:time,y:rate}

			ylim,'mvn_sta_db_tot',.1,10000,1
			ylim,'mvn_sta_db',.5,1000,1
			ylim,'mvn_sta_db_tof',0,100,0

			zlim,'mvn_sta_db',1.,1.e4,1
			zlim,'mvn_sta_db_tof',1.,1.e4,1

			datagap=150.
			options,'mvn_sta_db',datagap=datagap
			options,'mvn_sta_db_tof',datagap=datagap
			options,'mvn_sta_db_tot',datagap=datagap
	
			options,'mvn_sta_db','spec',1
			options,'mvn_sta_db_tof','spec',1

			options,'mvn_sta_db',ytitle='sta!Cdb!C!CTOF!Cbin'
			options,'mvn_sta_db_tof',ytitle='sta!Cdb!C!CTOF!Cns'
			options,'mvn_sta_db_tot',ytitle='sta!Cdb!C!CCounts'

			options,'mvn_sta_db',ztitle='counts'
			options,'mvn_sta_db_tof',ztitle='counts'
	endif

; General

	options,'mvn_sta*',no_interp=1
	ylim,'*mode',-1,8,0
	ylim,'*rate',-1,7,0


;***************************************************************************************************************
;***************************************************************************************************************

; form combined plots

	get_data,'mvn_sta_d8_R1_Qual',data=tmp1
	get_data,'mvn_sta_c6_tot',data=tmp2
	if (size(tmp1,/type) eq 8) and (size(tmp2,/type) eq 8) then begin
		d8 = interp(tmp2.y,tmp2.x,tmp1.x)
		store_data,'mvn_sta_fq_eff',data={x:tmp1.x,y:d8/(4.*tmp1.y+.001)}
		ylim,'mvn_sta_fq_eff',.1,1.1,1
	endif


;   Mixed product plots

	tt1=0 & tt2=0 & tt3=0
	get_data,'mvn_sta_ca_P3_A',data=t1
	get_data,'mvn_sta_d4_P4E_A',data=t2
	get_data,'mvn_sta_d2_P4D_A',data=t3
	if size(/type,t1) eq 8 then tt1=1
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if (tt1) then store_data,'mvn_sta_A',data=['mvn_sta_ca_P3_A'] 
	if (tt2) then store_data,'mvn_sta_A',data=['mvn_sta_d4_P4E_A']
	if (tt3) then store_data,'mvn_sta_A',data=['mvn_sta_d2_P4D_A'] 
	if (tt1 and tt2) then store_data,'mvn_sta_A',data=['mvn_sta_ca_P3_A','mvn_sta_d4_P4E_A']
	if (tt1 and tt3) then store_data,'mvn_sta_A',data=['mvn_sta_ca_P3_A','mvn_sta_d2_P4D_A']
	if (tt2 and tt3) then store_data,'mvn_sta_A',data=['mvn_sta_d4_P4E_A','mvn_sta_d2_P4D_A']
	if (tt1 and tt2 and tt3) then store_data,'mvn_sta_A',data=['mvn_sta_ca_P3_A','mvn_sta_d4_P4E_A','mvn_sta_d2_P4D_A']
		ylim,'mvn_sta_A',-180,200,0
		zlim,'mvn_sta_A',1,1.e4,1
		options,'mvn_sta_A','spec',1
		options,'mvn_sta_A',ytitle='sta!C!CAnode!Cphi'

	tt1=0 & tt2=0 
	get_data,'mvn_sta_c8_P2_D',data=t1
	get_data,'mvn_sta_d4_P4E_D',data=t2
	if size(/type,t1) eq 8 then tt1=1
	if size(/type,t2) eq 8 then tt2=1
	if (tt1) then store_data,'mvn_sta_D',data=['mvn_sta_c8_P2_D']
	if (tt2) then store_data,'mvn_sta_D',data=['mvn_sta_d4_P4E_D']
	if (tt1 and tt2) then store_data,'mvn_sta_D',data=['mvn_sta_d4_P4E_D','mvn_sta_c8_P2_D']
		ylim,'mvn_sta_D',-45,45,0
		zlim,'mvn_sta_D',1,1.e4,1
		options,'mvn_sta_D','spec',1
		options,'mvn_sta_D',ytitle='sta!C!CDef!Ctheta'

;    P4 Survey combined plots

	tt1=0 & tt2=0 & tt3=0 & tt4=0
	get_data,'mvn_sta_cc_P4A_E',data=t1
	get_data,'mvn_sta_ce_P4B_E',data=t2
	get_data,'mvn_sta_d0_P4C_E',data=t3
	get_data,'mvn_sta_d2_P4D_E',data=t4
	if size(/type,t1) eq 8 then tt1=1
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if size(/type,t4) eq 8 then tt4=1
	if tt1 or tt2 or tt3 or tt4 then begin
		store_data,'mvn_sta_P4_E',data=['mvn_sta_cc_P4A_E','mvn_sta_ce_P4B_E','mvn_sta_d0_P4C_E','mvn_sta_d2_P4D_E']
		ylim,'mvn_sta_P4_E',.1,40000.,1
		zlim,'mvn_sta_P4_E',1,1.e5,1
		options,'mvn_sta_P4_E',ytitle='sta!CP4 !CEnergy!CeV'
	endif

	tt1=0 & tt2=0 & tt3=0 & tt4=0
	get_data,'mvn_sta_cc_P4A_M',data=t1
	get_data,'mvn_sta_ce_P4B_M',data=t2
	get_data,'mvn_sta_d0_P4C_M',data=t3
	get_data,'mvn_sta_d2_P4D_M',data=t4
	if size(/type,t1) eq 8 then tt1=1
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if size(/type,t4) eq 8 then tt4=1
	if tt1 or tt2 or tt3 or tt4 then begin
		store_data,'mvn_sta_P4_M',data=['mvn_sta_cc_P4A_M','mvn_sta_ce_P4B_M','mvn_sta_d0_P4C_M','mvn_sta_d2_P4D_M']
		ylim,'mvn_sta_P4_M',.5,100,1
		zlim,'mvn_sta_P4_M',1,1.e5,1
		options,'mvn_sta_P4_M',ytitle='sta!CP4 !CMass!Camu'
	endif


	tt1=0 & tt2=0 & tt3=0 
	get_data,'mvn_sta_cc_P4A_D',data=t1
	get_data,'mvn_sta_ce_P4B_D',data=t2
	get_data,'mvn_sta_d0_P4C_D',data=t3
	if size(/type,t1) eq 8 then tt1=1
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if tt1 or tt2 or tt3 then begin
		store_data,'mvn_sta_P4_D',data=['mvn_sta_cc_P4A_D','mvn_sta_ce_P4B_D','mvn_sta_d0_P4C_D']
		ylim,'mvn_sta_P4_D',-45,45,0
		zlim,'mvn_sta_P4_D',1,1.e5,1
		options,'mvn_sta_P4_D',ytitle='sta!CP4 !CDef!Ctheta'
	endif


	tt2=0 & tt3=0 & tt4=0
	get_data,'mvn_sta_ce_P4B_A',data=t2
	get_data,'mvn_sta_d0_P4C_A',data=t3
	get_data,'mvn_sta_d2_P4D_A',data=t4
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if size(/type,t4) eq 8 then tt4=1
	if tt2 or tt3 or tt4 then begin
		store_data,'mvn_sta_P4_A',data=['mvn_sta_ce_P4B_A','mvn_sta_d0_P4C_A','mvn_sta_d2_P4D_A']
		ylim,'mvn_sta_P4_A',-180,200,0
		zlim,'mvn_sta_P4_A',1,1.e5,1
		options,'mvn_sta_P4_A',ytitle='sta!CP4 !CAnode!Cphi'
	endif

;   P4 Archive combined plots

	tt1=0 & tt2=0 & tt3=0 & tt4=0
	get_data,'mvn_sta_cd_P4A_E',data=t1
	get_data,'mvn_sta_cf_P4B_E',data=t2
	get_data,'mvn_sta_d1_P4C_E',data=t3
	get_data,'mvn_sta_d3_P4D_E',data=t4
	if size(/type,t1) eq 8 then tt1=1
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if size(/type,t4) eq 8 then tt4=1
	if tt1 or tt2 or tt3 or tt4 then begin
		store_data,'mvn_sta_P4_arc_E',data=['mvn_sta_cd_P4A_E','mvn_sta_cf_P4B_E','mvn_sta_d1_P4C_E','mvn_sta_d3_P4D_E']
		ylim,'mvn_sta_P4_arc_E',.1,40000.,1
		ylim,'mvn_sta_P4_arc_E',1,1.e4,1
		options,'mvn_sta_P4_arc_E',ytitle='sta!CP4 arc !CEnergy!CeV'
	endif

	tt1=0 & tt2=0 & tt3=0 & tt4=0
	get_data,'mvn_sta_cd_P4A_M',data=t1
	get_data,'mvn_sta_cf_P4B_M',data=t2
	get_data,'mvn_sta_d1_P4C_M',data=t3
	get_data,'mvn_sta_d3_P4D_M',data=t4
	if size(/type,t1) eq 8 then tt1=1
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if size(/type,t4) eq 8 then tt4=1
	if tt1 or tt2 or tt3 or tt4 then begin
		store_data,'mvn_sta_P4_arc_M',data=['mvn_sta_cd_P4A_M','mvn_sta_cf_P4B_M','mvn_sta_d1_P4C_M','mvn_sta_d3_P4D_M']
		ylim,'mvn_sta_P4_arc_M',.5,100,1
		zlim,'mvn_sta_P4_arc_M',1,1.e4,1
		options,'mvn_sta_P4_arc_M',ytitle='sta!CP4 arc !CMass!Camu'
	endif


	tt1=0 & tt2=0 & tt3=0 
	get_data,'mvn_sta_cd_P4A_D',data=t1
	get_data,'mvn_sta_cf_P4B_D',data=t2
	get_data,'mvn_sta_d1_P4C_D',data=t3
	if size(/type,t1) eq 8 then tt1=1
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if tt1 or tt2 or tt3 then begin
		store_data,'mvn_sta_P4_arc_D',data=['mvn_sta_cd_P4A_D','mvn_sta_cf_P4B_D','mvn_sta_d1_P4C_D']
		ylim,'mvn_sta_P4_arc_D',-45,45,0
		zlim,'mvn_sta_P4_arc_D',1,1.e5,1
		options,'mvn_sta_P4_arc_D',ytitle='sta!CP4 arc!CDef!Ctheta'
	endif


	tt2=0 & tt3=0 & tt4=0
	get_data,'mvn_sta_cf_P4B_A',data=t2
	get_data,'mvn_sta_d1_P4C_A',data=t3
	get_data,'mvn_sta_d3_P4D_A',data=t4
	if size(/type,t2) eq 8 then tt2=1
	if size(/type,t3) eq 8 then tt3=1
	if size(/type,t4) eq 8 then tt4=1
	if tt2 or tt3 or tt4 then begin
		store_data,'mvn_sta_P4_arc_A',data=['mvn_sta_cf_P4B_A','mvn_sta_d1_P4C_A','mvn_sta_d3_P4D_A']
		ylim,'mvn_sta_P4_arc_A',-180,200,0
		options,'mvn_sta_P4_arc_A',ytitle='sta!CP4 arc !CAnode!Cphi'
	endif




end


