;+
;FUNCTION:
;  srscan_trex_rgb_test_offline
;
;PURPOSE:
;  Offline (pure-logic) tests for the srs_canada TREx RGB routines: no
;  network access and no local data cache required. Covers the archive
;  filename window filter, gz dedup, the site table, keyword validation
;  in the public loader, and the config reader.
;
;  Each test is a procedure in this file; the function at the bottom
;  (same name as the file) returns the list of test names, so calling it
;  also compiles every test. Run with:
;    IDL> srscan_test_run, srscan_trex_rgb_test_offline()
;  or as part of the full suite via srscan_run_tests.
;-

; ---------------------------------------------------------------------
; srscan_files_in_window
; ---------------------------------------------------------------------

; minute granules: only files whose START time lies in [t0, t1] are
; kept, in original order
pro srscan_test_fiw_minute_granules
  compile_opt idl2
  f = '20230324_06' + ['00', '01', '02', '03', '04'] + '_gill_rgb-04_full.h5'
  r = srscan_files_in_window(f, time_double('2023-03-24/06:02:00'), $
    time_double('2023-03-24/06:03:59'), count = c)
  srscan_test_assert, c eq 2, 'expected 2 files kept, got ' + strtrim(c, 2)
  srscan_test_assert, array_equal(r, f[2 : 3]), 'wrong files kept or order not preserved'
end

; window bounds are inclusive on both ends
pro srscan_test_fiw_inclusive_bounds
  compile_opt idl2
  f = '20230324_06' + ['00', '01', '02', '03', '04'] + '_gill_rgb-04_full.h5'
  r = srscan_files_in_window(f, time_double('2023-03-24/06:01:00'), $
    time_double('2023-03-24/06:03:00'), count = c)
  srscan_test_assert, c eq 3, 'inclusive bounds: expected 3 files, got ' + strtrim(c, 2)
  srscan_test_assert, array_equal(r, f[1 : 3]), 'files at exact window bounds must be kept'
end

; hour granules (YYYYMMDD_hh_ basenames, e.g. hourly keograms)
pro srscan_test_fiw_hour_granules
  compile_opt idl2
  f = '20230324_' + ['05', '06', '07'] + '_gill_rgb-04_full-keogram.jpg'
  r = srscan_files_in_window(f, time_double('2023-03-24/06:00:00'), $
    time_double('2023-03-24/06:59:59'), count = c)
  srscan_test_assert, c eq 1, 'expected 1 hour granule kept, got ' + strtrim(c, 2)
  srscan_test_assert, r[0] eq f[1], 'wrong hour granule kept'
end

; basenames that match neither granule form are kept (fail open)
pro srscan_test_fiw_fail_open
  compile_opt idl2
  f = ['notes.txt', '20230324_0602_gill_rgb-04_full.h5']
  r = srscan_files_in_window(f, time_double('2023-03-24/07:00:00'), $
    time_double('2023-03-24/08:00:00'), count = c)
  srscan_test_assert, c eq 1, 'unrecognized basename must be kept (fail open)'
  srscan_test_assert, r[0] eq 'notes.txt', 'kept the wrong file'
end

; nothing in window: count 0 and '' returned
pro srscan_test_fiw_none_match
  compile_opt idl2
  r = srscan_files_in_window(['20230324_0602_gill_rgb-04_full.h5'], $
    time_double('2023-03-24/07:00:00'), time_double('2023-03-24/08:00:00'), count = c)
  srscan_test_assert, c eq 0, 'expected count 0'
  srscan_test_assert, r[0] eq '', "expected '' when no files match"
end

; ---------------------------------------------------------------------
; srscan_dedup_gz
; ---------------------------------------------------------------------

; prefers the .gz twin, keeps gz-less entries, preserves order
pro srscan_test_dedup_prefers_gz
  compile_opt idl2
  f = ['a/x.pgm', 'a/x.pgm.gz', 'b/y.pgm', 'c/z.pgm.gz']
  r = srscan_dedup_gz(f)
  srscan_test_assert, n_elements(r) eq 3, $
    'expected 3 entries, got ' + strtrim(n_elements(r), 2)
  srscan_test_assert, array_equal(r, ['a/x.pgm.gz', 'b/y.pgm', 'c/z.pgm.gz']), $
    '.gz variant not preferred or order not preserved'
end

; accepts LIST input (json_parse output)
pro srscan_test_dedup_list_input
  compile_opt idl2
  r = srscan_dedup_gz(list('a/x.pgm', 'a/x.pgm.gz'))
  srscan_test_assert, n_elements(r) eq 1 && r[0] eq 'a/x.pgm.gz', $
    'LIST input not deduped to the .gz variant'
end

; single-element input is returned unchanged
pro srscan_test_dedup_single
  compile_opt idl2
  r = srscan_dedup_gz(['only.pgm'])
  srscan_test_assert, n_elements(r) eq 1 && r[0] eq 'only.pgm', $
    'single-element input must pass through unchanged'
end

; ---------------------------------------------------------------------
; srscan_trex_rgb_sites
; ---------------------------------------------------------------------

pro srscan_test_sites_table
  compile_opt idl2
  s = srscan_trex_rgb_sites()
  srscan_test_assert, n_elements(s) eq 7, $
    'expected 7 sites, got ' + strtrim(n_elements(s), 2)
  srscan_test_assert, n_elements(uniq(s.uid, sort(s.uid))) eq 7, 'site uids must be unique'
  srscan_test_assert, total(s.uid eq 'gill') eq 1, 'gill missing from site table'
  srscan_test_assert, min(s.glat) gt 45 && max(s.glat) lt 70, $
    'site latitudes outside plausible range'
  srscan_test_assert, min(s.glon) gt -180 && max(s.glon) lt -80, $
    'site longitudes outside plausible range (east longitude, -180..180)'
end

; ---------------------------------------------------------------------
; srscan_load_trex_rgb keyword validation (returns before any I/O)
; ---------------------------------------------------------------------

pro srscan_test_load_valid_names
  compile_opt idl2
  srscan_load_trex_rgb, /valid_names, site = vs, datatype = vd
  srscan_test_assert, n_elements(vs) eq 7, 'valid_names: expected 7 sites'
  srscan_test_assert, array_equal(vd, ['raw', 'keogram', 'grid']), $
    'valid_names: unexpected datatype list'
end

pro srscan_test_load_invalid_site
  compile_opt idl2
  srscan_load_trex_rgb, site = 'zzzz', datatype = 'raw', $
    trange = ['2023-03-24/06:00', '2023-03-24/06:01'], /no_download
  tn = tnames('srscan_trexrgb_zzzz*', n)
  srscan_test_assert, n eq 0, 'invalid site must create no variables'
end

; ---------------------------------------------------------------------
; config reader
; ---------------------------------------------------------------------

; returns a structure (config exists) or -1 (no config); either is valid
pro srscan_test_config_read
  compile_opt idl2
  c = srscan_read_config()
  tp = size(c, /type)
  if tp eq 8 then begin
    srscan_test_assert, tag_exist(c, 'local_data_dir'), $
      'config struct missing local_data_dir'
  endif else begin
    srscan_test_assert, c[0] eq -1, 'expected struct or -1 from srscan_read_config'
  endelse
end

; ---------------------------------------------------------------------
; test list (function name matches the file so calling it compiles all
; of the tests above)
; ---------------------------------------------------------------------
function srscan_trex_rgb_test_offline

  compile_opt idl2

  return, [ $
    'srscan_test_fiw_minute_granules', $
    'srscan_test_fiw_inclusive_bounds', $
    'srscan_test_fiw_hour_granules', $
    'srscan_test_fiw_fail_open', $
    'srscan_test_fiw_none_match', $
    'srscan_test_dedup_prefers_gz', $
    'srscan_test_dedup_list_input', $
    'srscan_test_dedup_single', $
    'srscan_test_sites_table', $
    'srscan_test_load_valid_names', $
    'srscan_test_load_invalid_site', $
    'srscan_test_config_read' $
  ]
end
