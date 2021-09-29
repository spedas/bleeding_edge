;+
; FUNCTION:
;         unix_to_tt2000
;
; PURPOSE:
;         Converts unix times to TT2000 times. 
;
; INPUT:
;         unix_times: unix time values 
;
; EXAMPLE:
;         IDL> tt2000_time = unix_to_tt2000(1.4501376e+09)
;         IDL> tt2000_time
;               503409664183998107
;            
;          convert back:
;         IDL> print, tt2000_2_unix(503409664183998107ll)
;               1.4501376e+09
;        
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-08-10 09:13:29 -0700 (Mon, 10 Aug 2020) $
;$LastChangedRevision: 29011 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/TT2000/unix_to_tt2000.pro $
;-
function spd_tt2000_leap_seconds, dates
  cdf_leap_second_init

  if size(dates[0], /type) eq 14 then tt2000 = 1b
  info = CDF_LEAPSECONDS_INFO()

  leap_dates= time_double(strtrim(info.LEAPSECONDS[0, *],2)+'-'+strtrim(info.LEAPSECONDS[1, *],2)+'-'+strtrim(info.LEAPSECONDS[2, *],2)+'/00:00:00')

  ls_idx = where(leap_dates ge time_double('2000-01-01/12:00:00'))
  for date_idx = 0, n_elements(dates)-1 do begin
    dt_dx = where(leap_dates le time_double(dates[date_idx], tt2000=tt2000))
    append_array, leap_seconds, n_elements(ssl_set_intersection(ls_idx, dt_dx))
  endfor
  return, leap_seconds
end
function unix_to_tt2000, unix_times

  defsysv,'!CDF_LEAP_SECONDS',exists=exists

  if ~keyword_set(exists) then begin
    cdf_leap_second_init
  endif
  
  ; need to check that the input times are doubles (floats might lead to unexpected precision problems)
  if size(unix_times[0], /type) ne 5 then begin
    dprint, dlevel=1, 'Warning: the input values to unix_to_tt2000 should be double-precision'
  endif
  
  if !version.release ge 8.4 then begin
    tt_conversion = biginteger(9467279358160018921ull)
    unix_times_big = biginteger((unix_times+spd_tt2000_leap_seconds(unix_times))*1d10)
    tt2000_times = (unix_times_big - tt_conversion)/biginteger(10)
    tt2000_times = tt2000_times.ToInteger()
    return, tt2000_times
  endif else begin
    tt_conversion = 946727935.8160018921d

    tt2000_times = (unix_times - tt_conversion + spd_tt2000_leap_seconds(tt2000_times))*1d9
    
    return, long64(tt2000_times)
  endelse
end