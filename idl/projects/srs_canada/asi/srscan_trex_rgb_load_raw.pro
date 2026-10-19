;+
;PROCEDURE:
;  srscan_trex_rgb_load_raw
;
;PURPOSE:
;  Load TREx RGB raw (stream0 nominal cadence) truecolor images from the
;  data archive (data.phys.ucalgary.ca) into tplot variables:
;    srscan_trexrgb_<site>: {x: double[n], y: byte[n,3,553,480],
;                            v1: [3], v2: [553], v3: [480]}
;  Frames are ORIENTed (north-up/east-right): reform(y[i,*,*,*]) is a
;  [3,553,480] truecolor frame ready for tv,/true.
;
;  This is an internal worker for srscan_load_trex_rgb; users should call
;  srscan_load_trex_rgb.
;
;  MEMORY NOTE: one hour of one site is ~1200 frames x 0.8 MB = ~0.95 GB.
;  Load short windows (minutes) or use time= for single frames.
;
;KEYWORDS:
;  sites:        string array of 4-letter site codes (lowercase)
;  trange:       time range (defaults to timerange()); whole 1-min files
;                covering the range are fetched and the output is clipped
;                to trange unless /no_time_clip is set
;  no_time_clip: store every frame of every fetched file instead of
;                clipping the output to trange (output then aligns to
;                1-min file boundaries)
;  time:         load only the single frame nearest this time (+-1.5 s);
;                output y is [3,553,480], the single-record convention
;  suffix:       appended to tplot variable names
;  downloadonly: download files but do not load into tplot
;  no_download:  do not contact server; use only the local cache
;  verbose:      dprint verbosity
;  files:        (in/out) APPENDS local file paths across sites. The public
;                loader collects these in a local and assigns its own files
;                keyword once per call (the GUI reuses one variable per
;                load, so appending at the public level would grow it)
;  relpathnames_all: (in/out) accumulates cache-relative paths, same contract
;  tplotnames:   (out) accumulates created tplot variable names
;-

; dlimits for a TREx RGB raw image variable (CDF-style shape so downstream
; SPEDAS/GUI metadata consumers find what they expect)
function srscan_trex_rgb_load_raw_dlimits, vname, site, source_file
  compile_opt idl2, hidden

  gatt = { $
    project: 'TREx', $
    source_name: 'TREX>Transition Region Explorer', $
    discipline: ['Space Physics>Magnetospheric Science', 'Space Physics>Ionospheric Science'], $
    data_type: 'RGB>All Sky Imager, Full resolution colour images', $
    descriptor: strupcase(site), $
    data_version: '1', $
    pi_name: 'E. Spanswick & E. Donovan', $
    pi_affiliation: 'University of Calgary', $
    text: 'Transition Region Explorer RGB colour all-sky imager network', $
    instrument_type: 'Ground-Based Imagers, Photometrics', $
    mission_group: 'Ground-Based Observatory', $
    logical_source: 'trex_rgb_' + site, $
    logical_file_id: file_basename(source_file), $
    logical_source_description: 'Ground-based colour All Sky Imager, 3sec nominal cadence, TREx network', $
    time_resolution: '3s', $
    rules_of_use: 'Open Data for Scientific Use', $
    doi: 'https://doi.org/10.11575/4P8E-1K65', $
    generated_by: 'SPEDAS srscan loader (data.phys.ucalgary.ca)', $
    generation_date: '', $
    link_text: ['https://data.phys.ucalgary.ca'], $
    link_title: ['data.phys.ucalgary.ca'], $
    http_link: ['https://data.phys.ucalgary.ca'], $
    file_naming_convention: 'source_datatype_descriptor' $
    }
  vatt = { $
    catdesc: 'Colour images of 553x480 pixels (RGB channels first)', $
    depend_0: vname + '_epoch', $
    display_type: 'image', $
    fieldnam: vname, $
    fillval: 255b, $
    format: 'I3', $
    lablaxis: 'Width', $
    units: 'counts', $
    validmin: 0b, $
    validmax: 255b, $
    var_type: 'data' $
    }
  return, { $
    cdf: {filename: source_file, gatt: gatt, vname: vname, vatt: vatt}, $
    spec: 0b, $
    log: 0b, $
    data_att: {coord_sys: '', units: 'counts'}, $
    ysubtitle: '[counts, 8-bit]' $
    }
end

pro srscan_trex_rgb_load_raw, sites = sites, trange = trange, time = time, $
  no_time_clip = no_time_clip, suffix = suffix, $
  downloadonly = downloadonly, no_download = no_download, $
  verbose = verbose, files = files, relpathnames_all = relpathnames_all, $
  tplotnames = tplotnames

  compile_opt idl2

  srscan_init
  cfg = srscan_api_config()
  if ~keyword_set(suffix) then suffix = ''
  dataset = cfg.dataset_rgb_raw
  local_root = !srs_canada.local_data_dir + dataset + path_sep()

  ; ---- determine request window (whole 1-min file granules)
  ; the API matches files whose START time lies in [start, end], so the
  ; window must reach back to the start of the 1-min file granule; range
  ; requests snap outward to whole granules so only the files actually
  ; covering trange are fetched
  if keyword_set(time) then begin
    t0 = time_double(time)
    win0 = floor((t0 - 2d) / 60d) * 60d
    win1 = t0 + 2d
  endif else begin
    tr = timerange(trange)
    granule = 60d
    win0 = floor(tr[0] / granule) * granule
    win1 = (ceil(tr[1] / granule) * granule - granule) > win0
    win1 = win1 + granule - 1d
  endelse
  iso0 = time_string(win0, tformat='YYYY-MM-DDThh:mm:ss')
  iso1 = time_string(win1, tformat='YYYY-MM-DDThh:mm:ss')

  for isite = 0, n_elements(sites) - 1 do begin
    site = strlowcase(sites[isite])
    vname = 'srscan_trexrgb_' + site + suffix

    ; ---- resolve files: server first, cache glob as offline fallback
    flist = ''
    nf_files = 0
    if ~keyword_set(no_download) then begin
      d = srscan_download(dataset, iso0, iso1, site_uid = site, $
        verbose = verbose)
      if d.count gt 0 then begin
        flist = d.files
        nf_files = d.count
      endif
    endif
    if nf_files eq 0 then begin
      ; offline / fallback: glob the local cache tree hour by hour
      for t = floor(win0 / 3600d) * 3600d, win1, 3600d do begin
        ymd = time_string(t, tformat='YYYY') + path_sep() + $
          time_string(t, tformat='MM') + path_sep() + time_string(t, tformat='DD')
        pat = local_root + ymd + path_sep() + site + '_*' + path_sep() + $
          'ut' + time_string(t, tformat='hh') + path_sep() + '*_full.h5'
        found = file_search(pat, count = nfound)
        if nfound gt 0 then begin
          if nf_files eq 0 then flist = found else flist = [flist, found]
          nf_files += nfound
        endif
      endfor
      if nf_files gt 0 then begin
        flist = flist[uniq(flist, sort(flist))]
        ; keep only files inside the request window -- the hour glob
        ; catches every minute file of the hour, which for a time=
        ; request would read ~60x the data needed (~1 GB for one frame)
        flist = srscan_files_in_window(flist, win0, win1, count = nf_files)
      endif
    endif

    if nf_files eq 0 then begin
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_raw: no raw files ' + $
        'for site ' + site + ' in ' + iso0 + ' .. ' + iso1
      continue
    endif

    ; ---- accumulate files / relpathnames_all (append contract, see header)
    if undefined(files) then files = flist else files = [files, flist]
    rel = flist
    for i = 0, n_elements(rel) - 1 do begin
      r = rel[i]
      pos = strpos(r, dataset)
      if pos ge 0 then r = strmid(r, pos)
      rel[i] = strjoin(strsplit(r, '\', /extract), '/')
    endfor
    if undefined(relpathnames_all) then relpathnames_all = rel $
    else relpathnames_all = [relpathnames_all, rel]

    if keyword_set(downloadonly) then continue

    ; ---- read frames (readfile returns them time-sorted)
    srscan_trex_rgb_readfile, flist, images, times, count = nframes, verbose = verbose
    if nframes eq 0 then begin
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_raw: no frames read for ' + site
      continue
    endif

    ; orient the whole cube at once (flips the y dimension)
    images = srscan_trex_rgb_orient(temporary(images))

    if keyword_set(time) then begin
      ; single-frame mode: nearest frame within +-1.5 s ([3,553,480] output)
      mindt = min(abs(times - t0), jj)
      if mindt gt 1.5 then begin
        dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_raw: no frame within ' + $
          '1.5 s of ' + time_string(t0) + ' for ' + site
        continue
      endif
      data = {x: [times[jj]], y: reform(images[jj, *, *, *]), $
        v1: indgen(3), v2: indgen(553), v3: indgen(480)}
    endif else begin
      ; drop duplicate timestamps if any
      keep = uniq(times)
      if n_elements(keep) lt nframes then begin
        dprint, dlevel=2, verbose=verbose, 'srscan_trex_rgb_load_raw: dropped ' + $
          strtrim(nframes - n_elements(keep), 2) + ' duplicate-timestamp frame(s) for ' + site
        times = times[keep]
        images = images[keep, *, *, *]
      endif
      ; clip to the requested trange (standard SPEDAS loader behavior);
      ; whole-file output is available with /no_time_clip
      if ~keyword_set(no_time_clip) then begin
        win = where(times ge tr[0] and times le tr[1], nin)
        if nin eq 0 then begin
          dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_raw: no frames ' + $
            'within requested trange for ' + site
          continue
        endif
        if nin lt n_elements(times) then begin
          times = times[win]
          images = images[win, *, *, *]
        endif
      endif
      data = {x: times, y: temporary(images), $
        v1: indgen(3), v2: indgen(553), v3: indgen(480)}
    endelse

    dl = srscan_trex_rgb_load_raw_dlimits(vname, site, flist[0])
    store_data, vname, data = data, dlimits = dl
    if undefined(tplotnames) then tplotnames = vname else tplotnames = [tplotnames, vname]
    dprint, dlevel=2, verbose=verbose, 'srscan_trex_rgb_load_raw: created ' + vname
  endfor
end
