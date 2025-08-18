;+
;PROCEDURE: 
;	MVN_SWE_ETSPEC
;
;PURPOSE:
;	Makes tplot variables with respect to the MAVEN SWEA
;       Energy-time spectrogram(s). 
;
;CALLING SEQUENCE: 
;       mvn_swe_etspec, ['2014-11-17/08:04:19', '2014-11-17/12:40:31'], $
;                      units='eflux', data_type='3d', $
;                      angle='pa', /default
;
;INPUTS: 
;   none - 3D, PAD, or SPEC  data are obtained from SWEA common block.
;   If you set the time interval, then a tplot variable is created
;   between you specified time intervals.  
;   (Noted that it might take more than 10 minutes to resample pitch
;   angle distributions if you use PAD data for 1 day, depending on
;   your machine spec and data amount.)
;
;KEYWORDS:
;   TRANGE:    Instead of an input variable, you can alternatively specify
;              the time interval when you want to create a tplot variable.
;
;   DATA_TYPE: Chooses the data product type ('3d', 'pad', or 'spec')
;              Default is 'spec'.
;
;   ERANGE:    Specifies energy range over which you want to plot .
;              Default is the whole enegy range.
;
;   UNITS:     Sets the unit to prefer to use. Default = 'crate'.
;
;   ANGLE:     Selects the angular spectrum. Now 'pa' is only available.
;              'pa' means it can plot the pitch-angle-sorted, energy-time
;              spectrogram. In near future, 'phi'(= azimuth anode),
;              'theta'(= deflection angle) will be available.
;   
;   PHI:       Limits the azimuth anode (or looking direction) as
;              2-elements array [min, max], in degrees.
;
;   THETA:     Limits the deflection angle (or lookgin direction) as
;              2-elements array [min, max], in degrees.
;
;   PITCH:     Limits the pitch angle as 2-elements array [min, max],
;              in dgrees. If it is used, 'mvn_swe_pad_resample' is
;              automatically executed.
;
;   SUFFIX:    Sets a tplot suffix to apply when generating outputs.
;
;   MASK:      Masks the expected angular bins whose field of view is
;              blocked by the spacecraft body and solar
;              paddles. Automatically identifying the mission phases
;              (cruise or science mapping).
;
;   STOW:      (Obsolete). Mask the angular bins whose field of view
;              is blocked before the boom deploy. 
;
;   ARCHIVE:   Uses the archive data, instead of the survey data.
;
;   WINDOW:    Set the window number to show the snapshot. Default = 0.
;
;   ABINS:     Specify which anode bins to 
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,16)
;
;   DBINS:     Specify which deflection bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,6)
;
;   MBINS:     Specify which angular (both anode and deflection) bins
;              to include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1, 96)
;
;   SC_POT:    Account for the spacecraft potential correction.
;              (Not completely activated yet)
;
;   VERBOSE:   Controls how often the processing information is shown
;              onto the terminal.
;
;   Default:   If you use this keyword, the following tplot variables
;              are automatically created:
;              If you also use the keyword as angle='pa',
;                 - quasi-parallel (0-30 deg),
;                 - quasi-perpendicular (75-105 deg),
;                 - quasi-antiparallel (150-180 deg),
;              Above 3 directional pitch-angle-sorted energy-time spectrograms
;              are created.
;              If you do NOT use 'angle' keyword, 
;                 - sunward      (+ MSO_X)
;                 - anti-sunward (- MSO_X)
;                 - duskward     (+ MSO_Y)
;                 - dawnward     (- MSO_Y)
;                 - northward    (+ MSO_Z)
;                 - southward    (- MSO_Z)
;              Above 6 directional enegry-time spectrograms
;              are created if SPICE/Kernels are available.
;
;  FRAME:      Sets the coordinate system to define the direction. 
;              In the present version, the coordinate system(s)
;              derived from the SPICE/Kernels are available, 
;              e.g., 'MAVEN_MSO', 'IAU_MARS', 'MAVEN_SWEA' or so on.
;
;CREATED BY:      Takuya Hara on 2014-11-22. 
;
; $LastChangedBy: hara $
; $LastChangedDate: 2015-08-12 20:41:21 -0700 (Wed, 12 Aug 2015) $
; $LastChangedRevision: 18478 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_etspec.pro $
;
;MODIFICATION LOG:
;(YYYY-MM-DD)
; 2014-11-22: Starts to prepare this routine.
; 
;-
PRO mvn_swe_etspec_cotrans, var, tvar, pvar, from=from, to=to, verbose=silent, $
                            vx=vxn, vy=vyn, vz=vzn, theta=thetan, phi=phin, status=status
  dat = var
  time = (dat.time + dat.end_time)/2.d0 
  theta = tvar
  phi = pvar

  sphere_to_cart, 1.d0, dat.theta, dat.phi, vx, vy, vz

  q = spice_body_att(from, to, time, $
                     /quaternion, check_object='MAVEN_SPACECRAFT', $
                     verbose=-1)
  
  t2 =   q[0]*q[1]              ;- cf. quaternion_rotation.pro
  t3 =   q[0]*q[2]
  t4 =   q[0]*q[3]
  t5 =  -q[1]*q[1]
  t6 =   q[1]*q[2]
  t7 =   q[1]*q[3]
  t8 =  -q[2]*q[2]
  t9 =   q[2]*q[3]
  t10 = -q[3]*q[3]
  
  vxn = 2*( (t8 + t10)*vx + (t6 -  t4)*vy + (t3 + t7)*vz ) + vx
  vyn = 2*( (t4 +  t6)*vx + (t5 + t10)*vy + (t9 - t2)*vz ) + vy
  vzn = 2*( (t7 -  t3)*vx + (t2 +  t9)*vy + (t5 + t8)*vz ) + vz

  thetan = 90. - ACOS(vzn)*!RADEG
  phin = ATAN(vyn, vxn) * !RADEG 
  IF ((STRMID(to, 0, 5) EQ 'MAVEN' ) OR (to EQ 'IAU_MARS')) THEN RETURN
  undefine, vx, vy, vz, theta, phi

  RETURN
END
PRO mvn_swe_etspec_default, dat, theta, phi, units=units, y=y, v=v, index=i, suffix=suffix
  nan = !values.f_nan
  FOR j=0, N_ELEMENTS(suffix)-1 DO BEGIN
     ; j = 0, sunward (+ MSO_X)
     ; j = 1, anti sunward (- MSO_X)
     ; j = 2, duskward (+ MSO_Y)
     ; j = 3, dawnward (- MSO_Y)
     ; j = 4, northward (+ MSO_Z)
     ; j = 5, southward (- MSO_Z)
     CASE j OF
        0:  idx = WHERE( (ABS(theta) LE 45.) AND (ABS(phi) LE 45.), ndat)
        1:  idx = WHERE( (ABS(theta) LE 45.) AND (ABS(phi) GE 135.), ndat)
        2:  idx = WHERE( (ABS(theta) LE 45.) AND (phi GT 45. AND phi LT 135.), ndat)
        3:  idx = WHERE( (ABS(theta) LE 45.) AND (phi GT -135. AND phi LT -45.), ndat)
        4:  idx = WHERE( theta GT 45., ndat)
        5:  idx = WHERE( theta LT -45., ndat)
     ENDCASE

     IF ndat GT 0 THEN BEGIN
        weight = dat.data * 0.
        weight[idx] = 1.
        IF STRLOWCASE(units) NE 'counts' THEN $
           y[j, i, *] = TOTAL(dat.data*dat.domega*weight, 2, /nan) / TOTAL(dat.domega*weight, 2, /nan) $
        ELSE y[j, i, *] = TOTAL(dat.data*weight, 2, /nan)
     ENDIF ELSE y[j, i, *] = nan
     v[j, i, *] = average(dat.energy, 2, /nan) 
     undefine, idx, ndat
  ENDFOR 
END 
PRO mvn_swe_etspec, var, trange=trange, data_type=data_type, erange=erange, units=units, $
                    angle=angle, phi=phrange, theta=thrange, pitch=pitch, suffix=suffix, $
                    mask=mask, stow=stow, archive=archive, window=wi, _extra=extra, $
                    abins=abins, dbins=dbins, mbins=mbins, sc_pot=sc_pot, $
                    verbose=vb, verbose=verbose, default=default, frame=frame 

  COMPILE_OPT idl2
  @mvn_swe_com
  nan = !values.f_nan 
  fifb = string("15b) ;"
  from = 'MAVEN_SWEA'
  IF keyword_set(archive) THEN aflg = 1 ELSE aflg = 0
  IF (aflg) THEN pname = 'Archive' ELSE pname = 'Survey' ; product name
  IF ~keyword_set(suffix) THEN suffix = '' 
  ;; IF keyword_set(silent)  THEN verbose = - silent ELSE verbose = 0
  IF keyword_set(vb) THEN verbose = vb
  IF ~keyword_set(frame)  THEN to = 'MAVEN_SWEA' ELSE to = frame
  IF keyword_set(default) THEN to = 'MAVEN_MSO'

  ; Data types
  ;--------------- 
  IF SIZE(data_type, /type) EQ 0 THEN data_type = 'spec' 
  CASE STRLOWCASE(data_type) OF
     'spec': dtype = 0
     '3d'  : dtype = 1
     'pad' : dtype = 2
     ELSE  : BEGIN
        dprint, 'Input did not include a valid data type.'
        RETURN
     END  
  ENDCASE 

  CASE dtype OF 
     0: IF (aflg) THEN dname = 'mvn_swe_engy_arc' ELSE dname = 'mvn_swe_engy'
     1: IF (aflg) THEN dname = 'mvn_swe_3d_arc' ELSE dname = 'mvn_swe_3d'
     2: IF (aflg) THEN dname = 'mvn_swe_pad_arc' ELSE dname = 'mvn_swe_pad'
  ENDCASE

  status = EXECUTE('dat = ' + dname)
  IF SIZE(dat, /type) NE 8 THEN BEGIN
     dprint, '', dlevel=1, verbose=verbose, /print_trace
     dprint, '  No ' + STRUPCASE(data_type) + ' ' + pname + ' L2 data. Try to search L0 data instead.', $
             print_trace=0, dlevel=1, verbose=verbose
     dprint, "  If you want to use L2 data, please use 'mvn_swe_load_l2' first.", print_trace=0, dlevel=2, verbose=verobse

     CASE dtype OF 
        0: IF (aflg) THEN dname = 'a5' ELSE dname = 'a4'
        1: IF (aflg) THEN dname = 'swe_3d_arc' ELSE dname = 'swe_3d'
        2: IF (aflg) THEN dname = 'a3' ELSE dname = 'a2'
     ENDCASE
     
     undefine, dat
     status = EXECUTE('dat = ' + dname)
     IF SIZE(dat, /type) NE 8 THEN BEGIN
        dprint, '', dlevel=1, verbose=verbose, /print_trace
        dprint, '  No ' + STRUPCASE(data_type) + ' ' + pname + ' L0 data.', print_trace=0, dlevel=1, verbose=verbose
        dprint, "  Use 'mvn_swe_load_l0' first.", print_trace=0, dlevel=2, verbose=verbose
        dprint, print_trace=1, dwait=10.
        RETURN     
     ENDIF 
  ENDIF
  undefine, status

  dprint, 'Uses SWEA ' + STRUPCASE(data_type) + ' ' + pname + ' data.', dlevel=1, verbose=verbose, /print_trace
  ndat = N_ELEMENTS(dat)
  IF SIZE(var, /type) NE 0 THEN BEGIN
     trange = var
     IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
  ENDIF ELSE BEGIN
     IF ~keyword_set(trange) THEN trange = minmax(dat.time) $
     ELSE trange = trange
  ENDELSE 
 
  IF N_ELEMENTS(trange) EQ 2 THEN BEGIN
     idx = WHERE(dat.time GE MIN(trange) AND dat.time LE MAX(trange), ndat)
     IF ndat EQ 0 THEN BEGIN
        PRINT, ptrace()
        PRINT, '  No data during the specified time you set.'
        RETURN
     ENDIF ELSE dat = dat[idx]
  ENDIF ELSE BEGIN
     PRINT, ptrace()
     PRINT, '  You must input 2 elements of the time interval.'
     RETURN
  ENDELSE  
  IF keyword_set(default) THEN mk = mvn_spice_kernels(/load, /all, trange=trange, verbose=verbose)
  IF keyword_set(aflg) THEN product = 'arc' ELSE product = 'svy'
  IF NOT keyword_set(units) THEN units = 'crate'
  CASE STRUPCASE(units) OF
     'COUNTS' : ztit = 'Counts [#]'                    ; Raw counts
     'RATE'   : ztit = 'Counts Rate!C[#/sec]'          ; Raw counts/sec
     'CRATE'  : ztit = 'Counts Rate!C[#/sec]'          ; Corrected counts/sec
     'EFLUX'  : ztit = 'EFlux!C[eV/cm!E2!N sec sr eV]' ; eV/cm^2-sec-sr-eV
     'FLUX'   : ztit = 'Flux!C[#/cm!E2!N sec sr eV]'   ; 1/cm^2-sec-sr-eV
     'DF'     : ztit = 'DF!C[cm!E-3!N(km/s)!E-3!N]'    ; 1/(cm^3-(km/s)^3)
     ELSE     : ztit = 'Unknown'
  ENDCASE

  oytit = 'SWEA (' + STRUPCASE(data_type) + ')!CEnergy [eV]'
  di = 0 ; For Default setting case
  IF dtype EQ 0 THEN BEGIN
     mvn_swe_convert_units, dat, units

     x = dat.time
     y = TRANSPOSE(dat.data)

     ;tmin = MIN(x, max=tmax)
     ;tsp = [tsp, tmin, tmax]

     v = swe_swp[*, 0]
  ENDIF ELSE BEGIN
     IF NOT keyword_set(default) THEN BEGIN
        ; theta (deflection angle or looking direction) selection
        IF keyword_set(thrange) THEN BEGIN
           IF N_ELEMENTS(thrange) LT 2 THEN BEGIN
              dprint, 'Error: theta keyword should have 2 elements.'
              RETURN
           ENDIF ELSE thrange = minmax(thrange)
           IF thrange[0] LT -90. || thrange[1] GT 90. THEN BEGIN
              dprint, 'Error: theta must be between -90 and 90 deg.'
              RETURN
           ENDIF 
        ENDIF ELSE thrange = [-90., 90.]
        ; phi (anode or looking direction) selection                                
        IF keyword_set(phrange) THEN BEGIN
           IF N_ELEMENTS(phrange) LT 2 THEN BEGIN
              dprint, 'Error: phi keyword should have 2 elements.'
              RETURN
           ENDIF ELSE phrange = minmax(phrange)
           IF phrange[0] LT 0. || phrange[1] GT 360. THEN BEGIN
              dprint, 'Error: phi must be between 0 and 360 deg.'
              RETURN
           ENDIF
        ENDIF ELSE phrange = [0., 360.] 
     ENDIF 

     IF NOT keyword_set(angle) THEN BEGIN
        IF NOT keyword_set(abins) THEN abins = REPLICATE(1., 16)
        IF NOT keyword_set(dbins) THEN dbins = REPLICATE(1., 6)
        obins = REFORM(abins # dbins, 96)
        i = WHERE(obins EQ 0., cnt)
        IF cnt GT 0 THEN obins[i] = nan
        undefine, i, cnt
        
        stow = INTARR(ndat)
        stow[*] = 0
        IF keyword_set(mask) THEN BEGIN
           mobins = FLTARR(96, 2)
           mdbins = [0., 0., 0., 1., 1., 1.]
           mabins = REPLICATE(1., 16)
           
           mobins[*, 1] = REFORM(mabins # mdbins, 96)
           mobins[*, 0] = 1.
           mobins[0:3, 0] = 0.
           mobins[16:19, 0] = 0.
           i = WHERE(dat.time LT t_mtx[2], cnt)
           IF cnt GT 0 THEN stow[i] = 1
           undefine, i, cnt
        ENDIF ELSE IF keyword_set(mbins) THEN BEGIN
           IF N_ELEMENTS(mbins) EQ 96 THEN mobins = mbins $
           ELSE BEGIN
              dprint, 'You should input 96 elements of array to mask.'
              mobins = REPLICATE(1., 96)
           ENDELSE 
        ENDIF ELSE mobins = REPLICATE(1., 96)
        i = WHERE(mobins EQ 0., cnt)
        IF cnt GT 0 THEN mobins[i] = nan
        undefine, i, cnt

        x = dat.time
        IF keyword_set(default) THEN suffix = ['sun', 'anti_sun', 'dusk', 'dawn', 'north', 'south']
        y = FLTARR(N_ELEMENTS(suffix), ndat, 64)
        y[*] = 0.
        v = y
        CASE dtype OF 
           1: BEGIN
              FOR i=0LL, ndat-1 DO BEGIN
                 j = 0
                 swe = mvn_swe_get3d(dat[i].time, unit=units, archive=aflg)
                 swe.data *= REBIN(TRANSPOSE(obins*mobins[*, stow[i]]), swe.nenergy, swe.nbins)
                 theta = swe.theta
                 phi = swe.phi
                 IF from NE to THEN mvn_swe_etspec_cotrans, swe, theta, phi, theta=theta, phi=phi, $
                    from=from, to=to

                 IF NOT keyword_set(default) THEN BEGIN
                    ibins = WHERE( (theta GE thrange[0] AND theta LE thrange[1]) $
                                   AND (phi GE phrange[0] AND phi LE phrange[1]), nibins)

                    IF nibins GT 0 THEN y[j, i, *] = TOTAL(swe.data[*, ibins], 2, /nan) $
                    ELSE y[j, i, *] = nan
                    v[j, i, *] = average(swe.energy, 2, /nan)
                 ENDIF ELSE mvn_swe_etspec_default, swe, theta, phi, units=units, y=y, v=v, index=i, suffix=suffix
                 undefine, swe, ibins, nibins, theta, phi
              ENDFOR
           END 
           2: BEGIN
              FOR i=0LL, ndat-1 DO BEGIN
                 j = 0
                 swe = mvn_swe_getpad(dat[i].time, unit=units, archive=aflg)
                 swe.data *= REBIN(TRANSPOSE(obins[swe.k3d]*mobins[swe.k3d, stow[i]]), swe.nenergy, swe.nbins)
                 theta = swe.theta
                 phi = swe.phi
                 IF from NE to THEN mvn_swe_etspec_cotrans, swe, theta, phi, theta=theta, phi=phi, from=from, to=to

                 IF NOT keyword_set(default) THEN BEGIN
                    ibins = WHERE( (theta GE thrange[0] AND theta LE thrange[1]) $
                                   AND (phi GE phrange[0] AND phi LE phrange[1]), nibins)
                    IF nibins GT 0 THEN y[j, i, *] = TOTAL(swe.data[*, ibins], 2, /nan) $
                    ELSE y[j, i, *] = nan
                    v[j, i, *] = average(swe.energy, 2, /nan)
                 ENDIF ELSE mvn_swe_etspec_default, swe, theta, phi, units=units, y=y, v=v, index=i, suffix=suffix 
                 undefine, swe, ibins, nibins
              ENDFOR
           END 
        ENDCASE 
     ENDIF ELSE BEGIN
        CASE angle OF
           'pa': BEGIN
              IF SIZE(swe_mag1, /type) NE 8 THEN BEGIN
                 print, ptrace()
                 print, '  No MAG1 data loaded.  Use mvn_swe_addmag first.'
                 RETURN
              ENDIF

              IF NOT keyword_set(default) THEN BEGIN
                 IF keyword_set(pitch) THEN BEGIN
                    IF N_ELEMENTS(pitch) LT 2 THEN BEGIN
                       dprint, 'Error: pitch keyword should have 2 elements.'
                       RETURN
                    ENDIF ELSE pitch = minmax(pitch) 
                    IF pitch[0] LT 0. || pitch[1] GT 180. THEN BEGIN
                       dprint, 'Error: pitch must be 0 and 180 deg.'
                       RETURN
                    ENDIF 
                 ENDIF 
              ENDIF  
              mvn_swe_pad_resample, trange, result=result, snap=0, tplot=0, mask=mask,  $
                                    abins=abins, dbins=dbins, mbins=mbins, nbins=nbins, $
                                    archive=aflg, map3d=2-dtype, verbose=verbose

              x = result.time
              default_loop_pa:
              IF keyword_set(default) THEN BEGIN
                 CASE di OF
                    0: BEGIN
                       pitch = [0., 30.]
                       suffix = 'para'
                    END 
                    1: BEGIN
                       pitch = [75., 105.]
                       suffix = 'perp'
                    END 
                    2: BEGIN
                       pitch = [150., 180.]
                       suffix = 'anti_para'
                    END 
                 ENDCASE
              ENDIF 
              idx = WHERE(result[0].xax GE pitch[0] AND result[0].xax LE pitch[1], nidx)

              IF nidx GT 0 THEN y = TRANSPOSE(average(result.avg[*, idx, *], 2, /nan)) $
              ELSE BEGIN
                 dprint, 'There is no data found in your specified pitch angle ranges.'
                 RETURN
              ENDELSE  
              v = swe_swp[*, 0]
           END
        ENDCASE
     ENDELSE 
  ENDELSE 
  
  emin = MIN(v, max=emax)
  tname = 'mvn_swe_et_' + data_type + '_' + product   
  IF suffix[0] NE '' THEN BEGIN
     ytit = oytit + '!C' + suffix
     tname += '_' + suffix 
  ENDIF ELSE ytit = oytit

  FOR i=0, N_ELEMENTS(suffix)-1 DO BEGIN
     IF (dtype GT 0) AND SIZE(y, /n_dimension) GT 2 THEN BEGIN
        ydata = REFORM(y[i, *, *])
        vdata = REFORM(v[i, *, *])
     ENDIF ELSE BEGIN
        ydata = y
        vdata = v
     ENDELSE 
     store_data, tname[i], data={x:x, y:ydata, v:vdata}, $
                 dl={spec: 1, ytitle: ytit[i], yticks: 0, $
                     yminor: 0, y_no_interp: 1, x_no_interp: 1, $
                     ztitle: ztit, datagap: 300}
     undefine, ydata, vdata
  ENDFOR 
  ylim, tname, emin, emax, 1, /def
  zlim, tname, 0, 0, 1, /def

  IF keyword_set(default) AND (di LT 2) THEN BEGIN
     di += 1
     undefine, y, v
     undefine, idx, nidx
     undefine, pitch, suffix
     IF keyword_set(angle) THEN IF angle EQ 'pa' THEN GOTO, default_loop_pa
  ENDIF 
  RETURN
END
