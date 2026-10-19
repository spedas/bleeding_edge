;+
;FUNCTION:
;  srscan_trex_rgb_test_data
;
;PURPOSE:
;  Data-dependent tests for the srs_canada TREx RGB loaders. These run
;  entirely offline (/no_download) against the local data cache for the
;  reference test night 2023-03-24 (the aurora event used throughout the
;  cribs); tests SKIP rather than fail when the needed dataset is not
;  cached. Cache expectations:
;    TREX_RGB_RAW_NOMINAL:    2023-03-24 ut06 (all sites; rabb also has
;                             ut07 minute 0722 for the cross-hour test)
;    TREX_RGB_HOURLY_KEOGRAM: 2023-03-24 ut01..ut10+ per site
;    TREX_RGB_GRID_MOSV001:   2023-03-24 06:22
;  A first run with downloads enabled populates the cache, e.g.:
;    srscan_load_trex_rgb, site='gill', trange=['2023-03-24/06:00','2023-03-24/07:00'], /downloadonly
;
;  Each test is a procedure in this file; the function at the bottom
;  (same name as the file) returns the list of test names. Run with:
;    IDL> srscan_test_run, srscan_trex_rgb_test_data()
;  or as part of the full suite via srscan_run_tests.
;-

; skip the current test if the given dataset has no cached 2023-03-24 tree
pro srscan_test_require_cache, dataset
  compile_opt idl2
  srscan_init
  d = !srs_canada.local_data_dir + dataset + path_sep() + '2023' + $
    path_sep() + '03' + path_sep() + '24'
  if ~file_test(d, /directory) then $
    srscan_test_skip, dataset + ' 2023-03-24 data not in local cache (' + d + ')'
end

; ---------------------------------------------------------------------
; raw (stream0 1-min HDF5 granules, ~3-s cadence)
; ---------------------------------------------------------------------

; range load: clipped to trange, [n,3,553,480] byte, ~3-s cadence
pro srscan_test_raw_load_clip
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_raw
  del_data, 'srscan_trexrgb_gill'
  tr = ['2023-03-24/06:15:30', '2023-03-24/06:17:30']
  srscan_load_trex_rgb, site = 'gill', datatype = 'raw', trange = tr, /no_download
  get_data, 'srscan_trexrgb_gill', data = d
  srscan_test_assert, is_struct(d), 'srscan_trexrgb_gill not created'
  srscan_test_assert, min(d.x) ge time_double(tr[0]) && max(d.x) le time_double(tr[1]), $
    'frames outside requested trange (default clipping broken)'
  sz = size(d.y)
  srscan_test_assert, sz[0] eq 4 && sz[2] eq 3 && sz[3] eq 553 && sz[4] eq 480, $
    'unexpected raw image dimensions'
  srscan_test_assert, sz[5] eq 1, 'raw frames must be byte type'
  n = n_elements(d.x)
  srscan_test_assert, n ge 30 && n le 50, $
    'expected ~40 frames for 2 min at 3 s, got ' + strtrim(n, 2)
  dt = median(d.x[1 : *] - d.x)
  srscan_test_assert, abs(dt - 3d) lt 0.5d, $
    'cadence not ~3 s (median dt = ' + strtrim(dt, 2) + ')'
end

; /no_time_clip: output aligns to the whole 1-min file granules; also
; exercises suffix=
pro srscan_test_raw_no_time_clip
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_raw
  del_data, 'srscan_trexrgb_gill_nc'
  tr = ['2023-03-24/06:15:30', '2023-03-24/06:17:30']
  srscan_load_trex_rgb, site = 'gill', trange = tr, /no_download, $
    /no_time_clip, suffix = '_nc'
  get_data, 'srscan_trexrgb_gill_nc', data = d
  srscan_test_assert, is_struct(d), 'suffixed variable not created'
  srscan_test_assert, min(d.x) lt time_double(tr[0]) && $
    min(d.x) ge time_double('2023-03-24/06:15:00'), $
    'no_time_clip output must start at the 06:15 granule boundary'
  srscan_test_assert, max(d.x) gt time_double(tr[1]) && $
    max(d.x) lt time_double('2023-03-24/06:18:00'), $
    'no_time_clip output must end at the 06:17 granule end'
end

; time=: single nearest frame, [3,553,480] single-record convention
pro srscan_test_raw_single_frame
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_raw
  del_data, 'srscan_trexrgb_gill'
  t = '2023-03-24/06:22:30'
  srscan_load_trex_rgb, site = 'gill', time = t, /no_download
  get_data, 'srscan_trexrgb_gill', data = d
  srscan_test_assert, is_struct(d), 'single-frame variable not created'
  srscan_test_assert, n_elements(d.x) eq 1, 'time= must load exactly one frame'
  srscan_test_assert, abs(d.x[0] - time_double(t)) le 1.5d, $
    'frame not within 1.5 s of requested time'
  sz = size(d.y)
  srscan_test_assert, sz[0] eq 3 && sz[1] eq 3 && sz[2] eq 553 && sz[3] eq 480, $
    'single-frame y must be [3,553,480]'
end

; range requests resolve exactly the 1-min granules covering trange
pro srscan_test_raw_file_granules
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_raw
  srscan_load_trex_rgb, site = 'gill', $
    trange = ['2023-03-24/06:15:30', '2023-03-24/06:17:30'], $
    /no_download, /downloadonly, files = ff
  srscan_test_assert, n_elements(ff) eq 3, $
    'expected the 3 granules 0615..0617, got ' + strtrim(n_elements(ff), 2)
  b = file_basename(ff)
  srscan_test_assert, array_equal(strmid(b, 0, 13), '20230324_06' + ['15', '16', '17']), $
    'wrong granules resolved: ' + strjoin(b, ' ')
end

; relpathnames_all: cache-relative, forward slashes, dataset-rooted
pro srscan_test_raw_relpaths
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_raw
  srscan_load_trex_rgb, site = 'gill', $
    trange = ['2023-03-24/06:15:30', '2023-03-24/06:17:30'], $
    relpathnames_all = rp
  srscan_test_assert, n_elements(rp) eq 3, $
    'expected 3 relpaths, got ' + strtrim(n_elements(rp), 2)
  srscan_test_assert, total(strpos(rp, '\') ge 0) eq 0, $
    'relpaths must use forward slashes'
  srscan_test_assert, array_equal(strmid(rp, 0, 20), 'TREX_RGB_RAW_NOMINAL'), $
    'relpaths must be rooted at the dataset name'
end

; a trange spanning an hour boundary picks up granules from both hour
; directories of the cache tree (rabb has ut06 0659 and ut07 0722 cached)
pro srscan_test_raw_cross_hour
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_raw
  del_data, 'srscan_trexrgb_rabb'
  tr = ['2023-03-24/06:59:00', '2023-03-24/07:22:59']
  srscan_load_trex_rgb, site = 'rabb', trange = tr, /no_download
  get_data, 'srscan_trexrgb_rabb', data = d
  srscan_test_assert, is_struct(d), 'srscan_trexrgb_rabb not created'
  srscan_test_assert, total(d.x lt time_double('2023-03-24/07:00:00')) gt 0, $
    'no frames from the ut06 side of the hour boundary'
  srscan_test_assert, total(d.x ge time_double('2023-03-24/07:22:00')) gt 0, $
    'no frames from the ut07 side of the hour boundary'
end

; a range with no cached files must create nothing and not throw
pro srscan_test_raw_no_data_range
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_raw
  del_data, 'srscan_trexrgb_gill'
  srscan_load_trex_rgb, site = 'gill', $
    trange = ['2023-03-25/06:00', '2023-03-25/06:02'], /no_download
  tn = tnames('srscan_trexrgb_gill', n)
  srscan_test_assert, n eq 0, 'no variable should be created for an uncached range'
end

; ---------------------------------------------------------------------
; keogram (hourly JPEG quicklooks)
; ---------------------------------------------------------------------

; RGB keogram [n,rows,3] clipped to trange, plus channel companion [n,rows]
pro srscan_test_keogram_load
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_keogram
  del_data, 'srscan_trexrgb_keo_gill*'
  tr = ['2023-03-24/04:00', '2023-03-24/06:00']
  srscan_load_trex_rgb, site = 'gill', datatype = 'keogram', trange = tr, $
    /no_download, channel = 'r'
  get_data, 'srscan_trexrgb_keo_gill', data = d
  srscan_test_assert, is_struct(d), 'srscan_trexrgb_keo_gill not created'
  sz = size(d.y)
  srscan_test_assert, sz[0] eq 3 && sz[3] eq 3, $
    'keogram y must be [n, rows, 3] truecolor'
  srscan_test_assert, min(d.x) ge time_double(tr[0]) && max(d.x) le time_double(tr[1]), $
    'keogram columns outside requested trange (clipping broken)'
  get_data, 'srscan_trexrgb_keo_gill_r', data = dc
  srscan_test_assert, is_struct(dc), 'channel companion srscan_trexrgb_keo_gill_r not created'
  szc = size(dc.y)
  srscan_test_assert, szc[0] eq 2 && szc[2] eq sz[2], $
    'channel companion must be [n, rows]'
end

; ---------------------------------------------------------------------
; grid (MOSv001 pre-rendered mosaic grids)
; ---------------------------------------------------------------------

; [n,3,1024,512] float with -999 fill cells
pro srscan_test_grid_load
  compile_opt idl2
  srscan_test_require_cache, (srscan_api_config()).dataset_rgb_grid
  del_data, 'srscan_trexrgb_grid'
  srscan_load_trex_rgb, datatype = 'grid', $
    trange = ['2023-03-24/06:22:00', '2023-03-24/06:22:59'], /no_download
  get_data, 'srscan_trexrgb_grid', data = d
  srscan_test_assert, is_struct(d), 'srscan_trexrgb_grid not created'
  sz = size(d.y)
  srscan_test_assert, sz[0] eq 4 && sz[2] eq 3 && sz[3] eq 1024 && sz[4] eq 512, $
    'unexpected grid dimensions'
  srscan_test_assert, sz[5] eq 4, 'grid must be float type'
  srscan_test_assert, total(d.y eq -999.) gt 0, $
    'expected -999 fill cells outside imager fields of view'
end

; ---------------------------------------------------------------------
; test list (function name matches the file so calling it compiles all
; of the tests above)
; ---------------------------------------------------------------------
function srscan_trex_rgb_test_data

  compile_opt idl2

  return, [ $
    'srscan_test_raw_load_clip', $
    'srscan_test_raw_no_time_clip', $
    'srscan_test_raw_single_frame', $
    'srscan_test_raw_file_granules', $
    'srscan_test_raw_relpaths', $
    'srscan_test_raw_cross_hour', $
    'srscan_test_raw_no_data_range', $
    'srscan_test_keogram_load', $
    'srscan_test_grid_load' $
  ]
end
