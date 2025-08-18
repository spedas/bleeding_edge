;+
;PROCEDURE:	mvn_sta_bkg_stragglers
;PURPOSE:	
;	Adds straggler background from solar wind protons, alphas
;		Should first run mvn_sta_bkg_load and mvn_sta_bkg_correct to load other backgrounds and fill the 
;		Or run mvn_sta_l2_load,/iv1 and mvn_sta_bkg_correct and restore,filename='C:\data\maven\data\sci\sta\iv1\dead\year\mo\mvn_sta_dead_yearmoda.sav' 
;		Or run mvn_sta_l2_load,/iv2 and restore,filename='C:\data\maven\data\sci\sta\iv1\dead\year\mo\mvn_sta_dead_yearmoda.sav' 
;INPUT:		
;
;KEYWORDS:
;	save_bkg	0/1	if set, will save    current bkg and exit
;	restore_bkg	0/1	if set, will restore current bkg and exit
;	trange		dbl(2)	tbd, not working  - time range for background subtraction - used for testing
;					default is full time range - 
;
;CREATED BY:	J. McFadden 20/09/05
;VERSION:	1
;LAST MODIFICATION:  20/09/05		
;MOD HISTORY:
;
;NOTES:	  
;	straggle0 is a proton ghost peak and linear in rate
;	straggle4 is an alpha ghost peak and linear in rate
;	straggle1,2 are actual protons stragglers and linear in rate 
;	straggle5,6 are actual alphas  stragglers and linear in rate 
;	straggle3,8 are non-linear events from protons and a slow TOF circuit reset
;	straggle7,9 are non-linear events from alphas  and a slow TOF circuit reset
;	straggle10 is a ghost peak from protons sputtering e- which produce a weak C++ signal - linear in rate 
;-

pro mvn_sta_bkg_stragglers_all,save_bkg=save_bkg,restore_bkg=restore_bkg,fix_anode=fix_anode

starttime = systime(1)

	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
	common mvn_c8,mvn_c8_ind,mvn_c8_dat 
	common mvn_ca,mvn_ca_ind,mvn_ca_dat 
	common mvn_d0,mvn_d0_ind,mvn_d0_dat 
	common mvn_d1,mvn_d1_ind,mvn_d1_dat 
	common mvn_sta_dead,dat_dead	

; check if required c6 data is loaded

if size(dat_dead,/type) ne 8 then begin
	print,'Error - dat_dead common block must be loaded'
	print,'     Either run: restore,filename=C:\data\maven\data\sci\sta\iv1\dead\year\mo\mvn_sta_dead_yearmoda.sav' 
	print,'     or     run: mvn_sta_dead_load,/make_common 
	return
endif

if max(total(mvn_c6_dat.bkg[*,*,56:63],3)) lt 1. then begin
	print,'Error - it appears that coincident background is not loaded, run mvn_sta_bkg_load.pro'
	return
endif

get_data,'coincidence_corr_arr',data=coin_corr			; this is created by restore of the idlsave file
if size(coin_corr,/type) ne 8 then begin
	print,'Error - tplot variable coincidence_corr_arr must be loaded'
	print,'     Run: mvn_sta_bkg_correct,/test
	return
endif

; these are for testing

if keyword_set(save_bkg) then begin
	common bkg_c0_straggler,bkg_c0_arr_old
	common bkg_c6_straggler,bkg_c6_arr_old
	common bkg_c8_straggler,bkg_c8_arr_old
	common bkg_ca_straggler,bkg_ca_arr_old
	common bkg_d0_straggler,bkg_d0_arr_old
	common bkg_d1_straggler,bkg_d1_arr_old
	if size(mvn_c0_dat,/type) eq 8 then bkg_c0_arr_old=mvn_c0_dat.bkg
	if size(mvn_c6_dat,/type) eq 8 then bkg_c6_arr_old=mvn_c6_dat.bkg
	if size(mvn_c8_dat,/type) eq 8 then bkg_c8_arr_old=mvn_c8_dat.bkg
	if size(mvn_ca_dat,/type) eq 8 then bkg_ca_arr_old=mvn_ca_dat.bkg
	if size(mvn_d0_dat,/type) eq 8 then bkg_d0_arr_old=mvn_d0_dat.bkg
	if size(mvn_d1_dat,/type) eq 8 then bkg_d1_arr_old=mvn_d1_dat.bkg
	print,'Background saved'
	return
endif

if keyword_set(restore_bkg) then begin
	common bkg_c0_straggler,bkg_c0_arr_old
	common bkg_c6_straggler,bkg_c6_arr_old
	common bkg_c8_straggler,bkg_c8_arr_old
	common bkg_ca_straggler,bkg_ca_arr_old
	common bkg_d0_straggler,bkg_d0_arr_old
	common bkg_d1_straggler,bkg_d1_arr_old
	if size(mvn_c6_dat,/type) eq 8 and size(bkg_c6_arr_old,/type) eq 4 then mvn_c6_dat.bkg=bkg_c6_arr_old
	if size(mvn_c0_dat,/type) eq 8 and size(bkg_c0_arr_old,/type) eq 4 then mvn_c0_dat.bkg=bkg_c0_arr_old
	if size(mvn_c8_dat,/type) eq 8 and size(bkg_c8_arr_old,/type) eq 4 then mvn_c8_dat.bkg=bkg_c8_arr_old
	if size(mvn_ca_dat,/type) eq 8 and size(bkg_ca_arr_old,/type) eq 4 then mvn_ca_dat.bkg=bkg_ca_arr_old
	if size(mvn_d0_dat,/type) eq 8 and size(bkg_d0_arr_old,/type) eq 4 then mvn_d0_dat.bkg=bkg_d0_arr_old
	if size(mvn_d1_dat,/type) eq 8 and size(bkg_d1_arr_old,/type) eq 4 then mvn_d1_dat.bkg=bkg_d1_arr_old
	print,'Background restored'
	return
endif


;***********************************************************************************************
; misc notes -- orbits perhaps worth checking

; 20180128 - anode 10	- probably not used	
; 20180131 - anode 10	- tenuous, probably not used
; 20180827 - anode 10	- intense
; 20180215 - anode 12	- probably not used
; 20180710 - anode 12
; 20180730 - anode 12
; 20180314 - anode 14	- intense, 
; 20181015 - anode 13	- 
; 20180117* - anode 11,9
; 20180120* - anode 9weak
; 20180128* - anode 10
; 20180131* - anode 10weak
; 20180215* - anode 12
; 20180303* - anode 13

;***********************************************************************************************
; below are anode dependent constants that define the straggling funcional dependence on anode
; these constants are currently assumed to be time indepenent over the mission
; the 11 constants scale the linear and non-linear term in count rate
; amp3, amp7, amp8, amp9 are non-linear scale factors - vary as rate^2
; these calibration days have some data with the solar wind in the single identified anode 

; completed calibration used these days

; 20170626 - anode 0**  	
; 20170204 - anode 1**  	
; 20160402 - anode 2** 	
; 20160311 - anode 3**
; 20160303 - anode 4**
; 20160208 - anode 5**
; 20171221 - anode 6**
; 20171230 - anode 7**		
; 20180110 - anode 8**		
; 20180102 - anode 9**		
; 20180827 - anode 10**
; 20180205 - anode 11**	 	
; 20180730 - anode 12**
; 20181015 - anode 13**	
; 20180314 - anode 14**
; 20160402 - anode 15** 		 

; completed	0**	1**	2**	3**	4**	5**	6**	7**	8**	9**	10**	11**	12**	13**	14**	15**

	an_0 = [-0.35,	-0.19,	0.00,	-0.20,	-0.10,	-0.20,	-0.37,	-0.26,	-0.45,	-0.35,	-0.40,	-0.50,	-0.45,	-0.55,	-0.55,	-0.40]
	an_4 = [-0.35,	-0.19,	0.00,	-0.20,	-0.10,	-0.20,	-0.37,	-0.26,	-0.45,	-0.35,	-0.40,	-0.50,	-0.45,	-0.55,	-0.55,	-0.40]
	an_8 = [-0.35,	-0.19,	0.00,	-0.20,	-0.10,	-0.20,	-0.37,	-0.26,	-0.45,	-0.35,	-0.40,	-0.50,	-0.45,	-0.55,	-0.55,	-0.40]
	an_9 = [-0.35,	-0.19,	0.00,	-0.20,	-0.10,	-0.20,	-0.37,	-0.26,	-0.45,	-0.35,	-0.40,	-0.50,	-0.45,	-0.55,	-0.55,	-0.40]
	an_10= [ 0.00,	 0.00,	0.00,	 0.60,	 0.40,	-0.20,	 0.20 ,	 0.30,	-0.30,	-0.10,	-0.50,	-0.30,	-0.40,	-0.30,	-0.40,	-0.40]

	amp0 = [3.8e-3,	3.3e-3,	3.0e-3,	3.0e-3,	3.0e-3,	5.0e-3,	5.0e-3,	4.0e-3,	4.5e-3,	4.5e-3,	2.5e-3,	3.5e-3,	2.0e-3,	4.0e-3,	3.5e-3,	3.0e-3]		; proton ghost peak
	amp1 = [4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4,	4.0e-4]		; perhaps same for all anodes
	amp2 = [0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5,	0.7e-5]		; proton high mass tail
	amp3 = [4.0e-3,	7.5e-3,	5.8e-3,	4.5e-3,	5.5e-3,	4.7e-3,	6.5e-3,	6.5e-3,	6.0e-3,	5.7e-3,	3.5e-3,	8.0e-3,	5.5e-3,	7.0e-3,	6.0e-3,	5.5e-3]		; intense protons, non-lin

	amp4 = [3.6e-3,	3.0e-3,	2.0e-3,	2.0e-3,	2.0e-3,	3.0e-3,	4.0e-3,	3.0e-3,	3.0e-3,	3.0e-3,	2.0e-3,	2.5e-3,	1.5e-3,	3.0e-3,	2.5e-3,	2.0e-3]		; alpha ghost peak
	amp5 = [8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4,	8.0e-4]		; 2x amp1
	amp6 = [1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5,	1.6e-5]		; alpha high mass tail
	amp7 = [3.0e-3,	7.5e-3,	5.8e-3,	4.5e-3,	5.5e-3,	4.7e-3,	6.5e-3,	6.5e-3,	6.0e-3,	5.7e-3,	3.5e-3,	8.0e-3,	5.5e-3,	7.0e-3,	6.0e-3,	5.5e-3] 	; same as amp3, non-lin

	amp8 = [1.2e-2,	1.1e-2,	1.0e-2,	0.9e-2,	1.3e-2,	1.5e-2,	2.0e-2,	2.2e-2,	1.9e-2,	1.6e-2,	1.2e-2,	2.5e-2,	2.0e-2,	2.0e-2,	1.8e-2,	1.6e-2]		; intense protons, non-lin
	amp9 = [1.2e-2,	1.1e-2,	1.0e-2,	0.9e-2,	1.3e-2,	1.5e-2,	2.0e-2,	2.2e-2,	1.9e-2,	1.6e-2,	1.2e-2,	2.5e-2,	2.0e-2,	2.0e-2,	1.8e-2,	1.6e-2]		; same as amp8

	amp10= [0.1e-4,	0.1e-4,	2.0e-4,	5.5e-4,	5.5e-4,	5.5e-4,	5.0e-4,	5.0e-4,	5.0e-4,	8.0e-4,	5.0e-4,	7.0e-4,	1.0e-4,	4.0e-4,	1.0e-4,	1.0e-4]		; proton sputtered ghost peak

; completed	0**	1**	2**	3**	4**	5**	6**	7**	8**	9**	10**	11**	12**	13**	14**	15**

	exp1 = [-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0]
	exp5 = [-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0,	-1.0]
 
	exp3 = [-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5]
	exp7 = [-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5,	-0.5]

	wid0 = [0.23,	0.30,	0.30,	0.30,	0.30,	0.35,	0.35,	0.35,	0.35,	0.40,	0.35,	0.40,	0.30,	0.35,	0.35,	0.30]
	wid4 = [0.23,	0.30,	0.30,	0.30,	0.30,	0.35,	0.35,	0.35,	0.35,	0.40,	0.35,	0.40,	0.30,	0.35,	0.35,	0.30]
 
	wid1 = [2.8,	3.0,	3.5,	4.0,	4.5,	5.5,	4.8,	5.0,	6.0,	5.5,	4.0,	4.8,	4.0,	3.5,	3.3,	2.8]
	wid5 = [2.8,	3.0,	3.5,	4.0,	4.5,	5.5,	4.8,	5.0,	6.0,	5.5,	4.0,	4.8,	4.0,	3.5,	3.3,	2.8]

	wid3 = [2.8,	3.0,	3.5,	4.0,	4.5,	5.5,	4.8,	5.0,	6.0,	5.5,	4.0,	4.8,	4.0,	3.5,	3.3,	2.8]
	wid7 = [2.8,	3.0,	3.5,	4.0,	4.5,	5.5,	4.8,	5.0,	6.0,	5.5,	4.0,	4.8,	4.0,	3.5,	3.3,	2.8]

	wid8 = [0.60,	0.60,	0.50,	0.60,	0.60,	0.65,	0.65,	0.65,	0.65,	0.60,	0.60,	0.70,	0.65,	0.65,	0.70,	0.65]
	wid9 = [1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0,	1.0]

	wid10= [0.4,	0.4,	0.4,	0.4,	0.4,	0.5,	0.6,	0.6,	0.5,	0.5,	0.4,	0.5,	0.5,	0.4,	0.4,	0.4]

;***********************************************************************************************
; for testing purposes

if keyword_set(fix_anode) then begin

	an_0[*] = an_0[fix_anode]
	an_4[*] = an_4[fix_anode]
	an_8[*] = an_8[fix_anode]
	an_9[*] = an_9[fix_anode]
	an_10[*]= an_10[fix_anode]

	amp0[*] = amp0[fix_anode]
	amp1[*] = amp1[fix_anode]
	amp2[*] = amp2[fix_anode]
	amp3[*] = amp3[fix_anode]
	amp4[*] = amp4[fix_anode]
	amp5[*] = amp5[fix_anode]
	amp6[*] = amp6[fix_anode]
	amp7[*] = amp7[fix_anode]
	amp8[*] = amp8[fix_anode]
	amp9[*] = amp9[fix_anode]
	amp10[*]= amp10[fix_anode]

	exp1[*] = exp1[fix_anode]
	exp5[*] = exp5[fix_anode]
	exp3[*] = exp3[fix_anode]
	exp7[*] = exp7[fix_anode]

	wid0[*] = wid0[fix_anode]
	wid4[*] = wid4[fix_anode]
	wid1[*] = wid1[fix_anode]
	wid5[*] = wid5[fix_anode]
	wid3[*] = wid3[fix_anode]
	wid7[*] = wid7[fix_anode]
	wid8[*] = wid8[fix_anode]
	wid9[*] = wid9[fix_anode]
	wid10[*]= wid10[fix_anode]

	print,'Background parameters assume fixed anode = '+string(fix_anode)

endif


;***********************************************************************************************
;***********************************************************************************************
; main loop starts here

;***********************************************************************************************
;***********************************************************************************************
; add stragglers to apid c6 

	npts = n_elements(mvn_c6_dat.time)

for ii=0,npts-1 do begin
	
	time = mvn_c6_dat.time[ii]+2. 
	cnts = reform(mvn_c6_dat.data[ii,*,*])
	c6_cnt = reform(mvn_c6_dat.data[ii,*,*])
	bkg  = reform(mvn_c6_dat.bkg[ii,*,*])
	swp  = mvn_c6_dat.swp_ind[ii]
	mass = reform(mvn_c6_dat.mass_arr[swp,*,*]) 
;	mass_an = reform(replicate(1.,16)#reform(mass,32*64),16,32,64)
	mass_an = transpose(reform(replicate(1.,16*16*2)#reform(mass,32*64),16,16,64,64),[0,2,1,3])
	mlut = mvn_c6_dat.mlut_ind[ii]
	twt  = reform(mvn_c6_dat.twt_arr[mlut,*,*])
	twt_an = transpose(reform(replicate(1.,16*16*2)#reform(twt,32*64),16,16,64,64),[0,2,1,3])

	minval = min(abs(dat_dead.time-time),ind_dead)
	minval = min(abs(coin_corr.x-time),ind_coin)

	rate  = reform(dat_dead.rate[ind_dead,*,*])
	dead  = reform(dat_dead.dead[ind_dead,*,*])
	valid = reform(dat_dead.valid[ind_dead,*,*])
	anode = reform(dat_dead.anode[ind_dead,*,*])
; calculation of dat_dead.anode assumes even and odd energies (64E) have same anode distribution since no product has this information
	anode32 = reform(anode[indgen(32)*2,*])

;	anode_nonlin = reform(reform(transpose(anode32),16*32)#replicate(1.,64),16,32,64)
	anode_nonlin = reform(reform(transpose(anode),16*64)#replicate(1.,16*64),16,64,16,64)

	coin_val = reform(coin_corr.y[ind_coin,*])#replicate(1.,16)
	coin_val64 = reform(transpose(reform(reform(coin_corr.y[ind_coin,*])#replicate(1.,32),32,2,16),[1,0,2]),64,16)

;	The following have the dimensions [16A,64E,16D,64M]

	amp_straggle0 = reform(amp0 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle1 = reform(amp1 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle2 = reform(amp2 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle3 = reform(amp3 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle4 = reform(amp4 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle5 = reform(amp5 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle6 = reform(amp6 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle7 = reform(amp7 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle8 = reform(amp8 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle9 = reform(amp9 #replicate(1.,64l*16*64),16,64,16,64) 
	amp_straggle10= reform(amp10#replicate(1.,64l*16*64),16,64,16,64) 

	anode_off0 = reform(an_0 #replicate(1.,64l*16*64),16,64,16,64) 
	anode_off4 = reform(an_4 #replicate(1.,64l*16*64),16,64,16,64) 
	anode_off8 = reform(an_8 #replicate(1.,64l*16*64),16,64,16,64) 
	anode_off9 = reform(an_9 #replicate(1.,64l*16*64),16,64,16,64) 
	anode_off10= reform(an_10#replicate(1.,64l*16*64),16,64,16,64) 

	exp_1 = reform(exp1 #replicate(1.,64l*16*64),16,64,16,64) 
	exp_3 = reform(exp3 #replicate(1.,64l*16*64),16,64,16,64) 
	exp_5 = reform(exp5 #replicate(1.,64l*16*64),16,64,16,64) 
	exp_7 = reform(exp7 #replicate(1.,64l*16*64),16,64,16,64) 

	width0 = reform(wid0 #replicate(1.,64l*16*64),16,64,16,64) 
	width1 = reform(wid1 #replicate(1.,64l*16*64),16,64,16,64) 
	width3 = reform(wid3 #replicate(1.,64l*16*64),16,64,16,64) 
	width4 = reform(wid4 #replicate(1.,64l*16*64),16,64,16,64) 
	width5 = reform(wid5 #replicate(1.,64l*16*64),16,64,16,64) 
	width7 = reform(wid7 #replicate(1.,64l*16*64),16,64,16,64) 
	width8 = reform(wid8 #replicate(1.,64l*16*64),16,64,16,64) 
	width9 = reform(wid9 #replicate(1.,64l*16*64),16,64,16,64) 
	width10= reform(wid10#replicate(1.,64l*16*64),16,64,16,64) 

; nonlinear term scaling for counts: c6_nor_1 assumes relative proton/all_ion counts are independent of deflector
;	c6_nor_1[64E,16D] - no deflector dependence
; 	coin_val64, c6_nor_1, valid, rate, dead - arrays[64E,16D]
;	nonlin_straggle1[16A,64E,16D,64M]

	c6_nor_1 = reform(transpose(reform(reform(total(c6_cnt[*,0:7],2)/(total(c6_cnt[*,*],2)+.0000001))#replicate(1.,32),32,2,16),[1,0,2]),64,16)		; 64Ex16D
;	nonlin_straggle1 = transpose(reform(total(total(reform(coin_val64*c6_nor_1*valid*rate*dead/1.e6,2,32,16),1),2)#replicate(1.,16*64),32,16,64),[1,0,2])
	nonlin_straggle1 = transpose(reform(reform(coin_val64*c6_nor_1*valid*rate*dead/1.e6,64*16)#replicate(1.,16*64),64,16,16,64),[2,0,1,3])   

	c6_nor_2 = reform(transpose(reform(reform(total(c6_cnt[*,8:15],2)/(total(c6_cnt[*,*],2)+.0000001))#replicate(1.,32),32,2,16),[1,0,2]),64,16)
;	nonlin_straggle2 = transpose(reform(total(total(reform(coin_val64*c6_nor_2*valid*rate*dead/1.e6,2,32,16),1),2)#replicate(1.,16*64),32,16,64),[1,0,2])
	nonlin_straggle2 = transpose(reform(reform(coin_val64*c6_nor_2*valid*rate*dead/1.e6,64*16)#replicate(1.,16*64),64,16,16,64),[2,0,1,3])   

; linear scaling for counts: anode[64E,16A], c6_nor_1[64E,16D], valid[64E,16D]
; nor_straggling1[16A,64E,16D,64M] - no mass dependance

;	c6_nor_1_32 = total(reform(c6_nor_1,2,32,16),1)		
;	c6_nor_2_32 = total(reform(c6_nor_2,2,32,16),1)		

;	temp1 = reform(reform(transpose(anode),16*64)#replicate(1.,16),16,64,16) * reform(replicate(1.,16)#reform(c6_nor_1*valid/2.,64*16),16,64,16) 
;	nor_straggling1 = reform(reform(temp1,16*64*16)#replicate(1.,64),16,64,16,64) 	; why is it divided by 2? - scale could be elsewhere

	nor_straggling1 = reform(reform( reform(reform(transpose(anode),16*64)#replicate(1.,16),16,64,16) * reform(replicate(1.,16)#reform(c6_nor_1*valid/2.,64*16),16,64,16) ,16*64*16) # replicate(1.,64),16,64,16,64) 	; why is it divided by 2? - scale could be elsewhere
	nor_straggling2 = reform(reform( reform(reform(transpose(anode),16*64)#replicate(1.,16),16,64,16) * reform(replicate(1.,16)#reform(c6_nor_2*valid/2.,64*16),16,64,16) ,16*64*16) # replicate(1.,64),16,64,16,64) 	; why is it divided by 2? - scale could be elsewhere

;	nor_straggling1 = reform(reform(transpose(anode32)*(replicate(1.,16)#total(cnts[*,0:7] ,2)/2.),16*32) # replicate(1.,64),16,32,64)		; why is it divided by 2? - scale could be elsewhere
;	nor_straggling2 = reform(reform(transpose(anode32)*(replicate(1.,16)#total(cnts[*,8:15],2)/2.),16*32) # replicate(1.,64),16,32,64)		; why is it divided by 2? - scale could be elsewhere


; The following contains the mass dependence of this background

; straggle0[16A,32E,16D,64M]


	straggle0 = amp_straggle0 * exp(-(mass_an-(3.1+anode_off0))^2/width0^2)		
	straggle1 = amp_straggle1 * exp(-((mass_an-1.5)>0)^3/width1^3)*(mass_an/4.)^(exp_1)	
	straggle2 = amp_straggle2 * (mass_an/50.)^(-1.5)
	straggle3 = amp_straggle3 * exp(-((mass_an-1.5)>0)^3/width3^3)*(mass_an/1.5)^(exp_3)			 		
	straggle4 = amp_straggle4 * exp(-(mass_an-(4.7+anode_off4))^2/width4^2)		
	straggle5 = amp_straggle5 * exp(-((mass_an-3.0)>0)^3/width5^3)*(mass_an/4.)^(exp_5)	
	straggle6 = amp_straggle6 * (mass_an/50.)^(-1.5)			 		
	straggle7 = amp_straggle7 * exp(-((mass_an-3.0)>0)^3/width7^3)*(mass_an/3.0)^(exp_7)
	straggle8 = amp_straggle8 * exp(-(mass_an-(1.5+anode_off8))^2/width8^2)		
	straggle9 = amp_straggle9 * exp(-(mass_an-(2.5+anode_off9))^2/width9^2)		
	straggle10= amp_straggle10* exp(-(mass_an-(6.5+anode_off10))^2/width10^2)		


; calculate backgrounds

	bkg0 = nor_straggling1	* straggle0			*twt_an/4. 	& bkg0[*,*,*,0:7]=0. 	; why twt_an/4.
	bkg1 = nor_straggling1	* straggle1			*twt_an/4. 	& bkg1[*,*,*,0:7]=0.
	bkg2 = nor_straggling1	* straggle2			*twt_an/4. 	& bkg2[*,*,*,0:7]=0.
	bkg3 = nonlin_straggle1	* straggle3 *anode_nonlin	*twt_an/4.  	& bkg3[*,*,*,0:7]=0.

	bkg4 = nor_straggling2	* straggle4			*twt_an/4. 	& bkg4[*,*,*,0:13]=0.
	bkg5 = nor_straggling2	* straggle5			*twt_an/4. 	& bkg5[*,*,*,0:13]=0.
	bkg6 = nor_straggling2	* straggle6			*twt_an/4. 	& bkg6[*,*,*,0:13]=0.
	bkg7 = nonlin_straggle2	* straggle7 *anode_nonlin	*twt_an/4.  	& bkg7[*,*,*,0:13]=0.

	bkg8 = nonlin_straggle1	* straggle8 *anode_nonlin	*twt_an/4.  	& bkg8[*,*,*,0:7]=0.
	bkg9 = nonlin_straggle2	* straggle9 *anode_nonlin	*twt_an/4.  	& bkg9[*,*,*,0:13]=0.

	bkg10= nor_straggling1	* straggle10			*twt_an/4. 	& bkg10[*,*,*,0:7]=0. 	; why twt/4.

; combine the terms

	bkg_strag = fltarr(16,64,16,64)
	bkg_strag = bkg0+bkg1+bkg2+bkg3+bkg4+bkg5+bkg6+bkg7+bkg8+bkg9+bkg10

	if (ii mod 1000) eq 0 then print,'c6 ii=',ii,' out of ',npts,total(bkg_strag),total(mvn_c6_dat.bkg[ii,*,*])

; add stragglers to apid c6 

	mvn_c6_dat.bkg[ii,*,*] = mvn_c6_dat.bkg[ii,*,*] + total(reform(total(total(bkg_strag,3),1),2,32,64),1)

; add stragglers to apid c0 

	minval = min(abs(mvn_c0_dat.time-time+2.),ii_c0)
	if (time lt mvn_c0_dat.end_time[ii_c0]) and (time gt mvn_c0_dat.time[ii_c0]) then begin
		mvn_c0_dat.bkg[ii_c0,*,*] = mvn_c0_dat.bkg[ii_c0,*,*] + total(reform(total(total(bkg_strag,3),1),64,32,2),2)
	endif

; add stragglers to apid c8 

	minval = min(abs(mvn_c8_dat.time-time+2.),ii_c8)
	if (time lt mvn_c8_dat.end_time[ii_c8]) and (time gt mvn_c8_dat.time[ii_c8]) then begin
		mvn_c8_dat.bkg[ii_c8,*,*] = mvn_c8_dat.bkg[ii_c8,*,*] + total(reform(total(total(bkg_strag,4),1),2,32,16),1)
	endif

; add stragglers to apid ca 

	minval = min(abs(mvn_ca_dat.time-time+2.),ii_ca)
	if (time lt mvn_ca_dat.end_time[ii_ca]) and (time gt mvn_ca_dat.time[ii_ca]) then begin
		mvn_ca_dat.bkg[ii_ca,*,*] = mvn_ca_dat.bkg[ii_ca,*,*] + reform(transpose(total(total(reform(total(bkg_strag,4),16,4,16,4,4),4),2),[1,2,0]),16,64)
	endif

; add stragglers to apid d0 

	minval = min(abs((mvn_d0_dat.time+mvn_d0_dat.end_time)/2.-time),ii_d0)
	if (time lt mvn_d0_dat.end_time[ii_d0]) and (time gt mvn_d0_dat.time[ii_d0]) then begin
		mvn_d0_dat.bkg[ii_d0,*,*,*] = mvn_d0_dat.bkg[ii_d0,*,*,*] + reform(transpose(total(total(total(reform(bkg_strag,16,2,32,4,4,8,8),6),4),2),[1,2,0,3]),32,64,8)
	endif

; add stragglers to apid d1

	if size(mvn_d1_dat,/type) eq 8 then begin
	minval = min(abs((mvn_d1_dat.time+mvn_d1_dat.end_time)/2.-time),ii_d1)
	if (time lt mvn_d1_dat.end_time[ii_d1]) and (time gt mvn_d1_dat.time[ii_d1]) then begin
		mvn_d1_dat.bkg[ii_d1,*,*,*] = mvn_d1_dat.bkg[ii_d1,*,*,*] + reform(transpose(total(total(total(reform(bkg_strag,16,2,32,4,4,8,8),6),4),2),[1,2,0,3]),32,64,8)
	endif
	endif

endfor


; print out the run time

	print,'mvn_sta_bkg_stragglers run time = ',systime(1)-starttime

end
