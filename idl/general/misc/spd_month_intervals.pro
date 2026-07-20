;+
; NAME:
;   SPD_MONTH_INTERVALS
;
; PURPOSE:
;   Return calendar-month intervals sufficient to cover an input
;   Unix-time interval.
;
; CALLING SEQUENCE:
;   intervals = spd_month_intervals(start_time, end_time)
;
; INPUTS:
;   start_time:
;     Scalar Unix timestamp marking the beginning of the requested
;     interval.
;
;   end_time:
;     Scalar Unix timestamp marking the end of the requested interval.
;     Must be greater than or equal to START_TIME.
;
; RETURN VALUE:
;   A DOUBLE array with dimensions [2, N_MONTHS].
;
;   For interval I:
;
;     intervals[0, i] = beginning of the calendar month
;     intervals[1, i] = beginning of the following calendar month
;
;   The returned intervals therefore use half-open semantics:
;
;     [month_start, next_month_start)
;
;   If END_TIME falls exactly on a calendar-month boundary, the month
;   beginning at END_TIME is not included, unless START_TIME and
;   END_TIME are identical.
;
; EXAMPLE:
;   start_time = time_double('2024-01-15/12:00:00')
;   end_time   = time_double('2024-04-01/00:00:00')
;
;   intervals = spd_month_intervals(start_time, end_time)
;
;   for i = 0L, n_elements(intervals[0, *]) - 1L do begin
;     print, time_string(intervals[0, i]), '  ', $
;            time_string(intervals[1, i])
;   endfor
;
;   This produces intervals equivalent to:
;
;     2024-01-01 -> 2024-02-01
;     2024-02-01 -> 2024-03-01
;     2024-03-01 -> 2024-04-01
;-
function spd_month_intervals, start_time, end_time

  compile_opt idl2

  if n_elements(start_time) ne 1 then begin
    message, 'START_TIME must be a scalar Unix timestamp.'
  endif

  if n_elements(end_time) ne 1 then begin
    message, 'END_TIME must be a scalar Unix timestamp.'
  endif

  t_start = time_double(start_time)
  t_end   = time_double(end_time)

  if finite(t_start) eq 0 then begin
    message, 'START_TIME must be finite.'
  endif

  if finite(t_end) eq 0 then begin
    message, 'END_TIME must be finite.'
  endif

  if t_end lt t_start then begin
    message, 'END_TIME must be greater than or equal to START_TIME.'
  endif

  seconds_per_day = 86400.0d
  unix_epoch_jd = julday(1, 1, 1970, 0, 0, 0.0d)

  ; Determine the calendar month containing START_TIME.

  start_jd = unix_epoch_jd + t_start / seconds_per_day
  caldat, start_jd, start_month, start_day, start_year

  ; Determine the calendar month containing END_TIME.

  end_jd = unix_epoch_jd + t_end / seconds_per_day
  caldat, end_jd, end_month, end_day, end_year

  ; Represent a month as an integer index.  January of year Y has
  ; index Y*12; February has index Y*12+1, and so forth.

  first_month_index = long64(start_year) * 12LL + $
    long64(start_month - 1)

  end_month_index = long64(end_year) * 12LL + $
    long64(end_month - 1)

  ; Find the Unix timestamp corresponding to the beginning of the
  ; month containing END_TIME.

  end_month_start_jd = julday(end_month, 1, end_year, $
    0, 0, 0.0d)

  end_month_start = $
    (end_month_start_jd - unix_epoch_jd) * seconds_per_day

  ; If END_TIME is exactly a month boundary, that boundary can serve
  ; as the exclusive end of the final returned interval.  Otherwise,
  ; include the complete month containing END_TIME.
  ;
  ; The tolerance accounts for small floating-point errors introduced
  ; by conversion through Julian dates.

  boundary_tolerance = 1.0d-5

  end_is_month_boundary = $
    abs(t_end - end_month_start) le boundary_tolerance

  if end_is_month_boundary && (t_end gt t_start) then begin
    exclusive_month_index = end_month_index
  endif else begin
    exclusive_month_index = end_month_index + 1LL
  endelse

  n_months = exclusive_month_index - first_month_index

  ; A zero-duration interval located exactly at a month boundary still
  ; returns one calendar-month interval.

  if n_months lt 1LL then n_months = 1LL

  intervals = dblarr(2, long(n_months))

  for i = 0LL, n_months - 1LL do begin

    month_index = first_month_index + i

    this_year  = long(month_index / 12LL)
    this_month = long(month_index mod 12LL) + 1L

    next_month_index = month_index + 1LL

    next_year  = long(next_month_index / 12LL)
    next_month = long(next_month_index mod 12LL) + 1L

    this_month_jd = julday(this_month, 1, this_year, $
      0, 0, 0.0d)

    next_month_jd = julday(next_month, 1, next_year, $
      0, 0, 0.0d)

    intervals[0, i] = $
      (this_month_jd - unix_epoch_jd) * seconds_per_day

    intervals[1, i] = $
      (next_month_jd - unix_epoch_jd) * seconds_per_day

  endfor

  return, intervals

end