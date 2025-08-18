;+
;NAME:
; thm_ui_check4spin
;PURPOSE:
; given a THEMIS tplot variable name, check to see if spin period and
; phase exist, for coordinate transformations, If they do not, load
; the state data for the appropriate time period
;CALLING SEQUENCE:
; thm_ui_check4spin, vname, vname_spin1, vname_spin2, history_out
;INPUT:
; vname = tplot variable name
;OUTPUT:
; vname_spin1 = the tplot variable containing the spin period. or
;                 spinras
; vname_spin2 = the tplot variable containing the spin phase or 
;                   spindec
; history_out = a history string, if data needs loading
;KEYWORDS:
; rasdec = if set, return the variables for spinras, and spindec used
;          for dsl <-> gse tranformations
;HISTORY:
; 26-feb-2007, jmm, jimm@ssl.berkeley.edu
; 
; NOTES:
;   The rest of the original GUI has been deprecated, but this routine is useful for a lot of the other THEMIS code.
;     For now, it will live in common
; 
;$LastChangedBy: jwl $
;$LastChangedDate: 2014-01-24 16:22:37 -0800 (Fri, 24 Jan 2014) $
;$LastChangedRevision: 14015 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_check4spin.pro $
;
;-
Pro thm_ui_check4spin, vname, vname_spin1, vname_spin2, history_out, $
                       rasdec = rasdec, probe_in = probe_in, $
                       trange = trange, progobj = progobj, _extra = _extra

  @tplot_com
  If(keyword_set(probe_in)) Then probe = probe_in $
  Else probe = strmid(vname, 2, 1)
;set getspin to zero if there is data for this probe and time_range
  getspin = 1b
;Check for spin data
  all_names = tnames()
  If(keyword_set(rasdec)) Then Begin
    var1 = '_state_spinras'
    var2 = '_state_spindec'
  Endif Else Begin
    var1 = '_state_spinper'
    var2 = '_state_spinphase'
  Endelse
    
  ok1 = where(all_names Eq 'th'+probe+var1)
  ok2 = where(all_names Eq 'th'+probe+var2)
  If(keyword_set(trange)) Then tj = time_double(trange) Else Begin
    data_ssj = where(data_quants.name Eq vname)
    tj = data_quants[data_ssj].trange
  Endelse
  If(ok1[0] Ne -1) And (ok2[0] Ne -1) Then Begin
;check for time ranges
    tper = data_quants[ok1[0]+1].trange
    tphase = data_quants[ok2[0]+1].trange
    If(tj[0] Ge tper[0] And tj[1] Le tper[1] And $
       tj[0] Ge tphase[0] And tj[1] Le tphase[1]) Then getspin = 0b
  Endif

  If(getspin) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0,  $
      text = 'Loading State data for Calibration, Probe: '+probe
    thm_load_state, probe = probe, /get_support_data, trange = tj
    tj = time_string(tj)        ;for history
    history_out = 'thm_load_state, probe = '+''''+probe+''''+$
      ', trange = ['+''''+tj[0]+''''+', '+''''+tj[1]+''''+$
      '], /get_support_data'
    If(obj_valid(progobj)) Then progobj -> update, 0.0,  $
      text = 'FInished Loading State data for Calibration, Probe: '+probe
  Endif Else history_out = ''
  all_names = tnames()
  ok1 = where(all_names Eq 'th'+probe+var1)
  ok2 = where(all_names Eq 'th'+probe+var2)
  If(ok1[0] Eq -1) Then vname_spin1 = '' $
  Else vname_spin1 = 'th'+probe+var1
  If(ok2[0] Eq -1) Then vname_spin2 = '' $
  Else vname_spin2 = 'th'+probe+var2
  Return
End




