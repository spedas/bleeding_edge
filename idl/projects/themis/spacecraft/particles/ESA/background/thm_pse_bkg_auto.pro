;+
;PROCEDURE:	thm_pse_bkg_auto,sc=sc,t1=t1,t2=t2
;INPUT:	
;	
;PURPOSE:
;	Generates 'th'+sc+'_pser_minus_bkg' for use by thm_load_esa_bkg.pro -- Auto selects time interval for pser background subtract
;
;CREATED BY:
;	J.McFadden	09-01-01
;Modifications
;	J.McFadden	09-02-05	modified to work with both attenuator on and off	
;	J.McFadden	09-04-15	modified to include correct calibrations	
;	J.McFadden	09-09-16	modified to include modes with psef w/ spin resolution and pser w/o spin resolution
; aflores   2016-06-30  minor changes to integrate with spedas	
;Assumptions
;	SST data is already loaded
;	Uses pser data only - assumes it is the highest time resolution	 
;-

pro thm_pse_bkg_auto,sc=sc,t1=t1,t2=t2

  compile_opt strictarr

; sc default
	if not keyword_set(sc) then begin
		dprint,'Error - sc keyword must be set!', level=0
		return
	endif

; time range default
	if not keyword_set(t1) then begin
		tt=timerange()
		t1=tt[0] & t2=tt[1]
	endif

; one spacecraft at a time - background intervals differ for different s/c
	if n_elements(sc) gt 1 then begin
		dprint,' Error - sc keyword must be set to one of the following - a,b,c,d,e', level=0
		return
	endif

; load pser data in counts and get attenuator status
	gap_time = 1.e8

	get_dat='thm_sst_pser'
	name1='th'+sc+'_pser_counts'
	thm_get_en_spec,get_dat,units='counts',name=name1,probe=sc,t1=t1,t2=t2,gap_time=gap_time
		ylim,name1,10000.,1000000.,1
		zlim,name1,100.,100000.,1
		options,name1,'ytitle','e- th'+sc+'!C!CCounts'
		options,name1,'spec',1
	name2='th'+sc+'_pser_atten'
	thm_get_2dt,'sst_atten',get_dat,name=name2,probe=sc,t1=t1,t2=t2,gap_time=gap_time
		ylim,name2,0.,11,0
		options,name2,'ytitle','e- sst th'+sc+'!C!C Atten'
    ;if variable already exists from thm_load_sst then tplot will attempt to use bitplot (var is float)
    options,name2,'tplot_routine',/default
	name3='th'+sc+'_pser6_counts_bin'
	thm_get_en_spec,get_dat,units='counts',name=name3,probe=sc,t1=t1,t2=t2,bins=[0,0,0,1,0,1],gap_time=gap_time
		ylim,name3,10000.,1000000.,1
		zlim,name3,100.,100000.,1
		options,name3,'ytitle','e- th'+sc+'!C!CCounts'
		options,name3,'spec',1
	get_dat='thm_sst_psef'
	name4='th'+sc+'_psef_counts_bin'
	thm_get_en_spec,get_dat,units='counts',name=name4,probe=sc,t1=t1,t2=t2,gap_time=gap_time
		ylim,name4,10000.,1000000.,1
		zlim,name4,100.,100000.,1
		options,name4,'ytitle','e- th'+sc+'!C!CCounts'
		options,name4,'spec',1
	name5='th'+sc+'_psef_atten'
	thm_get_2dt,'sst_atten',get_dat,name=name5,probe=sc,t1=t1,t2=t2,gap_time=gap_time
		ylim,name5,0.,11,0
		options,name5,'ytitle','e- sst th'+sc+'!C!C Atten'
	name6='th'+sc+'_psef6_counts_bin'
	bins=bytarr(64) & bins[50:53]=1 & bins[58:61]=1 & bins[34:37]=1 & bins[42:45]=1
	thm_get_en_spec,get_dat,units='counts',name=name6,probe=sc,t1=t1,t2=t2,bins=bins,gap_time=gap_time
		ylim,name6,10000.,1000000.,1
		zlim,name6,100.,100000.,1
		options,name6,'ytitle','e- th'+sc+'!C!CCounts'
		options,name6,'spec',1

	get_data,name1,data=tmp1
	get_data,name2,data=tmp2
	get_data,name3,data=tmp3
	get_data,name4,data=tmp4
	get_data,name5,data=tmp5
	get_data,name6,data=tmp6

  if ~is_struct(tmp) || ~is_struct(tmp) || ~is_struct(tmp) || $ 
     ~is_struct(tmp) || ~is_struct(tmp) || ~is_struct(tmp) then begin
    dprint, 'Missing required SST data for background determination', dlevel=1
    return
  endif

	ntmp1 = n_elements(tmp1.x)
	ntmp2 = n_elements(tmp2.x)
	ntmp3 = n_elements(tmp3.x)
	ntmp4 = n_elements(tmp4.x)
	ntmp5 = n_elements(tmp5.x)
	ntmp6 = n_elements(tmp6.x)
;print,ntmp1,ntmp2,ntmp3,ntmp4,ntmp5,ntmp6
if ntmp1 ne ntmp2 or ntmp4 ne ntmp5 then begin
	dprint,'Error: Time samples between SST variables to not match.  Canceling PSER background calculation.', level=0
	return
endif

; don't bother using psef before 2009-03-01 since pser has spin resolution before this date
if time_double(t1) gt time_double('2009-02-01/23:59') then begin
	ntimes=ntmp1+ntmp4
	times=[tmp1.x,tmp4.x+.1] 
	ptot=[total(tmp1.y[*,0:8],2),total(tmp4.y[*,0:8],2)]
	ptmp=[tmp1.y,tmp4.y]
	ptmp6=[tmp3.y,tmp6.y]
	atot=[tmp2.y,tmp5.y]
	sind=sort(times) 
	times=times[sind] & ptot=ptot[sind] & atot=atot[sind] 
	ptmp=ptmp[sind,*] & ptmp6=ptmp6[sind,*]
	sind2=where(times[1:ntimes-1]-times[0:ntimes-2] gt 1.) 
	times=[times[sind2],times[ntimes-1]]
	ptot=[ptot[sind2],ptot[ntimes-1]]
	ptmp=[ptmp[sind2,*],ptmp[ntimes-1,*]]
	ptmp6=[ptmp6[sind2,*],ptmp6[ntimes-1,*]]
	ptot6 = total(ptmp6,2)
	atot=[atot[sind2],atot[ntimes-1]]
	ntot=n_elements(atot)
	ind_on  = where(atot eq 5,cnt_on)
	ind_off = where(atot ne 5,cnt_off)
	nrg = n_elements(tmp1.y[0,*])
	energy = reform(tmp1.v[0,*])
endif else begin
	ntot = n_elements(tmp1.x)
	times=tmp1.x
	ptot=total(tmp1.y[*,0:8],2)
	ptmp=tmp1.y
	ptmp6=tmp3.y
	atot = tmp2.y
	ptot6 = total(tmp3.y,2)
	ind_on  = where(atot eq 5,cnt_on)
	ind_off = where(atot ne 5,cnt_off)
	nrg = n_elements(tmp1.y[0,*])
	energy = reform(tmp1.v[0,*])
endelse

; attenuator ON: determine intervals with lowest counts for pser background 

	if cnt_on ne 0 then begin
		atten = replicate(1.,ntot) 
		if cnt_off ne 0 then atten[ind_off] = 100000. 



;		print,'minmax(ptot)=',minmax(ptot)
		scale = 2.^(1./32.)
		npts = 0l 
		pmax = 500.*scale & pmin = 5.
		while npts lt 100 and pmax lt 8000. do begin
			ind = where(ptot*atten lt pmax and ptot*atten gt pmin and ptot6 ne 0.,npts)
			pmax = pmax*scale
		endwhile
		if npts gt 50 then begin
;				the following could include a correction for relative sensitivity instead of just 4.*
			pbak_on = total(ptmp[ind,*],1)/npts - 4.*total(ptmp6[ind,*],1)/npts
;print,'pbak_on'
;print,pbak_on
;print,total(ptmp(ind,*),1)/npts
;print,4.*total(ptmp6(ind,*),1)/npts
		endif else begin
			npts = 0l 
			pmax = 500.*scale & pmin = 5.
			while npts lt 100 and pmax lt 8000. do begin
				ind = where(ptot*atten lt pmax and ptot*atten gt pmin,npts)
				pmax = pmax*scale
			endwhile
			if npts gt 50 then pbak_on = total(ptmp[ind,*],1)/npts else pbak_on = fltarr(nrg)
		endelse
	endif else pbak_on = fltarr(nrg)
	pbak_on = pbak_on > 0.

; display the pser counts and levels used for pser background determination
; diagnostics
;	print,'npts, pmax, cnt_on', npts,pmax/scale,cnt_on
;	print,'pbak_on=',pbak_on
		window,2,xsize=800,ysize=800
		plot,ptot,yrange=[100.,10000000.],ylog=1,title='PSER background auto select'
		if keyword_set(pmax) then begin
			oplot,[0.,100000.],[pmax,pmax]/scale
			oplot,[0.,100000.],[pmax,pmax]/scale^2
		endif


; attenuator OFF: determine intervals with lowest counts for pser background 

	if cnt_off ne 0 then begin
		atten = replicate(1.,ntot) 
		if cnt_on ne 0 then atten[ind_on] = 1000000. 

;		print,'minmax(ptot)=',minmax(ptot)
		scale = 2.^(1./32.)
		npts = 0l 
		pmax = 500.*scale & pmin = 5.
		while npts lt 20 and pmax lt 20000. do begin
			ind = where(ptot*atten lt pmax and ptot*atten gt pmin and ptot6 ne 0.,npts)
			pmax = pmax*scale
		endwhile
		if npts gt 10 then begin
;				the following could include a correction for relative sensitivity instead of just 4.*
			pbak_off = total(ptmp[ind,*],1)/npts - 4.*total(ptmp6[ind,*],1)/npts
;print,'pbak_off'
;print,pbak_off
;print,total(ptmp(ind,*),1)/npts
;print,4.*total(ptmp6(ind,*),1)/npts
		endif else begin

			npts = 0l 
			pmax = 500.*scale & pmin = 5.
			while npts lt 20 and pmax lt 20000. do begin
				ind = where(ptot*atten lt pmax and ptot*atten gt pmin,npts)
				pmax = pmax*scale
			endwhile
			if npts gt 10 then pbak_off = total(ptmp[ind,*],1)/npts else pbak_off = fltarr(nrg)
		endelse
	endif else pbak_off = fltarr(nrg)
	pbak_off = pbak_off > 0.

; display the pser counts and levels used for pser background determination
; diagnostics
;	print,'npts, pmax, cnt_off', npts,pmax/scale,cnt_off
;	print,'pbak_off=',pbak_off
		oplot,ptot,color=6
		if keyword_set(pmax) then begin
			oplot,[0.,100000.],[pmax,pmax]/scale,color=6
			oplot,[0.,100000.],[pmax,pmax]/scale^2,color=6
		endif

; calculate and subtract background from pser data and store

	bak_on = fltarr(ntot) & bak_off=fltarr(ntot)
	if cnt_on  ne 0 then bak_on[ind_on]=1. 
	if cnt_off ne 0 then bak_off[ind_off]=1. 
	tmp = ptmp - bak_on#pbak_on - bak_off#pbak_off > 0.
	tmp0 = ptmp > 0.

; normalize for attenuators 	
;	gf_scale is the for the atten=on, gf_scale2 is for atten=off
;	gf_scale changes so slowly over time, it is not worth making minor correction

	if sc eq 'a' then begin
		gf_scale=[1.08,1.03,1.02,0.87]*1.30				; tha atten=on
		gf_scale2=[1.04,1.09,0.93,0.94]*1.20				; tha atten=off	
		scale=64.*total(gf_scale/gf_scale2)/4.
	endif else if sc eq 'b' then begin
		gf_scale=[1.14,0.89,1.03,0.94]*1.30			; thb,  2007-12-12/03:19:39	; after 20071208/02:19 
		gf_scale2=[0.98,0.85,1.06,1.11]*1.20				; thb atten=off	
		scale=64.*total(gf_scale/gf_scale2)/4.
	endif else if sc eq 'c' then begin
		gf_scale=[1.26,0.82,1.04,0.88]*1.10				; thc, atten=on,  2009
		gf_scale2=[1.14,0.91,1.01,0.94]*1.20				; thc, atten=off, 2009	
		scale=64.*total(gf_scale/gf_scale2)/4.
	endif else if sc eq 'd' then begin
		gf_scale=[1.16,0.98,0.95,0.91]*1.30				; thd, atten=on,  2009
		gf_scale2=[1.13,1.05,0.88,0.94]*1.20				; thd, atten=off, 2009	
		scale=64.*total(gf_scale/gf_scale2)/4.
	endif else if sc eq 'e' then begin
		gf_scale=[1.00,1.48,0.73,0.79]*1.50				; the, atten=on,  2009
		gf_scale2=[1.32,0.89,0.81,0.98]*1.20				; the, atten=off, 2009	
		scale=64.*total(gf_scale/gf_scale2)/4.
	endif else if sc eq 'f' then begin
		scale=64.
	endif


if cnt_off ne 0 then begin
	tmp[ind_off,*]=tmp[ind_off,*]/scale
	tmp0[ind_off,*]=tmp0[ind_off,*]/scale
endif


	store_data,'th'+sc+'_pser_minus_bkg',data={x:times,y:tmp,v:replicate(1.,ntot)#energy}
		ylim,'th'+sc+'_pser_minus_bkg',0,0,1
		zlim,'th'+sc+'_pser_minus_bkg',1,1.e5,1
		options,'th'+sc+'_pser_minus_bkg',spec=1
	store_data,'th'+sc+'_pser_with_bkg',data={x:times,y:tmp0,v:replicate(1.,ntot)#energy}
		ylim,'th'+sc+'_pser_with_bkg',0,0,1
		zlim,'th'+sc+'_pser_with_bkg',1,1.e5,1
		options,'th'+sc+'_pser_with_bkg',spec=1

dprint,'pbak_off', dlevel=4
dprint,pbak_off, dlevel=4
dprint,'pbak_on', dlevel=4
dprint,pbak_on, dlevel=4
dprint,'scale factor is the ratio of gf for att_off/att_on, should be approximately 64', dlevel=4
dprint,'scale=',scale, dlevel=4

	store_data,'th'+sc+'_pser_minus_bkg_tot0-8',data={x:times,y:total(tmp[*,0:8],2)}
		ylim,'th'+sc+'_pser_minus_bkg_tot0-8',1,1.e5,1

	store_data,'th'+sc+'_pser_with_bkg_tot0-8',data={x:times,y:total(tmp0[*,0:8],2)}
		ylim,'th'+sc+'_pser_with_bkg_tot0-8',1,1.e5,1
		options,'th'+sc+'_pser_with_bkg_tot0-8',color=6

	store_data,'th'+sc+'_pser_tot0-8',data=['th'+sc+'_pser_minus_bkg_tot0-8','th'+sc+'_pser_with_bkg_tot0-8']
		ylim,'th'+sc+'_pser_tot0-8',1,1.e5,1

;	wait,2
	tplot,['th'+sc+'_pser_tot0-8','th'+sc+'_pser_atten','th'+sc+'_pser_minus_bkg','th'+sc+'_pser_with_bkg']


end

