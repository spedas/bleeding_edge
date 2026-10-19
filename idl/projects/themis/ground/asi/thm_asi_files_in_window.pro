;+
;FUNCTION:
;  thm_asi_files_in_window
;
;PURPOSE:
;  Filter a list of archive file paths to those whose filename start
;  timestamp lies within [t0, t1] -- the same "file START time in
;  [start, end]" rule the data distribution API applies to listings, so
;  the offline cache-glob fallbacks resolve the same file set the server
;  query would.
;
;  Without this, the hour/day globs can catch granules far outside the
;  request window: a single-frame time= request globs every minute file
;  of the hour (~60x the data needed), and an ast/VEC1024 time= request
;  globs every hourly file of the day.
;
;  Archive basenames start 'YYYYMMDD_hhmm_' (minute granules) or
;  'YYYYMMDD_hh_' (hour granules); files whose basename does not match
;  either form are kept (fail open).
;
;INPUT:
;  files:  string array of file paths
;  t0, t1: window bounds (unix time, inclusive)
;
;KEYWORDS:
;  count: (out) number of files kept
;
;OUTPUT:
;  Filtered string array ('' when count is 0; original order preserved).
;-
function thm_asi_files_in_window, files, t0, t1, count = count

  compile_opt idl2

  n = n_elements(files)
  count = 0l
  if n eq 0 then return, files

  keep = bytarr(n)
  for i = 0l, n - 1 do begin
    b = file_basename(files[i])
    m = stregex(b, '^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})?_', $
      /subexpr, /extract)
    if m[0] eq '' then begin
      keep[i] = 1b                               ; unrecognized name: keep
      continue
    endif
    mm = (m[5] eq '') ? '00' : m[5]
    ft = time_double(m[1] + '-' + m[2] + '-' + m[3] + '/' + m[4] + ':' + mm + ':00')
    keep[i] = (ft ge t0) && (ft le t1)
  endfor

  w = where(keep, count)
  return, (count gt 0) ? files[w] : ''
end
