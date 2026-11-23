;+
;
;PROCEDURE:       ESC_SPICE_LOAD
;
;PURPOSE:         Loads the ESCAPADE SPICE kernels and creates several
;                 tplot variables containing the spacecraft position data.
;
;INPUTS:          None.
;
;KEYWORDS:
;
;       RES:      Specifies the time resolution of the tplot variables to be created.
;                 Default is 60 s.
;
;        KM:      If set, uses kilometers as the distance unit.
;
;   KERNELS:      Returns a string array containing the names of the loaded SPICE/kernels.
;
;DOWNLOAD_ONLY:   If set, only loading the SPICE/kernels.
;
;    LOITER:      If set, creates tplot variables optimized for the Earth L2 Loiter phase.
;
;    CRUISE:      If set, creates tplot variables optimized for the cruise phase.
;
;NOTE:            As of 2025-11-17, only ESCAPADE science team members  
;                 are permitted to use this procedure only under the UCB-SSL remote servers.
;
;CREATED BY:      Takuya Hara on 2025-11-17.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-11-20 00:55:47 -0800 (Fri, 20 Nov 2026) $
; $LastChangedRevision: 35062 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/spice/esc_spice_load.pro $
;
;-
PRO esc_spice_load, trange=itime, kernels=kernels, verbose=verbose, blue=blue, gold=gold, resolution=res, $
                    load=load, clear=clear, info=info, km=km, _extra=extra, download_only=download_only,  $
                    loiter=loiter, cruise=cruise

  tr = timerange(itime)
  IF undefined(clear) THEN clear = 1
  IF undefined(load)  THEN load  = 1
 
  kernels = esc_spice_kernels(trange=tr, blue=blue, gold=gold, load=load, clear=clear, info=info)
  IF KEYWORD_SET(download_only) THEN RETURN

  IF ~undefined(blue) THEN bflg = FIX(blue) ELSE bflg = 0
  IF ~undefined(gold) THEN gflg = FIX(gold) ELSE gflg = 0
  IF (bflg + gflg) EQ 0 THEN BEGIN
     bflg = 1
     gflg = 1
  ENDIF 

  IF undefined(loiter) AND undefined(cruise) THEN loiter = 1
  
  IF is_struct(info) THEN BEGIN
     w = WHERE(info.type EQ 'SPK' and info.obj_name EQ 'ESCAPADE_BLUE', nw)
     v = WHERE(info.type EQ 'SPK' and info.obj_name EQ 'ESCAPADE_GOLD', nv)
     IF nw GT 0 THEN tcov_b = minmax(time_double(info[w].trange))
     IF nv GT 0 THEN tcov_g = minmax(time_double(info[v].trange))

     IF (bflg + gflg) EQ 2 THEN BEGIN
        IF tcov_b[0] GE tcov_g[0] THEN append_array, tcov, tcov_b[0] ELSE append_array, tcov, tcov_g[0]
        IF tcov_b[1] LE tcov_g[1] THEN append_array, tcov, tcov_b[1] ELSE append_array, tcov, tcov_g[1]
     ENDIF ELSE BEGIN
        IF ~undefined(tcov_b) THEN tcov = tcov_b
        IF ~undefined(tcov_g) THEN tcov = tcov_g
     ENDELSE
     
     IF tr[0] LT tcov[0] THEN tr[0] = time_double(time_string(tcov[0], prec=-1)) + 120.d0
     IF tr[1] GT tcov[1] THEN tr[1] = time_double(time_string(tcov[1], prec=-1)) - 120.d0
  ENDIF 
  
  IF undefined(res) THEN dt = 60.d0 ELSE dt = DOUBLE(res)
  time = dgen(range=tr, resolution=dt)
  
  IF KEYWORD_SET(km) THEN BEGIN
     rp = 1.d0 
     unit = '[km]'
  ENDIF ELSE BEGIN
     IF KEYWORD_SET(loiter) THEN BEGIN
        rp = 6378.1d0           ; Earth Radii
        unit = '[R_E]'
     ENDIF
     IF KEYWORD_SET(cruise) THEN BEGIN
        rp = !const.au * 1.d-3  ; AU
        unit = '[AU]'
     ENDIF
  ENDELSE 
  
  IF KEYWORD_SET(loiter) THEN BEGIN
     IF (bflg) THEN BEGIN
        b = spice_body_pos('ESCAPADE_BLUE', 'EARTH', utc=time, frame='GSE')
        store_data, 'escb_eph_gse', data={x: time, y: TRANSPOSE(b)/rp}, $
                    dlim={ytitle: 'BLUE', ysubtitle: 'GSE ' + unit, labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr', constant: 0.}
     ENDIF 
     IF (gflg) THEN BEGIN
        g = spice_body_pos('ESCAPADE_GOLD', 'EARTH', utc=time, frame='GSE')
        store_data, 'escg_eph_gse', data={x: time, y: TRANSPOSE(g)/rp}, $
                    dlim={ytitle: 'GOLD', ysubtitle: 'GSE ' + unit, labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr', constant: 0.}
     ENDIF

     IF (bflg + gflg) EQ 2 THEN BEGIN
        dist = b - g
        dist = SQRT(TOTAL(dist*dist, 1))
        store_data, 'esc_blue_gold_dist', data={x: time, y: dist/rp}, dlim={ytitle: 'BLUE-GOLD', ysubtitle: 'Distance ' + unit}
     ENDIF 
  ENDIF

  IF KEYWORD_SET(cruise) THEN BEGIN
     IF (bflg) THEN BEGIN
        b = spice_body_pos('ESCAPADE_BLUE', 'SUN', utc=time, frame='ECLIPJ2000')
        store_data, 'escb_eph_j2000', data={x: time, y: TRANSPOSE(b)/rp}, $
                    dlim={ytitle: 'BLUE', ysubtitle: 'J2000 ' + unit, labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr', constant: 0.}

        eb = spice_body_pos('ESCAPADE_BLUE', 'EARTH', utc=time, frame='GSE')
        mb = spice_body_pos('ESCAPADE_BLUE', 'MARS',  utc=time, frame='MSO')

        store_data, 'escb_eph_dist', data={x: time, y: [ [SQRT(TOTAL(b*b, 1))], [SQRT(TOTAL(eb*eb, 1))], [SQRT(TOTAL(mb*mb, 1))]]/rp}, $
                    dlim={ytitle: 'BLUE', ysubtitle: 'Distance ' + unit, labels: 'DIST!D' + ['S!N', 'E!N ' + unit, 'M!N']}
     ENDIF
     IF (gflg) THEN BEGIN
        g = spice_body_pos('ESCAPADE_GOLD', 'SUN', utc=time, frame='ECLIPJ2000')
        store_data, 'escg_eph_j2000', data={x: time, y: TRANSPOSE(g)/rp}, $
                    dlim={ytitle: 'GOLD', ysubtitle: 'J2000 ' + unit, labels: ['X', 'Y', 'Z'], labflag: -1, colors: 'bgr', constant: 0.}
        
        eg = spice_body_pos('ESCAPADE_GOLD', 'EARTH', utc=time, frame='GSE')
        mg = spice_body_pos('ESCAPADE_GOLD', 'MARS',  utc=time, frame='MSO')

        store_data, 'escg_eph_dist', data={x: time, y: [ [SQRT(TOTAL(g*g, 1))], [SQRT(TOTAL(eg*eg, 1))], [SQRT(TOTAL(mg*mg, 1))]]/rp}, $
                    dlim={ytitle: 'GOLD', ysubtitle: 'Distance ' + unit, labels: 'DIST!D' + ['S!N', 'E!N ' + unit, 'M!N']}
     ENDIF
  ENDIF
  
  RETURN
END 
