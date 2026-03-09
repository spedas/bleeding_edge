;+
;
;PROCEDURE:       ESC_EESA_TPLOT
;
;PURPOSE:         Creates tplot variables of the ESCAPADE EESA-e data.
;
;INPUTS:          None.
;
;KEYWORDS:
;
;     TNAME:      Returns the tplot variables created.
;
;      MEAN:      If set, calculates the mean counts instead of the total counts.
;
;CREATED BY:      Takuya Hara on 2026-03-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-03-05 13:17:40 -0800 (Thu, 05 Mar 2026) $
; $LastChangedRevision: 34232 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/electron/esc_eesa_tplot.pro $
;
;-
PRO esc_eesa_tplot, data, verbose=verbose, tname=tname, mean=avg
  tnow = SYSTIME(/sec)
  prod = ['F3D', 'SPEC', 'PAD', 'POT']
  prob = 'ESC-P'
  IF KEYWORD_SET(avg) THEN aflg = 1 ELSE aflg = 0
  IF (aflg) THEN ztit = 'Mean ' ELSE ztit = ''
  
  ; Full 3D (f3d)
  cvar = 'escp_eesa_f3d'
  FOR i=1, 2 DO BEGIN           ; FM1 = BLUE, FM2 = GOLD
     IF i EQ 1 THEN prefix = cvar.replace('p', 'b') ELSE prefix = cvar.replace('p', 'g')
     undefine, EXECUTE("dat = SCOPE_VARFETCH(prefix, common='esc_eesa_f3d_com')")

     IF ~is_struct(dat) THEN CONTINUE

     IF i EQ 1 THEN probe = prob.replace('P', 'B') ELSE probe = prob.replace('P', 'G')
     ntimes  = N_ELEMENTS(dat.time)
     nbins   = dat[0].nbins
     nenergy = dat[0].nenergy
     ndef    = dat[0].ndef
     nanode  = dat[0].nanode

     energy  = dat.energy
     theta   = dat.theta
     phi     = dat.phi

     time    = 0.5d0 * (dat.time + dat.end_time)
     data    = dat.data
     cnts    = dat.cnts
     
     phi     = REFORM(phi,   nenergy, nanode, ndef, ntimes)
     theta   = REFORM(theta, nenergy, nanode, ndef, ntimes)
     cnts_3d = REFORM(cnts,  nenergy, nanode, ndef, ntimes) 

     IF (aflg) THEN ydat = TRANSPOSE(MEAN(cnts, dim=2, /nan)) ELSE ydat = TRANSPOSE(TOTAL(cnts, 2, /nan)) 
     store_data, prefix + '_E_cnts', data={x: time, y: TEMPORARY(ydat), v: TRANSPOSE(MEAN(energy, dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'Energy [eV]', ztitle: ztit + 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ytickunits: 'scientific', ztickunits: 'scientific'}
     ylim, prefix + '_E_cnts', 0.5, 10.e3, 1, /def
     zlim, prefix + '_E_cnts', 1., 10.^(5-2*aflg), 1, /def

     IF (aflg) THEN ydat = TRANSPOSE(MEAN(MEAN(cnts_3d, dim=1, /nan), dim=1, /nan)) ELSE ydat = TRANSPOSE(TOTAL(TOTAL(cnts_3d, 1, /nan), 1, /nan))
     store_data, prefix + '_D_cnts', data={x: time, y: TEMPORARY(ydat), v: TRANSPOSE(MEAN(MEAN(theta, dim=1), dim=1))}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'Theta [deg]', ztitle: ztit + 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ztickunits: 'scientific', ytickinterval: 30., yminor: 3}
     ylim, prefix + '_D_cnts', -60., 60., 0, /def
     zlim, prefix + '_D_cnts', 1., 10.^(6-3*aflg), 1, /def

     IF (aflg) THEN ydat = TRANSPOSE(MEAN(MEAN(cnts_3d, dim=1, /nan), dim=2, /nan)) ELSE ydat = TRANSPOSE(TOTAL(TOTAL(cnts_3d, 1, /nan), 2, /nan))
     store_data, prefix + '_A_cnts', data={x: time, y: TEMPORARY(ydat), v: TRANSPOSE(MEAN(MEAN(phi, dim=1), dim=2))}, $
                 dlim={ytitle: probe + ' ' + prod[0], ysubtitle: 'Phi [deg]', ztitle: ztit + 'Counts [#]', spec: 1, no_interp: 1, extend_y_edges: 1, $
                       ztickunits: 'scientific', ytickinterval: 90., yminor: 4}
     ylim, prefix + '_A_cnts', 0., 247.5, 0, /def
     zlim, prefix + '_A_cnts', 1., 10.^(6-3*aflg), 1, /def
    
     undefine, dat
  ENDFOR 

  tn = tnames('*', create_time=ctime)
  w = WHERE(ctime GT tnow, nw)
  IF nw GT 0 THEN tname = tn[w]
  
  RETURN
END
