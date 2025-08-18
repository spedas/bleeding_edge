;+
;PROCEDURE:	thm_load_peer
;PURPOSE:	
;	Decommutates the raw THEMIS electron esa reduced data packets, (peer - apid 458), and puts data structure in a common for access by get_th*_peer.pro and generates tplot energy spectrogram
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
;
;NOTES:
;	
;-

pro thm_load_peer,file=file,sc=sc,themishome=themishome, $
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
		common tha_458,tha_458_ind,tha_458_dat & tha_458_dat=0 & tha_458_ind=-1l
	endif else if sc eq 'b' then begin
		common thb_458,thb_458_ind,thb_458_dat & thb_458_dat=0 & thb_458_ind=-1l
	endif else if sc eq 'c' then begin
		common thc_458,thc_458_ind,thc_458_dat & thc_458_dat=0 & thc_458_ind=-1l
	endif else if sc eq 'd' then begin
		common thd_458,thd_458_ind,thd_458_dat & thd_458_dat=0 & thd_458_ind=-1l
	endif else if sc eq 'e' then begin
		common the_458,the_458_ind,the_458_dat & the_458_dat=0 & the_458_ind=-1l
	endif else if sc eq 'f' then begin
		common thf_458,thf_458_ind,thf_458_dat & thf_458_dat=0 & thf_458_ind=-1l
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
			name='th'+sc+'_l0_458_'+yr+mo+da+'.pkt'
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
;	n_modes=5				; number of modes (not used as of 2014-03-26 JWL)
	mode_decode=intarr(256,256)		; decode array
	mode_decode[*,*]=-1
	mode_decode[0,0]=0			;  1A x 16E, snapshot, 1 spin 
	mode_decode[1,1]=1			;  1A x 32E, snapshot, 1 spin
	mode_decode[2,1]=2			;  6A x 32E, snapshot, 1 spin
	mode_decode[1,2]=3			;  1A x 32E, snapshot, 1 spin
	mode_decode[2,2]=4			;  6A x 32E, snapshot, 1 spin
	mode_decode[3,1]=5			;  1A x 32E, snapshot, 1 spin
  ;magnetospheric slow/fast modes with reduced energy map - added ????-??-??
  mode_decode[1,4]=6      ;  1A x 32E, snapshot, 1 spin
  mode_decode[2,4]=7      ;  6A x 32E, snapshot, 1 spin
  ;Another low-energy magnetospheric mode 0x0304  JWL 2013-07-24
  mode_decode[3,4]=8      ;  1A x 32E, snapshot, 1 spin
  ;Revised low-energy magnetospheric modes 0x0105, 0x0205
  mode_decode[1,5]=9      ;  1A x 32E, snapshot, 1 spin
  mode_decode[2,5]=10     ;  6A x 32E, snapshot, 1 spin
  ;magnetospheric slow/fast modes, low E - added 2016-03-18
  mode_decode[1,6]=11     ;  1A x 32E, snapshot, 1 spin
  mode_decode[2,6]=12     ;  6A x 32E, snapshot, 1 spin



; define mode variables for different modes
	nspins = [1,1,1,1,1,1,1,1,1,1,1,1,1]               ; # of spins between measurements in mode
	nenergy = [16,32,32,32,32,32,32,32,32,32,32,32,32]      ; # of energies in mode
	nangle = [1,1,6,1,6,1,1,6,1,1,1,1,6]               ; # of angles in mode
	dat_len = nenergy*nangle                 ; size data arrays
	spin_decode  = [160,96,16,96,16,96,96,16,96,96,96,96,16]; # measurements in packet
	case_decode  = [0,1,3,1,3,1,1,3,1,1,1,1,3]         ; datl[16,32,96,192]==>size[0,1,2,3]
	angle_decode = [0,1,2,1,2,1,1,2,1,1,1,1,2]         ; angle mode index
	energy_decode = [0,1,1,2,2,1,3,3,3,4,4,5,5]        ; energy mode index


; initialize arrays
	ndays=n_elements(file)
	nmax=40000l*ndays
	dat_0=bytarr(nmax,16) 
	dat_1=bytarr(nmax,32) 
	dat_2=bytarr(nmax,96) 
	dat_3=bytarr(nmax,192) 


	n_case=lonarr(4) & n_case[*]=0		; # elements in n_case is number of dat_? arrays
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
	dprint, dlevel=4, '458 Download time= ',tm2-tm1
	if data_size eq 0 then return


; Calculate spin period using header times the 3rd and 4th packets, 
; assume spin period does not change within data.
;; This spin period will be used if spin model data is not present.
;-----------------------------------------
	hdrl=16								; header length
	pntr=0l
	pktl=0l
	npkt=0l
	ntot=0l
	tf_spin=1  ;;track if spin period has been successfully determined
	last_spin_period=0.
	i=0

while (tf_spin and i lt 100 and pntr+hdrl+pktl lt data_size and data_size gt 4000) do begin

	i=i+1
;	print,tf_spin,i

	hdr  = adat[pntr:pntr+hdrl-1]       ;;header
	time = (1.d*((hdr[6]*256ul+hdr[7])*256ul+hdr[8])*256ul+hdr[9])+(hdr[10]+hdr[11]/256.d)/256.
	pktl = hdr[4]*256+hdr[5]+7-hdrl     ;;packet length
	config = [adat[pntr+hdrl],adat[pntr+hdrl+1]]   ;;get index into mode table
	mode=mode_decode[config[0],config[1]]          ;;get mode from table
	
	pntr = pntr+pktl+hdrl               ;;increment to next packet
	hdr2 = adat[pntr:pntr+hdrl-1]
	time2 = (1.d*((hdr2[6]*256ul+hdr2[7])*256ul+hdr2[8])*256ul+hdr2[9])+(hdr2[10]+hdr2[11]/256.d)/256.
	pktl2 = hdr2[4]*256+hdr2[5]+7-hdrl
	configg = [adat[pntr+hdrl],adat[pntr+hdrl+1]]
	mode2 = mode_decode[configg[0],configg[1]]
	
	;;calculate spin period
	;;if successful the loop will be exited
	if pktl eq pktl2 then begin  
		if mode eq mode2 and mode ne -1 then begin

		  ;; dt/(n_spins * n_measurements/packet), n_spins always 1 
			spin_period = (time2-time)/(nspins[mode]*spin_decode[mode]) 
			
			if spin_period lt 6. and spin_period gt 1.5 $
			  and abs(spin_period-last_spin_period) lt .005 $
			    then tf_spin=0 $                  ;;spin per in (1.5,6) & close to previous
			    else last_spin_period=spin_period ;;spin per outside range, different from last, or first run

		endif
	endif
	
;	print,pntr,'  ',pktl,'  ',time_to_str(time),'  ',adat[pntr+hdrl],'  ',adat[pntr+hdrl+1],'  spin period= ',spin_period
endwhile


;	if tf_spin then print,'ERROR : spin period calculation error, setting spin period to 3. seconds'

	
	;; If spin period was never in (1.5,6) or varied >.005 from previous each time
	;; or while loop only ran once then the spin period is set to 3.
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
	model = spinmodel_get_ptr(sc,use_eclipse_corrections=use_eclipse_corrections)
  if ~obj_valid(model) then begin
    dprint, dlevel=2, 'Using default spin period: '+strtrim(spin_period,2)+' sec'
  endif



; Start decommutation 
;-----------------------------------------
;	help,adat
	dprint, dlevel=4, 'Decommutating data ...  Data volume (bytes) =',data_size
;	print,'Current data	pktl	time				config bytes '

; initialize variables
  t0=time_double('2001-1-1/0')
	pntr=0l   ;;pointer to current location in file
	pktl=0l   ;;packet length
	npkt=0l   ;;number of packets?
	ntot=0l   ;;index into initialized data 
	hdr  = adat[pntr:pntr+hdrl-1]  ;;header
	last_apid_cntr= hdr[3]
	last_time = (1.d*((hdr[6]*256ul+hdr[7])*256ul+hdr[8])*256ul+hdr[9]) $  ;; ??
	             + (hdr[10]+hdr[11]/256.d)/256.


;;loop over packet file
while pntr+1 lt data_size do begin
	hdr  = adat[pntr:pntr+hdrl-1]   ;;get header for this packet
	apid_cntr= hdr[3]
	spin_num = hdr[15]              ;;n spins
	
  ;;get header time and copy to new var
	time = (1.d*((hdr[6]*256ul+hdr[7])*256ul+hdr[8])*256ul+hdr[9])+(hdr[10]+hdr[11]/256.d)/256.
	time2 = time

  ;;if spin model data is present:
  ;; -shift the copied time to be at the begining of the most recent spin
  ;; -set the spin period to that of the model
;	if spindata then begin
;	
;		if n_elements(spinmodel.s_time) eq 1 then begin
;		
;		  ;; rounded # full spins between time and spin_time
;			spin_offset = long((time-spinmodel.s_time)/spinmodel.spin_period+.5d)
;			;; spin_time + time taken for rounded # of spins
;			time2 = spinmodel.s_time + spin_offset * spinmodel.spin_period
;			;; subtract one spin from new time if original time exceeded
;			if time2 gt time then time2 = time2 - spinmodel.spin_period
;
;			spin_period = spinmodel.spin_period ;; set spin per
;			
;;			offset=2.00+(6./32.)*(spin_period-3.)
;;			if apid_cntr ne last_apid_cntr then   print,'ERROR: peer apid counter discontinuity                            : '$
;;				,time2-time,-1.*offset,apid_cntr,last_apid_cntr,' th'+sc,' ',time_string(last_time+t0),' '$
;;				,time_string(time+t0),' ',spinmodel.spin_period,' ',pntr
;;			if abs(time2-time+offset) gt .15 then print,'ERROR: peer Header time differs from spin model spin-start time by: '$
;;				,time2-time,-1.*offset,apid_cntr,last_apid_cntr,' th'+sc,' ',time_string(last_time+t0),' '$
;;				,time_string(time+t0),' ',spinmodel.spin_period,' ',pntr
;;			print,spinmodel.s_time,time2,time,time2-time
;
;		endif else begin
;		  
;		  ;; min dt between time and spin time
;			mintm = min(abs(spinmodel.s_time-time),ind)
;			;; use spin_time closest to but not exceeding time
;			if spinmodel.s_time[ind] gt time and ind ne 0 then ind = ind-1
;			
;			;; rounded # full spins between time and spin_time
;			spin_offset = long((time-spinmodel.s_time[ind])/spinmodel.spin_period[ind]+.5d)
;			;; spin_time + time taken for roudned # of spins
;			time2 = spinmodel.s_time[ind] + spin_offset * spinmodel.spin_period[ind]
;			;; subract one spin from new time if original time exceeded
;			if time2 gt time then time2 = time2-spinmodel.spin_period[ind]
;
;      spin_period = spinmodel.spin_period[ind] ;; set spin per
;      
;;     offset=2.00+(6./32.)*(spin_period-3.)
;;     if apid_cntr ne last_apid_cntr then   print,'ERROR: peer apid counter discontinuity                            : '$
;;       ,time2-time,-1.*offset,apid_cntr,last_apid_cntr,' th'+sc,' ',time_string(last_time+t0),' '$
;;       ,time_string(time+t0),' ',spinmodel.spin_period(ind),' ',pntr
;;     if abs(time2-time+offset) gt .15 then print,'ERROR: peer Header time differs from spin model spin-start time by: '$
;;       ,time2-time,-1.*offset,apid_cntr,last_apid_cntr,' th'+sc,' ',time_string(last_time+t0),' '$
;;       ,time_string(time+t0),' ',spinmodel.spin_period(ind),' ',pntr
;;     print,spinmodel.s_time(ind),time2,time,time2-time
;
;		endelse
;		
;	endif

	
  ;2012-10-16
  ;If spin model is present:
  ; -get spin period
  ; -set adjusted time to be at the begining of the most recent spin
	if obj_valid(model) then begin
    thm_esa_spin_adjust, model=model, time=time, adjusted_time=time2, $
                         spin_period=spin_period
	endif
	
	
	pktl = hdr[4]*256+hdr[5]+7-hdrl
	pktp = 0l
	datl = 0
	pkt  = adat[pntr+hdrl:pntr+hdrl+pktl-1]
	sub_spin=0
	last_mode=mode_decode[pkt[0],pkt[1]]
	last_apid_cntr= byte(apid_cntr+1)
	mode_change=0


  ;;loop over packet looking for valid samples
  ;;  -set start/end time for each measurement
  ;;  -check for mode change and add timing correction if found
  ;;    (this can only occur once through entire loop; all 
  ;;     remaining data in the packet will be corrected) 
	while pktp+4 lt pktl do begin

		config_1 = pkt[pktp]     ;; get first two bytes (config word)
		config_2 = pkt[pktp+1]   ;;
		mode = mode_decode[config_1,config_2]  ;;determine mode from config word
		
		if mode ne -1 then datl = dat_len[mode]  ;;get length of data portion
		
		if mode ne -1 and pktp+datl+4 le pktl then begin  ;skip if invalid or incomplete
		
;			datl = dat_len[mode]
			navg = pkt[pktp+3]        ;; # spins per measure from packet data
			nsp = nspins[mode]        ;; # spins per measure based on mode
			config1[ntot] = config_1  ;; config word
			config2[ntot] = config_2  ;;
			an_ind[ntot] = angle_decode[mode]   ;;angle mode index
			en_ind[ntot] = energy_decode[mode]  ;;energy mode index
			md_ind[ntot] = mode       ;;mode index
			nc = case_decode[mode]
			cs_ind[ntot] = nc
			cs_ptr[ntot] = n_case[nc]

      ;;check for mid-packet mode change, specifically check if:
      ;;  -current mode different from previous
      ;;  -next header in current file
      ;;  -first two conditions not previously met in this loop
      ;;   (i.e. code in this block gets hit once, at most, while looping over current packet)
			if mode ne last_mode and pntr+pktl+hdrl+hdrl-1 lt data_size and mode_change ne 1 then begin
				
				;;get next packet's header time
				hdr  = adat[pntr+pktl+hdrl:pntr+pktl+hdrl+hdrl-1]
;				print,fix((time-last_time)/spin_period+.5),spin_num,hdr[15]
        mode_change=1  ;;set flag
				next_time = (1.d*((hdr[6]*256ul+hdr[7])*256ul+hdr[8])*256ul+hdr[9])+(hdr[10]+hdr[11]/256.d)/256.
				
				;;get # of remaining samples in current packet
				n_rem = (pktl - pktp)/(datl+4)
				;;increment if remainder was truncated
				if n_rem*(datl+4) ne (pktl-pktp) then begin
				  n_rem=n_rem+1
				endif
				
				;;get # spins between initial header time and mode change: 
				;; rounded total spins in packet - whole # of spins to reach next packet from mode change
				rem_spin = fix((next_time-time)/spin_period+.5) - n_rem*nsp
				
				;;unneeded, set later
				time0 = time_double('1900-1-1')		
				if next_time lt 3.e9 then time0 = time_double('2001-1-1')		; if 2001 epoch used
;				print,'Mode change in packet: ',time_string(next_time+time0),mode,last_spin,rem_spin, n_rem,pktl,pktp $
;					,datl,nsp,(1.*pktl-pktp)/(datl+4),fix((next_time-time)/spin_period+.5)

        ;;select larger of:
        ;;  # spins encountered up to this point
        ;;  # total spins in packet - spins remaining after mode change (based on calculation above)
				sub_spin = rem_spin > sub_spin

;				print,'sub_spin = ',sub_spin
			endif

      ;;set sample start/end times for common block structure
      ;;  spin-model-corrected header time  +  spin period  *  rounded number of spins to current location
			s_time[ntot] = time2 + spin_period * (sub_spin-1) 
			e_time[ntot] = time2 + spin_period * (sub_spin+navg)

			tmp=reform(pkt[pktp+4:pktp+4+datl-1],1,datl)
			case nc of
				0: dat_0[n_case[nc],*]=tmp
				1: dat_1[n_case[nc],*]=tmp
				2: dat_2[n_case[nc],*]=tmp
				3: dat_3[n_case[nc],*]=tmp
			endcase
			
			ntot = ntot + 1  ;;increment data index
			n_case[nc] = n_case[nc] + 1

		endif else begin
			pktp = pktl
;			print,'Error: Invalid ESA config header bytes - skipping packet'
;			print,mode,config_1,config_2,pntr,pktl,pktp
			datl=0
			nsp=1
		endelse

		pktp = pktp + 4 + datl   ;;go to next sample
		 
		last_spin = sub_spin
		sub_spin = sub_spin + nsp
		last_mode = mode	

;		if ntot-1000l*ceil(ntot/1000l) eq 0 then print,pntr,'  ',pktl,'  ',time_string(time),'  ',adat[pntr+hdrl],'  ',adat[pntr+hdrl+1]

	endwhile ;;end loop over current packet
	
	pntr = pntr + pktl + hdrl   ;;increment main pointer
;	print,pntr,'  ',ntot
	last_time=time

endwhile ;;end loop over data file

	tm2=systime(1)
	dprint, dlevel=4, '458 Decommutation time= ',tm2-tm1
	
	if ntot eq 0 then return


; Get rid of extra elements in arrays
;-----------------------------------------
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
;-----------------------------------------
case sc of
	'a': fm=1
	'b': fm=2
	'c': fm=5
	'd': fm=4
	'e': fm=3
	'f': fm=6
endcase

emode=thm_read_esa_sweep_reduced_mode(fm)

energy=emode.e_energy
denergy=emode.e_denergy
nenergy=emode.e_nenergy

;***********************************************************************************
; Calibration: geometric factor and deadtime and efficiency

calib=get_thm_esa_cal(sc=sc,ion=0,time=s_time)

geom_factor=calib.geom_factor				; geom_factor of 22.5x22.5 angle bin
an_eff = calib.an_eff
rel_gf = calib.rel_gf
an_en_eff = calib.an_en_eff

deadtime=1.7e-7

; Make electron energy efficiency array 
; 	REF: Relative electron detection efficiency of microchannel plates from 0-3 keV
; 	R.R. Goruganthu and W. G. Wilson, Rev. Sci. Instrum. Vol. 55, No. 12 Dec 1984

	tmax = 2.283
	aa = 1.35
	delta_max = 1.0
	emax = 325.  ;eV
	en_acc = 450. ;eV for THEMIS
	delta = delta_max * ((energy+en_acc)/emax)^(1-aa)*(1-exp(-tmax*((energy+en_acc)/emax)^aa))/(1-exp(-tmax))
	k = 2.2
en_eff = (1-exp(-k*delta/delta_max))/(1-exp(-k))


;***********************************************************************************

amode=thm_read_eesa_angle_reduced_mode()

nbins=amode.e_nbins
theta=amode.e_theta
dtheta=amode.e_dtheta
phi=amode.e_phi
dphi=amode.e_dphi
domega=amode.e_domega
nrg_wt=amode.e_nrg_wt
anodes=amode.e_anodes
an_map=amode.e_an_map

;***********************************************************************************
; to get magnetometer data, use thm_load_esa_mag.pro

	magf=fltarr(ntot,3)	& magf[*]=!values.f_nan

;***********************************************************************************
; gf, dt_arr, dt

	dt_arr=(dphi/11.25)*anodes*nrg_wt
	gf=dphi/22.5*dtheta/22.5*nrg_wt
	dt=e_time-s_time

;***********************************************************************************
; to load background data, use thm_load_pee_bkg.pro
;   bkg, bkg_pse, bkg_pee are the time dependent background counts for the entire analyzer in 1/32 of a spin 
;	bkg is roughly the MCP rate per cm^2-s 
;   	bkg_pse is an eSST determined background
;   	bkg_pee is an eESA determined background
;   	bkg is generally the smaller of bkg_pse, bkg_pee -- see keywords in thm_load_pee_bkg.pro
;   an_bkg - relative bkg per anode - determined from sc='e' on 08-01-16, 
;	an_bkg should probably be a function of sc and perhaps of time
;   bkg_arr is the relative background per energy-angle bin
;   	background arrays are constructed as: bkg*bkg_arr

	bkg_pse=fltarr(ntot) 	& bkg_pse[*]=!values.f_nan
	bkg_pee=fltarr(ntot) 	& bkg_pee[*]=!values.f_nan
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


erd_dat = 	{project_name:		'THEMIS',				$
		spacecraft:		sc, 					$
		data_name:		'EESA 3D Reduced', 			$
		apid:			'458'x,					$
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
		an_en_eff: 		an_en_eff,				$
		geom_factor: 		geom_factor,				$
		dead: 			deadtime,				$

		mass: 			5.68566e-06, 				$
		charge: 		-1., 					$
		sc_pot: 		replicate(0.,ntot),			$

		magf:	 		magf, 					$

		bkg_pse:	 	bkg_pse, 				$
		bkg_pei:	 	bkg_pee, 				$
		bkg_pee:	 	bkg_pee, 				$
		bkg:	 		bkg, 					$
		bkg_arr:		bkg_arr,				$

		dat0:			dat_0,					$
		dat1:			dat_1,					$
		dat2:			dat_2,					$
		dat3:			dat_3}




if sc eq 'a' then begin
	common tha_458,tha_458_ind,tha_458_dat & tha_458_dat=erd_dat & tha_458_ind=0l
endif else if sc eq 'b' then begin
	common thb_458,thb_458_ind,thb_458_dat & thb_458_dat=erd_dat & thb_458_ind=0l
endif else if sc eq 'c' then begin
	common thc_458,thc_458_ind,thc_458_dat & thc_458_dat=erd_dat & thc_458_ind=0l
endif else if sc eq 'd' then begin
	common thd_458,thd_458_ind,thd_458_dat & thd_458_dat=erd_dat & thd_458_ind=0l
endif else if sc eq 'e' then begin
	common the_458,the_458_ind,the_458_dat & the_458_dat=erd_dat & the_458_ind=0l
endif else if sc eq 'f' then begin
	common thf_458,thf_458_ind,thf_458_dat & thf_458_dat=erd_dat & thf_458_ind=0l
endif


;store time range & eclipse correction status
eclipse = undefined(use_eclipse_corrections) ? 0:use_eclipse_corrections
thm_part_trange, sc, 'peer', set={trange:timerange(trange),eclipse:eclipse}


; help,erd_dat,/st
dprint, dlevel=4, 'Data loading complete: th'+sc+' peer - apid 458'

;***********************************************************************************
; Make tplot structures

cols=get_colors()

en_dat=fltarr(ntot,32)
energy=fltarr(ntot,32)

for i=0l,ntot-1l do begin
;	print,i,cs_ptr[i],cs_ind[i]
	case cs_ind[i] of
		0: en_dat[i,0:15]=reform(decompress[erd_dat.dat0[cs_ptr[i],*]])
		1: en_dat[i,0:31]=reform(decompress[erd_dat.dat1[cs_ptr[i],*]])
		2: en_dat[i,0:15]=total(reform(decompress[erd_dat.dat2[cs_ptr[i],*]],6,16),1)
		3: en_dat[i,0:31]=total(reform(decompress[erd_dat.dat3[cs_ptr[i],*]],6,32),1)


	endcase
	energy[i,*]=reform(erd_dat.energy[*,en_ind[i]])
endfor

if not keyword_set(gap_time) then gap_time=10.
if ntot gt 1 then begin
ind=where(s_time[1:ntot-1]-s_time[0:ntot-2] gt gap_time,n_ind)
if n_ind gt 0 then begin
	en_dat[ind,*]=!values.f_nan
	en_dat[ind+1,*]=!values.f_nan
endif
endif

name1='th'+sc+'_peer_en_counts'+suffix
store_data,name1,data={x:(erd_dat.time+erd_dat.end_time)/2.,y:en_dat,v:energy}
	zlim,name1,0,0,1,/def
	ylim,name1,3.,40000.,1,/def
	options,name1,'ztitle','Counts',/def
	options,name1,'ytitle','e- th'+sc+'!C!C eV',/def
	options,name1,'spec',1,/def
	options,name1,'x_no_interp',1,/def
	options,name1,'y_no_interp',1,/def

name1='th'+sc+'_peer_mode'+suffix
store_data,name1,data={x:(s_time+e_time)/2.,y:[[config1-.1],[config2+.1],[md_ind]]}
	ylim,name1,-1,10,0,/def
	options,name1,'ytitle','e- th'+sc+'!C!C mode',/def
	options,name1,'colors',[cols.red,cols.green,cols.blue],/def
	options,name1,labels=['config1', 'config2', 'mode'],constant=0.,/def
	options,name1,'labflag',3,/def
	options,name1,'labpos',[0,3,6],/def

;***********************************************************************************

end
