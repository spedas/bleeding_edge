;+
; FUNCTION:
;         unix_to_tt2000_vect
;
; PURPOSE:
;         Converts unix times to TT2000 times, as a vectorized alternative to unix_to_tt2000.pro.
; Notes:
;         Code run time could be reduced if method introduced to bypass loop to populate 
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
;$LastChangedBy: dcarpenter $
;$LastChangedDate: 2025-08-14 17:03:01 -0700 (Thu, 14 Aug 2025) $
;$LastChangedRevision: 33546 $
;$URL (NEEDS COMMIT): svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/tags/spedas_6_1/general/misc/time/TT2000/unix_to_tt2000_vect.pro $
;-
function spd_tt2000_leap_seconds_vect, dates
  cdf_leap_second_init
  
  dates_double = time_double(dates, tt2000=tt2000)
  
  if size(dates[0], /type) eq 14 then tt2000 = 1b
  info = CDF_LEAPSECONDS_INFO()
  
  leap_dates= time_double(strtrim(info.LEAPSECONDS[0, *],2)+'-'+strtrim(info.LEAPSECONDS[1, *],2)+'-'+strtrim(info.LEAPSECONDS[2, *],2)+'/00:00:00')
  
  ; Assert dates are ascending:
  if ~array_equal(dates[sort(dates)],dates) then begin
    ;throw issue that dates aren't in ascending order
    dprint, dlevel=1, 'Warning: the input values to unix_to_tt2000 should be in ascending order'
  endif
  ; Assert leap_dates are monotonically increasing
  if ~array_equal(leap_dates[sort(leap_dates)],leap_dates) then begin
    ;throw issue that leap dates aren't in ascending order
    dprint, dlevel=1, 'Warning: leap seconds dates should be in ascending order'
  endif
  
  ; generate an array containing the index of leap dates which occur after january 1 2000
  leap_dates_post_2000 = where(leap_dates ge time_double('2000-01-01/12:00:00'))
  
  ; pre-allocate leap_seconds array
  leap_seconds = lon64arr(n_elements(dates))
  
  ;Check if difference in leap seconds for first and last date. 
  sec_first = size(where(leap_dates[leap_dates_post_2000] lt dates_double[0]),/n_elements)
  sec_last = size(where(leap_dates[leap_dates_post_2000] lt dates_double[-1]),/n_elements)
  ; If same, assign number of leap seconds to the entire array
  if (sec_last-sec_first) eq 0 then begin
    ;dprint, dlevel=1, 'Leap seconds determined to be constant throughout selected period.'
    leap_seconds = leap_seconds + sec_first
  endif 
  ; If last date has more leap seconds than first date, loop through leap dates and assign accordingly
  if (sec_last-sec_first) gt 0 then begin
    ;dprint, dlevel=1, 'Leap seconds determined to be variable throughout selected period.'
    for ld_idx = 0, n_elements(leap_dates_post_2000)-1 do begin
      ;select indices of dates_double where preceded by given leapdate
      ls_idx = where(leap_dates[leap_dates_post_2000[ld_idx]] le dates_double,count)
      ;increment leap_seconds up by one at given indices, only if the number of elements meeting the condition isn't 0
      IF count NE 0 THEN leap_seconds[ls_idx]=leap_seconds[ls_idx]+1
    endfor
  endif
  ; If last date somehow has less leap seconds than first date, throw error (shouldn't be possible)
  if (sec_last-sec_first) lt 0 then begin
    dprint, dlevel=1, 'Warning: first date found more leap seconds than last date'
  endif
  
  return, leap_seconds
end

function unix_to_tt2000_vect, unix_times
  
  defsysv,'!CDF_LEAP_SECONDS',exists=exists

  if ~keyword_set(exists) then begin
    cdf_leap_second_init
  endif

  ; need to check that the input times are doubles (floats might lead to unexpected precision problems)
  if size(unix_times[0], /type) ne 5 then begin
    dprint, dlevel=1, 'Warning: the input values to unix_to_tt2000 should be double-precision'
  endif
  
  leap_seconds = spd_tt2000_leap_seconds_vect(unix_times)
    
  if !version.release ge 8.4 then begin
    tt_conversion = biginteger(9467279358160018921ull)
    
    tt2000_times = lon64arr(n_elements(unix_times))
    for k=0, n_elements(unix_times)-1 do begin
      unix_times_big = biginteger((unix_times[k]+leap_seconds[k])*1d10)
      tt2000_times[k] = ((unix_times_big - tt_conversion)/biginteger(10)).ToInteger()
    endfor
    
    return, tt2000_times
  endif else begin
    tt_conversion = 946727935.8160018921d

    tt2000_times = (unix_times - tt_conversion + leap_seconds)*1d9

    return, long64(tt2000_times)
  endelse
end