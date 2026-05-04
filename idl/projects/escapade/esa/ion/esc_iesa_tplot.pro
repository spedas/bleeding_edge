;+
;
;PROCEDURE:       ESC_IESA_TPLOT
;
;PURPOSE:         Creates tplot variables of the ESCAPADE EESA-i data.
;
;INPUTS:          None.
;
;KEYWORDS:
;
;     TNAME:      Returns the tplot variables created.
;
;CREATED BY:      Gwen Hanley & Takuya Hara on 2026-02-22.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-05-02 16:19:25 -0700 (Sat, 02 May 2026) $
; $LastChangedRevision: 34422 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_tplot.pro $
;
;-
PRO esc_iesa_tplot, verbose=verbose, tname=tname, data=data, limits=limits

  IF is_struct(data) AND is_struct(limits) THEN BEGIN
     str_element, data, 'vmin', value=vmin
     str_element, data, 'vmax', value=vmax

     IF ~undefined(vmin) AND ~undefined(vmax) THEN BEGIN
        engy = [vmin, vmax]
        engy = engy[REVERSE(SORT(engy))]
        cnts = FLTARR(N_ELEMENTS(data.x), N_ELEMENTS(engy))
        FOR i=0, N_ELEMENTS(engy)-1 DO cnts[*, i] = data.y[*, FLOOR(0.5*i)]
        str_element, data, 'y', cnts, /add_replace
        str_element, data, 'v', engy, /add
     ENDIF
     IF tag_exist(limits, 'spec', /quiet) THEN specplot, data=data, limits=limits ELSE mplot, data=data, limits=limits
     RETURN
  ENDIF 
  
  tnow = SYSTIME(/sec)
  prod = ['F4D', 'FM', 'FE', 'SW']
  prob = 'ESC-P'
  p = ['b', 'g']
  
  ; Fine 4D (f4d)
  cvar = 'escp_iesa_f4d'
  FOR i=1, 2 DO BEGIN           ; FM1 = BLUE, FM2 = GOLD
     ;COMMON esc_iesa_f4d_com, escb_iesa_f4d, escg_iesa_f4d
     IF i EQ 1 THEN prefix = cvar.replace('p', 'b') ELSE prefix = cvar.replace('p', 'g')
     undefine, EXECUTE("dat = SCOPE_VARFETCH(prefix, common='esc_iesa_f4d_com')")

     IF ~is_struct(dat) THEN CONTINUE

     IF i EQ 1 THEN probe = prob.replace('P', 'B') ELSE probe = prob.replace('P', 'G')
     ntimes  = N_ELEMENTS(dat.time)
     nbins   = dat[0].nbins
     nenergy = dat[0].nenergy
     ndef    = dat[0].ndef
     nanode  = dat[0].nanode
     nmass   = dat[0].nmass

     energy  = dat.energy
     theta   = dat.theta
     phi     = dat.phi
     mass    = dat.mass

     time    = 0.5d0 * (dat.time + dat.end_time)
     data    = dat.data
     cnts    = dat.cnts
     mass_arr = dat.mass_arr 
     
     phi     = REFORM(phi,   nenergy, nanode, ndef, nmass, ntimes)
     theta   = REFORM(theta, nenergy, nanode, ndef, nmass, ntimes)
     
     phi = TRANSPOSE(phi, [0, 2, 1, 3, 4]) ; theta and phi got scrambled so swap them around 
     theta = TRANSPOSE(theta, [0, 2, 1, 3, 4]) 
     
     cnts_4d = REFORM(cnts,  nenergy, ndef, nanode, nmass, ntimes) 

     store_data, prefix + '_E_cnts', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(cnts, 2, /nan), 2, /nan)), v: TRANSPOSE(MEAN(MEAN(energy, dim=2), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'Energy [eV]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ytickunits: 'scientific', ztickunits: 'scientific'}
     ylim, prefix + '_E_cnts', 1., 30.e3, 1, /def
     zlim, prefix + '_E_cnts', 1., 1.e4, 1, /def
     
     store_data, prefix + '_D_cnts', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(TOTAL(cnts_4d, 1, /nan), 2, /nan), 2, /nan)), v: TRANSPOSE(MEAN(MEAN(MEAN(theta, dim=1), dim=2), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'Theta [deg]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ztickunits: 'scientific', ytickinterval: 45., yminor: 4}
     ylim, prefix + '_D_cnts', -50., 50., 0, /def
     zlim, prefix + '_D_cnts', 1., 1.e4, 1, /def

     store_data, prefix + '_A_cnts', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(TOTAL(cnts_4d, 1, /nan), 1, /nan), 2, /nan)), v: TRANSPOSE(MEAN(MEAN(MEAN(phi, dim=1), dim=1), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'Phi [deg]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ztickunits: 'scientific', ytickinterval: 90., yminor: 4}
     ylim, prefix + '_A_cnts', 0., 247.5, 0, /def
     zlim, prefix + '_A_cnts', 1., 1.e4, 1, /def
    
     store_data, prefix + '_M_cnts', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(cnts, 1, /nan), 1, /nan)), v: TRANSPOSE(MEAN(MEAN(mass_arr, dim=1), dim=1))}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'Mass [amu]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                 ztickunits: 'scientific'}
     zlim, prefix + '_M_cnts', 1., 1.e4, 1, /def
     
     store_data, prefix + '_att', data={x: time, y: dat.att_ind}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'Att. Ind', ytickinterval: 1., yminor: 1}
     ylim, prefix + '_att', -0.5, 3.5, 0, /def
     
     store_data, prefix + '_sc_pot', data={x: time, y: dat.sc_pot}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'S/C Pot [V]'}
     
     store_data, prefix + '_neg_sc_pot', data={x: time, y: -1.*dat.sc_pot} 
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: '-S/C Pot [V]'}                    
     
     undefine, dat
  ENDFOR 

  ; Fine Masses (fm)
  cvar = 'escp_iesa_fm'
  FOR i=1, 2 DO BEGIN           ; FM1 = BLUE, FM2 = GOLD
     IF i EQ 1 THEN prefix = cvar.replace('p', 'b') ELSE prefix = cvar.replace('p', 'g')
     undefine, EXECUTE("dat = SCOPE_VARFETCH(prefix, common='esc_iesa_fm_com')")

     IF ~is_struct(dat) THEN CONTINUE

     IF i EQ 1 THEN probe = prob.replace('P', 'B') ELSE probe = prob.replace('P', 'G')
     ntimes  = N_ELEMENTS(dat.time)
     nbins   = dat[0].nbins
     nenergy = dat[0].nenergy
     nmass   = dat[0].nmass

     energy  = dat.energy
     emin    = dat[0].energy_min
     emax    = dat[0].energy_max
     mass    = dat.mass

     time    = 0.5d0 * (dat.time + dat.end_time)
     data    = dat.data
     cnts    = dat.cnts

     mass_arr = dat.mass_arr 
     mass_arr = INDGEN(64)
     
     store_data, prefix + '_M_cnts', data={x: time, y: TRANSPOSE(TOTAL(cnts, 1, /nan)), v: mass_arr}, $
                 dlim={ytitle: probe + ' ' + prod[1], ysubtitle: 'Mass Bins', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ztickunits: 'scientific'}
     ylim, prefix + '_M_cnts', 0., 64., 0, /def
     zlim, prefix + '_M_cnts', 1., 1., 1, /def

     IF nenergy GT 1 THEN BEGIN ; Fine Masses Prime
        FOR j=0, 2 DO BEGIN
           ysubtit = 'Mass Bins'
           store_data, prefix + '_M_cnts_' + roundst(j), data={x: time, y: TRANSPOSE(REFORM(cnts[j, *, *])), v: mass_arr}, $
                       dlim={ytitle: probe + ' ' + prod[1], ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                             ztickunits: 'scientific'}
           ylim, prefix + '_M_cnts_' + roundst(j), 0., 64., 0, /def
           zlim, prefix + '_M_cnts_' + roundst(j), 1., 1., 1, /def

           options, prefix + '_M_cnts_' + roundst(j), ysubtitle=ysubtit + '!C' + STRING(emin[j, 0], '(F0.1)') + ' - ' + STRING(emax[j, 0], '(F0.1)') + ' eV', /def
        ENDFOR
        
        store_data, prefix + '_E_cnts', data={x: time, y: TRANSPOSE(TOTAL(cnts, 2, /nan)), vmin: MEAN(emin, dim=2), vmax: MEAN(emax, dim=2)}, $ 
                    dlim={ytitle: probe + ' ' + prod[1], ysubtitle: 'Energy [eV]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, $
                          ytickunits: 'scientific', ztickunits: 'scientific', tplot_routine: 'esc_iesa_tplot'}
        ylim, prefix + '_E_cnts', 1., 30.e3, 1, /def
        zlim, prefix + '_E_cnts', 1.e2, 1.e4, 1, /def
        
     ENDIF
     undefine, dat
  ENDFOR 

  ; Solar Wind (sw)
  cvar = 'escp_iesa_sw'
  FOR i=1, 2 DO BEGIN           ; FM1 = BLUE, FM2 = GOLD
     IF i EQ 1 THEN prefix = cvar.replace('p', 'b') ELSE prefix = cvar.replace('p', 'g')
     IF i EQ 1 THEN probe = prob.replace('P', 'B') ELSE probe = prob.replace('P', 'G')
     undefine, EXECUTE("dat = SCOPE_VARFETCH(prefix, common='esc_iesa_sw_com')")

     IF ~is_struct(dat) THEN CONTINUE

     IF i EQ 1 THEN probe = prob.replace('P', 'B') ELSE probe = prob.replace('P', 'G')
     ntimes  = N_ELEMENTS(dat.time)
     nbins   = dat[0].nbins
     nenergy = dat[0].nenergy
     ndef    = dat[0].ndef
     nanode  = dat[0].nanode
     nmass   = dat[0].nmass

     energy  = dat.energy
     theta   = dat.theta
     phi     = dat.phi
     mass    = dat.mass

     time    = 0.5d0 * (dat.time + dat.end_time)
     data    = dat.data
     cnts    = dat.cnts
     mass_arr = dat.mass_arr

     phi     = REFORM(phi,   nenergy, nanode, ndef, nmass, ntimes)
     theta   = REFORM(theta, nenergy, nanode, ndef, nmass, ntimes)

     phi = TRANSPOSE(phi, [0, 2, 1, 3, 4]) ; theta and phi got scrambled so swap them around
     theta = TRANSPOSE(theta, [0, 2, 1, 3, 4])

     cnts_4d = REFORM(cnts,  nenergy, ndef, nanode, nmass, ntimes)

     store_data, prefix + '_E_cnts', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(cnts, 2, /nan), 2, /nan)), v: TRANSPOSE(MEAN(MEAN(energy, dim=2), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[3], ysubtitle: 'Energy [eV]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ytickunits: 'scientific', ztickunits: 'scientific'}
     ylim, prefix + '_E_cnts', 1., 30.e3, 1, /def
     zlim, prefix + '_E_cnts', 1., 1.e4, 1, /def

     store_data, prefix + '_E_cnts_proton', data={x: time, y: TRANSPOSE(TOTAL(REFORM(cnts[*, *, 0, *]), 2, /nan)), v: TRANSPOSE(MEAN(MEAN(energy, dim=2), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[3], ysubtitle: 'H!E+!N!CEnergy [eV]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ytickunits: 'scientific', ztickunits: 'scientific'}
     ylim, prefix + '_E_cnts_proton', 1., 30.e3, 1, /def
     zlim, prefix + '_E_cnts_proton', 1., 1.e4, 1, /def
     store_data, prefix + '_E_cnts_alpha', data={x: time, y: TRANSPOSE(TOTAL(REFORM(cnts[*, *, 1, *]), 2, /nan)), v: TRANSPOSE(MEAN(MEAN(energy, dim=2), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[3], ysubtitle: 'He!E++!N!CEnergy [eV]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ytickunits: 'scientific', ztickunits: 'scientific'}
     ylim, prefix + '_E_cnts_alpha', 1., 30.e3, 1, /def
     zlim, prefix + '_E_cnts_alpha', 1., 1.e4, 1, /def
     
     store_data, prefix + '_D_cnts', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(TOTAL(cnts_4d, 1, /nan), 2, /nan), 2, /nan)), v: TRANSPOSE(MEAN(MEAN(MEAN(theta, dim=1), dim=2), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[3], ysubtitle: 'Theta [deg]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ztickunits: 'scientific', ytickinterval: 45., yminor: 4}
     ylim, prefix + '_D_cnts', -50., 50., 0, /def
     zlim, prefix + '_D_cnts', 1., 1.e4, 1, /def
     
     store_data, prefix + '_A_cnts', data={x: time, y: TRANSPOSE(TOTAL(TOTAL(TOTAL(cnts_4d, 1, /nan), 1, /nan), 2, /nan)), v: TRANSPOSE(MEAN(MEAN(MEAN(phi, dim=1), dim=1), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[3], ysubtitle: 'Phi [deg]', ztitle: 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ztickunits: 'scientific', ytickinterval: 90., yminor: 4}
     ylim, prefix + '_A_cnts', 0., 247.5, 0, /def
     zlim, prefix + '_A_cnts', 1., 1.e4, 1, /def
     
     undefine, dat
  ENDFOR 

  tn = tnames('*', create_time=ctime)
  w = WHERE(ctime GT tnow, nw)
  IF nw GT 0 THEN tname = tn[w] $
  ELSE BEGIN
     dprint, dlevel=2, verbose=verbose, 'No tplot(s) newly created.'
     RETURN
  ENDELSE 
  undefine, ctime

  cvar = 'escp_iesa_'
  type = ['E', 'D', 'A']
  FOR i=0, 1 DO BEGIN
     prefix = cvar.replace('p', p[i])
     probe  = prob.replace('P', (p[i]).toupper())
     FOR j=0, 2 DO BEGIN
        undefine, iname 
        iname = strfilter(tname, prefix + ['sw', 'f4d'] + '_' + type[j] + '_cnts', count=ntplot)
        IF TEMPORARY(ntplot) EQ 0 THEN CONTINUE
        
        iname = REVERSE(iname)  ; The order must be ['sw', 'f4d'].
        get_data, iname[0], alim=alim
        extract_tags, ilim, alim, tags=['yrange', 'ylog', 'yticks', 'yminor', 'constant', 'ytitle', 'ysubtitle', 'ytickunits']
        store_data, prefix + type[j] + '_cnts', data=iname, dlim=ilim
        options, prefix + type[j] + '_cnts', ytitle=probe + '!CEESA-i', /def
        undefine, alim, ilim
     ENDFOR
  ENDFOR 

  tn = tnames('*', create_time=ctime)
  w = WHERE(ctime GT tnow, nw)
  IF nw GT 0 THEN tname = tn[w]
  
  RETURN
END
