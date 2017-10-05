
;;Quality Flag Legend
;;
;;Location   	Definition   					Determined from                                                             
;;---------------------------------------------------------------------------------------------------------------------------------                       
;bit 0		test pulser on					- testpulser header bit set
;bit 1		diagnostic mode					- diagnostic header bit set
;bit 2		dead time correction > factor of 2		- deadtime correction > 2
;bit 3		mcp detector gain droop flag 			- deadtime and beam width - flagged if correction > 2
;bit 4		dead time correction not at event time		- missing data quantity for deadtime
;bit 5		electrostatic attenuator failing at low energy	- attE on and eprom_ver<2
;bit 6  	attenuator change during accumulation		- att 1->2 or 2->1 transition (one measurement)	
;bit 7		mode change during accumulation			- only needed for packets that average data during mode transition
;bit 8		lpw sweeps interfering with data 		- lpw mode not dust mode
;bit 9		high background 		 		- minimum value in DA > 10000 Hz
;bit 10		missing background 		 		- dat.bkg = 0		- may not be needed
;bit 11		missing spacecraft potential			- dat.sc_pot = 0	- may not be needed	
;bit 12		inflight calibration 				- date determined, set to 1 until calibration finalized
;bit 13		tbd
;bit 14		tbd
;bit 15		not used


;;Bit Value Definition
;;----------------------------------------------------------
;;bit = 0 -> No Flag.
;;bit = 1 -> Flag set (see legend above). 
;;
;;Example:
;;
;;     IDL> print, format='(B)',quality_flag
;;     IDL> 0000100101100
;;
;;     Flags are set for:
;;     bit 2 = 1
;;     bit 3 = 1
;;     bit 5 = 1
;;     bit 8 = 1




pro mvn_sta_qf_load,verbose=verbose



  ;;--------------------------------------------------------
  ;;Declare all the common block arrays
  common mvn_2a,mvn_2a_ind,mvn_2a_dat
  common mvn_c0,mvn_c0_ind,mvn_c0_dat
  common mvn_c2,mvn_c2_ind,mvn_c2_dat
  common mvn_c4,mvn_c4_ind,mvn_c4_dat
  common mvn_c6,mvn_c6_ind,mvn_c6_dat
  common mvn_c8,mvn_c8_ind,mvn_c8_dat
  common mvn_ca,mvn_ca_ind,mvn_ca_dat
  common mvn_cc,mvn_cc_ind,mvn_cc_dat
  common mvn_cd,mvn_cd_ind,mvn_cd_dat
  common mvn_ce,mvn_ce_ind,mvn_ce_dat
  common mvn_cf,mvn_cf_ind,mvn_cf_dat
  common mvn_d0,mvn_d0_ind,mvn_d0_dat
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_d2,mvn_d2_ind,mvn_d2_dat
  common mvn_d3,mvn_d3_ind,mvn_d3_dat
  common mvn_d4,mvn_d4_ind,mvn_d4_dat
  common mvn_d6,mvn_d6_ind,mvn_d6_dat
  common mvn_d7,mvn_d7_ind,mvn_d7_dat
  common mvn_d8,mvn_d8_ind,mvn_d8_dat
  common mvn_d9,mvn_d9_ind,mvn_d9_dat
  common mvn_da,mvn_da_ind,mvn_da_dat
  common mvn_db,mvn_db_ind,mvn_db_dat



  ;;----------------------------------------------------
  ;;Make sure da is loaded to obtain quality flags
  ;;for the the background (bit 9).
  temp=execute("temp1=mvn_da_dat")
  if size(temp1,/type) ne 8 then mvn_sta_l2_load, sta_apid=['da']
  temp=execute("temp1=mvn_da_dat")
  if size(temp1,/type) ne 8 then begin
     dprint, 'mvn_da_dat needs to be loaded.'
     return
  endif



  ;;-----------------------
  ;;Find orbits and altitude
  tt=timerange()
  orb_time = tt[0]+360.*findgen(240)*(tt[1]-tt[0])/(24.*3600.)
  orb_num = mvn_orbit_num(time=orb_time)-0.3
  maven_orbit_tplot,result=result,/loadonly
  R_m = 3389.9D
  npts=n_elements(result.x)
  ss = dblarr(npts, 4)
  ss[*,0] = result.x
  ss[*,1] = result.y
  ss[*,2] = result.z
  ss[*,3] = result.r
  alt = (ss[*,3] - 1D)*R_m




  ;;;********************************************************
  ;;;Get APID c0 and c6
  ;;;
  ;;
  ;;NOTE:
  ;;
  ;;     APID c6 is used as the base time. All other APIDs
  ;;     will be prodcued based on the c6 time intervals.
  ;;

  ;;Load c6 - Change structure name to dat
  print, 'Generate Quality Flags for APID c6...'
  dat=mvn_c6_dat  
  npts     = dimen1(dat.data)
  nmass    = dat.nmass
  nenergy  = dat.nenergy
  nbins    = dat.nbins
  time     = dat.time
  time_end = dat.end_time
  mode     = dat.mode
  att      = dat.att_ind
  header   = dat.header
  eprom    = dat.eprom_ver

  ;Load c0 - For bit 5 specifically.
  c0_npts    = dimen1(mvn_c0_dat.data)
  nmass      = mvn_c0_dat.nmass
  nenergy    = mvn_c0_dat.nenergy
  nbins      = mvn_c0_dat.nbins
  c0_counts  = reform(mvn_c0_dat.data,c0_npts,nenergy,nbins,nmass)
  c0_swp_ind = mvn_c0_dat.swp_ind
  c0_start   = mvn_c0_dat.time
  c0_end     = mvn_c0_dat.end_time
  c0_energy  = reform(mvn_c0_dat.energy,dimen1(mvn_c0_dat.energy),nenergy,nbins,nmass) 


  ;;--------------------------------------------------------
  ;;Clear the following bits: 0,1,5,6,7,8,9,10,11,12
  bitclear=2^0  + 2^1  + 2^5 + 2^6  + $
           2^7  + 2^8  + 2^9 + 2^10 + $
           2^11 + 2^12
  dat.quality_flag=dat.quality_flag and (not bitclear)
  

  ;;***************************************************************
  ;;Bit 0 - Test pulser
  ;;QF bit 0    test pulser on   (header and 128)        
  bit0mask=2^0
  head=(header and 128L)/128L
  pp=where(head eq 1L,cc)
  if cc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit0mask
  if keyword_set(verbose) then print, 'Bit 0 flags - Total:  '+string(cc)+'/'+string(npts)



  ;;***************************************************************
  ;;Bit 1 - Diagnostic Mode
  ;;QF bit 1    diagnostic mode  (header and 64)        
  bit1mask=2^1
  head=(header and 64L)/64L
  pp=where(head eq 1L,cc)
  if cc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit1mask
  if keyword_set(verbose) then $
     print, 'Bit 1 flags - Total:  '+string(cc)+'/'+string(npts)



  ;;***************************************************************
  ;;Bit 2 - Dead time correction
  bit2mask=2^2
  if keyword_set(verbose) then $
     print, 'Bit 2 flags - Total:  '+string(0L)+'/'+string(npts)  

  
  
  ;;***************************************************************
  ;;Bit 3 - MCP Gain Droop
  bit3mask=2^3
  if keyword_set(verbose) then $
     print, 'Bit 3 flags - Total:  '+string(0L)+'/'+string(npts)  

  
  
  ;;***************************************************************
  ;;Bit 4 - Dead time correction
  bit4mask=2^4
  if keyword_set(verbose) then $
     print, 'Bit 4 flags - Total:  '+string(0L)+'/'+string(npts)  
  
  
  ;;***************************************************************
  ;;Bit 5 - Electrostatic Attenuator Irregularity
  ;;
  ;;NOTES:
  ;;      Electrostatic attenuator flag should be set if
  ;;      ((att_ind eq 1) or (att_ind eq 3)) and
  ;;      (((eprom eq 2) and (c1 gt 10.)) or ((eprom eq 1) and 
  ;;      (c2 gt 10.))) 
  ;;      where c1 is the total counts in apid c0 less than .75 eV
  ;;      where c2 is the total counts in apid c0 less than 2.5 eV 

  
  ;;Jim's Method
  bit5mask=2^5
  npts=n_elements(dat.time)
  bit5=intarr(npts)
  eprom = dat.eprom_ver
  att = dat.att_ind
  ind = where(eprom eq 1 or eprom eq 2 ,cnt)
  if cnt gt 0 then begin
     for i=0,npts-1 do begin
        if (att[i] eq 1 or att[i] eq 3) then begin   
	   count=0
           if eprom[i] eq 1 then ind = where(dat.energy[dat.swp_ind[i],*,0] lt 2.4,count)
           if eprom[i] eq 2 then ind = where(dat.energy[dat.swp_ind[i],*,0] lt 0.69,count)
           if count ge 1 then begin
              datt = total(dat.data[i,ind,*])
              ;if datt gt 10. then bit5[i]=2^5
              if datt gt 10. then dat.quality_flag[i] = dat.quality_flag[i] or bit5mask
           endif
        endif
   endfor
  endif 

  

  ;;Old Method
  ;energies=c6_energy[c6_swp_ind,*,*,*]
  ;p1_energies=where(energies[*,nenergy-1,0,0] lt 0.75,c1_energies)
  ;p2_energies=where(energies[*,nenergy-1,0,0] lt 2.50,c2_energies)
  ;;;c1-----------------------------
  ;if c1_energies gt 0 then begin     
  ;   att_e1=att[p1_energies]
  ;   e1_temp=c0_counts[p1_energies,*,*]
  ;   c1=fltarr(c1_energies)
  ;   for i=0, c1_energies-1 do $
  ;      c1[i]=total(e1_temp[i,where(e1_temp[i,*,0] lt 0.75),0],2)
  ;   ppp=where($
  ;       ((att_e1 eq 1)  or  $
  ;        (att_e1 eq 3)) and $
  ;       ((eprom[p1_energies] eq 2)    and $
  ;        (c1 gt 10.)),ccc)
  ;   if ccc ne 0 then pp=p1_energies[ppp]
  ;   if ccc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit5mask
  ;endif
  ;;;c2-----------------------------
  ;if c2_energies gt 0 then begin     
  ;   att_e2=att[p2_energies]
  ;   e2_temp=c0_counts[p2_energies,*,*]
  ;   c2=fltarr(c2_energies)
  ;   for i=0, c2_energies-1 do $
  ;      c2[i]=total(e2_temp[i,where(e2_temp[i,*,0] lt 2.50),0],2)
  ;   ppp=where($
  ;       ((att_e2 eq 1)  or  $
  ;        (att_e2 eq 3)) and $
  ;       ((eprom[p2_energies] eq 1)    and $
  ;        (c2 gt 10.)),ccc)
  ;   if ccc ne 0 then pp=p2_energies[ppp]
  ;   if ccc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit5mask
  ;endif
  if keyword_set(verbose) and n_elements(ccc) then $
     print, 'Bit 5 flags - Total:  '+string(ccc)+'/'+string(npts) $
  else print, 'Bit 5 flags - Total:  '+string(0L)+'/'+string(npts)
  


  ;;***************************************************************
  ;;Bit 6 - Attenuator Change During Accumulation
  ;;NOTE
  ;;
  ;; 1. Bit6 is allowed to land on boundaries only for electrostatic
  ;; attenuator.
  ;; 2. For APIDs with 4  second cadence we only want to include
  ;; transitions to and from mechanical. e.g. 1->2 or 2->1. For APIDs
  ;; that have a larger cadence we include all changes.
	;; this is modified 20150724 to handle mech attenuator changes better
  bit6mask=2^6
  pp=[0,lindgen(n_elements(att)-1)]        
  temp=att-att[pp]
  ind=where(temp ne 0,cc)-1
  if cc ne 0 then dat.quality_flag[ind] = dat.quality_flag[ind] or bit6mask
  if keyword_set(verbose) then $
     print, 'Bit 6 flags - Total:  '+string(cc)+'/'+string(npts)


  ;;***************************************************************  
  ;;Bit 7  - Mode Change During Accumulation
  ;;NOTE
  ;;
  ;; Is allowed to land on boundaries   
  bit7mask=2^7
  pp=[0,lindgen(n_elements(att)-1)]        
  temp=mode-mode[pp]
  ind=where(temp ne 0,cc)-1
  if cc ne 0 then dat.quality_flag[ind] = dat.quality_flag[ind] or bit7mask
  if keyword_set(verbose) then $
     print, 'Bit 7 flags - Total:  '+string(cc)+'/'+string(npts)
  
  
  ;;***************************************************************  
  ;;Bit 8  - LPW Sweep Interference
  ;;
  ;;NOTES:
  ;;    - LPW sweeps interfering with data:
  ;;      - Date lt 2014-11-20 for all orbits
  ;;      - Date gt 2014-11-20 and date lt 2015-01-07 for odd orbits
  ;;    - The LPW interference should only apply to 'conic' (2)
  ;;      and 'ram' (1) modes on the identified orbits,
  ;;      i.e. mode less than 3 
  bit8mask=2^8
  orb_num_new=fix(interpol(orb_num,orb_time,time))
  date1=time_double('2014-11-20')
  date2=time_double('2015-01-07')
  pp1=where(time lt date1 and mode lt 3,cc1)
  if cc1 ne 0 then dat.quality_flag[pp1] = dat.quality_flag[pp1] or bit8mask
  pp2=where(time ge date1 and $
            time lt date2 and $
            (orb_num_new mod 2) eq 1 and $ ;odd orbits 
            mode lt 3,cc2)
  if cc2 ne 0 then dat.quality_flag[pp2] = dat.quality_flag[pp2] or bit8mask
  if keyword_set(verbose) then $
     print, 'Bit 8 flags - Total:  '+string(cc1)+'/'+string(npts)+' (c1)'
  if keyword_set(verbose) then $
     print, 'Bit 8 flags - Total:  '+string(cc1)+'/'+string(npts)+' (c2)'



  ;;***************************************************************
  ;;Bit 9  - High Background
  bit9mask=2^9
;  pp=where(min(mvn_da_dat.rates,dim=2) ge 1000.D,cc)
;  if cc ne 0 then begin
;     ind=mvn_da_dat.time*0.D
;     ind[pp]=1.
;     time_da=mvn_da_dat.time[pp]
;     ;;Interpolate for apid c6 (time)  
;     ind2=ceil(interpol(ind,mvn_da_dat.time,time))
;     pp=where(ind2 gt 0)
;     dat.quality_flag[pp] = dat.quality_flag[pp] or bit9mask
;  endif
	rates = interp(mvn_da_dat.rates,mvn_da_dat.time,time)
	for i=0,npts-1 do begin
		if (min(rates[i,*]) ge 10000.) then begin
			dat.quality_flag[i] = dat.quality_flag[i] or bit9mask
		endif else begin
			dat.quality_flag[i] = dat.quality_flag[i] and (not bit9mask)
		endelse
	endfor
  if keyword_set(verbose) then $
     print, 'Bit 9 flags - Total:  '+string(cc)+'/'+string(npts)



  ;;***************************************************************
  ;;Bit 10 - Missing Background
  ;;
  ;; !!! Default is set to 1 until these values are calculated !!!
  bit10mask=2^10
  dat.quality_flag = dat.quality_flag or bit10mask
  if keyword_set(verbose) then $
     print, 'Bit 10 flags - Total: '+string(npts)+'/'+string(npts)
  


  ;;***************************************************************  
  ;;Bit 11 - Missing Spacecraft Potential
  ;;
  ;; !!! Default is set to 1 until these values are calculated !!!
  bit11mask=2^11
  dat.quality_flag = dat.quality_flag or bit11mask
  if keyword_set(verbose) then $
     print, 'Bit 11 flags - Total: '+string(npts)+'/'+string(npts)
  
  

  ;;***************************************************************
  ;;Bit 12 - Extra
  ;;
  ;; !!! Default is set to 1 until these values are calculated !!!
  bit12mask=2^12
  dat.quality_flag = dat.quality_flag or bit12mask
  if keyword_set(verbose) then $
     print, 'Bit 12 flags - Total: '+string(npts)+'/'+string(npts)
  





  ;;-----------------------------------------------
  ;;Apply quality flag to all APIDs (except c6 since
  ;;it was already set).Define QF and APIDs

  qf=dat.quality_flag

  apid=['2a','c0','c2','c4','c8','c6',$
        'ca','cc','cd','ce','cf','d0',$
        'd1','d2','d3','d4','d6','d7',$
        'd8','d9','da','db']


  nn_apid=n_elements(apid)
  for api=0, nn_apid-1 do begin     
     temp=execute('nn7=size(mvn_'+apid[api]+'_dat,/type)')
     if nn7 eq 8 then begin
        
        ;;------------------------------------------------
        ;; Get APID Data
        res1 = execute('qf_new  = mvn_'+apid[api]+'_dat.quality_flag')
        res2 = execute('t_start = mvn_'+apid[api]+'_dat.time')
        res3 = execute('t_stop  = mvn_'+apid[api]+'_dat.end_time')
        
        ;;------------------------------------------------
        ;; Error Check
        if res1 eq 0 and res2 eq 0 and res3 eq 0 then begin
           print, 'No qf or start/stop times for '+apid[api]+'.'
           goto, skip_apid
        endif
        if res2 eq 1 and res3 eq 0 then begin
           nn  =n_elements(t_start)
           nn1 = lindgen(nn-1)
           t_stop = t_start + 0.004
        endif
        nn1 = n_elements(t_start)

        ;;--------------------------------------------------
        ;; Clear and insert bit 2,3, and 4
       	qf_new = qf_new and (2^2+2^3+2^4)

        for itime=0l, nn1-1 do begin
           pp=where( time+2. ge t_start[itime] and $
                     time+2. le t_stop[itime],cc)
		if cc eq 0 then begin
			minval = min(abs(time-t_start[itime]),pp)
			cc=1
		endif
           if cc eq 1 then begin
		if (((att[pp] eq 1) and (att[(pp+1)<(npts-1)] eq 2)) or ((att[pp] eq 2) and (att[(pp+1)<(npts-1)] eq 1))) then tmpmask=2^15-1-bit7mask else tmpmask=2^15-1-bit6mask-bit7mask 
		qf_new[itime]=qf_new[itime] or (qf[pp] and tmpmask)
	   endif else if cc ge 2 then begin
		for i=0, cc-2 do qf_new[itime]=qf_new[itime] or qf[pp[i]] 
		if (((att[pp[cc-1]] eq 1) and (att[(pp[cc-1]+1)<(npts-1)] eq 2)) or ((att[pp[cc-1]] eq 2) and (att[(pp[cc-1]+1)<(npts-1)] eq 1))) then tmpmask=2^15-1-bit7mask else tmpmask=2^15-1-bit6mask-bit7mask 
		qf_new[itime]=qf_new[itime] or (qf[pp[cc-1]] and tmpmask)
	   endif
        endfor


        ;;-------------------------------------------------------
        ;;Insert new 
        temp=execute('mvn_'+apid[api]+'_dat.quality_flag=qf_new')

        
     endif
     skip_apid:
  endfor

	store_data,'mvn_sta_c6_quality_flag',data={x:(mvn_c6_dat.time+mvn_c6_dat.end_time)/2.,y:mvn_c6_dat.quality_flag}
		options,'mvn_sta_c6_quality_flag',tplot_routine='bitplot',psym = 1,symsize=1

end




























;;-------------------
;; Old Code

        ;temp=execute('qf_new=mvn_'+apid[api]+'_dat.quality_flag')        
        ;temp=execute('t_start=mvn_'+apid[api]+'_dat.time')        
        ;;---------------------------------------------------------
        ;;Time interval
	;nn1 = n_elements(qf_new)
        ;temp2=execute('nn2=n_elements(mvn_'+apid[api]+'_dat.end_time)')

        ;start time
        ;temp=execute('t_start=mvn_'+apid[api]+'_dat.time')        

        ;stop time
        ;if temp2 then temp=execute('t_stop=mvn_'+apid[api]+'_dat.end_time') $
        ;else t_stop = [t_start[1:nn1-1],2.*t_start[nn1-1]-t_start[nn1-2]] 

