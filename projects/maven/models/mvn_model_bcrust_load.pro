;+
;
;PROCEDURE:       MVN_MODEL_BCRUST_LOAD
;
;PURPOSE:         Loads the Martian crustal magnetic field model(s) at
;                 the MAVEN location. It is a simple wrapper of
;                 'mvn_model_bcrust' and 'mvn_model_bcrust_restore'.
;
;INPUTS:          
;
;       TRANGE:   An array in any format accepted by time_double().
;                 The minimum and maximum values in this array specify
;                 the time range to load.
;
;KEYWORDS:
;
;        ORBIT:   Loads the Martian crustal magnetic field model(s) by orbit number
;                 or range of orbit numbers (trange is ignored). Orbits are numbered
;                 using the NAIF convention, where the orbit number increments
;                 at periapsis. Data are loaded from the apoapsis preceding
;                 the first orbit (periapsis) number to the apoapsis following
;                 the last orbit number.
;
; MORSCHHAUSER:   Loads Morschhauser's 2014 spherical harmonic model.
;                 (It is the default model to resotre).
;
;       ARKANI:   Loads Arkani-Hamed's spherical harmonic model.
;
;    CAIN_2003:   Loads Cain's 2003 spherical harmonic model.
;
;    CAIN_2011:   Loads Cain's 2011 spherical harmonic model.
;
;     PURUCKER:   Loads Purucker's spherical harmonic model.
;
;         CALC:   If there are no tplot save files to load, the Martian
;                 crustal magnetic field is calculated by 'mvn_model_bcrust'.
;
;       NOCALC:   If there are no tplot save files to load, then don't
;                 try to calculate them, and don't ask.  (Allows non-
;                 interactive calls.)  Takes precedence over CALC.
;
;       STATUS:   Returns the loading status:
;                 0 = Failure.
;                 1 = Success.
;
;RELATED ROUTINES:
;                 'mvn_model_bcrust', 'mvn_model_bcrust_restore'.
;
;CREATED BY:      Takuya Hara on 2015-02-18.
;
;LAST MODIFICATION:
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-17 09:05:18 -0800 (Tue, 17 Nov 2015) $
; $LastChangedRevision: 19384 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/models/mvn_model_bcrust_load.pro $
;
;-
PRO mvn_model_bcrust_load, var, orbit=orbit, silent=sl, verbose=vb, calc=calc, status=status, $
                           cain_2003=cain_2003, cain_2011=cain_2011, arkani=arkani, $
                           purucker=purucker, morschhauser=morschhauser, path=path, $
                           resolution=resolution, data=modelmag, nmax=nmax, version=version, $
                           nocalc=nocalc, _extra=ext

  IF SIZE(var, /type) NE 0 THEN BEGIN
     trange = time_double(var)
     IF N_ELEMENTS(trange) NE 2 THEN BEGIN
        dprint, 'The time range must be two elements array like [tmin, tmax].'
        RETURN
     ENDIF 
  ENDIF ELSE BEGIN
     IF keyword_set(orbit) THEN BEGIN
        imin = MIN(orbit, max=imax)
        trange = mvn_orbit_num(orbnum=[imin-0.5, imax+0.5])
        undefine, imin, imax
     ENDIF 
     
     tplot_options, get_opt=topt
     tspan_exists = (MAX(topt.trange_full) GT time_double('2014-09-22'))
     IF (tspan_exists) THEN trange = topt.trange_full
     undefine, topt, tspan_exists
  ENDELSE 

  IF SIZE(trange, /type) EQ 0 THEN BEGIN
     dprint, 'You must set the specified time interval to load.'
     RETURN
  ENDIF
 
  IF keyword_set(sl) THEN silent = sl ELSE silent = 0
  IF keyword_set(vb) THEN verbose = vb ELSE verbose = 0
  verbose -= silent 
  IF keyword_set(calc) THEN cflg = 1 ELSE cflg = 0
  IF keyword_set(nocalc) THEN cflg = -1

  mvn_model_bcrust_restore, trange, silent=silent, verbose=verbose, status=status,  $
                            cain_2003=cain_2003, cain_2011=cain_2011, arkani=arkani, $
                            purucker=purucker, morschhauser=morschhauser
  
  IF status EQ 0 THEN BEGIN
     CASE (cflg) OF
       1 : yes = 1
       0 : BEGIN
             PRINT, ptrace()
             PRINT, '  It seems that the tplot save files have not been generated yet.' 
             result = EXECUTE("READ,  '  Do you want to calculate now (Yes=1 / No=0)?: ', yes ")
             IF result EQ 0 THEN yes = 0
           END
       ELSE : yes = 0
     ENDCASE

     IF yes EQ 1 THEN BEGIN
        IF SIZE(morschhauser, /type) EQ 0 THEN morschhauser = 1
        dotplot = INTARR(5)
        dotplot[*] = 0
        dotplot[0] = keyword_set(morschhauser)
        dotplot[1] = keyword_set(cain_2003)
        dotplot[2] = keyword_set(cain_2011)
        dotplot[3] = keyword_set(arkani)
        dotplot[4] = keyword_set(purucker)
        IF TOTAL(dotplot) EQ 1 THEN suffix = ''
        tname = 'mvn_model_bcrust'
        nname = 'mvn_mod_bcrust'
        modeler = ['morschhauser', 'cain_2003', 'cain_2011', 'arkani', 'purucker']
        suffixes = ['_m', '_c03', '_c11', '_a', '_p']

        FOR i=0, 4 DO BEGIN
           IF (dotplot[i]) THEN BEGIN
              CASE i OF
                 0: mor = 1
                 1: c03 = 1
                 2: c11 = 1
                 3: ark = 1
                 4: pur = 1
              ENDCASE 

              mvn_model_bcrust, trange, resolution=resolution, data=modelmag, $
                                silent=silent, verbose=verbose, $
                                arkani=ark, purucker=pur, /tplot,     $
                                cain_2003=c03, cain_2011=c11,     $
                                version=version, morschhauser=mor, _extra=ext
              
              IF SIZE(suffix, /type) NE 0 THEN suf = suffix ELSE suf = suffixes[i]
              store_data, tname + '_geo_' + modeler[i], /delete, verbose=verbose
              store_data, tname + '_amp_' + modeler[i], newname=nname + '_amp' + suf
              store_data, tname + '_mso_' + modeler[i], newname=nname + '_mso' + suf
              options, nname + ['_amp' , '_mso'] + suf, ytitle='Model'
              IF SIZE(suffix, /type) NE 0 THEN BEGIN
                 status = 1
                 RETURN
              ENDIF 
              undefine, suf
              undefine, mor, c03, c11, ark, pur
           ENDIF 
        ENDFOR 
        status = 1
     ENDIF   
  ENDIF    
  RETURN
END
