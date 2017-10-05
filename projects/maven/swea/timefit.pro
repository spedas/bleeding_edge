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
;       time:      Time array in any format accepted by time_double().
;
;                  If all the times are identical and if keyword PAD
;                  is not set, then a one hour interval centered on
;                  that time is set.
;
;KEYWORDS:
;
;       VAR:       TPLOT variable name or index from which to get time array.
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
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/timefit.pro $
;
;CREATED BY:	David L. Mitchell  07-06-14
;-
pro timefit, time, var=var, pad=pad, min=min, hour=hour, day=day

  if (size(var,/type) ne 0) then begin
    get_data,var,data=dat
    if (size(dat,/type) ne 8) then begin
      print,"Tplot variable ",var," not found."
      print,"Can't get time."
      return
    endif
    
    time = dat.x
  endif
  
  if (size(time,/type) eq 0) then return

  tmin = min(time_double(time), max=tmax)

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
