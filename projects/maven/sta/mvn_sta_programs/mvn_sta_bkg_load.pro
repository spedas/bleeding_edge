;;-----------------------------------
;; Background constsist of two parts:
;;
;;  1.  Electrostatic Attenuator (10-30 eV) Ions.
;;  2.  TOF Stragglers.

pro mvn_sta_bkg_load, tplot_test=tplot_test

  
  ;; Declare Common Blocks with Background
  common mvn_c0,mvn_c0_ind,mvn_c0_dat
  common mvn_c6,mvn_c6_ind,mvn_c6_dat
  common mvn_c8,mvn_c8_ind,mvn_c8_dat
  common mvn_ca,mvn_ca_ind,mvn_ca_dat
  common mvn_cc,mvn_cc_ind,mvn_cc_dat
  common mvn_cd,mvn_cd_ind,mvn_cd_dat
  common mvn_ce,mvn_ce_ind,mvn_ce_dat
  common mvn_cf,mvn_cf_ind,mvn_cf_dat
  common mvn_d0,mvn_d0_ind,mvn_d0_dat
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_d4,mvn_d4_ind,mvn_d4_dat

  apid=['c0','c6','c8',$
        'ca','cc','cd','ce','cf',$
        'd0','d1','d4']
  nn_apid=n_elements(apid)

  ;;---------------------
  ;; Load L2 tplot data
  if keyword_set(tplot_test) then mvn_sta_l2_tplot







  ;;-------------------------------------------------------------
  ;; 1.  Electrostatic Attenuator (10-30 eV) Ions.
  ;;-------------------------------------------------------------





  ;;-------------------------
  ;; Check if c0 is available
  if n_elements(mvn_c0_dat.time) eq 0 then begin
     print, 'mvn_sta_bkg_load.pro requires STATIC c0.'
     return
  endif

  ;;-----------------------------
  ;; Check if ephemeris is loaded
  if total(mvn_c0_dat.pos_sc_mso) eq 0 then begin
     print, 'mvn_sta_bkg_load.pro requires STATIC ephemris.'
     return
  endif


  ;;--------------------
  ;; Use c0 as base time
  time = mvn_c0_dat.time
  mode = mvn_c0_dat.att_ind

  ;;-------------------
  ;; Get Altitude Data

  ;; Mars Information
  R_m   = 3389.9D
  R_equ = 3396.2D
  R_pol = 3376.2D

  ;; Calculate altitude from ephemeris
  alt = sqrt(total(mvn_c0_dat.pos_sc_mso^2,2)) - R_m

  ;; Set Altitude
  alt_limit = 175. 

  ;; Set Energy Range
  erange   = [10,30]

  ;; ----------- Selection Criteria --------------
  ;; 1. Below specified altitude
  ;; 2. Within mode 3 (electrostatic + mechanical)
  ;; 3. Only near Deep Dip #2
  pp = where(alt  lt alt_limit and $
             mode eq 3         and $
             time gt time_double('2015-04-12') and $
             time lt time_double('2015-04-28'),cc)
  ;; Create time index
  ind     = intarr(n_elements(time))
  ind[pp] = 1 
  ;store_data, 'AttenuatorIonsC0', time, ind


  ;;--------------------------------------------------------------------
  ;; Cycle through APIDs
  for api = 0, nn_apid-1 do begin
     temp=execute('nn1=size(mvn_'+apid[api]+'_dat,/type)')
     if nn1 eq 8 then begin    
        
        ;; Create APID data
        temp    = execute('tt  = mvn_'+apid[api]+'_dat.time')        
        temp    = execute('dat = mvn_'+apid[api]+'_dat.data')        
        temp    = execute('enr = reform(mvn_'+apid[api]+'_dat.energy['+$
                          'mvn_'+apid[api]+'_dat.swp_ind,*,0])')
        new_ind = fix(round(interpol(ind,time,tt)))
        new_pp  = where(new_ind eq 1,new_cc)
        bkg     = dat*0.D
           
        ;; Load Background for matching intervals
        for ibkg=0, new_cc-1 do begin
           new_enr = where(enr[new_pp[ibkg],*] gt erange[0] and $
                           enr[new_pp[ibkg],*] lt erange[1],cc)
           if cc eq 0 then stop
           bkg[new_pp[ibkg],new_enr,*] = dat[new_pp[ibkg],new_enr,*]
        endfor       
        temp = execute('mvn_'+apid[api]+'_dat.bkg = bkg')        

        ;;------------------------------------------------------------
        ;; Load tplot variables
        if keyword_set(tplot_test) then begin

           ;; Background
           store_data,'bkg_'+apid[api],data={x:tt,y:total(bkg,3),v:enr}
           ylim,    'bkg_'+apid[api],0.1,40000., 1
           zlim,    'bkg_'+apid[api],1,1.e4,1
           options, 'bkg_'+apid[api],datagap=7.
           options, 'bkg_'+apid[api],'spec',1           
           ;; Remove Interpolation
           options,'bkg_'+apid[api],no_interp=1

           ;; Background removed from data
           store_data,apid[api],data={x:tt,y:total(dat-bkg,3),v:enr}
           ylim,      apid[api]+' - bkg',0.1,40000., 1
           zlim,      apid[api]+' - bkg',1,1.e4,1
           options,   apid[api]+' - bkg',datagap=7.
           options,   apid[api]+' - bkg','spec',1
           ;; Remove Interpolation
           options,apid[api]+' - bkg',no_interp=1

        endif

     endif
  endfor



  ;;----------------------------------------------------------
  ;; 2. TOF Stragglers
  ;;----------------------------------------------------------


end


