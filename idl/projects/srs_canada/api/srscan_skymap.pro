;+
;FUNCTION:
;  srscan_skymap
;
;PURPOSE:
;  Locate, download, and restore the best skymap for a site at a
;  given time: the skymap with the latest validity start time at or before
;  the requested time. If the requested time predates all available
;  skymaps, the earliest one is used with a warning.
;
;  This routine is instrument-agnostic: the skymap dataset is passed in,
;  so every srs_canada imager network reuses it unmodified (e.g.
;  'TREX_RGB_SKYMAP_IDLSAV', and in the future 'TREX_NIR_SKYMAP_IDLSAV',
;  'SMILE_ASI_SKYMAP_IDLSAV', ...).
;
;INPUT:
;  dataset_name: skymap dataset, e.g. 'TREX_RGB_SKYMAP_IDLSAV' (string)
;  site:         4-letter site code, e.g. 'gill' (string)
;  time:         requested time (double unix time or string)
;
;KEYWORDS:
;  no_download: use only the local cache
;  verbose:     dprint verbosity
;  filename:    (out) local path of the restored skymap file
;
;OUTPUT:
;  the restored skymap structure, or -1 if none could be obtained
;-
function srscan_skymap, dataset_name, site, time, $
  no_download = no_download, verbose = verbose, filename = filename

  compile_opt idl2

  srscan_init
  cfg = srscan_api_config()
  filename = ''
  t = (size(time, /type) eq 7) ? time_double(time) : double(time)
  local_root = !srs_canada.local_data_dir + dataset_name + path_sep()

  ; candidate list: [path, validity-start date] pairs; the validity date is
  ; YYYYMMDD from a path of the form
  ; .../<site>/<site>_YYYYMMDD[_...]/<...>_skymap_<site>_...sav
  cand_paths = ['']
  cand_dates = [0l]

  if ~keyword_set(no_download) then begin
    ; query the full catalog (2000 -> now): sites whose earliest archived
    ; skymap postdates the requested time still need a candidate list for
    ; the earliest-available fallback below
    urls_result = srscan_get_urls(dataset_name, $
      '2000-01-01T00:00:00', time_string(systime(1, /seconds) > t, $
      tformat='YYYY-MM-DDThh:mm:ss'), site_uid = site, verbose = verbose)
    if isa(urls_result) && urls_result.count gt 0 then begin
      for i = 0, n_elements(urls_result.urls) - 1 do begin
        url = urls_result.urls[i]
        relpath = strmid(url, strlen(urls_result.dataset.data_tree_url) + 1)
        toks = strsplit(relpath, '/', /extract)
        if n_elements(toks) lt 3 then continue
        dtoks = strsplit(toks[1], '_', /extract)
        if n_elements(dtoks) lt 2 then continue
        cand_paths = [cand_paths, url]
        cand_dates = [cand_dates, long(dtoks[1])]
      endfor
    endif
  endif else begin
    found = file_search(local_root + site + path_sep() + site + '_*' + path_sep() + $
      '*skymap*' + site + '*.sav', count = nfound)
    for i = 0, nfound - 1 do begin
      dirname = file_basename(file_dirname(found[i]))
      dtoks = strsplit(dirname, '_', /extract)
      if n_elements(dtoks) lt 2 then continue
      cand_paths = [cand_paths, found[i]]
      cand_dates = [cand_dates, long(dtoks[1])]
    endfor
  endelse

  if n_elements(cand_paths) le 1 then begin
    dprint, dlevel=1, verbose=verbose, 'srscan_skymap: no skymap found for site ' + site
    return, -1
  endif
  cand_paths = cand_paths[1:*]
  cand_dates = cand_dates[1:*]

  ; pick latest validity start <= requested time; else earliest available
  tdate = long(time_string(t, tformat='YYYYMMDD'))
  w = where(cand_dates le tdate, nw)
  if nw gt 0 then begin
    !null = max(cand_dates[w], imax)
    pick = w[imax]
  endif else begin
    !null = min(cand_dates, imin)
    pick = imin
    dprint, dlevel=1, verbose=verbose, 'srscan_skymap: requested time ' + $
      time_string(t) + ' predates all skymaps for ' + site + '; using earliest (' + $
      strtrim(cand_dates[imin], 2) + ')'
  endelse

  if ~keyword_set(no_download) then begin
    ; map the chosen URL into the cache and download if needed
    url = cand_paths[pick]
    relpath = strmid(url, strlen(urls_result.dataset.data_tree_url) + 1)
    local_file = local_root + strjoin(strsplit(relpath, '/', /extract), path_sep())
    if ~file_test(local_file, /regular) then begin
      !null = spd_download(remote_file = url, local_file = local_file, $
        user_agent = cfg.user_agent, _extra = srscan_proxy(verbose = verbose))
      if ~file_test(local_file, /regular) then begin
        dprint, dlevel=0, verbose=verbose, 'srscan_skymap: download failed: ' + url
        return, -1
      endif
    endif
    filename = local_file
  endif else filename = cand_paths[pick]

  dprint, dlevel=3, verbose=verbose, 'srscan_skymap: using ' + filename
  restore, filename
  return, skymap
end
