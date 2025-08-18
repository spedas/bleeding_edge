;+
;PROCEDURE:   timefit
;PURPOSE:
;  Given an input time array or tplot variable name, sets the tplot time window to span
;  the range of times in the array or tplot variable.
;
;USAGE:
;  timefit, time, var=var
;
;INPUTS:
;       time:      If this is a scalar string or integer, it's interpreted as
;                  a tplot variable name or number, from which the time is
;                  extracted.  If this is an array, it's interpreted as an
;                  array of times, in any format accepted by time_double().
;
;                  If all the times are identical and if keyword PAD
;                  is not set, then a one hour interval centered on
;                  that time is set.
;
;KEYWORDS:
;
;       VAR:       Tplot variable name/number.  OBSOLETE, but retained for 
;                  backward compatibility.  If VAR is set, then time input
;                  is ignored.
;
;       PAD:       Amount of time to pad on either end of the time
;                  span.  Default units are seconds.
;
;       MIN:       PAD units are minutes.
;
;       HOUR:      PAD units are hours.
;
;       DAY:       PAD units are days.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-12-15 12:58:34 -0800 (Tue, 15 Dec 2020) $
; $LastChangedRevision: 29488 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/timefit.pro $
;
;CREATED BY:	David L. Mitchell  07-06-14
;-
pro timefit, time, var=var, pad=pad, min=min, hour=hour, day=day

  if (size(var,/type) gt 0) then begin
    get_data, var, data=dat, index=i
    if (i eq 0) then begin
      print, "Tplot variable ",var," not found."
      return
    endif
    if (size(dat,/type) eq 7) then begin
      print, "Cannot process compound variable: ", var
      return
    endif
    str_element, dat, 'x', x, success=ok
    if (ok) then time = minmax(x) else begin
      print, "Cannot process variable: ", var
      return
    endelse
  endif

  case n_elements(time) of
     0   : begin
             print, "You must supply a time array or a tplot variable name/number."
             return
           end
     1   : begin
             get_data, time, data=dat, index=i
             if (i eq 0) then begin
               print, "Tplot variable ",time," not found."
               return
             endif
             if (size(dat,/type) eq 7) then begin
               print, "Cannot process compound variable: ", time
               return
             endif
             str_element, dat, 'x', x, success=ok
             if (ok) then time = minmax(x) else begin
               print, "Cannot process variable: ", time
               return
             endelse
           end
    else : ; do nothing
  endcase

  tmin = min(time, max=tmax)

  if keyword_set(pad) then begin
    pad = double(pad)

    if keyword_set(min) then begin
      pad = pad*60D
      hour = 0
      day = 0
    endif

    if keyword_set(hour) then begin
      pad = pad*3600D
      day = 0
    endif

    if keyword_set(day) then pad = pad*86400D

  endif else pad = 0D

  if ((tmin eq tmax) and (pad eq 0D)) then pad = 1800D

  timespan, [(tmin-pad), (tmax+pad)], /sec

end
