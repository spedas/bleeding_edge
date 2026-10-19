;+
;FUNCTION:
;  srscan_download
;
;PURPOSE:
;  Download data files from the data archive (data.phys.ucalgary.ca) for
;  a given dataset, timeframe, and optional site. File URLs are resolved
;  with srscan_get_urls (the api.phys.ucalgary.ca data distribution
;  endpoint) and fetched with the standard SPEDAS spd_download, so
;  proxy/network behavior matches the rest of SPEDAS.
;
;  Files are cached under
;    !srs_canada.local_data_dir + '<DATASET_NAME>/<archive tree>'
;  mirroring the archive layout below the dataset's data_tree_url.
;  Files already present in the cache are not re-downloaded (the archive
;  files are immutable).
;
;INPUT:
;  dataset_name: dataset to download, e.g. 'TREX_RGB_RAW_NOMINAL' (string)
;  start_ts:     start timestamp, ISO format YYYY-MM-DDTHH:MM:SS (string)
;  end_ts:       end timestamp (inclusive), same format (string)
;
;KEYWORDS:
;  site_uid:    4-letter site UID filter, e.g. 'gill' (string)
;  device_uid:  device UID filter, e.g. 'rgb-04' (string)
;  no_download: if set, do not contact the API or server at all; returns
;               count=0 (callers fall back to globbing the local cache)
;  verbose:     dprint verbosity passthrough
;
;OUTPUT:
;  Structure:
;    { files:     string array of local absolute paths (only files that
;                 exist locally after the call),
;      count:     number of elements in files,
;      relpaths:  archive-tree-relative paths (below data_tree_url),
;      data_tree_url: the dataset's archive root URL,
;      total_urls: number of URLs the API listed,
;      api_ok:    1b if the API responded (even with zero URLs), 0b if the
;                 API was not contacted or the request failed }
;  Returns count=0 structure if nothing was listed/downloaded.
;
;EXAMPLE:
;  d = srscan_download('TREX_RGB_RAW_NOMINAL', $
;        '2023-03-24T06:00:00','2023-03-24T06:59:59', site_uid='gill')
;-
function srscan_download, dataset_name, start_ts, end_ts, $
  site_uid = site_uid, device_uid = device_uid, $
  no_download = no_download, verbose = verbose

  compile_opt idl2

  empty_result = {files: [''], count: 0l, relpaths: [''], data_tree_url: '', total_urls: 0l, api_ok: 0b}

  srscan_init
  cfg = srscan_api_config()

  if keyword_set(no_download) then begin
    dprint, dlevel=2, verbose=verbose, 'srscan_download: no_download set, skipping server contact'
    return, empty_result
  endif

  ; resolve file URLs through the API
  urls_result = srscan_get_urls(dataset_name, start_ts, end_ts, $
    site_uid = site_uid, device_uid = device_uid, verbose = verbose)
  if ~isa(urls_result) then return, empty_result
  if (urls_result.count eq 0) then begin
    dprint, dlevel=2, verbose=verbose, 'srscan_download: no files found for ' + $
      dataset_name + ' ' + start_ts + ' to ' + end_ts
    r = empty_result
    r.api_ok = 1b
    return, r
  endif

  data_tree_url = urls_result.dataset.data_tree_url
  local_root = !srs_canada.local_data_dir + dataset_name + path_sep()

  ; spd_download picks up http_proxy on its own, but resolve here as well so
  ; the AURORAX_PROXY_* override applies to the file GETs too; !null when no
  ; proxy is configured, which makes the _extra passthrough below a no-op
  proxy_props = srscan_proxy(verbose = verbose)

  ; some archive trees list both an uncompressed file and its .gz twin;
  ; pull only one per logical file (preferring .gz)
  urls = srscan_dedup_gz(urls_result.urls)
  n_urls = n_elements(urls)
  files = strarr(n_urls)
  relpaths = strarr(n_urls)
  n_ok = 0l

  for i = 0l, n_urls - 1 do begin
    url = urls[i]

    ; archive-tree-relative path (strip data_tree_url plus its trailing '/')
    relpath = strmid(url, strlen(data_tree_url) + 1)
    local_file = local_root + strjoin(strsplit(relpath, '/', /extract), path_sep())

    ; archive files are immutable: trust the cache
    if file_test(local_file, /regular) then begin
      dprint, dlevel=4, verbose=verbose, 'srscan_download: cached: ' + local_file
    endif else begin
      dl = spd_download(remote_file = url, local_file = local_file, $
        user_agent = cfg.user_agent, progress_object = progress_object, $
        _extra = proxy_props)
      if ~file_test(local_file, /regular) then begin
        dprint, dlevel=1, verbose=verbose, 'srscan_download: failed to download ' + url
        continue
      endif
    endelse

    files[n_ok] = local_file
    relpaths[n_ok] = relpath
    n_ok += 1
  endfor

  if (n_ok eq 0) then begin
    r = empty_result
    r.api_ok = 1b
    return, r
  endif

  dprint, dlevel=2, verbose=verbose, 'srscan_download: ' + strtrim(n_ok, 2) + '/' + $
    strtrim(n_urls, 2) + ' file(s) available locally for ' + dataset_name

  return, {files: files[0:n_ok-1], count: n_ok, relpaths: relpaths[0:n_ok-1], $
    data_tree_url: data_tree_url, total_urls: long(n_urls), api_ok: 1b}
end
