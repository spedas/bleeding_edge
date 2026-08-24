;+
;
;PROCEDURE:       ESC_QL_EPH
;
;PURPOSE:         Creates the quicklook plots on the ESCAPADE position.
;
;INPUTS:          Date (= Time stamp) on the ESCAPADE position.
;
;KEYWORDS:
;
;    WINDOW:      Window number to show the quicklook plots.
;
;      LOAD:      If set, loading the ESCAPADE position from the SPICE/kernels.
;
;    DEVICE:      If set, changes the device to be Z-buffer.
;
;       PNG:      If set, generates PNG images.
;
;ORBIT_ONLY:      If set, only visualizes the orbital trajectories.
;
;      TPOS:      Specifies where to plot the orbital projection in the Y-Z plane as the normal coordinate. 
;
;NOTE:            Currently, this routine is optimized for the L2 Earth loitering phase.
;
;CREATED BY:      Takuya Hara on 2025-11-18.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-08-20 08:44:38 -0700 (Thu, 20 Aug 2026) $
; $LastChangedRevision: 34785 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/quicklook/esc_ql_eph.pro $
;
;-
PRO esc_ql_eph, date, bsp=bsp, verbose=verbose, window=window, gsm=gsm, $
                trange=trange, path=path, load=load, device=device, png=png, $
                reset=reset, spk=spk, orbit_only=orbit_only, tpos=tpos, $
                boundary=boundary, timebar=itbar, wait=t_wait ;, cjobs=cjobs

  tplot_options, get_opt=topt0
  tlaunch = time_double('2025-11-13/20:55')
  prefix  = 'esc_ql_eph_'
  re = 6378.1d0
  rm = 3389.9d0
  oneday = 86400.d0
  dname = !d.name
  
  IF undefined(date) THEN date = '2025-11-15'
  IF undefined(trange) THEN trange = ['2025-11-14', '2027']
  IF undefined(window) THEN wnum = 0 ELSE wnum = FIX(window)
  IF undefined(path) THEN path = './'   
  IF KEYWORD_SET(device) THEN zflg = 1 ELSE zflg = 0
  IF KEYWORD_SET(png) THEN pflg = 1 ELSE pflg = 0
  IF KEYWORD_SET(gsm) THEN mflg = 1 ELSE mflg = 0
  IF KEYWORD_SET(orbit_only) THEN oflg = 0 ELSE oflg = 1
  IF ~(oflg) THEN wnum -= 1
  file_mkdir2, path

  IF N_ELEMENTS(date) EQ 2 THEN dates = time_intervals(trange=date, /daily_res) ELSE dates = date

  FOR i=0, N_ELEMENTS(dates)-1 DO BEGIN
     IF KEYWORD_SET(reset) THEN store_data, '*', /delete
     IF KEYWORD_SET(load) THEN BEGIN
        ;IF undefined(helio) THEN helio=root_data_dir() + 'misc/spice/naif/generic_kernels/fk/heliospheric.tf'
        esc_spice_load, trange=trange;, helio=helio
        get_data, 'escb_eph_gse', time
        mn = spice_body_pos('MOON', 'EARTH', utc=time, frame='GSE')
        store_data, 'moon_gse', data={x: time, y: TRANSPOSE(mn)/re}
        
        tspan = minmax(time)
        tspan[0] = time_double(time_string(tspan[0], prec=-3))
        tspan[1] = time_double(time_string(tspan[1], prec=-3)) + 86400.d0
        store_data_colbar, 'esc_eph_timebar', data={x: time, y: time}, range=tspan, lim={xticklen: 0.2}
     ENDIF 

     cotrans, 'escb_eph_gse', 'escb_eph_gsm', /gse2gsm
     cotrans, 'escg_eph_gse', 'escg_eph_gsm', /gse2gsm
     options, 'esc' + ['b', 'g'] + '_eph_gsm', ysubtitle='GSM [R_E]', /def
  
     get_data, 'escb_eph_gse', data=b
     get_data, 'escg_eph_gse', data=g
     store_data, 'esc_eph_gse_x', data={x: b.x, y: [ [b.y[*, 0]], [g.y[*, 0]] ]}, dlim={ytitle: 'X GSE [R!DE!N]', colors: [2, 5], labels: ['BLUE', 'GOLD'], labflag: -1, constant: 0.}
     store_data, 'esc_eph_gse_y', data={x: b.x, y: [ [b.y[*, 1]], [g.y[*, 1]] ]}, dlim={ytitle: 'Y GSE [R!DE!N]', colors: [2, 5], labels: ['BLUE', 'GOLD'], labflag: -1, constant: 0.}
     store_data, 'esc_eph_gse_z', data={x: b.x, y: [ [b.y[*, 2]], [g.y[*, 2]] ]}, dlim={ytitle: 'Z GSE [R!DE!N]', colors: [2, 5], labels: ['BLUE', 'GOLD'], labflag: -1, constant: 0.}
     
     IF undefined(tspan) THEN BEGIN
        tspan = minmax(b.x)
        tspan[0] = time_double(time_string(tspan[0], prec=-3))
        tspan[1] = time_double(time_string(tspan[1], prec=-3)) + oneday
     ENDIF 
     
     r_b = SQRT(TOTAL(b.y*b.y, 2))
     r_g = SQRT(TOTAL(g.y*g.y, 2))

     IF (mflg) THEN BEGIN
        get_data, 'escb_eph_gsm', data=b
        get_data, 'escg_eph_gsm', data=g
        store_data, 'esc_eph_gsm_x', data={x: b.x, y: [ [b.y[*, 0]], [g.y[*, 0]] ]}, dlim={ytitle: 'X GSM [R!DE!N]', colors: [2, 5], labels: ['BLUE', 'GOLD'], labflag: -1, constant: 0.}
        store_data, 'esc_eph_gsm_y', data={x: b.x, y: [ [b.y[*, 1]], [g.y[*, 1]] ]}, dlim={ytitle: 'Y GSM [R!DE!N]', colors: [2, 5], labels: ['BLUE', 'GOLD'], labflag: -1, constant: 0.}
        store_data, 'esc_eph_gsm_z', data={x: b.x, y: [ [b.y[*, 2]], [g.y[*, 2]] ]}, dlim={ytitle: 'Z GSM [R!DE!N]', colors: [2, 5], labels: ['BLUE', 'GOLD'], labflag: -1, constant: 0.}
  
        get_data, 'esc_blue_gold_dist', data=d, index=index
        IF index NE 0 THEN BEGIN
           copy_data, 'esc_blue_gold_dist', 'esc_blue_gold_dist_re'
           store_data, 'esc_blue_gold_dist_km', data={x: d.x, y: d.y*re}
           options, 'esc_blue_gold_dist_km', ytitle='B-G [km]', format='(F0.1)'
           options, 'esc_blue_gold_dist_re', ytitle='Dist. [R!DE!N]', format='(F0.3)'
           
           options, tnames('esc_blue_gold_dist_*'), tplot_routine='esc_tplot_var_labels', panel_size=0.1, colors=0
           options, tnames('esc_blue_gold_dist_*'), 'ysubtitle', /def
        ENDIF 
        
        store_data, 'escb_eph_alt', data={x: b.x, y: r_b}, dlim={ytitle: 'R!DB!N [R!DE!N]', colors: 2, tplot_routine: 'esc_tplot_var_labels', panel_size: 0.1}
        store_data, 'escg_eph_alt', data={x: g.x, y: r_g}, dlim={ytitle: 'R!DG!N [R!DE!N]', colors: 5, tplot_routine: 'esc_tplot_var_labels', panel_size: 0.1}
     ENDIF ELSE BEGIN 
        get_data, 'esc_blue_gold_dist', data=d, alim=alim
        IF alim.ysubtitle.matches('R_E') THEN BEGIN
           store_data, 'esc_blue_gold_dist', data={x: d.x, y: d.y*re}
           options, 'esc_blue_gold_dist', ysubtitle='Distance [km]', /def

           options, 'esc_blue_gold_dist', axis={ytitle: 'Distance [R!DE!N]', normal: re, yaxis: 1}, ystyle=8
        ENDIF
        undefine, alim
        options, 'esc_blue_gold_dist', auto_ylog=1.e3

        store_data, 'esc_eph_alt', data={x: b.x, y: [ [r_b], [r_g] ]*re}, dlim={ytitle: 'Earth', ysubtitle: 'Distance [km]', colors: [2, 5]} ;labels: ['BLUE', 'GOLD'], labflag: -1}
        options, 'esc_eph_alt', axis={ytitle: 'Distance [R!DE!N]', normal: re, yaxis: 1}, ystyle=8
     ENDELSE 

     options, 'esc_eph_timebar', panel_size=0.1
     IF ~undefined(title) THEN tplot_options, 'title', title

     t0 = time_double(dates[i])
     suffix = time_string(t0, tformat='YYYYMMDD')

     IF (oflg) THEN BEGIN       ; If ploting both tplot & orbital trajectories
        IF (zflg) THEN BEGIN    ; Z buffer
           set_plot, 'Z'
           device, set_resolution = [600, 1000]
           device, set_pixel_depth = 24, decompose = 0 ; for TrueColor
           !p.font = -1                                ; Use default fonts
           loadct2, 43
           !p.background = !d.table_size-1 ; White background   (color table 34)
           !p.color = 0                    ; Black Pen
        ENDIF ELSE BEGIN                   ; X window
           wi, wnum, wsize=[600, 1000]
        ENDELSE
     ENDIF 
     IF (zflg) THEN chsz = 1. ELSE IF tag_exist(topt0, 'charsize', /quiet) THEN chsz = topt0.charsize ELSE chsz = 1.
     
     IF (mflg) THEN $
        tname = ['esc_eph_gse_' + ['x', 'y', 'z'], 'esc_eph_gsm_' + ['x', 'y', 'z'], 'esc_eph_timebar', 'esc' + ['b', 'g'] + '_eph_alt', 'esc_blue_gold_dist_' + ['km', 're']] $
     ELSE tname = ['esc_eph_gse_' + ['x', 'y', 'z'], 'esc_blue_gold_dist', 'esc_eph_alt', 'esc_eph_timebar'] 
     options, tname[0:4+mflg], tplot_routine='esc_tplot', timebar={time: t0, linestyle: 2, psym: 6}

     options, 'esc_eph_timebar', tplot_routine='esc_tplot', timebar={time: t0, color: 1, thick: 2}
     
     tplot_options, 'title', 'Where is ESCAPADE ? : ' + time_string(t0, prec=-1)
     tplot_options, 'num_lab_min', 4
     tplot_options, 'charsize', chsz

     tspan0 = [tlaunch, t0 + 30.d0*oneday]
     IF (t0 - tlaunch) GT 30.d0*oneday THEN tspan0[0] = t0 - 30.d0*oneday 
     IF (oflg) THEN BEGIN
        ;turbo_rainbow, 248, /load
        loadct_sd, 48
        line_colors, 5
        tplot, tname, wi=wnum, trange=tspan0, get_plot_pos=tpos
     ENDIF 
     tplot_options, 'title'
     tplot_options, 'num_lab_min'
     IF tag_exist(topt0, 'charsize', /quiet) THEN tplot_options, 'charsize', topt0.charsize

     IF (oflg) THEN BEGIN
        IF (pflg) THEN IF (zflg) THEN makepng, path + prefix + 'tplot_' + suffix, /no_expose $
        ELSE makepng, path + prefix + 'tplot_' + suffix, wi=wnum
     ENDIF
     
     IF (zflg) THEN BEGIN
        set_plot, dname
        set_plot, 'Z'
        device, set_resolution = [400, 1000]
        device, set_pixel_depth = 24, decompose = 0 ; for TrueColor
        !p.font = -1                                ; Use default fonts
        loadct2, 43
        !p.background = !d.table_size-1 ; White background   (color table 34)
        !p.color = 0                    ; Black Pen
     ENDIF ELSE wi, wnum+1, wsize=[400, 1000] 
     ;turbo_rainbow, 248, /load
     loadct_sd, 48
     line_colors, 5

     get_data, 'escb_eph_gse', data=b
     get_data, 'escg_eph_gse', data=g
     get_data, 'moon_gse', data=m

     wb = WHERE(b.x GE tspan[0] AND b.x LE tspan[1])
     wg = WHERE(g.x GE tspan[0] AND g.x LE tspan[1])

     colb = colorscale(b.x, mind=tspan[0], maxd=tspan[1], minc=7, maxc=254)
     colg = colorscale(g.x, mind=tspan[0], maxd=tspan[1], minc=7, maxc=254)
     
     nb = nn2(b.x, t0)
     ng = nn2(g.x, t0)
     nm = nn2(m.x, t0)
     
     region = !p.region
     !p.region = [0., 0.45, 1., 1.]
     xr = [200., -400.]
     yr = [525., -525.]

     tit = ' Created on ' + SYSTIME(0)
     ptit = time_string(t0, prec=-1)
     IF time_string(t0, tformat='hh:mm') EQ '00:00' THEN ptit = ptit.replace('/00:00', ' (DOY = ' + time_string(t0, tformat='DOY') + ')')
     PLOT, [0.], [0.], xrange=xr, yrange=yr, /xst, /yst, /iso, charsize=chsz, xtitle='X GSE [R!DE!N]', ytitle='Y GSE [R!DE!N]', /nodata, $
           xtickinterval=200., title=ptit ;time_string(t0, prec=-1)

     XYOUTS, !x.window[1] + chsz * !d.y_ch_size/!d.x_size, !y.window[0], tit, charsize=chsz * 0.75, orien=90., /normal
     
     loadct2, 0
     OPLOT, [0., 0.], [-1000., 1000.], linestyle=2
     OPLOT, [-1000., 1000.], [0., 0.], linestyle=2

     IF KEYWORD_SET(boundary) THEN BEGIN
        bd = model_boundary_draw()
        OPLOT, bd.xgse,  bd.ygse, color=96
        OPLOT, bd.xgse, -bd.ygse, color=96
        XYOUTS, -375., -160., /data, /align, 'BS', charsize=chsz*0.9
     ENDIF 

     rm = 60.242946             ; Mean Moon pos [R_E]
     theta = FINDGEN(361) * !DTOR
     L2 = [-1.5d6/re, 0.d0]
     
     OPLOT, rm*COS(theta), rm*SIN(theta), thick=2., color=198
     OPLOT, [m.y[nm, 0]], [m.y[nm, 1]], psym=symcat(16), color=198, symsize=1.5 - 0.5*zflg
     OPLOT, [L2[0]], [L2[1]], psym=4, symsize=2. - (0.6*zflg), thick=2
     XYOUTS, -250., -30., 'L2', charsize=chsz*0.9, /data
     
     IF ~undefined(bsp) AND KEYWORD_SET(load) THEN BEGIN
        IF FILE_TEST(bsp) THEN BEGIN
           bspfile = bsp
           spice_kernel_load, bspfile, info=spk
           tspk = time_double(time_string(time_double(spk[-1].trange), prec=-1)) + [1.d0, -1.d0]*120.d0
           pos = spice_body_pos('ESCAPADE_BLUE', 'EARTH', frame='GSE', $
                                utc=dgen(range=TEMPORARY(tspk), resolution=oneday))
           OPLOT, pos[0, *]/re, pos[1, *]/re, linestyle=1

           ispk = WHERE(spk.type eq 'SPK' and (spk.obj_name).contains('ESCAPADE'), nspk)
           IF nspk GT 0 THEN spk = FILE_BASENAME(spk[ispk].filename)  
        ENDIF 
     ENDIF 
     
     ;turbo_rainbow, 248, /load
     loadct_sd, 48
     line_colors, 5
     
     PLOTS, b.y[wb, 0], b.y[wb, 1], color=colb, thick=3, noclip=0
     PLOTS, g.y[wg, 0], g.y[wg, 1], color=colg, thick=3, noclip=0
     OPLOT, [b.y[nb, 0]], [b.y[nb, 1]], color=2, psym=symcat(12, thick=2), thick=3, symsize=1.5; - 0.5*zflg
     OPLOT, [g.y[ng, 0]], [g.y[ng, 1]], color=5, psym=symcat(13, thick=2), thick=3, symsize=1.5; - 0.5*zflg
     undefine, symcat(16)

     !p.region = region
     xw = !x.window
     yw = !y.window
     dx = xw[1] - xw[0]
     dy = dx * 400. / 1000.
     
     ;IF (mflg) THEN yp = tpos[1, 5] + [0., dy] ELSE yp = tpos[3, 3] - [dy, 0.]
     IF undefined(tpos) THEN BEGIN
        IF (mflg) THEN yp = 0.442615 - [dy, 0.] ELSE yp = 0.438529 - [dy, 0.]
     ENDIF ELSE BEGIN
        IF ndimen(tpos) LT 2 THEN yp = tpos - [dy, 0.] $
        ELSE IF (mflg) THEN yp = tpos[3, 4] - [dy, 0.] ELSE yp = tpos[3, 3] - [dy, 0.]
     ENDELSE 
     PLOT, [0.], [0.], xrange=[-100, 100], yrange=[-100., 100.], /xst, /yst, position=[xw[0], yp[0], xw[1], yp[1]], charsize=chsz, /noerase, /nodata, $
           xtitle='Y GSE [R!DE!N]', ytitle='Z GSE [R!DE!N]'
     OPLOT, 50.*COS(theta), 50.*SIN(theta), linestyle=2
     IF ~undefined(pos) THEN OPLOT, pos[1, *]/re, pos[2, *]/re, linestyle=1
     
     PLOTS, b.y[wb, 1], b.y[wb, 2], color=colb, thick=3, noclip=0
     ;PLOTS, g.y[wg, 1], g.y[wg, 2], color=colg, thick=3, noclip=0
     OPLOT, [b.y[nb, 1]], [b.y[nb, 2]], color=2, psym=symcat(12, thick=2), thick=3, symsize=1.5; - 0.5*zflg
     OPLOT, [g.y[ng, 1]], [g.y[ng, 2]], color=5, psym=symcat(13, thick=2), thick=3, symsize=1.5; - 0.5*zflg
     XYOUTS, 0., 80., '--- Nominal 50 R!DE!N Magnetotail Extent', charsize=chsz*0.9, align=0.5
     
     tpos2 = plot_positions(opt={region: [0., 0., 1., 0.11], ymargin: [5., 2.], xmargin: [10., 3.], charsize: chsz})
     tplot_options, get_opt=topt
     options, 'esc_eph_timebar', position=[xw[0], tpos2[1], xw[1], tpos2[3]]

     get_data, 'esc_eph_timebar', alim=alim
     tbar = alim.timebar

     IF (oflg) THEN BEGIN
        tbar = LIST(tbar)
        tbar.add, {time: tspan0[0]}
        tbar.add, {time: tspan0[1]}
     ENDIF ELSE BEGIN
        IF ISA(itbar, 'LIST') THEN BEGIN
           tbar = LIST(tbar)
           tbar.add, itbar, /extract
        ENDIF 
     ENDELSE 
     options, 'esc_eph_timebar', 'timebar', TEMPORARY(tbar)
     
     tplot_options, 'region', [0., 0., 1., 0.11]

     tplot_options, 'charsize', chsz
     tplot, 'esc_eph_timebar', /oplot, wi=wnum+1, trange=tspan
     options, 'esc_eph_timebar', 'position'
     options, 'esc_eph_timebar', 'timebar'
     tplot_options, opt=topt
     
     tplot_options, opt=topt0
     IF (pflg) THEN IF (zflg) THEN makepng, path + prefix + 'orbit_' + suffix, /no_expose $
     ELSE makepng, path + prefix + 'orbit_' + suffix, wi=wnum+1
     IF (zflg) THEN set_plot, dname
     
     IF (pflg) AND (oflg) THEN BEGIN
        cmd = 'convert ' + path + prefix + 'tplot_' + suffix + '.png ' + $
              path + prefix + 'orbit_' + suffix + '.png +append ' + path + prefix + suffix + '.png'
        SPAWN, cmd
        FILE_DELETE, path + prefix + 'tplot_' + suffix + '.png' 
        FILE_DELETE, path + prefix + 'orbit_' + suffix + '.png' 
     ENDIF

     IF ~undefined(t_wait) THEN WAIT, t_wait
  ENDFOR 
  RETURN
END 
