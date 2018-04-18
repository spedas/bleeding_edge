;+
;PROCEDURE:	mvn_sta_scpot_load
;PURPOSE:	
;	Loads scpot into static apid common blocks for science data products - only works if scpot is negative
;
;KEYWORDS:
;	check:		0,1		if set, prints diagnostic data
;
;CREATED BY:	J. McFadden	  15/01/??
;VERSION:	1
;LAST MODIFICATION:  16/02/22
;MOD HISTORY:
;
;NOTES:	  
;	Program assumes that "mvn_sta_l0_load" or "mvn_sta_l2_load,/test" has been run 
;	Program will use some combination of sta, lpw, swe data to estimate scpot
;	Assumption 1 - O2+ ram velocity only valid below 300 km
;	Assumption 2 - low energy cutoff only valid when (Ni>100/cc and alt>180km) or in shadow
;	Assumption 3 - when the above do not apply, s/c potential set to 0V 
;
;	TBDs - scpot is not valid 20151127/1:00UT - why is it invalid?
;
;	TBD - cutoff keyword forces the use of c0 cutoff for potential - needed if winds impact potential
;
;
;-
pro mvn_sta_scpot_load,tplot=tplot,max_alt=max_alt,max_nrg=max_nrg,ram_min=ram_min,max_den=max_den,max_ec=max_ec,skip=skip,kk2=kk2,swe=swe,pot_err=pot_err,alt_vo2=alt_vo2,cutoff=cutoff

	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_ca,mvn_ca_ind,mvn_ca_dat 


	if size(mvn_c6_dat,/type) ne 8 or size(mvn_c0_dat,/type) ne 8 or size(mvn_ca_dat,/type) ne 8 then begin
		print,'Error - c6, c0 and ca data must be loaded'
		return
	endif

;	mvn_c6_dat.sc_pot[*] = 0.
;	mvn_c0_dat.sc_pot[*] = 0.

	if not keyword_set(max_alt) then max_alt=10000.			; below this altitude s/c potential is assumed negative and algorithm valid when in sunlight 
									; 	potential is also assumed negative and algorithm valid in eclipse at higher altitudes
									;	as a default, we assume the algorithm works everywhere
	if not keyword_set(max_nrg) then max_nrg=30.			; -1*max_nrg is the maximum negative s/c potential determined by ram flow
	if not keyword_set(ram_min) then ram_min=0.12 			; -1*ram_min is the minimum negative s/c potential determined by ram flow

	if not keyword_set(max_den) then max_den=8. 			; if in sunlight and >250km and density<max_den and characteristic_energy>max_ec then s/c potential is set to 0
	if not keyword_set(max_ec) then max_ec=50. 			; if in sunlight and >250km and density<max_den and characteristic_energy>max_ec then s/c potential is set to 0
	if not keyword_set(pot_err) then pot_err=3. 			; ion cutoff pot < pot_err indicates valid potential, when in sunlight and >250km and ec indicates sheath 
	if not keyword_set(alt_vo2) then alt_vo2=300. 			; max alt where vel of O2+ can be used to estimate scpot - varies with local time  
 

	time = (mvn_c6_dat.time + mvn_c6_dat.end_time)/2.
	npts = n_elements(time)
	qf_valid = (mvn_c6_dat.quality_flag and 3) eq 0
	c6_mode = mvn_c6_dat.mode
	cols=get_colors()

	if not keyword_set(kk2) then kk2 = mvn_sta_get_kk2(time[0])					; correcting for ion suppression introduces errors
;	kk2=0.								

print,'kk2=',kk2

;**********************************************************
; get swe data if swe keyword is set

if keyword_set(swe) then begin

	get_data,'mvn_swe_spec_dens',data=tmp
	if size(tmp,/type) ne 8 then begin
		mvn_swe_load_l2,/spec
		mvn_swe_sumplot,/loadonly
		mvn_swe_sc_pot,/over,badval=0
		mvn_swe_n1d,/mom,background=1e3,minden=1e-4
		get_data,'mvn_swe_spec_dens',data=tmp
		if size(tmp,/type) eq 8 then begin
			swe_den = interp(tmp.y,tmp.x,time)
			get_data,'mvn_swe_spec_temp',data=tmp2
			swe_te = interp(tmp2.y,tmp2.x,time)
			swe_den = swe_den*(10./(swe_te>10.))
		endif else begin
			print,'Error - swe data not available, sc potential not loaded'
			return
		endelse
	endif else begin
		swe_den = interp(tmp.y,tmp.x,time)
		get_data,'mvn_swe_spec_temp',data=tmp2
		swe_te = interp(tmp2.y,tmp2.x,time)
		swe_den = swe_den*(10./(swe_te>10.))
	endelse
	if keyword_set(tplot) then store_data,'swe_den_scaled_te',data={x:time,y:swe_den}
		if keyword_set(tplot) then ylim,'swe_den_scaled_te',1,100,1

endif

;**********************************************************
; estimate density and characteristic energy without s/c potential corrections


	get_data,'mvn_sta_test_density3',data=tmp
	if size(tmp,/type) ne 8 or (not keyword_set(skip)) then begin

		get_4dt,'ec_4d','mvn_sta_get_c6',mass=[0,1.7],name='mvn_sta_test_ec_p',energy=[0,30000.]
			ylim,'mvn_sta_test_ec_p',1,1.e4,1
			options,'mvn_sta_test_ec_p',colors=cols.green,ytitle='sta!Cc6!Ctest!Cec_p',labels='H+He+',labpos=1000

		get_4dt,'ec_4d','mvn_sta_get_c6',mass=[10,100],name='mvn_sta_test_ec_o',energy=[0,30000.]
			ylim,'mvn_sta_test_ec_o',1,1.e4,1
			options,'mvn_sta_test_ec_o',colors=cols.red,ytitle='sta!Cc6!Ctest!Cec_o',labels='O+O++',labpos=10

		get_4dt,'n_4d','mvn_sta_get_c6',mass=[.3,5],name='mvn_sta_test_density1',m_int=1.,energy=[0,30000.]
			options,'mvn_sta_test_density1',colors=cols.green,labels='H+He+',labpos=100

		get_4dt,'n_4d','mvn_sta_get_c6',mass=[10.,100.],name='mvn_sta_test_density2',energy=[0,30000.]
			options,'mvn_sta_test_density2',colors=cols.red,labels='O+O++',labpos=1

		get_4dt,'c_4d','mvn_sta_get_c6',mass=[.3,5],name='mvn_sta_test_cnts_p_low',m_int=1.,energy=[0,12.]
			options,'mvn_sta_test_cnts_p_low',ytitle='sta!Cc6!CH+!C<12eV!Ccnts',psym=-1,colors=cols.green,labels='H+He+',labpos=100
			ylim,'mvn_sta_test_cnts_p_low',1,1000,1

		get_4dt,'c_4d','mvn_sta_get_c6',mass=[12,100],name='mvn_sta_test_cnts_o_med',m_int=32,energy=[0,30.]			; this energy range may be too high
			options,'mvn_sta_test_cnts_o_med',colors=cols.cyan,ytitle='sta!Cc6!CO+,O++!C<30eV!Ccnts',psym=-1
			ylim,'mvn_sta_test_cnts_o_med',1,1000,1

		get_4dt,'c_4d','mvn_sta_get_c6',mass=[12,100],name='mvn_sta_test_cnts_o_low',m_int=32,energy=[0,12.]			; this energy range may be too high
			options,'mvn_sta_test_cnts_o_low',ytitle='sta!Cc6!CO+,O++!C<12eV!Ccnts',psym=-1,colors=cols.red,labels='O+O++',labpos=10
			ylim,'mvn_sta_test_cnts_o_low',1,1000,1

		get_4dt,'c_4d','mvn_sta_get_c6',mass=[12,100],name='mvn_sta_test_cnts_o',m_int=32,energy=[30,40000.]			; this energy range may be too high
			options,'mvn_sta_test_cnts_o',colors=cols.cyan,ytitle='sta!Cc6!CO+,O++!C>30eV!Ccnts',psym=-1
			ylim,'mvn_sta_test_cnts_o',1,10000,1

		get_4dt,'v_4d','mvn_sta_get_ca',name='mvn_sta_ca_vel3',m_int=1.,energy=[0,40000.]
			get_data,'mvn_sta_ca_vel3',data=tmp
			store_data,'mvn_sta_ca_vel',data={x:tmp.x,y:(total(tmp.y*tmp.y,2))^.5}
				options,'mvn_sta_ca_vel','sta!Cca!CH+!Cvel!Ckm/s'
				ylim,'mvn_sta_ca_vel',10,500,1

		get_data,'mvn_sta_test_density1',data=tmp1
		get_data,'mvn_sta_test_density2',data=tmp2
		store_data,'mvn_sta_test_density3',data={x:tmp1.x,y:tmp1.y+tmp2.y}
			ylim,'mvn_sta_test_density3',1,100.,1
	endif

	get_data,'mvn_sta_test_density1',data=tmp1
	get_data,'mvn_sta_test_density2',data=tmp2
	get_data,'mvn_sta_test_density3',data=tmp
	ind = where(tmp.y gt 0.,count)
	if count gt 1 then begin
		den = interp(tmp.y[ind],tmp.x[ind],time)
		p_den = interp(tmp1.y[ind],tmp1.x[ind],time)
		o_den = interp(tmp2.y[ind],tmp2.x[ind],time)
	endif else begin
		print,'Error - STATIC c6 data not loaded'
		return
	endelse

	get_data,'mvn_sta_test_ec_p',data=tmp
		p_ec = interp(tmp.y[ind],tmp.x[ind],time)
	get_data,'mvn_sta_test_ec_o',data=tmp
		o_ec = interp(tmp.y[ind],tmp.x[ind],time)
	get_data,'mvn_sta_test_cnts_p_low',data=tmp
		p_low = interp(tmp.y[ind]+.1,tmp.x[ind],time)
	get_data,'mvn_sta_ca_vel',data=tmp
		p_vel = interp(tmp.y,tmp.x,time)
	get_data,'mvn_sta_test_cnts_o',data=tmp
		o_cnt=interp(tmp.y,tmp.x,time)
	get_data,'mvn_sta_test_cnts_o_med',data=tmp
		o_med=interp(tmp.y,tmp.x,time)
	get_data,'mvn_sta_test_cnts_o_low',data=tmp
		o_low=interp(tmp.y,tmp.x,time)

	store_data,'mvn_sta_test_density',data=['mvn_sta_test_density1','mvn_sta_test_density2']
		options,'mvn_sta_test_density',ytitle='sta!C!Ctest!C!Cdensity'
		ylim,'mvn_sta_test_density',.1,1000,1
	store_data,'mvn_sta_test_ec',data=['mvn_sta_test_ec_p','mvn_sta_test_ec_o']
		ylim,'mvn_sta_test_ec',1,2000,1
		options,'mvn_sta_test_ec',ytitle='sta!Cc6!CH+,O+!C!CEc'

	store_data,'mvn_sta_test_cnts_low',data=['mvn_sta_test_cnts_o_low','mvn_sta_test_cnts_p_low']
		ylim,'mvn_sta_test_cnts_low',1,2000,1
		options,'mvn_sta_test_cnts_low',ytitle='sta!Cc6!C<10eV!C!CCnts'

;**********************************************************
; determine when sc is in shadow and wake

	mars_radius = 3386.

	pos = mvn_c6_dat.pos_sc_mso

	if min((pos[*,0]^2+pos[*,1]^2+pos[*,2]^2)^.5) lt mars_radius then begin
		print,'Error - missing ephemeris data in c6'
		maven_orbit_tplot,/current,result=foo,/LOADONLY,eph=eph	
		if size(foo,/type) eq 8 then begin		
			pos[*,0] = interp(foo.x*mars_radius,foo.t,time)
			pos[*,1] = interp(foo.y*mars_radius,foo.t,time)
			pos[*,2] = interp(foo.z*mars_radius,foo.t,time)
			print,'Alert: mvn_c6_dat.pos_sc_mso has values < mars_radius, using maven_orbit_tplot to determine s/c position'
		endif else begin
			print,'Error: sc position not determined - aborting mvn_sta_scpot_load!!!!'
			return
		endelse
	endif

	shadow = ((pos[*,1]^2+pos[*,2]^2)^.5 - 200.) lt mars_radius and pos[*,0] lt 0. 
	if keyword_set(tplot) then store_data,'mvn_shadow',data={x:time,y:shadow}
		if keyword_set(tplot) then ylim,'mvn_shadow',-1,2,0

	wake = ((pos[*,1]^2+pos[*,2]^2)^.5) lt (mars_radius+500.-pos[*,0]*sin(10./!radeg)) and (pos[*,0] lt 0.) 
	if keyword_set(tplot) then store_data,'mvn_wake',data={x:time,y:wake}
		if keyword_set(tplot) then ylim,'mvn_wake',-1,2,0

	if keyword_set(tplot) then store_data,'mvn_yz',data={x:time,y:(pos[*,1]^2+pos[*,2]^2)^.5 - mars_radius}
		if keyword_set(tplot) then ylim,'mvn_yz',-4000,4000,0

	alt = (pos[*,0]^2+pos[*,1]^2+pos[*,2]^2)^.5 - mars_radius

	min_alt = min(alt) > 150.

;**********************************************************
; determine sc velocity relative to planet - this is ram velocity

	get_data,'V_sc_MAVEN_APP',data=tmp81
	if size(tmp81,/type) eq 8 then begin
		vtot = (total(tmp81.y*tmp81.y,2))^.5
		vel = interp(vtot,tmp81.x,mvn_c6_dat.time+2.)
	endif else begin
		mkernels = mvn_spice_kernels(/load)
		trange = timerange()
		mvn_ramdir,trange,frame=['MAVEN_APP'],dt=1,/polar
		get_data,'V_sc_MAVEN_APP',data=tmp81
		if size(tmp81,/type) eq 8 then begin 
			vtot = (total(tmp81.y*tmp81.y,2))^.5
			vel = interp(vtot,tmp81.x,mvn_c6_dat.time+2.)
		endif else begin			; approximate velocity from position motion - used prior to 20160805
			vel = total((pos[1:npts-1,*] - pos[0:npts-2,*])^2,2)^.5/(time[1:npts-1]-time[0:npts-2])	
			vel = [vel[0],[vel]]
			print,'ERROR - mvn_ramdir did not run!!! - using maven_orbit_tplot to estimate velocity ignoring planet rotation'
			print,'ERROR - this approximation will introduce sc_pot error at periapsis!!!'
		endelse
	endelse

	if keyword_set(tplot) then store_data,'mvn_sta_scpot_vel',data={x:time,y:vel}

	nrg_offset=+.0									; this is included incase sensor HV has an offset


;**********************************************************
; estimate sc potential using c6 O2+ velocity data
; 	this estimate is only valid below about 300 km

	pot = fltarr(npts)
	vd = fltarr(npts)
	vth = fltarr(npts)
	ano = fltarr(npts)
	ms = mvn_c6_dat.mass*32.

	mass_o2 = [28,40.]
	m_o2 = 32.
	min_o2 = 0
	engy_o2 = [0,11]

for i=0l,npts-1 do begin
	if mvn_c6_dat.energy[mvn_c6_dat.swp_ind[i],31,0] lt 2. then begin	; the lower energy limit of the sweep must be less then 2 eV

; the following was used prior to 20170502 - replaced by more accurate vb_pot_4d.pro
	if 0 then begin
		cnts=reform(mvn_c6_dat.data[i,*,*])
		data=reform(mvn_c6_dat.eflux[i,*,*])

		mass=reform(mvn_c6_dat.mass_arr[mvn_c6_dat.swp_ind[i],*,*])
			ind = where(mass lt 25 or mass gt 40,count)
;			ind = where(mass lt 30 or mass gt 34,count)			; this was used during some testing to see if it worked better
			if count ne 0 then data[ind]=0.
			if count ne 0 then cnts[ind]=0.
		nrg = (reform(mvn_c6_dat.energy[mvn_c6_dat.swp_ind[i],*,*]) + nrg_offset) > 0.01		; nrg_offset is currently 0, but might be needed

; anode array may be useful in the future for eliminating data when flow not in ram direction
		min_ca = min(abs(mvn_ca_dat.time +2. - time[i]),ind_ca) 
		anode = reform(replicate(1.,2)#reform(total(reform(mvn_ca_dat.data[ind_ca,*,*],16,4,16),2),16*16),32,16)

; the following kluge to max_nrg was needed for cases with nightside vdis at 10 eV - example 20160107 0317UT
		max_nrg2 = max_nrg
		peak_eflx_ca = max(anode[*,7],ind_peak_ca)
		peak_eflx_c6 = max(total(data,2),ind_peak_c6)
		if ind_peak_ca gt (ind_peak_c6+1) then begin
			mintmp = min(abs(nrg[ind_peak_ca,0]-nrg[*,0]),minind) 
			maxnrg = nrg(minind-2,0)
			if alt[i] le 180. and total(cnts[((minind-2)>1):31,*]) ge 10 then max_nrg2=nrg(((minind-2)>1),0)
		endif

;			bin10ev = min(abs(nrg[*,0]-10.),ind10ev)
;			if alt[i] le 180. and total(cnts[ind10ev:31,*]) ge 10 then max_nrg2=10.  
;			bin6ev = min(abs(nrg[*,0]-6.),ind6ev)
;			if alt[i] le 180. and total(cnts[ind6ev:31,*]) ge 10 then max_nrg2=6.  
			
		ind = where(nrg gt max_nrg2,count)
			if count ne 0 then data[ind]=0.
			if count ne 0 then cnts[ind]=0.
			ind = where(nrg lt 1.,count)
			if count ne 0 then data[ind]=0.
			if count ne 0 then cnts[ind]=0.
		v = (2.*nrg/ms)^.5

		maxcnt = max(total(data,2),mind) 

		data[0:((mind-4)>0),*]=0.
;		data[((mind+4)<31):31,*]=0.
		en_peak=nrg[mind,0]
		data = data*(exp((kk2/nrg)^2) < 10.)			; this conservative correction may be inadequate between 20150201 and 20151001

		vd[i] = total(data)/(total(data/v)>1.e-20) 
		vth[i] = (total(data*(v-vd[i])^2/v)/(total(data/v)>1.e-20))^.5

	endif else begin
		dat6 = mvn_sta_get_c6(mvn_c6_dat.time[i])	
		cnts = cb_4d(dat6,mass=mass_o2,m_int=m_o2,energy=engy_o2,mincnt=min_o2)				; not quite consistent with vb_pot_4d.pro
; 3 iterations give an accurate potential

		dat7 = dat6 & dat7.sc_pot=0.
		vd7 = vb_pot_4d(dat7,mass=mass_o2,m_int=m_o2,energy=engy_o2,mincnt=min_o2,/no_co2)
		pd7 = 0.5*ms*(vd7^2-vel[i]^2)

		dat8 = dat6 & dat8.sc_pot = -pd7
		vd8 = vb_pot_4d(dat8,mass=mass_o2,m_int=m_o2,energy=engy_o2,mincnt=min_o2,/no_co2)
		pd8 = 0.5*ms*(vd8^2-vel[i]^2)

		dat9 = dat6 & dat9.sc_pot = -pd7-pd8
		vd9 = vb_pot_4d(dat9,mass=mass_o2,m_int=m_o2,energy=engy_o2,mincnt=min_o2,/no_co2)
		pd9 = 0.5*ms*(vd9^2-vel[i]^2)

		vd[i] = vd7
	endelse

		pot[i] = pd7+pd8+pd9 > ram_min									; ram_min=0.12  the minimum allowed negative potential
;		pot[i] = 0.5*ms*(vd[i]^2-vel[i]^2) > ram_min							; ram_min=0.12  the minimum allowed negative potential
; not sure what these lines do so getting rid of them 
		if total(cnts) lt 5. and alt[i] le 180. then pot[i]=pot[(i-1)>0] 
		if total(cnts) lt 5. and alt[i] gt 180. then pot[i]=pot[(i-1)>0]
;		if total(cnts) lt 5. and alt[i] gt 180. and den[i] lt 1. then pot[i]=pot[(i-1)>0]
;		if total(cnts) lt 5. and alt[i] gt 180. and den[i] ge 1. then pot[i]=max_nrg
;		if alt[i] gt 180. then pot[i]=pot[i] > .8
		if (mvn_c6_dat.quality_flag[i] and 192) gt 0 then pot[i]=pot[(i-1)>0]
		if (mvn_c6_dat.quality_flag[i] and 3) gt 0 then pot[i]=0
	endif
endfor

if keyword_set(tplot) then store_data,'mvn_sta_c6_pot_vd',data={x:time,y:vd}
	if keyword_set(tplot) then options,'mvn_sta_c6_pot_vd',colors=cols.green
if keyword_set(tplot) then store_data,'mvn_sta_c6_pot_vth',data={x:time,y:vth}
if keyword_set(tplot) then store_data,'mvn_sta_c6_pot_ec',data={x:time,y:0.5*ms*vd^2}
;print,minmax(vth/vd)

;**********************************************************
; estimate sc potential using c0 data

	time2 = (mvn_c0_dat.time + mvn_c0_dat.end_time)/2.
	npts2 = n_elements(time2)
	pot2 = fltarr(npts2)
	pot22 = fltarr(npts2)
	pot2_cutoff_cnts = fltarr(npts2)
	pot2_p_cutoff_cnts = fltarr(npts2)
	pot2_p_cutoff_cnts0 = fltarr(npts2)
	pot2_p_cutoff_cnts1 = fltarr(npts2)
	pot2_p_cutoff_cnts2 = fltarr(npts2)
	pot2_p_cutoff_cnts3 = fltarr(npts2)
	modep_reject = fltarr(npts2)
	modem_reject = fltarr(npts2)
	pot_bad = fltarr(npts2)
	cnts_lt_pot = fltarr(npts2)
	swp_ind = mvn_c0_dat.swp_ind
	pot0 = interp(pot,time,time2)

	get_data,'mvn_sta_test_density3',data=tmp3
	den2 = interp(tmp3.y,tmp3.x,time2)
	ind_cutoff = fltarr(npts2)
	p_only = fltarr(npts2)

	oxgt30eV=mvn_c0_dat

;	get_data,'alt',data=tmp
;		alt2 = interp(tmp.y,tmp.x,time2)
		alt2 = interp(alt,time,time2)
	pot1 = interp(pot,time,time2)				; pot1 determined from c6 O2+ velocity data

	sha2 = interp(shadow,time,time2)
	o_cnt2 = interp(o_cnt,time,time2)			; 30-40,000 eV
	p_low2 = interp(p_low,time,time2)			; 0-12 eV
	o_low2 = interp(o_low,time,time2)			; 0-12 eV
	o_med2 = interp(o_med,time,time2)			; 0-30 eV


; Determine pot2, the following is stored as 'mvn_sta_c6_O2+_sc_pot_h+'
; Designed to not use oxygen during s/c charging events with scpot<-5 eV since sputtered-trapped O2+ ions at <pot
; Sputtered trapped ions occur when den>3000

for i=1l,npts2-2 do begin
	if mvn_c0_dat.energy[mvn_c0_dat.swp_ind[i],63,0] lt 2. then begin	; the lower energy limit of the sweep must be less then 2 eV

		modep = (mvn_c0_dat.mode[i] eq mvn_c0_dat.mode[i+1]) and (((mvn_c0_dat.quality_flag[i+1] and 64)/64) eq 0)
		modem = (mvn_c0_dat.mode[i] eq mvn_c0_dat.mode[i-1]) and (((mvn_c0_dat.quality_flag[i-1] and 64)/64) eq 0)

;		if (pot1[i] lt 3.) or ((alt2[i] gt 400.) and sha2[i] and (o_cnt2[i] lt 25)) then begin					; used prior to 20161130, checked in on ?	
;		if (pot1[i] lt 3.) or ((alt2[i] gt 400.) and sha2[i] and (o_cnt2[i] lt 25) and (p_low2[i] lt 20)) then begin		; o_cnt2 >30eV, changed to only use protons when there are enough proton counts, fixed problem on 20160915/2307UT	
;		if (pot1[i] lt 3.) or ((alt2[i] gt 400.) and sha2[i] and (o_cnt2[i] lt 25) and (p_low2[i] lt 20)) $
;			or ((alt2[i] gt 400.) and not sha2[i] and (o_low2[i] gt 5)) then begin					; o_cnt2 >30eV, changed to only use protons when there are enough proton counts, fixed problem on 20160915/2307UT	

; this had problems on 20170223/1508-1528UT
;		if ((pot1[i] lt 3.) and (o_cnt2[i] lt 100)) or ((alt2[i] gt 400.) and sha2[i] and (o_cnt2[i] lt 25) and (p_low2[i] lt 20)) then begin	; o_cnt2 >30eV, changed to only use protons when there are enough proton counts, fixed problem on 20160915/2307UT	


; changed 20170228 -- needs testing, 
		if 	((pot1[i] lt 3.) and (o_cnt2[i] lt 100)) $
		     or ((alt2[i] gt 400.) and sha2[i] and (o_cnt2[i] lt 25) and (p_low2[i] lt 20)) $
;		     or ((alt2[i] gt (min_alt+30.)) and (den2[i] lt 3000.)) then begin			; changed to use all ions when the den<3000., modified 20170330 to use (min_alt+30.) - didn't seem to matter
		     or ((alt2[i] gt 150.) and (den2[i] lt 3000.)) then begin				; changed to use all ions when the den<3000.	

			dat1c=total(reform(mvn_c0_dat.data[i,*,*]),2)
			dat1p=total(reform(mvn_c0_dat.data[i+1,*,*]),2)
			dat1m=total(reform(mvn_c0_dat.data[i-1,*,*]),2)
		endif else begin						; this eliminates sputtereed O2+ when s/c charges to >5V, and just uses protons when there are enough counts
			dat1c=reform(mvn_c0_dat.data[i,*,0])
			dat1p=reform(mvn_c0_dat.data[i+1,*,0])
			dat1m=reform(mvn_c0_dat.data[i-1,*,0])
			p_only[i]=1
		endelse
			dat3c=reform(mvn_c0_dat.data[i,*,0])
			dat3p=reform(mvn_c0_dat.data[i+1,*,0])
			dat3m=reform(mvn_c0_dat.data[i-1,*,0])


;		if p_low2[i] gt 30 then begin				; old code
;			modep=0
;			modem=0
;		endif

		dat2c = shift(dat1c,1)
		dat2p = shift(dat1p,1)
		dat2m = shift(dat1m,1)
		dat4c = shift(dat3c,1)
		dat4p = shift(dat3p,1)
		dat4m = shift(dat3m,1)

		dat5c = shift(dat1c,2)
		dat6c = shift(dat3c,2)
		
		data1 = dat1c+modep*dat1p+modem*dat1m
		data2 = dat2c+modep*dat2p+modem*dat2m
		energy0 = reform(mvn_c0_dat.energy[swp_ind[i],*,0])
		energy = (energy0 + nrg_offset) > .01
		denergy = reform(mvn_c0_dat.denergy[swp_ind[i],*,0])*energy/energy0

		ind0 = 0 
; 		ind0 = where (data1 ge 1. and data2 ge 1. and (data1+data2) ge 4.,count)
; changed 20170228
;		ind0 = where ( 	   ( (data1 ge 1.) and (data2 ge 1.) and ((data1+data2) ge 4.) and  (dat5c ge 1.)	) $
;				or ( ((dat3c+dat4c) ge 3.) and  (dat5c ge 1.)			) $
;				or ( ((dat3c+dat4c) ge 2.) and  (dat5c ge 2.)		   ) ,count)
; changed 20170412
		ind0 = where ( 	   ( ((dat1c ge 1.) or (data1 ge 2.)) and ((dat2c ge 1.) or (data2 ge 2.)) and ((dat1c+dat2c) ge 2.) and ((data1+data2) ge 4.) and ((data1+data2+dat5c) ge 5.)	) $
				or ( ((dat1c ge 1.) or (data1 ge 2.)) and ((dat2c ge 1.) or (data2 ge 2.)) and ((dat1c+dat2c) ge 2.) and ((data1+data2) ge 3.) and ((dat1c+dat2c+dat5c) ge 4.)	) $
				or ( (dat3c ge 1.) and ((dat3c+dat4c) ge 3.) and  ((dat3c+dat4c+dat6c) ge 4.) ) $
				or ( (dat3c ge 1.) and ((dat3c+dat4c) ge 2.) and  ((dat3c+dat4c+dat6c) ge 5.) )		   ,count)
;		if count gt 0 then mind0=max(ind0) 			; would crashed, changed 20170812
		if count gt 0 then mind0=max(ind0) else mind0=1
		mind0 = mind0 > 1


; don't average over time if dat1c >10 counts, added 20170331
;		if count gt 0 and (dat1c[mind0]+dat2c[mind0]+dat2c[(mind0-1)>0]) gt 10. then begin	; old method
		if count gt 0 and (dat1c[mind0]+dat2c[mind0]) ge 10. then begin
;			if dat1c[mind0] eq 0 then mind0=(mind0-1)>1					; old method
			data1=dat1c
			data2=dat2c
			modep = 0
			modem = 0
		endif

; interpolate 

;		if energy[mind0] lt max_nrg and ((alt2[i] gt 180.) or ((data1[mind0]+data2[mind0]) gt 20.)) then begin
		if energy[mind0] lt max_nrg and ((alt2[i] gt (min_alt+25.)) or ((data1[mind0]+data2[mind0]) ge 20.)) then begin
;			e0 = energy[mind0] - denergy[mind0]/2.
;			d1 = data1[mind0] 
;			e1 = energy[mind0] - e0
;			d2 = data2[mind0-1] 
;			e2 = energy[mind0-1] - e0
;			scale = 0. > (1-(d1/d2)*(e2/e1)^1) < 1.
;			pot2[i]= (energy[mind0] - denergy[mind0]/2. + denergy[mind0]*scale) < max_nrg

			e0 = energy[mind0]
			d0 = data1[mind0] 
			e1 = energy[mind0-1]
			d1 = data1[mind0-1] 
			pot2[i] = e0 + .5*(e1-e0)*(d1-d0)/(d1+d0+3.)				; the "3" here just skews it toward mind0 for low count rates
			if d1 le 3. then pot2[i]=energy[mind0]					; don't interpolate if d1 is small
		endif else pot2[i] = max_nrg
;		endif else pot2[i] = 2.5

;		if alt2[i] ge 300. and den2[i] lt 1. then pot2[i] = 2.5
		if (mvn_c0_dat.quality_flag[i] and 192) gt 0 then pot2[i]=pot2[(i-1)>0]
		if (mvn_c0_dat.quality_flag[i] and 3) gt 0 then pot2[i]=max_nrg
		if (alt2[i] lt (min_alt+25.)) then pot2[i]=max_nrg

	endif else pot2[i] = max_nrg

;**************************************
; this added 20170330 this is used to determine validity of low energy cutoff for along track wind calculations

	if pot2[i] lt (max_nrg*.9 > 10.) then begin
		nrg = reform(mvn_c0_dat.energy[swp_ind[i],*,0])
;		minval = min(abs(nrg-pot2[i]),ind77)
		ind77=mind0

		minval = min(abs(nrg-(2.7+pot0[i])*.70),ind87)
		if alt2[i] lt alt_vo2 then ind77=ind77>ind87		; this makes sure we don't count o2+ stragglers 

		pot2_cutoff_cnts[i] = total(dat1c[0>(ind77-2):(ind77+1)<63]+modep*dat1p[0>(ind77-2):(ind77+1)<63]+modem*dat1m[0>(ind77-2):(ind77+1)<63])
		pot2_p_cutoff_cnts[i] = total(dat3c[0>(ind77-1):(ind77+1)<63]+modep*dat3p[0>(ind77-1):(ind77+1)<63]+modem*dat3m[0>(ind77-1):(ind77+1)<63])
		pot2_p_cutoff_cnts0[i] = (total(dat3c[0>(mind0-2):mind0])+modep*total(dat3p[0>(mind0-1):mind0])+modem*total(dat3m[0>(mind0-1):mind0]))/(1+modep+modem) 
		pot2_p_cutoff_cnts1[i] = total(dat3c[63<(mind0+1):63]+modep*dat3p[63<(mind0+1):63]+modem*dat3m[63<(mind0+1):63])
		pot2_p_cutoff_cnts2[i] = total(dat3c[0>(mind0-1):mind0]) 
		pot2_p_cutoff_cnts3[i] = total(dat3c[63<(mind0+1):63])
		modep_reject[i] = modep
		modem_reject[i] = modem
		ind_cutoff[i]=ind77
	endif

;**************************************

endfor

; for testing only
if keyword_set(tplot) then store_data,'modep_reject',data={x:time2,y:modep_reject}
if keyword_set(tplot) then options,'modep_reject',yrange=[-1,2]
if keyword_set(tplot) then store_data,'modem_reject',data={x:time2,y:modem_reject}
if keyword_set(tplot) then options,'modem_reject',yrange=[-1,2]

if keyword_set(tplot) then store_data,'pot2_p_cutoff_cnts0',data={x:time2,y:pot2_p_cutoff_cnts0}
if keyword_set(tplot) then options,'pot2_p_cutoff_cnts0',ylog=1,yrange=[1,100],psym=-1
if keyword_set(tplot) then store_data,'pot2_p_cutoff_cnts1',data={x:time2,y:pot2_p_cutoff_cnts1}
if keyword_set(tplot) then options,'pot2_p_cutoff_cnts1',ylog=1,yrange=[1,100],psym=-1

if keyword_set(tplot) then store_data,'pot2_p_cutoff_cnts2',data={x:time2,y:pot2_p_cutoff_cnts2}
if keyword_set(tplot) then options,'pot2_p_cutoff_cnts2',ylog=1,yrange=[1,100],psym=-1
if keyword_set(tplot) then store_data,'pot2_p_cutoff_cnts3',data={x:time2,y:pot2_p_cutoff_cnts3}
if keyword_set(tplot) then options,'pot2_p_cutoff_cnts3',ylog=1,yrange=[1,100],psym=-1

if keyword_set(tplot) then store_data,'ind_cutoff',data={x:time2,y:ind_cutoff}
if keyword_set(tplot) then store_data,'p_only',data={x:time2,y:p_only}
	ylim,'p_only',-1,2,0

; tplot,['pot2_p_cutoff_cnts0','pot2_p_cutoff_cnts1','pot2_p_cutoff_cnts2','pot2_p_cutoff_cnts3','mvn_sta_c6_O2+_lpw_sc_pot_all','mvn_sta_c6_pot_cutoff_valid','mvn_sta_c0_P1A_L_E_pot','mvn_sta_c0_P1A_H_E_pot']

; If counts <10eV exceed 10, density>8., and alt>400 then use the total count cutoff without averaging 
; Determine pot22, the following is stored as 'mvn_sta_c6_O2+_sc_pot_o+h+'

for i=1l,npts2-2 do begin
	if mvn_c0_dat.energy[mvn_c0_dat.swp_ind[i],63,0] lt 2. then begin	; the lower energy limit of the sweep must be less then 2 eV

		if ((alt2[i] gt 400.) and den2[i] gt 8. and ((o_low2[i]+p_low2[i]) gt 10)) then begin					; o_cnt2 >30eV, changed to only use protons when there are enough proton counts, fixed problem on 20160915/2307UT	
			energy0 = reform(mvn_c0_dat.energy[swp_ind[i],*,0])
			dat22=total(reform(mvn_c0_dat.data[i,*,*]),2)
			minval = min(abs(energy0-max_nrg),max_nrg_ind)
			dat22[0:max_nrg_ind]=0.
			dat23=shift(dat22,1)
			mincnts = 3. > (o_low2[i]+p_low2[i])/20. > (o_cnt2[i]+o_med2[i])/40.			; higher threshold to eliminate sputtered trapped O+ background

			ind22 = where ((dat22 ge 1.) and (dat23 ge 1.) and ((dat22+dat23) ge mincnts),count)
			if count ge 1 then begin								; interpolate between energy bins
			if 1 then begin
				mind22 = max(ind22)
				d1 = dat22[mind22] 
				d2 = dat22[mind22-1] 
				e1 = energy0[mind22]
				e2 = energy0[mind22-1]
				pot22[i] = e1 + .5*(e2-e1)*(1.-(d1>3.)/(d2>d1>3.)) - .5*(e2-e1)*(1.-3./(d1>3.))
;				pot22[i] = e1 
			endif
			if 0 then begin
				mind22 = max(ind22)
				energy = (energy0 + nrg_offset) > .01
				denergy = reform(mvn_c0_dat.denergy[swp_ind[i],*,0])*energy/energy0
				e0 = energy[mind22] - denergy[mind22]/2.
				d1 = dat22[mind22] 
				e1 = energy[mind22] - e0
				d2 = dat22[mind22-1] 
				e2 = energy[mind22-1] - e0
				scale = 0. > (1-(d1/d2)*(e2/e1)^1) < 1.
				pot22[i] = (energy[mind22] - denergy[mind22]/2. + denergy[mind22]*scale) < max_nrg
			endif
			endif else pot22[i]=max_nrg
		endif else pot22[i] = max_nrg
		if (mvn_c0_dat.quality_flag[i] and 192) gt 0 then pot22[i]=pot22[(i-1)>0]
		if (mvn_c0_dat.quality_flag[i] and 3) gt 0 then pot22[i]=max_nrg

	endif else pot22[i] = max_nrg
endfor

;**********************************************************
; eliminate data when there are significant counts below scpot

for i=1l,npts2-2 do begin
	if mvn_c0_dat.energy[mvn_c0_dat.swp_ind[i],63,0] lt 2. then begin	; the lower energy limit of the sweep must be less then 2 eV
		energy0 = reform(mvn_c0_dat.energy[swp_ind[i],*,0])
		pot_tmp = pot2[i] < pot22[i]
		ind = where(energy0 lt pot_tmp/1.1,count)
		if count gt 1 then cnts_lt_pot[i] = total(mvn_c0_dat.data[i,ind,*]) 
		if cnts_lt_pot[i] gt 5. and alt2[i] gt 400. and sha2[i] then pot_bad[i] = 1
	endif else pot_bad[i] = 1
endfor

if keyword_set(tplot) then store_data,'ion_cutoff_pot_bad',data={x:time2,y:pot_bad} & ylim,'ion_cutoff_pot_bad',-1,2,0
if keyword_set(tplot) then store_data,'cnts_lt_pot',data={x:time2,y:cnts_lt_pot}


pot3 = interp(pot2>max_nrg*pot_bad,time2,time)
pot3a = pot3 
pot33 = interp(pot22>max_nrg*pot_bad,time2,time) 
pot3 = (pot3<pot33) > 0.

pot3_cutoff_cnts = interp(pot2_cutoff_cnts,time2,time)
pot3_p_cutoff_cnts = interp(pot2_p_cutoff_cnts,time2,time)

;**********************************************************
; estimate sc potential from swea data - this is turned off since it fails too often

if 0 then begin

	get_data,'mvn_swe_sc_pot',data=tmp9
	if size(tmp9,/type) ne 8 then begin
		mvn_swe_load_l2, /spec,/sumplot
		mvn_swe_sc_pot,/over,badval=0
		get_data,'mvn_swe_sc_pot',data=tmp9
	endif

	get_data,'swe_a4',data=tmp6
		npts6 = n_elements(tmp6.x)
			pk6=fltarr(npts6) & ind6=intarr(npts6)
			pkh=fltarr(npts6) & pkl=fltarr(npts6)
			pkc=fltarr(npts6) & pkr=fltarr(npts6)
			en6=fltarr(npts6) & fx6=fltarr(npts6)
			mpk = min(abs(tmp6.v-10.),ind0)

		for i=0l,npts6-1 do begin
			pk6[i]=max(tmp6.y[i,52:59],ind)
			pkh[i]=tmp6.y[i,52+ind-4]
			pkl[i]=tmp6.y[i,52+ind+4]
			pkr[i]=pkh[i]/pkl[i]
			pkc[i]=2*pk6[i]/(pkh[i]+pkl[i])
			en6[i]=tmp6.v[52+ind]
			fx6[i]=tmp6.y[i,56]
		endfor
;	end

	cold = (pkr gt .8) and (en6 lt 7.) and (fx6 gt 6.e7)
	get_data,'mvn_sta_c6_E',data=tmp99 & time=tmp99.x
	cold2 = fix(interp((1.*cold),tmp6.x,time)+.6)

if keyword_set(tplot) then 	store_data,'cold',data={x:tmp6.x,y:cold} & ylim,'cold',-1,2,0
if keyword_set(tplot) then 	store_data,'cold2',data={x:time,y:cold2} & ylim,'cold2',-1,2,0
if keyword_set(tplot) then 	store_data,'swe_id1',data={x:tmp6.x,y:pkr}
if keyword_set(tplot) then 	store_data,'swe_id2',data={x:tmp6.x,y:pkc}
if keyword_set(tplot) then 	store_data,'swe_id3',data={x:tmp6.x,y:pkh}
if keyword_set(tplot) then 	store_data,'swe_id4',data={x:tmp6.x,y:pkl}
if keyword_set(tplot) then 	store_data,'swe_id5',data={x:tmp6.x,y:en6}
if keyword_set(tplot) then 	store_data,'swe_id6',data={x:tmp6.x,y:fx6}

;tplot,['swe_id1','swe_id5','swe_id6','swe_a4_pot','cold','cold2']


	if size(tmp9,/type) eq 8 then begin
		npts9 = n_elements(tmp9.x)
		pot9 = tmp9.y

;		ind = where(pot9[1:npts9-2] ne 0. or (pot9[0:npts9-3] eq 0 and pot9[2:npts9-1] eq 0)) 
;		pot9 = pot9[ind+1]
;		tim9 = tmp9.x[ind+1]
;		pot4 = interp(pot9,tim9,time)

; get rid of single/double bad points
		ind = where(pot9[2:npts9-3] gt 10. and (pot9[0:npts9-5] eq 0 and pot9[1:npts9-4] eq 0 and pot9[3:npts9-2] eq 0 and pot9[4:npts9-1] eq 0),count) 
		if count ne 0 then pot9[ind+2] = 0
		ind = where(pot9[2:npts9-3] gt 10. and (pot9[2:npts9-3] gt 2.*pot9[0:npts9-5] and pot9[2:npts9-3] gt 2.*pot9[1:npts9-4] $
			and pot9[2:npts9-3] gt 2.*pot9[3:npts9-2] and pot9[2:npts9-3] gt 2.*pot9[4:npts9-1]),count) 
		if count ne 0 then pot9[ind+2] = 0

; get rid of single/double bad points
		ind = where(pot9[1:npts9-2] eq 0. and (pot9[0:npts9-3] ne 0 and pot9[2:npts9-1] ne 0),count) 
		if count ne 0 then pot9[ind+1] = (pot9[ind]+pot9[ind+2])/2.
		ind = where(pot9[1:npts9-2] eq 0. and pot9[0:npts9-3] ne 0,count) 
		if count ne 0 then pot9[ind+1] = pot9[ind]
		ind = where(pot9[1:npts9-2] eq 0. and pot9[2:npts9-1] ne 0,count) 
		if count ne 0 then pot9[ind+1] = pot9[ind+2]
; do it again - get rid of up to 4 bad points
		ind = where(pot9[1:npts9-2] eq 0. and (pot9[0:npts9-3] ne 0 and pot9[2:npts9-1] ne 0),count) 
		if count ne 0 then pot9[ind+1] = (pot9[ind]+pot9[ind+2])/2.
		ind = where(pot9[1:npts9-2] eq 0. and pot9[0:npts9-3] ne 0,count) 
		if count ne 0 then pot9[ind+1] = pot9[ind]
		ind = where(pot9[1:npts9-2] eq 0. and pot9[2:npts9-1] ne 0,count) 
		if count ne 0 then pot9[ind+1] = pot9[ind+2]

		pot4 = interp(pot9,tmp9.x,time)
		pot4a = interp(tmp9.y,tmp9.x,time)

		ind = where(tmp9.y gt 0.,count)
		if count eq 0 then print,'Alert: No sc potential data available from swea'
	endif else begin
		pot4=replicate(0.,npts)
		print,'Alert: No sc potential data available from swea - data missing'
	endelse

	if keyword_set(tplot) then store_data,'pot4',data={x:time,y:pot4}
		if keyword_set(tplot) then options,'pot4',colors=1,thick=2

	get_data,'mvn_swe_spec_temp,data=tmp8
	if size(tmp8,/type) ne 8 then begin
		mvn_swe_n1d,/mom,background=1e3,minden=1e-4
	endif
	get_data,'mvn_swe_spec_temp',data=tmp8
	if size(tmp8,/type) eq 8 then begin
		tsmooth2,'mvn_swe_spec_temp',3,newname='mvn_swe_spec_temp_3s'
			ylim,'mvn_swe_spec_temp_3s',1,50.,1
		get_data,'mvn_swe_spec_temp_3s',data=tmp8
		temp_e = interp(tmp8.y,tmp8.x,time)
		get_data,'mvn_swe_spec_dens',data=tmp9
		tsmooth2,'mvn_swe_spec_dens',3,newname='mvn_swe_spec_dens_3s'
			ylim,'mvn_swe_spec_dens_3s',0,50.,0
		get_data,'mvn_swe_spec_dens_3s',data=tmp9
		dens_e = interp(tmp9.y,tmp9.x,time)
;		dens_e = 1.2*dens_e*(temp_e gt 13.)
;		dens_e = 1.2*dens_e*(temp_e gt 11.)
		dens_e = 1.2*dens_e
;		print,'dens_e minmax = ',minmax(dens_e)
	endif else begin
		print,'Alert: No electron temperature data
		temp_e = replicate(10.,npts)
		dens_e = replicate(10.,npts)
	endelse

endif

;**********************************************************
;**********************************************************
; combine potential estimates
; if in sunlight and >250km and density<max_den and characteristic_energy>max_ec then s/c potential is set to 0


;sc_neg = den gt max_den or alt lt max_alt or shadow
;sc_neg = alt lt max_alt or shadow
;sc_pos = (alt gt max_alt or ((alt gt 250.) and (den lt max_den) and (p_ec gt max_ec)) or ((alt gt 250.) and (p_ec gt 400.) and (p_low lt 2.)) or ((alt gt 400.) and (c6_mode lt 2))) and (not shadow)

if keyword_set(swe) then den2 = (den>swe_den) else den2=den

; sc_pos = (((alt gt 250.) and (den2 lt max_den) and (p_ec gt max_ec))) and (not shadow)		; used to define sc_neg, p_ec is proton ec, low density and high proton ec and not shadow
; sc_pos = ( (alt gt 250.) and (den2 lt max_den) and (p_ec gt max_ec) and (pot3 gt 2.5) ) and (not shadow)		; used to define sc_neg, p_ec is proton ec, low density and high proton ec and not shadow
;  sc_pos = ( (alt gt 250.) and (den2 lt max_den) and (pot3 gt 2.5   ) ) and (not shadow)		; used to define sc_neg, p_ec is proton ec, low density and high proton ec and not shadow
  sc_pos = ( (alt gt 250.) and (den2 lt max_den) and (pot3 gt pot_err   ) ) and (not shadow)		; changed 20161205 used to define sc_neg, p_ec is proton ec, low density and high proton ec and not shadow

scpot_invalid =  (alt gt max_alt) 					or $						; max altitude for scpot calculation, generally no limit
;		((alt gt 250.) and (p_ec gt 400.) and (p_low lt 4.)) or $						; eliminate sw or sheath data, p_ec is proton ec, p_low is proton counts less than 10eV - doesn't work well
;		((alt gt 250.) and (p_ec gt 400.) and (p_low lt 4.) and (o_low lt 10)) or $				; changed 20161205, eliminate sw or sheath data, p_ec is proton ec, p_low is proton counts less than 10eV - doesn't work well

		((alt gt 250.) and (p_ec gt 400.) and (p_den gt 2.) and (p_den gt o_den)) or $				; changed 20170302, eliminate sw or sheath data, p_ec is proton ec, p_den is proton density, modified for feb27,0150UT 
		((alt gt 400.) and (p_vel gt 120.) and (not shadow) and (p_den gt o_den)) or $				; changed 20170302, eliminate sheath, 120 is too high for subsolar point, modified for feb27,0150UT 
;		((alt gt 250.) and (p_ec gt 400.) and (p_den gt 2.)) or $						; changed 20161205, eliminate sw or sheath data, p_ec is proton ec, p_den is proton density - doesn't work that well
;		((alt gt 400.) and (p_vel gt 120.) and (not shadow)) or $						; eliminate sheath, 120 is too high for subsolar point - may need to modify if additional conditions don't work

;		((alt gt 400.) and (p_ec gt 100.) and (o_ec gt 100.) and (not shadow)) or $				; added 20161130, eliminate sheath, 
;		((alt gt 400.) and (p_ec gt 100.) and (o_ec gt 100.) and (pot3 gt 2.5) and (not shadow)) or $		; added 20161130, eliminate sheath, 
;		((alt gt 400.) and (p_ec gt max_ec) and (o_ec gt max_ec) and (pot3 gt pot_err) and (not shadow)) or $	; added 20161130, eliminate sheath, 
;		((alt gt 400.) and (p_ec gt 100.) and (o_med lt 20.) and (not shadow)) or $				; added 20161130, eliminate sheath, 
;		((alt gt 400.) and (p_ec gt max_ec) and (o_med lt 20.) and (not shadow)) or $				; added 20161130, eliminate sheath, 
		((alt gt 400.) and (p_low lt 4.) and (o_low lt (10>((o_cnt+o_med)/40.))) and (not shadow)) or $		; added 20161130, eliminate counts less than background, 
		((alt gt alt_vo2) and (pot3 ge max_nrg*.99)) or $							; assume invalid operation ion cutoff exceeds max_nrg
		((alt gt 400.) and (c6_mode lt 2) and (not shadow)) or $						; assume invalid operation when ram and conic mode are used at high altitude
		((den lt .5) and (not shadow)) 										; assume it fails if density is too low

sc_neg = 1-sc_pos

if keyword_set(tplot) then store_data,'scpot_invalid',data={x:time,y:scpot_invalid}
	if keyword_set(tplot) then ylim,'scpot_invalid',-1,2,0
if keyword_set(tplot) then store_data,'sc_neg',data={x:time,y:sc_neg}
	if keyword_set(tplot) then ylim,'sc_neg',-1,2,0
if keyword_set(tplot) then store_data,'sc_pos',data={x:time,y:sc_pos}
	if keyword_set(tplot) then ylim,'sc_pos',-1,2,0
if keyword_set(tplot) then store_data,'alt_gt_250',data={x:time,y:(alt gt 250.)}
	if keyword_set(tplot) then ylim,'alt_gt_250',-1,2,0
if keyword_set(tplot) then store_data,'den_lt_max',data={x:time,y:(den2 lt max_den)}
	if keyword_set(tplot) then ylim,'den_lt_max',-1,2,0
if keyword_set(tplot) then store_data,'ec_gt_max',data={x:time,y:(p_ec gt max_ec)}
	if keyword_set(tplot) then ylim,'ec_gt_max',-1,2,0


;pot_all = -(pot3 < (pot+1000.*(alt gt alt_vo2)))*(1.*sc_neg) + (pot4 > 1.)*(-sc_neg+1.)

pot_all = -(pot3 < (pot+1000.*(alt gt alt_vo2)))*(1.*sc_neg)*(1.*qf_valid)*(1.-scpot_invalid)	; sc_pos comes into play, pot3 is ion cutoff, the alt cutoff at alt_vo2=300km should be variable

;pot_cutoff_valid = (pot3 lt 1.2*(pot+1000.*(alt gt alt_vo2)))*(1.*sc_neg)*(1.*qf_valid)*(1.-scpot_invalid) and (alt gt ((min_alt+25.)>180.))		; pre-20170331 algorithm


pot_cutoff_valid = (pot3_cutoff_cnts gt 5.1)*(1.*sc_neg)*(1.*qf_valid)*(1.-scpot_invalid) and (pot3_p_cutoff_cnts gt 2.1 or alt gt alt_vo2) and (alt gt ((min_alt+35.)>180.))		; are 35 and 180 the best parameters?

	ind = where(not pot_cutoff_valid[1:npts-2] and pot_cutoff_valid[0:npts-3] and pot_cutoff_valid[2:npts-1],count)
	if count gt 0 then pot_cutoff_valid[ind+1] = 1
	ind = where(pot_cutoff_valid[1:npts-2] and not pot_cutoff_valid[0:npts-3] and not pot_cutoff_valid[2:npts-1],count)
	if count gt 0 then pot_cutoff_valid[ind+1] = 0

if keyword_set(cutoff) then pot_all = -(pot3*pot_cutoff_valid + pot*(1-pot_cutoff_valid))*(1.*sc_neg)*(1.*qf_valid)*(1.-scpot_invalid)	; use pot3 when valid

; fill in missing single potentials - mainly at attenuator changes

ind = where(pot_all[1:npts-2] eq 0 and pot_all[0:npts-3] ne 0 and pot_all[2:npts-1] ne 0,count)
if count gt 0 then begin
	pot_all[ind+1] = (pot_all[ind] + pot_all[ind+2])/2.
	pot_cutoff_valid[ind+1] = fix((pot_cutoff_valid[ind] + pot_cutoff_valid[ind+2])/2)
endif

; remove isolated single potentials - mainly at places where density is near 10/cc

ind = where(pot_all[1:npts-2] ne 0 and pot_all[0:npts-3] eq 0 and pot_all[2:npts-1] eq 0,count)
if count gt 0 then begin
	pot_all[ind+1] = 0.
	pot_cutoff_valid[ind+1] = 0
endif

ind = where(pot_all ne 0.,count)
pot_valid = fltarr(npts) 
if count ge 1 then pot_valid[ind]=1
if keyword_set(tplot) then store_data,'mvn_sta_scpot_valid',data={x:time,y:pot_valid}
	if keyword_set(tplot) then ylim,'mvn_sta_scpot_valid',-1,2,0


;**********************************************************
;**********************************************************
;**********************************************************
; testing
; tplot,['alt2','scpot_invalid','sc_pos','mvn_shadow','mvn_sta_scpot_valid','mvn_sta_test_density','mvn_sta_test_ec','mvn_sta_ca_vel','mvn_sta_test_cnts_p_low','mvn_sta_test_cnts_o_med','mvn_sta_test_cnts_o','mvn_sta_c0_L_E_pot','mvn_sta_c0_E_pot_ec','mvn_sta_c6_O2+_sc_pot_all']
; tplot,['alt2','sc_pos','mvn_sta_scpot_valid','mvn_sta_test_density','mvn_sta_c0_E','mvn_sta_c0_L_E_pot','mvn_sta_c0_E_pot_ec','mvn_sta_c6_O2+_sc_pot_all']
; tplot,['alt2','swe_a4_pot','mvn_sta_scpot_valid','sc_pos','mvn_sta_scpot_valid','mvn_sta_c0_L_E_pot','mvn_sta_c0_E_pot_ec','mvn_sta_c6_O2+_sc_pot_all']

; tplot,['alt2','swe_a4_pot','mvn_sta_scpot_valid','sc_pos','mvn_sta_scpot_valid','mvn_sta_test_ec','mvn_sta_test_density','mvn_sta_test_cnts_low','mvn_sta_c0_L_E_pot','mvn_sta_c0_E_pot_ec','mvn_sta_c6_O2+_sc_pot_all']
; tplot,['mvn_sta_c0_P1A_H_E','mvn_sta_test_cnts_p_low','alt2','swe_a4_pot','mvn_sta_c0_L_E_pot','mvn_sta_c0_E_pot_ec','mvn_sta_c6_O2+_sc_pot_all']
; tplot,['mvn_sta_c0_P1A_E','alt2','swe_a4_pot','mvn_sta_c0_L_E_pot','mvn_sta_c0_E_pot_ec','mvn_sta_c6_O2+_sc_pot_all']

; ylim,'mvn_lpw_swp1_V2',.3,10,1
; zlim,'mvn_sta_c0_P1A_E_pot',1,10,1 & tplot,['alt2','mvn_sta_scpot_valid','mvn_sta_test_density','swe_a4','mvn_sta_c0_E','mvn_sta_c0_L_E_pot','mvn_sta_c0_E_pot_ec','mvn_sta_c6_O2+_sc_pot_all','mvn_lpw_swp1_V2']



;**********************************************************
; make some tplot structures if keyword is set

if keyword_set(tplot) then store_data,'mvn_sta_c6_pot_cutoff_valid',data={x:time,y:pot_cutoff_valid} & options,'mvn_sta_c6_pot_cutoff_valid',thick=2,yrange=[-1,2],ylog=0,ytitle='pot!Cion!Ccutoff!Cvalid'
if keyword_set(tplot) then store_data,'mvn_sta_c6_pot3_cutoff_cnts',data={x:time,y:pot3_cutoff_cnts} & options,'mvn_sta_c6_pot3_cutoff_cnts',thick=2,yrange=[.1,20],ylog=1,ytitle='pot3!Cion!Ccutoff!Ccnts'
if keyword_set(tplot) then store_data,'mvn_sta_c6_pot3_p_cutoff_cnts',data={x:time,y:pot3_p_cutoff_cnts} & options,'mvn_sta_c6_pot3_p_cutoff_cnts',thick=2,yrange=[.1,20],ylog=1,ytitle='pot3!Ch+!Ccutoff!Ccnts'

if keyword_set(tplot) then store_data,'mvn_sta_c6_O2+_sc_pot_red',data={x:time,y:pot_all} & options,'mvn_sta_c6_O2+_sc_pot_red',colors=6,thick=2,yrange=[.1,50],ylog=1
if keyword_set(tplot) then store_data,'mvn_sta_c6_O2+_sc_pot_blk',data={x:time,y:pot_all} & options,'mvn_sta_c6_O2+_sc_pot_blk',colors=0,thick=2,yrange=[.1,50],ylog=1
if keyword_set(tplot) then store_data,'mvn_sta_c6_O2+_sc_pot_vo2',data={x:time,y:pot*1.1} & options,'mvn_sta_c6_O2+_sc_pot_vo2',colors=3,thick=2,yrange=[.1,50],ylog=1	; the 1.1 is so they don't plot on top of one another
if keyword_set(tplot) then store_data,'mvn_sta_c6_O2+_sc_pot_h+',data={x:time,y:pot3a*1.1} & options,'mvn_sta_c6_O2+_sc_pot_h+',colors=4,thick=2,yrange=[.1,50],ylog=1	; the 1.1 is so they don't plot on top of one another
if keyword_set(tplot) then store_data,'mvn_sta_c6_O2+_sc_pot_o+h+',data={x:time,y:pot33*1.1} & options,'mvn_sta_c6_O2+_sc_pot_o+h+',colors=2,thick=2,yrange=[.1,50],ylog=1	; the 1.1 is so they don't plot on top of one another
;if keyword_set(tplot) then store_data,'mvn_sta_sc_pot',data={x:time,y:[[pot_all],[-pot_all]]} & options,'mvn_sta_sc_pot',colors=[4,6],thick=2,yrange=[.1,30],ylog=1
if keyword_set(tplot) then store_data,'mvn_sta_c6_O2+_sc_pot_all',data=['mvn_sta_c6_neg_scpot','mvn_sta_c6_O2+_sc_pot_vo2','mvn_sta_c6_O2+_sc_pot_h+','mvn_sta_c6_O2+_sc_pot_o+h+']
if keyword_set(tplot) then ylim,'mvn_sta_c6_O2+_sc_pot_all',0.1,50,1

store_data,'mvn_sta_c6_scpot',data={x:time,y:pot_all}
store_data,'mvn_sta_c6_neg_scpot',data={x:time,y:-pot_all}
	options,'mvn_sta_c6_neg_scpot',colors=cols.red

if keyword_set(tplot) then store_data,'mvn_sta_c0_P1A_E_pot',data=['mvn_sta_c0_P1A_E','mvn_sta_c6_neg_scpot'] & options,'mvn_sta_c0_P1A_E_pot',yrange=[.3,30],ylog=1
if keyword_set(tplot) then store_data,'mvn_sta_c0_P1A_H_E_pot',data=['mvn_sta_c0_P1A_H_E','mvn_sta_c6_neg_scpot'] & options,'mvn_sta_c0_P1A_H_E_pot',yrange=[.3,30],ylog=1,zrange=[1,1000],zlog=1
if keyword_set(tplot) then store_data,'mvn_sta_c0_P1A_L_E_pot',data=['mvn_sta_c0_P1A_L_E','mvn_sta_c6_neg_scpot'] & options,'mvn_sta_c0_P1A_L_E_pot',yrange=[.3,30],ylog=1,zrange=[1,1000],zlog=1

if keyword_set(tplot) then store_data,'mvn_sta_c0_E_pot_ec',data=['mvn_sta_c0_E','mvn_sta_c6_neg_scpot','mvn_sta_c6_pot_ec'] & options,'mvn_sta_c0_E_pot_ec',yrange=[.3,30],ylog=1,zrange=[1.e4,1.e9],zlog=1
if keyword_set(tplot) then store_data,'mvn_sta_c0_H_E_pot_ec',data=['mvn_sta_c0_H_E','mvn_sta_c6_neg_scpot','mvn_sta_c6_pot_ec'] & options,'mvn_sta_c0_H_E_pot_ec',yrange=[.3,30],ylog=1,zrange=[1.e4,1.e9],zlog=1

if not keyword_set(tplot) then 	store_data,delete='mvn_sta_test*'


;  Science data product common blocks
 
;	common mvn_c2,mvn_c2_ind,mvn_c2_dat 
;	common mvn_c4,mvn_c4_ind,mvn_c4_dat 
	common mvn_c8,mvn_c8_ind,mvn_c8_dat 
	common mvn_cc,mvn_cc_ind,mvn_cc_dat 
	common mvn_cd,mvn_cd_ind,mvn_cd_dat 
	common mvn_ce,mvn_ce_ind,mvn_ce_dat 
	common mvn_cf,mvn_cf_ind,mvn_cf_dat 
	common mvn_d0,mvn_d0_ind,mvn_d0_dat 
	common mvn_d1,mvn_d1_ind,mvn_d1_dat 
	common mvn_d2,mvn_d2_ind,mvn_d2_dat 
	common mvn_d3,mvn_d3_ind,mvn_d3_dat 
	common mvn_d4,mvn_d4_ind,mvn_d4_dat 


	mvn_c6_dat.sc_pot = pot_all
	mvn_c6_dat.quality_flag = (mvn_c6_dat.quality_flag and 30719) or fix(round(2^11*(1-pot_valid)))

	pot_c0 = interp(pot_all,time,(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.) & mvn_c0_dat.sc_pot = pot_c0
	pot_valid_c0 = fix(round(interp(pot_valid,time,(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.))) & mvn_c0_dat.quality_flag = (mvn_c0_dat.quality_flag and 30719) or 2^11*(1-pot_valid_c0)

	pot_ca = interp(pot_all,time,(mvn_ca_dat.time+mvn_ca_dat.end_time)/2.) & mvn_ca_dat.sc_pot = pot_ca
	pot_valid_ca = fix(round(interp(pot_valid,time,(mvn_ca_dat.time+mvn_ca_dat.end_time)/2.))) & mvn_ca_dat.quality_flag = (mvn_ca_dat.quality_flag and 30719) or 2^11*(1-pot_valid_ca)

	if size(mvn_c8_dat,/type) eq 8 then begin
		pot_c8 = interp(pot_all,time,(mvn_c8_dat.time+mvn_c8_dat.end_time)/2.) & mvn_c8_dat.sc_pot = pot_c8
		pot_valid_c8 = fix(round(interp(pot_valid,time,(mvn_c8_dat.time+mvn_c8_dat.end_time)/2.))) & mvn_c8_dat.quality_flag = (mvn_c8_dat.quality_flag and 30719) or 2^11*(1-pot_valid_c8)
	endif
	if size(mvn_d4_dat,/type) eq 8 then begin
		pot_d4 = interp(pot_all,time,(mvn_d4_dat.time+mvn_d4_dat.end_time)/2.) & mvn_d4_dat.sc_pot = pot_d4
		pot_valid_d4 = fix(round(interp(pot_valid,time,(mvn_d4_dat.time+mvn_d4_dat.end_time)/2.))) & mvn_d4_dat.quality_flag = (mvn_d4_dat.quality_flag and 30719) or 2^11*(1-pot_valid_d4)
	endif

	if size(mvn_cc_dat,/type) eq 8 then begin
		pot_cca = interp(pot_all,time,mvn_cc_dat.time+2.)
		pot_ccb = interp(pot_all,time,mvn_cc_dat.end_time-2.)
		pot_ccc = interp(pot_all,time,(mvn_cc_dat.time+mvn_cc_dat.end_time)/2.)
		mvn_cc_dat.sc_pot = (pot_cca+pot_ccb+2.*pot_ccc)/4.
		ind = where(mvn_cc_dat.sc_pot eq 0.,count)
		mvn_cc_dat.quality_flag = mvn_cc_dat.quality_flag and 30719
		mvn_cc_dat.quality_flag[ind] = mvn_cc_dat.quality_flag[ind] or 2^11
	endif
	if size(mvn_cd_dat,/type) eq 8 then begin
		pot_cda = interp(pot_all,time,mvn_cd_dat.time+2.)
		pot_cdb = interp(pot_all,time,mvn_cd_dat.end_time-2.)
		pot_cdc = interp(pot_all,time,(mvn_cd_dat.time+mvn_cd_dat.end_time)/2.)
		mvn_cd_dat.sc_pot = (pot_cda+pot_cdb+2.*pot_cdc)/4.
		ind = where(mvn_cd_dat.sc_pot eq 0.,count)
		mvn_cd_dat.quality_flag = mvn_cd_dat.quality_flag and 30719
		mvn_cd_dat.quality_flag[ind] = mvn_cd_dat.quality_flag[ind] or 2^11
	endif
	if size(mvn_ce_dat,/type) eq 8 then begin
		pot_cea = interp(pot_all,time,mvn_ce_dat.time+2.)
		pot_ceb = interp(pot_all,time,mvn_ce_dat.end_time-2.)
		pot_cec = interp(pot_all,time,(mvn_ce_dat.time+mvn_ce_dat.end_time)/2.)
		mvn_ce_dat.sc_pot = (pot_cea+pot_ceb+2.*pot_cec)/4.
		ind = where(mvn_ce_dat.sc_pot eq 0.,count)
		mvn_ce_dat.quality_flag = mvn_ce_dat.quality_flag and 30719
		mvn_ce_dat.quality_flag[ind] = mvn_ce_dat.quality_flag[ind] or 2^11
	endif
	if size(mvn_cf_dat,/type) eq 8 then begin
		pot_cfa = interp(pot_all,time,mvn_cf_dat.time+2.)
		pot_cfb = interp(pot_all,time,mvn_cf_dat.end_time-2.)
		pot_cfc = interp(pot_all,time,(mvn_cf_dat.time+mvn_cf_dat.end_time)/2.)
		mvn_cf_dat.sc_pot = (pot_cfa+pot_cfb+2.*pot_cfc)/4.
		ind = where(mvn_cf_dat.sc_pot eq 0.,count)
		mvn_cf_dat.quality_flag = mvn_cf_dat.quality_flag and 30719
		mvn_cf_dat.quality_flag[ind] = mvn_cf_dat.quality_flag[ind] or 2^11
	endif
	if size(mvn_d0_dat,/type) eq 8 then begin
		pot_d0a = interp(pot_all,time,mvn_d0_dat.time+2.)
		pot_d0b = interp(pot_all,time,mvn_d0_dat.end_time-2.)
		pot_d0c = interp(pot_all,time,(mvn_d0_dat.time+mvn_d0_dat.end_time)/2.)
		mvn_d0_dat.sc_pot = (pot_d0a+pot_d0b+2.*pot_d0c)/4.
		ind = where(mvn_d0_dat.sc_pot eq 0.,count)
		mvn_d0_dat.quality_flag = mvn_d0_dat.quality_flag and 30719
		mvn_d0_dat.quality_flag[ind] = mvn_d0_dat.quality_flag[ind] or 2^11
	endif
	if size(mvn_d1_dat,/type) eq 8 then begin
		pot_d1a = interp(pot_all,time,mvn_d1_dat.time+2.)
		pot_d1b = interp(pot_all,time,mvn_d1_dat.end_time-2.)
		pot_d1c = interp(pot_all,time,(mvn_d1_dat.time+mvn_d1_dat.end_time)/2.)
		mvn_d1_dat.sc_pot = (pot_d1a+pot_d1b+2.*pot_d1c)/4.
		ind = where(mvn_d1_dat.sc_pot eq 0.,count)
		mvn_d1_dat.quality_flag = mvn_d1_dat.quality_flag and 30719
		mvn_d1_dat.quality_flag[ind] = mvn_d1_dat.quality_flag[ind] or 2^11
	endif
	if size(mvn_d2_dat,/type) eq 8 then begin
		pot_d2a = interp(pot_all,time,mvn_d2_dat.time+2.)
		pot_d2b = interp(pot_all,time,mvn_d2_dat.end_time-2.)
		pot_d2c = interp(pot_all,time,(mvn_d2_dat.time+mvn_d2_dat.end_time)/2.)
		mvn_d2_dat.sc_pot = (pot_d2a+pot_d2b+2.*pot_d2c)/4.
		ind = where(mvn_d2_dat.sc_pot eq 0.,count)
		mvn_d2_dat.quality_flag = mvn_d2_dat.quality_flag and 30719
		mvn_d2_dat.quality_flag[ind] = mvn_d2_dat.quality_flag[ind] or 2^11
	endif
	if size(mvn_d3_dat,/type) eq 8 then begin
		pot_d3a = interp(pot_all,time,mvn_d3_dat.time+2.)
		pot_d3b = interp(pot_all,time,mvn_d3_dat.end_time-2.)
		pot_d3c = interp(pot_all,time,(mvn_d3_dat.time+mvn_d3_dat.end_time)/2.)
		mvn_d3_dat.sc_pot = (pot_d3a+pot_d3b+2.*pot_d3c)/4.
		ind = where(mvn_d3_dat.sc_pot eq 0.,count)
		mvn_d3_dat.quality_flag = mvn_d3_dat.quality_flag and 30719
		mvn_d3_dat.quality_flag[ind] = mvn_d3_dat.quality_flag[ind] or 2^11
	endif

print,' c6 sc_pot added to structures c6, c0, c8, ca, cc, cd, ce, cf, d0, d1, d2, d3, d4'

return

end
