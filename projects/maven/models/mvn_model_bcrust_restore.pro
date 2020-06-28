;+
;
;PROCEDURE:       MVN_MODEL_BCRUST_RESTORE
;
;PURPOSE:         Restores tplot save file(s) associated with the
;                 Martian crustal magnetic field model(s).
;
;INPUTS:          
;
;       TRANGE:   Restores tplot save files spanning this time range.
;
;KEYWORDS:
;
;        ORBIT:   Restores tplot save files by orbit number or range
;                 of orbit numbers (trange is ignored). Orbits are numbered
;                 using the NAIF convention, where the orbit number increments
;                 at periapsis. Data are loaded from the apoapsis preceding
;                 the first orbit (periapsis) number to the apoapsis following
;                 the last orbit number.
;
; MORSCHHAUSER:   Restores Morschhauser's 2014 spherical harmonic model.
;                 (It is the default model to resotre).
;
;       ARKANI:   Restores Arkani-Hamed's spherical harmonic model.
;
;    CAIN_2003:   Restores Cain's 2003 spherical harmonic model.
;
;    CAIN_2011:   Restores Cain's 2011 spherical harmonic model.
;
;     PURUCKER:   Restores Purucker's spherical harmonic model.
;
;     LANGLAIS:   Restores Langlais's 2019 spherical harmonic model.
;
;CREATED BY:      Takuya Hara on 2015-02-18.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2020-06-26 22:07:05 -0700 (Fri, 26 Jun 2020) $
; $LastChangedRevision: 28820 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/models/mvn_model_bcrust_restore.pro $
;
;-
PRO mvn_model_bcrust_restore, var, orbit=orbit, silent=sl, verbose=vb, status=status,  $
                              cain_2003=cain_2003, cain_2011=cain_2011, arkani=arkani, $
                              purucker=purucker, morschhauser=morschhauser, path=path, langlais=langlais

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

  IF ~keyword_set(path) THEN $
     path = 'maven/data/mod/bcrust/YYYY/MM/'
  fname = 'mvn_mod_bcrust_YYYYMMDD.tplot'
  
  file = mvn_pfp_file_retrieve(path+fname, trange=trange, /daily_names, /valid)
  
  idx = WHERE(file NE '', ndat)
  IF ndat EQ 0 THEN BEGIN
     dprint, 'No tplot save files found.'
     status = 0
     RETURN
  ENDIF ELSE status = 1
  undefine, idx

  IF SIZE(morschhauser, /type) EQ 0 THEN morschhauser = 1 $
  ELSE IF morschhauser NE 0 THEN morschhauser = 1

  nmod =  ( KEYWORD_SET(cain_2003) + KEYWORD_SET(cain_2011) + KEYWORD_SET(purucker) + $
            KEYWORD_SET(arkani) + KEYWORD_SET(morschhauser) + KEYWORD_SET(langlais) )
  IF nmod EQ 1 THEN suffix = ''

  dotplot = INTARR(6)
  dotplot[*] = 0
  dotplot[0] = keyword_set(morschhauser)
  dotplot[1] = keyword_set(cain_2003)
  dotplot[2] = keyword_set(cain_2011)
  dotplot[3] = keyword_set(arkani)
  dotplot[4] = keyword_set(purucker)
  dotplot[5] = keyword_set(langlais)

  tplot_restore, filename=file, /append

  tname = 'mvn_mod_bcrust'
  modeler = [ 'Morschhauser', $
              'Cain (2003)' , $
              'Cain (2011)' , $
              'Arkani',       $
              'Purucker',     $
              'Langlais'      ]

  modelers = ['morschhauser', 'cain_2003', 'cain_2011', 'arkani', 'purucker', 'langlais'] 
  suffixes = ['_m', '_c03', '_c11', '_a', '_p', '_l']

  FOR i=0, N_ELEMENTS(dotplot)-1 DO BEGIN
     IF dotplot[i] THEN BEGIN
        get_data, 'mvn_model_bcrust_mso_' + modelers[i], time, bmso, dlim=dlim, index=index

        IF index EQ 0 THEN BEGIN
           dprint, modeler[i] + ' crustal B field model is not available yet.', dlevel=0, verbose=verbose
           CONTINUE
        ENDIF 

        bmso = bmso[UNIQ(time, SORT(time)), *]
        time = time[UNIQ(time, SORT(time))]
        
        idx = WHERE(time GE trange[0] AND time LE trange[1], cnt)
        IF cnt GT 0 THEN BEGIN
           bmso = bmso[idx, *]
           time = time[idx]
           IF SIZE(suffix, /type) NE 0 THEN suf = suffix ELSE suf = suffixes[i]
           store_data, tname + '_mso' + suf, data={x: time, y: bmso}, dlimits=dlim, lim={ytitle: 'Model'}
           store_data, tname + '_amp' + suf, data={x: time, y: SQRT(TOTAL(bmso*bmso, 2))}, $
                       dlimits={ytitle: modeler[i], ysubtitle: '|B| [nT]'}, limits={ytitle: 'Model'}
           
           IF SIZE(suffix, /type) NE 0 THEN BREAK 
        ENDIF 
        undefine, idx, cnt
        undefine, time, bmso, dlim        
     ENDIF 
  ENDFOR 

  store_data, tnames('mvn_model_bcrust_mso_*'), /delete, verbose=verbose
  RETURN
END
