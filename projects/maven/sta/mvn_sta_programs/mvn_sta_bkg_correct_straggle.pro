;+
;PROCEDURE:	mvn_sta_bkg_correct_straggle
;PURPOSE:	
;	Corrects coincident background in sw where time variations happen on <4ms time scales, and runs mvn_sta_bkg_straggle_all.pro
;INPUT:		
;
;KEYWORDS:
;	avg_interval	flt	number of c6 packets averaged for correction
;					default = 21
;	scale1		flt	default=0.00015, scale factor for variations in coincidence with mass - emperically determined on 20160401
;	scale2		flt	default=0.1, fraction of counts in massbin=40:55 that exceed cnts in massbin=56:63 to ignore correction
;					o2+,co2+ counts straggle into massbins 56:63 making correction inaccurate
;	value2		flt	minimum value of c6 bkg summed over massbin=56:63 at a energy bin to trigger correction algorithm
;					def=0.3  -- should this be lowered? see problem below
;	value3		flt	smoothing valued
;					def=value2
;	test		0/1	if set, will create tplot variables for testing
;	tplot		0/1	if set, will run "mvn_sta_l2_tplot,/test,/all,/replace" at completion of the program
;	save_bkg	0/1	if set, will save the current value of bkg in an intermediate array -- for testing
;	restore_bkg	0/1	if set, will restore value of bkg in an intermediate array created by save_bkg -- for testing
;	only_c6		0/1	if set, only c6 gets bkg updated
;	maven_dead_dir	string	maven_dead_dir is the directory root directory where dat_dead - default = 'c:\data\
;
;
;CREATED BY:	J. McFadden 20/07/16
;VERSION:	1
;LAST MODIFICATION:  20/07/27		
;MOD HISTORY:
;
;NOTES:	  
; 	bkg7 from mvn_sta_bkg_load (coincident events) are corrected for fast time variations 
;	bkg7 is proportional to rate squared, so any averaging of fluctuations during a 4ms accumulation will result in underestimates of bkg
;	The assumption is that high massbins=56:63 are entirely due to coincident ions unless significant o2+,co2+ is present
;	Differences between dat.bkg estimate from rate^2 and dat.cnts for massbins=56:63 is assumed to be due to rapid flux changes over the 4ms accumulation time
;	Correction factors to dat.bkg are based on (dat.cnts/dat.bkg) ratios and calculated for each energy using c6
;	- a secondary 10% level correction is also applied based coincident timing https://en.wikipedia.org/wiki/Exponential_distribution
; 	- it corrects for the exponential decrease in coincident events with increasing mass
;	correction are based on c6, so the time base for corrections will be from c6
;	c6 data for the day before and day after are loaded for intermediate calculations, but c6 is returned to a single day being loaded.
;	some parameters were determined emperically defaults values see to work
;
;	Problem: there may be a problem with not correcting if calculated bkg is greater than the cnts high mass bins 56:63
;		Changed the >1. to >0.7 on line 238,  also may need to change value2. 
;		Saw this problem on 20160402  22:23-22:50 with a weak solar wind and modified code to >0.7 
;-

pro mvn_sta_bkg_correct_straggle,avg_interval=avg_interval,value2=value2,value3=value3,scale1=scale1,scale2=scale2,test=test,tplot=tplot,$
		save_bkg=save_bkg,restore_bkg=restore_bkg,maven_dead_dir=maven_dead_dir

starttime = systime(1)

common mvn_c0,mvn_c0_ind,mvn_c0_dat 
common mvn_c6,mvn_c6_ind,mvn_c6_dat 
common mvn_c8,mvn_c8_ind,mvn_c8_dat 
common mvn_ca,mvn_ca_ind,mvn_ca_dat 
common mvn_d0,mvn_d0_ind,mvn_d0_dat 
common mvn_d1,mvn_d1_ind,mvn_d1_dat 

common mvn_d8,mvn_d8_ind,mvn_d8_dat 
common mvn_d9,mvn_d9_ind,mvn_d9_dat 
common mvn_da,mvn_da_ind,mvn_da_dat 
common mvn_db,mvn_db_ind,mvn_db_dat 

common mvn_sta_dead,dat_dead	

; check if required c6 data is loaded

if size(mvn_c6_dat,/type) ne 8 then begin
	print,'Error - c6 data not loaded'
	return
endif

if max(total(mvn_c6_dat.bkg[*,*,56:63],3)) lt 1. then begin
	print,'Error - it appears that coincident background is not loaded, run mvn_sta_bkg_load.pro'
	return
endif

; these are for testing

if keyword_set(save_bkg) then begin
	common bkg_c0,bkg_c0_arr_old
		if size(mvn_c0_dat,/type) eq 8 then bkg_c0_arr_old=mvn_c0_dat.bkg
	common bkg_c6,bkg_c6_arr_old
		if size(mvn_c6_dat,/type) eq 8 then bkg_c6_arr_old=mvn_c6_dat.bkg
	common bkg_c8,bkg_c8_arr_old
		if size(mvn_c8_dat,/type) eq 8 then bkg_c8_arr_old=mvn_c8_dat.bkg
	common bkg_ca,bkg_ca_arr_old
		if size(mvn_ca_dat,/type) eq 8 then bkg_ca_arr_old=mvn_ca_dat.bkg
	common bkg_d0,bkg_d0_arr_old
		if size(mvn_d0_dat,/type) eq 8 then bkg_d0_arr_old=mvn_d0_dat.bkg
	common bkg_d1,bkg_d1_arr_old
		if size(mvn_d1_dat,/type) eq 8 then bkg_d1_arr_old=mvn_d1_dat.bkg
endif

if keyword_set(restore_bkg) then begin
	if size(mvn_c0_dat,/type) eq 8 and size(bkg_c0_arr_old,/type) eq 4 then mvn_c0_dat.bkg=bkg_c0_arr_old
	if size(mvn_c6_dat,/type) eq 8 and size(bkg_c6_arr_old,/type) eq 4 then mvn_c6_dat.bkg=bkg_c6_arr_old
	if size(mvn_c8_dat,/type) eq 8 and size(bkg_c8_arr_old,/type) eq 4 then mvn_c8_dat.bkg=bkg_c8_arr_old
	if size(mvn_ca_dat,/type) eq 8 and size(bkg_ca_arr_old,/type) eq 4 then mvn_ca_dat.bkg=bkg_ca_arr_old
	if size(mvn_d0_dat,/type) eq 8 and size(bkg_d0_arr_old,/type) eq 4 then mvn_d0_dat.bkg=bkg_d0_arr_old
	if size(mvn_d1_dat,/type) eq 8 and size(bkg_d1_arr_old,/type) eq 4 then mvn_d1_dat.bkg=bkg_d1_arr_old
	print,'Background restored'
	return
endif

cols=get_colors()

; set default values
	if not keyword_set(scale1) then scale1 = 0.00013				; emperically determined to be between 0.0001 and 0.00015 on 20160401
	if not keyword_set(scale2) then scale2 = 0.1					; 
	if not keyword_set(value2) then value2 = 0.3					; fraction of O2+ that leaks into high mass bins
	if not keyword_set(value3) then value3 = value2					; fraction of O2+ that leaks into high mass bins
	if keyword_set(avg_interval) then navg=avg_interval else navg=21
	n2 = round((navg-1)/2)

; expand the time range for c6 and dat_dead commong by +/- 1000 sec to allow averaging across day boundaries

		tt_day=timerange()
		tr_c6 = minmax(mvn_c6_dat.time)
		tr0 = timerange()
		timespan,tr0[0]-1000.,(tr0[1]-tr0[0]+2000.)/(24.*3600.)
		mvn_sta_l2_load, sta_apid = ['c6'],iv_level=1
		if total(mvn_c6_dat.bkg) eq 0. then begin				; this is for testing only
			print,'bkg not loaded - aborting run'
			timespan,tr0[0],(tr0[1]-tr0[0])/(24.*3600.) 			; reset timespan
			mvn_sta_l2_load, sta_apid = ['c6']
			if size(mvn_c6_dat,/type) eq 8 and size(bkg_c6_arr_old,/type) eq 4 then mvn_c6_dat.bkg=bkg_c6_arr_old
			return
		endif
		timespan,tr0[0],(tr0[1]-tr0[0])/(24.*3600.) 		; reset timespan


; use apid c6 for the time base

	time = (mvn_c6_dat.time+mvn_c6_dat.end_time)/2.
	npts = n_elements(time)

	alt = total(mvn_c6_dat.pos_sc_mso[*,*]*mvn_c6_dat.pos_sc_mso[*,*],2)^.5 - 3390.
	alt = alt#replicate(1.,32)

	bkg_56_63 = total(mvn_c6_dat.bkg[*,*,56:63],3)
	cnt_56_63 = total(mvn_c6_dat.data[*,*,56:63],3)
	cmb_40_55 = total(mvn_c6_dat.data[*,*,40:55],3)-total(mvn_c6_dat.bkg[*,*,40:55],3)
	cnt_0_15 = total(mvn_c6_dat.data[*,*,0:15],3)
	cnt_32_55 = total(mvn_c6_dat.data[*,*,32:55],3)

; make some tplot variables for testing if test keyword is set

	if keyword_set(test) then begin
		store_data,'bkg_56_63',data={x:time,y:total(bkg_56_63,2)}
			options,'bkg_56_63',ytitle='bkg!C56-63',yrange=[.1,1000],ylog=1,colors=cols.red
		store_data,'cnt_56_63',data={x:time,y:total(cnt_56_63,2)}
			options,'cnt_56_63',ytitle='cnt!C56-63',yrange=[.1,1000],ylog=1
		store_data,'cmb_40_55',data={x:time,y:total(cmb_40_55,2)}
			options,'cmb_40_55',ytitle='cnt-bkg!C40-55',yrange=[.1,1000],ylog=1
		store_data,'cmb_40_55_scale',data={x:time,y:total(scale2*cmb_40_55,2)}
			options,'cmb_40_55_scale',ytitle='cnt-bkg!C40-55',yrange=[.1,1000],ylog=1,colors=cols.green
		store_data,'cnt_bkg_56_63',data=['cnt_56_63','bkg_56_63','cmb_40_55_scale']
			options,'cnt_bkg_56_63',ytitle='cnt-b!Cbkg-r!C56-63!C40-55g',yrange=[.1,1000],ylog=1

		store_data,'cnt_0_15',data={x:time,y:total(cnt_0_15,2)}
			options,'cnt_0_15',ytitle='cnt!C0-15',yrange=[.1,1000],ylog=1,colors=cols.red
		store_data,'cnt_32_55',data={x:time,y:total(cnt_32_55,2)}
			options,'cnt_32_55',ytitle='cnt!C32-55',yrange=[.1,1000],ylog=1,colors=cols.green
		store_data,'cnt_0_15_and_32_55',data=['cnt_0_15','cnt_32_55']
			options,'cnt_0_15_and_32_55',ytitle='cnt!C0-15r!C32-55g',yrange=[.1,10000],ylog=1
	endif

; abort bkg corrections if bkg is missing from c6 common block

	ind_en = where(bkg_56_63[*,*] gt value2,ncount)     ; don't correct if too many o2+ counts
	if ncount lt 1 then begin
		print,'Error: No intervals with background, you must run mvn_sta_bkg_load first.''
		return
	endif

; expand the time range for c6 to allow averaging

	if keyword_set(trange) then begin
		ind_jj=where(mvn_c6_dat.time gt trange[0] and mvn_c6_dat.time lt trange[1])
	endif else begin
		ind_jj=lindgen(npts)
	endelse
	npts2=n_elements(ind_jj)

; temporary calculation arrays

	bkg_tmp = fltarr(npts,32)
	cnt_tmp = fltarr(npts,32)
	cor_tmp = fltarr(npts,32)
	cor_max = fltarr(npts)
	c6_norm_arr = fltarr(npts,32)
	c6_norm2_arr = fltarr(npts,32,64)
	d0_norm2_arr = fltarr(npts,32,64,8)
	d1_norm2_arr = fltarr(npts,32,64,8)

;    these are diagnostic arrays to test that background correction is the same in all products

	bkgc0 = fltarr(npts)
	bkgc6 = fltarr(npts)
	bkgc8 = fltarr(npts)
	bkgca = fltarr(npts)
	bkgd0 = fltarr(npts)
	bkgd1 = fltarr(npts)

	bkg2c0 = fltarr(npts)
	bkg2c6 = fltarr(npts)
	bkg2c8 = fltarr(npts)
	bkg2ca = fltarr(npts)
	bkg2d0 = fltarr(npts)
	bkg2d1 = fltarr(npts)

	bkg1c6 = fltarr(npts)			; total coincidence counts before corrections

; determine which times and energies should have corrections applied
;	corrections are ignored if heavy ions (o2+,co2+ massbin=40:55) times scale2 (def=0.1) exceed bkg_56_63 
;	corrections are ignored at <400 km
;	corrections are ignored if calculated bkg counts in massbin=56:63 are less than value2 (def=0.3)

	for jj=0l,npts2-1 do begin
		ii = ind_jj[jj]
;		ind_en = where((bkg_56_63[ii,*] gt value2) and (scale2*cmb_40_55[ii,*] lt bkg_56_63[ii,*]) and (cnt_0_15[ii,*] gt (cnt_32_55[ii,*]+1.)) and (alt[ii,*] gt 400.),ncount)     
		ind_en = where((bkg_56_63[ii,*] gt value2) and (scale2*cmb_40_55[ii,*] lt bkg_56_63[ii,*]) and (alt[ii,*] gt 400.),ncount)     
		if ncount ge 1 then bkg_tmp[ii,ind_en] = bkg_56_63[ii,ind_en]
		if ncount ge 1 then cnt_tmp[ii,ind_en] = cnt_56_63[ii,ind_en]
;		if keyword_set(test) and (jj mod 1000 eq 1) then print,jj,ii,npts,systime(1)-starttime		; tracking progress
		if (jj mod 1000 eq 1) then print,jj,ii,npts,systime(1)-starttime		; tracking progress
	endfor

; correct c6 background - first perform the average to get statistically significant corrections

	for jj=0l+n2,npts2-1-n2 do begin
		ii = ind_jj[jj]
; need to decide whether we restrict this to >1.  -- at low rates statistical variations make it low, at high rates non-linear droop make it low 
; weak   solar wind 20160402 at 22:30 had values of 0.7 - see problem in notes
; strong solar wind 20180827 at 13:00 had values of 0.5 - see problem in notes
;		cor_tmp[ii,*] = (navg*value3+total(cnt_tmp[ii-n2:ii+n2,*],1))/(navg*value3+total(bkg_tmp[ii-n2:ii+n2,*],1))>1.
;		cor_tmp[ii,*] = (navg*value3+total(cnt_tmp[ii-n2:ii+n2,*],1))/(navg*value3+total(bkg_tmp[ii-n2:ii+n2,*],1))>0.7
		cor_tmp[ii,*] = (navg*value3+total(cnt_tmp[ii-n2:ii+n2,*],1))/(navg*value3+total(bkg_tmp[ii-n2:ii+n2,*],1))>0.5
		cor_max[ii] = max(cor_tmp[ii,*])
		c6_cor = cor_tmp[ii,*]
		c6_twt = reform(mvn_c6_dat.twt_arr[mvn_c6_dat.mlut_ind[ii],*,*])
		c6_norm = reform(reform((c6_cor-1.)*bkg_56_63[ii,*]/total(c6_twt[*,56:63],2))#replicate(1.,64),32,64)
		c6_norm_arr[ii,*]=reform((c6_cor-1.)*bkg_56_63[ii,*]/total(c6_twt[*,56:63],2))  
		mvn_c6_dat.bkg[ii,*,*] = mvn_c6_dat.bkg[ii,*,*] + c6_twt*c6_norm

		bkgc6[ii]=total(c6_twt*c6_norm)					; this is for testing purposes - used to generate a tplot below

; 	the following corrects for the exponential decrease in coincident events with increasing mass
;	This is only about a 10% effect across the mass range for typical solar wind rate of ~1MHz
;	https://en.wikipedia.org/wiki/Exponential_distribution

		c6_norm2 = reform(reform(c6_cor*bkg_56_63[ii,*]/total(c6_twt[*,56:63],2))#replicate(1.,64),32,64)
		bkg1c6[ii] = total(c6_twt*c6_norm2)
		tof = reform(mvn_c6_dat.tof_arr[mvn_c6_dat.mlut_ind[ii],*,*]+16.)/5.844
		tof60 = tof[*,60]#replicate(1.,64)
		rate_factor = scale1*total(reform(mvn_c6_dat.bkg[ii,*,*]),2)^.5	#replicate(1.,64)			; scale1 determined emperically on 20160401
;		rate_factor = .0002*total(reform(mvn_c6_dat.bkg[ii,*,*]),2)^.5	#replicate(1.,64)			; this over corrects
;		rate_factor = .0000*total(reform(mvn_c6_dat.bkg[ii,*,*]),2)^.5	#replicate(1.,64)			; this turn off the correction

;		mvn_c6_dat.bkg[ii,*,*] = c6_twt*c6_norm2*(exp(-tof*rate_factor)/exp(-tof60*rate_factor))		; for testing coincidence only

		c6_norm2_arr[ii,*,*] = c6_twt*c6_norm2*(exp(-tof*rate_factor)/exp(-tof60*rate_factor)-1.) 

		mvn_c6_dat.bkg[ii,*,*] = mvn_c6_dat.bkg[ii,*,*] + c6_norm2_arr[ii,*,*]

		bkg2c6[ii] = total(c6_norm2_arr[ii,*,*])			; this is for testing purposes - used to generate a tplot below

	endfor


; store the coincidence corrections

	store_data,'coincidence_corr',data={x:time,y:cor_max}
		options,'coincidence_corr',ytitle='max!Ccoin!Ccorr'
	store_data,'coincidence_corr_arr',data={x:time,y:cor_tmp,v:reform(mvn_c6_dat.energy[mvn_c6_dat.swp_ind,*,0])}
		options,'coincidence_corr_arr',spec=1,ytitle='Energy!C!CeV',yrange=[100,10000],ylog=1,ystyle=1,zrange=[1.,5],zlog=1,no_interp=1


; correct c0 background

	if size(mvn_c0_dat,/type) eq 8 then begin
 		npts4=n_elements(mvn_c0_dat.time)	
		bkgc0 = fltarr(npts4)
		if keyword_set(trange) then begin
			minval = min(abs(time[ind_jj[n2]]-mvn_c0_dat.time-2.),kk0)
			minval = min(abs(time[ind_jj[npts2-1-n2]]-mvn_c0_dat.time-2.),kk1)
		endif else begin
			kk0=0l
			kk1=npts4-1
		endelse
		for kk=kk0,kk1 do begin
			c0_time = mvn_c0_dat.time[kk]+2.
	    		minval = min(abs(time-c0_time),ind_c6)
			c0_cnts0 = reform(mvn_c0_dat.data[kk,*,0])
			c0_cnts2 = reform(c0_cnts0,2,32)^2						; assume rate^2 for distributing coincidence over adjacent energy bins
			c0_norm = reform(c0_cnts2/((replicate(1.,2)#total(c0_cnts2,1))+.00001),64)
			c0_twt = reform(mvn_c0_dat.twt_arr[mvn_c0_dat.mlut_ind[kk],*,*])
			c6_norm = reform(replicate(1.,2)#reform(c6_norm_arr[ind_c6,*]),64) 
			mvn_c0_dat.bkg[kk,*,*] = mvn_c0_dat.bkg[kk,*,*] + ((c6_norm*c0_norm)#replicate(1.,2))*c0_twt	

			bkgc0[kk] = total(((c6_norm*c0_norm)#replicate(1.,2))*c0_twt)		; this is for testing purposes - used to generate a tplot below 

; 	the following corrects for the exponential decrease in coincident events with increasing mass

			c6_norm2 = reform(replicate(1.,2)#reform(total(reform(c6_norm2_arr[ind_c6,*,*],32,32,2),2),64),64,2)
			mvn_c0_dat.bkg[kk,*,*] = mvn_c0_dat.bkg[kk,*,*] + c6_norm2*(c0_norm#replicate(1.,2))	

			bkg2c0[kk] = total(c6_norm2*(c0_norm#replicate(1.,2)))

		endfor
	endif

; correct d0 background

	if size(mvn_d0_dat,/type) eq 8 then begin
 		npts7=n_elements(mvn_d0_dat.time)	
		bkgd0 = fltarr(npts7)
		if keyword_set(trange) then begin
			minval = min(abs(time[ind_jj[n2]]-mvn_d0_dat.time-2.),kk0)
			minval = min(abs(time[ind_jj[npts2-1-n2]]-mvn_d0_dat.end_time+2.),kk1)
		endif else begin
			kk0=0l
			kk1=npts7-1
		endelse
		for kk=kk0,kk1 do begin
			d0_t = mvn_d0_dat.time[kk]
			d0_e = mvn_d0_dat.end_time[kk]
	    		minval = min(abs(time-2.-d0_t),ind_c6_0)
	    		minval = min(abs(time+2.-d0_e),ind_c6_1)
			d0_cor = (total(cor_tmp[ind_c6_0:ind_c6_1,*],1)/(ind_c6_1-ind_c6_0+1))#replicate(1.,64)
			d0_twt = reform(mvn_d0_dat.twt_arr[mvn_d0_dat.mlut_ind[kk],*,*,*])
			d0_norm = reform(reform((d0_cor-1.)*reform(mvn_d0_dat.bkg[kk,*,*,7])/reform(d0_twt[*,*,7]),32l*64) #replicate(1.,8),32,64,8)
			mvn_d0_dat.bkg[kk,*,*,*] = mvn_d0_dat.bkg[kk,*,*,*] + d0_twt*d0_norm

			bkgd0[kk]=total(d0_twt*d0_norm)/(ind_c6_1-ind_c6_0+1)

; 	the following corrects for the exponential decrease in coincident events with increasing mass

			d0_norm2 = reform(reform(d0_cor*reform(mvn_d0_dat.bkg[kk,*,*,7])/reform(d0_twt[*,*,7]),32l*64) #replicate(1.,8),32,64,8)
			tof = reform(mvn_d0_dat.tof_arr[mvn_d0_dat.mlut_ind[kk],*,*,*]+16.)/5.844
			tof7 = reform(reform(tof[*,*,7],32*64l)#replicate(1.,8),32,64,8)
			rate_factor = scale1*reform(reform(total(reform(mvn_d0_dat.bkg[kk,*,*,*]/(ind_c6_1-ind_c6_0+1)),3)^.5,32l*64)#replicate(1.,8),32,64,8)			; scale1 determined emperically on 20160401

			d0_norm2_arr[kk,*,*,*] = d0_twt*d0_norm2*(exp(-tof*rate_factor)/exp(-tof7*rate_factor)-1.) 

			mvn_d0_dat.bkg[kk,*,*,*] = mvn_d0_dat.bkg[kk,*,*,*] + d0_norm2_arr[kk,*,*,*]

			bkg2d0[kk] = total(d0_norm2_arr[kk,*,*,*])/(ind_c6_1-ind_c6_0+1)		; this is for testing purposes - used to generate a tplot below

		endfor
	endif


; correct d1 background

	if size(mvn_d1_dat,/type) eq 8 then begin
 		npts8=n_elements(mvn_d1_dat.time)	
		bkgd1 = fltarr(npts8)
		if keyword_set(trange) then begin
			minval = min(abs(time[ind_jj[n2]]-mvn_d1_dat.time-2.),kk0)
			minval = min(abs(time[ind_jj[npts2-1-n2]]-mvn_d1_dat.end_time+2.),kk1)
		endif else begin
			kk0=0l
			kk1=npts8-1
		endelse
		for kk=kk0,kk1 do begin
			d1_t = mvn_d1_dat.time[kk]
			d1_e = mvn_d1_dat.end_time[kk]
	    		minval = min(abs(time-2.-d1_t),ind_c6_0)
	    		minval = min(abs(time+2.-d1_e),ind_c6_1)
			d1_cor = (total(cor_tmp[ind_c6_0:ind_c6_1,*],1)/(ind_c6_1-ind_c6_0+1))#replicate(1.,64)
			d1_twt = reform(mvn_d1_dat.twt_arr[mvn_d1_dat.mlut_ind[kk],*,*,*])
			d1_norm = reform(reform((d1_cor-1.)*reform(mvn_d1_dat.bkg[kk,*,*,7])/reform(d1_twt[*,*,7]),32l*64) #replicate(1.,8),32,64,8)
			mvn_d1_dat.bkg[kk,*,*,*] = mvn_d1_dat.bkg[kk,*,*,*] + d1_twt*d1_norm

			bkgd1[kk]=total(d1_twt*d1_norm)/(ind_c6_1-ind_c6_0+1)

; 	the following corrects for the exponential decrease in coincident events with increasing mass

			d1_norm2 = reform(reform(d1_cor*reform(mvn_d1_dat.bkg[kk,*,*,7])/reform(d1_twt[*,*,7]),32l*64) #replicate(1.,8),32,64,8)
			tof = reform(mvn_d1_dat.tof_arr[mvn_d1_dat.mlut_ind[kk],*,*,*]+16.)/5.844
			tof7 = reform(reform(tof[*,*,7],32*64l)#replicate(1.,8),32,64,8)
			rate_factor = scale1*reform(reform(total(reform(mvn_d1_dat.bkg[kk,*,*,*]/(ind_c6_1-ind_c6_0+1)),3)^.5,32l*64)#replicate(1.,8),32,64,8)			; scale1 determined emperically on 20160401

			d1_norm2_arr[kk,*,*,*] = d1_twt*d1_norm2*(exp(-tof*rate_factor)/exp(-tof7*rate_factor)-1.) 

			mvn_d1_dat.bkg[kk,*,*,*] = mvn_d1_dat.bkg[kk,*,*,*] + d1_norm2_arr[kk,*,*,*]

			bkg2d1[kk] = total(d1_norm2_arr[kk,*,*,*])/(ind_c6_1-ind_c6_0+1)		; this is for testing purposes - used to generate a tplot below

		endfor
	endif

; correct c8 background

	if size(mvn_c8_dat,/type) eq 8 then begin
 		npts5=n_elements(mvn_c8_dat.time)	
		bkgc8 = fltarr(npts5)
		if keyword_set(trange) then begin
			minval = min(abs(time[ind_jj[n2]]-mvn_c8_dat.time-2.),kk0)
			minval = min(abs(time[ind_jj[npts2-1-n2]]-mvn_c8_dat.time-2.),kk1)
		endif else begin
			kk0=0l
			kk1=npts5-1
		endelse
		for kk=kk0,kk1 do begin
			c8_time = mvn_c8_dat.time[kk]+2.
	    		minval = min(abs(time-c8_time),ind_c6)
			c8_cnts0 = reform(mvn_c8_dat.data[kk,*,*])
			c8_cnts2 = c8_cnts0^2
			c8_dist = c8_cnts2/(total(c8_cnts2,2)#replicate(1.,16)+.00001)
			c8_twt = reform(mvn_c8_dat.twt_arr[mvn_c8_dat.mlut_ind[kk],*,0])
			c6_norm = reform(c6_norm_arr[ind_c6,*]) 
			mvn_c8_dat.bkg[kk,*,*] = mvn_c8_dat.bkg[kk,*,*] + ((c6_norm*c8_twt)#replicate(1.,16))*c8_dist	

			bkgc8[kk] = total(((c6_norm*c8_twt)#replicate(1.,16))*c8_dist)		

; 	the following corrects for the exponential decrease in coincident events with increasing mass

			c6_norm2 = total(reform(c6_norm2_arr[ind_c6,*,*]),2)#replicate(1.,16)
			mvn_c8_dat.bkg[kk,*,*] = mvn_c8_dat.bkg[kk,*,*] + c6_norm2*c8_dist	

			bkg2c8[kk] = total(c6_norm2*c8_dist)

		endfor
	endif

; correct ca background

	if size(mvn_ca_dat,/type) eq 8 then begin
		npts6=n_elements(mvn_ca_dat.time)	
		bkgca = fltarr(npts6)
		if keyword_set(trange) then begin
			minval = min(abs(time[ind_jj[n2]]-mvn_ca_dat.time-2.),kk0)
			minval = min(abs(time[ind_jj[npts2-1-n2]]-mvn_ca_dat.time-2.),kk1)
		endif else begin
			kk0=0l
			kk1=npts6-1
		endelse
		for kk=kk0,kk1 do begin
			ca_time = mvn_ca_dat.time[kk]+2.
	    		minval = min(abs(time-ca_time),ind_c6)
			ca_cnts0 = reform(mvn_ca_dat.data[kk,*,*])
			ca_cnts2 = ca_cnts0^2
			ca_dist = ca_cnts2/(total(ca_cnts2,2)#replicate(1.,64)+.00001)
			ca_twt = reform(mvn_ca_dat.twt_arr[mvn_ca_dat.mlut_ind[kk],*,0])
			c6_norm = total(reform(c6_norm_arr[ind_c6,*],2,16),1) 
			mvn_ca_dat.bkg[kk,*,*] = mvn_ca_dat.bkg[kk,*,*] + ((c6_norm*ca_twt)#replicate(1.,64))*ca_dist	

			bkgca[kk] = total(((c6_norm*ca_twt)#replicate(1.,64))*ca_dist)		

; 	the following corrects for the exponential decrease in coincident events with increasing mass

			c6_norm2 = total(total(reform(c6_norm2_arr[ind_c6,*,*],2,16,64),3),1)#replicate(1.,64)
			mvn_ca_dat.bkg[kk,*,*] = mvn_ca_dat.bkg[kk,*,*] + c6_norm2*ca_dist	

			bkg2ca[kk] = total(c6_norm2*ca_dist)

		endfor
	endif

; store bkg data for comparison -- this is a diagnostic for comparison

	store_data,'bkgc6',data={x:time,y:bkgc6}
	if size(mvn_c0_dat,/type) eq 8 then store_data,'bkgc0',data={x:mvn_c0_dat.time+2.,y:bkgc0}
		options,'bkgc0',colors=cols.red,psym=1
	if size(mvn_c8_dat,/type) eq 8 then store_data,'bkgc8',data={x:(mvn_c8_dat.time+mvn_c8_dat.end_time)/2.,y:bkgc8}
		options,'bkgc8',colors=cols.cyan,psym=2
	if size(mvn_ca_dat,/type) eq 8 then store_data,'bkgca',data={x:(mvn_ca_dat.time+mvn_ca_dat.end_time)/2.,y:bkgca}
		options,'bkgca',colors=cols.green,psym=4
	if size(mvn_d0_dat,/type) eq 8 then store_data,'bkgd0',data={x:(mvn_d0_dat.time+mvn_d0_dat.end_time)/2.,y:bkgd0}
		options,'bkgd0',colors=cols.blue,psym=1
	if size(mvn_d1_dat,/type) eq 8 then store_data,'bkgd1',data={x:(mvn_d1_dat.time+mvn_d1_dat.end_time)/2.,y:bkgd1}
		options,'bkgd1',colors=cols.magenta,psym=1

	store_data,'bkg_test',data=['bkgc6','bkgc0','bkgc8','bkgca','bkgd0','bkgd1','bkgc6']
		options,'bkg_test',ystyle=1,yrange=[.5,500],ylog=1

	store_data,'bkg1c6',data={x:time,y:bkg1c6}
		options,'bkg1c6',ystyle=1,yrange=[.5,500],ylog=1

	store_data,'bkg2c6',data={x:time,y:bkg2c6}
		options,'bkg2c6',ystyle=1,yrange=[.05,50],ylog=1
	if size(mvn_c0_dat,/type) eq 8 then store_data,'bkg2c0',data={x:mvn_c0_dat.time+2.,y:bkg2c0}
		options,'bkg2c0',colors=cols.red,psym=1,ystyle=1,yrange=[.05,50],ylog=1
	if size(mvn_c8_dat,/type) eq 8 then store_data,'bkg2c8',data={x:(mvn_c8_dat.time+mvn_c8_dat.end_time)/2.,y:bkg2c8}
		options,'bkg2c8',colors=cols.cyan,psym=2
	if size(mvn_ca_dat,/type) eq 8 then store_data,'bkg2ca',data={x:(mvn_ca_dat.time+mvn_ca_dat.end_time)/2.,y:bkg2ca}
		options,'bkg2ca',colors=cols.green,psym=4
	if size(mvn_d0_dat,/type) eq 8 then store_data,'bkg2d0',data={x:(mvn_d0_dat.time+mvn_d0_dat.end_time)/2.,y:bkg2d0}
		options,'bkg2d0',colors=cols.blue,psym=1
	if size(mvn_d1_dat,/type) eq 8 then store_data,'bkg2d1',data={x:(mvn_d1_dat.time+mvn_d1_dat.end_time)/2.,y:bkg2d1}
		options,'bkg2d1',colors=cols.magenta,psym=1

	store_data,'bkg2_test',data=['bkg1c6','bkg2c6','bkg2c0','bkg2c8','bkg2ca','bkg2d1','bkg2d0','bkg2c6']
		options,'bkg2_test',ystyle=1,yrange=[.05,500],ylog=1

	if keyword_set(tplot) then begin
		mvn_sta_l2_tplot,/test,/all,/replace
		tplot,['cnt_0_15_and_32_55','cnt_bkg_56_63','coincidence_corr','mvn_sta_d0_E','mvn_sta_da_E','mvn_sta_c6_M_twt']
	endif

; print out the run time

	print,'mvn_sta_bkg_correct run time = ',systime(1)-starttime

; restore the dat_dead common block

	mvn_sta_restore_the_dead,maven_dead_dir=maven_dead_dir,expand=1000.

	if keyword_set(test) then begin 
		npts=n_elements(dat_dead.time)
		pk_droop=fltarr(npts)
		max_droop=fltarr(npts)
		avg_droop=fltarr(npts)
		min_droop=fltarr(npts)

		for i=0,npts-1 do pk_droop[i]=max(dat_dead.droop[i,*,*])
		for i=0,npts-1 do max_droop[i]=max(total(dat_dead.droop[i,*,*],3)/16.)
		for i=0,npts-1 do avg_droop[i]=total(dat_dead.droop[i,*,*])/(16.*64)
		for i=0,npts-1 do min_droop[i]=min(dat_dead.droop[i,*,*])

		store_data,'pk_max_droop',data={x:dat_dead.time,y:[[pk_droop],[max_droop]]}
			ylim,'max_avg_droop',0,4,0
		store_data,'min_avg_droop',data={x:dat_dead.time,y:[[avg_droop],[min_droop]]}
			ylim,'min_avg_droop',0,4,0
		store_data,'min_max_droop',data={x:dat_dead.time,y:[[max_droop],[min_droop]]}
			ylim,'min_max_droop',0,4,0
		store_data,'min_droop',data={x:dat_dead.time,y:[min_droop]}
			ylim,'min_droop',0,4,0
		store_data,'avg_droop',data={x:dat_dead.time,y:[avg_droop]}
			ylim,'avg_droop',0,4,0
	endif

; now run mvn_sta_bkg_stragglers_all

	print,'Starting mvn_sta_bkg_stragglers_all -- this will take 1-2 hours to run'
	mvn_sta_bkg_stragglers_all

; save the expanded time range c6_bkg

	c6_bkg = mvn_c6_dat.bkg

; reload c6 with the day boundary and insert the proper c6_bkg

		minval = min(abs(time-tr_c6[0]-2.),ind0)
		minval = min(abs(time-tr_c6[1]-2.),ind1)
		timespan,tt_day[0],1
		mvn_sta_l2_load, sta_apid = ['c6'],/no_time_clip
		if (ind1-ind0+1) eq n_elements(mvn_c6_dat.time) then begin
			mvn_c6_dat.bkg = c6_bkg[ind0:ind1,*,*]
			print,'c6_bkg properly restored'
		endif else begin
			print,'Error in restoring c6 bkg - indexes dont match - using nearest value'
			for mm = 0,n_elements(mvn_c6_dat.time)-1 do begin
				minval=min(abs(mvn_c6_dat.time[mm]-time),indval)
				mvn_c6_dat.bkg[mm,*,*] = c6_bkg[indval,*,*]
			endfor
			print,'Error in restoring c6 bkg - indexes dont match - using nearest value'
		endelse

; restore the eflux in the common blocks

		mvn_sta_l2eflux, mvn_c0_dat
		mvn_sta_l2eflux, mvn_c6_dat
		mvn_sta_l2eflux, mvn_c8_dat
		mvn_sta_l2eflux, mvn_ca_dat
		mvn_sta_l2eflux, mvn_d0_dat
		if size(mvn_d1_dat,/type) eq 8 then mvn_sta_l2eflux, mvn_d1_dat

; print out the run time

	print,'mvn_sta_bkg_correct_straggle run time = ',systime(1)-starttime
	print,'data now ready to save in iv3 directories

end
