;+
;PROCEDURE:	thm_load_pei_bkg
;PURPOSE:	
;	Adds background count rates to the ESA structures for use by thm_pei_bkg_sub
;INPUT:		
;
;KEYWORDS:
;	probe:		strarr		themis spacecraft - "a", "b", "c", "d", "e"
;					if not set defaults to all		
;	sc:		strarr		themis spacecraft - "a", "b", "c", "d", "e"
;					if not set defaults to all		
;	themishome:	string		path to data dir, where data dir contains the th* dir, where *=a,b,c,d,e
;	datatype	string or 0/1	if not set, uses both pser and peir data
;					if set to pser, uses pser only
;					if set to peir, uses peir only
;	user_select	0/1		if set, will let the user selected interval for pser sunlight background 
;						assumes that thm_pse_bkg_set.pro has been run
;					if not set, will run thm_pse_bkg_auto.pro for automated background subtraction
;
;CREATED BY:	J. McFadden	08/12/31
;VERSION:	1
;LAST MODIFICATION:  08/12/31
;MOD HISTORY:
;				08/12/31	
;				10/03/18	added peer background from scattered electrons	
;
;NOTES:	 
;		Assumes pser data is loaded if pser data to be used for background 
;		pser data is only used for times when the attenuators are closed
;		Assumes esa data is loaded 
;		If both esa and sst data sets are used, will use the lower background estimate 
;		Will only work properly if data includes a perigee pass 
;	
;-

pro thm_load_pei_bkg,sc=sc,probe=probe,themishome=themishome,datatype=datatype

;	Time how long the routine takes
	ex_start = systime(1)

cols=get_colors()

; sc default
	if keyword_set(probe) then sc=probe
	if not keyword_set(sc) then begin
		print,'S/C number not set, default = all probes'
		sc=['a','b','c','d','e','f']
	endif

	if not keyword_set(themishome) then themishome=!themis.local_data_dir

nsc = n_elements(sc)
probes=strarr(1)
if nsc eq 1 then probes(0)=strlowcase(sc)
if nsc ne 1 then probes=strlowcase(sc)

; matrix to transform pser count spectra to psir background counts -- needs to be calculated
; we may need different arrays for different spacecraft

;aa = 1.e-3*[0.32,0.425,.537,.672,.935,1.378,1.985,2.825,3.995]^2.
;aa = [1.50000,0.000113094, 0.000113094,0.000132572,0.000312597,0.00131105,0.00480372,0.0229715 ,0.0229715]	; 20080213
aa = [1.50000,6.27452e-005,0.000120554,0.000222392,0.000539607,0.00150673,0.00392665,0.00984036,0.0241520]
; the 0.7 in aa[0] sets the minimum background determined from pser
aa = [0.70,6.27452e-005,0.000120554,0.000222392,0.000539607,0.00150673,0.00392665,0.00984036,0.0241520]
;***********************************************************************************
; get background data

for i=0,nsc-1 do begin

	print,'Calculating background for th'+probes[i]
	data_type=' '
	if keyword_set(datatype) then data_type=datatype

; pser determined background

	if not keyword_set(datatype) or string(data_type) eq 'pser' then begin
		print,'Calculating background from pser data'
		wait,.1

;	'th'+probes[i]+'_pser_minus_bkg' contains pser counts after sunlight background subtraction

;		tmp = thm_sst_pser(probe=probes[i],index=10)
;		if not keyword_set(tmp) then thm_load_sst,probe=probes[i]
		thm_load_sst,probe=probes[i]

		if keyword_set(user_select) then begin
; this user_select section doesn't work, bkg keyword disabled for pse data
			name1='th'+probes[i]+'_pser_minus_bkg'
			get_dat='thm_sst_pser'
			get_en_spec,get_dat,units='counts',name=name1,probe=probes(i),bkg=1
				ylim,name1,100.,100000.,1
				options,name1,'ytitle','e- th'+probes[i]+'!C!CCounts'
				options,name1,'spec',0
			name2='th'+probes[i]+'_pser_atten'
			get_2dt,'sst_atten',get_dat,name=name2,probe=probes(i)
				ylim,name2,0.,11,0
				options,name2,'ytitle','e- sst th'+probes[i]+'!C!C Atten'
		endif else thm_pse_bkg_auto,sc=probes[i]

		get_data,'th'+probes[i]+'_pser_minus_bkg',data=tmp1
;		get_data,'th'+probes[i]+'_pser_atten',data=tmp2
		sst = transpose(tmp1.y[*,0:8]) & sst[0,*]=1.
;		att = interp(tmp2.y,tmp2.x,tmp1.x)
		npt = n_elements(tmp1.x) 
;		att_on=fltarr(npt) & att_on(where(att eq 5))=1.
		att_on=replicate(1.,npt)
		bkg1 = total((aa#att_on)*sst,1)
		time1=tmp1.x

		get_2dt,'jo_3d_new','th'+sc+'_peer',name='Jeo_10_30keV',gap_time=6.,energy=[10000,27000.]
		get_data,'Jeo_10_30keV',data=tmp8
		bkg_pee = 5.e-9*interp(tmp8.y,tmp8.x,tmp1.x)
		store_data,'th'+probes[i]+'_peer_pei_bkg',data={x:tmp1.x,y:bkg_pee}
			ylim,'th'+probes[i]+'_peer_pei_bkg',1,100,1
		bkg1=bkg1+bkg_pee

		store_data,'th'+probes[i]+'_pser_pei_bkg',data={x:tmp1.x,y:bkg1}
			ylim,'th'+probes[i]+'_pser_pei_bkg',1.,10000.,1
			options,'th'+probes[i]+'_pser_pei_bkg','ytitle','Bkg pse th'+probes[i]+'!C!CCounts'

	endif else begin
		att_on = [1.,1.]
		bkg1 = [0.,0.]
		time1 = [time_double('07-02-01/0'),time_double('27-02-01/0')]
	endelse

; peir determined background

	if not keyword_set(datatype) or string(data_type) eq 'peir' then begin
		print,'Calculating background from peir data'
		wait,.1

		get_dat='th'+probes[i]+'_peir'
		name1='th'+probes[i]+'_pei_pei_bkg'
		get_2dt,'thm_pei_bkg',get_dat,name=name1
			ylim,name1,1.,10000.,1
			options,name1,'ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
; the following screwed up in shadow and was replaced with tsmooth2
;		get_data,name1,data=tmp2
;		pei_bkg_3s=smooth_in_time(tmp2.y,tmp2.x,1.05*(tmp2.x[50]-tmp2.x[47]))	; smooth over 3 spins
;		store_data,'thm_pei_bkg_smooth',data={x:tmp2.x,y:pei_bkg_3s}
;		bkg2=pei_bkg_3s
		tsmooth2,name1,3,newname='thm_pei_bkg_smooth'				; smooth over 3 spins
		get_data,'thm_pei_bkg_smooth',data=tmp2
		bkg2=tmp2.y
		time2=tmp2.x

	endif else begin
		bkg2 = [0.,0.]
		time2 = [time_double('07-02-01/0'),time_double('27-02-01/0')]
	endelse

; if both peir and pser background used, then optimize pser background, state data must be loaded

	get_data,'th'+probes[i]+'_state_pos',data=tmp3,index=index
		if index eq 0 then begin
			thm_load_state,/get_support_data,probe=probes[i],version=2
			get_data,'th'+probes[i]+'_state_pos',data=tmp3,index=index
		endif
	if index then begin
		dis3=(total(tmp3.y^2,2))^.5/6370.
		time3=tmp3.x
		if total(bkg1)*total(bkg2) ne 0. then begin
			ind = where(bkg1 gt 20. and bkg1 lt 500.,count)
			if count gt 1000 then begin 
				bkg8=interp(bkg2,time2,time1[ind])
				dist=interp(dis3,time3,time1[ind])
				bkg7=bkg1[ind]
				ind2 = where(finite(bkg8) and finite(bkg7) and dist gt 5.3,count2)
				if count2 gt 1000 then scale = total(bkg7[ind2]*bkg8[ind2])/total(bkg7[ind2]*bkg7[ind2]) else scale=1.
				if scale gt 2. or scale lt .5 then begin
					print,'Error - thm_load_pei_bkg scale correction is too large'
					print,'Probable error in pser optimization code'
					print,'pser background set to zero'
					att_on = [1.,1.]
					bkg1 = [0.,0.]
					time1 = [time_double('07-02-01/0'),time_double('27-02-01/0')]
				endif else begin
					print,'pser background scaled from default values by :',scale
					bkg1 = bkg1 * scale
					store_data,'th'+probes[i]+'_pser_pei_bkg',data={x:time1,y:bkg1}
				endelse
			endif
		endif
	endif else begin
		print,'State data not loaded for th'+probes[i]+', cannot optimize pser background subtraction'
	endelse


; diagnostics
; print,minmax(bkg1)
; print,minmax(bkg2)
; print,n_elements(where(att eq 5))
; print,n_elements(where(att_on eq 1))
; print,n_elements(where(att_on ne 1))

	if probes(i) eq 'a' then begin
		common tha_454,tha_454_ind,tha_454_dat 
		if n_elements(tha_454_dat) ne 0 then begin
		  if tha_454_ind ne -1 then begin
			time=(tha_454_dat.time+tha_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_454_dat.bkg_pse=bkg_pse
			tha_454_dat.bkg_pei=bkg_pei
			tha_454_dat.bkg=bkg3
		  endif
		endif
		common tha_455,tha_455_ind,tha_455_dat 
		if n_elements(tha_455_dat) ne 0 then begin
		  if tha_455_ind ne -1 then begin
			time=(tha_455_dat.time+tha_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_455_dat.bkg_pse=bkg_pse
			tha_455_dat.bkg_pei=bkg_pei
			tha_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common tha_456,tha_456_ind,tha_456_dat 
		if n_elements(tha_456_dat) ne 0 then begin
		  if tha_456_ind ne -1 then begin
			time=(tha_456_dat.time+tha_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_456_dat.bkg_pse=bkg_pse
			tha_456_dat.bkg_pei=bkg_pei
			tha_456_dat.bkg=bkg3
		  endif
		endif
	endif else if probes(i) eq 'b' then begin
		common thb_454,thb_454_ind,thb_454_dat 
		if n_elements(thb_454_dat) ne 0 then begin
		  if thb_454_ind ne -1 then begin
			time=(thb_454_dat.time+thb_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_454_dat.bkg_pse=bkg_pse
			thb_454_dat.bkg_pei=bkg_pei
			thb_454_dat.bkg=bkg3
		  endif
		endif
		common thb_455,thb_455_ind,thb_455_dat 
		if n_elements(thb_455_dat) ne 0 then begin
		  if thb_455_ind ne -1 then begin
			time=(thb_455_dat.time+thb_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_455_dat.bkg_pse=bkg_pse
			thb_455_dat.bkg_pei=bkg_pei
			thb_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common thb_456,thb_456_ind,thb_456_dat 
		if n_elements(thb_456_dat) ne 0 then begin
		  if thb_456_ind ne -1 then begin
			time=(thb_456_dat.time+thb_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_456_dat.bkg_pse=bkg_pse
			thb_456_dat.bkg_pei=bkg_pei
			thb_456_dat.bkg=bkg3
		  endif
		endif
	endif else if probes(i) eq 'c' then begin
		common thc_454,thc_454_ind,thc_454_dat 
		if n_elements(thc_454_dat) ne 0 then begin
		  if thc_454_ind ne -1 then begin
			time=(thc_454_dat.time+thc_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_454_dat.bkg_pse=bkg_pse
			thc_454_dat.bkg_pei=bkg_pei
			thc_454_dat.bkg=bkg3
		  endif
		endif
		common thc_455,thc_455_ind,thc_455_dat 
		if n_elements(thc_455_dat) ne 0 then begin
		  if thc_455_ind ne -1 then begin
			time=(thc_455_dat.time+thc_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_455_dat.bkg_pse=bkg_pse
			thc_455_dat.bkg_pei=bkg_pei
			thc_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common thc_456,thc_456_ind,thc_456_dat 
		if n_elements(thc_456_dat) ne 0 then begin
		  if thc_456_ind ne -1 then begin
			time=(thc_456_dat.time+thc_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_456_dat.bkg_pse=bkg_pse
			thc_456_dat.bkg_pei=bkg_pei
			thc_456_dat.bkg=bkg3
		  endif
		endif
	endif else if probes(i) eq 'd' then begin
		common thd_454,thd_454_ind,thd_454_dat 
		if n_elements(thd_454_dat) ne 0 then begin
		  if thd_454_ind ne -1 then begin
			time=(thd_454_dat.time+thd_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_454_dat.bkg_pse=bkg_pse
			thd_454_dat.bkg_pei=bkg_pei
			thd_454_dat.bkg=bkg3
		  endif
		endif
		common thd_455,thd_455_ind,thd_455_dat 
		if n_elements(thd_455_dat) ne 0 then begin
		  if thd_455_ind ne -1 then begin
			time=(thd_455_dat.time+thd_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_455_dat.bkg_pse=bkg_pse
			thd_455_dat.bkg_pei=bkg_pei
			thd_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common thd_456,thd_456_ind,thd_456_dat 
		if n_elements(thd_456_dat) ne 0 then begin
		  if thd_456_ind ne -1 then begin
			time=(thd_456_dat.time+thd_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_456_dat.bkg_pse=bkg_pse
			thd_456_dat.bkg_pei=bkg_pei
			thd_456_dat.bkg=bkg3
		  endif
		endif
	endif else if probes(i) eq 'e' then begin
		common the_454,the_454_ind,the_454_dat 
		if n_elements(the_454_dat) ne 0 then begin
		  if the_454_ind ne -1 then begin
			time=(the_454_dat.time+the_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_454_dat.bkg_pse=bkg_pse
			the_454_dat.bkg_pei=bkg_pei
			the_454_dat.bkg=bkg3
		  endif
		endif
		common the_455,the_455_ind,the_455_dat 
		if n_elements(the_455_dat) ne 0 then begin
		  if the_455_ind ne -1 then begin
			time=(the_455_dat.time+the_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_455_dat.bkg_pse=bkg_pse
			the_455_dat.bkg_pei=bkg_pei
			the_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common the_456,the_456_ind,the_456_dat 
		if n_elements(the_456_dat) ne 0 then begin
		  if the_456_ind ne -1 then begin
			time=(the_456_dat.time+the_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse(indtmp) = bkg_pei(indtmp) > bkg_pse(indtmp) 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_456_dat.bkg_pse=bkg_pse
			the_456_dat.bkg_pei=bkg_pei
			the_456_dat.bkg=bkg3
		  endif
		endif
	endif

	ex_time = systime(1) - ex_start
	message,'Loading pei background complete:  '+string(ex_time)+' seconds execution time.',/info,/cont
	tplot,['th'+probes[i]+'_pei_bkg'],title='THEMIS '+strupcase(sc)+'  PEI Background'

endfor
end
