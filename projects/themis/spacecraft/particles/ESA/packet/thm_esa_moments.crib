;***********************************************************************************
; Calculates ion and electron moments from full distribution
; this is a cut and paste crib, not to be run as program

; Cavets
; works best with data type - full, 
; moments don't work well with data type - reduced 
; data prior to 2007-03-30 may have errors in ETC table maps that produce errors in moments and distributions

; select day for event
	startdate = '2007-03-23/0:00'
;	startdate = '2007-04-18/0:00'
	t1=time_double(startdate)
	ndays=2
	t2=t1+ndays*24.*3600.
	timespan,startdate,ndays

; select a probe
	sc='a'

; load state data and esa data
	thm_load_state,probe=sc
	thm_load_esa_pkt,probe=sc
	thm_load_esa_mag,probe=sc
	thm_load_esa_pot,probe=sc
;	thm_load_esa_bkg,probe=sc

; choose type of data - f-full, r-reduced, b-burst
	typ='f'
	if typ eq 'f' then gap_time=1000. else gap_time=10.

; decide if you want magnetosheath (sheath=1) or plasmasheet (sheath=0) limits, default is sheath=1
;	sheath=0
;	if sheath then nmax=100. else nmax=10.
	sheath=1
	nmax=100.
	emin=15

; Get position info

	get_data,'th'+sc+'_state_pos',data=tmp
	store_data,'th'+sc+'_state_pos_x',data={x:tmp.x,y:tmp.y(*,0)/6370.}
		options,'th'+sc+'_state_pos_x','ytitle','th'+sc+'_X-GSE'
	store_data,'th'+sc+'_state_pos_y',data={x:tmp.x,y:tmp.y(*,1)/6370.}
		options,'th'+sc+'_state_pos_y','ytitle','th'+sc+'_Y-GSE'
	store_data,'th'+sc+'_state_pos_z',data={x:tmp.x,y:tmp.y(*,2)/6370.}
		options,'th'+sc+'_state_pos_z','ytitle','th'+sc+'_Z-GSE'

; ion plots

	get_dat='get_th'+sc+'_pei'+typ
	name1='th'+sc+'_pei'+typ+'_en_eflux'
	get_en_spec,get_dat,units='eflux',retrace=1,name=name1,gap_time=gap_time,t1=t1,t2=t2
	zlim,name1,1.e3,1.e7,1
	ylim,name1,3.,40000.,1
	options,name1,'ztitle','Eflux !C!C eV/cm!U2!N-s-sr-eV'
	options,name1,'ytitle','i+ th'+sc+'!C!C eV'
	options,name1,'spec',1
	options,name1,'x_no_interp',1
	options,name1,'y_no_interp',1

	name1='th'+sc+'_pei'+typ+'_N'
	get_2dt,'n_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[20.,21000.]
	ylim,name1,.1,nmax,1
	options,name1,'ytitle','Ni th'+sc+'!C!C1/cm!U3'
	
	name1='th'+sc+'_pei'+typ+'_V'
	get_2dt,'v_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[20.,21000.]
	ylim,name1,-500,500.,0
	ylim,name1,-200,200.,0
	if sheath then ylim,name1,-500,200.,0
	options,name1,'ytitle','Vi th'+sc+'!C!Ckm/s'
	options,name1,'colors',[cols.blue,cols.green,cols.red]
	options,name1,labels=['Vi!dx!n', 'Vi!dy!n', 'Vi!dz!n'],constant=0.

	name1='th'+sc+'_pei'+typ+'_T'
	get_2dt,'t_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[20.,21000.]
	ylim,name1,100,10000.,1
	if sheath then ylim,name1,10,10000.,1
	options,name1,'ytitle','Ti th'+sc+'!C!CeV'

; plot the ion data

	tplot,['th'+sc+'_pei'+typ+'_en_eflux','th'+sc+'_pei'+typ+'_N','th'+sc+'_pei'+typ+'_V','th'+sc+'_pei'+typ+'_T'],$
	title='Themis',var_label=['th'+sc+'_state_pos_x','th'+sc+'_state_pos_y','th'+sc+'_state_pos_z']

; electron plots

	get_dat='get_th'+sc+'_pee'+typ
	name1='th'+sc+'_pee'+typ+'_en_eflux'
	get_en_spec,get_dat,units='eflux',retrace=1,name=name1,gap_time=gap_time,t1=t1,t2=t2
	zlim,name1,1.e5,1.e9,1
	ylim,name1,3.,40000.,1
	options,name1,'ztitle','Eflux !C!C eV/cm!U2!N-s-sr-eV'
	options,name1,'ytitle','e- th'+sc+'!C!C eV'
	options,name1,'spec',1
	options,name1,'x_no_interp',1
	options,name1,'y_no_interp',1

	name1='th'+sc+'_pee'+typ+'_N'
	get_2dt,'n_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[emin,27000.]
	ylim,name1,.1,nmax,1
	options,name1,'ytitle','Ne th'+sc+'!C!C1/cm!U3'
	
	name1='th'+sc+'_pee'+typ+'_V'
	get_2dt,'v_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[emin,27000.]
	ylim,name1,-500,500.,0
	ylim,name1,-200,200.,0
	if sheath then ylim,name1,-500,200.,0
	options,name1,'ytitle','Ve th'+sc+'!C!Ckm/s'
	options,name1,'colors',[cols.blue,cols.green,cols.red]
	options,name1,labels=['V!dex!n', 'V!dey!n', 'V!dez!n'],constant=0.

	name1='th'+sc+'_pee'+typ+'_T'
	get_2dt,'t_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[emin,27000.]
	ylim,name1,100,10000.,1
	if sheath then ylim,name1,10,10000.,1
	options,name1,'ytitle','Te th'+sc+'!C!CeV'


; plot the electron data

	tplot,['th'+sc+'_pee'+typ+'_en_eflux','th'+sc+'_pee'+typ+'_N','th'+sc+'_pee'+typ+'_V','th'+sc+'_pee'+typ+'_T'],$
	title='Themis',var_label=['th'+sc+'_state_pos_x','th'+sc+'_state_pos_y','th'+sc+'_state_pos_z']

end
