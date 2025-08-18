;+
;
;PROCEDURE:       MVN_QL_PFP_TPLOT2
;
;PURPOSE:         Creates quicklook summary tplot(s) of MAVEN PF packages. 
;
;INPUTS:          
;
;      TRANGE:    An array in any format accepted by time_double().
;                 The minimum and maximum values in this array specify
;                 the time range to load.
;
;KEYWORDS:
;
;       ORBIT:    Specifies the time range to show by using
;                 orbit number or range of orbit numbers (trange is ignored).
;                 Orbits are numbered using the NAIF convention, where
;                 the orbit number increments at periapsis. Data are
;                 loaded from the apoapsis preceding the first orbit
;                 (periapsis) number to the apoapsis following the
;                 last orbit number.
;
;   NO_DELETE:    Not deleting pre-exist tplot variable(s).
;
;         PAD:    Restores the SWEA resampling PAD tplot save files by
;                 using 'mvn_swe_pad_restore'. 
;   
;       TPLOT:    Plots the summary tplots.
;
;      WINDOW:    Sets the window number to show tplots.
;                 Default is 0.
;
;       TNAME:    Returns the tplot names to plot (or defines the
;                 tplot names to plot if user knows the precise names).
;
;      PHOBOS:    Computes the MAVEN and Phobos distance by 'mvn_phobos_tplot'.
;
;      BCRUST:    Defines to execute calculating the crustal magnetic
;                 field model, if tplot save files are not available. 
;
;   BURST_BAR:    Draw a color bar during the time intervals when the burst
;                 (archive) PFP data has been already downlinked and available.  
;
;      SUNDIR:    Computes the direction of the Sun in the payload coordinates.
;                 It can be useful for Tohban to check the MAG rolls.
;
;      TOHBAN:    If set, some additional tplot variables, which burst request
;                 "Tohban" should sometimes check, are automatically generated.
;                    - Currently available burst data time segments,
;                    - Phobos-MAVEN distance,
;                    - Sun direction in the payload coordinates used
;                      to check the MAG rolls.
;
;SPACEWEATHER:    If set, some representative tplot variables useful
;                 for the spaceweather studies will be created. 
;
;     SWIA, SWEA, STATIC, SEP, MAG, LPW, EUV individual instruments' switches to load:
;                 Default = 1 except for EUV. If they set to be zero (e.g., swia=0), it skips to load.                 
;
;NOTE:            This routine is assumed to be used when there are
;                 no tplot variables.
;
;CREATED BY:      Takuya Hara on 2015-04-09.
;
;LAST MODIFICATION:
; $LastChangedBy: jimm $
; $LastChangedDate: 2024-03-14 13:06:27 -0700 (Thu, 14 Mar 2024) $
; $LastChangedRevision: 32496 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_ql_pfp_tplot2.pro $
;
;-
PRO mvn_ql_pfp_tplot2, var, orbit=orbit, verbose=verbose, no_delete=no_delete, no_download=no_download, $
                       pad=pad, tplot=tplot, window=window, tname=ptname, phobos=phobos, $
                       bcrust=bcrust, burst_bar=bbar, bvec=bvec, sundir=sundir, tohban=tohban, tobhan=tobhan, $
                       swia=swi, swea=swe, static=sta, sep=sep, mag=mag, lpw=lpw, euv=euv, spaceweather=spw

  oneday = 24.d0 * 3600.d0
  nan = !values.f_nan
  IF ~keyword_set(no_delete) THEN store_data, '*', /delete, verbose=verbose
  IF keyword_set(window) THEN wnum = window ELSE wnum = 0
  IF SIZE(bcrust, /type) NE 0 THEN bflg = bcrust

  tplot_options, get_options=topt
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
     ENDIF ELSE BEGIN
        tspan_exists = (MAX(topt.trange_full) GT time_double('2014-09-22'))
        IF (tspan_exists) THEN trange = topt.trange_full
        undefine, tspan_exists
     ENDELSE 
  ENDELSE
  
  IF SIZE(trange, /type) EQ 0 THEN BEGIN
     dprint, 'You must set the specified time interval to load.'
     RETURN
  ENDIF

  IF KEYWORD_SET(spw) THEN BEGIN
     IF SIZE(swi, /type) EQ 0 THEN swi = 1
     IF SIZE(swe, /type) EQ 0 THEN swe = 1
     IF SIZE(sta, /type) EQ 0 THEN sta = 0
     IF SIZE(sep, /type) EQ 0 THEN sep = 1
     IF SIZE(mag, /type) EQ 0 THEN mag = 0
     IF SIZE(lpw, /type) EQ 0 THEN lpw = 0
     IF SIZE(euv, /type) EQ 0 THEN euv = 1
     IF SIZE(bbar, /type) EQ 0 THEN bbar = 1
  ENDIF 

  IF SIZE(swi, /type) EQ 0 THEN iflg = 1 ELSE iflg = swi 
  IF SIZE(swe, /type) EQ 0 THEN eflg = 1 ELSE eflg = swe 
  IF SIZE(sta, /type) EQ 0 THEN tflg = 1 ELSE tflg = sta 
  IF SIZE(sep, /type) EQ 0 THEN pflg = 1 ELSE pflg = sep 
  IF SIZE(mag, /type) EQ 0 THEN mflg = 1 ELSE mflg = mag 
  IF SIZE(lpw, /type) EQ 0 THEN lflg = 1 ELSE lflg = lpw 
  IF SIZE(euv, /type) EQ 0 THEN vflg = 0 ELSE vflg = euv ; Perhaps it changes someday... 
  IF keyword_set(tobhan) THEN BEGIN
     dprint, 'It is a misspelling! (Tobhan -> Tohban)...', dlevel=2, verbose=verbose
     tohban = 1                 ; Many people tend to mistake its spelling...
  ENDIF 
  IF keyword_set(tohban) THEN BEGIN
     IF SIZE(bbar, /type) EQ 0 THEN bbar = 1
     IF SIZE(phobos, /type) EQ 0 THEN phobos = 1
     IF SIZE(sundir, /type) EQ 0 THEN sundir = 1
  ENDIF 

  ; SPICE
  IF TOTAL(mvn_spice_valid_times(trange)) LT 2 THEN BEGIN
     mvn_spice_load, trange=trange, /download_only, verbose=verbose, no_download=no_download
     store_data, 'orb*num', /delete, verbose=verbose
  ENDIF 
  ;status = EXECUTE("mvn_spice_load, trange=trange, /download_only, verbose=verbose")
  ;IF status EQ 0 THEN $
  ;   dprint, 'SPICE/kernels are unexpectedly unable to load.', dlevel=2, verbose=verbose
  ;undefine, status

  ; SWEA
  IF (eflg) THEN BEGIN
     mvn_swe_load_l2, trange, prod=['svypad','svyspec'], spiceinit=1 ;jmm, 2024-03-14
     status = EXECUTE("mvn_swe_engy = SCOPE_VARFETCH('mvn_swe_engy', common='swe_dat')")
     IF (SIZE(mvn_swe_engy, /type) NE 8) THEN BEGIN
        dprint, 'No SWEA data found.', verbose=verbose, dlevel=2
        no_swe:
        emin = 3.
        emax = 4627.5
        vswe = [emin, emax]
        xswe = trange
        yswe = REFORM(REPLICATE(nan, 4), [2, 2])
        noswe = 1
     ENDIF ELSE BEGIN
        vswe = (SCOPE_VARFETCH('swe_swp', common='swe_cal'))[*, 0]
        emin = MIN(vswe, max=emax)
        
        mvn_swe_convert_units, mvn_swe_engy, 'EFLUX'
        xswe = mvn_swe_engy.time
        yswe = TRANSPOSE(mvn_swe_engy.data)
        
        idx = WHERE(xswe GE trange[0] AND xswe LE trange[1], nidx)
        IF nidx GT 0 THEN BEGIN
           xswe = xswe[idx]
           yswe = yswe[idx, *]
           noswe = 0
        ENDIF ELSE BEGIN
           dprint, 'There is no data in the specified time interval.', dlevel=2, verbose=verbose
           GOTO, no_swe
        ENDELSE
        undefine, idx, nidx
     ENDELSE 
     undefine, status
     store_data, 'mvn_swe_etspec', data={x:xswe, y:yswe, v:vswe}, $
                 dlimits={spec: 1, ytitle: 'SWEA', ysubtitle: 'Energy [eV]', yticks: 0, $
                          yminor: 0, y_no_interp: 1, x_no_interp: 1, $
                          ztitle: 'EFLUX', datagap: 300}, limit={ytickformat: 'mvn_ql_pfp_tplot_ytickname_plus_log'}
     ylim, 'mvn_swe_etspec', emin, emax, 1, /def
     IF (noswe) THEN BEGIN
        zlim, 'mvn_swe_etspec', 1.d4, 1.d9, 1, /def
        options, 'mvn_swe_etspec', bottom=7, top=254, no_color_scale=0
     ENDIF ELSE zlim, 'mvn_swe_etspec', 0, 0, 1, /def
     undefine, xswe, yswe, vswe
     undefine, emin, emax
     IF keyword_set(pad) THEN mvn_swe_pad_restore, trange 
     mvn_swe_clear
  ENDIF 

  ; SWIA
  IF (iflg) THEN BEGIN
     trange_full = time_double( time_string(trange, tformat='YYYY-MM-DD') )
     IF time_string(trange[1], tformat='hh:mm:ss') NE '00:00:00' THEN $
        trange_full[1] += oneday
     IF MEAN(trange - trange_full) NE 0.d0 THEN clip = 1 ELSE clip = 0
     mvn_swia_load_l2_data, trange=trange_full, /tplot, /loadspec, /loadcoarse, /eflux
     
     undefine, trange_full
     tname = tnames('mvn_swis_en_eflux', ntplot)
     IF ntplot EQ 0 THEN BEGIN
        dprint, 'There is no SWIA tplot variables.', dlevel=2, verbose=verbose
        tname = 'mvn_swis_en_eflux'
        store_data, tname, data={x: trange, y: REFORM(REPLICATE(nan, 4), [2, 2]), v: [25.9375, 23244.8]}, $
                    dlim={datagap: [180L], ylog: [1L], zlog: [1L], spec: [1L], no_interp: [1L], $
                          yrange: [4L, 30000], ystyle: [1L], zrange: [1.e4, 1.e8]}
     ENDIF ELSE BEGIN
        aname = tnames('mvn_swi*')
        idx = WHERE(aname NE tname)
        store_data, aname[idx], /delete, verbose=verbose
        undefine, aname, idx
        
        get_data, tname, data=d, dlim=dl, lim=lim
        extract_tags, d2, d, tags=['x', 'y', 'v']
        extract_tags, dl, d, except=['x', 'y', 'v']
        
        store_data, tname, data=d2, dlim=dl, lim=lim
        IF (clip) THEN time_clip, tname, trange[0], trange[1], /replace
        undefine, d, d2, dl, lim
     ENDELSE 
     options, tname, ztitle='EFLUX', ytitle='SWIA', ysubtitle='Energy [eV]', ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log', $
              bottom=7, top=254, no_color_scale=0
     undefine, tname, ntplot, clip
  ENDIF 

  ; STATIC
  IF (tflg) THEN BEGIN
     mvn_sta_l2_load, trange=trange, sta_apid=['c0', 'c6'] 
     mvn_sta_l2_tplot
     tname = tnames('mvn_sta*', ntplot, index=n)
     statn0 = 'mvn_sta_c' + ['0_E', '0_H_E', '6_M_twt']
     statn = tnames(statn0, index=m)
     
     IF ntplot EQ 0 THEN BEGIN
        dprint, 'There are no STATIC tplot variables.', dlevel=2, verbose=verbose

        store_data, statn0[0], data={x: trange, y: REFORM(REPLICATE(nan, 4), [2, 2]), v: [0.1046, 31380.]}, $
                    dlim={yrange: [0.1, 4.e4], ystyle: 1, ylog: 1, zrange: [1.e3, 1.e9], zstyle: 1, zlog: 1, $
                          datagap: 7., spec: 1}
        store_data, statn0[1], data={x: trange, y: REFORM(REPLICATE(nan, 4), [2, 2]), v: [0.1046, 31380.]}, $
                    dlim={yrange: [0.1, 4.e4], ystyle: 1, ylog: 1, zrange: [1.e3, 1.e9], zstyle: 1, zlog: 1, $
                          datagap: 7., spec: 1}
        store_data, statn0[2], data={x: trange, y: REFORM(REPLICATE(nan, 4), [2, 2]), v: [0.1046, 31380.]}, $
                    dlim={yrange: [0.5, 100.], ystyle: 1, ylog: 1, zrange: [1.e3, 1.e9], zstyle: 1, zlog: 1, $
                          datagap: 7., spec: 1}  
     ENDIF ELSE BEGIN
        state = 'idx = WHERE('
        FOR i=0, N_ELEMENTS(m)-1 DO BEGIN
           state += '(n eq m[' + string(i, '(I0)') + '])'
           IF i NE N_ELEMENTS(m)-1 THEN state += ' OR '
        ENDFOR 
        undefine, i
        state += ', nidx, complement=jdx, ncomplement=njdx)'
        
        status = EXECUTE(state)
        IF status EQ 1 THEN IF njdx GT 0 THEN store_data, n[jdx], /delete, verbose=verbose
        undefine, idx, jdx, nidx, njdx
        undefine, state, status
     ENDELSE 
     undefine, statn0, statn, tname, n, m
     tname = tnames('mvn_sta*', ntplot)
     options, tname, ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log', ztitle='EFLUX'
     options, tname[0], ysubtitle='Energy [eV]' 
     options, tname[1], ysubtitle='Energy [eV]!CM/q > 12' 
     options, tname[2], ysubtitle='Mass [amu]'

     suffix = STRARR(ntplot)
     product = STRARR(ntplot)
     FOR i=0, ntplot-1 DO BEGIN
        get_data, tname[i], data=d, dl=dl, lim=lim
        extract_tags, dall, dl
        extract_tags, dall, lim
        lim = 0
        IF SIZE(d, /type) EQ 8 THEN $
           store_data, tname[i], data=d, dl=dall, lim=lim $
        ELSE store_data, tname[i], data=STRLOWCASE(d), dl=dall, lim=lim
        IF tname[i] NE STRLOWCASE(tname[i]) THEN $
           store_data, tname[i], newname=STRLOWCASE(tname[i])
        
        suffix[i] = STRMID(STRLOWCASE(tname[i]), STRLEN(tname[i])-2)
        product[i] = (STRSPLIT(STRLOWCASE(tname[i]), '_', /extract))[2]
        undefine, d, dall, dl, lim
     ENDFOR
     undefine, tname, ntplot

     tname = tnames('mvn_sta*') 
     apid = ['2a','c0','c2','c4','c6','c8', $
             'ca','cc','cd','ce','cf','d0', $
             'd1','d2','d3','d4','d6','d7', $
             'd8','d9','da','db']
     napid = N_ELEMENTS(apid)
     FOR i=0, napid-1 DO BEGIN
        idx = WHERE(product EQ apid[i], cnt)
        IF cnt GT 0 THEN options, tname[idx], ytitle='STA ' + STRUPCASE(apid[i]), $
                                  bottom=7, top=254, no_color_scale=0
        undefine, idx, cnt
     ENDFOR
     undefine, apid, napid
     undefine, tname, suffix, product
  ENDIF 

  ; SEP
  ; I might change tplot variables used as a quicklook, 
  ; because the latest procedure to load SEP data creates
  ; a lot of new tplot variables.                              
  IF (pflg) THEN BEGIN
     ptime1 = SYSTIME(/sec)
     status = EXECUTE("mvn_sep_load, trange=trange")

     pname = tnames('*', create_time=ptime2)
     pname = pname[WHERE(ptime2 GT ptime1)]
     w = WHERE(STRMATCH(pname, 'mvn_SEP*_eflux') EQ 0, nw, comp=v, ncomp=nv)
     IF nw GT 0 THEN store_data, pname[w], /delete, verbose=verbose
     IF nv GT 0 THEN BEGIN
        FOR ip=0, nv-1 DO store_data, pname[v[ip]], newname=STRLOWCASE(pname[v[ip]])
        pname = STRLOWCASE(pname[v])
     ENDIF ELSE BEGIN
        undefine, pname
        append_array, pname, 'mvn_sep1' + ['f', 'r'] + '_ion_eflux'
        append_array, pname, 'mvn_sep1' + ['f', 'r'] + '_elec_eflux'
        append_array, pname, 'mvn_sep2' + ['f', 'r'] + '_ion_eflux'
        append_array, pname, 'mvn_sep2' + ['f', 'r'] + '_elec_eflux'
        FOR ip=0, N_ELEMENTS(pname)-1 DO $
           store_data, pname[ip], data={x: trange, y: REFORM(REPLICATE(nan, 4), [2, 2]), v: [10., 6000]}, $
                       dlim={spec: 1, ylog: 1, ystyle: 1, yrange: [10., 6000.]}
     ENDELSE 
     
     options, pname, ysubtitle='Energy [keV]', ztitle='EFLUX', ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log', /def
     zlim, pname, 1.e0, 1.e5, 1
     undefine, w, v, nw, nv

     w = WHERE(STRMATCH(pname, '*ion*') EQ 1, nw, comp=v, ncomp=nv)
     pcomp = (STRSPLIT(TRANSPOSE(pname), '_', /extract)).toarray()

     IF nw GT 0 THEN FOR ip=0, nw-1 DO options, pname[w[ip]], ytitle='SEP ' + STRUPCASE(STRMID(pcomp[w[ip], 1], 3)) + '!CIon'
     IF nv GT 0 THEN BEGIN
        ylim, pname[v], 10., 300., 1
        FOR ip=0, nv-1 DO options, pname[v[ip]], ytitle='SEP ' + STRUPCASE(STRMID(pcomp[v[ip], 1], 3)) + '!Ce!E-!N'
     ENDIF 
     undefine, w, v, nw, nv
     options, pname, bottom=7, top=254, no_color_scale=0
     undefine, pname, pcomp, ip
  ENDIF 

  ; LPW
  IF (lflg) THEN BEGIN
     lpath = 'maven/data/sci/lpw/l2/'
     lname = 'YYYY/MM/mvn_lpw_l2_lpiv_YYYYMMDD_*.cdf'
     lfile = mvn_pfp_file_retrieve(lpath + lname, trange=trange, /daily, /valid_only, /last)
     IF lfile[0] NE '' THEN BEGIN
        lflg1 = 0
        mvn_lpw_cdf_cdf2tplot, file=lfile, varformat='data'
        get_data, 'mvn_lpw_lp_iv_l2', data=d, dl=dl, lim=lim
        extract_tags, d1, TEMPORARY(d), tags=['x', 'y', 'v']
        extract_tags, nlim, lim, tags=['yrange', 'ylog', 'zlog', 'spec', 'no_interp', 'ystyle']
        nz = WHERE(d1.y NE 0, nnz) ; here, guard against no non-zero data
        IF (nnz GT 0) THEN BEGIN
           mndy = ABS(MIN(d1.y[nz]))
           gz = WHERE(d1.y GT 0, ngz)
           lz = WHERE(d1.y LT 0, nlz)
           zz = WHERE(d1.y EQ 0, nzz)
           IF (ngz GT 0) THEN d1.y[gz] = ALOG10(d1.y[gz])
           IF (nlz GT 0) THEN d1.y[lz] = ALOG10(ABS(d1.y[lz]))
           IF (nzz GT 0) THEN d1.y[zz] = ALOG10(mndy)
        ENDIF
        store_data, 'mvn_lpw_iv', data=d1, dl=dl, lim=nlim
        options, 'mvn_lpw_iv', 'zrange', [-10, -4]
        options, 'mvn_lpw_iv', ytitle='LPW (IV)', ysubtitle='[V]', ztitle='Log(abs(IV))', $
                 xsubtitle='', zsubtitle=''
        get_data, 'mvn_lpw_iv', lim=nlim
        store_data, 'mvn_lpw_lp_iv_l2', /delete, verbose=verbose
        IF (trange[1]-MAX(d1.x)) GT 0.9 * oneday THEN lflg1 = 1
     ENDIF ELSE lflg1 = 1
     IF (lflg1) THEN BEGIN
        lpath = 'maven/data/sci/lpw/tplot/'
        lname = 'YYYY/mvn_lpw_iv_YYYYMMDD.tplot'
        lfile = mvn_pfp_file_retrieve(lpath + lname, trange=trange, /daily, /valid_only)
        IF (lfile[0] NE '') THEN BEGIN
           FOR i=0, N_ELEMENTS(lfile)-1 DO BEGIN
              tplot_restore, filenames=lfile[i]
              get_data, 'mvn_lpw_iv', data=dd
              IF SIZE(dd.y, /n_dimen) EQ 2 THEN BEGIN
                 IF SIZE(d2, /type) EQ 0 THEN d2 = {x: dd.x, y: dd.y, v: dd.v} $
                 ELSE d2 = {x: [d2.x, dd.x], y: [d2.y, dd.y], v: [d2.v, dd.v]}
                 w = WHERE(d2.x GE trange[0] AND d2.x LE trange[1], nw)
                 IF nw GT 0 THEN d2 = {x: d2.x[w], y: d2.y[w, *], v: d2.v[w, *]}
              ENDIF
              IF SIZE(d2, /type) EQ 8 THEN store_data, 'mvn_lpw_iv', data=d2
              undefine, dd, w, nw
           ENDFOR
           IF (~IS_STRUCT(d2)) THEN lflg2 = 1 $
           ELSE BEGIN
              IF SIZE(d1, /type) NE 0 THEN BEGIN
                 w = WHERE(d2.x GT MAX(d1.x), nw)
                 IF nw GT 0 THEN d2 = {x: d2.x[w], y: d2.y[w, *], v: d2.v[w, *]}
                 store_data, 'mvn_lpw_iv', data={x: [d1.x, d2.x], y: [d1.y, d2.y], v: [d1.v, d2.v]}, dlim=dl, lim=nlim
                 undefine, w, nw
              ENDIF 
           ENDELSE  
        ENDIF  
     ENDIF 
     get_data, 'mvn_lpw_iv', index=ilpw
     IF (ilpw EQ 0) THEN $
        store_data, 'mvn_lpw_iv', data={x: trange, y: REFORM(REPLICATE(nan, 4), [2, 2]), v: [-45, 45]}, $
                    dlim={yrange: [-43.3274, 43.2675], ystyle: 1, zrange: [-10, -4], zstyle: 1, spec: 1}

     ylim, 'mvn_lpw_iv', -43.3274, 43.2675
     options, 'mvn_lpw_iv', bottom=7, top=254, no_color_scale=0, datagap=60.d0, spec=1
     options, 'mvn_lpw_iv', ytitle='LPW (IV)', ysubtitle='[V]', ztitle='Log(abs(IV))'

  ;   lpath = 'maven/data/sci/lpw/l2/'
  ;   lname = 'YYYY/MM/mvn_lpw_l2_wspecpas_YYYYMMDD_*.cdf'
  ;   lfile = mvn_pfp_file_retrieve(lpath + lname, trange=trange, /daily, /valid_only, /last)

  ;   IF lfile[0] NE '' THEN BEGIN
  ;      mvn_lpw_cdf_cdf2tplot, file=lfile, varformat='data'
  ;      get_data, 'mvn_lpw_w_spec_pas_l2', data=d, dl=dl, lim=lim
  ;      extract_tags, nlim, lim, tags=['yrange', 'ylog', 'zlog', 'spec', 'no_interp', 'ystyle']
  ;      store_data, 'mvn_lpw_w_spec_pas_l2', data=d, dl=dl, lim=nlim
  ;      zlim, 'mvn_lpw_w_spec_pas_l2', 1.e-15, 1.e-8, /def
  ;      options, 'mvn_lpw_w_spec_pas_l2', ylog=1
  ;      undefine, d, dl, lim, nlim
  ;   ENDIF ELSE BEGIN
  ;      store_data, 'mvn_lpw_w_spec_pas_l2', data={x: trange, y: REFORM(REPLICATE(nan, 4), [2, 2]), v: [1., 2.d6]}, $
  ;                  dlim={yrange: [1, 2.d6], ystyle: 1, ylog: 1, zrange: [1.e-14, 1.e-5], zstyle: 1, zlog: 1, spec: 1}  
  ;      options, 'mvn_lpw_w_spec_pas_l2', bottom=7, top=254
  ;   ENDELSE 
  ;   options, 'mvn_lpw_w_spec_pas_l2', ytitle='LPW (pas)', ysubtitle='f [Hz]', ztitle='Pwr', $
  ;            xsubtitle='', zsubtitle=''
  ;   undefine, lpath, lname, lfile
  ENDIF 

  ; EUV
  IF (vflg) THEN BEGIN
     mvn_euv_load, /all
     get_data, 'mvn_euv_data', data=vd
     get_data, 'mvn_euv_flag', data=vf, index=ivf
     IF (ivf) THEN w = WHERE(vf.y EQ 0, nw) ELSE nw = 0
     IF nw GT 0 THEN vd = {x: vd.x[w], y: vd.y[w, *]} $
     ELSE vd = {x: trange, y: REFORM(REPLICATE(nan, 6), [2, 3])}
     undefine, w, nw

     store_data, 'mvn_euv_irrad', data=vd, dlim={datagap: 60., ysubtitle: '[W/m!E2!N]', ytickformat: 'mvn_ql_pfp_tplot_ytickname_plus_log', ylog: 1}
     split_vec, 'mvn_euv_irrad', suffix='_ch_' + ['a', 'b', 'c']
     options, 'mvn_euv_irrad', labels=['ch_a:!C  17-22 nm', 'ch_b:!C  0-7 nm', 'ch_c:!C  121-122 nm'], $
              ytitle='EUV!CIrradiance', labflag=1, colors='bgr', /def
     options, 'mvn_euv_irrad', labsize=0.8
     options, 'mvn_euv_irrad_ch_a', ytitle='EUV!C17-22 nm', /def
     options, 'mvn_euv_irrad_ch_b', ytitle='EUV!C0-7 nm', /def
     options, 'mvn_euv_irrad_ch_c', ytitle='EUV!C121-122 nm', /def
     store_data, 'mvn_euv_' + ['data', 'dfreq', 'ddata', 'flag'], /delete, verbose=verbose
  ENDIF 

  ; MAG 
  bvec = 'mvn_mag_bmso_1sec'
  IF (mflg) THEN BEGIN
     mvn_mag_load, trange=trange, timecrop=trange
     tname = tnames('mvn_B*', ntplot)
     IF ntplot GT 0 THEN BEGIN
        get_data, tname, alim=alim, data=b
        lvl = alim.level
        btot = SQRT(TOTAL(b.y*b.y, 2))

        valid = spice_valid_times(time_ephemeris(b.x), object='MAVEN_SPACECRAFT')
        idx = WHERE(valid EQ 1B, nidx)
        IF FLOAT(nidx) / FLOAT(N_ELEMENTS(valid)) GT 0.5 THEN check_obj = 'MAVEN_SPACECRAFT'

        undefine, alim, b
        undefine, valid, idx, nidx
        status = EXECUTE("spice_vector_rotate_tplot, 'mvn_B_1sec', 'MAVEN_MSO', verbose=verbose, check_object=check_obj")
        IF status EQ 1 THEN BEGIN 
           store_data, 'mvn_B_1sec', /delete, verbose=verbose
           bvec = 'mvn_mag_bmso_1sec'
           store_data, 'mvn_B_1sec_MAVEN_MSO', newname=bvec
           frame = 'MSO'
           options, bvec, ysubtitle='Bmso [nT]', /def
        ENDIF ELSE BEGIN
           bvec = 'mvn_mag_bpl_1sec'
           store_data, 'mvn_B_1sec', newname=bvec
           frame = 'PL'
           options, bvec, ysubtitle='Bpl [nT]', /def
        ENDELSE 
     ENDIF ELSE BEGIN
        lvl = ''
        bvec = 'mvn_mag_bmso_1sec'
        frame = 'MSO'
        store_data, bvec, data={x: trange, y: REFORM(REPLICATE(nan, 6), [2, 3])}, dlim={ysubtitle: 'Bmso [nT]'}
        btot = [nan, nan]
     ENDELSE 
     undefine, tname, ntplot
     options, bvec, labels=['Bx', 'By', 'Bz'], colors='bgr', labflag=1, constant=0, /def
     IF lvl NE '' THEN options, bvec, ytitle='MAG ' + lvl ELSE options, bvec, ytitle='MAG'
     get_data, bvec, data=b ;, dl=bl
     bmax = MAX(btot, /nan)

     copy_data, bvec, bvec + '_symlog'
     options, bvec + '_symlog', tplot_routine='mplot_symlog'

     store_data, 'mvn_mag_bamp_1sec', data={x: b.x, y: btot}, dlimits={ysubtitle: '|B| [nT]'}
     IF lvl NE '' THEN options, 'mvn_mag_bamp_1sec', ytitle='MAG ' + lvl ELSE options, 'mvn_mag_bamp_1sec', ytitle='MAG'
     
     mvn_model_bcrust_load, trange, verbose=verbose, calc=bflg
     store_data, 'mvn_mag_bamp', data=['mvn_mag_bamp_1sec', 'mvn_mod_bcrust_amp'], $
                 dlimits={labels: ['Data', 'Model'], colors: [0, 2], labflag: -1, ysubtitle: '|B| [nT]'} 
     IF lvl NE '' THEN options, 'mvn_mag_bamp', ytitle='MAG ' + lvl ELSE options, 'mvn_mag_bamp', ytitle='MAG'

     get_data, 'mvn_mod_bcrust_amp', data=bcrust_mod
     If(is_struct(bcrust_mod)) Then bmax = max([bmax, bcrust_mod.y], /nan) ;needed if there is no MAG data
     IF bmax GT 100. THEN blog = 1 ELSE blog = 0 ; It means B field Log scale or not.     
     IF (blog) THEN BEGIN
        ylim, 'mvn_mag_bamp', 0.5, bmax*1.1, 1
        options, 'mvn_mag_bamp', ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log'
     ENDIF
     undefine, bmax, blog, status
     
     bphi = ATAN(b.y[*, 1], b.y[*, 0])
     bthe = ASIN(b.y[*, 2] / btot)
     idx = WHERE(bphi LT 0., nidx)
     IF nidx GT 0 THEN bphi[idx] += 2. * !pi
     undefine, idx, nidx

     aopt = {yaxis: 1, ystyle: 1, yrange: [-90., 90.], ytitle: 'Bthe [deg]', color: 2, yticks: 4, yminor: 3}
     IF tag_exist(topt, 'charsize') THEN str_element, aopt, 'charsize', topt.charsize, /add
     store_data, 'mvn_mag_bang_1sec', data={x: b.x, y: [ [2.*bthe*!RADEG + 180.], [bphi*!RADEG]]}, $
                 dlimits={psym: 3, colors: [2, 0], ytitle: 'MAG ' + '(' + frame + ')', ysubtitle: 'Bphi [deg]', $
                          yticks: 4, yminor: 3, constant: 180, axis: aopt}
     ylim, 'mvn_mag_bang_1sec', 0., 360., 0., /def
     options, 'mvn_mag_bang_1sec', ystyle=9
     undefine, bphi, bthe, b
  ENDIF 

; Ephemeris, current and timecrop keywords are now obsolete, but
; trange is needed for input, jmm, 2023-10-09
  maven_orbit_tplot, trange = trange, /load
; maven_orbit_tplot, /current, /load, timecrop=[-2.d0, 2.d0]*oneday +
; trange ; +/- 2 day is buffer.
  options, 'alt2', panel_size=2./3., ytitle='Alt. [km]'
  IF KEYWORD_SET(spw) THEN BEGIN
     options, ['twake', 'tpileup', 'tsheath', 'twind'], 'color'
     options, 'twake', colors=2
     options, 'tpileup', colors=5
     options, 'tsheath', colors=4
     options, 'twind', colors=0
     options, 'stat', yminor=2, labflag=-1, labels=['WIND', 'SHEATH', 'PILEUP', 'SHADOW'], ytitle='Orbit!CFraction'
     ylim, 'stat', -0.05, 1.05
  ENDIF
  IF keyword_set(phobos) THEN BEGIN
     mvn_phobos_tplot, trange=trange
     options, 'Phobos-MAVEN', panel_size=0.75, ytitle='Phobos!CMAVEN', ylog=1, /def
  ENDIF 
  IF keyword_set(bbar) THEN BEGIN
     status = EXECUTE("swica = SCOPE_VARFETCH('swica', common='mvn_swia_data')")
     IF SIZE(swica, /type) EQ 8 THEN BEGIN
        btime = swica.time_unix + 4.d0 * swica.num_accum/2.d0
        bdata = FLTARR(N_ELEMENTS(btime))
        bdata[*] = 1.
        ; Forward survey
        dt = btime[1:N_ELEMENTS(btime)-1] - btime[0:N_ELEMENTS(btime)-2]
        gap = FLOAT(ROUND(MIN(dt))) 
        idx = WHERE(dt GT 600., ndat)
        IF ndat GT 0 THEN BEGIN
           btime = [btime, btime[idx] + gap/2.d0]
           bdata = [bdata, REPLICATE(nan, ndat)]
           idx = SORT(btime)
           btime = btime[idx]
           bdata = bdata[idx]
        ENDIF 
        undefine, idx, ndat, dt
        ; Backward survey
        dt = ABS((REVERSE(btime))[1:N_ELEMENTS(btime)-1] - (REVERSE(btime))[0:N_ELEMENTS(btime)-2])
        idx = WHERE(dt GT 600., ndat)
        IF ndat GT 0 THEN BEGIN
           btime = [btime, (REVERSE(btime))[idx] - gap/2.d0]
           bdata = [bdata, REPLICATE(nan, ndat)]
           idx = SORT(btime)
           btime = btime[idx]
           bdata = bdata[idx]
        ENDIF 
        undefine, idx, ndat, dt
     ENDIF ELSE BEGIN
        btime = trange
        bdata = [nan, nan]
     ENDELSE 
     store_data, 'burst_flag', data={x: btime, y: [ [bdata], [bdata] ], v: [0, 1]}, $
                 dlim={ytitle: 'BST', yticks: 1, yminor: 1, ytickname: [' ', ' '], spec: 1, $
                       no_color_scale: 1, panel_size: 0.2, xticklen: 0.5}
     options, 'burst_flag', bottom=0, top=6 
     zlim, 'burst_flag', 0, 1, /def
  ENDIF 
  IF keyword_set(sundir) THEN BEGIN
     tsundir = dgen(range=trange, resolution=1.d0)
     ; MAVEN_SSO direction of Sun
     store_data,'mvn_sundir', data={x: tsundir, y: REPLICATE(1., N_ELEMENTS(tsundir)) # [1.,0.,0.], v: INDGEN(3)}, $
                dlim={labels: ['X', 'Y', 'Z'], labflag: 1, colors: 'bgr', $
                      spice_master_frame: 'MAVEN_SPACECRAFT', spice_frame: 'MAVEN_SSO'}
     spice_vector_rotate_tplot, 'mvn_sundir', 'MAVEN_SPACECRAFT', trange=trange, $
                                check='MAVEN_SPACECRAFT', suffix='_payload', verbose=verbose
     store_data, 'mvn_sundir', /delete, verbose=verbose
     options, 'mvn_sundir_payload', ytickinterval=1, yminor=4, constant=[-1., 0., 1.], $
              ytitle='S/C!CSundir', panel_size=0.75, /def
     ylim, 'mvn_sundir_payload', -1.25, 1.25, /def
  ENDIF 
  
  tplot_options, opt=topt 
  IF keyword_set(tplot) THEN BEGIN
     IF SIZE(ptname, /type) EQ 0 THEN BEGIN
        IF KEYWORD_SET(spw) THEN $
           ptname = ['mvn_euv_irrad_ch_b', 'mvn_sep1f_ion_eflux', 'mvn_sep1f_elec_eflux', $
                     'mvn_swis_en_eflux', 'mvn_swe_etspec', 'stat'] $
        ELSE $
           ptname = ['mvn_sep1f_ion_eflux', 'mvn_sep1r_ion_eflux', 'mvn_sep1f_elec_eflux', $
                     'mvn_sta_c0_e', 'mvn_sta_c6_m', 'mvn_swis_en_eflux', $
                     'mvn_swe_etspec', 'mvn_lpw_iv', 'mvn_mag_bamp', 'mvn_mag_bang_1sec', 'alt2']

        IF keyword_set(bbar) THEN ptname = [ptname, 'burst_flag'] 
        IF keyword_set(tohban) THEN ptname = ['mvn_sundir_payload', 'Phobos-MAVEN', ptname]
     ENDIF 
     tplot, ptname, wi=wnum 
  ENDIF 
  RETURN
END
