;+
;PROCEDURE:	thm_load_peir
;PURPOSE:	
;	Decommutates the raw THEMIS ion esa reduced data packets, (peir - apid 455), and puts data structure in a common for access by get_th*_peir.pro and generates tplot energy spectrogram
;INPUT:		
;
;KEYWORDS:
;	file:		string, strarr	the complete path and filename to the raw pkt files
;					if not set, uses timerange to select files
;	sc:		string		themis spacecraft - "a", "b", "c", "d", "e"
;					if not set defaults to "a"		
;	themishome:	string		path to data dir, where data dir contains the th* dir, where *=a,b,c,d,e
;	gap_time	real		data gaps greater than gap_time have a NAN replacing a data point in tplot structures
; 	suffix		string		"suffix" is appended to the default tplot names 
;
;CREATED BY:	J. McFadden	  07/03/18
;VERSION:	1
;LAST MODIFICATION:  08/05/14
;MOD HISTORY:
;			suffix keyword added  08/05/14
;NOTES:	  
;	
;-

pro thm_load_peir,file=file,sc=sc,themishome=themishome, $
                  gap_time=gap_time,suffix=suffix,trange=trange, $
                  use_eclipse_corrections=use_eclipse_corrections

; suffix default
 	 if ~keyword_set(suffix) then suffix = ''

; sc default
	if not keyword_set(sc) then begin
		dprint, 'S/C number not set, default = a'
		sc='a'
	endif

; zero data common
	if sc eq 'a' then begin
		common tha_455,tha_455_ind,tha_455_dat & tha_455_dat=0 & tha_455_ind=-1l
	endif else if sc eq 'b' then begin
		common thb_455,thb_455_ind,thb_455_dat & thb_455_dat=0 & thb_455_ind=-1l
	endif else if sc eq 'c' then begin
		common thc_455,thc_455_ind,thc_455_dat & thc_455_dat=0 & thc_455_ind=-1l
	endif else if sc eq 'd' then begin
		common thd_455,thd_455_ind,thd_455_dat & thd_455_dat=0 & thd_455_ind=-1l
	endif else if sc eq 'e' then begin
		common the_455,the_455_ind,the_455_dat & the_455_dat=0 & the_455_ind=-1l
	endif else if sc eq 'f' then begin
		common thf_455,thf_455_ind,thf_455_dat & thf_455_dat=0 & thf_455_ind=-1l
	endif

	if not keyword_set(themishome) then themishome=!themis.local_data_dir

; get filenames if file keyword not set
	if not keyword_set(file) then begin
		tt=timerange(trange)
		t1=time_double(strmid(time_string(tt(0)),0,10))
		t2=time_double(strmid(time_string(tt(1)-1.),0,10))
		ndays=1+fix((t2-t1)/(24.*3600.))
;		print,ndays
		file=strarr(ndays)
		i=0
		while t1 le t2 do begin
			ts=time_string(t1)
			yr=strmid(ts,0,4)
			mo=strmid(ts,5,2)
			da=strmid(ts,8,2)
			if i eq 0 then yrmoda1=yr+mo+da
			yrmoda2=yr+mo+da
			dir=themishome+'th'+sc+'/l0/'+yr+'/'+mo+'/'+da+'/' 
			name='th'+sc+'_l0_455_'+yr+mo+da+'.pkt'
			file[i]=dir+name
			i=i+1
			t1=t1+24.*3600.
		endwhile
	endif

; check that files exist
	nfiles=n_elements(file)
	if nfiles eq 1 then begin
		if not file_test(file) then begin
			dprint, file+' --- does not exist.'
			return 
		endif
	endif else begin 
		ind=-1
		for i=0,nfiles-1 do begin
			if file_test(file[i]) then ind=[ind,i] else dprint, file[i]+' --- does not exist.'
		endfor
		n_ind=n_elements(ind)
		if n_ind eq 1 then return else begin
			ind=ind[1:n_ind-1]
			file=file[ind]
		endelse 
	endelse	

; decompression array
	decompress=1.*[indgen(16),16+2*indgen(8),32+4*indgen(24),128+8*indgen(16),256+16*indgen(16),$
	512+32*indgen(16),1024+64*indgen(16),2048+128*indgen(48),8192+256*indgen(32),$
	16384+512*indgen(32),32768+1024*indgen(32)]

; define mode decoder
	n_modes=9				; number of modes
	mode_decode=intarr(256,256)		; decode array
	mode_decode[*,*]=-1
	mode_decode[0,0]=0			;  1A x 16E, snapshot, 1 spin 
	mode_decode[1,1]=1			;  1A x 32E, snapshot, 1 spin
	mode_decode[2,1]=2			; 50A x 24E, snapshot, 1 spin
	mode_decode[3,2]=3			;  1A x 16E, snapshot, 1 spin
	mode_decode[4,2]=4			; 72A x 16E, snapshot, 1 spin
	mode_decode[1,3]=5			;  1A x 32E, snapshot, 1 spin
	mode_decode[5,3]=6			; 50A x 24E, snapshot, 1 spin
	mode_decode[6,1]=7			;  6A x 32E, snapshot, 1 spin
	mode_decode[7,2]=8			;  6A x 16E, snapshot, 1 spin
  ;magnetospheric slow/fast modes, low E - added 2016-03-18
  mode_decode[1,4]=9      ;  1A x 32E, snapshot, 1 spin
  mode_decode[2,4]=10     ; 50A x 24E, snapshot, 1 spin

; define mode variables for different modes
	nspins = [1,1,1,1,1,1,1,1,1,1,1]					; # of spins between measurements in mode
	nenergy = [16,32,24,16,16,32,24,32,16,32,24]				; # of energies in mode
	nangle = [1,1,50,1,72,1,50,6,6,1,50]					; # of angles in mode
	dat_len = nenergy*nangle					; size data arrays
	spin_decode  = [160,96,3,192,3,96,3,20,38,96,3]			; # measurements in packet
	case_decode  = [0,1,5,0,4,1,5,3,2,1,5]				; datl[16,32,96,192,1152,1200]==>size[0,1,2,3,4,5]
	angle_decode = [0,1,2,3,5,1,4,6,7,1,2]				; angle mode index
	energy_decode = [0,1,2,3,3,4,5,1,3,6,7]				; energy mode index
	
; initialize arrays
	ndays=n_elements(file)
	nmax=40000l*ndays
	dat_0=bytarr(nmax,16) 
	dat_1=bytarr(nmax,32) 
	dat_2=bytarr(nmax,96) 
	dat_3=bytarr(nmax,192) 
	dat_4=bytarr(nmax,1152) 
	dat_5=bytarr(nmax,1200) 
	n_case=lonarr(6) & n_case[*]=0
	config1=bytarr(nmax) 
	config2=bytarr(nmax) 
	an_ind = intarr(nmax)
	en_ind = intarr(nmax)
	md_ind = intarr(nmax)
	cs_ind = intarr(nmax)
	cs_ptr = lonarr(nmax)
	s_time = dblarr(nmax)
	e_time = dblarr(nmax)
	data_size=0l

; get the files
	tm1=systime(1)
	dprint, dlevel=2, 'Downloading data'
	if n_elements(file) eq 1 then openr,fp,file,/get_lun else openr,fp,file[0],/get_lun
	fs = fstat(fp)
;	printdat,fs
	if fs.size ne 0 then begin
		adat = bytarr(fs.size) 
		data_size=fs.size*1l
		readu,fp,adat
		free_lun,fp
	endif
	if n_elements(file) ne 1 then begin
		nfile=n_elements(file)
		for i=1,nfile-1 do begin
			openr,fp,file[i],/get_lun
			fs = fstat(fp)
;			printdat,fs
			if fs.size ne 0 then begin
				adat2 = bytarr(fs.size)
				readu,fp,adat2
				if data_size ne 0 then adat=[adat,adat2] else adat=adat2
				data_size=data_size+fs.size
				free_lun,fp
			endif
		endfor
	endif
	tm2=systime(1)
	dprint, dlevel=2, 'Data download complete'
	dprint, dlevel=4, '455 Download time= ',tm2-tm1
	if data_size eq 0 then return

; Calculate spin period using header times the 3rd and 4th packets, assume spin period does not change within data

	hdrl=16								; header length
	pntr=0l
	pktl=0l
	npkt=0l
	ntot=0l
	tf_spin=1
	last_spin_period=0.
	i=0

while (tf_spin and i lt 100 and pntr+hdrl+pktl lt data_size and data_size gt 4000) do begin
	i=i+1
;	print,tf_spin,i
	hdr  = adat[pntr:pntr+hdrl-1]
	time = (1.d*((hdr[6]*256ul+hdr[7])*256ul+hdr[8])*256ul+hdr[9])+(hdr[10]+hdr[11]/256.d)/256.
	pktl = hdr[4]*256+hdr[5]+7-hdrl
	config = [adat[pntr+hdrl],adat[pntr+hdrl+1]]
;	print,'Config bytes = ',config
	mode=mode_decode[config[0],config[1]]
	pntr = pntr+pktl+hdrl
	hdr2 = adat[pntr:pntr+hdrl-1]
	time2 = (1.d*((hdr2[6]*256ul+hdr2[7])*256ul+hdr2[8])*256ul+hdr2[9])+(hdr2[10]+hdr2[11]/256.d)/256.
	pktl2 = hdr2[4]*256+hdr2[5]+7-hdrl
	configg = [adat[pntr+hdrl],adat[pntr+hdrl+1]]
	mode2 = mode_decode[configg[0],configg[1]]
	if pktl eq pktl2 then begin
		if mode eq mode2 and mode ne -1 then begin
			spin_period = (time2-time)/(nspins[mode]*spin_decode[mode])






			if spin_period lt 6. and spin_period gt 1.5 and abs(spin_period-last_spin_period) lt .005 then tf_spin=0 else last_spin_period=spin_period
		endif
	endif
;	print,pntr,'  ',pktl,'  ',time_to_str(time),'  ',adat[pntr+hdrl],'  ',adat[pntr+hdrl+1],'  spin period= ',spin_period
endwhile

;	if tf_spin then print,'ERROR : spin period calculation error, setting spin period to 3. seconds'
	if tf_spin then spin_period=3.
	dprint, dlevel=4, 'spin_period = ',spin_period
	last_spin_period = spin_period

	tm1=systime(1)

;; Load spin data
;	spinmodel=thm_load_spinmodel(sc=sc,themishome=themishome,available=spindata)


  ; 2012-10-16
  ; Load spin model
  ; Support data should already be loaded at this point
  ;-------------------------------------
  model = spinmodel_get_ptr(sc, use_eclipse_corrections=use_eclipse_corrections)
  if ~obj_valid(model) then begin
    dprint, dlevel=2, 'Using default spin period: '+strtrim(spin_period,2)+' sec'
  endif



; Start decommutation 

;	help,adat
	dprint, dlevel=4, 'Decommutating data ...  Data volume (bytes) =',data_size
;	print,'Current data	pktl	time				config bytes '

; initialize variables
t0=time_double('2001-1-1/0')
	pntr=0l
	pktl=0l
	npkt=0l
	ntot=0l
	hdr  = adat[pntr:pntr+hdrl-1]
	last_apid_cntr= hdr[3]
	last_time = (1.d*((hdr[6]*256ul+hdr[7])*256ul+hdr[8])*256ul+hdr[9])+(hdr[10]+hdr[11]/256.d)/256.




while pntr+1 lt data_size do begin
	hdr  = adat[pntr:pntr+hdrl-1]
	apid_cntr= hdr[3]
	spin_num = hdr[15]
	
	time = (1.d*((hdr[6]*256ul+hdr[7])*256ul+hdr[8])*256ul+hdr[9])+(hdr[10]+hdr[11]/256.d)/256.
	time2 = time
	
;	if spindata then begin
;		if n_elements(spinmodel.s_time) eq 1 then begin
;			spin_offset=long((time-spinmodel.s_time)/spinmodel.spin_period+.5d)
;			time2=spinmodel.s_time+spin_offset*spinmodel.spin_period
;			if time2 gt time then time2=time2-spinmodel.spin_period
;			spin_period=spinmodel.spin_period
;;			offset=2.37+(6./32.)*(spin_period-3.)
;;			if apid_cntr ne last_apid_cntr then   print,'ERROR: peir apid counter discontinuity                            : '$
;;				,time2-time,-1.*offset,apid_cntr,last_apid_cntr,' th'+sc,' ',time_string(last_time+t0),' '$
;;				,time_string(time+t0),' ',spinmodel.spin_period,' ',pntr
;;			if abs(time2-time+offset) gt .15 then print,'ERROR: peir Header time differs from spin model spin-start time by: '$
;;				,time2-time,-1.*offset,apid_cntr,last_apid_cntr,' th'+sc,' ',time_string(last_time+t0),' '$
;;				,time_string(time+t0),' ',spinmodel.spin_period,' ',pntr
;;			print,spinmodel.s_time,time2,time,time2-time
;		endif else begin
;			mintm=min(abs(spinmodel.s_time-time),ind)
;			if spinmodel.s_time(ind) gt time and ind ne 0 then ind=ind-1
;			spin_offset=long((time-spinmodel.s_time(ind))/spinmodel.spin_period(ind)+.5d)
;			time2=spinmodel.s_time(ind)+spin_offset*spinmodel.spin_period(ind)
;			if time2 gt time then time2=time2-spinmodel.spin_period(ind)
;			spin_period=spinmodel.spin_period(ind)
;;			offset=2.37+(6./32.)*(spin_period-3.)
;;			if apid_cntr ne last_apid_cntr then   print,'ERROR: peir apid counter discontinuity                            : '$
;;				,time2-time,-1.*offset,apid_cntr,last_apid_cntr,' th'+sc,' ',time_string(last_time+t0),' '$
;;				,time_string(time+t0),' ',spinmodel.spin_period(ind),' ',pntr
;;			if abs(time2-time+offset) gt .15 then print,'ERROR: peir Header time differs from spin model spin-start time by: '$
;;				,time2-time,-1.*offset,apid_cntr,last_apid_cntr,' th'+sc,' ',time_string(last_time+t0),' '$
;;				,time_string(time+t0),' ',spinmodel.spin_period(ind),' ',pntr
;;			print,spinmodel.s_time(ind),time2,time,time2-time
;		endelse
;	endif


  ;;2012-10-16
  ;;If spin model is present:
  ;; -get spin period
  ;; -set adjusted time to be at the begining of the most recent spin
  if obj_valid(model) then begin
    thm_esa_spin_adjust, model=model, time=time, adjusted_time=time2, $
                         spin_period=spin_period
  endif


	pktl = hdr[4]*256+hdr[5]+7-hdrl
	pktp = 0l & datl=0
	pkt  = adat[pntr+hdrl:pntr+hdrl+pktl-1]
	sub_spin=0
	last_mode=mode_decode[pkt[0],pkt[1]]
	last_apid_cntr= byte(apid_cntr+1)
mode_change=0



	while pktp+4 lt pktl do begin

		config_1 = pkt[pktp] & config_2 = pkt[pktp+1]
		mode = mode_decode[config_1,config_2]
		if mode ne -1 then datl = dat_len[mode]
		if mode ne -1 and pktp+datl+4 le pktl then begin
;			datl = dat_len[mode]
			navg = pkt[pktp+3]
			nsp = nspins[mode]
			config1[ntot] = config_1
			config2[ntot] = config_2
			an_ind[ntot] = angle_decode[mode]
			en_ind[ntot] = energy_decode[mode]
			md_ind[ntot] = mode
			nc = case_decode[mode]
			cs_ind[ntot] = nc
			cs_ptr[ntot] = n_case[nc]

			if mode ne last_mode and pntr+pktl+hdrl+hdrl-1 lt data_size and mode_change ne 1 then begin
				hdr  = adat[pntr+pktl+hdrl:pntr+pktl+hdrl+hdrl-1]
;				print,fix((time-last_time)/spin_period+.5),spin_num,hdr[15]
				mode_change=1
				next_time = (1.d*((hdr[6]*256ul+hdr[7])*256ul+hdr[8])*256ul+hdr[9])+(hdr[10]+hdr[11]/256.d)/256.
				n_rem = (pktl - pktp)/(datl+4)
				if n_rem*(datl+4) ne (pktl-pktp) then n_rem=n_rem+1 
				rem_spin = fix((next_time-time)/spin_period+.5) - n_rem*nsp
;				time0 = time_double('1900-1-1')		
;				if next_time lt 3.e9 then time0 = time_double('2001-1-1')		; if 2001 epoch used
;				print,'Mode change in packet: ',time_string(next_time+time0),mode,last_spin,rem_spin, n_rem,pktl,pktp $
;					,datl,nsp,(1.*pktl-pktp)/(datl+4),fix((next_time-time)/spin_period+.5)
				sub_spin=rem_spin>sub_spin
;				print,'sub_spin = ',sub_spin
			endif

			s_time[ntot] = time2 + spin_period*(sub_spin-1)
			e_time[ntot] = time2 + spin_period*(sub_spin+navg)			

			tmp=reform(pkt[pktp+4:pktp+4+datl-1],1,datl)
			case nc of
				0: dat_0[n_case[nc],*]=tmp
				1: dat_1[n_case[nc],*]=tmp
				2: dat_2[n_case[nc],*]=tmp
				3: dat_3[n_case[nc],*]=tmp
				4: dat_4[n_case[nc],*]=tmp
				5: dat_5[n_case[nc],*]=tmp
			endcase
			ntot = ntot + 1
			n_case[nc] = n_case[nc] + 1

		endif else begin
;			print,'Error: Invalid ESA config header bytes - skipping packet'
;			print,mode,config_1,config_2,pntr,pktl,pktp,datl,pktp+datl+4
			datl=0 & nsp=1
			pktp = pktl
		endelse

		pktp = pktp + 4 + datl
		last_spin = sub_spin
		sub_spin = sub_spin + nsp
		last_mode = mode	
;		if ntot-1000l*ceil(ntot/1000l) eq 0 then print,pntr,'  ',pktl,'  ',time_string(time),'  ',adat[pntr+hdrl],'  ',adat[pntr+hdrl+1]
	endwhile
	pntr = pntr + pktl + hdrl
;	print,pntr,'  ',ntot
	last_time=time

endwhile

	tm2=systime(1)
	dprint, dlevel=4, '455 Decommutation time= ',tm2-tm1
	if ntot eq 0 then return

; Get rid of extra elements in arrays

	config1 = config1[0:ntot-1]
	config2 = config2[0:ntot-1]
	an_ind = an_ind[0:ntot-1]
	en_ind = en_ind[0:ntot-1]
	md_ind = md_ind[0:ntot-1]
	cs_ind = cs_ind[0:ntot-1]
	cs_ptr = cs_ptr[0:ntot-1]
	s_time = s_time[0:ntot-1]
	e_time = e_time[0:ntot-1]	

	if n_case[0] gt 0 then dat_0=dat_0[0:n_case[0]-1,*] else dat_0=dat_0[0,*]		
	if n_case[1] gt 0 then dat_1=dat_1[0:n_case[1]-1,*] else dat_1=dat_1[0,*]			
	if n_case[2] gt 0 then dat_2=dat_2[0:n_case[2]-1,*] else dat_2=dat_2[0,*]			
	if n_case[3] gt 0 then dat_3=dat_3[0:n_case[3]-1,*] else dat_3=dat_3[0,*]			
	if n_case[4] gt 0 then dat_4=dat_4[0:n_case[4]-1,*] else dat_4=dat_4[0,*]			
	if n_case[5] gt 0 then dat_5=dat_5[0:n_case[5]-1,*] else dat_5=dat_5[0,*]			


  ; Get eclipse delta phi from spin model for each sample time
  ; If the model is not available the field will be filled with NaNs
  if obj_valid(model) then begin
    thm_esa_spin_adjust, model=model, time=s_time, eclipse_dphi=eclipse_dphi
  endif else begin
    eclipse_dphi = replicate(!values.d_nan,size(s_time,/dim))
  endelse


; shift the time to unix time
	time0 = time_double('1900-1-1')		
	if s_time[ntot-1 < 5] lt 3.e9 then time0 = time_double('2001-1-1')		; if 2001 epoch used
	s_time = s_time + time0 
	e_time = e_time + time0


;***********************************************************************************
; may want to fix this section
	valid=bytarr(ntot) & valid[*]=1
;	ind=where(s_time gt e_time),count)
;	if count gt 0 then valid[ind]=0

;***********************************************************************************
;Energy mode determination 

case sc of
	'a': fm=1
	'b': fm=2
	'c': fm=5
	'd': fm=4
	'e': fm=3
	'f': fm=6
endcase

emode=thm_read_esa_sweep_reduced_mode(fm)

energy=emode.i_energy
denergy=emode.i_denergy
nenergy=emode.i_nenergy

;***********************************************************************************
; Calibration: geometric factor and deadtime and efficiency

calib=get_thm_esa_cal(sc=sc,ion=1,time=s_time)

geom_factor=calib.geom_factor				; geom_factor of 22.5x22.5 angle bin
an_eff = calib.an_eff
rel_gf = calib.rel_gf

deadtime=1.7e-7

; Make ion energy efficiency array 
; 	REF: Funsten curves for CEMs, assumes 2 kV pre-acceleration

en_eff=(1.+0.3*((energy+2000.)/30000.)^.5)/1.075

; empirical correction from derived from sheath ion/electron density comparison
; 	was used until 08-07-11: corr=0.85+.35*exp(-energy/400.) & en_eff=en_eff*corr
  corr=1. 						;default
  corr1=1. & corr2=1.					;default
;  corr=0.85+.35*exp(-energy/400.)			;due to leakage fields into ESA
;  corr=0.95+.95*exp(-energy/40.)			;due to leakage fields into ESA
;  corr=.905*(1.+.55*exp(-energy/180.))			;due to leakage fields into ESA
;  corr=.91*(1.+.41*((1.-alog(energy)/7.)>0.))		;due to leakage fields into ESA
  lf=2./3.
;  lf=1.

;guard against 0 energy, jmm, 2016-03-30, chaned lower limit to 0.1
;ev, on advice from J.McFadden, 2016-04-01
  energy_n0 = energy > 0.1
  corr=.91*(1.+.32*(1.-alog(lf*energy_n0)/8.9)*exp(-lf*energy_n0/350.) + .05*(1.-alog(lf*energy_n0)/12.))	;due to leakage fields into ESA
  corr1=   (1.+.10*((1.-alog(energy_n0/.25)/7.8)>0.))	;due to ESA exit grid 
  corr2=   (1.+.05*((1.-alog(energy_n0/1.5)/7.8)>0.))	;due to MCP grid 

en_eff=en_eff*corr*corr1*corr2

;***********************************************************************************

amode=thm_read_iesa_angle_reduced_mode() 

nbins=amode.i_nbins
theta=amode.i_theta
dtheta=amode.i_dtheta
phi=amode.i_phi
dphi=amode.i_dphi
domega=amode.i_domega
nrg_wt=amode.i_nrg_wt
anodes=amode.i_anodes
an_map=amode.i_an_map

;***********************************************************************************
; to get magnetometer data, use thm_load_esa_mag.pro

	magf=fltarr(ntot,3)	& magf[*]=!values.f_nan

;***********************************************************************************
; gf, dt_arr, dt

	dt_arr=(dphi/11.25)*anodes*nrg_wt
	gf=dphi/22.5*dtheta/22.5*nrg_wt
	dt=e_time-s_time

;***********************************************************************************
; to load background data, use thm_load_pei_bkg.pro
;   bkg, bkg_pse, bkg_pei are the time dependent background counts for the entire analyzer in 1/32 of a spin 
;	bkg is roughly the MCP rate per cm^2-s 
;   	bkg_pse is an eSST determined background
;   	bkg_pei is an iESA determined background
;   	bkg is generally the smaller of bkg_pse, bkg_pei -- see keywords in thm_load_pei_bkg.pro
;   an_bkg - relative bkg per anode - determined from sc='e' on 08-01-16, 
;	an_bkg should probably be a function of sc and perhaps of time
;   bkg_arr is the relative background per energy-angle bin
;   	background arrays are constructed as: bkg*bkg_arr

	bkg_pse=fltarr(ntot) 	& bkg_pse[*]=!values.f_nan
	bkg_pei=fltarr(ntot) 	& bkg_pei[*]=!values.f_nan
	bkg=fltarr(ntot) 	& bkg[*]=0.
	an_bkg = [1.32653,1.12855,0.759310,0.658778,0.689404,0.764592,1.17875,1.49409]
	mapdim = size(an_map)
	maxbins = mapdim[2]
	nummaps = mapdim[3]
	tmparr = fltarr(maxbins,nummaps)
	for i=0,nummaps-1 do tmparr[*,i] =total((an_bkg#replicate(1.,maxbins))*an_map[*,*,i],1)
	bkg_arr = reform(replicate(1.,32)#reform(tmparr,maxbins*nummaps),32,maxbins,nummaps)
	bkg_arr = bkg_arr*gf/128.

;***********************************************************************************
; Make 3D data structures
; Note: sc_pot, b_gse, magf, rot, phi_offset - are to be added later


ird_dat = 	{project_name:		'THEMIS',				$
		spacecraft:		sc, 					$
		data_name:		'IESA 3D Reduced', 			$
		apid:			'455'x,					$
		units_name: 		'compressed', 				$
		units_procedure: 	'thm_convert_esa_units', 		$
		valid: 			valid, 					$

		time:			s_time,					$
		end_time:		e_time,					$
		delta_t:		dt,					$
		integ_t: 		dt/1024.,				$
		dt_arr: 		dt_arr,					$

		cs_ptr:			cs_ptr,					$
		cs_ind:			cs_ind,					$
		config1:		config1,				$
		config2:		config2,				$
		an_ind:			an_ind,					$
		en_ind:			en_ind,					$
		md_ind:			md_ind,					$

		nenergy: 		nenergy, 				$
		energy: 		energy, 				$
		denergy: 		denergy, 				$
;		eff: 			en_eff,	 				$

		nbins: 			nbins, 					$
		theta: 			theta,  				$
		dtheta: 		dtheta,  				$
		phi: 			phi,  					$
		dphi: 			dphi,  					$
		phi_offset: 		replicate(0.,ntot),  			$
		domega: 		domega,  				$
		gf: 			gf, 					$
		an_map: 		an_map,					$

    eclipse_dphi:    eclipse_dphi,    $

		rel_gf: 		rel_gf,					$
		an_eff: 		an_eff,					$
		en_eff: 		en_eff,					$
		geom_factor: 		geom_factor,				$
		dead: 			deadtime,				$

		mass: 			1.0438871e-02, 				$
		charge: 		1., 					$
		sc_pot: 		replicate(0.,ntot),			$

		magf:	 		magf, 					$

		bkg_pse:	 	bkg_pse, 				$
		bkg_pei:	 	bkg_pei, 				$
		bkg:	 		bkg, 					$
		bkg_arr:		bkg_arr,				$

		dat0:			dat_0,					$
		dat1:			dat_1,					$
		dat2:			dat_2,					$
		dat3:			dat_3,					$
		dat4:			dat_4,					$
		dat5:			dat_5}


if sc eq 'a' then begin
	common tha_455,tha_455_ind,tha_455_dat & tha_455_dat=ird_dat & tha_455_ind=0l
endif else if sc eq 'b' then begin
	common thb_455,thb_455_ind,thb_455_dat & thb_455_dat=ird_dat & thb_455_ind=0l
endif else if sc eq 'c' then begin
	common thc_455,thc_455_ind,thc_455_dat & thc_455_dat=ird_dat & thc_455_ind=0l
endif else if sc eq 'd' then begin
	common thd_455,thd_455_ind,thd_455_dat & thd_455_dat=ird_dat & thd_455_ind=0l
endif else if sc eq 'e' then begin
	common the_455,the_455_ind,the_455_dat & the_455_dat=ird_dat & the_455_ind=0l
endif else if sc eq 'f' then begin
	common thf_455,thf_455_ind,thf_455_dat & thf_455_dat=ird_dat & thf_455_ind=0l
endif


;store time range & eclipse correction status
eclipse = undefined(use_eclipse_corrections) ? 0:use_eclipse_corrections
thm_part_trange, sc, 'peir', set={trange:timerange(trange),eclipse:eclipse}


; help,ird_dat,/st
dprint, dlevel=4, 'Data loading complete: th'+sc+' peir - apid 455'

;***********************************************************************************
; Make tplot structures

cols=get_colors()

en_dat=fltarr(ntot,32)
energy=fltarr(ntot,32)

for i=0l,ntot-1l do begin
;	print,ntot,i,cs_ptr[i],cs_ind[i]
	case cs_ind[i] of
		0: en_dat[i,0:15]=reform(decompress[ird_dat.dat0[cs_ptr[i],*]])
		1: en_dat[i,0:31]=reform(decompress[ird_dat.dat1[cs_ptr[i],*]])
		2: en_dat[i,0:15]=total(reform(decompress[ird_dat.dat2[cs_ptr[i],*]],6,16),1)
		3: en_dat[i,0:31]=total(reform(decompress[ird_dat.dat3[cs_ptr[i],*]],6,32),1)
		4: en_dat[i,0:15]=total(reform(decompress[ird_dat.dat4[cs_ptr[i],*]],72,16),1)
		5: en_dat[i,0:23]=total(reform(decompress[ird_dat.dat5[cs_ptr[i],*]],50,24),1)
	endcase
	energy(i,*)=reform(ird_dat.energy[*,en_ind[i]])
endfor

if not keyword_set(gap_time) then gap_time=10.
if ntot gt 1 then begin
ind=where(s_time[1:ntot-1]-s_time[0:ntot-2] gt gap_time,n_ind)
if n_ind gt 0 then begin
	en_dat[ind,*]=!values.f_nan
	en_dat[ind+1,*]=!values.f_nan
endif
endif

name1='th'+sc+'_peir_en_counts'+suffix
store_data,name1,data={x:(ird_dat.time+ird_dat.end_time)/2.,y:en_dat,v:energy}
	zlim,name1,0,0,1,/def
	ylim,name1,3.,40000.,1,/def
	options,name1,'ztitle','Counts',/def
	options,name1,'ytitle','i+ th'+sc+'!C!C eV',/def
	options,name1,'spec',1,/def
	options,name1,'x_no_interp',1,/def
	options,name1,'y_no_interp',1,/def

name1='th'+sc+'_peir_mode'+suffix
store_data,name1,data={x:(s_time+e_time)/2.,y:[[config1-.1],[config2+.1],[md_ind]]}
	ylim,name1,-1,10,0,/def
	options,name1,'ytitle','i+ th'+sc+'!C!C mode',/def
	options,name1,'colors',[cols.red,cols.green,cols.blue],/def
	options,name1,labels=['config1', 'config2', 'mode'],constant=0.,/def
	options,name1,'labflag',3,/def
	options,name1,'labpos',[0,3,6],/def

;***********************************************************************************

end
