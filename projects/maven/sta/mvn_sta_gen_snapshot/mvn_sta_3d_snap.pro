;+
;
;PROCEDURE:       MVN_STA_3D_SNAP
;
;PURPOSE:         Plots 3D (angular) snapshots in a separate window
;                 for times selected with the cursor in a tplot window.
;                 Hold down the left mouse button and slide for a movie effect.
;                 This version uses 'plot3d' (or 'spec3d') on packaged 3D data.
;
;INPUTS:          None. 
;                 But the specified time (or [tmin, tmax]) is set, it
;                 automatically show the snapshot. In this case, the
;                 cursor does not appear in a tplot window. 
;
;KEYWORDS:
;
;   EBINS:        Energy bins to plot (passed to plot3d). 
;                 Default = ddd.nenergy.
;
;   CENTER:       Longitude and latitude of the center [lon, lat].
;
;   MAP:          Mapping projection. See 'plot3d_options' for details.
;
;   SPEC:         Plots energy spectra using 'spec3d'.
;                 (Not working yet.)
;
;   UNITS:        Units for the 'spec3d'.
;                 (Not working yet.)
;
;   ENERGY:       One or more energies to plot.  Overrides "EBINS".
;
;   DDD:          Named variable to hold a 3D structure including mass
;                 at the last time selected.
;
;   SUM:          If set, use cursor to specify time ranges for averaging.
;
;   SMO:          Sets smoothing in energy and angle.  Since there are only
;                 4 theta bins depending APIDs, smoothing in that dimension is not recommended.
;
;                 smo = [n_energy, n_phi, n_theta]  ; default = [1,1,1]
;
;                 This routine takes into account the 360-0 degree wrap when 
;                 smoothing (But not working yet).
;
;   SUNDIR:       Plots the direction of the Sun in STATIC coordinates.
;                 (Not working yet.)
;
;   LABEL:        If set, label the 3D angle bins.
;
;   KEEPWINS:     If set, then don't close the snapshot window(s) on exit.
;
;   ARCHIVE:      If set, show snapshots of archive data.
;
;   BURST:        Synonym for "ARCHIVE".
;
;   MASK_SC:      Masks solid angle bins that are blocked by the spacecraft.
;                 (Not working yet.)
;
;   MASS:         Selects ion mass/charge range to show. Default is all.
;
;   MMIN:         Defines the minimum ion mass/charge to use.
; 
;   MMAX:         Defines the maximum ion mass/charge to use.
;
;   M_INT:        Assumes ion mass/charge. Default = 1.
;
;   ERANGE:       If set, plots energy ranges for averaging.
;
;   WINDOW:       Sets the window number to show. Default = 0.
;
;   MSODIR:       Plots the direction of the MSO axes in STATIC coordinates. 
;
;   APPDIR:       Plots the direction of the APP boom in STATIC coordinates.  
;
;   APID:         If set, specifies the APID data product to use. 
;
;   PLOT_SC:      Overplots the projection of the spacecraft body.
;
;   SWIA:         Overplots the SWIA FOV in STATIC coordidates in
;                 order to make sure the FOV overlap each other.
;
;   ZLOG:         Sets a logarithmic color bar scaling. 
;
;   CT:           Sets a color table number based on 'loadct2'.
;                 Default is 34 (Rainbow).
;
;NOTE:            This routine is written based on partially 'swe_3d_snap'
;                 created by Dave Mitchell.
;
;USAGE EXAMPLES: 
;                 1.
;                 mvn_sta_3d_snap, erange=[0.1, 1.d4], wi=1, /mso, /app, /label, /plot_sc
;
;                 2.
;                 ctime, t ; Clicks once or twice on the tplot window.
;                 mvn_sta_3d_snap, t, erange=[0.1, 1.d4], wi=1, /mso, /app, /label, /plot_sc
;
;                 3.
;                 ctime, routine='mvn_sta_3d_snap'
;
;CREATED BY:      Takuya Hara on  2015-02-11.
;
; $LastChangedBy: hara $
; $LastChangedDate: 2015-08-20 16:43:03 -0700 (Thu, 20 Aug 2015) $
; $LastChangedRevision: 18552 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/mvn_sta_3d_snap.pro $
;
;-

;sub program
FUNCTION mvn_sta_3d_snap_exponent, axis, index, number
  times = 'x'
  ;; A special case.
  IF number EQ 0 THEN RETURN, '0'
  
  ;; Assuming multiples of 10 with format.
  ex = STRING(number, format='(e8.0)')
  pt = STRPOS(ex, '.')

  first = STRMID(ex, 0, pt)
  sign  = STRMID(ex, pt+2, 1)
  thisExponent = STRMID(ex, pt+3)

  ;; Shave off leading zero in exponent
  WHILE STRMID(thisExponent, 0, 1) EQ '0' DO thisExponent = STRMID(thisExponent, 1)

  ;; Fix for sign and missing zero problem.
  IF (Long(thisExponent) EQ 0) THEN BEGIN
     sign = ''
     thisExponent = '0'
  ENDIF

  IF (first EQ '  1') OR (first EQ ' 1') THEN BEGIN
     first = ''
     times = ''
  ENDIF
  ;; Make the exponent a superscript.
  IF sign EQ '-' THEN BEGIN
     RETURN, first + times + '10!U' + sign + thisExponent + '!N'
  ENDIF ELSE BEGIN
     RETURN, first + times + '10!U' + thisExponent + '!N'
  ENDELSE
END
;main program
PRO mvn_sta_3d_snap, var1, var2, spec=spec, keepwins=keepwins, archive=archive, ebins=ebins,  $
                     center=center, units=units, ddd=ddd, sum=sum, energy=energy, $
                     label=label, smo=smo, sundir=sundir, map=map, $
                     abins=abins, dbins=dbins, obins=obins, mask_sc=mask_sc, burst=burst, $
                     mass=mass, m_int=mq, erange=erange, window=window, msodir=mso, apid=id, $
                     appdir=app, mmin=mmin, mmax=mmax, plot_sc=plot_sc, swia=swia, $
                     _extra=extra, $ ; for 'plot3d_new' options.
                     zlog=zlog, zrange=zrange, unnormalize=unnormalize, ct=ct

  COMMON mvn_c6
  tplot_options, get_option=topt
  except = !except
  IF SIZE(var1, /type) NE 0 AND SIZE(var2, /type) EQ 0 THEN var2 = var1
  IF SIZE(var2, /type) NE 0 THEN BEGIN
     trange = time_double(var2)
     IF SIZE(window, /type) EQ 0 THEN $
        IF !d.window EQ topt.window THEN window = !d.window + 1 ELSE window = !d.window
     IF compare_struct(var1, var2) EQ 0 THEN BEGIN
        IF SIZE(mso, /type) EQ 0 THEN mso = 1
        IF SIZE(app, /type) EQ 0 THEN app = 1
        IF SIZE(plot_sc, /type) EQ 0 THEN plot_sc = 1
        IF SIZE(label, /type) EQ 0 THEN label = 1
        IF SIZE(erange, /type) EQ 0 THEN erange = [0.01, 40.d3] ; whole energy range
     ENDIF 
  ENDIF 
  IF keyword_set(archive) THEN aflg = 1 ELSE aflg = 0
  IF keyword_set(burst) THEN aflg = 1
  IF keyword_set(energy) THEN e1flg = 1 ELSE e1flg = 0
  IF keyword_set(erange) THEN e2flg = 1 ELSE e2flg = 0
  IF keyword_set(zrange) THEN unnormalize = 1
  IF keyword_set(unnormalize) THEN BEGIN
     nocolorbar = 1
     IF SIZE(zlog, /type) EQ 0 THEN zlog = 1
  ENDIF 
  IF ~keyword_set(ct) THEN ct = 34
  IF (SIZE(units, /type) NE 7) THEN units = 'crate'
  IF (SIZE(map, /type) NE 7) THEN map = 'ait'
  IF keyword_set(mass) THEN mmin = MIN(mass, max=mmax)
  IF keyword_set(mmin) AND ~keyword_set(mmax) THEN mtit = STRING(mmin, '(F0.1)') + ' < m/q'
  IF keyword_set(mmax) AND ~keyword_set(mmin) THEN mtit = 'm/q < ' + STRING(mmax, '(F0.1)')
  IF keyword_set(mmin) AND  keyword_set(mmax) THEN mtit = STRING(mmin, '(F0.1)') + ' < m/q < ' + STRING(mmax, '(F0.1)')
  IF SIZE(mtit, /type) EQ 0 THEN mtit = 'm/q = all'
  plot3d_options, map=map
  
  case strupcase(units) of
    'COUNTS' : yrange = [1.,1.e5]
    'RATE'   : yrange = [1.,1.e5]
    'CRATE'  : yrange = [1.,1.e6]
    'FLUX'   : yrange = [1.,1.e8]
    'EFLUX'  : yrange = [1.e4,1.e9]
    'DF'     : yrange = [1.e-19,1.e-8]
    else     : yrange = [0.,0.]
  endcase

  case n_elements(center) of
    0 : begin
          lon = 180.
          lat = 0.
        end
    1 : begin
          lon = center[0]
          lat = 0.
        end
    else : begin
             lon = center[0]
             lat = center[1]
           end
  endcase

  if keyword_set(spec) then sflg = 1 else sflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1

  if (n_elements(smo) gt 0) then begin
    nsmo = [1,1,1]
    for i=0,(n_elements(smo)-1) do nsmo[i] = round(smo[i])
    dosmo = 1
  endif else dosmo = 0

  if keyword_set(sum) then npts = 2 else npts = 1

; Put up snapshot window(s)
  IF keyword_set(window) THEN wnum = window ELSE wnum = !d.window 
  wi, wnum, wsize=[800, 600]

; Select the first time, then get the 3D spectrum closest that time
  IF SIZE(var1, /type) EQ 0 THEN print,'Use button 1 to select time; button 3 to quit.'

  wset, wnum
  IF SIZE(var2, /type) EQ 0 THEN ctime2, trange, npoints=npts, /silent, button=button $
  ELSE IF N_ELEMENTS(var2) EQ 2 THEN sum = 1

;  if (size(trange,/type) eq 2) then begin ; Abort before first time select.
;     if (sflg) then wdelete, wnum+1
;     wset, wnum
;     return
;  endif
  
  ok = 1
  IF ~keyword_set(id) THEN BEGIN
     mode = mvn_c6_dat.mode
     mtime = mvn_c6_dat.time
  ENDIF 
  func = 'mvn_sta_get'
  IF ~keyword_set(mmin) THEN mmin = 0
  IF ~keyword_set(mmax) THEN mmin = 100.
  loadct2, ct, previous=oldct
  init_swi = 1
  WHILE (ok) DO BEGIN   
     ;; Put up a 3D spectrogram
     wset, wnum
     IF ~keyword_set(id) THEN BEGIN
        idx = nn(mtime, trange)
        emode = mode[idx]
        emode = emode[uniq(emode)]
        IF N_ELEMENTS(emode) EQ 1 THEN BEGIN
           IF MEAN(trange) LT time_double('2015-07') THEN BEGIN
              CASE emode OF
                 1: IF (aflg) THEN apid = 'cd' ELSE apid = 'cc'
                 2: IF (aflg) THEN apid = 'cf' ELSE apid = 'ce'
                 3: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
                 5: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
                 6: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
                 ELSE: apid = 'ca'
              ENDCASE 
           ENDIF ELSE IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
        ENDIF ELSE BEGIN
           dprint, 'The selected time interval includes multiple APID modes.'
           apid = 'ca'
        ENDELSE 
        undefine, idx, emode
     ENDIF ELSE apid = id 

     IF keyword_set(sum) THEN ddd = mvn_sta_get(apid, tt=trange) $
     ELSE ddd = CALL_FUNCTION(func + '_' + apid, trange)
     
     IF ddd.valid EQ 1 THEN BEGIN
        IF keyword_set(mass) THEN BEGIN
           idx = where(ddd.mass_arr LT mass[0] OR ddd.mass_arr GT mass[1], nidx)
           IF nidx GT 0 THEN ddd.data[idx] = 0.
           IF keyword_set(mq) THEN ddd.mass *= FLOAT(mq)
        ENDIF 
        ddd = conv_units(ddd, units)
        ddd = sum4m(ddd)
        IF SIZE(var2, /type) NE 0 THEN $
           IF SIZE(var1, /type) EQ SIZE(var2, /type) THEN $
              IF compare_struct(var1, var2) EQ 1 THEN IF ((e1flg EQ 0) AND (e2flg EQ 0)) THEN energy = average(ddd.energy, 2)

        IF (SIZE(ddd, /type) EQ 8) THEN BEGIN
           data = ddd.data
           
           IF (e1flg) THEN BEGIN
              IF (e2flg) THEN BEGIN
                 esweep = average(ddd.energy, 2)
                 idx = WHERE(esweep GE MIN(erange) AND esweep LE MAX(erange), nidx)
                 IF nidx GT 0 THEN BEGIN
                    n_e = nidx
                    ebins = idx
                 ENDIF ELSE RETURN
                 undefine, esweep, idx, nidx
              ENDIF ELSE BEGIN
                 n_e = n_elements(energy)
                 ebins = intarr(n_e)
                 FOR k=0,(n_e-1) DO BEGIN
                    de = MIN(ABS(ddd.energy[*,0] - energy[k]), j)
                    ebins[k] = j
                 ENDFOR 
              ENDELSE 
           ENDIF 
           IF (e2flg) THEN BEGIN
              IF e1flg EQ 0 THEN BEGIN
                 idx = where(ddd.energy[*, 0] GE erange[0] AND ddd.energy[*, 0] LE erange[1], nidx)
                 IF nidx GT 0 THEN BEGIN
                    ebins = idx[0]
                    sebins = nidx
                 ENDIF ELSE RETURN
              ENDIF ELSE sebins = 1
           ENDIF ELSE sebins = 1
           IF (SIZE(ebins, /type) EQ 0) THEN ebins = REVERSE(INDGEN(ddd.nenergy))
           nbins = FLOAT(N_ELEMENTS(ebins))

           IF N_ELEMENTS(ebins) GT 1 THEN nocolorbar = 0
           plot3d_new, ddd, lat, lon, ebins=ebins, sum_ebins=sebins, $
                       _extra=extra, log=zlog, zrange=zrange, nocolorbar=nocolorbar

           lab2 = ''
           IF keyword_set(mso) THEN BEGIN
              vec = [ [1., 0., 0.], [0., 1., 0.], [0., 0., 1.] ]
              IF TOTAL(ddd.quat_mso) EQ 0. THEN $
                 FOR i=0, 2 DO append_array, vmso, TRANSPOSE(spice_vector_rotate(vec[*, i], MEAN(trange), 'MAVEN_MSO', 'MAVEN_STATIC', verbose=-1)) $
              ELSE FOR i=0, 2 DO append_array, vmso, TRANSPOSE(quaternion_rotation(vec[*, i], qinv(ddd.quat_mso), /last_ind))
              xyz_to_polar, vmso, theta=tmso, phi=pmso, /ph_0_360
              PLOTS, pmso, tmso, psym=1, color=[2, 4, 6], thick=2, symsize=1.5
              PLOTS, pmso+180., -tmso, psym=4, color=[2, 4, 6], thick=2, symsize=1.5
              undefine, vec, vmso, tmso, pmso 
              lab2 += ' Xmso (b) Ymso (g) Zmso (r) '
           ENDIF 
           IF keyword_set(app) THEN BEGIN
              IF TOTAL(ddd.quat_sc) EQ 0. THEN $
                 xsc = TRANSPOSE(spice_vector_rotate([1., 0., 0.], MEAN(trange), 'MAVEN_SPACECRAFT', 'MAVEN_STATIC', verbose=-1)) $
              ELSE xsc = TRANSPOSE(quaternion_rotation([1., 0., 0.], qinv(ddd.quat_sc), /last_ind))
              xyz_to_polar, xsc, theta=tsc, phi=psc, /ph_0_360
              PLOTS, psc, tsc, psym=7, color=1, thick=2, symsize=1.5
              undefine, xsc, tsc, psc 
              lab2 += 'APP (m) '
           ENDIF 
           IF keyword_set(plot_sc) THEN $
              mvn_spc_fov_blockage, trange=MEAN(trange), /static, clr=1, /invert_phi, /invert_theta
           
           IF keyword_set(label) THEN BEGIN
              lab = STRCOMPRESS(INDGEN(ddd.nbins), /rem)
              XYOUTS, REFORM(ddd.phi[ddd.nenergy-1, *]), REFORM(ddd.theta[ddd.nenergy-1, *]), lab, align=0.5
              XYOUTS, !x.window[1], !y.window[0]*1.2, lab2, charsize=!p.charsize, /normal, color=255, align=1.
              XYOUTS, !x.window[1], !y.window[1]-!y.window[0]*0.5, '(+: Plus / -: Diamond) ', charsize=!p.charsize, /normal, color=255, align=1.
           ENDIF 

           XYOUTS, !x.window[0]*1.2, !y.window[0]*1.2, mtit, charsize=!p.charsize, /normal, color=255

           IF keyword_set(swia) THEN BEGIN
              status = EXECUTE("swicom = SCOPE_VARNAME(common='mvn_swia_data')")
              IF status EQ 1 THEN BEGIN
                 IF (init_swi) THEN BEGIN
                    status = EXECUTE('COMMON mvn_swia_data')
                    init_swi = 0
                 ENDIF 
                 dcs = mvn_swia_get_3dc(MEAN(trange))

                 mk = spice_test('*')
                 idx = WHERE(mk NE '', count)
                 IF count EQ 0 THEN mk = mvn_spice_kernels(/load, /all, trange=trange, verbose=-1)
                 undefine, idx, count
                 mvn_pfp_cotrans, dcs, from='MAVEN_SWIA', to='MAVEN_STATIC', theta=tswi, phi=pswi, verbose=-1
                 ; Assuming that the color table is defined via 'loadct2'.
                 cswi = bytescale(dcs.phi, bottom=7, top=254, range=[0., 360.])
                 lswi = [0., 90., 180., 270., 360.]
                 clswi = bytescale(lswi, bottom=7, top=254, range=[0., 360.])
                 
                 idx = WHERE(dcs.theta[dcs.nenergy-1, *] GT 0., nidx, complement=jdx, ncomplement=njdx)
                 PLOTS, REFORM(pswi[dcs.nenergy-1, idx], nidx), REFORM(tswi[dcs.nenergy-1, idx], nidx), $
                        psym=6, color=REFORM(cswi[dcs.nenergy-1, idx], nidx)
                 PLOTS, REFORM(pswi[dcs.nenergy-1, jdx], njdx), REFORM(tswi[dcs.nenergy-1, jdx], njdx), $
                        psym=5, color=REFORM(cswi[dcs.nenergy-1, jdx], njdx)
                 undefine, dcs, tswi, pswi, cswi, idx, nidx, jdx, njdx

                 XYOUTS, !x.window[0]*1.2, !y.window[1]-!y.window[0]*0.5, '(SWIA, +: Square / -: Triangle)', charsize=!p.charsize, /normal, color=255
                 FOR i=0, N_ELEMENTS(lswi)-1 DO $
                    XYOUTS, !x.window[0]*1.2 + 0.04*i, !y.window[1]-!y.window[0]*1.1, STRING(lswi[i], '(I0)'), charsize=!p.charsize, /normal, color=clswi[i]
                 undefine, i, lswi, clswi 
              ENDIF ELSE dprint, 'No SWIA data loaded.'
              undefine, status, swicom
           ENDIF 
           
           if (sflg) then begin
              wset, wnum+1
              spec3d, ddd, units=units, limits={yrange:yrange, ystyle:1, ylog:1, psym:0}
           endif
        endif

        IF keyword_set(unnormalize) AND N_ELEMENTS(ebins) EQ 1 THEN BEGIN
           IF keyword_set(zrange) THEN crange = zrange ELSE crange = minmax(TOTAL(data[ebins:ebins+sebins-1, *], 1), /pos)
           xposmax = 0.
           yposmax = 0.
           yposmin = 1.
           IF xposmax LT !x.window[1] THEN xposmax = !x.window[1]
           IF yposmax LT !y.window[1] THEN yposmax = !y.window[1]
           IF yposmin GT !y.window[1] THEN yposmin = !y.window[0]
           IF !p.charsize EQ 0 THEN chsz = 1 ELSE chsz = !p.charsize
           space = chsz * FLOAT(!d.x_ch_size)/!d.x_size
           colbar_pos =[xposmax+space, yposmin, xposmax+3*space, yposmax]
           !except = 0
           draw_color_scale, range=crange, pos=colbar_pos, chars=chsz, log=zlog, ytickformat='mvn_sta_3d_snap_exponent'
           !except = except
           XYOUTS, colbar_pos[2], colbar_pos[3] + (colbar_pos[1]/!y.margin[0]), STRUPCASE(units), charsize=chsz, align=0.5, /normal
           undefine, crange
        ENDIF  
        
        ;; Get the next button press
     ENDIF ELSE dprint, 'Click again.'
     wset, wnum
     IF SIZE(var2, /type) EQ 0 THEN BEGIN
        ctime2,trange,npoints=npts,/silent,button=button
        if (size(trange,/type) eq 5) then ok = 1 else ok = 0
     ENDIF ELSE ok = 0
  ENDWHILE  
  loadct2, oldct
  if (kflg) then begin
     IF SIZE(var2, /type) EQ 0 THEN BEGIN
        wdelete, wnum
        if (sflg) then wdelete, wnum+1 
     ENDIF 
  endif
  RETURN
END 
