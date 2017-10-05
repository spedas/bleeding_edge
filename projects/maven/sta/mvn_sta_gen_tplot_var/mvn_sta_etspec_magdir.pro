;+
;
;PROCEDURE:       MVN_STA_ETSPEC_MAGDIR
;
;PURPOSE:         Makes directional energy-time spectrogram in the
;                 specified pitch angle range from STATIC 4d data.
;
;INPUTS:          None. 
;                 (STATIC data should have been loaded and MAG data
;                 should have been also inserted into the STATIC
;                 common blocks by 'mvn_sta_mag_load' before using
;                 this routine.
;
;KEYWORDS:        (All keywords are optional.)
;
;   APID:         Not necessary, but you can explicitly specify the
;                 STATIC APID to use. Default is "d0".
;
;   PITCH:        Specifies the pitch angle range (Def: [0., 30.]).
;
;   UNITS:        Specifies the units ('eflux', 'counts', etc.).
;                 (Def: 'eflux')
;
;   TRANGE:       Time range to compute directional spectra (Def: all).
;
;   MASS:         Specifies mass per charge ranges which you want to use.
;                 Default is All mass range.
;
;   SUFFIX:       Defines a suffix of the created tplot variable name 
;                 (Def: e.g., '_ms012-020_pa000-030').
;
;NOTE:            This routine is based on 'mvn_swia_diretmag' written
;                 by Dr. Yuki Harada.  
;
;CREATED BY:      Takuya Hara on 2015-01-21.
;
; $LastChangedBy: hara $
; $LastChangedDate: 2015-03-04 06:51:10 -0800 (Wed, 04 Mar 2015) $
; $LastChangedRevision: 17086 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_tplot_var/mvn_sta_etspec_magdir.pro $
;
;-
PRO mvn_sta_etspec_magdir, apid, pitch=pad, units=units, trange=trange, $
                           mass=mrange, suffix=suffix, verbose=verbose, _extra=extra
  nan = !values.f_nan
  IF ~keyword_set(verbose) THEN v = 1 ELSE v = verbose
  IF ~keyword_set(apid) THEN apid = 'd0'
  IF ~keyword_set(pad) THEN pitch = [0., 30.] ELSE pitch = minmax(ABS(pad))
  IF ~keyword_set(units) THEN units = 'eflux'
  IF ~keyword_set(mrange) THEN mass = [1.d-3, 1.d2] ELSE mass = minmax(mrange)
  IF ~keyword_set(suffix) THEN BEGIN
     suffix = '_ms'
     IF ~keyword_set(mrange) THEN suffix += 'all' ELSE $
        suffix += STRING(mass[0], '(I3.3)') + '-' + STRING(mass[1], '(I3.3)')
     suffix += '_pa' + STRING(pitch[0], '(I3.3)') + '-' + STRING(pitch[1], '(I3.3)')
  ENDIF 
  fname = 'mvn_sta_get_' + apid
  time = CALL_FUNCTION(fname, /times)
  IF keyword_set(trange) THEN BEGIN
     idx = WHERE(time GE trange[0] AND time LE trange[1], nidx)
     IF nidx GT 0 THEN time = time[idx] $
     ELSE BEGIN
        dprint, dlevel=1, verbose=verbose, 'No data in the specified time range.'
        RETURN
     ENDELSE 
     undefine, idx, nidx
  ENDIF 
  center_time = DBLARR(N_ELEMENTS(time))
  fifb = STRING("15b) ;"
  FOR i=0LL, N_ELEMENTS(time)-1 DO BEGIN ;- time loop
     d = CALL_FUNCTION(fname, time[i])
     d = conv_units(d, units)
     center_time[i] = (d.time+d.end_time)/2.d

     IF i EQ 0LL THEN BEGIN
        energy = FLTARR(N_ELEMENTS(time), d.nenergy)
        eflux_dir = FLTARR(N_ELEMENTS(time), d.nenergy)
     ENDIF 

     idx = WHERE(d.mass_arr LT mass[0] OR d.mass_arr GT mass[1], nidx)
     IF nidx GT 0 THEN d.data[idx] = 0.
     undefine, idx, nidx
     
     energy[i, *] = average(average(d.energy, 3), 2)
     xyz_to_polar, d.magf, theta=bth, phi=bph
     pa = pangle(d.theta, d.phi, bth, bph)
     undefine, bth, pth

     IF ((i MOD 100) EQ 0) OR (i EQ N_ELEMENTS(time)-1) THEN $
        IF v GE 1 THEN BEGIN $
        num = i
        IF i EQ N_ELEMENTS(time)-1 THEN num += 1
        PRINT, format='(a, a, a, a, a, a, $)', $
               '      ', fifb, ptrace(), STRING(num), ' /', STRING(N_ELEMENTS(time))
     ENDIF

     idx = WHERE(pa GT pitch[0] AND pa LT pitch[1], nidx)
     IF nidx GT 0 THEN BEGIN
        w = d.data * 0.
        w[idx] = 1.
        IF STRLOWCASE(units) NE 'counts' THEN $
           eflux_dir[i, *] = TOTAL( TOTAL( (d.data*d.domega*w), 3), 2) $
                             / TOTAL(TOTAL((d.domega*w), 3), 2) $
        ELSE eflux_dir[i, *] = TOTAL(TOTAL((d.data*w), 3), 2)
     ENDIF ELSE eflux_dir[i, *] = nan 
     undefine, pa, idx, nidx, w
     IF v GE 1 AND i EQ N_ELEMENTS(time)-1 THEN PRINT, ' '
  ENDFOR                         ;- time loop end

  ytit = 'STA ' + STRUPCASE(apid) + '!C' + $
         'PA: [' + STRING(pitch[0], '(I0)') + ', ' + STRING(pitch[1], '(I0)') + ']'
  ztit = units + '!CM/Q: ' 
  IF ~keyword_set(mrange) THEN ztit += 'All' ELSE $
     ztit += '[' + STRING(mass[0], '(I0)') + ', ' + STRING(mass[1], '(I0)') + ']'
  store_data, 'mvn_sta_' + apid + '_en_' + units + suffix, $
              data={x: center_time, y: eflux_dir, v: energy}, $
              dlim={spec: 1, zlog: 1, ylog: 1, yrange: minmax(energy), $
                    ystyle: 1, ytitle: ytit, ysubtitle:'Energy [eV]', $
                    ztitle: ztit, datagap: 600.}, verbose=verbose
  RETURN 
END 
