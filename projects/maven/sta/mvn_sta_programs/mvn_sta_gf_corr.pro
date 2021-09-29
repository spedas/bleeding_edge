;+
;
;PROCEDURE:       MVN_STA_GF_CORR
;
;PURPOSE:         
;                 Computes a corrected g-factor for C0, C6, and C8 data products based on the CA data product.
;
;INPUTS:          None.
;
;KEYWORDS:
;
;     TPLOT:      Makes some tplot variables by using the corrected g-factor.
;
;CREATED BY:      Takuya Hara on 2018-08-09.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2021-02-25 08:53:57 -0800 (Thu, 25 Feb 2021) $
; $LastChangedRevision: 29701 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_programs/mvn_sta_gf_corr.pro $
;
;-
PRO mvn_sta_gf_corr, tplot=tplot, verbose=verbose
  COMMON mvn_c0, mvn_c0_ind, mvn_c0_dat
  COMMON mvn_c6, mvn_c6_ind, mvn_c6_dat
  COMMON mvn_ca, mvn_ca_ind, mvn_ca_dat
  
  COMMON mvn_c6e, mvn_c6e_ind, mvn_c6e_dat
  COMMON mvn_c8, mvn_c8_ind, mvn_c8_dat

  c0 = 1
  IF N_ELEMENTS(mvn_c0_ind) EQ 0 THEN c0 = 0 $
  ELSE IF mvn_c0_ind EQ -1 THEN c0 = 0

  c6 = 1
  IF N_ELEMENTS(mvn_c6_ind) EQ 0 THEN c6 = 0 $
  ELSE IF mvn_c6_ind EQ -1 THEN c6 = 0

  ca = 1
  IF N_ELEMENTS(mvn_ca_ind) EQ 0 THEN ca = 0 $
  ELSE IF mvn_ca_ind EQ -1 THEN ca = 0
  IF (ca EQ 0) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No CA data product loaded.'
     RETURN
  ENDIF 

  c6e = 1
  IF N_ELEMENTS(mvn_c6e_ind) EQ 0 THEN c6e = 0 $
  ELSE IF mvn_c6e_ind EQ -1 THEN c6e = 0
  c8 = 1
  IF N_ELEMENTS(mvn_c8_ind) EQ 0 THEN c8 = 0 $
  ELSE IF mvn_c8_ind EQ -1 THEN c8 = 0

  npts = N_ELEMENTS(mvn_ca_dat.time)
  iswp = mvn_ca_dat.swp_ind
  iatt = mvn_ca_dat.att_ind
  nenergy = mvn_ca_dat.nenergy
  nbins = mvn_ca_dat.nbins
 
  gf = REFORM(mvn_ca_dat.gf[iswp, *, *, 0] * ((iatt EQ 0) # REPLICATE(1., nenergy*nbins)) + $
              mvn_ca_dat.gf[iswp, *, *, 1] * ((iatt EQ 1) # REPLICATE(1., nenergy*nbins)) + $
              mvn_ca_dat.gf[iswp, *, *, 2] * ((iatt EQ 2) # REPLICATE(1., nenergy*nbins)) + $
              mvn_ca_dat.gf[iswp, *, *, 3] * ((iatt EQ 3) # REPLICATE(1., nenergy*nbins)), npts*nenergy*nbins)
  gf = REFORM(gf, npts, nenergy, nbins)
 
  cnts = mvn_ca_dat.data
  ctot = TOTAL(cnts, 3)
  ctot = REBIN(ctot, npts, nenergy, nbins, /sample)
  cnrm = (cnts / ctot) > 0.

  avg_an = 16                   ; cf. 'mvn_sta_prod_cal'.
  gf_corr = avg_an * TOTAL(gf * cnrm, 3)
  w = WHERE(gf_corr EQ 0., nw)
  IF nw GT 0 THEN gf_corr[w] = (avg_an * (TOTAL(gf, 3) / nbins))[w] 
  gfca = TEMPORARY(gf)

  ; C0
  IF (c0) THEN BEGIN
     npts = N_ELEMENTS(mvn_c0_dat.time)
     iswp = mvn_c0_dat.swp_ind
     ieff = mvn_c0_dat.eff_ind
     iatt = mvn_c0_dat.att_ind
     nenergy = mvn_c0_dat.nenergy
     avg_nrg = nenergy / mvn_ca_dat.nenergy
     nmass = mvn_c0_dat.nmass
     
     time = (mvn_c0_dat.time + mvn_c0_dat.end_time)/2.
     data = mvn_c0_dat.data
     energy = REFORM(mvn_c0_dat.energy[iswp, *, 0])
     mass = TOTAL(mvn_c0_dat.mass_arr[iswp, *, *], 2)/nenergy
     
     bkg = mvn_c0_dat.bkg
     dead = mvn_c0_dat.dead
     gf = REFORM(mvn_c0_dat.gf[iswp, *, 0]*((iatt EQ 0)#REPLICATE(1., nenergy)) +$
                 mvn_c0_dat.gf[iswp, *, 1]*((iatt EQ 1)#REPLICATE(1., nenergy)) +$
                 mvn_c0_dat.gf[iswp, *, 2]*((iatt EQ 2)#REPLICATE(1., nenergy)) +$
                 mvn_c0_dat.gf[iswp, *, 3]*((iatt EQ 3)#REPLICATE(1., nenergy)), npts*nenergy)#REPLICATE(1., nmass)
     eff = mvn_c0_dat.eff[ieff, *, *]
     dt = FLOAT(mvn_c0_dat.integ_t#REPLICATE(1., nenergy*nmass))

     n = nn(mvn_ca_dat.time, mvn_c0_dat.time)
     gf2 = gf_corr[n, *]  
     gf2 = REBIN(gf2, npts, mvn_ca_dat.nenergy, avg_nrg, /sample)
     gf2 = REBIN(REFORM(TRANSPOSE(gf2, [0, 2, 1]), npts, nenergy), npts, nenergy, nmass, /sample)
     cf  = gf2 / gf
     str_element, mvn_c0_dat, 'gf_corr', cf[*, *, 0], /add ; slim down array size

     gf = mvn_c0_dat.geom_factor*REFORM(gf, npts, nenergy, nmass)
     eflux = (data-bkg)*dead/((gf*cf)*eff*dt)
     str_element, mvn_c0_dat, 'eflux', eflux, /add_replace
     
     IF KEYWORD_SET(tplot) THEN BEGIN
        qf = (mvn_c0_dat.quality_flag AND 128)/128 OR (mvn_c0_dat.quality_flag AND 64)/64
        ind = where(qf EQ 1, count)
        IF count GE 1 THEN data[ind, *, *] = 0.
        IF count GE 1 THEN eflux[ind, *, *] = 0.

        store_data,'mvn_sta_c0_e_gf_corr', data={x: time, y: TOTAL(eflux, 3), v: energy}, $
                   dlim={ylog: 1, zlog: 1, datagap: 7., spec: 1, ytitle: 'STA C0', ztitle: 'eflux', no_interp: 1, $
                         ysubtitle: 'Energy [eV]'}
        ylim, 'mvn_sta_c0_e_gf_corr', .1, 40.e3, 1, /def
        zlim, 'mvn_sta_c0_e_gf_corr', 1.e3, 1.e9, 1, /def
     ENDIF 
  ENDIF 

  ; C6
  IF (c6) THEN BEGIN
     npts = N_ELEMENTS(mvn_c6_dat.time)
     iswp = mvn_c6_dat.swp_ind
     ieff = mvn_c6_dat.eff_ind
     iatt = mvn_c6_dat.att_ind
     nenergy = mvn_c6_dat.nenergy
     avg_nrg = nenergy / mvn_ca_dat.nenergy
     nmass = mvn_c6_dat.nmass
     
     time = (mvn_c6_dat.time + mvn_c6_dat.end_time)/2.
     data = mvn_c6_dat.data
     energy = REFORM(mvn_c6_dat.energy[iswp, *, 0])
     mass = TOTAL(mvn_c6_dat.mass_arr[iswp, *, *], 2)/nenergy
     
     bkg = mvn_c6_dat.bkg
     dead = mvn_c6_dat.dead
     gf = REFORM(mvn_c6_dat.gf[iswp, *, 0]*((iatt EQ 0)#REPLICATE(1., nenergy)) +$
                 mvn_c6_dat.gf[iswp, *, 1]*((iatt EQ 1)#REPLICATE(1., nenergy)) +$
                 mvn_c6_dat.gf[iswp, *, 2]*((iatt EQ 2)#REPLICATE(1., nenergy)) +$
                 mvn_c6_dat.gf[iswp, *, 3]*((iatt EQ 3)#REPLICATE(1., nenergy)), npts*nenergy)#REPLICATE(1., nmass)
     
     eff = mvn_c6_dat.eff[ieff, *, *]
     dt = FLOAT(mvn_c6_dat.integ_t#REPLICATE(1., nenergy*nmass))
     
     n = nn(mvn_ca_dat.time, mvn_c6_dat.time)
     gf2 = gf_corr[n, *]
     gf2 = REBIN(gf2, npts, mvn_ca_dat.nenergy, avg_nrg, /sample)
     gf2 = REBIN(REFORM(TRANSPOSE(gf2, [0, 2, 1]), npts, nenergy), npts, nenergy, nmass, /sample)
     cf  = gf2 / gf
     str_element, mvn_c6_dat, 'gf_corr', cf[*, *, 0], /add
     
     gf = mvn_c6_dat.geom_factor*REFORM(gf, npts, nenergy, nmass)  
     eflux = (data-bkg)*dead/((gf*cf)*eff*dt)
     str_element, mvn_c6_dat, 'eflux', eflux, /add_replace
     
     IF KEYWORD_SET(tplot) THEN BEGIN
        qf = (mvn_c6_dat.quality_flag AND 128)/128 OR (mvn_c6_dat.quality_flag AND 64)/64
        ind = where(qf EQ 1, count)
        IF count GT 0 THEN data[ind, *, *] = 0.
        IF count GT 0 THEN eflux[ind, *, *] = 0.
        
        store_data,'mvn_sta_c6_e_gf_corr', data={x: time, y: TOTAL(eflux, 3), v: energy}, $
                   dlim={ylog: 1, zlog: 1, datagap: 7., spec: 1, ytitle: 'STA C6', ztitle: 'eflux', no_interp: 1, $
                         ysubtitle: 'Energy [eV]'}
        ylim, 'mvn_sta_c6_e_gf_corr', .1, 40.e3, 1, /def
        zlim, 'mvn_sta_c6_e_gf_corr', 1.e3, 1.e9, 1, /def
        
        store_data,'mvn_sta_c6_m_gf_corr', data={x: time, y: TOTAL(eflux, 2), v: mass}, $
                   dlim={ylog: 1, zlog: 1, datagap: 7., spec: 1, ytitle: 'STA C6', ztitle: 'eflux', no_interp: 1, $
                         ysubtitle: 'Mass [amu]'}
        ylim, 'mvn_sta_c6_m_gf_corr', .5, 100., /def
        zlim, 'mvn_sta_c6_m_gf_corr', 1.e3, 1.e9, 1, /def
     ENDIF 
  ENDIF 

  ; C6E
  IF (c6e) THEN BEGIN
     npts = N_ELEMENTS(mvn_c6e_dat.time)
     iswp = mvn_c6e_dat.swp_ind
     ieff = mvn_c6e_dat.eff_ind
     iatt = mvn_c6e_dat.att_ind
     nenergy = mvn_c6e_dat.nenergy
     avg_nrg = nenergy / mvn_ca_dat.nenergy
     nmass = mvn_c6e_dat.nmass
     
     time = (mvn_c6e_dat.time + mvn_c6e_dat.end_time)/2.
     data = mvn_c6e_dat.data
     energy = REFORM(mvn_c6e_dat.energy[iswp, *, 0])
     mass = TOTAL(mvn_c6e_dat.mass_arr[iswp, *, *], 2)/nenergy

     bkg = mvn_c6e_dat.bkg
     dead = mvn_c6e_dat.dead
     gf = REFORM(mvn_c6e_dat.gf[iswp, *, 0]*((iatt EQ 0)#REPLICATE(1., nenergy)) +$
                 mvn_c6e_dat.gf[iswp, *, 1]*((iatt EQ 1)#REPLICATE(1., nenergy)) +$
                 mvn_c6e_dat.gf[iswp, *, 2]*((iatt EQ 2)#REPLICATE(1., nenergy)) +$
                 mvn_c6e_dat.gf[iswp, *, 3]*((iatt EQ 3)#REPLICATE(1., nenergy)), npts*nenergy)#REPLICATE(1., nmass)
     
     eff = mvn_c6e_dat.eff[ieff, *, *]
     dt = FLOAT(mvn_c6e_dat.integ_t#REPLICATE(1., nenergy*nmass))

     n = nn(mvn_ca_dat.time, mvn_c6e_dat.time)
     gf2 = gf_corr[n, *]
     gf2 = REBIN(gf2, npts, mvn_ca_dat.nenergy, avg_nrg, /sample)
     gf2 = REBIN(REFORM(TRANSPOSE(gf2, [0, 2, 1]), npts, nenergy), npts, nenergy, nmass, /sample)
     cf  = gf2 / gf
     str_element, mvn_c6e_dat, 'gf_corr', cf[*, *, 0], /add

     gf = mvn_c6e_dat.geom_factor*REFORM(gf, npts, nenergy, nmass)
     eflux = (data-bkg)*dead/((gf*cf)*eff*dt)
     str_element, mvn_c6e_dat, 'eflux', eflux, /add_replace
     
     IF KEYWORD_SET(tplot) THEN BEGIN
        qf = (mvn_c6e_dat.quality_flag AND 128)/128 OR (mvn_c6e_dat.quality_flag AND 64)/64
        ind = where(qf EQ 1, count)
        IF count GT 0 THEN data[ind, *, *] = 0.
        IF count GT 0 THEN eflux[ind, *, *] = 0.
        
        store_data,'mvn_sta_c6e_e_gf_corr', data={x: time, y: TOTAL(eflux, 3), v: energy}, $
                   dlim={ylog: 1, zlog: 1, datagap: 7., spec: 1, ytitle: 'STA C6E', ztitle: 'eflux', no_interp: 1, $
                         ysubtitle: 'Energy [eV]'} ;, ytickformat: 'exponent'}                                                                                                        
        ylim, 'mvn_sta_c6e_e_gf_corr', .1, 40.e3, 1, /def
        zlim, 'mvn_sta_c6e_e_gf_corr', 1.e3, 1.e9, 1, /def
        
        store_data,'mvn_sta_c6e_m_gf_corr', data={x: time, y: TOTAL(eflux, 2), v: mass}, $
                dlim={ylog: 1, zlog: 1, datagap: 7., spec: 1, ytitle: 'STA C6E', ztitle: 'eflux', no_interp: 1, $
                      ysubtitle: 'Mass [amu]'} ;, ytickformat: 'exponent'}                                                                                                         
        ylim, 'mvn_sta_c6e_m_gf_corr', .5, 100., /def
        zlim, 'mvn_sta_c6e_m_gf_corr', 1.e3, 1.e9, 1, /def
     ENDIF     
  ENDIF 

  ; C8
  IF (c8) THEN BEGIN
     npts = N_ELEMENTS(mvn_ca_dat.time)
     iswp = mvn_ca_dat.swp_ind
     nenergy = mvn_ca_dat.nenergy
     ndef = mvn_ca_dat.ndef
     nanode = mvn_ca_dat.nanode

     gf   = REFORM(TEMPORARY(gfca), npts, nenergy, ndef, nanode)
     cnts = REFORM(cnts, npts, nenergy, ndef, nanode)
     ctot = TOTAL(cnts, 4)
     ctot = REBIN(ctot, npts, nenergy, ndef, nanode, /sample)
     cnrm = (cnts / ctot) > 0.
     
     avg_an = 16               ; cf. 'mvn_sta_prod_cal'.                                                                                                                         
     gf_corr = avg_an * TOTAL(gf * cnrm, 4)
     w = WHERE(gf_corr EQ 0., nw)
     IF nw GT 0 THEN gf_corr[w] = (avg_an * (TOTAL(gf, 4) / nanode))[w]      
     
     npts = N_ELEMENTS(mvn_c8_dat.time)
     iswp = mvn_c8_dat.swp_ind
     ieff = mvn_c8_dat.eff_ind
     iatt = mvn_c8_dat.att_ind
     
     nenergy = mvn_c8_dat.nenergy
     avg_nrg = nenergy / mvn_ca_dat.nenergy
     ndef = mvn_c8_dat.ndef
     avg_def = ndef / mvn_ca_dat.ndef

     time = (mvn_c8_dat.time + mvn_c8_dat.end_time)/2.
     data = mvn_c8_dat.data
     energy = REFORM(mvn_c8_dat.energy[iswp, *, 0])
     theta = REFORM(mvn_c8_dat.theta[iswp, nenergy-1, *])
     bkg = mvn_c8_dat.bkg
     dead = mvn_c8_dat.dead
     
     gf = REFORM(mvn_c8_dat.gf[iswp, *, *, 0] * ((iatt EQ 0) # REPLICATE(1., nenergy*ndef)) + $
                 mvn_c8_dat.gf[iswp, *, *, 1] * ((iatt EQ 1) # REPLICATE(1., nenergy*ndef)) + $
                 mvn_c8_dat.gf[iswp, *, *, 2] * ((iatt EQ 2) # REPLICATE(1., nenergy*ndef)) + $
                 mvn_c8_dat.gf[iswp, *, *, 3] * ((iatt EQ 3) # REPLICATE(1., nenergy*ndef)), npts, nenergy, ndef)
     
     eff = mvn_c8_dat.eff[ieff, *, *]
     dt = FLOAT(mvn_c8_dat.integ_t # REPLICATE(1., nenergy*ndef))

     n = nn(mvn_ca_dat.time, mvn_c8_dat.time)
     gf2 = gf_corr[n, *, *]
     gf2 = REBIN(gf2, npts, mvn_ca_dat.nenergy, mvn_ca_dat.ndef, avg_def, /sample)
     gf2 = REFORM(TRANSPOSE(gf2, [0, 1, 3, 2]), npts, mvn_ca_dat.nenergy, ndef)
     gf2 = REBIN(TRANSPOSE(gf2, [0, 2, 1]), npts, ndef, mvn_ca_dat.nenergy, avg_nrg, /sample)
     gf2 = TRANSPOSE(REFORM(TRANSPOSE(gf2, [0, 1, 3, 2]), npts, ndef, nenergy), [0, 2, 1])

     cf  = gf2 / gf
     str_element, mvn_c8_dat, 'gf_corr', cf, /add

     gf = mvn_c8_dat.geom_factor * gf
     eflux = (data-bkg)*dead/((gf*cf)*eff*dt)
     str_element, mvn_c8_dat, 'eflux', eflux, /add_replace

     IF KEYWORD_SET(tplot) THEN BEGIN
        qf = (mvn_c8_dat.quality_flag AND 128)/128 OR (mvn_c8_dat.quality_flag AND 64)/64
        ind = where(qf EQ 1, count)
        IF count GT 0 THEN data[ind, *, *] = 0.
        IF count GT 0 THEN eflux[ind, *, *] = 0.

        store_data,'mvn_sta_c8_e_gf_corr', data={x: time, y: TOTAL(eflux, 3)/ndef, v: energy}, $
                   dlim={ylog: 1, zlog: 1, datagap: 7., spec: 1, ytitle: 'STA C8', ztitle: 'eflux', no_interp: 1, $
                         ysubtitle: 'Energy [eV]'} ;, ytickformat: 'exponent'}

        ylim, 'mvn_sta_c8_e_gf_corr', .1, 40.e3, 1, /def
        zlim, 'mvn_sta_c8_e_gf_corr', 1.e3, 1.e9, 1, /def

        store_data,'mvn_sta_c8_d_gf_corr', data={x: time, y: TOTAL(eflux, 2)/nenergy, v: theta}, $
                   dlim={zlog: 1, datagap: 7., spec: 1, ytitle: 'STA C8', ztitle: 'eflux', no_interp: 1, $
                         ysubtitle: 'Def [deg]'}

        ylim, 'mvn_sta_c8_d_gf_corr', -50., 50., /def
        zlim, 'mvn_sta_c8_d_gf_corr', 1.e3, 1.e9, 1, /def
     ENDIF 
  ENDIF 
  
  RETURN
END
