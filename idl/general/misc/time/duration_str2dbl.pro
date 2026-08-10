;-
;FUNCTION:
;  duration_sec =  duration_str2dbl(duration_string)
;PURPOSE:
;   Converts a descriptive string (e.g. '5 days'
; or '3 minutes') into a number of seconds.
;
; Intended for converting userfriendly
; strings into something that can be added/subtracted
; from Unix time objects.
;
; Example:
; > print, duration_str2dbl('3d')
; 259200.00
; > print, duration_str2dbl('1h')
; 3600.000
;
; WARNING: Will not work for a mixed user friendly
; case, e.g. '1 hour 4 min'
;+
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2026-08-05 18:04:57 -0700 (Wed, 05 Aug 2026) $
; $LastChangedRevision: 34706 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/duration_str2dbl.pro $
;-

function duration_str2dbl, duration_string

  ; Recursion for multiple strings:
  if n_elements(duration_string) ne 1 then begin
    durarr = dblarr(n_elements(duration_string)) 
    foreach durstrng_i, duration_string, i do begin
      durdble_i = duration_str2dbl(durstrng_i)
      durarr[i] = durdble_i
    endforeach
    return, durarr

  endif

  ; All lower case the string:
  ds = duration_string.tolower()

  ; First, check if seconds:
  has_seconds = ds.contains('s')
  if has_seconds then begin
    duration_s = (ds.split('s'))[0].trim()
    duration_s = double(duration_s)
  endif

  ; Next, check if minutes:
  has_min = ds.contains('m')
  if has_min then begin
    duration_min = (ds.split('m'))[0].trim()
    duration_s = 60d*double(duration_min)
  endif

  ; Next, hours:
  has_hr = ds.contains('h')
  if has_hr then begin
    duration_hr = (ds.split('h'))[0].trim()
    duration_s = 3600d*double(duration_hr)
  endif

  ; Next, hours:
  has_days = ds.contains('d')
  if has_days then begin
    duration_days = (ds.split('d'))[0].trim()
    duration_s = 3600d*24*double(duration_days)
  endif

  return, duration_s

end