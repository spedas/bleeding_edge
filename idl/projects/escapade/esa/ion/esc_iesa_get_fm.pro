;+
;
;FUNCTION:        ESC_IESA_GET_FM
;
;PURPOSE:         Returns EESA-i Fine Masses (FM) data stored in common blocks.
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_get_fm.pro $
;
;-
FUNCTION esc_iesa_get_fm, itime, blue=blue, gold=gold, index=ind, times=times, dynamic=dynamic;, array=array
  IF KEYWORD_SET(blue) THEN p = 'b'
  IF KEYWORD_SET(gold) THEN p = 'g'

  IF undefined(p) THEN BEGIN
     dprint, dlevel=2, 'User must specify which spacecraft data should be returned.'
     RETURN, -1
  ENDIF 

  IF KEYWORD_SET(dynamic) THEN dflg = 1 ELSE dflg = 0
  ;IF KEYWORD_SET(array) THEN aflg = 1 ELSE aflg = 0

  cvar = 'escp_iesa_fm'
  dat  = SCOPE_VARFETCH(cvar.replace('p', p), common='esc_iesa_fm_com')
  par  = SCOPE_VARFETCH(cvar.replace('p', p) + '_par', common='esc_iesa_fm_com')

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
  
  data = REPLICATE(esc_iesa_struct('fm', blue=bflg, gold=gflg, nenergy=par.nenergy), nw)
  
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
  ;data.valid         = dat.valid[w]
  data.sc_pot        = dat.sc_pot[w]
  
  data.magf          = TRANSPOSE(dat.magf[w, *])
  data.bkg           = TRANSPOSE(dat.bkg[w, *, *, *], [1, 2, 0])
  ;data.dead          = TRANSPOSE(dat.dead[w, *, *, *], [1, 2, 0])
  data.data          = TRANSPOSE(dat.data[w, *, *, *], [1, 2, 0])
  data.cnts          = data.data

  n_e = data[0].nenergy
  n_m = data[0].nmass
  n_b = data[0].nbins
  n_a = data[0].nanode
  n_d = data[0].ndef
  
  eidx = 7L * data.spoiler_state + data.sweep_table
  IF nw GT 1 THEN BEGIN
     data.energy   = TRANSPOSE(par.energy[eidx, *, *, *], [1, 2, 0])
     data.denergy  = TRANSPOSE(par.denergy[eidx, *, *, *], [1, 2, 0])
     data.theta    = TRANSPOSE(par.theta[eidx, *, *, *], [1, 2, 0])
     data.dtheta   = TRANSPOSE(par.dtheta[eidx, *, *, *], [1, 2, 0])
     data.phi      = TRANSPOSE(par.phi[eidx, *, *, *], [1, 2, 0])
     data.dphi     = TRANSPOSE(par.dphi[eidx, *, *, *], [1, 2, 0])
     data.domega   = TRANSPOSE(par.domega[eidx, *, *, *], [1, 2, 0])
     data.gf       = TRANSPOSE(par.gf[eidx, *, *, *], [1, 2, 0])

     data.energy_min = TRANSPOSE(par.energy_min[eidx, *, *, *], [1, 2, 0])
     data.energy_max = TRANSPOSE(par.energy_max[eidx, *, *, *], [1, 2, 0])
     
     data.eff     = REBIN(par.eff,  n_e, n_m, nw, /sample)
     data.bins    = REBIN(par.bins, n_e, n_m, nw, /sample)
     data.mass_arr = REBIN(par.mass_arr, n_e, n_m, nw, /sample)

     data.valid   = REPLICATE(par.valid, nw)
     data.dead    = REBIN(par.dead, n_e, n_m, nw, /sample)
  ENDIF ELSE BEGIN
     data.energy  = REFORM(par.energy[eidx, *, *])
     data.denergy = REFORM(par.denergy[eidx, *, *])
     data.theta   = REFORM(par.theta[eidx, *, *])
     data.dtheta  = REFORM(par.dtheta[eidx, *, *])
     data.phi     = REFORM(par.phi[eidx, *, *])
     data.dphi    = REFORM(par.dphi[eidx, *, *])
     data.domega  = REFORM(par.domega[eidx, *, *])
     data.gf      = REFORM(par.gf[eidx, *, *])

     data.energy_min = REFORM(par.energy_min[eidx, *, *])
     data.energy_max = REFORM(par.energy_max[eidx, *, *])
     
     data.eff     = par.eff
     data.bins    = par.bins
     data.mass_arr = par.mass_arr
     
     data.valid   = par.valid
     data.dead    = par.dead
  ENDELSE
  data.geom_factor = par.geom_factor[eidx]

  IF (dflg) THEN BEGIN
     darray = dynamicarray(name=cvar.replace('p', p))
     darray.append, TEMPORARY(data)
     data = TEMPORARY(darray)
  ENDIF 

  RETURN, data
END 
