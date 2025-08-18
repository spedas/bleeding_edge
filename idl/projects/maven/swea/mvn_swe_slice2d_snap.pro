;+
;
;PROCEDURE:       MVN_SWE_SLICE2D_SNAP
;
;PURPOSE:         Plots 2D slice for the times and data type selected by cursor.
;                 Hold down the left mouse button and slide for a movie effect. 
;                 
;INPUTS:          None.
;                 But the specified time (or [tmin, tmax]) is set, it
;                 automatically show the snapshot. In this case, the
;                 cursor does not appear in a tplot window.
;
;CAUTION:         *** !!! ***
;                 The velocity estimated from the SWEA electron 3D data
;                 via 'v_3d' is not likely reliable. 
;                 Highly recommended to use the bulk velocity
;                 estimated from the other data (e.g., SWIA ion data). 
;                 *** !!! ***
;
;KEYWORDS:        All the keywords included in 'slice2d' are acceptable. 
;
;   ARCHIVE:      Returns archive distribution instead of survey.
;
;     BURST:      Synonym for "ARCHIVE".
;   
;    WINDOW:      Specifies window number to plot.
;                 A new window to show is generated as default.
;   
;     BLINE:      Shows magnetic field direction by a black solid line.
;
;       MSO:      Rotates into the MSO coordinates (no effect on 'BV',
;                 'BE', and 'perp' cuts). 
;
;     ABINS:      Specifies which azimuth anode bins to
;                 include in the analysis: 0 = no, 1 = yes.
;                 Default = replicate(1, 16)
;
;     DBINS:      Specifies which deflection bins to
;                 include in the analysis: 0 = no, 1 = yes.
;                 Default = replicate(1, 6).
;
;     OBINS:      Specifies which angular bins to inclue in the
;                 analysis: 0 = no, 1 = yes. Default = replicate(1, 96).
;
;   MASK_SC:      Mask solid angle bins that are blocked by the spacecraft.
;                 Default = 1
;
;   KEEPWIN:      If set, then don't close the snapshot window on exit.
;
;       SUM:      If set, use cursor to specify time ranges for averaging.
;
;USAGE EXAMPLES:
;         1.      ; Normal case
;                 ; Uses archive data, and shows the B field direction.
;                 ; Draws the X-Y plane slice in the SWEA coordinates.
;   
;                 mvn_swe_slice2d_snap, /arc, /bline, rot='xy'
;
;         2.      ; Specified time case
;                 ; Selects the time to show.
;
;                 ctime, t ; Clicks once or twice on the tplot window.
;
;                 ; Draws the electron velocity distribution
;                 ; function in the plane perpendicular to the B field.   
;
;                 mvn_swe_slice2d_snap, t, rot='perp' 
;
;         3.      ; Advanced case
;                 ; Uses 'ctime' procedure with "routine" keyword.
;
;                 ctime, routine='mvn_swe_slice2d_snap'
;
;CREATED BY:      Takuya Hara on 2015-07-13.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2015-07-17 14:34:02 -0700 (Fri, 17 Jul 2015) $
; $LastChangedRevision: 18173 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_slice2d_snap.pro $
;
;-
PRO mvn_swe_slice2d_snap, var1, var2, archive=archive, window=window, mso=mso, _extra=_extra,    $
                          bline=bline, abins=abins, dbins=dbins, obins=obins, mask_sc=mask_sc,   $
                          verbose=verbose, keepwin=keepwin, charsize=chsz, sum=sum, burst=burst, vel=vel
  
  @mvn_swe_com
  tplot_options, get_option=topt
  dsize = GET_SCREEN_SIZE()
  IF SIZE(var2, /type) NE 0 THEN BEGIN
     keepwin = 1
     str_element, _extra, 'rot', 'BE', /add_replace
     str_element, _extra, 'showdata', 1, /add_replace
     window = topt.window + 1 
  ENDIF 
  IF SIZE(var1, /type) NE 0 AND SIZE(var2, /type) EQ 0 THEN var2 = var1
  IF SIZE(var2, /type) NE 0 THEN trange = time_double(var2)

  IF keyword_set(window) THEN wnum = window ELSE BEGIN
     WINDOW, /free, xsize=dsize[0]/2., ysize=dsize[1]*2./3., xpos=0., ypos=0.
     wnum = !d.window
  ENDELSE 
  ochsz = !p.charsize
  IF keyword_set(chsz) THEN !p.charsize = chsz
  IF keyword_set(archive) THEN aflg = 1
  IF keyword_set(burst) THEN aflg = 1
  IF SIZE(aflg, /type) EQ 0 THEN aflg = 0

  IF (N_ELEMENTS(abins) NE 16) THEN abins = REPLICATE(1B, 16)
  IF (N_ELEMENTS(dbins) NE  6) THEN dbins = REPLICATE(1B, 6)
  IF (N_ELEMENTS(abins) NE 96) THEN BEGIN
     obins = REPLICATE(1B, 96, 2)
     obins[*, 0] = REFORM(abins # dbins, 96)
     obins[*, 1] = obins[*, 0]
  ENDIF ELSE obins = BYTE(obins # [1B, 1B])
  IF (SIZE(mask_sc, /type) EQ 0) THEN mask_sc = 1
  IF keyword_set(mask_sc) THEN obins = swe_sc_mask * obins
  
  omask = REPLICATE(1., 96, 2)
  omask1 = omask
  idx = WHERE(obins EQ 0B, count)
  IF (count GT 0L) THEN BEGIN
     omask[idx] = !values.f_nan
     omask1[idx] = 0.
  ENDIF 
  omask = REFORM(REPLICATE(1.,64) # REFORM(omask, 96*2), 64, 96, 2)
  omask1 = REFORM(REPLICATE(1.,64) # REFORM(omask1, 96*2), 64, 96, 2)
  undefine, idx, count

  IF SIZE(trange, /type) NE 0 THEN IF N_ELEMENTS(trange) GT 1 THEN sum = 1
  IF keyword_set(sum) THEN npts = 2 ELSE npts = 1

  IF SIZE(var1, /type) EQ 0 THEN $
     dprint, 'Uses button 1 to select time: botton 3 to quit.', dlevel=2, verbose=verbose
  IF SIZE(var2, /type) EQ 0 THEN ctime, trange, npoints=npts, /silent

  ok = 1
  WHILE (ok) DO BEGIN
     ddd = mvn_swe_get3d(trange, archive=aflg, all=doall, /sum)
     IF (SIZE(ddd, /type) EQ 8) THEN BEGIN
        str_element, ddd, 'bins', REPLICATE(1L, [ddd.nenergy, ddd.nbins]), /add
        IF (ddd.time GT t_mtx[2]) THEN boom = 1 ELSE boom = 0
        data = ddd.data
        idx = WHERE(~FINITE(ddd.data), count)
        IF count GT 0 THEN ddd.data[idx] = 0.
        undefine, idx, count
        ddd.data = ddd.data * omask1[*, *, boom]
        vel = v_3d(ddd) ; ! Causion ! This estimated velocity is not reliable.
        ddd.data = data * omask[*, *, boom]
        
        IF keyword_set(mso) THEN BEGIN
           mvn_pfp_cotrans, ddd, from='MAVEN_SWEA', to='MAVEN_MSO', /overwrite
           bnew = spice_vector_rotate(ddd.magf, (ddd.time+ddd.end_time)/2.d, 'MAVEN_SWEA', 'MAVEN_MSO', check='MAVEN_SPACECRAFT', verbose=verbose)
           str_element, ddd, 'magf', bnew, /add_replace
        ENDIF 
        IF keyword_set(bline) THEN bdir = ddd.magf/SQRT(TOTAL(ddd.magf*ddd.magf))

        wset, wnum
        status = EXECUTE("slice2d, ddd, _extra=_extra, sundir=bdir, vel=vel")
        undefine, status
        undefine, ddd, data, boom
        undefine, bnew, bdir, vel
     ENDIF ELSE dprint, 'Click again.', dlevel=2, verbose=verbose
     
     IF SIZE(var2, /type) EQ 0 THEN BEGIN
        ctime, trange, npoints=npts, /silent
        IF (SIZE(trange, /type) EQ 5) THEN ok = 1 ELSE ok = 0
     ENDIF ELSE ok = 0
     undefine, ddd
  ENDWHILE 
  IF ~keyword_set(keepwin) THEN wdelete, wnum
  !p.charsize = ochsz
  RETURN
END 
