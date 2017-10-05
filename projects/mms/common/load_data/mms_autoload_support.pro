;+
;NAME:
; mms_autoload_support
;PURPOSE:
; given a MMS tplot variable name, check to see if attitude and/or ephemeris are available, if they do not, load
; the state data for the appropriate time period
;CALLING SEQUENCE:
; mms_autoload_support, vname=vname, attdata=attdata, ephdata=ephdata, probe_in=probe,
;     trange=[tmin, tmax], history_out=hist_string
;INPUT:
;OUTPUT:
;KEYWORDS:
; vname = a tplot variable name
; trange: Specify a time range for which support data should be loaded
;        (required if vname is not supplied)
; attdata: If set to 1, ensure attitude data is loaded and covers the
;           requested time interval
; ephdata: If set to 1, ensure ephemeris data is loaded and covers the
;           requested time interval
; probe_in: Specifies the probe name to load support data for
; history_out = a history string, if data needs loading
;HISTORY:
; 2013-12-19: Adapted from thm_autoload_support by clr
;
; NOTES:
;  Either 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-01 13:09:14 -0800 (Wed, 01 Mar 2017) $
;$LastChangedRevision: 22883 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_autoload_support.pro $
;
;-
Pro mms_autoload_support, vname=vname, attdata=attdata, ephdata=ephdata, history_out=history_out, probe_in=probe_in, trange=trange, progobj=progobj, _extra=_extra

  ; Check to see if input variable name is specified
  if ~keyword_set (vname) then begin
    if ~keyword_set(trange) then message, 'The trange keyword must be used if no input variable name is supplied.'
    if ~keyword_set(probe_in) then message, 'The probe_in keyword must be used if no input variable name is supplied.'
  endif

  ; Set trange and probe (from input tplot variable, if necessary)
  If ~keyword_set(trange) then begin
    get_data,vname,trange=trange
    if n_elements(trange) NE 2 then message,'Tplot variable name ' + vname + ' not found.'
    if ~keyword_set(probe_in) then probe_in = strmid(vname, 3, 1) else probe_in = probe_in
  endif

  ; Maximum allowable extrapolation time (seconds) outside range of support data
  ;slop=120.0D
  slop=0.0D
  loadeph=0b
  loadatt=0b
  history_out = ''
  
  ; Does any data cover the time range?
  ; Check ephemeris and attitude data separately (don't load attitude
  ; if you don't have to - files are very large)
  if keyword_set(ephdata) then begin
     var1 = 'mms'+probe_in+'_defeph_pos'
     var2 = 'mms'+probe_in+'_defeph_vel'
     get_data,var1,trange=tr1
     get_data,var2,trange=tr2
     if ((n_elements(tr1) NE 2) OR (n_elements(tr2) NE 2)) then begin
        loadeph = 1b
     endif else begin
        tr1 += [-slop,slop]
        tr2 += [-slop,slop]
        if ((trange[0] LT tr1[0]) OR (trange[1] GT tr1[1])) then loadeph=1b
        if ((trange[0] LT tr2[0]) OR (trange[1] GT tr2[1])) then loadeph=1b
     endelse  
  endif

  if keyword_set(attdata) then begin
     var3 = 'mms'+probe_in+'_defatt_spinras'
     var4 = 'mms'+probe_in+'_defatt_spindec'
     get_data,var3,trange=tr3
     get_data,var4,trange=tr4
     if ((n_elements(tr3) NE 2) OR (n_elements(tr4) NE 2)) then begin
       loadatt = 1b
     endif else begin
        tr3 += [-slop,slop]
        tr4 += [-slop,slop]
        if ((trange[0] LT tr3[0]) OR (trange[1] GT tr3[1])) then loadatt=1b
        if ((trange[0] LT tr4[0]) OR (trange[1] GT tr4[1])) then loadatt=1b
     endelse
  endif
  
  If (loadeph) Then Begin
    If (obj_valid(progobj)) Then progobj -> update, 0.0,  $
      text = 'Loading ephemeris data for MMS'+probe
    mms_load_state, probe = probe_in, trange = trange, /ephemeris_only
    tj = time_string(trange)        ;for history
    history_out = 'mms_load_state, probe = '+''''+probe_in+''''+$
      ', trange = ['+''''+tj[0]+''''+', '+''''+tj[1]+''''+$
      '], /ephemeris_only'
    If(obj_valid(progobj)) Then progobj -> update, 100.0,  $
      text = 'Finished Loading ephemeris data for MMS'+probe_in
  endif

  If (loadatt) Then Begin
    If (obj_valid(progobj)) Then progobj -> update, 0.0,  $
      text = 'Loading attitude data for MMS'+probe
    mms_load_state, probe = probe_in, trange = trange, /attitude_only
    tj = time_string(trange)        ;for history
    history_out = 'mms_load_state, probe = '+''''+probe_in+''''+$
      ', trange = ['+''''+tj[0]+''''+', '+''''+tj[1]+''''+$
      '], /attitude_only'
    If(obj_valid(progobj)) Then progobj -> update, 100.0,  $
      text = 'Finished Loading ephemeris data for MMS'+probe_in
  endif

  Return

End
