;+
;FUNCTION:
;  srscan_hapi_test_network
;
;PURPOSE:
;  Network tests for the riometer HAPI server (srscan_api_config's
;  hapi_url, https://api.phys.ucalgary.ca/hapi by default) through the
;  generic SPEDAS client hapi_load_data. Covers the informational
;  endpoints (capabilities/catalog/info), loads of each dataset family
;  (NORSTAR_RIOMETER_K0, NORSTAR_RIOMETER_K2, SWAN_HSR_K0 spectrogram
;  with time-varying bins), parameters=/prefix=/suffix=, NaN fill
;  handling, and clean failure for requests the server rejects.
;
;  Unlike the offline and data tiers these tests need the network; every
;  test SKIPs when the server cannot be reached. Reference values are
;  pinned to archived intervals (2007-11-19 and 1989-03-10 at gill, HSR
;  2026-01-25) -- a server-side reprocessing of those days would show up
;  here as a value mismatch. Downloaded CSVs go to a scratch directory
;  under IDL's temp dir, not the srs_canada data cache.
;
;  Each test is a procedure in this file; the function at the bottom
;  (same name as the file) returns the list of test names. Run with:
;    IDL> srscan_test_run, srscan_hapi_test_network()
;  or as part of the full suite via srscan_run_tests, /network.
;-

; skip the current test if the HAPI server does not answer /capabilities
; (probed once per session with a short timeout, so an unreachable server
; costs seconds rather than hapi_load_data's multi-minute timeouts)
pro srscan_test_require_hapi
  compile_opt idl2
  common srscan_test_hapi_com, hapi_up
  if n_elements(hapi_up) eq 0 then begin
    hapi_up = 0b
    catch, err
    if err eq 0 then begin
      parts = parse_url((srscan_api_config()).hapi_url)
      u = obj_new('IDLnetURL', url_scheme = parts.scheme, url_host = parts.host, $
        url_path = parts.path + '/capabilities', connect_timeout = 15, timeout = 30)
      r = json_parse(string(u->get(/buffer)))
      hapi_up = r.hasKey('HAPI')
    endif
    catch, /cancel
    if obj_valid(u) then obj_destroy, u
  endif
  if ~hapi_up then srscan_test_skip, 'HAPI server not reachable (' + $
    (srscan_api_config()).hapi_url + ')'
end

; hapi_load_data against the configured server with a scratch download
; directory; returns the tplot names created ('' if none) and their count
function srscan_test_hapi_load, dataset, trange, count = count, _extra = ex
  compile_opt idl2
  srscan_test_require_hapi
  del_data, '*'
  tn = !null
  hapi_load_data, server = (srscan_api_config()).hapi_url, dataset = dataset, $
    trange = trange, tplotnames = tn, $
    local_data_dir = filepath('srscan_hapi_test', /tmp), _extra = ex
  count = n_elements(tn)
  return, count gt 0 ? tn : ''
end

; ---------------------------------------------------------------------
; informational endpoints
; ---------------------------------------------------------------------

; HAPI 3.x server offering csv (the only format hapi_load_data reads)
pro srscan_test_hapi_capabilities
  compile_opt idl2
  srscan_test_require_hapi
  cap = 1
  hapi_load_data, capabilities = cap, server = (srscan_api_config()).hapi_url
  srscan_test_assert, isa(cap, 'HASH'), 'capabilities not returned'
  srscan_test_assert, strmid(cap['HAPI'], 0, 1) ge '3', $
    'expected HAPI 3.x, got ' + cap['HAPI']
  srscan_test_assert, total(cap['outputFormats'].toArray() eq 'csv') eq 1, $
    'server does not offer csv output'
end

; catalog lists all three dataset families as <FAMILY>@<SITE> ids
pro srscan_test_hapi_catalog
  compile_opt idl2
  srscan_test_require_hapi
  cat = 1
  hapi_load_data, catalog = cat, server = (srscan_api_config()).hapi_url
  srscan_test_assert, isa(cat, 'HASH') && cat.hasKey('catalog'), 'catalog not returned'
  ids = strarr(n_elements(cat['catalog']))
  foreach entry, cat['catalog'], i do ids[i] = entry['id']
  foreach id, ['NORSTAR_RIOMETER_K0@GILL', 'NORSTAR_RIOMETER_K2@GILL', $
    'SWAN_HSR_K0@GILL'] do $
    srscan_test_assert, total(ids eq id) eq 1, id + ' missing from catalog'
  srscan_test_assert, total(stregex(ids, '^[A-Z0-9_]+@[A-Z]{4}$', /boolean)) eq n_elements(ids), $
    'catalog id not of the form <FAMILY>@<SITE>'
end

; info: parameter names/units, 5-s cadence, NaN fill
pro srscan_test_hapi_info
  compile_opt idl2
  srscan_test_require_hapi
  info = 1
  hapi_load_data, info = info, dataset = 'NORSTAR_RIOMETER_K2@GILL', $
    server = (srscan_api_config()).hapi_url
  srscan_test_assert, isa(info, 'HASH') && info.hasKey('parameters'), 'info not returned'
  p = info['parameters']
  srscan_test_assert, n_elements(p) eq 3, 'expected 3 parameters, got ' + strtrim(n_elements(p), 2)
  srscan_test_assert, p[0, 'name'] eq 'Time' && p[0, 'type'] eq 'isotime', $
    'first parameter must be the isotime Time column'
  srscan_test_assert, p[1, 'name'] eq 'absorption' && p[1, 'units'] eq 'dB', 'absorption (dB) expected'
  srscan_test_assert, p[2, 'name'] eq 'raw_signal' && p[2, 'units'] eq 'V', 'raw_signal (V) expected'
  srscan_test_assert, p[1, 'fill'] eq 'NaN', 'absorption fill must be NaN'
  srscan_test_assert, info['cadence'] eq 'PT5S', 'expected PT5S cadence, got ' + info['cadence']
end

; ---------------------------------------------------------------------
; data loads
; ---------------------------------------------------------------------

; K2 (absorption + raw signal): one hour at 5 s, pinned first values
pro srscan_test_hapi_k2_load
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K2@GILL', $
    ['2007-11-19/00:00', '2007-11-19/01:00'])
  srscan_test_assert, total(tn eq 'absorption') eq 1 && total(tn eq 'raw_signal') eq 1, $
    'absorption/raw_signal not created (got: ' + strjoin(tn, ',') + ')'
  get_data, 'absorption', data = a
  get_data, 'raw_signal', data = r
  srscan_test_assert, n_elements(a.x) eq 720, 'expected 720 samples, got ' + strtrim(n_elements(a.x), 2)
  srscan_test_assert, size(a.y, /type) eq 5 && size(r.y, /type) eq 5, 'data must be double'
  srscan_test_assert, a.x[0] eq time_double('2007-11-19/00:00:04'), $
    'first sample at ' + time_string(a.x[0]) + ', expected 00:00:04'
  srscan_test_assert, abs(median(a.x[1 : *] - a.x) - 5d) lt 1d-6, 'cadence not 5 s'
  srscan_test_assert, abs(a.y[0] - 0.079d) lt 1d-9 && abs(r.y[0] - 3.887d) lt 1d-9, $
    'first values changed (absorption ' + strtrim(a.y[0], 2) + ', raw ' + strtrim(r.y[0], 2) + ')'
end

; K0 (raw signal only) with prefix=/suffix= naming for multi-site work
pro srscan_test_hapi_k0_prefix_suffix
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K0@GILL', $
    ['2015-10-09/00:00', '2015-10-09/01:00'], prefix = 'gill_', suffix = '_k0')
  srscan_test_assert, total(tn eq 'gill_raw_signal_k0') eq 1, $
    'gill_raw_signal_k0 not created (got: ' + strjoin(tn, ',') + ')'
  srscan_test_assert, tnames('raw_signal') eq '', 'unprefixed variable also created'
  get_data, 'gill_raw_signal_k0', data = d
  srscan_test_assert, n_elements(d.x) ge 700 && n_elements(d.x) le 720, $
    'expected ~720 samples, got ' + strtrim(n_elements(d.x), 2)
end

; parameters= limits the request (and the variables created)
pro srscan_test_hapi_parameters_subset
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K2@GILL', $
    ['2007-11-19/00:00', '2007-11-19/01:00'], parameters = 'raw_signal')
  srscan_test_assert, total(tn eq 'raw_signal') eq 1, 'raw_signal not created'
  srscan_test_assert, total(tn eq 'absorption') eq 0, 'absorption created despite parameters='
  get_data, 'raw_signal', data = r
  srscan_test_assert, n_elements(r.x) eq 720 && abs(r.y[0] - 3.887d) lt 1d-9, $
    'subset request returned wrong data'
end

; NaN fill: absorption is NaN where the baseline could not be computed
; (52 of 337 samples here); raw_signal stays fully finite
pro srscan_test_hapi_nan_fill
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K2@GILL', $
    ['1989-03-10/00:00', '1989-03-10/00:30'])
  get_data, 'absorption', data = a
  get_data, 'raw_signal', data = r
  srscan_test_assert, is_struct(a) && is_struct(r), 'variables not created'
  srscan_test_assert, size(a.y, /type) eq 5, 'absorption must be double'
  srscan_test_assert, n_elements(a.x) eq 337, 'expected 337 samples, got ' + strtrim(n_elements(a.x), 2)
  srscan_test_assert, total(finite(a.y)) eq 285, $
    'expected 285 finite absorption samples, got ' + strtrim(long(total(finite(a.y))), 2)
  srscan_test_assert, total(finite(r.y)) eq 337, 'raw_signal must be fully finite'
end

; a window where absorption is entirely NaN must still load as double
; (read_csv types an all-'NaN' column as STRING)
pro srscan_test_hapi_all_nan_column
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K2@GILL', $
    ['1989-03-10/00:11:00', '1989-03-10/00:11:30'])
  get_data, 'absorption', data = a
  srscan_test_assert, is_struct(a), 'absorption not created'
  srscan_test_assert, size(a.y, /type) eq 5, $
    'all-NaN absorption loaded as ' + size(a.y, /tname) + ', expected DOUBLE'
  srscan_test_assert, total(finite(a.y)) eq 0, 'expected all-NaN absorption'
end

; a one-sample response must still load as numbers
pro srscan_test_hapi_single_sample
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K2@GILL', $
    ['2007-11-19/00:00:00', '2007-11-19/00:00:05'])
  get_data, 'raw_signal', data = r
  srscan_test_assert, is_struct(r), 'raw_signal not created'
  srscan_test_assert, n_elements(r.x) eq 1, 'expected 1 sample, got ' + strtrim(n_elements(r.x), 2)
  srscan_test_assert, size(r.y, /type) eq 5, $
    'single-sample raw_signal loaded as ' + size(r.y, /tname) + ', expected DOUBLE'
  srscan_test_assert, abs(r.y[0] - 3.887d) lt 1d-9, 'wrong value'
end

; the isotime column is the time axis, not a data variable
pro srscan_test_hapi_no_time_variable
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K2@GILL', $
    ['2007-11-19/00:00', '2007-11-19/00:10'])
  srscan_test_assert, total(strlowcase(tn) eq 'time') eq 0, $
    'Time column stored as a tplot variable'
end

; SWAN HSR: 11-band spectrogram whose bin centers come from the
; band_central_frequency parameter (time-varying v, out-of-order bands)
pro srscan_test_hapi_hsr_spectrogram
  compile_opt idl2
  tn = srscan_test_hapi_load('SWAN_HSR_K0@GILL', $
    ['2026-01-25/00:00', '2026-01-25/00:10'], prefix = 'gill_hsr_')
  get_data, 'gill_hsr_raw_power', data = d, dlimits = dl
  srscan_test_assert, is_struct(d), 'gill_hsr_raw_power not created (got: ' + strjoin(tn, ',') + ')'
  srscan_test_assert, tag_exist(d, 'v'), 'raw_power has no v (bin centers)'
  srscan_test_assert, array_equal(size(d.y, /dimensions), [600, 11]), $
    'expected y[600,11], got [' + strjoin(strtrim(size(d.y, /dimensions), 2), ',') + ']'
  srscan_test_assert, array_equal(size(d.v, /dimensions), [600, 11]), $
    'expected time-varying v[600,11]'
  srscan_test_assert, array_equal(reform(d.v[0, *]), $
    [30d, 20, 22, 24, 26, 28, 32, 34, 36, 38, 40]), 'band centers changed'
  srscan_test_assert, abs(median(d.x[1 : *] - d.x) - 1d) lt 1d-6, 'cadence not 1 s'
  srscan_test_assert, abs(d.y[0, 0] - 31.090511d) lt 1d-6, 'first raw_power value changed'
  str_element, dl, 'spec', spec
  str_element, dl, 'sort_spec_bins', sortbins
  srscan_test_assert, keyword_set(spec) && keyword_set(sortbins), $
    'raw_power must be flagged spec=1, sort_spec_bins=1'
end

; ---------------------------------------------------------------------
; requests the server rejects or that return nothing: no error thrown,
; no variables created
; ---------------------------------------------------------------------

; window outside the dataset coverage (caught client-side from info)
pro srscan_test_hapi_outside_coverage
  compile_opt idl2
  tn = srscan_test_hapi_load('SWAN_HSR_K0@PINA', ['2025-10-01', '2025-10-02'], count = n)
  srscan_test_assert, n eq 0, 'variables created outside dataset coverage'
end

; longer than maxRequestDuration (P31D): server answers HTTP 400 / 1408
pro srscan_test_hapi_too_long_request
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K2@GILL', ['2007-01-01', '2007-03-01'], count = n)
  srscan_test_assert, n eq 0, 'variables created for a rejected request'
end

; unknown dataset id: server answers HTTP 404 / 1406
pro srscan_test_hapi_unknown_dataset
  compile_opt idl2
  tn = srscan_test_hapi_load('NORSTAR_RIOMETER_K2@ZZZZ', ['2007-11-19', '2007-11-20'], count = n)
  srscan_test_assert, n eq 0, 'variables created for an unknown dataset'
end

; in coverage but no samples (empty 200 response)
pro srscan_test_hapi_empty_window
  compile_opt idl2
  tn = srscan_test_hapi_load('SWAN_HSR_K0@GILL', $
    ['2025-07-23/12:00:00', '2025-07-23/12:00:01'], count = n)
  srscan_test_assert, n eq 0, 'variables created for an empty window'
end

; ---------------------------------------------------------------------
; test list (function name matches the file so calling it compiles all
; of the tests above)
; ---------------------------------------------------------------------
function srscan_hapi_test_network

  compile_opt idl2

  return, [ $
    'srscan_test_hapi_capabilities', $
    'srscan_test_hapi_catalog', $
    'srscan_test_hapi_info', $
    'srscan_test_hapi_k2_load', $
    'srscan_test_hapi_k0_prefix_suffix', $
    'srscan_test_hapi_parameters_subset', $
    'srscan_test_hapi_nan_fill', $
    'srscan_test_hapi_all_nan_column', $
    'srscan_test_hapi_single_sample', $
    'srscan_test_hapi_no_time_variable', $
    'srscan_test_hapi_hsr_spectrogram', $
    'srscan_test_hapi_outside_coverage', $
    'srscan_test_hapi_too_long_request', $
    'srscan_test_hapi_unknown_dataset', $
    'srscan_test_hapi_empty_window' $
  ]
end
