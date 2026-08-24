;+
;PROCEDURE:	mvn_sta_c6_bkg_load
;PURPOSE:	
;	Loads background data into APID c6 common block 
;INPUT:		
;
;KEYWORDS:
;
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  19/04/04
;MOD HISTORY:
;
;NOTES:	  
;	Assume all counts in a single anode - should be fine for periapsis
; bkg5 are proton stragglers
; bkg7 is background from coincident events where different ions (or radiation) produce start and stop
; bkg8 is background created by residual charge on TOF capacitor with a cross talk event that triggers both start and stop
; bkg9 is background created by delayed Start signal from scattered molecular ion fragment that failed to produce a start at the carbon foil
;-

pro mvn_sta_c6_bkg_load

common mvn_c6,mvn_c6_ind,mvn_c6_dat 
common mvn_db,mvn_db_ind,mvn_db_dat 
common mvn_d9,mvn_d9_ind,mvn_d9_dat 
common mvn_d8,mvn_d8_ind,mvn_d8_dat 

if size(mvn_c6_dat,/type) ne 8 then begin
	print,'Error - c6 data not loaded'
	return
endif
if size(mvn_db_dat,/type) ne 8 then begin
	print,'Error - db data not loaded'
	return
endif
if size(mvn_d9_dat,/type) ne 8 then begin
	print,'Error - d9 data not loaded'
	return
endif
if size(mvn_d8_dat,/type) ne 8 then begin
	print,'Error - d8 data not loaded'
	return
endif

	nenergy = mvn_c6_dat.nenergy

;***************************************************************************************
; must run mvn_sta_dead_load,/test,/make_common for this to work

common mvn_sta_dead,dat_dead	

if size(dat_dead,/type) ne 8 then begin
	print,'Error - mvn_sta_dead common not created. RUN: mvn_sta_dead_load,/test,/make_common'
	return
endif

if max(dat_dead.rate) eq 0. then begin
	print,'Error - rate data indicates background is zero'
	return
endif

	st_eff = replicate(1.,64)#replicate(.70,16) 						; start eff of protons, assume energy independent, initially assume anode/time independent but change it later
	sp_eff = replicate(1.,64)#replicate(.47,16) 						; stop  eff of protons, assume energy independent, initially assume anode/time independent but change it later
	st_no_stop_eff = replicate(1.,64)#replicate(.70,16) 					; start eff of protons, assume energy independent, initially assume anode/time independent but change it later

	scale = 1.0d
	no_sp_eff = .45									; fraction of start_no_stop in rst - may need droop correction
	sp_eff = .47									; fraction of start_no_stop in rst - may need droop correction
	integ_t = 0.0037988282								; accumulation time for a single sample, roughly 4s/1024.
	b_ns  = 5.844 									; tof bins per ns
	tof_offset = 16.

; the following change allows mvn_sta_l2_tplot.pro to be run after this mvn_sta_c6_bkg_load.pro

;	get_data,'mvn_sta_d8_R1_eff_start',data=tmp1a
	tmp1a = {x:mvn_d8_dat.time,y:mvn_d8_dat.rates[*,7]/(mvn_d8_dat.rates[*,11]>1.e-10)}
;	get_data,'mvn_sta_d8_R1_eff_stop',data=tmp2a
	tmp2a = {x:mvn_d8_dat.time,y:mvn_d8_dat.rates[*,7]/(mvn_d8_dat.rates[*,10]>1.e-10)}
;	get_data,'mvn_sta_d8_R1_Unqual',data=tmp3a
	tmp3a = {x:mvn_d8_dat.time,y:mvn_d8_dat.rates[*,6]}
;	get_data,'mvn_sta_d8_R1_RST',data=tmp4a
	tmp4a = {x:mvn_d8_dat.time,y:mvn_d8_dat.rates[*,4]}
;	get_data,'mvn_sta_d8_R1_NoStart',data=tmp5a
	tmp5a = {x:mvn_d8_dat.time,y:mvn_d8_dat.rates[*,5]}
;	get_data,'mvn_sta_d8_R1_A&B',data=tmp6a
	tmp6a = {x:mvn_d8_dat.time,y:mvn_d8_dat.rates[*,10]}
;	get_data,'mvn_sta_d8_R1_Qual',data=tmp7a
	tmp7a = {x:mvn_d8_dat.time,y:mvn_d8_dat.rates[*,7]}

	get_data,'mvn_sta_dl_eff_qual',data=tmp8a

;		 	 0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
	mass_offset = [.05, .03, .05, .08, .00, .00, .00, .00, .15, .13, .18, .20, .20, .17, .20, .20]

; 20160124 	anode 6,11
	sp_an_eff = [.415, .415, .440, .435, .420, .405, .405, .425, .460, .475, .420, .400, .435, .460, .440, .435]	; before anode reject table correction

;	anode number	0     1     2     3     4     5     6     7     8     9    10 	 11    12    13    14    15
; 20160401 	anode 0,1,2,7,12,13,15
	droop_rate = [1.00, 1.20, 1.00, 1.00, 1.00, 1.00, 1.00, 1.20, 1.00, 1.00, 1.00, 1.00, 1.40, 1.00, 1.00, 1.00]*1.		; anode-11 assume same as 10
	droop_rate = [1.22, 1.25, 1.25, 1.00, 1.00, 1.00, 1.00, 1.45, 1.00, 1.00, 1.00, 1.00, 1.40, 1.10, 1.00, 1.15]*1.		; anode-11 assume same as 10
; 20180106 	anode 1,(5,6),8,9,13,15
	droop_rate = [1.22, 1.25, 1.25, 1.00, 1.00, 1.40, 1.40, 1.45, 1.00, 1.30, 1.00, 1.00, 1.40, 1.10, 1.00, 1.15]*1.		; anode-11 assume same as 10
; 20171223 	anode 4,6,7,12,13,15
	droop_rate = [1.22, 1.25, 1.25, 1.00, 1.00, 1.40, 1.40, 1.45, 1.00, 1.30, 1.00, 1.00, 1.40, 1.10, 1.00, 1.05]*1.		; anode-11 assume same as 10
; 20180113 	anode 8,9,
	droop_rate = [1.22, 1.25, 1.25, 1.00, 1.00, 1.40, 1.40, 1.45, 1.20, 1.25, 1.00, 1.00, 1.40, 1.10, 1.00, 1.15]*1.		; anode-11 assume same as 10
; 20160303 	anode 4,15
	droop_rate = [1.22, 1.25, 1.25, 1.00, 1.38, 1.40, 1.40, 1.45, 1.20, 1.25, 1.00, 1.00, 1.40, 1.10, 1.00, 1.05]*1.		; anode-11 assume same as 10
; 20160313 	anode 4,15
	droop_rate = [1.22, 1.25, 1.25, 1.10, 1.38, 1.40, 1.40, 1.45, 1.20, 1.25, 1.00, 1.00, 1.40, 1.10, 1.00, 1.05]*1.		; anode-11 assume same as 10
; 20170623 	anode 0,10,11,15
	droop_rate = [1.22, 1.25, 1.25, 1.10, 1.38, 1.40, 1.40, 1.45, 1.20, 1.25, 1.15, 1.40, 1.40, 1.10, 1.00, 1.05]*1.		; anode-11 assume same as 10


;***************************************************************************************
; the following is used to map molecular events to bkg9 background from an late TOF Start

tof1 = reform(mvn_c6_dat.tof_arr[1,31,*])		;
tof1 = (tof1+tof_offset)/b_ns
tof2 = fltarr(64,64)
;fra2 = .49
fra2 = .48
for i=0,63 do begin
	for j=0,63 do begin
		tof2[i,j] = (tof1[j] gt (1.-fra2)*tof1[i])*((tof1[i]-tof1[j])>0.)/(fra2*tof1[i])
	endfor
endfor

;***************************************************************************************

npts = n_elements(mvn_c6_dat.time)

for ii=0l,npts-1 do begin

	nearest = min(abs(dat_dead.time - mvn_c6_dat.time[ii]),ind)

	rate = reform(dat_dead.rate[ind,*,*])						; recorded event rates
	valid = reform(dat_dead.valid[ind,*,*])					
	droop = reform(dat_dead.droop[ind,*,*])					
	dead = reform(dat_dead.dead[ind,*,*])					
	anode = reform(dat_dead.anode[ind,*,*])	

	anode_sq = total(anode^2,2)#replicate(1.,16)	

	ratem = reform(dat_dead.rate[(ind-1)>0,*,*])						
	ratep = reform(dat_dead.rate[(ind+1)<npts-1,*,*])						
	sort_rate0 = rate[sort(rate)]					
	brate0 = total(sort_rate0[0:99])			
	sort_ratem = ratem[sort(ratem)]
	bratem = total(sort_ratem[0:99])		
	sort_ratep = ratep[sort(ratep)]
	bratep = total(sort_ratep[0:99])	
	brate = (brate0+bratem+bratep)/300.		

	mlut_ind = mvn_c6_dat.mlut_ind[ii]
	swp_ind = mvn_c6_dat.swp_ind[ii]
	tof_arr = reform(mvn_c6_dat.tof_arr[mlut_ind,*,*])
	twt_arr = reform(mvn_c6_dat.twt_arr[mlut_ind,*,*])

	nearest = min(abs(tmp1a.x - (mvn_c6_dat.time[ii]+2.)),ind_d8)

	tmp1 = tmp1a.y[ind_d8]		; st_eff
	tmp2 = tmp2a.y[ind_d8]		; sp_eff
	tmp3 = tmp3a.y[ind_d8]		; unqual
	tmp4 = tmp4a.y[ind_d8]		; rst
	tmp5 = tmp5a.y[ind_d8]		; nostart
	tmp6 = tmp6a.y[ind_d8]		; A&B
	tmp7 = tmp7a.y[ind_d8]		; qual

	nearest = min(abs(tmp8a.x - (mvn_c6_dat.time[ii]+2.)),ind_dl)
	tmp8 = tmp8a.y[ind_dl]							; qu_eff
	
	nearest = min(abs((mvn_db_dat.time+mvn_db_dat.end_time)/2. - (mvn_c6_dat.time[ii]+2.)),ind_db)
	db_arr = reform(mvn_db_dat.data[ind_db,*])
	qu_valid = total(db_arr[42:815])/total(db_arr)

	nearest = min(abs((mvn_d9_dat.time+mvn_d9_dat.end_time)/2.-(mvn_c6_dat.time[ii]+2.)),ind_d9)
	indbk9 = sort(mvn_d9_dat.rates[ind_d9,7,*])
	bk7 = total(mvn_d9_dat.rates[ind_d9,7,indbk9[0:9]])/10.
	tmp9 = total(valid)/((4.*qu_valid*(tmp7-bk7)) > 1.1*total(valid))
if (tmp8 gt tmp9) then print,tmp8,tmp9,qu_valid,total(valid),tmp7,bk7,brate,total(rate*integ_t)

; ,total(rate)/1024.,total(sort_rate0[0:1023])*integ_t,total(sort_rate0[0:500])*integ_t,total(sort_rate0[0:99])*integ_t
	
;***************************************************************************************
; bkg5 are proton stragglers

	offset_an_arr 	= replicate(1.,64)#mass_offset
	offset_an	= reform(total(reform(anode,2,32,16),1),32,16)
	offset_arr 	= total(offset_an_arr*offset_an,2)#replicate(1.,64)

	cnts = reform(mvn_c6_dat.data[ii,*,*])
	mass = reform(mvn_c6_dat.mass_arr[swp_ind,*,*]) - offset_arr

	p_cts = total(cnts[*,0:7],2)#replicate(1.,64)
	aa0 = (2.5 le mass and mass lt 3.5)*.0025*p_cts*exp(-(mass-3.)^(2)/.3^2)*3.^(-2)
	aa1 = (1.5 le mass and mass lt 7.)*.002*p_cts *mass^(-2)               
	aa2 = (7 le mass and mass lt 9.) *.002*p_cts *7.^(-2)*(mass/7.)^(-6.)       
	aa3 = (9. le mass and mass lt 23.)*.002*p_cts*7.^(-2)*(9./7.)^(-6.)*(mass/9.)^(-1.)      
	bkg5 = (aa0+aa1+aa2+aa3)*twt_arr
;	bkg5 = 2.*(aa0+aa1+aa2+aa3)*twt_arr

;***************************************************************************************
; bkg7 is background from coincident events where different ions (or radiation) produce start and stop
; bkg7 is proportional to total rate squared 
; bkg7 depends on the anode distribution of events - which differs for beams and penetrating radiation
; bkg7 is due to a "start_no_stop" followed by a stop from a second ion or penetrating background
; bkg7 will be underestimated when variations in solar wind flux occur during a sample period.  


	st_eff = replicate(tmp1,64,16)
	sp_eff = replicate(tmp2,64,16)
	qu_eff = replicate(tmp8,64,16)
	qu_eff[*,*] = .8					; not sure which is better
	qu_eff[*,*] = tmp9>tmp8					; not sure which is better

	droop_an_arr 	= replicate(1.,64)#droop_rate
	droop_arr 	= total(droop_an_arr*anode,2)#replicate(1.,16)

	avg_droop = replicate(total(valid*droop)/total(valid),64,16)
	droop_eff_corr = avg_droop/droop

	sp_an_eff_arr = replicate(1.,64)#sp_an_eff
	sp_eff_arr = total(sp_an_eff_arr*anode,2)#replicate(1.,16)
	ab_rate_ratio = replicate(tmp6/(tmp4+.001),64,16)		; A&B/RST
	st_no_sp_eff = (1.- sp_eff_arr)*ab_rate_ratio

	corr_rate = 1. + (1.-st_eff)*(1.-sp_eff)
	st_no_sp_eff = st_no_sp_eff*droop_eff_corr*droop_arr


	rbkg1 = scale*st_no_sp_eff*rate*corr_rate*(anode_sq*qu_eff)*integ_t* (sp_eff_arr*rate*corr_rate*dead*1d*1.e-9/b_ns)		; not sure which is better
;	rbkg1 = scale*st_no_sp_eff*rate*corr_rate*(anode_sq<qu_eff)*integ_t* (sp_eff_arr*rate*corr_rate*dead*1d*1.e-9/b_ns)
	rbkg2 = total(total(reform(rbkg1,2,32,16),1),2)
	bkg7 = (rbkg2#replicate(1,64))*twt_arr					; total bkg per tof bin

;***************************************************************************************

; bkg8 and bkg8a look like stragglers but are caused by incomplete discharge in the TOF capacitor from Start-no-Stop events 
; bkg8 are from Start-no-Stop followed closely a proton event 
; bkg8a are from Start-no-Stop followed closely by a TOF=0 event caused by Start-Stop cross-talk (these events are most easily see in apid DB)

; bkg8 is background created by residual charge on TOF capacitor with a cross talk event that triggers both start and stop
; bkg8 is proportional to total rate squared 
; fudge_factor2 is a scale factor determined empirically in conjunction with fudge_factor1 

; this is currently not working correctly

;	fudge_factor2 = 1.6
;	bkg8 = fudge_factor2*(bkg_cnts#replicate(1,64))*(twt_arr/1024.)*(tof_arr/175)^(-1.5)

	fudge_factor2 = .25
;	bkg8 = fudge_factor2*(rbkg2#replicate(1,64))*twt_arr*(tof_arr/175)^(-1.5)
;	bkg8 = fudge_factor2*(rbkg2#replicate(1,64))*twt_arr*(tof_arr/175)^(-3.)
;	bkg8 = fudge_factor2*(rbkg2#replicate(1,64))*twt_arr*(tof_arr/175)^(-4.)
	bkg8 = fudge_factor2*(rbkg2#replicate(1,64))*twt_arr*(tof_arr/175)^(-4.)*((total(cnts*(mass lt 1.5),2)/(total(cnts,2)+.0001))#replicate(1.,64))*(mass gt 1.5)

;***************************************************************************************
; bkg8a is background created by residual charge on TOF capacitor with a cross talk event that triggers both start and stop
; bkg8a is proportional to total rate squared 
; fudge_factor2a is a scale factor determined empirically in conjunction with fudge_factor1 

; under development

if 0 then begin
tof7 = (tof_arr+tof_offset)/b_ns
aa = (200.*tof7^(-1.5) + 5.e6*(tof7)^(-7.))


bb = (2./(1.+exp((tof7/23.)^6.)))

	fudge_factor2a = 28.
	bkg8a = fudge_factor2a*(rbkg2#replicate(1,64))*twt_arr*aa*bb
endif else bkg8a=0.

;***************************************************************************************
; bkg9 is background created by delayed Start signal from scattered molecular ion fragment that failed to produce a start at the carbon foil
; bkg9 is proportional to valid event rate - depicted in figures 33 & 34 of Mcfadden et al. 2015
; currently this background is only valid for low energy ions where the TOF bins are independent of energy
; bkg9 has two components

; bkg9 is primarily a low mass shoulder on the O2+ and CO2+ mass peaks seen in ground calibrations (N2+) and at Mars (O2+).
; 	This low mass shoulder background is only observed with molecules 
;	The low mass shoulder TOF relative to the primary molecule varies only with primary energy, not with TOF voltage.
;	This background is therefore internally produced in the TOF analyzer from a delayed START or early STOP signal, the latter having no known mechanism.
; 	These events are believed created by molecules hitting the start carbon foil grid (or suppression grid) and dissociating into two fragments
;	Neither fragment produces a normal START, while one fragment produces a normal STOP and the other a delayed START 
;	The delayed START is from a large angle scattering hitting an interal surface near the START foil and producing a secondary electron
;	Both O2+ and CO2+  exhibit a shoulder about 2 orders of magnitude below the nominal peak extending a factor of 2 in TOF below the peak
;	In addition, CO2+ exhibits a second peak about a factor of 17 below the primary peak at a TOF that peaks about a factor of 1.4 below the primary peak (see fig. 34 mcfadden et al.)
;	This secondary CO2+ peak is not observed in flight data at low energies and was likely a CO+ fragment from dissociation of keV ion molecules at the analyzer exit

; bkg9a also includes an ion peak at M/Q ~ 6-7, which shifts with TOF voltage but not with primary molecule energy (see fig. 34a mcfadden et al.)
;	This peak is believed to be C++ caused by backscattered secondary electrons produced at the START carbon foil by primary molecules
;	These electrons are accelerated to 15keV and strike the ESA sputtering C++ from surfaces (probably residual CO2 gas on the surfaces).   

; the following produces the low mass shoulder primarily from O2+, with contributions from other molecules such as CO2+, CO+, N2+, etc 

	dead_c6 = mvn_c6_dat.dead[ii,*,*]
	cxd = cnts*dead_c6/twt_arr*(mass gt 24. and mass lt 100.)
	bkg9 = .0020*twt_arr*(tof2##cxd)

	cxd = cnts*dead_c6/twt_arr*(mass gt 24. and mass lt 100.)
	bkg9a = 0.0016*twt_arr*((replicate(1.,64)#exp(-(tof1-31.2)^2/1.5^2))##cxd)


;***************************************************************************************
;***************************************************************************************
;***************************************************************************************

;	bkg_tot = bkg5+bkg7+bkg8+bkg8a+bkg9+bkg9a	
;	bkg_tot = bkg7+bkg8a+bkg9						; this is for testing 
	bkg_tot = bkg7+bkg9+bkg9a					; this is for testing 
;	bkg_tot = bkg8					; this is for testing 
	ind = where(bkg_tot lt .01,count)
;	if count gt 0 then bkg_tot[ind]=0.			; do we want to throw out tiny background

	mvn_c6_dat.bkg[ii,*,*] = bkg_tot

endfor
	
end

