;+
;NAME:
; mvn_sta_l2scpot
;PURPOSE:
; Wrapper for mvn_sta_scpot_load that insures that c0 and c6 data have
; the same number of times
;CALLING SEQUENCE:
; mvn_sta_l2scpot
;INPUT:
; the c6 and c0 data structures are assumed to have been loaded
;OUTPUT:
; none, the sc_pot tag is filled for all ap_ids using
; mvn_sta_scpot_load
;KEYWORDS:
; l0l2 = if set, then the input comes from L0 data.
;HISTORY:
; 2017-04-10, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-04-10 12:52:08 -0700 (Mon, 10 Apr 2017) $
; $LastChangedRevision: 23128 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_l2scpot.pro $
;-
Pro mvn_sta_l2scpot, l0l2=l0l2, _extra=_extra

  common mvn_c0, mvn_c0_ind, mvn_c0_dat
  common mvn_c6, mvn_c6_ind, mvn_c6_dat

  If(~is_struct(mvn_c0_dat) || ~is_struct(mvn_c6_dat)) Then Return

  c0_time = mvn_c0_dat.time & nc0 = n_elements(c0_time)
  c6_time = mvn_c6_dat.time & nc6 = n_elements(c6_time)
  date = time_string(median(c0_time), precision=-3, format=6)
  t0 = time_double(date)+[0.0d0, 24.0d0*3600.0d0]
  If(keyword_set(l0l2)) Then Begin
     If(nc0 Gt nc6) Then Begin
        c0_tmp = mvn_c0_dat
        mvn_c0_dat = mvn_sta_cmn_tclip(temporary(mvn_c0_dat), t0)
        mvn_sta_scpot_load, /tplot ;ok for all except c0 data, now to fix
        mvn_c0_dat = c0_tmp
        pot_all = mvn_c6_dat.sc_pot
        time = c6_time
        get_data, 'mvn_sta_scpot_valid', data = dscpotv
        pot_valid = dscpotv.y
        pot_c0 = interp(pot_all,time,(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.) 
        mvn_c0_dat.sc_pot = pot_c0
        pot_valid_c0 = fix(round(interp(pot_valid,time,(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.)))
        mvn_c0_dat.quality_flag = (mvn_c0_dat.quality_flag and 30719) or 2^11*(1-pot_valid_c0)
     Endif Else Begin
        mvn_sta_scpot_load
     Endelse
  Endif Else Begin ;in the l2-l2 processing, we should be able to insure that c0 and c6 have the same time arrays, add 5 minutes to each end
     t005 = t0+[-300.0d0, 300.0d0]
     mvn_sta_l2_load, sta_apid= ['c0', 'c6'], trange = t005
     nc05 = n_elements(mvn_c0_dat.time)
     nc65 = n_elements(mvn_c6_dat.time)
     If(nc05 Gt nc65) Then Begin
        c0_tmp = mvn_c0_dat
        t065 = minmax(mvn_c6_dat.time)
        mvn_c0_dat = mvn_sta_cmn_tclip(temporary(mvn_c0_dat), t065)
        mvn_sta_scpot_load, /tplot ;ok for all except c0 data, now to fix
        mvn_c0_dat = c0_tmp
        pot_all = mvn_c6_dat.sc_pot
        time = c6_time
        get_data, 'mvn_sta_scpot_valid', data = dscpotv
        pot_valid = dscpotv.y
        pot_c0 = interp(pot_all,time,(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.) 
        mvn_c0_dat.sc_pot = pot_c0
        pot_valid_c0 = fix(round(interp(pot_valid,time,(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.)))
        mvn_c0_dat.quality_flag = (mvn_c0_dat.quality_flag and 30719) or 2^11*(1-pot_valid_c0)
     Endif Else Begin
        mvn_sta_scpot_load      ;ok for all except c0, c6, clip those
     Endelse
;for exact clipping, extend end time by 1 second
     c0_tr = minmax(c0_time)+[0.0, 1.0]
     c6_tr = minmax(c6_time)+[0.0, 1.0]
     mvn_c0_dat = mvn_sta_cmn_tclip(temporary(mvn_c0_dat), c0_tr)
     mvn_c6_dat = mvn_sta_cmn_tclip(temporary(mvn_c6_dat), c6_tr)
  Endelse
End
