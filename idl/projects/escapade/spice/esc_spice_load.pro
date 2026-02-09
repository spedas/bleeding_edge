;+
;
;PROCEDURE:       ESC_SPICE_LOAD
;
;PURPOSE:         Loads the ESCAPADE SPICE kernels and creates several
;                 tplot variables on the spacecraft position.
;
;INPUTS:          None.
;
;KEYWORDS:
;
;       RES:      Specifies the time resolution to be created tplots.
;                 Default is 60 s.
;
;     HELIO:      Obsolete: No longer needed to specify the heliospheric frame kernel.
;
;        km:      If set, the unit should be kilometer.
;                 Default is R_E (Earth Radii).
;
;NOTE:            As of 2025-11-17, only ESCAPADE science team members  
;                 are permitted to use this procedure only under the UCB-SSL remote servers.
;
;CREATED BY:      Takuya Hara on 2025-11-17.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-02-03 15:22:23 -0800 (Tue, 03 Feb 2026) $
; $LastChangedRevision: 34113 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/spice/esc_spice_load.pro $
;
;-
PRO esc_spice_load, trange=itime, verbose=verbose, blue=blue, gold=gold, resolution=res, $
                    load=load, clear=clear, info=info, km=km, _extra=extra;, helio=helio

  tr = timerange(itime)
  IF undefined(clear) THEN clear = 1
  IF undefined(load)  THEN load  = 1
 
  kernels = esc_spice_kernels(trange=tr, blue=blue, gold=gold, load=load, clear=clear, info=info)
  ;IF FILE_TEST(helio) THEN spice_kernel_load, helio ELSE RETURN

  IF ~undefined(blue) THEN bflg = FIX(blue) ELSE bflg = 0
  IF ~undefined(gold) THEN gflg = FIX(gold) ELSE gflg = 0
  IF (bflg + gflg) EQ 0 THEN BEGIN
     bflg = 1
     gflg = 1
  ENDIF 

  IF is_struct(info) THEN BEGIN
     w = WHERE(info.type EQ 'SPK' and info.obj_name EQ 'ESCAPADE_BLUE', nw)
     v = WHERE(info.type EQ 'SPK' and info.obj_name EQ 'ESCAPADE_GOLD', nv)
     IF nw GT 0 THEN tcov_b = minmax(time_double(info[w].trange))
     IF nv GT 0 THEN tcov_g = minmax(time_double(info[v].trange))
     IF tcov_b[0] GE tcov_g[0] THEN append_array, tcov, tcov_b[0] ELSE append_array, tcov, tcov_g[0]
     IF tcov_b[1] LE tcov_g[1] THEN append_array, tcov, tcov_b[1] ELSE append_array, tcov, tcov_g[1]
     IF tr[0] LT tcov[0] THEN tr[0] = time_double(time_string(tcov[0], prec=-1)) + 120.d0
     IF tr[1] GT tcov[1] THEN tr[1] = time_double(time_string(tcov[1], prec=-1)) - 120.d0
  ENDIF 
  
  IF undefined(res) THEN dt = 60.d0 ELSE dt = DOUBLE(res)
  time = dgen(range=tr, resolution=dt)

  IF KEYWORD_SET(km) THEN BEGIN
     rp = 1.d0 
     unit = '[km]'
  ENDIF ELSE BEGIN
     rp = 6378.1d0              ; Earth Radii
     unit = '[R_E]'
  ENDELSE 
 
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

  RETURN
END 
