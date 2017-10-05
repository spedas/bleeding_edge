;+
; NAME:
;   fpi_quick
;
; PURPOSE:
;   This is an emergency script to be used when EVA is not working but
;   a FPI member still needs to submit a selection within a limited time.
;   There won't be any display (because it won't generate any tplot-variable).
;
; INPUT: 
;    START: (string) start time of the desired segment.
;    STOP: (string) stop time of the desired segment.
;    FOM: (long) the desired FOM value of the segment
;
;-
PRO fpi_quick, start, stop, fom
  compile_opt idl2
  common mms_sitl_connection, netUrl, connection_time, login_source

  ;-----------
  ; INITIALIZE
  ;-----------
  mms_init
  if (size(start,/type) ne 7) or (size(stop,/type) ne 7) then begin
    msg = 'time should be a string, e.g. "2015-05-15/16:32:23"'
    print, msg
    return
  endif
  ts = mms_unix2tai(str2time(start))
  te = mms_unix2tai(str2time(stop))
  
  ;-----------
  ; LOGIN
  ;-----------
  r = get_mms_sitl_connection()
  type = size(netUrl, /type) ;will be 11 if object has been created
  if (type eq 11) then begin
    netUrl->GetProperty, URL_USERNAME = username
  endif else begin
    message,'Something is wrong'
  endelse
  print, username+' logged in'
  
  ;-----------
  ; SUBMIT
  ;-----------
  mms_submit_fpi_calibration_segment, ts, te, fom, username+'(quick)', $
    error_flags, error_msg, $
    yellow_warning_flags, yellow_warning_msg, $
    orange_warning_flags, orange_warning_msg, $
    problem_status, warning_override=warning_override
  idx = where(error_flags eq 1, ct)
  imax = n_elements(error_flags)
  if ct gt 0 then begin
    print,'!!!!!!!!'
    for i=0,imax-1 do begin; for each error type
      if error_flags[i] eq 1 then print, error_msg[i]
    endfor
    print,'!!!!!!!!!'
  endif
  if orange_warning_flags then print, orange_warning_msg
  if yellow_warning_flags then print, yellow_warning_msg
END
