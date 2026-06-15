;+
;
;FUNCTION:        ESC_IESA_GET_SW
;
;PURPOSE:         Returns EESA-i Solar Wind (SW) data stored in common blocks.
;
;INPUTS:          The spacecraft is specified via the /blue or /gold keyword.
;
;KEYWORDS:
;
;      BLUE:      Specifies the BLUE spacecraft.
;
;      GOLD:      Specifies the GOLD spacecraft.
;
;     INDEX:      Returns the data structure corresponding to the specified index stored in common blocks.
;
;     TIMES:      Returns an array of times for all available data.
;
;   DYNAMIC:      If set, returns the data structure as a dynamic array.
;
;CREATED BY:      Takuya Hara on 2026-06-08.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-06-10 15:08:38 -0700 (Wed, 10 Jun 2026) $
; $LastChangedRevision: 34567 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_get_sw.pro $
;
;-
FUNCTION esc_iesa_get_sw, itime, blue=blue, gold=gold, index=ind, times=times, dynamic=dynamic;, array=array
  IF KEYWORD_SET(blue) THEN p = 'b'
  IF KEYWORD_SET(gold) THEN p = 'g'

  IF undefined(p) THEN BEGIN
     dprint, dlevel=2, 'User must specify which spacecraft data should be returned.'
     RETURN, -1
  ENDIF 

  IF KEYWORD_SET(dynamic) THEN dflg = 1 ELSE dflg = 0
  ;IF KEYWORD_SET(array) THEN aflg = 1 ELSE aflg = 0

  cvar = 'escp_iesa_sw'
  dat  = SCOPE_VARFETCH(cvar.replace('p', p), common='esc_iesa_sw_com')
  par  = SCOPE_VARFETCH(cvar.replace('p', p) + '_par', common='esc_iesa_sw_com')

  tc = 0.5d0 * (dat.time + dat.end_time)
  IF KEYWORD_SET(times) THEN RETURN, tc

  IF undefined(ind) THEN BEGIN
     IF undefined(itime) THEN ctime, itime, npoints=1
     time = itime
     IF is_string(time) THEN time = time_double(time)

     IF N_ELEMENTS(time) GT 1 THEN w = WHERE(tc GE MIN(time) AND tc LE MAX(time), nw) $
     ELSE BEGIN
        w = nn2(tc, time)
        nw = 1
     ENDELSE
  ENDIF ELSE BEGIN
     w = ind
     nw = 1
     IF w GE N_ELEMENTS(tc) THEN BEGIN
        dprint, dlevel=2, verbose=verbose, 'Input index is out of range for the loaded data.'
        nw = 0
     ENDIF 
  ENDELSE 
  IF nw EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No data found in the specified time range.'
     RETURN, -1
  ENDIF

  data = REPLICATE(esc_iesa_struct('sw', blue=bflg, gold=gflg), nw)
  
  data.time          = dat.time[w]
  data.end_time      = dat.end_time[w]
  data.delta_t       = 0.d0
  data.integ_t       = 0.d0
  data.quality_flag  = dat.quality_flag[w]
  data.att_state     = dat.att_state[w]
  data.spoiler_state = dat.spoiler_state[w]
  data.padding       = dat.padding[w]
  data.sweep_table   = dat.sweep_table[w]
  data.lut_id        = dat.lut_id[w]
  data.dp_cadence    = dat.dp_cadence[w]
  data.att_ind       = dat.att_ind[w]
  data.valid         = dat.valid[w]
  data.sc_pot        = dat.sc_pot[w]
  data.magf          = TRANSPOSE(dat.magf[w, *])
  data.bkg           = TRANSPOSE(dat.bkg[w, *, *, *], [1, 2, 3, 0])
  data.dead          = TRANSPOSE(dat.dead[w, *, *, *], [1, 2, 3, 0])
  data.data          = TRANSPOSE(dat.data[w, *, *, *], [1, 2, 3, 0])
  data.cnts          = data.data

  n_i  = 14L                     ; 2 spoiler states x 7 energy sweep tables
  n_ad = 128L                    ; 16 anodes x 8 deflectors
  n_e = data[0].nenergy
  n_m = data[0].nmass
  n_b = data[0].nbins
  n_a = data[0].nanode
  n_d = data[0].ndef
  
  emode = 7L * data.spoiler_state + data.sweep_table
  amode = par.lut_phi_ind
  aidx = INTARR(n_b, 8)
  FOR ia=0, 7 DO aidx[*, ia] = REFORM(TRANSPOSE(amode[*, ia] ## REPLICATE(1L, n_d) + 16L * REPLICATE(1L, n_a) ## INDGEN(n_d)), n_b)

  IF nw GT 1 THEN BEGIN
     aidx = REBIN(TRANSPOSE(aidx[*, data.lut_id]), nw, n_b, /sample)
     eidx = REBIN(emode, nw, n_b, /sample)
     idx = eidx + n_i * aidx

     data.energy  = TRANSPOSE(REFORM((REFORM(TRANSPOSE(par.energy, [0, 2, 1, 3]), n_i*n_ad, n_e, n_m))[idx, *, *], nw, n_b, n_e, n_m), [2, 1, 3, 0])
     data.denergy = TRANSPOSE(REFORM((REFORM(TRANSPOSE(par.denergy, [0, 2, 1, 3]), n_i*n_ad, n_e, n_m))[idx, *, *], nw, n_b, n_e, n_m), [2, 1, 3, 0])
     data.theta   = TRANSPOSE(REFORM((REFORM(TRANSPOSE(par.theta, [0, 2, 1, 3]), n_i*n_ad, n_e, n_m))[idx, *, *], nw, n_b, n_e, n_m), [2, 1, 3, 0])
     data.dtheta  = TRANSPOSE(REFORM((REFORM(TRANSPOSE(par.dtheta, [0, 2, 1, 3]), n_i*n_ad, n_e, n_m))[idx, *, *], nw, n_b, n_e, n_m), [2, 1, 3, 0])
     data.phi     = TRANSPOSE(REFORM((REFORM(TRANSPOSE(par.phi, [0, 2, 1, 3]), n_i*n_ad, n_e, n_m))[idx, *, *], nw, n_b, n_e, n_m), [2, 1, 3, 0])
     data.dphi    = TRANSPOSE(REFORM((REFORM(TRANSPOSE(par.dphi, [0, 2, 1, 3]), n_i*n_ad, n_e, n_m))[idx, *, *], nw, n_b, n_e, n_m), [2, 1, 3, 0])
     data.domega  = TRANSPOSE(REFORM((REFORM(TRANSPOSE(par.domega, [0, 2, 1, 3]), n_i*n_ad, n_e, n_m))[idx, *, *], nw, n_b, n_e, n_m), [2, 1, 3, 0])
     data.gf      = TRANSPOSE(REFORM((REFORM(TRANSPOSE(par.gf, [0, 2, 1, 3]), n_i*n_ad, n_e, n_m))[idx, *, *], nw, n_b, n_e, n_m), [2, 1, 3, 0])
  
     data.eff     = REBIN(par.eff,  n_b, n_e, n_m, nw, /sample)
     data.bins    = REBIN(par.bins, n_b, n_e, n_m, nw, /sample)
     data.mass_arr = REBIN(par.mass_arr, n_b, n_e, n_m, nw, /sample) 
  ENDIF ELSE BEGIN
     aidx = REFORM(aidx[*, data.lut_id])
     eidx = emode

     data.energy  = REFORM(par.energy[eidx, *, aidx, *])
     data.denergy = REFORM(par.denergy[eidx, *, aidx, *])
     data.theta   = REFORM(par.theta[eidx, *, aidx, *])
     data.dtheta  = REFORM(par.dtheta[eidx, *, aidx, *])
     data.phi     = REFORM(par.phi[eidx, *, aidx, *])
     data.dphi    = REFORM(par.dphi[eidx, *, aidx, *])
     data.domega  = REFORM(par.domega[eidx, *, aidx, *])
     data.gf      = REFORM(par.gf[eidx, *, aidx, *])

     data.eff     = par.eff
     data.bins    = par.bins
     data.mass_arr = par.mass_arr
  ENDELSE
  data.geom_factor = par.geom_factor[emode]

  IF (dflg) THEN BEGIN
     darray = dynamicarray(name=cvar.replace('p', p))
     darray.append, TEMPORARY(data)
     data = TEMPORARY(darray)
  ENDIF 

  RETURN, data
END 
