;+
;PROCEDURE:
;  srscan_trex_rgb_load_grid
;
;PURPOSE:
;  Load TREx RGB pre-rendered mosaic grids (MOSv001) from the data
;  archive (data.phys.ucalgary.ca) into a tplot variable:
;    srscan_trexrgb_grid: {x[n], y[n,3,1024,512] float, v1[3], v2[1024], v3[512]}
;
;  The grids are the OFFICIAL archive mosaic product: all available
;  cameras projected at 110 km onto a global geographic grid of
;  1024 x 512 (lon x lat) cells, 0.3515625 deg/cell, fill value -999 where
;  no camera maps. One 1-min HDF5 file holds 20 frames (3-s cadence).
;  The archive stores the lat axis north-first; the loader applies the
;  standard orient transform so index j increases NORTHWARD in the tplot
;  variable (lat = -90 + (j+0.5)*cell), consistent with everything else.
;  Grids are produced only for SELECTED intervals (e.g. 2023-03-23/24);
;  an empty result for other dates is expected, and the loader says so.
;
;  MEMORY NOTE: one minute is ~120 MB as float; load short windows or use
;  time= for a single frame.
;
;  Grid geometry (lon/lat cell edges, fill value) is carried in dlimits.
;
;  Internal worker for srscan_load_trex_rgb.
;
;KEYWORDS:
;  trange:       time range (defaults to timerange()); whole 1-min files
;                covering the range are fetched and the output is clipped
;                to trange unless /no_time_clip is set
;  no_time_clip: store every frame of every fetched file instead of
;                clipping the output to trange (output then aligns to
;                1-min file boundaries)
;  time:         load only the single frame nearest this time (+-1.5 s);
;                output y is [3,1024,512]
;  suffix:       appended to the tplot variable name
;  downloadonly: download files but do not load into tplot
;  no_download:  do not contact server; use only the local cache
;  verbose:      dprint verbosity
;  files, relpathnames_all: (in/out) append contract (see load_raw header)
;  tplotnames:   (out) accumulates created tplot variable names
;-
pro srscan_trex_rgb_load_grid, trange = trange, time = time, $
  no_time_clip = no_time_clip, suffix = suffix, $
  downloadonly = downloadonly, no_download = no_download, $
  verbose = verbose, files = files, relpathnames_all = relpathnames_all, $
  tplotnames = tplotnames

  compile_opt idl2

  srscan_init
  cfg = srscan_api_config()
  if ~keyword_set(suffix) then suffix = ''
  dataset = cfg.dataset_rgb_grid
  local_root = !srs_canada.local_data_dir + dataset + path_sep()
  vname = 'srscan_trexrgb_grid' + suffix

  ; ---- request window: 1-min granules; range requests snap outward to
  ; whole granules so only the files actually covering trange are fetched
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

  ; ---- resolve files: server first, cache glob as offline fallback
  ; (no site dimension: the grid merges all cameras)
  flist = ''
  nf_files = 0
  if ~keyword_set(no_download) then begin
    d = srscan_download(dataset, iso0, iso1, verbose = verbose)
    if d.count gt 0 then begin
      flist = d.files
      nf_files = d.count
    endif
  endif
  if nf_files eq 0 then begin
    for t = floor(win0 / 3600d) * 3600d, win1, 3600d do begin
      ymd = time_string(t, tformat='YYYY') + path_sep() + $
        time_string(t, tformat='MM') + path_sep() + time_string(t, tformat='DD')
      pat = local_root + ymd + path_sep() + 'ut' + time_string(t, tformat='hh') + $
        path_sep() + '*MOSv001_grid_trex-rgb.h5'
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
      ; request would read ~60x the data needed (~7.5 GB for one frame)
      flist = srscan_files_in_window(flist, win0, win1, count = nf_files)
    endif
  endif

  if nf_files eq 0 then begin
    dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_grid: no MOSv001 grid ' + $
      'files in ' + iso0 + ' .. ' + iso1 + ' -- note grids exist only for ' + $
      'selected intervals (see data.phys.ucalgary.ca)'
    return
  endif

  ; ---- accumulate files / relpathnames_all (append contract)
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

  if keyword_set(downloadonly) then return

  ; ---- read the grid files ([nf,3,1024,512] float + timestamps per file)
  g_list = list()
  t_list = list()
  count = 0l
  for i = 0l, nf_files - 1 do begin
    catch, gerr
    if gerr ne 0 then begin
      catch, /cancel
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_grid: failed to read ' + $
        flist[i] + ', skipping'
      if isa(fid) && fid gt 0 then h5f_close, fid
      fid = 0
      continue
    endif
    fid = h5f_open(flist[i])
    did = h5d_open(fid, '/data/grid')
    g = h5d_read(did)
    h5d_close, did
    did = h5d_open(fid, '/data/timestamp')
    ts = h5d_read(did)
    h5d_close, did
    h5f_close, fid
    fid = 0
    catch, /cancel

    sz = size(g, /dimensions)
    if n_elements(sz) eq 3 then begin
      g = reform(g, 1, sz[0], sz[1], sz[2])
      sz = size(g, /dimensions)
    endif
    if n_elements(sz) ne 4 || sz[1] ne 3 then continue
    nf = sz[0] < n_elements(ts)
    if nf le 0 then begin
      ; guards the g[0:nf-1,...] below: with nf=0 the subscript 0:-1
      ; would select the ENTIRE cube while count stays unincremented
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_grid: no timestamps ' + $
        'in ' + flist[i] + ', skipping'
      continue
    endif

    tt = dblarr(nf)
    for k = 0l, nf - 1 do begin
      s = ts[k]
      pos = strpos(s, ' UTC')
      if pos ge 0 then s = strmid(s, 0, pos)
      tt[k] = time_double(s)
    endfor
    g_list.add, g[0:nf-1, *, *, *]
    t_list.add, tt
    count += nf
  endfor

  if count eq 0 then begin
    dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_grid: no grid frames read'
    return
  endif

  nchunks = n_elements(g_list)
  if nchunks eq 1 then begin
    grids = g_list[0]
    times = t_list[0]
  endif else begin
    d4 = size(g_list[0], /dimensions)
    grids = fltarr(count, d4[1], d4[2], d4[3], /nozero)
    times = dblarr(count)
    ofs = 0l
    for i = 0l, nchunks - 1 do begin
      chunk = g_list[i]
      nf = (size(chunk, /dimensions))[0]
      grids[ofs:ofs+nf-1, *, *, *] = chunk
      times[ofs:ofs+nf-1] = t_list[i]
      ofs += nf
    endfor
  endelse
  srt = sort(times)
  if ~array_equal(srt, lindgen(count)) then begin
    times = times[srt]
    grids = grids[srt, *, *, *]
  endif

  ; the archive stores the lat dimension north-first (the same y-southward
  ; convention as the raw frames; verified empirically via the data
  ; footprint); the one orient transform flips it so j increases northward
  grids = srscan_trex_rgb_orient(temporary(grids))

  if keyword_set(time) then begin
    mindt = min(abs(times - t0), jj)
    if mindt gt 1.5 then begin
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_grid: no grid frame ' + $
        'within 1.5 s of ' + time_string(t0)
      return
    endif
    data = {x: [times[jj]], y: reform(grids[jj, *, *, *]), $
      v1: indgen(3), v2: indgen(1024), v3: indgen(512)}
  endif else begin
    ; clip to the requested trange (standard SPEDAS loader behavior);
    ; whole-file output is available with /no_time_clip
    if ~keyword_set(no_time_clip) then begin
      win = where(times ge tr[0] and times le tr[1], nin)
      if nin eq 0 then begin
        dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_grid: no grid ' + $
          'frames within requested trange'
        return
      endif
      if nin lt n_elements(times) then begin
        times = times[win]
        grids = grids[win, *, *, *]
      endif
    endif
    data = {x: times, y: temporary(grids), $
      v1: indgen(3), v2: indgen(1024), v3: indgen(512)}
  endelse

  ; dataset metadata, mirroring ISTP CDF global attributes (same pattern
  ; as the raw and keogram loaders)
  gatt = { $
    project: 'TREx', $
    source_name: 'TREX>Transition Region Explorer', $
    discipline: ['Space Physics>Magnetospheric Science', 'Space Physics>Ionospheric Science'], $
    data_type: 'GRID>All Sky Imager, Data-provider-verified pre-rendered mosaic grids (MOSv001)', $
    descriptor: 'MOSV001', $
    data_version: '1', $
    pi_name: 'E. Spanswick & E. Donovan', $
    pi_affiliation: 'University of Calgary', $
    text: 'Transition Region Explorer RGB colour all-sky imager network', $
    instrument_type: 'Ground-Based Imagers, Photometrics', $
    mission_group: 'Ground-Based Observatory', $
    logical_source: 'trex_rgb_grid', $
    logical_file_id: file_basename(flist[0]), $
    logical_source_description: 'Ground-based colour All Sky Imager data-provider-verified pre-rendered mosaic grids, TREx network', $
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

  ; grid geometry in dlimits: cell (i,j) spans
  ;   lon: -180 + i*cell .. -180 + (i+1)*cell
  ;   lat:  -90 + j*cell ..  -90 + (j+1)*cell   (j increases northward)
  dl = { $
    cdf: {filename: flist[0], gatt: gatt, vname: vname}, $
    spec: 0b, log: 0b, $
    data_att: {coord_sys: 'geographic', units: 'quicklook_dn', $
    cell_deg: 0.3515625d, lon0: -180d, lat0: -90d, fill: -999.}, $
    ysubtitle: '[quicklook DN]' $
  }
  store_data, vname, data = data, dlimits = dl
  if undefined(tplotnames) then tplotnames = vname else tplotnames = [tplotnames, vname]
  dprint, dlevel=2, verbose=verbose, 'srscan_trex_rgb_load_grid: created ' + vname + $
    ' (' + strtrim(keyword_set(time) ? 1 : count, 2) + ' frame(s))'
end
