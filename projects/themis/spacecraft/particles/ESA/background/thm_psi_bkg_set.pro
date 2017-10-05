;+
;PROCEDURE:	thm_psi_bkg_set,sc=sc,tt_on=tt_on,tt_off=tt_off
;INPUT:	
;	
;PURPOSE:
;	User selects time interval for determining ion sst background counts, use fast survey if available
;
;CREATED BY:
;	J.McFadden	10-04-25
;Modifications
;	J.McFadden	
;
;Assumptions
;		Needs corrections for different detector gf for psir6		 
;-

pro thm_psi_bkg_set,sc=sc,tt_on=tt_on,tt_off=tt_off


; sc default
	if not keyword_set(sc) then begin
		print,'Error - sc keyword must be set!'
		return
	endif

; one spacecraft at a time - background intervals differ for different s/c
	if n_elements(sc) gt 1 then begin
		print,' Error - sc keyword must be set to one of the following - a,b,c,d,e'
		return
	endif

; set up commons

	if sc eq 'a' then begin
		common tha_psi_bkg,tha_psir1_on,tha_psir6_on,tha_psif_on,tha_psir1_off,tha_psir6_off,tha_psif_off,dt_ar1_on,dt_ar6_on,dt_af_on,dt_ar1_off,dt_ar6_off,dt_af_off
	endif else if sc eq 'b' then begin
		common thb_psi_bkg,thb_psir1_on,thb_psir6_on,thb_psif_on,thb_psir1_off,thb_psir6_off,thb_psif_off,dt_br1_on,dt_br6_on,dt_bf_on,dt_br1_off,dt_br6_off,dt_bf_off
	endif else if sc eq 'c' then begin
		common thc_psi_bkg,thc_psir1_on,thc_psir6_on,thc_psif_on,thc_psir1_off,thc_psir6_off,thc_psif_off,dt_cr1_on,dt_cr6_on,dt_cf_on,dt_cr1_off,dt_cr6_off,dt_cf_off
	endif else if sc eq 'd' then begin
		common thd_psi_bkg,thd_psir1_on,thd_psir6_on,thd_psif_on,thd_psir1_off,thd_psir6_off,thd_psif_off,dt_dr1_on,dt_dr6_on,dt_df_on,dt_dr1_off,dt_dr6_off,dt_df_off
	endif else if sc eq 'e' then begin
		common the_psi_bkg,the_psir1_on,the_psir6_on,the_psif_on,the_psir1_off,the_psir6_off,the_psif_off,dt_er1_on,dt_er6_on,dt_ef_on,dt_er1_off,dt_er6_off,dt_ef_off
	endif else if sc eq 'f' then begin
		common thf_psi_bkg,thf_psir1_on,thf_psir6_on,thf_psif_on,thf_psir1_off,thf_psir6_off,thf_psif_off,dt_fr1_on,dt_fr6_on,dt_ff_on,dt_fr1_off,dt_fr6_off,dt_ff_off
	endif

; check for tplot variable 'th'+sc+'_psir_atten', and create it if it doesn't exist

	name2='th'+sc+'_psir_atten'
	get_data,name2,data=tmp2,index=index
	if index eq 0 then begin
		thm_get_2dt,'sst_atten','thm_sst_psir',name=name2,probe=sc,gap_time=10000.
			ylim,name2,0.,11,0
			options,name2,'ytitle','e- sst th'+sc+'!C!C Atten'
		get_data,name2,data=tmp2
	endif

	name3='th'+sc+'_psif_atten'
	get_data,name3,data=tmp3,index=index
	if index eq 0 then begin
		thm_get_2dt,'sst_atten','thm_sst_psif',name=name3,probe=sc,gap_time=10000.
			ylim,name3,0.,11,0
			options,name3,'ytitle','e- sst th'+sc+'!C!C Atten'
		get_data,name3,data=tmp3
	endif

; index compression of full to reduced 6 angle -- this probably doesn't work, psir6 background subtraction may have bugs

	case sc of 
		'a' : psir6_fix_date = time_double('09-02-02/22:30:14')
		'b' : psir6_fix_date = time_double('09-02-06/00:00')
		'c' : psir6_fix_date = time_double('09-02-06/00:00')
		'd' : psir6_fix_date = time_double('09-02-06/00:00')
		'e' : psir6_fix_date = time_double('09-02-06/00:00')
		'f' : psir6_fix_date = time_double('09-02-06/00:00')
	endcase

	if tmp2.x(0) lt psir6_fix_date then begin
		ind0=indgen(16)
		ind1=indgen(16)+48
		ind2=[indgen(4)+16,indgen(4)+32]
		ind3=[indgen(4)+20,indgen(4)+36]
		ind4=[indgen(4)+24,indgen(4)+40]
		ind5=[indgen(4)+28,indgen(4)+44]
	endif else begin
		ind0=indgen(16)
		ind1=indgen(16)+16
		ind2=[indgen(4)+32,indgen(4)+56]
		ind3=[indgen(4)+36,indgen(4)+60]
		ind4=[indgen(4)+40,indgen(4)+48]
		ind5=[indgen(4)+44,indgen(4)+52]
	endelse


; plot the data for selection

	tplot,['th'+sc+'_psir_atten','th'+sc+'_psir_en','th'+sc+'_psir6_en','th'+sc+'_peer_en_counts','th'+sc+'_psif_atten','th'+sc+'_psif_en','th'+sc+'_peef_en_counts']

; select atten=on time interval (atten=5)

	print,'****************************Attention************************************'
	print,'Select interval for atten=on, atten=5'
	print,'****************************Attention************************************'

	if not keyword_set(tt_on) then ctime,tt_on

   if not keyword_set(tt_on) then begin
		if sc eq 'a' then begin
			tha_psir1_on=0.  & tha_psir6_on=0.  & tha_psif_on=0.  & dt_ar1_on=3.  & dt_ar6_on=3.  & dt_af_on=3.
		endif else if sc eq 'b' then begin
			thb_psir1_on=0.  & thb_psir6_on=0.  & thb_psif_on=0.  & dt_br1_on=3.  & dt_br6_on=3.  & dt_bf_on=3.
		endif else if sc eq 'c' then begin
			thc_psir1_on=0.  & thc_psir6_on=0.  & thc_psif_on=0.  & dt_cr1_on=3.  & dt_cr6_on=3.  & dt_cf_on=3.
		endif else if sc eq 'd' then begin
			thd_psir1_on=0.  & thd_psir6_on=0.  & thd_psif_on=0.  & dt_dr1_on=3.  & dt_dr6_on=3.  & dt_df_on=3.
		endif else if sc eq 'e' then begin
			the_psir1_on=0.  & the_psir6_on=0.  & the_psif_on=0.  & dt_er1_on=3.  & dt_er6_on=3.  & dt_ef_on=3.
		endif else if sc eq 'f' then begin
			thf_psir1_on=0.  & thf_psir6_on=0.  & thf_psif_on=0.  & dt_fr1_on=3.  & dt_fr6_on=3.  & dt_ff_on=3.
		endif
;		return
   endif else begin 

; reorder times if backward

	if n_elements(tt_on) eq 1 then begin
		t1=tt_on & t2=tt_on
	endif else if n_elements(tt_on) gt 1 then begin
		t1=tt_on(0) & t2=tt_on(1)
		if t1 gt t2 then begin
			t1=tt_on(1) & t2=tt_on(0)
		endif
	endif

; get psir background for atten=on

	rdat = thm_sst_psir(t1,probe=sc,index=ind)
	data = rdat.data
	ndat = n_elements(rdat.data)
	ravg = 1
	dt = rdat.end_time-rdat.time

	while rdat.end_time lt t2 do begin
		ind=ind+1
		rdat = thm_sst_psir(probe=sc,index=ind)
		if n_elements(rdat.data) eq ndat then begin
			data = data + rdat.data 
			ravg = ravg + 1
			dt = dt + (rdat.end_time-rdat.time)
		endif else begin
			print,'Error - time interval includes multiple psir data types, terminating average'
			rdat.end_time = t2 + 1.
		endelse
	endwhile
	data = data/ravg 
	dt = dt/ravg
	if ndat eq 96 then begin
		data = data - reform(data(*,3)+data(*,5))#[1.,1.,.5,0.,.5,0.] > 0.
		data[*,3] = 0. & data[*,5] = 0.
	endif

; get psif background for atten=on

	fdat = thm_sst_psif(t1,probe=sc,index=indf)
	dataf = fdat.data
	ndat = n_elements(fdat.data)
	favg = 1
	dt_f = fdat.end_time-fdat.time

	while fdat.end_time lt t2 do begin
		indf=indf+1
		fdat = thm_sst_psif(probe=sc,index=indf)
		if n_elements(fdat.data) eq ndat then begin
			dataf= dataf+fdat.data 
			favg = favg + 1
			dt_f = dt_f + (fdat.end_time-fdat.time)
		endif else begin
			print,'Error - time interval includes multiple psif data types, terminating average'
			fdat.end_time = t2 + 1.
		endelse
	endwhile
	dataf = dataf/favg
	dt_f = dt_f/favg

	ib=total(dataf,1)
	ibmax = max(ib,imax_ind)
	if ibmax lt 100. then imax_ind=-1
	
	dataf2 = dataf & dataf[*] = 0.

	if imax_ind eq 55 or imax_ind eq 56 or imax_ind eq 40 or imax_ind eq 8 then begin
		dataf[*,[8,40,55,56]] = !values.f_nan
		dataf[*,9] = dataf2[*,9]-dataf2[*,10]
		dataf[*,24:25] = dataf2[*,24:25]-dataf2[*,[23,26]]
		dataf[*,41] = dataf2[*,41]-dataf2[*,42]
		dataf[*,57:58] = dataf2[*,57:58]-dataf2[*,[59,59]]
	endif else if imax_ind eq 47 or imax_ind eq 32 or imax_ind eq 48 or imax_ind eq 16 then begin
		dataf[*,[16,32,47,48]] = !values.f_nan
		dataf[*,0:1] = dataf2[*,0:1]-dataf2[*,[15,2]]
		dataf[*,17] = dataf2[*,17]-dataf2[*,18]
		dataf[*,33:34] = dataf2[*,33:34]-dataf2[*,[35,35]]
		dataf[*,49] = dataf2[*,49]-dataf2[*,50]
	endif

	indb = where(dataf lt 2., count) 
	if count ne 0 then dataf(indb) = 0.

; if favg gt ravg then form datar from dataf

	if favg gt ravg then begin
		data1 = total(dataf,2)
		data = fltarr(16,6)
		data(*,0) = total(dataf(*,ind0),2)
		data(*,1) = total(dataf(*,ind1),2)
		data(*,2) = total(dataf(*,ind2),2)
		data(*,3) = total(dataf(*,ind3),2)
		data(*,4) = total(dataf(*,ind4),2)
		data(*,5) = total(dataf(*,ind5),2)
		dt1=dt_f
		dt6=dt_f
		print,' Background for psir6 and psir1 are determined from psif'
	endif else if ndimen(data) eq 2 then begin
		data1 = total(data,2) 
		dt1=dt
		dt6=dt
		print,' Interval has psir6 so background for psir1 is determined from average of psir6'
	endif else begin
		data1 = data
		dt1=dt
		data = fltarr(16,6)
		data(*,0) = total(dataf(*,ind0),2)
		data(*,1) = total(dataf(*,ind1),2)
		data(*,2) = total(dataf(*,ind2),2)
		data(*,3) = total(dataf(*,ind3),2)
		data(*,4) = total(dataf(*,ind4),2)
		data(*,5) = total(dataf(*,ind5),2)
		dt6=dt_f
		print,' Interval is slow survey so background for psir6 is determined from psif'
	endelse

; put background in common block

	if sc eq 'a' then begin
		tha_psir1_on=data1 & tha_psir6_on=data & tha_psif_on=dataf & dt_ar1_on=dt1 & dt_ar6_on=dt6 & dt_af_on=dt_f
	endif else if sc eq 'b' then begin
		thb_psir1_on=data1 & thb_psir6_on=data & thb_psif_on=dataf & dt_br1_on=dt1 & dt_br6_on=dt6 & dt_bf_on=dt_f
	endif else if sc eq 'c' then begin
		thc_psir1_on=data1 & thc_psir6_on=data & thc_psif_on=dataf & dt_cr1_on=dt1 & dt_cr6_on=dt6 & dt_cf_on=dt_f
	endif else if sc eq 'd' then begin
		thd_psir1_on=data1 & thd_psir6_on=data & thd_psif_on=dataf & dt_dr1_on=dt1 & dt_dr6_on=dt6 & dt_df_on=dt_f
	endif else if sc eq 'e' then begin
		the_psir1_on=data1 & the_psir6_on=data & the_psif_on=dataf & dt_er1_on=dt1 & dt_er6_on=dt6 & dt_ef_on=dt_f
	endif else if sc eq 'f' then begin
		thf_psir1_on=data1 & thf_psir6_on=data & thf_psif_on=dataf & dt_fr1_on=dt1 & dt_fr6_on=dt6 & dt_ff_on=dt_f
	endif

   endelse
		
; select atten=off time interval (atten=10)

	print,'****************************Attention************************************'
	print,'Select interval for atten=off, atten=10'
	print,'****************************Attention************************************'

	wait,1
	if not keyword_set(tt_off) then ctime,tt_off

	if not keyword_set(tt_off) then begin
		if sc eq 'a' then begin
			tha_psir1_off=0. & tha_psir6_off=0. & tha_psif_off=0. & dt_ar1_off=3. & dt_ar6_off=3. & dt_af_off=3.
		endif else if sc eq 'b' then begin
			thb_psir1_off=0. & thb_psir6_off=0. & thb_psif_off=0. & dt_br1_off=3. & dt_br6_off=3. & dt_bf_off=3.
		endif else if sc eq 'c' then begin
			thc_psir1_off=0. & thc_psir6_off=0. & thc_psif_off=0. & dt_cr1_off=3. & dt_cr6_off=3. & dt_cf_off=3.
		endif else if sc eq 'd' then begin
			thd_psir1_off=0. & thd_psir6_off=0. & thd_psif_off=0. & dt_dr1_off=3. & dt_dr6_off=3. & dt_df_off=3.
		endif else if sc eq 'e' then begin
			the_psir1_off=0. & the_psir6_off=0. & the_psif_off=0. & dt_er1_off=3. & dt_er6_off=3. & dt_ef_off=3.
		endif else if sc eq 'f' then begin
			thf_psir1_off=0. & thf_psir6_off=0. & thf_psif_off=0. & dt_fr1_off=3. & dt_fr6_off=3. & dt_ff_off=3.
		endif
		return
	endif
	if n_elements(tt_off) eq 1 then begin
		t1=tt_off & t2=tt_off
	endif else if n_elements(tt_off) gt 1 then begin
		t1=tt_off(0) & t2=tt_off(1)
		if t1 gt t2 then begin
			t1=tt_off(1) & t2=tt_off(0)
		endif
	endif

; get psir background for atten=off

print,time_string(t1),t1
;print,time_string(t1),t1,ind

	rdat = thm_sst_psir(t1,probe=sc,index=ind)
	data = rdat.data
	ndat = n_elements(rdat.data)
	ravg = 1
	dt = rdat.end_time-rdat.time

	while rdat.end_time lt t2 do begin
		ind=ind+1
		rdat = thm_sst_psir(probe=sc,index=ind)
		if n_elements(rdat.data) eq ndat then begin
			data = data + rdat.data 
			ravg = ravg + 1
			dt = dt + (rdat.end_time-rdat.time)
		endif else begin
			print,'Error - time interval includes multiple psir data types, terminating average'
			rdat.end_time = t2 + 1.
		endelse
	endwhile
	data = data/ravg
	dt = dt/ravg
	if ndat eq 96 then begin
		data = data - reform(data(*,3)+data(*,5))#[1.,1.,.5,0.,.5,0.] > 0.
		data[*,3] = 0. & data[*,5] = 0.
	endif

; get psif background for atten=off

	fdat = thm_sst_psif(t1,probe=sc,index=indf)
	dataf = fdat.data
	ndat = n_elements(fdat.data)
	favg = 1
	dt_f = fdat.end_time-fdat.time

	while fdat.end_time lt t2 do begin
		indf=indf+1
		fdat = thm_sst_psif(probe=sc,index=indf)
		if n_elements(fdat.data) eq ndat then begin
			dataf= dataf+fdat.data 
			favg = favg + 1
			dt_f = dt_f + (fdat.end_time-fdat.time)
		endif else begin
			print,'Error - time interval includes multiple psif data types, terminating average'
			fdat.end_time = t2 + 1.
		endelse
	endwhile

	dataf = dataf/favg
	dt_f = dt_f/favg

	ib=total(dataf,1)
	ibmax = max(ib,imax_ind)
	if ibmax lt 100. then imax_ind=-1
	
	dataf2 = dataf & dataf[*] = 0.

	if imax_ind eq 55 or imax_ind eq 56 or imax_ind eq 40 or imax_ind eq 8 then begin
		dataf[*,[8,40,55,56,57]] = !values.f_nan
		dataf[*,9] = dataf2[*,9]-dataf2[*,10]
		dataf[*,24:25] = dataf2[*,24:25]-dataf2[*,[23,26]]
		dataf[*,41] = dataf2[*,41]-dataf2[*,42]
		dataf[*,58] = dataf2[*,58]-dataf2[*,59]
	endif else if imax_ind eq 47 or imax_ind eq 32 or imax_ind eq 48 or imax_ind eq 16 then begin
		dataf[*,[16,32,33,47,48]] = !values.f_nan
		dataf[*,0:1] = dataf2[*,0:1]-dataf2[*,[15,2]]
		dataf[*,17] = dataf2[*,17]-dataf2[*,18]
		dataf[*,34] = dataf2[*,34]-dataf2[*,35]
		dataf[*,49] = dataf2[*,49]-dataf2[*,50]
	endif

	indb = where(dataf lt 2., count) 
	if count ne 0 then dataf(indb) = 0.

; if favg gt ravg then form datar from dataf

	if favg gt ravg then begin
		data1 = total(dataf,2)
		data = fltarr(16,6)
		data(*,0) = total(dataf(*,ind0),2)
		data(*,1) = total(dataf(*,ind1),2)
		data(*,2) = total(dataf(*,ind2),2)
		data(*,3) = total(dataf(*,ind3),2)
		data(*,4) = total(dataf(*,ind4),2)
		data(*,5) = total(dataf(*,ind5),2)
		dt1=dt_f
		dt6=dt_f
		print,' Background for psir6 and psir1 are determined from psif'
	endif else if ndimen(data) eq 2 then begin
		data1 = total(data,2) 
		dt1=dt
		dt6=dt
		print,' Interval has psir6 so background for psir1 is determined from average of psir6'
	endif else begin
		data1 = data
		dt1=dt
		data = fltarr(16,6)
		data(*,0) = total(dataf(*,ind0),2)
		data(*,1) = total(dataf(*,ind1),2)
		data(*,2) = total(dataf(*,ind2),2)
		data(*,3) = total(dataf(*,ind3),2)
		data(*,4) = total(dataf(*,ind4),2)
		data(*,5) = total(dataf(*,ind5),2)
		dt6=dt_f
		print,' Interval is slow survey so background for psir6 is determined from psif'
	endelse

; put background in common block

	if sc eq 'a' then begin
		tha_psir1_off=data1 & tha_psir6_off=data & tha_psif_off=dataf & dt_ar1_off=dt1 & dt_ar6_off=dt6 & dt_af_off=dt_f
	endif else if sc eq 'b' then begin
		thb_psir1_off=data1 & thb_psir6_off=data & thb_psif_off=dataf & dt_br1_off=dt1 & dt_br6_off=dt6 & dt_bf_off=dt_f
	endif else if sc eq 'c' then begin
		thc_psir1_off=data1 & thc_psir6_off=data & thc_psif_off=dataf & dt_cr1_off=dt1 & dt_cr6_off=dt6 & dt_cf_off=dt_f
	endif else if sc eq 'd' then begin
		thd_psir1_off=data1 & thd_psir6_off=data & thd_psif_off=dataf & dt_dr1_off=dt1 & dt_dr6_off=dt6 & dt_df_off=dt_f
	endif else if sc eq 'e' then begin
		the_psir1_off=data1 & the_psir6_off=data & the_psif_off=dataf & dt_er1_off=dt1 & dt_er6_off=dt6 & dt_ef_off=dt_f
	endif else if sc eq 'f' then begin
		thf_psir1_off=data1 & thf_psir6_off=data & thf_psif_off=dataf & dt_fr1_off=dt1 & dt_fr6_off=dt6 & dt_ff_off=dt_f
	endif
		


end
