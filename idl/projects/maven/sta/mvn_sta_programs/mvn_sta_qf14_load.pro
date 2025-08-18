;+
;PROCEDURE:     mvn_sta_qf14_load_v2
;
;PURPOSE:
;
; Loads quality flag bit 14 into static apid common blocks - set
; to 1 during anomolous ion suppression
; 
; Criteria:
;
;    1. Only time intervals after 2015-01-01.
;    2. Only below 500km altitude. 
;    3. All modes except protect mode (6).
;

pro mvn_sta_qf14_load


  ;;------------------------------------
  ;; Declare all the common block arrays
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




  ;;;********************************************************
  ;;;Get APID c6
  ;;;
  ;;
  ;;NOTE:
  ;;
  ;;     APID c6 is used as the base time. All other APIDs
  ;;     will be prodcued based on the c6 time intervals.


  ;;-----------------------------------------
  ;; Check if APID c6 is loaded, it may be set to 0
  print, 'Generate Quality Flags for APID c6...'
  if n_elements(mvn_c6_dat) eq 0 || size(mvn_c6_dat, /type) Ne 8 then begin
     print, 'APID c6 must be loaded! Skipping qf14.'
     return
  endif

  ;;-----------------------------------------
  ;; Load c6 - Change structure name to dat
  dat       = mvn_c6_dat
  npts      = dimen1(dat.data)
  qf_c6     = dat.quality_flag
  nmass     = dat.nmass
  nenergy   = dat.nenergy
  nbins     = dat.nbins
  time      = dat.time
  time_end  = dat.end_time
  mode      = dat.mode
  att       = dat.att_ind
  header    = dat.header
  eprom     = dat.eprom_ver
  bit14     = 2^14
  bit14zero = 2^14-1


  ;;-------------------------
  ;; Find orbits and altitude
  tt=timerange()
  orb_time = tt[0]+360.*findgen(240)*(tt[1]-tt[0])/(24.*3600.)
  orb_num = mvn_orbit_num(time=orb_time)-0.3
  maven_orbit_tplot,result=result,/loadonly,/timecrop
  R_m = 3389.9D
  npts=n_elements(result.x)
  ss = dblarr(npts, 4)
  ss[*,0] = result.x
  ss[*,1] = result.y
  ss[*,2] = result.z
  ss[*,3] = result.r
  alt = (ss[*,3] - 1D)*R_m
  pp = where(result.t ge tt[0] and result.t le tt[1],cc)
  if cc eq 0 then begin
     print, 'No altitude available.'
     return
  endif
  alt = interp(alt[pp], result.t[pp], time)
  



  ;;-----------------------------------------------
  ;; Zero out all quality flag 14
  qf_c6 = qf_c6 and bit14zero

  ;;-----------------------------------------------
  ;; Find c6 time intervals which satisfy criteria 
  ;; and apply qf14
  time_2015 = time_double('2015-01-01')
  pp = where(time ge time_2015 and $   ;; 1. Past 2015-01-01
             mode ne 6         and $   ;; 2. Only mode 1
             alt  le 500.d,cc)         ;; 3. Below 500 km
  if cc eq 0 then begin
     print, 'No quality flag 14 in selected intervals.'
     return
  endif

  ;;---------------------------------------------
  ;; Apply quality flag 14
  qf_c6[pp] = qf_c6[pp] or bit14
  mvn_c6_dat.quality_flag = qf_c6

  ;;------------------------------------------
  ;; Cycle through all APIDs
  qf=qf_c6

  apid=['2a','c0','c2','c4',     'c8',$
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
           nn  = n_elements(t_start)
           nn1 = lindgen(nn-1)
           t_stop = t_start + 0.004
        endif

        ;;-----------------------------------------------------
        ;; Cycle through all APID times and interpolate with c6
        nn = n_elements(t_start)
        for itime = 0l, nn-1l do begin
           
           ;;-----------------------------------------------
           ;; Zero out all quality flag 14
           qf_new[itime] = qf_new[itime] and bit14zero              

           ;;--------------------------------------------------
           ;; Check if any c6 times fall in current APID interval
           pp=where( time+2. ge t_start[itime] and $
                     time+2. le t_stop[itime],cc)
		if cc eq 0 then begin
			minval = min(abs(time-t_start[itime]),pp)
			cc=1
		endif
           ;;-------------------
           ;; Single Time
           if cc eq 1 then $
              qf_new[itime] = qf_new[itime] or qf_c6[pp]

           ;;-------------------
           ;; Mutliple Times
           if cc ge 2 then begin
              for i=0, cc-2 do qf_new[itime]=qf_new[itime] or qf_c6[pp[i]]
              qf_new[itime] = qf_new[itime] or qf_c6[pp[cc-1]]
           endif
        endfor

        ;;-----------------------------------
        ;; Insert quality flags into APID
        temp=execute('mvn_'+apid[api]+'_dat.quality_flag=qf_new')
        
     endif
     skip_apid:
  endfor



end
