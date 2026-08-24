;+
;
;PROCEDURE:       ESC_QL_TPLOT
;
;PURPOSE:         Creates the ESCAPADE overview quicklook plot.
;
;INPUTS:          Date (optional if TRANGE is specified).
;
;KEYWORDS:
;
;    TRANGE:      Alternatively specifies the time range to visualize.
;
;    WINDOW:      Specifies the window number.
;                 Default is WINDOW = 0 (Orbit), WINDOW = 1 (Tplot).
;
;      PATH:      Specifies the path where the output PNG images are saved.
;
;    DEVICE:      If set, it processes the plot in the Z-buffer.
;
;       PNG:      If set, creates PNG images.
;
;     IPATH:      Specifies the input path from which to load the EESA-i CDF files.
;
;     RESET:      If set, clears all existing tplot variables.
;
;       BSP:      Explicitly specifies the long-term predictive SPK. 
;
;       SBS:      If set, visualizes TPLOT panels side by side for BLUE and GOLD.
;
;      long:      Specifies the duration of the time range in days.
;
;    TSHIFT:      Shifts the start UTC time to adjust the time range to be displayed.
;
;        L1:      If set, loads the real-time solar wind dataset observed by the L1 asset.
;
;      KEEP:      If set, preserves the previous tplot settings.
;
;     CLOCK:      If set, visualizes the IMF clock angle instead of the cone angle.
;
;       PAD:      If set PAD = 0, omits the EESA-e PAD panel from the tplot.
;
;       EUV:      If set EUV = 0, omits the ELP EUV proxy panel from the tplot.
;
;CREATED BY:      Takuya Hara on 2026-02-26.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-08-20 14:48:01 -0700 (Thu, 20 Aug 2026) $
; $LastChangedRevision: 34790 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/quicklook/esc_ql_tplot.pro $
;
;-
PRO esc_ql_tplot, date, trange=trange, verbose=verbose, window=window, path=path, device=device, png=png, $
                  ipath=ipath, reset=reset, blue=blue, gold=gold, bsp=bsp, sbs=sbs, long=long, $
                  tshift=tshift, l1=l1, keep=keep, clock=clock, pad=pad, euv=euv ;, cjobs=cjobs

  TVLCT, red0, green0, blue0, /get
  oneday = 86400.d0
  IF undefined(pad) THEN pad = 1
  IF undefined(euv) THEN euv = 1
  
  version = FLOAT(!version.release)
  tplot_options, get_opt=topt0
  tlaunch = time_double('2025-11-13/20:55')
  prefix  = 'escp_ql_'
  re = 6378.1d0
  rm = 3389.9d0
  dname = !d.name
  nan = !values.f_nan

  IF undefined(window) THEN wnum = 0 ELSE wnum = FIX(window)
  IF undefined(path) THEN path = './'
  IF KEYWORD_SET(device) THEN zflg = 1 ELSE zflg = 0
  IF KEYWORD_SET(png) THEN pflg = 1 ELSE pflg = 0
  IF undefined(long) THEN nday = 1.d0 ELSE nday = DOUBLE(long)
  file_mkdir2, path

  IF undefined(date) THEN BEGIN
     IF undefined(trange) THEN date = '2025-11-15' $
     ELSE BEGIN
        tspan = trange
        IF is_string(tspan) THEN tspan = time_double(tspan)
        date = tspan[0]
        nday = DOUBLE( (tspan[1] - tspan[0]) / oneday)
        IF nday GT 1. THEN IF undefined(long) THEN long = FIX(nday)
     ENDELSE 
  ENDIF 
  IF N_ELEMENTS(date) EQ 2 THEN dates = time_intervals(trange=date, /daily_res) ELSE dates = date

  IF version GE 9. THEN BEGIN
     nan1 = nan.dup([2]) 
     nan2 = nan.dup([2, 2])
  ENDIF ELSE BEGIN
     nan1 = REPLICATE(nan, 2)
     nan2 = REFORM(REPLICATE(nan, 4), 2, 2)
  ENDELSE

  IF undefined(tshift) THEN dt = 0.d0 ELSE dt = DOUBLE(tshift) 
  
  IF KEYWORD_SET(sbs) THEN sfix = '_sbs' ELSE sfix = ''
  IF KEYWORD_SET(long) THEN sfix = '_long' + sfix
  bframe = ['PL', 'GSE', 'RTN']
  IF KEYWORD_SET(l1) THEN frame = 'gse' ELSE frame = 'rtn'
  
  FOR i=0, N_ELEMENTS(dates)-1 DO BEGIN
     IF KEYWORD_SET(reset) THEN store_data, '*', /delete

     t0 = time_double(dates[i])
     suffix = time_string(t0, tformat='YYYYMMDD')

     tr = t0 + [0.d0, oneday * nday] + dt
     IF tr[1] - tr[0] GT oneday THEN BEGIN
        tbar = LIST()
        FOR j=0, N_ELEMENTS(tr)-1 DO tbar.add, {time: tr[j]}
     ENDIF
     IF KEYWORD_SET(long) THEN tsuffix = ': ' + time_string(tr[0], prec=-3) + ' -> ' + time_string(tr[1], prec=-3) ELSE tsuffix = ''
     
     esc_ql_eph, time_string(t0), bsp=bsp, window=wnum, /orbit_only, /load, $
                 path=path, device=device, png=png, timebar=TEMPORARY(tbar), /boundary  

     options, 'escb_eph_gse', tplot_routine='esc_tplot_var_labels', panel_size=0.4, colors=2
     options, 'escg_eph_gse', tplot_routine='esc_tplot_var_labels', panel_size=0.4, colors=5
     options, 'esc*_eph_gse', 'labflag', /def
     options, 'esc*_eph_gse', labels=['X!DGSE!N', 'Y!DGSE!N [R!DE!N]', 'Z!DGSE!N']

     timespan, [-1.d0, 1.d0] * oneday + tr
       FOR ip=0, 1 DO BEGIN       ; 0 = BLUE  &  1 = GOLD
        IF ip EQ 0 THEN BEGIN
           p     = 'b'
           probe = 'BLUE' 
        ENDIF ELSE BEGIN
           p     = 'g'
           probe = 'GOLD'
        ENDELSE 

        ; EESA-i (spectra: dummy)
        store_data, 'esc' + p + '_iesa_e', data={x: t0 + [0.d0, oneday], y: nan2, v: [1., 30.e3]}, $
                    dlim={ytitle: 'EESA-i', ysubtitle: 'Energy [eV]', ytickunits: 'scientific', ztitle: 'Counts [#]', ztickunits: 'scientific', spec: 1, no_color_scale: 0}
        ylim, 'esc' + p + '_iesa_e', 1., 30.e3, 1, /def
        zlim, 'esc' + p + '_iesa_e', 1., 1.e4, 1, /def
        esc_iesa_load, prod=['f4d', 'sw'], blue=1-ip, gold=ip, ipath=ipath
        esc_iesa_tplot, blue=1-ip, gold=ip
  
        get_data, 'esc' + p + '_iesa_E_cnts', index=index
        IF index NE 0 THEN BEGIN
           store_data, 'esc' + p + '_iesa_e', /delete
           store_data, 'esc' + p + '_iesa_E_cnts', newname='esc' + p + '_iesa_e'
        ENDIF 
        undefine, iesa, index

        ; EESA-i (moments: dummy)
        IF ((tnames('esc' + p + '_iesa_n'))[0]  EQ '') THEN store_data, 'esc' + p + '_iesa_n', data={x: t0 + [0.d0, oneday], y: nan1}, $
           dlim={ytitle: 'EESA-i', ysubtitle: 'Density!C[cm!E-3!N]', yminor: 5} $
        ELSE options, 'esc' + p + '_iesa_n', ytitle='EESA-i', ysubtitle='Density!C[cm!E-3!N]', yminor=5
        ylim, 'esc' + p + '_iesa_n', 0., 40., 0, /def
        IF ((tnames('esc' + p + '_iesa_v'))[0]  EQ '') THEN store_data, 'esc' + p + '_iesa_v', data={x: t0 + [0.d0, oneday], y: nan1}, $
           dlim={ytitle: 'EESA-i', ysubtitle: 'Velocity!C[km/s]', yminor: 4, ytickinterval: 200.} $
        ELSE options, 'esc' + p + '_iesa_v', ytitle='EESA-i', ysubtitle='Velocity!C[km/s]', yminor=5           
        ylim, 'esc' + p + '_iesa_v', 200., 800., 0, /def
        
        ; EESA-e (dummy)
        store_data, 'esc' + p + '_eesa_e', data={x: t0 + [0.d0, oneday], y: nan2, v: [1., 1.e4]}, $
                    dlim={ytitle: 'EESA-e', ysubtitle: 'Energy [eV]', ytickunits: 'scientific', ztitle: 'Counts [#]', ztickunits: 'scientific', spec: 1, no_color_scale: 0}
        ylim, 'esc' + p + '_eesa_e', 0.5, 10.e3, 1, /def
        zlim, 'esc' + p + '_eesa_e', 1., 1.e4, 1, /def
        store_data, 'esc' + p + '_eesa_pad', data={x: t0 + [0.d0, oneday], y: nan2, v: [0., 1.]}, $
                    dlim={ytitle: 'EESA-e', ysubtitle: 'PAD [deg]', ztitle: 'Norm!CCounts', spec: 1, yticks: 4, yminor: 3, zticks: 2}
        ylim, 'esc' + p + '_eesa_pad', 0., 180., 0, /def
        zlim, 'esc' + p + '_eesa_pad', 0.5, 1.5, 0, /def
        esc_eesa_load, prod=['f3d'], blue=1-ip, gold=ip
        esc_eesa_tplot, /mean, blue=1-ip, gold=ip

        get_data, 'esc' + p + '_eesa_f3d_E_cnts', data=eesa, index=index
        IF index NE 0 THEN BEGIN
           w = WHERE(eesa.x GE tr[0] AND eesa.x LT tr[1], nw)
           IF nw GT 0 THEN BEGIN
              store_data, 'esc' + p + '_eesa_e', /delete
              store_data, 'esc' + p + '_eesa_f3d_E_cnts', newname='esc' + p + '_eesa_e'
              options, 'esc' + p + '_eesa_e', ytitle='EESA-e', ysubtitle='Energy [eV]'
           ENDIF 
        ENDIF
        undefine, eesa, index
        
        ; ELP (EUV proxy: dummy)
        store_data, 'esc' + p + '_elp_euv', data={x: t0 + [0.d0, oneday], y: nan1}, $
                    dlim={ytitle: 'ELP', ysubtitle: 'EUV', yminor: 1, yticks: 1}
        ylim, 'esc' + p + '_elp_euv', 0., 1., 0, /def

        ; EMAG 
        esc_emag_load, blue=1-ip, gold=ip, frame=bframe, tname=mname
        IF undefined(mname) THEN BEGIN
           ; dummy
           store_data, 'esc' + p + '_emag_tot',  data={x: t0 + [0.d0, oneday], y: nan1}, dlim={ysubtitle: '|B|!C[nT]'}
           store_data, 'esc' + p + '_emag_' + frame +'_phi',  data={x: t0 + [0.d0, oneday], y: nan1}, dlim={ysubtitle: 'Bphi!C[deg]', yticks: 4, yminor: 3, constant: 180.}
           ylim, 'esc' + p + '_emag_' + frame + '_phi', 0., 360., 0., /def

           IF KEYWORD_SET(clock) THEN BEGIN
              store_data, 'esc' + p + '_emag_' + frame + '_clk', data={x: t0 + [0.d0, oneday], y: nan1}, dlim={ysubtitle: 'Bclock!C[deg]', yticks: 4, yminor: 3, constant: 90.*FINDGEN(4)}
              ylim, 'esc' + p + '_emag_' + frame + '_clk', 315., -45., 0., /def
              options, 'esc' + p + '_emag_' + frame + '_clk', ytickname=REVERSE(['N', 'E', 'S', 'W'])
           ENDIF ELSE BEGIN
              store_data, 'esc' + p + '_emag_' + frame + '_cone', data={x: t0 + [0.d0, oneday], y: nan1}, dlim={ysubtitle: 'Bcone!C[deg]', yticks: 4, yminor: 3, constant: 90.}
              ylim, 'esc' + p + '_emag_' + frame + '_cone', 0., 180., 0., /def
           ENDELSE 
        ENDIF ELSE BEGIN

           FOR im=0, N_ELEMENTS(mname)-2 DO BEGIN
              esc_emag_angle, mname[im], /cone, /clock
              options, mname[im] + '_phi', constant=180., ysubtitle='Bphi!C' + bframe[im] + '!C[deg]'
              options, mname[im] + '_cone', ysubtitle='Bcone!C' + bframe[im] + '!C[deg]'
              options, mname[im] + '_clk', ysubtitle='Bclock!C' + bframe[im] + '!C[deg]'
              options, mname[im], ysubtitle=bframe[im] + '!C[nT]'
           ENDFOR
        ENDELSE
        options, 'esc' + p + '_emag*', ytitle='EMAG', datagap=10.d0
        options, 'esc' + p + '_emag*tot*', ysubtitle='|B|!C[nT]'
        undefine, mname
     ENDFOR
     
     options, tnames('*iesa*'), datagap=3600.d0
     options, tnames('*eesa*'), datagap=3600.d0*3.d0
     bname = 'escb_' + ['iesa_e', 'eesa_e', 'eesa_pad', 'elp_euv', 'iesa_n', 'iesa_v', 'emag_tot', 'emag_' + frame + '_cone', 'emag_' + frame + '_phi', 'eph_gse']
     gname = 'escg_' + ['iesa_e', 'eesa_e', 'eesa_pad', 'elp_euv', 'iesa_n', 'iesa_v', 'emag_tot', 'emag_' + frame + '_cone', 'emag_' + frame + '_phi', 'eph_gse']

     IF KEYWORD_SET(clock) THEN BEGIN
        bname[-3] = (bname[-3]).replace('cone', 'clk')
        gname[-3] = (gname[-3]).replace('cone', 'clk')
     ENDIF 
     
     tplot_options, 'num_lab_min', 4
     tplot_options, 'xticklen', 0.04

     IF KEYWORD_SET(l1) THEN BEGIN
        omni_hro_load, trange=[-1.d0, 1.d0] * oneday + tr, tplotname=omn_name
        oidx = strfilter(omn_name, ['*BX_GSE', '*BY_GSE', '*BZ_GSE', '*proton_density', '*flow_speed'], /index)
        IF N_ELEMENTS(oidx) GE 5 THEN BEGIN
           get_data, omn_name[oidx[0]], data=obx
           get_data, omn_name[oidx[1]], data=oby
           get_data, omn_name[oidx[2]], data=obz

           store_data, 'OMNI_HRO_1min_B_GSE_tot', data={x: obx.x, y: SQRT(obx.y^2 + oby.y^2 + obz.y^2)} ;, dlim={colors: 100, color_table: 0}
           store_data, 'OMNI_HRO_1min_B_GSE', data={x: obx.x, y: [ [obx.y], [oby.y], [obz.y]]};, dlim={colors: 100, color_table: 0}
           esc_emag_angle, 'OMNI_HRO_1min_B_GSE', /cone, /clock

           ow  = WHERE(FINITE(obx.y))
           otr = minmax(obx.x[ow]) 
           
           omn_name = [omn_name[oidx[-1]], omn_name[oidx[-2]], 'OMNI_HRO_1min_B_GSE' + ['_tot', '_cone', '_phi']]
           IF KEYWORD_SET(clock) THEN omn_name[-2] = (omn_name[-2]).replace('cone', 'clk')
           options, omn_name, color_table=0, colors=100
           undefine, obx, oby, obz
        ENDIF ELSE undefine, omn_name

        undefine, dsc_name, swfo_name
        ;;;dsc_noaa_load, type=['f1m', 'm1m'], local_data_dir=GETENV('HOME')+'/work/data/dscovr/', tname=dsc_name
        IF undefined(dsc_name) THEN BEGIN
           dsc_name = 'dsc_' + ['fc_f1m_proton_' + ['dens', 'velc', 'vgse', 'temp'], 'mag_m1m_' + ['btot', 'bgse']]
           FOR io=0, N_ELEMENTS(dsc_name)-1 DO BEGIN
              IF io EQ 2 OR io EQ N_ELEMENTS(dsc_name)-1 THEN store_data, dsc_name[io], data={x: t0 + [0.d0, oneday], y: REBIN(nan1, 2, 3, /sample)} $
              ELSE store_data, dsc_name[io], data={x: t0 + [0.d0, oneday], y: nan1}
           ENDFOR

           IF undefined(swfo) THEN swfo = 1
           swfo:
           swfo_noaa_load, type='swpc', tname=swfo_name

           dsc_name[0] = swfo_name[0]
           dsc_name[1] = swfo_name[1]
           dsc_name[3] = swfo_name[2]
           dsc_name[4] = swfo_name[5]
           dsc_name[5] = swfo_name[4]
        ENDIF ELSE BEGIN
           get_data, dsc_name[-1], data=ddsc
           IF (time_string(MAX(ddsc.x), prec=-3) NE time_string(tr[1]-1.d0, prec=-3)) AND (tr[1] - MAX(ddsc.x) GT 0.5d0*oneday) THEN BEGIN
              swfo = 1
              GOTO, swfo
           ENDIF 
        ENDELSE 
        
        esc_emag_angle, dsc_name[-1], /cone, /clock
        dsc_name = [dsc_name[0:1], dsc_name[4], dsc_name[-1] + ['_cone', '_phi']]
        IF KEYWORD_SET(clock) THEN dsc_name[-2] = (dsc_name[-2]).replace('cone', 'clk')
        options, dsc_name, color_table=0, colors=200

        IF ~undefined(otr) THEN BEGIN
           FOR io=0, N_ELEMENTS(dsc_name)-1 DO BEGIN
              get_data, dsc_name[io], data=ddsc
              dw = WHERE(ddsc.x GE otr[0] AND ddsc.x LE otr[1], ndw)
              IF ndw GT 0 THEN BEGIN
                 ddsc.y[dw, *] = nan
                 store_data, dsc_name[io], data=ddsc
              ENDIF
              undefine, ddsc, dw, ndw
           ENDFOR
        ENDIF
        undefine, otr
     ENDIF 

     tdoy = dgen(range=tr, resolution=oneday)
     store_data, 'doy', data={x: tdoy, y: (time_struct(tdoy)).doy}, dlim={ytitle: 'DOY', format: '(I0)'}
     undefine, tdoy
     
     IF KEYWORD_SET(sbs) THEN BEGIN
        IF (zflg) THEN BEGIN    ; Z buffer
           set_plot, 'Z'
           device, set_resolution = [1600, 1000]
           device, set_pixel_depth = 24, decompose = 0 ; for TrueColor
           !p.font = -1                                ; Use default fonts
           loadct2, 43
           !p.background = !d.table_size-1 ; White background   (color table 34)
           !p.color = 0                    ; Black Pen
        ENDIF ELSE BEGIN                   ; X window
           wi, wnum+1, wsize=[1600, 1000]
        ENDELSE
        IF (zflg) THEN chsz = 1. ELSE IF tag_exist(topt0, 'charsize', /quiet) THEN chsz = topt0.charsize ELSE chsz = 1.
        ;turbo_rainbow, 248, /load
        loadct_sd, 48
        line_colors, 5

        options, [bname[0], gname[0]], ytitle='EESA-i!CEnergy', ysubtitle='[eV]', ztitle='Counts'
        options, [bname[1], gname[1]], ytitle='EESA-e!CF3D!CEnergy', ysubtitle='[eV]', ztitle='Counts'
        options, [bname[2], gname[2]], ytitle='EESA-e!CPAD', ysubtitle='[deg]'

        IF KEYWORD_SET(l1) THEN BEGIN
           FOR it=4, 8 DO BEGIN
              get_data, bname[it], alim=blim
              get_data, gname[it], alim=glim
              str_element, blim, 'datagap', /delete
              str_element, glim, 'datagap', /delete

              IF ~undefined(omn_name) THEN BEGIN
                 store_data, bname[it] + '_l1', data=[dsc_name[it-4], omn_name[it-4], bname[it]], dlim=TEMPORARY(blim), limits={colors: [200, 100, 2], color_table: 0} 
                 store_data, gname[it] + '_l1', data=[dsc_name[it-4], omn_name[it-4], gname[it]], dlim=TEMPORARY(glim), limits={colors: [200, 100, 5], color_table: 0} 
              ENDIF ELSE BEGIN
                 store_data, bname[it] + '_l1', data=[dsc_name[it-4], bname[it]], dlim=TEMPORARY(blim), limits={colors: [200, 2], color_table: 0} 
                 ;limits={labels: ['DSCOVR', 'BLUE'], colors: [178, 2], labflag: -1, color_table: 0} 
                 store_data, gname[it] + '_l1', data=[dsc_name[it-4], gname[it]], dlim=TEMPORARY(glim), limits={colors: [200, 5], color_table: 0} 
                 ;limits={labels: ['DSCOVR', 'GOLD'], colors: [178, 5], labflag: -1, color_table: 0} 
              ENDELSE 
              bname[it] = bname[it] + '_l1'
              gname[it] = gname[it] + '_l1'
           ENDFOR 
        ENDIF 

        
        tplot_options, 'charsize', chsz
        tplot_options, 'title', 'ESCAPADE/BLUE' + tsuffix 
        tplot_options, 'region', [0., 0., 0.5, 1.]
        IF KEYWORD_SET(long) THEN IF long EQ 14 THEN tplot_options, 'var_label', ['doy']
        tplot, bname, trange=tr, wi=wnum+1, get_plot_pos=tpos

        TVLCT, ctbl, /get
        loadct2, 0
        labnam = ['DSCOVR', 'OMNI', 'BLUE']
        IF ~undefined(swfo) THEN labnam[0] += '/!C  SOLAR-1!C  (SWFO)'
        labcol = [200, 100, 2]
        ypos = (FINDGEN(N_ELEMENTS(labnam)) + 0.5) * (tpos[3, -6]-tpos[1, -2])/N_ELEMENTS(labnam) + tpos[1, -2]
        xpos = tpos[2, -2]
        XYOUTS, xpos, ypos, '  ' + REVERSE(labnam), color=REVERSE(labcol), /norm, charsize=chsz
        TVLCT, TEMPORARY(ctbl)
        
        ;turbo_rainbow, 248, /load
        loadct_sd, 48
        line_colors, 5
        
        tplot_options, 'title', 'ESCAPADE/GOLD' + tsuffix 
        tplot_options, 'region', [0.5, 0., 1., 1.]
        tplot, gname, trange=tr, wi=wnum+1, /oplot, get_plot_pos=tpos

        TVLCT, ctbl, /get
        loadct2, 0
        labnam = ['DSCOVR', 'OMNI', 'GOLD']
        IF ~undefined(swfo) THEN labnam[0] += '/!C  SOLAR-1!C  (SWFO)'
        labcol = [200, 100, 5]
        ypos = (FINDGEN(N_ELEMENTS(labnam)) + 0.5) * (tpos[3, -6]-tpos[1, -2])/N_ELEMENTS(labnam) + tpos[1, -2]
        xpos = tpos[2, -2]
        XYOUTS, xpos, ypos, '  ' + REVERSE(labnam), color=REVERSE(labcol), /norm, charsize=chsz
        TVLCT, TEMPORARY(ctbl)
        
        IF tag_exist(topt0, 'charsize', /quiet) THEN tplot_options, 'charsize', topt0.charsize
        tplot_options, 'title'
        tplot_options, 'region'
        tplot_options, 'var_label'
     ENDIF ELSE BEGIN
        options, bname[0:2], tplot_routine='esc_tplot', ytitle_color=2
        options, gname[0:2], tplot_routine='esc_tplot', ytitle_color=5
        tname = [bname[0], gname[0], bname[1], gname[1], bname[2], gname[2]]
        append_array, tname, 'esc_' + ['elp_euv', 'iesa_n', 'iesa_v', 'emag_tot', 'emag_cone', 'emag_phi']
        IF KEYWORD_SET(clock) THEN tname[-2] = (tname[-2]).replace('cone', 'clk')
        append_array, tname, [bname[9], gname[9]]

        FOR it=3, 8 DO BEGIN
           ttname = [bname[it], gname[it]]
           labcol = [2, 5]
           labnam = ['BLUE', 'GOLD']

           IF KEYWORD_SET(l1) AND (it GT 3) THEN BEGIN
              IF ~undefined(omn_name) THEN BEGIN
                 ttname = [dsc_name[it-4], omn_name[it-4], ttname]
                 labcol = [200, 100, labcol]
                 labnam = ['DSCOVR', 'OMNI', labnam]
              ENDIF ELSE BEGIN
                 ttname = [dsc_name[it-4], ttname]
                 ;labcol = [178, labcol]
                 labcol = [200, labcol]
                 labnam = ['DSCOVR', labnam]
              ENDELSE
              get_data, bname[it], alim=alim
           ENDIF 
           store_data, tname[it+3], data=TEMPORARY(ttname), dlim={colors: TEMPORARY(labcol), color_table: 0};, labflag: -1, labels: TEMPORARY(labnam)}
           IF ~undefined(alim) THEN options, tname[it+3], ytitle=alim.ytitle, ysubtitle=alim.ysubtitle
           undefine, alim
        ENDFOR 

        ylim, 'esc_elp_euv', 0, 1, 0
        ylim, 'esc_iesa_n', 0, 40, 0
        ylim, 'esc_iesa_v', 200., 800., 0
        IF KEYWORD_SET(clock) THEN ylim, 'esc_emag_clk', 315., -45., 0 ELSE ylim, 'esc_emag_cone', 0., 180., 0
        ylim, 'esc_emag_phi', 0., 360., 0

        options, 'esc_iesa_n', yminor=5
        options, 'esc_iesa_v', ytickinterval=200., yminor=4
        options, bname[0:2], ytitle='BLUE'
        options, gname[0:2], ytitle='GOLD'

        options, [bname[0], gname[0]], ysubtitle='EESA-i!CE [eV]', ztitle='Counts'
        options, [bname[1], gname[1]], ysubtitle='EESA-e!CF3D!CE [eV]', ztitle='Counts'
        options, [bname[2], gname[2]], ysubtitle='EESA-e!CPAD!C[deg]'
        options, [bname[9], gname[9]], panel_size=0.6

        get_data, 'esc_blue_gold_dist', data=dist
        store_data, 'esc_blue_gold_dist_re', data={x: dist.x, y: dist.y/re}, dlim={ytitle: 'DIST [R!DE!N]', format: '(F0.2)'}
        
        IF KEYWORD_SET(long) THEN tplot_options, 'title', 'ESCAPADE Overview Quicklook' + tsuffix $
        ELSE tplot_options, 'title', 'ESCAPADE Overview Quicklook: ' + time_string(t0, prec=-3)

        IF KEYWORD_SET(long) THEN IF long EQ 14 THEN tplot_options, 'var_label', ['doy', 'esc_blue_gold_dist_re'] $
        ELSE tplot_options, 'var_label', 'esc_blue_gold_dist_re'

        IF (zflg) THEN BEGIN    ; Z buffer
           set_plot, 'Z'
           device, set_resolution = [800, 1000]
           device, set_pixel_depth = 24, decompose = 0 ; for TrueColor
           !p.font = -1                                ; Use default fonts
           loadct2, 43
           !p.background = !d.table_size-1 ; White background   (color table 34)
           !p.color = 0                    ; Black Pen
        ENDIF ELSE BEGIN                   ; X window
           wi, wnum+1, wsize=[800, 1000]
        ENDELSE
        IF (zflg) THEN chsz = 1. ELSE IF tag_exist(topt0, 'charsize', /quiet) THEN chsz = topt0.charsize ELSE chsz = 1.
        ;turbo_rainbow, 248, /load
        loadct_sd, 48
        line_colors, 5

        tplot_options, 'charsize', chsz

        IF ~(pad) THEN BEGIN
           tname[4] = ''
           tname[5] = ''
        ENDIF
        IF ~(euv) THEN tname[6] = ''
        IF ~(pad) AND ~(euv) THEN options, [bname[9], gname[9]], panel_size=0.5
        tplot, TEMPORARY(tname), trange=tr, wi=wnum+1, get_plot_pos=tpos

        TVLCT, ctbl, /get
        loadct2, 0
        labnam = ['DSCOVR', 'OMNI', 'BLUE', 'GOLD']
        IF ~undefined(swfo) THEN labnam[0] += '/!C  SOLAR-1!C  (SWFO)'
        labcol = [200, 100, 2, 5]

        ypos = (FINDGEN(N_ELEMENTS(labnam)) + 0.5) * (tpos[3, -7]-tpos[1, -3])/N_ELEMENTS(labnam) + tpos[1, -3]
        xpos = tpos[2, -1]
        XYOUTS, xpos, ypos, '  ' + REVERSE(labnam), color=REVERSE(labcol), /norm, charsize=chsz
        TVLCT, TEMPORARY(ctbl)
        
        IF NOT KEYWORD_SET(keep) THEN BEGIN
           IF tag_exist(topt0, 'charsize', /quiet) THEN tplot_options, 'charsize', topt0.charsize
           tplot_options, 'title'
           tplot_options, 'var_label'
        ENDIF
     ENDELSE

     IF (pflg) THEN IF (zflg) THEN makepng, path + prefix.replace('escp', 'esc') + 'tplot_' + suffix + sfix, /no_expose $
     ELSE makepng, path + prefix.replace('escp', 'esc') + 'tplot_' + suffix + sfix, wi=wnum+1
     IF (zflg) THEN set_plot, dname
     
     IF (pflg) THEN BEGIN
        cmd = 'convert ' + path + prefix.replace('escp', 'esc') + 'tplot_' + suffix + sfix + '.png ' + $
              path + 'esc_ql_eph_orbit_' + suffix + '.png +append ' + path + prefix.replace('escp', 'esc') + suffix + sfix + '.png'
        SPAWN, cmd
        FILE_DELETE, path + prefix.replace('escp', 'esc') + 'tplot_' + suffix + sfix + '.png'
        FILE_DELETE, path + 'esc_ql_eph_orbit_' + suffix + '.png'
     ENDIF
     IF NOT KEYWORD_SET(keep) THEN tplot_options, opt=topt0
  ENDFOR 

  TVLCT, red0, green0, blue0
  RETURN
END
