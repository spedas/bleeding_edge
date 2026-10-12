;+
; PROCEDURE:
;         test_flatten_spectra_multi
;
; PURPOSE:
;         Test crib for the COLORS and TRANGE keywords of flatten_spectra_multi
;         (spedas/bleeding_edge issues #52 and #53; PR #423, hand-merged into SVN r34924).
;         Uses synthetic tplot spectra, so nothing is downloaded.
;
; KEYWORDS:
;         PNG:      also save a PNG of the flatten_spectra_multi window (window 1) for each visual case
;         PNG_DIR:  full path of the folder for the PNG files (default: the IDL working directory)
;         PAUSE:    seconds to wait after each visual case (default: 1)
;
; USAGE:
;         IDL> .compile /path/to/test_flatten_spectra_multi.pro
;         IDL> test_flatten_spectra_multi
;         IDL> test_flatten_spectra_multi, /png, png_dir='/tmp/fsm_test', pause=3
;
;         Every check prints PASS, FAIL or INFO, and a summary is printed at the end.
;         Every visual case prints what window 1 should show.
;
; NOTES:
;         Needs a windowing graphics device (X or WIN): flatten_spectra_multi always calls WINDOW, 1.
;
;         No cursor clicks are needed with r34924 or later. An older flatten_spectra_multi ignores
;         TRANGE, so the cases that pass only TRANGE wait for cursor clicks in the tplot window.
;
;         Checks labelled [fix] test the follow-up commits on the fix-flatten-spectra-multi branch
;         (THICK/LINESTYLE sized by the selected times; no IDL error when no spectra exist at the
;         selected time). They are expected to FAIL against r34924 alone. All other checks
;         should PASS against r34924.
;
;         The color checks read window 1 back with TVRD(TRUE=1) and count the pixels that have
;         the RGB value of a color index in the current color table. Index 0 (black) is never
;         checked because the axes use it. The checks are skipped (INFO) if the device is not
;         X or WIN, or if decomposed color is on.
;
;         Synthetic data (t0 = 2020-01-01/00:00:00, 16 energies from 10 eV to 10 keV):
;           fsm_test_a: 61 samples every 10 s, y[i, *] = (1+i)^2 * shape, 1-D energy table
;           fsm_test_b: 31 samples every 20 s, y[i, *] = (3 + 0.5*i^3) * shape, 1-D energy table
;           fsm_test_c: same times as fsm_test_a, y = 0.5 * fsm_test_a, energy table
;                       that changes with time (2-D v)
;         The reference averages are computed here with an explicit loop over the samples with
;         trange[0] <= t <= trange[1], independently of flatten_spectra_multi.
;-

pro fsm_info, label
  compile_opt idl2, hidden
  common fsm_test_com, n_pass, n_fail, n_info, failed
  n_info += 1
  print, '  INFO: ' + label
end

pro fsm_check, condition, label
  compile_opt idl2, hidden
  common fsm_test_com, n_pass, n_fail, n_info, failed
  ; condition passes if it is defined and all of its elements are nonzero
  passed = n_elements(condition) gt 0 && total(condition ne 0) eq n_elements(condition)
  if passed then begin
    n_pass += 1
    print, '  PASS: ' + label
  endif else begin
    n_fail += 1
    failed = [failed, label]
    print, '  FAIL: ' + label
  endelse
end

function fsm_close, a, b, tol=tol
  compile_opt idl2, hidden
  ; 1b if a and b have the same number of finite elements and agree to a relative tolerance
  if n_elements(tol) eq 0 then tol = 1d-9
  if n_elements(a) eq 0 || n_elements(b) eq 0 then return, 0b
  if n_elements(a) ne n_elements(b) then return, 0b
  da = reform(double(a), n_elements(a))
  db = reform(double(b), n_elements(b))
  if total(finite(da)) ne n_elements(da) || total(finite(db)) ne n_elements(db) then return, 0b
  return, max(abs(da - db) / (abs(db) > 1d-300)) lt tol
end

function fsm_ref_mean, t, y, tr
  compile_opt idl2, hidden
  ; independent reference: plain average of the spectra with tr[0] <= t <= tr[1]
  w = where(t ge tr[0] and t le tr[1], nw)
  if nw eq 0 then return, !null
  total_spec = dblarr(n_elements(y[0, *]))
  for k=0, nw-1 do total_spec += reform(double(y[w[k], *]))
  return, total_spec / double(nw)
end

function fsm_hash_get, h, key
  compile_opt idl2, hidden
  ; value stored under key in the yvalues/xvalues hash, or !null
  if ~isa(h, 'HASH') then return, !null
  if ~h.haskey(key) then return, !null
  return, h[key]
end

function fsm_call, num_spec, _ref_extra=ex
  compile_opt idl2, hidden
  ; run flatten_spectra_multi; return 0b instead of stopping if it raises an IDL error
  catch, err
  if err ne 0 then begin
    catch, /cancel
    print, '        flatten_spectra_multi stopped with an error: ' + !error_state.msg
    return, 0b
  endif
  flatten_spectra_multi, num_spec, _extra=ex
  catch, /cancel
  return, 1b
end

function fsm_count_color, img, r, g, b, index
  compile_opt idl2, hidden
  ; number of pixels in the TVRD(TRUE=1) image with the RGB value of color table entry index
  match = (img[0, *, *] eq r[index]) and (img[1, *, *] eq g[index]) and (img[2, *, *] eq b[index])
  return, long(total(match))
end

pro fsm_check_colors, present, absent, label
  compile_opt idl2, hidden
  ; present: color indexes that must appear in window 1; absent: indexes that must not appear
  if !d.name ne 'X' && !d.name ne 'WIN' then begin
    fsm_info, label + ' pixel color check skipped: device is ' + !d.name
    return
  endif
  device, get_decomposed=dec
  device, window_state=ws
  if dec ne 0 || n_elements(ws) lt 2 || ws[1] eq 0 then begin
    fsm_info, label + ' pixel color check skipped: decomposed color is on, or window 1 does not exist'
    return
  endif
  wset, 1
  empty
  wait, 0.3
  img = tvrd(true=1)
  tvlct, r, g, b, /get
  for k=0, n_elements(present)-1 do begin
    n = fsm_count_color(img, r, g, b, present[k])
    fsm_check, n gt 0, label + ' color ' + strtrim(present[k], 2) + ' is drawn (' + strtrim(n, 2) + ' pixels)'
  endfor
  for k=0, n_elements(absent)-1 do begin
    ; an absent color with the same RGB as a present color cannot be told apart, so skip it
    same_rgb = 0b
    for m=0, n_elements(present)-1 do begin
      if r[absent[k]] eq r[present[m]] && g[absent[k]] eq g[present[m]] && b[absent[k]] eq b[present[m]] then same_rgb = 1b
    endfor
    if same_rgb then continue
    n = fsm_count_color(img, r, g, b, absent[k])
    fsm_check, n eq 0, label + ' color ' + strtrim(absent[k], 2) + ' is not drawn (' + strtrim(n, 2) + ' pixels)'
  endfor
end

pro fsm_show, vis, name, expect
  compile_opt idl2, hidden
  ; describe what window 1 should show, optionally save it, and pause
  print, '    VISUAL (window 1): ' + expect
  if vis.png then begin
    if vis.dir ne '' then begin
      file_mkdir, vis.dir
      fname = vis.dir + path_sep() + 'fsm_' + name
    endif else fname = 'fsm_' + name
    makepng, fname, window=1
    print, '    saved ' + fname + '.png'
  endif
  if vis.pause gt 0 then wait, vis.pause
end

pro fsm_tplot, vars
  compile_opt idl2, hidden
  ; draw the tplot window (window 0); flatten_spectra_multi takes the variable names from it
  device, window_state=ws
  if n_elements(ws) eq 0 || ws[0] eq 0 then window, 0, xsize=700, ysize=500 else wset, 0
  tplot, vars
end

pro fsm_make_data, t0
  compile_opt idl2, hidden
  nen = 16
  energy = 10d^(1d + 3d*dindgen(nen)/(nen-1))   ; 10 eV to 10 keV
  shape = 1d6 * (energy/10d)^(-1.5d)

  ; fsm_test_a: 10 s cadence; the amplitude is not linear in time, so an average differs from any single spectrum
  nta = 61
  ta = t0 + 10d*dindgen(nta)
  ya = dblarr(nta, nen)
  for i=0, nta-1 do ya[i, *] = (1d + i)^2 * shape
  store_data, 'fsm_test_a', data={x: ta, y: ya, v: energy}

  ; fsm_test_b: 20 s cadence, different amplitude
  ntb = 31
  tb = t0 + 20d*dindgen(ntb)
  yb = dblarr(ntb, nen)
  for i=0, ntb-1 do yb[i, *] = (3d + 0.5d*i^3) * shape
  store_data, 'fsm_test_b', data={x: tb, y: yb, v: energy}

  ; fsm_test_c: same times as fsm_test_a, energy table that changes with time (2-D v)
  vc = dblarr(nta, nen)
  yc = dblarr(nta, nen)
  for i=0, nta-1 do begin
    vc[i, *] = energy * (1d + 0.01d*i)
    yc[i, *] = 0.5d * (1d + i)^2 * shape
  endfor
  store_data, 'fsm_test_c', data={x: ta, y: yc, v: vc}

  options, ['fsm_test_a', 'fsm_test_b', 'fsm_test_c'], spec=1, ylog=1, zlog=1, ysubtitle='[eV]', ztitle='eflux'
  options, 'fsm_test_a', ytitle='fsm_test_a!C10 s'
  options, 'fsm_test_b', ytitle='fsm_test_b!C20 s'
  options, 'fsm_test_c', ytitle='fsm_test_c!C2-D v'
end

pro test_flatten_spectra_multi, png=png, png_dir=png_dir, pause=pause
  compile_opt idl2
  common fsm_test_com, n_pass, n_fail, n_info, failed

  n_pass = 0L
  n_fail = 0L
  n_info = 0L
  failed = ''
  if n_elements(pause) eq 0 then pause = 1.0
  if n_elements(png_dir) gt 0 then dir = png_dir else dir = ''
  vis = {png: keyword_set(png), dir: dir, pause: pause}

  if (!d.flags and 256) eq 0 then begin
    print, 'test_flatten_spectra_multi needs a windowing graphics device (X or WIN); the current device is ' + !d.name
    return
  endif

  ; report which flatten_spectra_multi is being tested
  resolve_routine, 'flatten_spectra_multi', /no_recompile
  path = routine_filepath('flatten_spectra_multi')
  print, 'Testing ' + path
  if path ne '' then begin
    openr, lun, path, /get_lun
    line = ''
    while ~eof(lun) do begin
      readf, lun, line
      if strpos(line, 'LastChangedRevision') ge 0 then print, strtrim(line, 2)
    endwhile
    free_lun, lun
  endif

  t0 = time_double('2020-01-01/00:00:00')
  fsm_make_data, t0
  if tnames('flatten_spectra_time_multi') ne '' then del_data, 'flatten_spectra_time_multi'
  get_data, 'fsm_test_a', data=da
  get_data, 'fsm_test_b', data=db
  get_data, 'fsm_test_c', data=dc
  timespan, t0, 10, /minutes

  tr = t0 + [100d, 200d]                  ; fsm_test_a rows 10..20, fsm_test_b rows 5..10; midpoint t0+150 (fsm_test_a row 15)
  ref_a = fsm_ref_mean(da.x, da.y, tr)
  ref_b = fsm_ref_mean(db.x, db.y, tr)
  ref_c = fsm_ref_mean(dc.x, dc.y, tr)
  near_a = reform(double(da.y[15, *]))    ; the single spectrum nearest the midpoint

  ;
  ; TRANGE (issue #53)
  ;
  print, ''
  print, '=== TRANGE (issue #53) ==='
  fsm_tplot, 'fsm_test_a'

  print, 'Case 1: trange as doubles, one variable'
  yv = !null
  xv = !null
  ok = fsm_call(trange=tr, yvalues=yv, xvalues=xv, /xlog, /ylog, /rangetitle)
  fsm_check, ok, 'C1 ran without error and without cursor clicks'
  got = fsm_hash_get(yv, 'fsm_test_a')
  fsm_check, fsm_close(got, ref_a), 'C1 yvalues = mean of the 11 spectra in trange'
  fsm_check, n_elements(got) gt 0 && ~fsm_close(got, near_a), 'C1 yvalues differ from the single spectrum nearest the midpoint (data were averaged)'
  fsm_check, fsm_close(fsm_hash_get(xv, 'fsm_test_a'), da.v), 'C1 xvalues = the energy table'
  get_data, 'flatten_spectra_time_multi', data=st
  fsm_check, is_struct(st) && n_elements(st.x) eq 1 && abs(st.x[0] - (t0 + 150d)) lt 1d-3, $
    'C1 one spectrum, stored at the trange midpoint (used by /replot)'
  fsm_show, vis, 'c1_trange', 'one black line (default color 0); the legend is the range 00:01:40.000 - 00:03:20.000 (/rangetitle)'

  print, 'Case 2: trange as strings, in reverse order'
  yv = !null
  ok = fsm_call(trange=time_string(t0 + [200d, 100d]), yvalues=yv, /xlog, /ylog)
  fsm_check, ok, 'C2 ran without error'
  fsm_check, fsm_close(fsm_hash_get(yv, 'fsm_test_a'), ref_a), 'C2 same average as case 1'

  print, 'Case 3: trange and time together (documented: trange is used)'
  yv = !null
  ok = fsm_call(trange=tr, time=time_string(t0 + [400d, 500d]), yvalues=yv, /xlog, /ylog)
  fsm_check, ok, 'C3 ran without error'
  fsm_check, fsm_close(fsm_hash_get(yv, 'fsm_test_a'), ref_a), 'C3 yvalues = trange average; time is ignored'
  get_data, 'flatten_spectra_time_multi', data=st
  fsm_check, is_struct(st) && n_elements(st.x) eq 1 && abs(st.x[0] - (t0 + 150d)) lt 1d-3, $
    'C3 one spectrum, at the trange midpoint'

  print, 'Case 4: trange with two variables at different cadences, colors=[6]'
  fsm_tplot, ['fsm_test_a', 'fsm_test_b']
  c4 = [6]
  yv = !null
  ok = fsm_call(trange=tr, colors=c4, yvalues=yv, /xlog, /ylog)
  fsm_check, ok, 'C4 ran without error'
  fsm_check, fsm_close(fsm_hash_get(yv, 'fsm_test_a'), ref_a), 'C4 fsm_test_a (10 s) = mean of its 11 spectra in trange'
  fsm_check, fsm_close(fsm_hash_get(yv, 'fsm_test_b'), ref_b), 'C4 fsm_test_b (20 s) = mean of its 6 spectra in trange'
  fsm_check, n_elements(c4) eq 1 && c4[0] eq 6, 'C4 colors=[6] kept for the one trange spectrum'
  fsm_check_colors, [6], [2, 4], 'C4'
  fsm_show, vis, 'c4_trange_two_vars', 'two red lines (colors are per time, not per variable) and two red time labels'

  print, 'Case 5: trange with a time-varying energy table (2-D v)'
  fsm_tplot, 'fsm_test_c'
  yv = !null
  xv = !null
  ok = fsm_call(trange=tr, yvalues=yv, xvalues=xv, /xlog, /ylog)
  fsm_check, ok, 'C5 ran without error'
  fsm_check, fsm_close(fsm_hash_get(yv, 'fsm_test_c'), ref_c), 'C5 yvalues = mean of the spectra in trange'
  fsm_check, fsm_close(fsm_hash_get(xv, 'fsm_test_c'), reform(dc.v[15, *])), 'C5 xvalues = energy table of the sample nearest the midpoint'

  print, 'Case 6: window_time overrides trange (documented)'
  fsm_tplot, 'fsm_test_a'
  yv = !null
  ok = fsm_call(trange=tr, window_time=40d, yvalues=yv, /xlog, /ylog)
  fsm_check, ok && fsm_close(fsm_hash_get(yv, 'fsm_test_a'), fsm_ref_mean(da.x, da.y, t0 + [150d, 190d])), $
    'C6 trange + window_time=40: average over [midpoint, midpoint + 40 s]'
  yv = !null
  ok = fsm_call(trange=tr, window_time=40d, /center_time, yvalues=yv, /xlog, /ylog)
  fsm_check, ok && fsm_close(fsm_hash_get(yv, 'fsm_test_a'), fsm_ref_mean(da.x, da.y, t0 + [130d, 170d])), $
    'C6 trange + window_time=40 + /center_time: average over midpoint +/- 20 s'

  print, 'Case 7: samples overrides trange (documented)'
  yv = !null
  ok = fsm_call(trange=tr, samples=2, yvalues=yv, /xlog, /ylog)
  fsm_check, ok && fsm_close(fsm_hash_get(yv, 'fsm_test_a'), fsm_ref_mean(da.x, da.y, t0 + [150d, 170d])), $
    'C7 trange + samples=2: average of rows 15..17 (samples=N averages N+1 rows, as in flatten_spectra)'

  print, 'Case 8: trange boundaries between samples'
  tr8 = t0 + [104d, 196d]
  yv = !null
  ok = fsm_call(trange=tr8, yvalues=yv, /xlog, /ylog)
  got = fsm_hash_get(yv, 'fsm_test_a')
  inside = fsm_ref_mean(da.x, da.y, tr8)                   ; 9 spectra, t0+110 .. t0+190
  snapped = fsm_ref_mean(da.x, da.y, t0 + [100d, 200d])    ; 11 spectra: each boundary moved to the nearest sample
  fsm_check, ok && (fsm_close(got, inside) || fsm_close(got, snapped)), 'C8 result is one of the two expected averages'
  if fsm_close(got, snapped) then fsm_info, 'C8 each boundary snaps to the nearest sample (t0+100 and t0+200, outside the requested range), as in flatten_spectra'
  if fsm_close(got, inside) then fsm_info, 'C8 only the spectra inside trange are averaged'

  print, 'Case 9: trange partly or fully outside the data'
  yv = !null
  ok = fsm_call(trange=t0 + [450d, 700d], yvalues=yv, /xlog, /ylog)
  fsm_check, ok && fsm_close(fsm_hash_get(yv, 'fsm_test_a'), fsm_ref_mean(da.x, da.y, t0 + [450d, 700d])), $
    'C9 trange past the end of the data, midpoint inside: clipped to the data (rows 45..60)'
  yv = !null
  ok = fsm_call(trange=t0 + [550d, 800d], yvalues=yv, /xlog, /ylog)
  fsm_check, ok, '[fix] C9 trange midpoint after the end of the data: no IDL error (r34924 stops with "Variable is undefined: XR")'
  fsm_check, ok && n_elements(fsm_hash_get(yv, 'fsm_test_a')) eq 0, '[fix] C9 and no spectrum is returned'
  yv = !null
  ok = fsm_call(trange=t0 - [300d, 100d], yvalues=yv, /xlog, /ylog)
  fsm_check, ok, '[fix] C9 trange entirely before the data: no IDL error'

  ;
  ; COLORS (issue #52)
  ;
  print, ''
  print, '=== COLORS (issue #52) ==='
  fsm_tplot, 'fsm_test_a'
  times = time_string(t0 + [100d, 300d, 500d])

  print, 'Case 10: time= with three times and colors=[6, 1, 3]'
  c10 = [6, 1, 3]
  yv = !null
  ok = fsm_call(time=times, colors=c10, yvalues=yv, /xlog, /ylog)
  fsm_check, ok, 'C10 ran without error'
  fsm_check, array_equal(c10, [6, 1, 3]), 'C10 user colors kept when time= is given (before r34924 they were reset to 0, 2, 4)'
  fsm_check_colors, [6, 1, 3], [2, 4], 'C10'
  fsm_check, fsm_close(fsm_hash_get(yv, 'fsm_test_a'), reform(da.y[50, *])), 'C10 yvalues hold the spectrum at the last time (00:08:20, row 50)'
  fsm_info, 'C10 yvalues/xvalues are keyed by variable name, so only the last selected time is returned'
  fsm_show, vis, 'c10_time_colors', 'three lines: red (00:01:40), magenta (00:05:00), cyan (00:08:20); legend labels in the same colors'

  print, 'Case 11: two variables, two times, colors=[6, 3]'
  fsm_tplot, ['fsm_test_a', 'fsm_test_b']
  c11 = [6, 3]
  ok = fsm_call(time=time_string(t0 + [100d, 400d]), colors=c11, /xlog, /ylog)
  fsm_check, ok && array_equal(c11, [6, 3]), 'C11 ran without error and kept colors=[6, 3]'
  fsm_check_colors, [6, 3], [2, 4], 'C11'
  fsm_show, vis, 'c11_two_vars_colors', 'two red lines (both variables at 00:01:40) and two cyan lines (00:06:40)'

  print, 'Case 12: fewer colors than times (colors=[6] for three times)'
  fsm_tplot, 'fsm_test_a'
  c12 = [6]
  ok = fsm_call(time=times, colors=c12, /xlog, /ylog)
  fsm_check, ok, 'C12 ran without error'
  fsm_check, array_equal(c12, [0, 2, 4]), 'C12 falls back to the default colors 0, 2, 4 (same rule as flatten_spectra)'
  fsm_check_colors, [2, 4], [6], 'C12'
  fsm_show, vis, 'c12_fewer_colors', 'three lines in the default colors: black, blue, green'

  print, 'Case 13: /replot (the three times stored by case 12) with colors'
  c13 = [6, 1, 3]
  ok = fsm_call(/replot, colors=c13, /xlog, /ylog)
  fsm_check, ok && array_equal(c13, [6, 1, 3]), 'C13 /replot keeps colors=[6, 1, 3]'
  fsm_check_colors, [6, 1, 3], [2, 4], 'C13'
  c13b = [6]
  ok = fsm_call(/replot, colors=c13b, /xlog, /ylog)
  fsm_check, ok, 'C13 /replot with fewer colors than times runs (before r34924: subscript out of range)'
  fsm_check, array_equal(c13b, [0, 2, 4]), 'C13 /replot with fewer colors falls back to 0, 2, 4'

  print, 'Case 14: scalar colors with one spectrum'
  c14 = 6
  ok = fsm_call(trange=tr, colors=c14, /xlog, /ylog)
  fsm_check, ok && n_elements(c14) eq 1 && c14[0] eq 6, 'C14 colors=6 (scalar) kept for one spectrum'
  fsm_check_colors, [6], [2], 'C14'
  c14z = 0
  ok = fsm_call(trange=tr, colors=c14z, /xlog, /ylog)
  fsm_check, ok && n_elements(c14z) eq 1 && c14z[0] eq 0, 'C14 colors=0 (scalar) kept: index 0 is a valid color'

  print, 'Case 15: no colors keyword'
  cdef = !null
  ok = fsm_call(time=times, colors=cdef, /xlog, /ylog)
  fsm_check, ok && n_elements(cdef) eq 3 && array_equal(cdef, [0, 2, 4]), 'C15 default colors are 0, 2, 4 for three times'

  print, 'Case 16: thick and linestyle with more times than num_spec (num_spec defaults to 2)'
  ok = fsm_call(time=times, colors=[6, 1, 3], thick=3, /xlog, /ylog)
  fsm_check, ok, '[fix] C16 time= with three times and a scalar thick=3 runs (r34924: subscript out of range)'
  th = [1, 3, 5]
  ls = [0, 2, 1]
  ok = fsm_call(time=times, colors=[6, 1, 3], thick=th, linestyle=ls, /xlog, /ylog)
  fsm_check, ok && n_elements(th) eq 3 && n_elements(ls) eq 3, $
    '[fix] C16 one thick and linestyle value per time is accepted (r34924 rejects them because num_spec is 2)'
  fsm_show, vis, 'c16_thick_linestyle', 'red thin solid, magenta medium dashed, cyan thick dotted lines'

  ;
  ; Summary
  ;
  print, ''
  print, '=== Summary ==='
  print, 'PASS: ' + strtrim(n_pass, 2) + '   FAIL: ' + strtrim(n_fail, 2) + '   INFO: ' + strtrim(n_info, 2)
  if n_fail gt 0 then begin
    print, 'Failed checks:'
    for k=1, n_elements(failed)-1 do print, '  ' + failed[k]
  endif
end