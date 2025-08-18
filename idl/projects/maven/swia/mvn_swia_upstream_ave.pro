;+
;
;PROCEDURE:       MVN_SWIA_UPSTREAM_AVE
;
;PURPOSE:         Calculates average and standard deviations for any
;                 specific quantity over upstream solar wind intervals.
;
;INPUTS:          Tplot names (or indices) to compute.
;
;KEYWORDS:
;       
;     REGID:      Region structure computed by 'mvn_swia_regid'.
;                 This keyword is essential to execute this procedure.
;
;       NPO:      Number of determinations per orbit.
;                 Default = 1.
;
;     MINPO:      Minimum data points during intervals to compute average
;                 and standard deviations. Default = 10.
;
;   NEWNAME:      Tplot names computed average and standard deviations.
;                 Default is 'original tplot name' + '_upstream_ave'.
;
; OVERWRITE:      Overwrites the results into the input tplot(s).
;
;    LIMITS:      A structure containing new limits for tplot options.
;                 Please use this keywords as 'options' for tplot packages.
;
;CREATED BY:      Takuya Hara on 2015-04-24.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2015-04-26 14:15:24 -0700 (Sun, 26 Apr 2015) $
; $LastChangedRevision: 17430 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_upstream_ave.pro $
;
;-
PRO mvn_swia_upstream_ave, tvar, regid=reg, npo=npo, minpo=mpo, newname=nname, $
                           overwrite=over, limits=nlim, verbose=verbose

  IF SIZE(tvar, /type) NE 0 THEN BEGIN
     ntplot = N_ELEMENTS(tvar)
     tname = STRARR(ntplot)
     FOR i=0L, ntplot-1L DO tname[i] = tnames(tvar[i])
  ENDIF ELSE BEGIN
     dprint, 'Tplot names or indices must be input in this procedure.', dlevel=2, verbose=verbose
     RETURN
  ENDELSE 
  IF SIZE(reg, /type) NE 8 THEN BEGIN
     dprint, "No region ID data found. Uses 'mvn_swia_regid' at first.", dlevel=2, verbose=verbose
     RETURN
  ENDIF 

  IF ~keyword_set(npo) THEN npo = 1
  IF ~keyword_set(mpo) THEN mpo = 10
  IF keyword_set(nname) THEN BEGIN
     IF N_ELEMENTS(nname) NE ntplot THEN BEGIN
        dprint, 'New names must have same elements to input tplot names.', dlevel=2, verbose=verbose
        RETURN
     ENDIF
  ENDIF 
  IF keyword_set(over) THEN oflg = 1 ELSE oflg = 0
  
  FOR i=0L, ntplot-1L DO BEGIN
     get_data, tname[i], data=d, dlim=dl, lim=lim

     ureg = INTERPOL(reg.y[*, 0], reg.x, d.x)
     idx = WHERE(ureg EQ 1, ndat)
     IF ndat GT 0 THEN BEGIN
        tin = d.x[idx]
        yin = d.y[idx, *]
        ncomp = N_ELEMENTS(d.y[0, *])

        orb = mvn_orbit_num(time=tin)
        orb = FLOOR(orb*npo)
        mino = MIN(orb, max=maxo)
        norb = maxo - mino + 1L

        undefine, idx
        tout = DBLARR(norb)
        yout = DBLARR(norb, ncomp)
        dout = DBLARR(norb, ncomp)
        FOR j=0L, norb-1L DO BEGIN
           idx = WHERE(orb EQ (mino+j), ndat)
           IF ndat GT mpo THEN BEGIN
              yout[j, *] = average(yin[idx, *], 1, stdev=dev, /nan)
              dout[j, *] = dev
              undefine, dev
              tout[j] = MEAN(tin[idx], /double, /nan)
           ENDIF
           undefine, idx, ndat
        ENDFOR 
        undefine, j
     
        idx = WHERE(tout NE 0.d)
        IF SIZE(nname, /type) NE 0 THEN name = nname[i] $
        ELSE IF (oflg) THEN name = tname[i] ELSE name = tname[i] + '_upstream_ave'
        
        IF SIZE(nlim, /type) EQ 8 THEN extract_tags, lim, nlim
        store_data, name, data={x: tout[idx], y: yout[idx, *], dy: dout[idx, *]}, dlim=dl, lim=lim, verbose=verbose
        
        undefine, name, idx, ndat
        undefine, tout, yout, dout
        undefine, orb, mino, maxo, norb
        undefine, tin, yin, ncomp
     ENDIF ELSE $
        dprint, "'" + tname[i] + "'" + ' does not have data in the upstream solar wind region.', dlevel=2, verbose=verbose
     undefine, idx, ndat, ureg
     undefine, d, dl, lim
  ENDFOR 
  RETURN
END
