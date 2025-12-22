;+
;NAME:
;fa_fields_sfa2tplot, tvar_names
;PURPOSE:
;Loads FAST SFA fields data from SDT and creates tplot variables for
;output
;CALLING SEQUENCE:
;fa_fields_sfa2tplot
;INPUT:
;trange = time range, not sure why this is needed, but get_fa_fields
;         is not working for SFA variables without time input.
;OUTPUT:
;tvar_names = a list of tplot variables to output
;HISTORY:
;11-Nov-2025, jmm, jimm@ssl.berkeley.edu
;+
Pro fa_fields_sfa2tplot, trange, tvar_names

  timespan, trange
  var0 = fa_sfa_process_varnames()
  nvar0 = n_elements(var0[0, *])
  ok = bytarr(nvar0)
  tvar_names = 'None'
  For j = 0, nvar0-1 Do Begin
     pj = get_fa_fields(var0[0, j])
     If(is_struct(pj) && pj.valid Eq 1) Then Begin
        ok[j] = 1
        tvj = var0[1, j]
        dqd_name = var0[0, j]
        short_name = strmid(dqd_name,7,5)
;hacked from ff_fields_sfa.pro
        data   = {x:pj.time, y:alog10(pj.comp1), v:pj.yaxis}
        store_data,tvj, data=data
; ESTABLISH ZLIM AND TITLES
        zlim = [-15, -6]
        ytit = 'HF E!C!C(kHz)'
        ztit = 'Log (V/m)!U2!N/Hz'
        IF (short_name EQ 'V1-V2') OR (short_name EQ 'V3-V4') OR $
           (short_name EQ 'V5-V6') OR (short_name EQ 'V7-V8') then BEGIN
           zlim = [-10,0]
           ytit = 'HF E 5m!C!C(kHz)'
        ENDIF
        IF (short_name EQ 'V9-V1') then BEGIN
           zlim = [-10,0]
           ytit = 'HF E Ax!C!C(kHz)'
        ENDIF
        if (short_name EQ 'V1-V4') OR (short_name EQ 'V5-V8') then $
           zlim = [-11,-1]
        if (short_name EQ 'V1-V4') then ytit = 'HF E 29m!C!C(kHz)'
        if (short_name EQ 'V5-V8') then ytit = 'HF E 55m!C!C(kHz)'
        IF (short_name EQ 'Mag3A') then BEGIN
           zlim = [-12,-6]
           ztit = 'Log nT!U2!N/Hz'
           ytit = 'HF B 21"!C!C(kHz)'
        ENDIF
        options,tvj,'spec',1
;        options,tvj,'panel_size',6
        options,tvj,'ytitle',ytit
;        options,tvj,'zstyle',1
        options,tvj,'zrange',zlim
        options,tvj,'ztitle',ztit
        options,tvj,'y_no_interp',1
        options,tvj,'x_no_interp',1
;        ff_ylim,tvj,[0.064,16.384],/log
        If(tvar_names[0] Eq 'None') Then Begin
           tvar_names = tvj
        Endif Else tvar_names = [tvar_names, tvj]
     Endif
  Endfor
;Try 'OMNI' variable(s)
  get_data, 'fa_sfa_ave_e14', data = e14
  get_data, 'fa_sfa_ave_e58', data = e58
  If(is_struct(e14) && is_struct(e58)) Then Begin
     fa_fields_sfa
     get_data, 'SFA_OMNI', data = om
     If(is_struct(om)) Then Begin
        copy_data, 'SFA_OMNI', 'fa_sfa_ave_eomni'
        tvar_names = [tvar_names, 'fa_sfa_ave_eomni']
     Endif
  Endif
  get_data, 'fa_sfa_burst_e14', data = e14
  get_data, 'fa_sfa_burst_e58', data = e58
  If(is_struct(e14) && is_struct(e58)) Then Begin
     fa_fields_sfa, /burst
     get_data, 'SFAB_OMNI', data = om
     If(is_struct(om)) Then Begin
        copy_data, 'SFAB_OMNI', 'fa_sfa_burst_eomni'
        tvar_names = [tvar_names, 'fa_sfa_burst_eomni']
     Endif
  Endif
  Return
End
