function sta_temp_scpot_test, scpot, lpw
  ;;; checks for large/missing spacecraft potential or missing lpw data 
  bad_scpot = (~finite(scpot) or (abs(scpot) ge 3.5)) 
  no_lpw = ~finite(lpw)
  
  if bad_scpot or no_lpw then return,1 else return,0
end

function sta_momtest, beamtemp, peaken, threshold=th
  ;; returns 1 if the moment calculation provides a valid kinetic temp, 0 if not 
  ;; find the "magic temp" for this peak energy:
  ;; If the distribution is a beam centered at the peak energy,
  ;; and the beam is 22.5 deg wide in angle space
  ;; (i.e. completely fills 1 angular FOV bin)
  ;; what would its temperature be?

  ;; for the maxwell-boltzmann distribution, sigma=sqrt(T/m)
  ;; FWHM = 2.355 sigma
  ;; v = sqrt(2*E/m)
  ;; v component in the deflector direction is v*sin(22.5)
  ;; Find T by assuming the FWHM occurs at v*sin(22.5)
  ;; sqrt(2*E/m)*sin(22.5) = 2.355*sqrt(T/m)
  ;; so T = (sin(22.5)/2.355)^2 * 2E
  
  if ~keyword_set(th) then th=0.3 

  magictemp = (sin(22.5/!radeg)/2.355)^2 * 2. * peaken

  ;; when the beam temp is the same order of magnitude as the magic temp,
  ;; the moment calculation can provide a valid kinetic temp

  ratio = beamtemp / magictemp
  
  if ratio gt th then return, 1 else return, 0
 
end 

pro mvn_sta_temp_stitch, PICK=pick, TEST=test, TAILS=tails, noload=noload

  ;;;; make a continuous temperature profile out of the methods for STA O2+ temperatures.
  ;;;; also provide a kinetic temperature. 
  ;; This routine 
  ;;    -- requires c6 data to be loaded and will load it if it is not loaded
  ;;    -- requires the existence of certain tplot variables,
  ;;       or for STATIC data to be loaded so that those variables can be created.
  ;;    -- assumes that mvn_sta_l2_tplot and mvn_lpw_l0_tplot_restore or mvn_lpw_l0_load have been run.
  ;; You can load
  ;;  -- d0/d1 OR mvn_sta_FOV_flag_mr(0.0,100.0)_er(0.0,1000000.0)
  ;;  -- ca OR mvn_sta_ca_anode_perc
  ;;  -- cb OR mvn_sta_c6_cb_scpot
  get_timespan,tt
  common mvn_d1, mvn_d1_ind, mvn_d1_dat
  common mvn_c6, mvn_c6_ind, mvn_c6_dat
  common mvn_c8, mvn_c8_ind, mvn_c8_dat
  common mvn_d0, mvn_d0_ind, mvn_d0_dat
  
  if ~keyword_set(noload) then begin
    ;; if loading data, use d1 to calculate the FOV flag if it's available, else use d0
;    if size(mvn_d1_dat,/type) eq 8 then begin
;      mvn_sta_fov_snap, trange=tt,sta_apid='d1',flag=covflag2
;    endif else begin
;      mvn_sta_fov_snap, trange=tt,sta_apid='d0',flag=covflag2
;    endelse

   
    
  endif
   ;; setup the checks for beamwidth
   mvn_sta_cac6_energy_peak,/energy,/angular
  get_data, 'mvn_sta_ca_anode_perc', data=ddperc
  get_data, 'mvn_sta_c6_energypeak', data=ddpeaken
  get_data, 'mvn_sta_c6_cb_scpot', data=ddscpot

  peakenergy_tplot = ddpeaken.y + ddscpot.y 
  tpeakenergy = ddpeaken.x 
  
  efluxperc_tplot=ddperc.y[*,1]
  tefluxperc=ddperc.x 
 
  pick=0
  c6told=!values.F_NAN
  if keyword_set(pick) then ctime,tt,np=2
  
  ;; pull out all the data 
  
  get_data, 'alt',data=altdat
  get_data, 'mvn_sta_c6_mode', modet, c6mode
  get_data, 'mvn_sta_c6_att', attt, c6att
  get_data, 'mvn_lpw_swp1_V2', lpwt, lpwdat

  get_data, 'mvn_sta_c6_o2+_temp', times, c6b
  get_data, 'mvn_sta_c6_o2+_temp_ac', tanac6, c6a
  get_data, 'mvn_sta_c6_o2+_temp_statunc', terrc6, c6e

  get_data, 'mvn_sta_c8_temp', tc8, c8b
  get_data, 'mvn_sta_c8_o2+_temp_ac', tanac8, c8a
  get_data, 'mvn_sta_c8_temp_statunc', terrc8, c8e
  
 ; if total(tanac8) eq 0 then get_data,'mvn_sta_c8_o2+_tp_ana',tanac8,c8a
  
  get_data, 'mvn_sta_temp_moment_o2+_all', tmall, temp_d1_all 
  if size(temp_d1_all,/type) eq 0 then get_data, 'temp_moment_O2_all', tmall, temp_d1_all
  d1aa=temp_d1_all[*,-1]
  d1xa=temp_d1_all[*,0]
    
 ; get_data, 'mvn_sta_FOV_flag_mr(0.0,100.0)_er(0.0,1000000.0)', covft, covf
  
  ;; loop through the times, unfortunately.
  goodtimes = where(times gt tt[0] and times lt tt[1])
  times = times[goodtimes]
  ntimes = n_elements(times)

  ;;; make arrays of the temperature and the flags.
  temp = make_array(ntimes, value=!values.F_NAN)
  err = make_array(ntimes, value=!values.F_NAN)
  kintemp = make_array(ntimes,4)
  prod = temp ;;0 = c6; 1 = c8; 2 = d1<10; 3 = d1<20; 4 = d1all; 5 = interpolated
  testpath = temp - 1
  
  tailtested = make_array(ntimes, value=!values.F_NAN) 
  core_A = make_array(ntimes, value=!values.F_NAN) 
  core_T = make_array(ntimes, value=!values.F_NAN) 
  core_v = make_array(ntimes, value=!values.F_NAN) 
  c6_df = make_array(ntimes,32, value=!values.F_NAN)
  eflux_ratio = core_T
  c6_df_engy = c6_df
  lpw_scpot = c6_df 
  

  flags = mvn_sta_tempflag_struct(ntimes)
  
  tol2=1
  tol = 0.80
  if tol2 eq 1 then tol=2.0
  
  ;; make sure the c6 data is loaded before starting the loop
  if size(mvn_c6_dat,/type) eq 0 then mvn_sta_l2_load,sta_apid='c6'
  
  for n=0.,ntimes-1 do begin
    

    tt2 = times[n]
    dat = mvn_sta_get_c6(tt2)
    dat2 = dat

    if dat.valid eq 0 then begin
      flags[n].cnts = 1
      temp[n] = !values.F_NAN
      prod[n] = !values.F_NAN
      err[n] = !values.F_NAN
      testpath[n] = 0
      c6told = !values.F_NAN
      continue
    endif else begin
      flags[n].cnts = 0
    endelse

    ;; COUNT RATE TEST

    ms = [28.,40.]

    ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
    if count ne 0 then dat.data[ind]=0.
    if count ne 0 then dat.bkg[ind]=0.

    if total(dat.data) lt 50. then begin
      flags[n].cnts = 1
      temp[n] = !values.F_NAN
      err[n] = !values.F_NAN
      prod[n] = !values.F_NAN
      testpath[n] = 1
      c6told = !values.F_NAN
      continue
    endif else begin
      flags[n].cnts = 0
    endelse
    
    ;; END COUNT RATE
    
    ;; FOV TEST
;    covftmp=min(abs(covft-dat.time),closestcovflag)
;    covflag=covf[closestcovflag]
;
;    if covflag gt 2 then begin
;      flags[n].coverage = 1
;      temp[n] = !values.F_NAN
;      prod[n] = !values.F_NAN
;      testpath[n] = 2
;      c6told = !values.F_NAN
;      continue
;    endif
    
   ;; END FOV

   ;; MODE CHANGE TEST -- REMOVED 4/30/20
   ;; at the end, interpolate across these times, but set a flag

   attd=min(abs(attt-dat.time),closestatt)
   att=c6att[((closestatt-2)>0):((closestatt+2)<(n_elements(attt)-1))]

   moded=min(abs(modet-dat.time),closestmode)
   mode=c6mode[closestmode]
   modes=c6mode[((closestmode-2)>0):((closestmode+2)<(n_elements(modet)-1))]
;
;   if ((att[0] ne att[-1]) or (modes[0] ne modes[-1])) then begin
;     flags[n].mode = 1
;     temp[n] = !values.F_NAN
;     testpath[n] = 3
;     continue
;   endif
    
   ;; END MODE CHANGE
  
   ;; if enough counts and not a mode change, 
   ;; pull out all the data for this timestamp 
      
    c6tmp=min(abs(times-dat.time),closestc6)  
    c6t = c6b[closestc6<(n_elements(c6b)-1)]
    c6ta = c6a[closestc6<(n_elements(c6b)-1)]
    c6corr = c6ta / c6t
    c6te = c6e[closestc6<(n_elements(c6e)-1)]
    
    c8tmp=min(abs(tc8-dat.time),closestc8)
    c8t=c8b[closestc8]

    c8atmp=min(abs(tanac8-dat.time),closestc8a)
    c8ta=c8a[closestc8a]

    c8corr = c8ta / c8t
    
    c8etmp=min(abs(terrc8-dat.time),closestc8e)
    c8te=c8e[closestc8e]

    d1xa_tmp=min(abs(tmall-dat.time),closest_d1xa)
    d1xat = d1xa[closest_d1xa]

    d1aa_tmp=min(abs(tmall-dat.time),closest_d1aa)
    d1aat = d1aa[closest_d1aa]

    lpw_tmp=min(abs(lpwt-dat.time),closest_lpw)
    lpwc = lpwdat[closest_lpw]
    
    efluxperc_tmp=min(abs(tefluxperc-dat.time),closest_efluxperc)
    efluxperc = efluxperc_tplot[closest_efluxperc]
    
    peakenergy_tmp=min(abs(tpeakenergy-dat.time),closest_peakenergy)
    peakenergy = peakenergy_tplot[closest_peakenergy]
    
    alt_tmp = min(abs(altdat.x-dat.time),closest_alt)
    alti = altdat.y[closest_alt]
    
    
    ;; LPW TEST
    ;; sc potential <-3.5 V or lpw data missing
    badlpw=sta_temp_scpot_test(dat.sc_pot, lpwc)
    if badlpw then flags[n].scpot = 1 else flags[n].scpot = 0 
    ;; END LPW 
    
    ;; check the mode. if ram/CO2 mode, then use c6, else check on c8
    ;; MODE TEST 
    
    if mode eq 1 or mode eq 7 then begin
      ;;; ideally want to use c6, but only if the lpw data is good and c6 is finite
      
      ;; FINITE C6 TEST (also checks for good LPW) 
      if (~badlpw and (finite(c6t) and c6t gt 0)) then begin
        ;; if the scpot and lpw data are fine then check the corrections to c6
            
        ;; C6/C8 CORRECTION COMPARISON TEST
        c6ratio = c6t/c6told 
        c6ratio_ok = (c6ratio gt 0.2 and c6ratio lt 5.) or (n eq 0)
          if (c6corr lt tol and c6ratio_ok) then begin
            ;; if the corrections are less than tol% of the value then use the c6 temperature
            ;; right now tol=200%
            ;; in mode 1,7 if the temp changes by >factor of 5 this is probably false
            ;; so block it out
            temp[n] = c6t
            err[n] = c6te
            prod[n] = 0
            testpath[n] = 4
              if keyword_set(tails) then begin
                core_dat = mvn_sta_l3_tailtest(tt2)
                flags[n].tail = core_dat.flag
                core_A[n] = core_dat.A
                core_T[n] = core_dat.Ti
                core_v[n] = core_dat.vb
                eflux_ratio[n] = core_dat.ratio
                c6_df[n,*] = transpose(core_dat.df) 
                c6_df_engy[n,*] = transpose(dat2.energy[*,0])
                lpw_scpot[n,*] = transpose(core_dat.lpw_scpot)
              endif
              c6told=c6t
            continue
          endif else begin ;; if the c6 corrections are gt tol% of the value then check the c8 corrections
            ;; use whichever correction is smaller
            
            if (finite(c8corr) and (c8corr lt tol)) then begin
;             if finite(c6ratio) then begin
;              print, 'c6corr: '+string(c6corr)
;              print, 'c8corr: '+string(c8corr)
;              print, 'c6ratio: '+string(c6ratio)
;             endif
              temp[n] = c8t
              err[n] = c8te
              prod[n] = 1
              testpath[n] = 5
              if keyword_set(tails) then begin
                core_dat = mvn_sta_l3_tailtest(tt2)
                flags[n].tail = core_dat.flag
                core_A[n] = core_dat.A
                core_T[n] = core_dat.Ti
                core_v[n] = core_dat.vb
                 eflux_ratio[n] = core_dat.ratio
                c6_df[n,*] = transpose(core_dat.df) 
                c6_df_engy[n,*] = transpose(dat2.energy[*,0])
                lpw_scpot[n,*] = transpose(core_dat.lpw_scpot)
              endif      
              c6told=c6t
              continue
            endif else begin
              ;; in this case both corrections are large so use whichever is smaller?
              ;; CHANGED 4/30 -- if corrections are too large just don't give a temperature
              flags[n].bigcorr = 1        
              if c6ta gt c8ta then begin
                ;temp[n] = c8t
                ;prod[n] = 1   
                temp[n] = !values.F_NAN 
                err[n] = !values.F_NAN
                prod[n] = !values.F_NAN       
                testpath[n] = 6
              if keyword_set(tails) then begin
                core_dat = mvn_sta_l3_tailtest(tt2)
                flags[n].tail = core_dat.flag
                core_A[n] = core_dat.A
                core_T[n] = core_dat.Ti
                core_v[n] = core_dat.vb
                 eflux_ratio[n] = core_dat.ratio
                c6_df[n,*] = transpose(core_dat.df) 
                c6_df_engy[n,*] = transpose(dat2.energy[*,0])
                lpw_scpot[n,*] = transpose(core_dat.lpw_scpot)
              endif              
              c6told=c6t
                continue
              endif else begin
;                temp[n] = c6t
                temp[n] = !values.F_NAN
                err[n] = !values.F_NAN
                prod[n] = !values.F_NAN
                testpath[n] = 7
              if keyword_set(tails) then begin
                core_dat = mvn_sta_l3_tailtest(tt2)
                flags[n].tail = core_dat.flag
                core_A[n] = core_dat.A
                core_T[n] = core_dat.Ti
                core_v[n] = core_dat.vb
                 eflux_ratio[n] = core_dat.ratio
                c6_df[n,*] = transpose(core_dat.df) 
                c6_df_engy[n,*] = transpose(dat2.energy[*,0])
                lpw_scpot[n,*] = transpose(core_dat.lpw_scpot)
              endif               
              c6told=c6t
                continue
              endelse ;; end c6corr > c8corr & bigcorr             
            endelse ;; end c8corr lt tol  
          endelse ;; end c6corr lt tol
          ;; END C6/C8 COMPARISON  
          endif else begin 
            ;; if the scpot or lpw data are bad or c6t is missing, then check for c8            
            ;; FINITE C8 TEST
            if (finite(c8t) and c8t ne 0) then begin ;; if c8 exists, use it
              temp[n] = c8t
              err[n] = c8te
              prod[n] = 1
              testpath[n] = 8
              if c8corr gt tol then flags[n].bigcorr = 1  
              if keyword_set(tails) then begin
                core_dat = mvn_sta_l3_tailtest(tt2)
                flags[n].tail = core_dat.flag
                core_A[n] = core_dat.A
                core_T[n] = core_dat.Ti
                core_v[n] = core_dat.vb
                 eflux_ratio[n] = core_dat.ratio
                c6_df[n,*] = transpose(core_dat.df) 
                c6_df_engy[n,*] = transpose(dat2.energy[*,0])
                lpw_scpot[n,*] = transpose(core_dat.lpw_scpot)
              endif              
              c6told=c6t
              continue   
            endif else begin
              ;; if no c8 and no c6/bad scpot, then no temp in these modes 
              temp[n] = !values.F_NAN
              err[n] = !values.F_NAN
              prod[n] = !values.F_NAN
              flags[n].tail = -1
              testpath[n] = 9
              c6told=c6t
              continue
            endelse ;; END FINITE C8
          endelse ;; END FINITE C6        
        endif else begin ;; mode ne 1,7
          ;; don't give a temperature if protect mode
          if mode eq 6 then begin
            temp[n] = !values.F_NAN
            err[n] = !values.F_NAN
            prod[n] = !values.F_NAN
            flags[n].tail = -1
            testpath[n] = 10
            c6told= !values.F_NAN
            continue
          endif
          
          ;; TEST -- BEAMLIKE DISTRIBUTION?
            ;; if beamlike, the moment calc will overestimate temperature
            ;; for gwen - also test for suprathermal tails
            ;; if beamlike, use c6. 
            ;; if not, use d0/d1 
                      
          threshold_perc = 75.  ;% threshold - this % of eflux must be in the 3 peak eflux bins, to be labelled as a cold beam
          threshold_en = 20.  ;eV: the eflux peak must be below this value, after correction for sc pot, to be considered a cold beam

          ;if peakenergyTMP lt threshold_en and efluxperc ge threshold_perc then <it's a beam> else <use moment>

          anglebeam = peakenergy lt threshold_en and efluxperc ge threshold_perc 
          ; 1 if distribution is beamlike in angle      
          
          if anglebeam then begin
            ;; if c6 is available then use it; else use d0/d1 ram
            ;; NOPE if c6 is unavailable then no temp because d0/d1 needs corrections for s/c fx
            if c6t ne 0 and finite(c6t) then begin                
              temp[n] = c6t
              err[n] = c6te
              testpath[n] = 11
	      prod[n] = 0
              if c6corr gt tol then flags[n].bigcorr = 1
              if keyword_set(tails) then begin
                core_dat = mvn_sta_l3_tailtest(tt2)
                flags[n].tail = core_dat.flag
                core_A[n] = core_dat.A
                core_T[n] = core_dat.Ti
                core_v[n] = core_dat.vb
                 eflux_ratio[n] = core_dat.ratio
                c6_df[n,*] = transpose(core_dat.df) 
                c6_df_engy[n,*] = transpose(dat2.energy[*,0])
                lpw_scpot[n,*] = transpose(core_dat.lpw_scpot)
              endif              ;;; if the beam temp is high enough, then the beam is basically 
              ;;; guaranteed to cover more than 1 angular bin, 
              ;;; meaning that the moment calculation will do an ok job
              ;;; (except for spacecraft blockage etc) 
              ;;; so return a kinetic temperature 
              momtest = sta_momtest(c6t,peakenergy)
              if momtest then kintemp[n,*] = temp_d1_all[closest_d1xa,*]
              c6told=c6t
              continue
            endif else begin ;; no c6, no c8, no temp!
              testpath[n] = 12
            ;; if it's beamlike but you got this far,
            ;;  then the beam is in the FOV,
            ;; STATIC is not in ram mode or CO2 mode, so 
            ;;  the moment calculation should be valid
              kintemp[n,*] = temp_d1_all[closest_d1xa,*]
              if keyword_set(tails) then begin
                core_dat = mvn_sta_l3_tailtest(tt2)
                flags[n].tail = core_dat.flag
                core_A[n] = core_dat.A
                core_T[n] = core_dat.Ti
                core_v[n] = core_dat.vb
                 eflux_ratio[n] = core_dat.ratio
                c6_df[n,*] = transpose(core_dat.df) 
                c6_df_engy[n,*] = transpose(dat2.energy[*,0])
                lpw_scpot[n,*] = transpose(core_dat.lpw_scpot)
              endif              
              c6told=!values.F_NAN
              continue 
            endelse ;; end beamlike w/ noc6 
          endif else begin ;; it is not a beam, so no beam temperature is returned. 
             testpath[n] = 13
             temp[n] = !values.F_NAN
             err[n] = !values.F_NAN
             prod[n] = !values.F_NAN
             c6told=c6t
             ;; if it's not beamlike but you got this far, 
             ;; then the distribution is in the FOV
             ;; and the moment calculation should be valid
             kintemp[n,*] = temp_d1_all[closest_d1xa,*]
             if (keyword_set(tails) and alti lt 2000.) then begin
                core_dat = mvn_sta_l3_tailtest(tt2)
                flags[n].tail = core_dat.flag
                core_A[n] = core_dat.A
                core_T[n] = core_dat.Ti
                core_v[n] = core_dat.vb
                 eflux_ratio[n] = core_dat.ratio
                c6_df[n,*] = transpose(core_dat.df) 
                c6_df_engy[n,*] = transpose(dat2.energy[*,0])
                lpw_scpot[n,*] = transpose(core_dat.lpw_scpot)
             endif
           endelse ;; END BEAMLIKE TEST 
        endelse ;; END MODE    

  ;c6told=c6t
  
endfor ;; END LOOPING THROUGH TIMES

kintemp[where(kintemp eq 0)] = !values.F_NAN
prod1 = prod
temp1 = temp 

;; NOW CLEAN UP THE TEMP ARRAY

  ;; overwrite the points where the data product changed for only 1 measurement
  ;; it's better to stick with 1 product than to jump back and forth between them

  ;; first find all the points where the product both before AND after is different,
  ;; except the first and last points
  ;; need to add 1 bc prod can be = 0
  prod2 = prod+1
  lastprod = shift(prod2,1)
  nextprod = shift(prod2,-1)

  lastprod = lastprod[1:-2]
  nextprod = nextprod[1:-2]
  prod2 = prod2[1:-2]

  chng1 = prod2 - lastprod
  chng2 = nextprod - prod2

  ;; shift the index by 1 to account for the fact that you removed time zero
  ;; a blip occurs when the data product is the same on either side, it's ok to change
  ;; products twice in a row as long as you don't go back to the original
  blip = 1 + where(chng1 ne 0 and finite(chng1) and chng2 ne 0 and finite(chng2) and chng1 eq -chng2)

  ;; at each blip index replace the temperature with the product that should be used

  prod[blip] = prod[blip-1]

  foreach b,blip do begin
    testpath[b] = 16
    case 1 of
      prod[b] eq 0: begin ;; use c6
        temp[b] = c6b[b]
        err[b] = c6e[b]
      end
      prod[b] eq 1: begin ;; use c8
        ;; find the c8 temp
        c8tmp=min(abs(tc8-times[b]),closestc8)
        temp[b] = c8b[closestc8]
        c8tmp=min(abs(terrc8-times[b]),closestc8)
        err[b] = c8e[closestc8]
      end
      else: begin
        temp[b] = !values.F_NAN
      end
    endcase
    endforeach
    
    ;; loop through the times again and test for big changes in temp
    ;; especially ones that are concurrent with a discontinuity
    
    ss = 5. ;; step size to do the cleanup over: use an odd number 
    ;; so the routine works with an even number of timestamps before and after
    ;; beware making this too long.. you're basically setting a length scale
    ;; over which the temp is allowed to vary... 
  
    ssh = floor(ss/2)
    print, 'starting second loop'
    for n2=ssh,ntimes-(ssh+1) do begin
      ; if it's already NaN then just keep going
      if ~finite(temp[n2]) then continue
      
      wndw_ind = indgen(ss, start=(n2-ssh)) ;; the indices of the points in the window
      ;; length = ss = number of measurements to use
      ;; start = n2 - ssh = this measurement - half the step size, so the
      ;; measurement being worked with here is the middle element in the array
      ;; and has the index ssh in the wndw arrays 
      wndw_time = times[wndw_ind]
      wndw_temp = temp[wndw_ind]
      wndw_prod = prod[wndw_ind]
      
      ;; NAN TEST
      ;; if there's a NaN on both sides of this measurement it's probably bad
      NaNbefore = total(~finite(wndw_temp[0:(ssh-1)]))
      NaNafter = total(~finite(wndw_temp[(ssh+1):-1]))
      
      if (NaNbefore ge 1) and (NaNafter ge 1) then begin
        temp[n2] = !values.F_NaN
        prod[n2] = !values.F_NaN
        testpath[n2] = testpath[n2]+0.5
        continue
      endif
      
      ;; at this point there's good data on at least 1 side of the measurement
      ;; check to see if the temperature spiked on this measurement
      
      ;; to find a spike, check the stdev of the data without the point in it
      
      temp_mask = [ wndw_temp[0:(ssh-1)], wndw_temp[(ssh+1):-1] ] 
      stdv = stddev(temp_mask,/NaN)
      
      dt1 = abs(wndw_temp[ssh] - wndw_temp[ssh-1])
      dt2 = abs(wndw_temp[ssh+1] - wndw_temp[ssh])
      ;print, dt1, dt2, stdv 
      if dt1/stdv ge 4. or dt2/stdv ge 4. then begin
        ;; there's been a spike! 
        ;; if the product also changed, or there's NaNs on one side
        ;; then the spike is probably false, so overwrite it with NaN
        
        prodchng = ( (wndw_prod[ssh] ne wndw_prod[ssh-1]) or (wndw_prod[ssh+1] ne wndw_prod[ssh]) )
        
        if prodchng or (NaNbefore ge 1) or (NaNafter ge 1) then begin
          temp[n2] = !values.F_NaN
          prod[n2] = !values.F_NaN
          testpath[n2] = testpath[n2]+0.25
          
          continue
        endif
        
        ;; could also set a flag at this point 
      endif  
endfor ;; end of the second loop

;; don't allow values <60 K
;; 60 K seems random but it comes from a simulation
;; it's the value where the corrected temperature "bottoms out"
;; see the STATIC temperature paper for details 
;t_cold = 100.*8.617333d-5 
t_cold = 60.*8.617333d-5
;; values of ti<t_cold are usually caused by overcorrecting 
;; on the nightside, especially in the c8 data

ncold = n_elements(where(temp lt t_cold))
prod[where(temp lt t_cold)] = !values.F_NAN
err[where(temp lt t_cold)] = !values.F_NAN
temp[where(temp lt t_cold)] = !values.F_NAN


 ; temp2 = temp
 ; temp = tempnew
  store_data, 'mvn_sta_o2+_temp_preclean', data={x:times, y:temp1}
  store_data, 'mvn_sta_o2+_temp', data={x:times, y:temp}
  store_data, 'mvn_sta_o2+_temp_unc', data={x:times, y:err}
  store_data, 'mvn_sta_o2+_kintemp', data={x:times, y:kintemp}
  store_data, 'mvn_sta_temp_product', data={x:times, y:prod}
;  store_data, 't2', data={x:times, y:temp2}
  store_data, 'mvn_sta_temp_path', data={x:times, y:testpath}
  store_data, 'tailflag', data={x:times, y:flags.tail}
  store_data, 'tailtested', data={x:times, y:tailtested}
  store_data, 'mvn_sta_magic_temp_compare', data=['mvn_sta_o2+_temp_final', 'mvn_sta_c6_magictemp']
  
  store_data,'core_A',data={x:times,y:core_A}
  store_data,'core_T',data={x:times,y:core_T}
  store_data,'core_v',data={x:times,y:core_v}
  store_data,'c6_df',data={x:times,v:c6_df_engy,y:c6_df}
  store_data,'lpw_scpot',data={x:times,v:c6_df_engy,y:lpw_scpot}
  store_data,'eflux_ratio_tail_to_core', data={x:times, y:eflux_ratio}
  options,'c6_df','spectrogram',1
  
  
;flagstruct = { cnts: 0, $ ; 1 if low countrate
;  mode: 0, $ ; 1 if w/in 8sec of mode change -- that means this value is interpolated
;  tail: !values.F_NAN, $ ; 1 if possible superthermal tail
;  bigcorr: 0, $  ; 1 if the correction on the provided value is large
;  coverage: 0, $ ; 1 if a moment is used -- only valid if angular coverage is good
;  scpot: 0 } ; 1 if sc potential is high or missing

;;; the final flag (for users) is set to 1 if the corrections or scpot are large.
;;; really bad data has already been removed from the set.

final_flag = make_array(ntimes,value=!values.F_NAN)
flagme = where(flags.bigcorr eq 1 or flags.scpot eq 1 and finite(temp))
final_flag[flagme] = 1
flagme = where(flags.bigcorr eq 0 and flags.scpot eq 0 and finite(temp))
final_flag[flagme] = 0 

  store_data,'mvn_sta_o2+_temp_flag',data={x:times,y:final_flag}

   store_data, 'cntflag', data={x:times,y:flags.cnts}
   ;store_data, 'modeflag', data={x:times,y:flags.mode}
   store_data, 'corrflag', data={x:times,y:flags.bigcorr}
   ;store_data, 'covflag', data={x:times,y:flags.coverage}
   store_data, 'scpotflag', data={x:times,y:flags.scpot}
   store_data, 'modeatt', data=['mvn_sta_c6_mode', 'mvn_sta_c6_att']
   options,'modeatt','colors',[0,250]
   options, 'mvn_sta_magic_temp_compare','colors',[0,250]

  ylim,'mvn_sta_temp_product',-1,6
  ylim,'mvn_sta_o2+_temp',0.001,10.,1
  ylim,'mvn_sta_o2+_temp_unc',0.00001,10.,1
  ylim,'mvn_sta_o2+_temp_preclean',0.001,10.,1
  ylim,'mvn_sta_magic_temp_compare',0.01,100,1
  ylim,'mvn_sta_o2+_kintemp',0.001,10.,1
  ylim,'mvn_sta_o2+_temp_flag',-1,2
  
 ; ylim,'t2',0.001,10.,1
  ylim,'modeatt',-1,8
  ylim, 'tailflag', -1,3
;  ylim, 'tailtested', -1,2

;  tplot_save, ['tempstitch', 't2', 'product', 'cntflag', 'modeflag', $
;    'corrflag', 'covflag', 'scpotflag'], filename='/Users/Gwen/Desktop/maven/conferences/MAVEN PSG/spring 2020 virtual/'+time_string(tt[0],prec=-3)
;  
 ; tplot, /add, ['t2', 'tempstitch', 'product', 'tpath', 'mvn_sta_FOV_flag_mr(0.0,100.0)_er(0.0,1000000.0)', 'tailflag']
 ;   stop
 

end
