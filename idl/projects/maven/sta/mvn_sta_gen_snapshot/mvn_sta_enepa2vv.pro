;+
;
;PROCEDURE:       MVN_STA_ENEPA2VV
;
;PURPOSE:         Plots STATIC ion distribution function f(vpara, vperp), assuming an ion gyrotropy.
;
;INPUTS:          None.
;                 But the specified time (or [tmin, tmax]) is set, it
;                 automatically show the snapshot. In this case, the
;                 cursor does not appear in a tplot window.
;
;KEYWORDS:
;
;   ARCHIVE:      Returns archive distribution instead of survey.
;
;     BURST:      Synonym for "ARCHIVE".
;
;      APID:      Specifies the STATIC APID data product.
;
;      MASS:      Specifies the mass range. 
;
;     M_INT:      Specifies the mass/charge value.
;
;     UNITS:      Specifies the units. Default is 'df'.
;
;    WINDOW:      Specifies window number to plot.
;                 A new window to show is generated as default.
;
;     WSIZE:      Specifies the window size.
;
;   MASK_SC:      Mask solid angle bins that are blocked by the spacecraft.
;                 Default = 1
;
;   KEEPWIN:      If set, then don't close the snapshot window on exit.
;
;       SUM:      If set, use cursor to specify time ranges for averaging.
;
;    ERANGE:      Specifies energy range to be used. Default is all.
;
;    ZRANGE:      Specifies the color bar range.
;
;RESOLUTION:      Resolution of the mesh in perp direction (Def: 51).
;
;    SMOOTH:      Width of the smoothing window (Def: no smoothing).
;
;       MAP:      If set, taking account for the STATIC solid angular width
;                 in computing the pitch angle.
;
;    NOZERO:      Removes the data with zero counts for plotting.
;
;    NOFILL:      Doesn't fill the contour plot with colors.
;
;    NLINES:      Defines how many lines to use if using "nofill".
;                 Default is 60.
;
;  NOOLINES:      Suppresses the black contour lines.
;
; NUMOLINES:      Defines how many black contour lines. Default is 20.
;
;  SHOWDATA:      Plots all the data points over the contour.
;
;   DATPLOT:      Returns the plotting data shown lastly.
;
;     DOPOT:      If set, correct for the spacecraft potential. The default is
;                 to use the potential stored in the L2 CDF's or calculated by
;                 mvn_sta_scpot_load.  If this estimate is not available, no
;                 correction is made.
;
;    SC_POT:      Override the default spacecraft potential with this.
;
;       VSC:      Corrects for the spacecraft velocity.
;
;CREATED BY:      Takuya Hara on 2017-06-02.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2017-06-22 14:53:33 -0700 (Thu, 22 Jun 2017) $
; $LastChangedRevision: 23492 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/mvn_sta_enepa2vv.pro $
;
;-
FUNCTION mvn_sta_enepa2vv_map, data
; Mapping pitch angle for the STATIC 3D distributions, 
; taken into account for the angular width.
; This subroutine is totally based on 'mvn_swe_padmap_3d'.

  magf = data.magf
  magt = SQRT(TOTAL(magf*magf, 1))

  n_a = data.nbins
  n_e = data.nenergy

  twopi = 2D*!dpi
  ddtor = !dpi/180D
  ddtors = REPLICATE(ddtor, n_e)
  n = 17                        ; patch size - odd integer

  magu = magf / magt            ; unit vector in direction of B

  Baz = ATAN(magu[1], magu[0])
  IF (Baz LT 0.) THEN Baz += twopi
  Bel = ASIN(magu[2])

  ;;; grids
  g1 = REFORM(REPLICATE(1D, n) # DOUBLE(INDGEN(n) - (n-1)/2)/DOUBLE(n-1), n*n)
  g2 = REFORM(TRANSPOSE(REFORM(g1, [n, n])), n*n)

  ;;; nxn az-el patch, n_a pitch angle bins, n_e energies
  Saz = TRANSPOSE(REBIN(data.dphi, n_e, n_a, n*n, /sample), [2, 0, 1]) * REFORM(REBIN(g1, n*n, n_e*n_a, /sample), n*n, n_e, n_a) + $
        TRANSPOSE(REBIN(data.phi, n_e, n_a, n*n, /sample), [2, 0, 1])
  Sel = TRANSPOSE(REBIN(data.dtheta, n_e, n_a, n*n, /sample), [2, 0, 1]) * REFORM(REBIN(g2, n*n, n_e*n_a, /sample), n*n, n_e, n_a) + $
        TRANSPOSE(REBIN(data.theta, n_e, n_a, n*n, /sample), [2, 0, 1])

  Sel *= ddtor
  Saz *= ddtor

  pam = ACOS(COS(Saz - Baz)*COS(Sel)*COS(Bel) + SIN(Sel)*SIN(Bel))
  RETURN, pam
END

PRO mvn_sta_enepa2vv, var1, var2, archive=archive, burst=burst, apid=dtype, mass=mrange, m_int=mq, units=units, mask_sc=mask_sc, $
                      charsize=chsz, sum=sum, _extra=extra, verbose=verbose, window=window, wsize=wsize, keepwin=keepwin, $
                      erange=erange, zrange=zr, resolution=resolution, smooth=smooth, map=map, nozero=nozero, $
                      datplot=datplot, showdata=showdata, nlines=nlines, nofill=nofill, nolines=noolines, numolines=numolines, $
                      dopot=dopot, sc_pot=sc_pot, vsc=vsc, no_download=no_download

  IF STRUPCASE(STRMID(!version.os, 0, 3)) EQ 'WIN' THEN lbreak = STRING([13B, 10B]) ELSE lbreak = STRING(10B)
  tplot_options, get_option=topt
  dsize = GET_SCREEN_SIZE()

  IF SIZE(window, /type) EQ 0 THEN wnum = topt.window + 1 ELSE wnum = window

  IF SIZE(var1, /type) NE 0 AND SIZE(var2, /type) EQ 0 THEN var2 = var1
  IF SIZE(var2, /type) NE 0 THEN trange = time_double(var2)

  fsize = [.5, (4./9.)]
  IF SIZE(wsize, /type) EQ 0 THEN wsize = LONG(dsize*fsize)
  wstat = EXECUTE("wset, wnum")
  IF wstat EQ 0 THEN wi, wnum, wsize=wsize
  undefine, wstat

  ochsz = !p.charsize
  IF keyword_set(chsz) THEN !p.charsize = chsz
  IF keyword_set(archive) THEN aflg = 1
  IF keyword_set(burst) THEN aflg = 1
  IF SIZE(aflg, /type) EQ 0 THEN aflg = 0

  IF SIZE(mask_sc, /type) EQ 0 THEN kflg = 1 ELSE kflg = FIX(mask_sc)
  IF KEYWORD_SET(sum) THEN sflg = 1 ELSE sflg = 0
  IF SIZE(mrange, /type) EQ 0 THEN mflg = 0 ELSE mflg = 1
  IF SIZE(map, /type) EQ 0 THEN pflg = 0 ELSE pflg = 1
  IF SIZE(nozero, /type) EQ 0 THEN zflg = 0 ELSE zflg = 1

  IF SIZE(units, /type) EQ 0 THEN units = 'df'
  IF ~keyword_set(resolution) THEN resolution = 51
  IF (resolution MOD 2) EQ 0 THEN resolution += 1
  IF ~keyword_set(nlines) THEN nlines = 60
  IF ~keyword_set(numolines) THEN numolines = 20
  IF keyword_set(nofill) THEN fflg = 0 ELSE fflg = 1

  IF SIZE(sc_pot, /type) NE 0 THEN forcepot = 1 ELSE forcepot = 0
  
  IF SIZE(trange, /type) NE 0 THEN IF N_ELEMENTS(trange) GT 1 THEN sflg = 1
  IF (sflg) THEN npts = 2 ELSE npts = 1
  IF SIZE(var1, /type) EQ 0 THEN $
     dprint, 'Uses button 1 to select time: botton 3 to quit.', dlevel=2, verbose=verbose
  IF SIZE(var2, /type) EQ 0 THEN ctime, trange, npoints=npts, /silent
  
  ok = 1
  oregion = !p.region
  !p.region = [0., 0., 0.85, 1.]
  xmargin = !x.margin
  ymargin = !y.margin

  angle = FINDGEN(181) * !DTOR
  func = 'mvn_sta_get'
  TVLCT, red, green, blue, /get 

  mc6 = (SCOPE_VARFETCH(common='mvn_c6', 'mvn_c6_dat')).mode
  tc6 = [ [(SCOPE_VARFETCH(common='mvn_c6', 'mvn_c6_dat')).time], [(SCOPE_VARFETCH(common='mvn_c6', 'mvn_c6_dat')).end_time] ]
  tc6 = MEAN(tc6, dim=2)

  WHILE (ok) DO BEGIN
     IF SIZE(dtype, /type) EQ 0 THEN BEGIN
        IF MEAN(trange) LT time_double('2015-07') THEN BEGIN
           n = nn(tc6, MEAN(trange))
           napid = mc6[n]
           
           CASE napid OF
              1:    IF (aflg) THEN apid = 'cd' ELSE apid = 'cc'
              2:    IF (aflg) THEN apid = 'cf' ELSE apid = 'ce'
              ELSE: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
           ENDCASE
           undefine, n, napid
        ENDIF ELSE IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
     ENDIF ELSE apid = STRLOWCASE(dtype)
     IF (sflg) THEN ddd = CALL_FUNCTION(func, apid, tt=trange) $
     ELSE ddd = CALL_FUNCTION(func + '_' + apid, trange)
 
     IF (SIZE(ddd, /type) EQ 8) THEN BEGIN
        title = 'STATIC ' + ddd.data_name + ' ' + time_string(ddd.time) $
                + ' -> ' + time_string(ddd.end_time, tformat='hh:mm:ss')
        
        IF (mflg) THEN BEGIN
           mmin = MIN(mrange, max=mmax)
           w = WHERE(ddd.mass_arr LT mmin OR ddd.mass_arr GT mmax, nw)
           IF nw GT 0 THEN BEGIN
              ddd.data[w] = 0.
              ddd.cnts[w] = 0.
           ENDIF 
           IF KEYWORD_SET(mq) THEN ddd.mass *= FLOAT(mq)
           title += '!C' + STRING(mmin, '(F0.1)') + ' < M/q < ' + STRING(mmax, '(F0.1)')
        ENDIF ELSE title += '!CM/q: all'
        
        ddd = conv_units(ddd, units)
        ddd = sum4m(ddd)

        IF (KEYWORD_SET(dopot) OR KEYWORD_SET(vsc)) THEN BEGIN
           IF KEYWORD_SET(vsc) THEN BEGIN
              sstat = EXECUTE("v_sc = spice_body_vel('MAVEN', 'MARS', utc=0.5*(ddd.time + ddd.end_time), frame='MAVEN_MSO')")
              IF sstat EQ 0 THEN BEGIN
                 mvn_spice_load, /download, verbose=verbose, no_download=no_download
                 v_sc = spice_body_vel('MAVEN', 'MARS', utc=0.5*(ddd.time + ddd.end_time), frame='MAVEN_MSO')
              ENDIF
              IF SIZE(v_sc, /type) NE 0 THEN BEGIN
                 v_sc = spice_vector_rotate(v_sc, 0.5*(ddd.time + ddd.end_time), 'MAVEN_MSO', 'MAVEN_STATIC', verbose=verbose)
                 dprint, dlevel=2, verbose=verbose, $
                         lbreak + '  Correcting f(v) for the spacecraft velocity:' + lbreak + $
                         '  V_sc (km/s) = [   ' + STRING(v_sc, '(3(F0, :, ",   "))') + '].'
              ENDIF
              v_sc *= -1.       ; reverse the sign because flow is opposite to s/c motion
              undefine, sstat
           ENDIF ELSE v_sc = [0., 0., 0.]

           IF (~FINITE(ddd.sc_pot)) THEN ddd.sc_pot = 0.
           IF (forcepot) THEN ddd.sc_pot = sc_pot
           IF KEYWORD_SET(dopot) THEN BEGIN
              dprint, dlevel=2, verbose=verbose, $
                      lbreak + '  Correcting f(v) for the spacecraft potential:' + $
                      '  SC_POT (V) = [   ' + STRING(ddd.sc_pot, '(F0.1)') + '].'
           ENDIF ELSE ddd.sc_pot = 0.

           ddd.sc_pot *= -1.                             ; Trick to apply 'convert_vframe'.
           ddd = convert_vframe(ddd, v_sc)               ; Correcting f(v) for either sc_pot or V_sc.
           badbin = WHERE(~FINITE(ddd.energy), nbad)
           IF nbad GT 0 THEN ddd.bins[badbin] = 0
        ENDIF
        
        xyz_to_polar, ddd.magf, theta=bth, phi=bph
        pa = pangle(ddd.theta, ddd.phi, bth, bph)
        undefine, bth, pth

        nbins = ddd.nbins
        nenergy = ddd.nenergy
        
        data = ddd.data
        bins_sc = TRANSPOSE(REBIN(ddd.bins_sc, nbins, nenergy, /sample))
        
        energy = ddd.energy
        mass = ddd.mass
        IF ~KEYWORD_SET(erange) THEN erange = minmax(energy) $
        ELSE title += ';  ' + STRING(erange[0], '(F0.1)') + ' < E/q < ' + STRING(erange[1], '(F0.1)')
        
        vx0 = SQRT(2*energy/mass) * COS(pa*!DTOR)
        vy0 = SQRT(2*energy/mass) * SIN(pa*!DTOR)

        IF (kflg) THEN bins = bins_sc $
        ELSE bins = REFORM(REPLICATE(1., nenergy*nbins), nenergy, nbins)
        IF (pflg) THEN BEGIN
           pa = mvn_sta_enepa2vv_map(ddd) * !RADEG
           nmap = 17*17
           data = TRANSPOSE(REBIN(data, nenergy, nbins, nmap, /sample), [2, 0, 1])
           energy = TRANSPOSE(REBIN(energy, nenergy, nbins, nmap, /sample), [2, 0, 1])
           ;bins_sc = TRANSPOSE(REBIN(bins_sc, nenergy, nbins, nmap, /sample), [2, 0, 1])
           bins = TRANSPOSE(REBIN(bins, nenergy, nbins, nmap, /sample), [2, 0, 1])
        ENDIF 
        
        vx = SQRT(2*energy/mass) * COS(pa*!DTOR)
        vy = SQRT(2*energy/mass) * SIN(pa*!DTOR)

        xrange = SQRT(2*MAX(erange)/mass) * [-1., 1.]
        yrange = [0, SQRT(2*MAX(erange)/mass)]
        xspacing = (xrange[1] - xrange[0]) / (resolution-1)/2.
        yspacing = (yrange[1] - yrange[0]) / (resolution-1)

        ;- reject NAN and INF
        ws  = 'WHERE( FINITE(data) AND (bins EQ 1.)'
        ws2 = ws + ' AND (energy GE erange[0] AND energy LE erange[1])'
        ws  = 'w = ' + ws
        ws2 = 'w2 = ' + ws2
        IF (zflg) THEN BEGIN
           ws  += ' AND (data NE 0.)'
           ws2 += ' AND (data NE 0.)'
        ENDIF 
        ws  += ', nw)'
        ws2 += ', nw2)'
        wst  = EXECUTE(ws)
        wst2 = EXECUTE(ws2)
        IF (nw EQ 0) OR (nw2 EQ 0) THEN BEGIN
           dprint, 'No finite data.', dlevel=2, verbose=verbose
           RETURN
        ENDIF
        vx2 = vx[w]
        vy2 = vy[w]
        data2 = data[w]

        ;- triangulate
        ;- qhull generally performs better than triangulate - (cf. spd_slice2d_2di.pro)
        qhull, vx2, vy2, tr, /delaunay
        ;; triangulate, vx, vy, tr, b      ;- obsolete
        
        newdata = trigrid(vx2, vy2, data2, tr, [xspacing, yspacing], $
                          [xrange[0], yrange[0], xrange[1], yrange[1] ], $
                          xgrid=vpara, ygrid=vperp)

        IF KEYWORD_SET(smooth) THEN newdata = SMOOTH(newdata, smooth, /nan)

        Npara = N_ELEMENTS(vpara)
        Nperp = N_ELEMENTS(vperp)
        vpara = REBIN(vpara, Npara, Nperp)
        vperp = TRANSPOSE(REBIN(vperp, Nperp, Npara))
        
        w0 = WHERE( (vpara^2+vperp^2)*mass/2. LT erange[0] $
                    OR (vpara^2+vperp^2)*mass/2. GT erange[1], nw0)
        IF nw0 GT 0 THEN newdata[w0] = 0.
        
        IF SIZE(zr, /type) EQ 0 THEN zr = minmax(newdata, /pos)

        levels = 10.^(INDGEN(nlines) / FLOAT(nlines) * (ALOG10(zr[1]) - ALOG10(zr[0])) + ALOG10(zr[0]))
        levels2 = 10.^(INDGEN(numolines) / FLOAT(numolines) * (ALOG10(zr[1]) - ALOG10(zr[0])) + ALOG10(zr[0]))
        colors = ROUND( (INDGEN(nlines)+1)*(!d.table_size-9)/nlines ) + 7

        WSET, wnum
        !x.margin[0] *= 1.2
        !y.margin[0] *= 1.2

        CONTOUR, newdata, vpara, vperp, /closed, fill=fflg, /isotropic, $
                 xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, c_colors=colors, $
                 levels=levels, charsize=1.3

        IF KEYWORD_SET(showdata) THEN BEGIN
           w = WHERE(bins_sc EQ 1, nw, complement=v, ncomplement=nv)
           IF nw GT 0 THEN oplot, vx0[w], vy0[w], psym=1
           IF nv GT 0 THEN oplot, vx0[v], vy0[v], psym=7, color=1
           undefine, v, w, nv, nw
        ENDIF    
        
        IF ~KEYWORD_SET(noolines) THEN $ 
           CONTOUR, newdata, vpara, vperp, /closed, /isotropic, color=0, levels=levels2, /noerase, $
                    xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, charsize=1.3

        OPLOT, SQRT(2.*MIN(erange)/mass) * COS(angle), SQRT(2.*MIN(erange)/mass) * SIN(angle), thick=2
        OPLOT, SQRT(2.*MAX(erange)/mass) * COS(angle), SQRT(2.*MAX(erange)/mass) * SIN(angle), thick=2

        pmin = MIN(pa[w2], max=pmax)
        undefine, idx, nidx

        ; Shading the blind pitch angle spots.
        LOADCT, 0, /silent
        IF ROUND(pmin) GT 0. THEN $
           POLYFILL, [0., MAX(vpara)*COS(FINDGEN(ROUND(pmin))*!DTOR), 0.], $
                     [0., MAX(vpara)*SIN(FINDGEN(ROUND(pmin))*!DTOR), 0.], color=150
        IF ROUND(pmax) LT 180. THEN $
           POLYFILL, [0., MAX(vpara)*COS((180. - FINDGEN(180. - ROUND(pmax)))*!DTOR), 0.], $
                     [0., MAX(vpara)*SIN((180. - FINDGEN(180. - ROUND(pmax)))*!DTOR), 0.], color=150
        TVLCT, red, green, blue

        PLOT, vx2, vy2, /noerase, xrange=xrange, yrange=yrange, title=title, charsize=1.3, _extra=extra, $
              /xstyle, /ystyle, xtitle='Vpara [km/s]', ytitle='Vperp [km/s]', /nodata, /isotropic

        !x.margin = xmargin
        !y.margin = ymargin
        IF ~KEYWORD_SET(ztitle) THEN ztitle = units_string(ddd.units_name)
        draw_color_scale, range=zr, /log, yticks=10, title=ztitle, charsize=1.3
        datplot = {x: vx2, y: vy2, v: data2, xg: vpara, yg: vperp, vg: newdata}
        undefine, ddd, data
     ENDIF ELSE dprint, 'Click again.', dlevel=2, verbose=verbose
     
     IF SIZE(var2, /type) EQ 0 THEN BEGIN
        ctime, trange, npoints=npts, /silent
        IF (SIZE(trange, /type) EQ 5) THEN ok = 1 ELSE ok = 0
     ENDIF ELSE ok = 0
     undefine, ddd
  ENDWHILE
  IF ~KEYWORD_SET(keepwin) THEN wdelete, wnum
  !p.charsize = ochsz
  !p.region = oregion
  RETURN
END
