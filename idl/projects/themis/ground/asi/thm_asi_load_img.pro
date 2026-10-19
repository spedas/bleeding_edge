;+
;PROCEDURE:
;  thm_asi_load_img
;
;PURPOSE:
;  Load THEMIS ASI image data (full-resolution 'asf' or thumbnail 'ast')
;  from the data archive at data.phys.ucalgary.ca into tplot variables that are
;  drop-in compatible with the legacy Berkeley CDF loader output:
;    thg_asf_<site>: {x: double[n], y: uint[n,256,256], v1:[256], v2:[256]}
;    thg_ast_<site>: {x: double[n], y: uint[n,32,32],  v1:[32],  v2:[32]}
;  with matching dlimits (cdf/gatt/vatt shape, spec=0, units 'counts').
;
;  This is an internal worker for thm_load_asi; users should keep calling
;  thm_load_asi.
;
;KEYWORDS:
;  sites:        string array of 4-letter site codes (lowercase)
;  datatype:     'asf' or 'ast' (scalar)
;  trange:       time range (defaults to timerange()); whole file granules
;                are fetched (1-min files for asf/rgf, hourly files for
;                ast) and the output is clipped to trange unless
;                /no_time_clip is set
;  no_time_clip: store every frame of every fetched file instead of
;                clipping the output to trange (output then aligns to
;                file-granule boundaries)
;  time:         load only the single frame nearest this time (+-1.5 s);
;                output y is 2-D, matching the legacy single-record read
;  suffix:       appended to tplot variable names
;  downloadonly: download files but do not load into tplot
;  no_download:  do not contact server; use only the local cache
;  verbose:      dprint verbosity
;  files:        (in/out) accumulates local file paths across the sites in
;                this call. NOTE the public loaders (thm_load_asi /
;                thm_load_rego) collect these in a local and ASSIGN their own
;                files keyword once, so that repeated calls replace rather
;                than grow the caller's variable -- the legacy thm_load_xxx
;                contract, which the SPEDAS GUI relies on (it reuses one
;                variable per load).
;  relpathnames_all: (in/out) accumulates cache-relative paths, same contract
;  tplotnames:   (out) accumulates created tplot variable names
;-

; build legacy-compatible dlimits for an asf/ast/rgf variable
function thm_asi_load_img_dlimits, vname, datatype, site, source_file
  compile_opt idl2, hidden

  if datatype eq 'rgf' then begin
    ; replica of the legacy clg_l1_rgf CDF global attributes
    gatt = { $
      project: 'REGO', $
      source_name: 'CLG_L1>Redline Emission Geospace Observatory', $
      discipline: ['Space Physics>Magnetospheric Science', 'Space Physics>Ionospheric Science'], $
      data_type: 'ASF>All Sky Imager, Full resolution images, High resolution', $
      descriptor: strupcase(site), $
      data_version: '1', $
      pi_name: 'E. Donovan', $
      pi_affiliation: 'Univ of Calgary', $
      text: 'UCalgary Ground Based Instrument part of the CSA GO Canada Program', $
      instrument_type: 'Ground-Based VLF/ELF/ULF, Photometrics', $
      mission_group: 'Groundbased Obaservatory', $
      logical_source: 'rego_l1_asf_' + site, $
      logical_file_id: file_basename(source_file), $
      logical_source_description: 'Ground-based All Sky Imager, 3sec Level-1, REGO network', $
      time_resolution: '3s', $
      rules_of_use: 'Open Data for Scientific Use', $
      generated_by: 'SPEDAS thm_asi loader (data.phys.ucalgary.ca)', $
      generation_date: '', $
      acknowledgement: 'CSA Contract', $
      mods: '', $
      adid_ref: '????', $
      link_text: ['http://sprg.ssl.berkeley.edu/themis', 'https://data.phys.ucalgary.ca'], $
      link_title: ['THEMIS GBO portal', 'data.phys.ucalgary.ca'], $
      http_link: ['http://sprg.ssl.berkeley.edu/themis', 'https://data.phys.ucalgary.ca'], $
      file_naming_convention: 'source_datatype_descriptor' $
      }
    vatt = { $
      catdesc: 'Images of 512x512 pixels', $
      depend_0: vname + '_epoch', $
      depend_1: vname + '_column', $
      depend_2: vname + '_row', $
      display_type: 'image', $
      fieldnam: vname, $
      fillval: 65535us, $
      format: 'I5', $
      lablaxis: 'Width', $
      units: 'counts', $
      validmin: 0us, $
      validmax: 65535us, $
      var_type: 'data', $
      depend_time: vname + '_time', $
      depend_epoch0: vname + '_epoch0' $
      }
    return, { $
      cdf: {filename: source_file, gatt: gatt, vname: vname, vatt: vatt}, $
      spec: 0b, $
      log: 0b, $
      data_att: {coord_sys: '', units: 'counts'}, $
      ysubtitle: '[counts]' $
      }
  endif

  if datatype eq 'asf' then begin
    data_type_gatt = 'ASF>All Sky Imager, Full resolution images, High resolution'
    catdesc = 'Images of 256x256 pixels'
  endif else begin
    data_type_gatt = 'AST>All Sky Imager, Thumbnail images, High resolution'
    catdesc = 'Thumbnail images of 32x32 pixels'
  endelse

  gatt = { $
    project: 'THEMIS', $
    source_name: 'THG_L1>THEMIS Ground Based Observatory', $
    discipline: ['Space Physics>Magnetospheric Science', 'Space Physics>Ionospheric Science'], $
    data_type: data_type_gatt, $
    descriptor: strupcase(site), $
    data_version: '1', $
    pi_name: 'V. Angelopoulos, S. Mende & E. Donovan', $
    pi_affiliation: 'UCB & Univ of Calgary respectively, NASA NAS5-02099', $
    text: 'THEMIS Ground Based Observatory part of the THEMIS GBO effort', $
    instrument_type: 'Ground-Based VLF/ELF/ULF, Photometrics', $
    mission_group: 'THEMIS', $
    logical_source: 'thg_l1_' + datatype + '_' + site, $
    logical_file_id: file_basename(source_file), $
    logical_source_description: 'Ground-based All Sky Imager, Level-1, THEMIS GBO network', $
    time_resolution: '3s', $
    rules_of_use: 'Open Data for Scientific Use', $
    generated_by: 'SPEDAS thm_asi loader (data.phys.ucalgary.ca)', $
    generation_date: '', $
    acknowledgement: 'NASA Contract NAS5-02099', $
    mods: '', $
    adid_ref: 'NSSD0110', $
    link_text: ['http://sprg.ssl.berkeley.edu/themis', 'https://data.phys.ucalgary.ca'], $
    link_title: ['THEMIS GBO portal', 'data.phys.ucalgary.ca'], $
    http_link: ['http://sprg.ssl.berkeley.edu/themis', 'https://data.phys.ucalgary.ca'], $
    file_naming_convention: 'source_datatype_descriptor' $
    }

  vatt = { $
    catdesc: catdesc, $
    depend_0: vname + '_epoch', $
    depend_1: vname + '_column', $
    depend_2: vname + '_row', $
    display_type: 'image', $
    fieldnam: vname, $
    fillval: 65535us, $
    format: 'I5', $
    lablaxis: 'Width', $
    units: 'counts', $
    validmin: 0us, $
    validmax: 65535us, $
    var_type: 'data', $
    depend_time: vname + '_time', $
    depend_epoch0: vname + '_epoch0' $
    }

  return, { $
    cdf: {filename: source_file, gatt: gatt, vname: vname, vatt: vatt}, $
    spec: 0b, $
    log: 0b, $
    data_att: {coord_sys: '', units: 'counts'}, $
    ysubtitle: '[counts]' $
    }
end

pro thm_asi_load_img, sites = sites, datatype = datatype, $
  trange = trange, time = time, no_time_clip = no_time_clip, suffix = suffix, $
  downloadonly = downloadonly, no_download = no_download, $
  verbose = verbose, files = files, relpathnames_all = relpathnames_all, $
  tplotnames = tplotnames

  compile_opt idl2

  thm_init
  cfg = thm_asi_config()
  if ~keyword_set(suffix) then suffix = ''
  dt = strlowcase(datatype[0])
  ; datatype selects instrument + product:
  ;   asf/ast = THEMIS ASI full/thumbnail;  rgf = REGO full resolution
  case dt of
    'rgf': begin
      dataset = cfg.dataset_rego_raw
      npix = 512
      vprefix = 'clg_'
      glob_suffix = '*_6300.pgm*'
    end
    'ast': begin
      dataset = cfg.dataset_ast
      npix = 32
      vprefix = 'thg_'
      glob_suffix = '*_vec1024.pgm*'
    end
    else: begin
      dataset = cfg.dataset_asf
      npix = 256
      vprefix = 'thg_'
      glob_suffix = '*_full.pgm*'
    end
  endcase
  local_root = !themis.local_data_dir + cfg.cache_subdir + dataset + path_sep()

  ; ---- determine request window (whole file granules)
  ; the API matches files whose START time lies in [start, end], so the
  ; window must reach back to the start of the file granule containing the
  ; requested time (1-min files for asf/rgf RAW, hourly files for
  ; ast/VEC1024); range requests snap outward to whole granules so only
  ; the files actually covering trange are fetched
  fgran = (dt eq 'ast') ? 3600d : 60d
  if keyword_set(time) then begin
    t0 = time_double(time)
    win0 = floor((t0 - 2d) / fgran) * fgran
    win1 = t0 + 2d
  endif else begin
    tr = timerange(trange)
    win0 = floor(tr[0] / fgran) * fgran
    win1 = (ceil(tr[1] / fgran) * fgran - fgran) > win0
    win1 = win1 + fgran - 1d
  endelse
  iso0 = time_string(win0, tformat='YYYY-MM-DDThh:mm:ss')
  iso1 = time_string(win1, tformat='YYYY-MM-DDThh:mm:ss')

  for isite = 0, n_elements(sites) - 1 do begin
    site = strlowcase(sites[isite])
    vname = vprefix + dt + '_' + site + suffix

    ; ---- resolve files: server first, cache glob as offline fallback
    flist = ''
    nf_files = 0
    if ~keyword_set(no_download) then begin
      d = thm_asi_download(dataset, iso0, iso1, site_uid = site, $
        verbose = verbose)
      if d.count gt 0 then begin
        flist = d.files
        nf_files = d.count
      endif
    endif
    if nf_files eq 0 then begin
      ; offline / fallback: glob the local cache tree hour by hour (or day
      ; by day); the loop start is floored to the step so a granule-aligned
      ; win0 cannot stride over an hour/day directory boundary
      step = (dt eq 'ast') ? 86400d : 3600d
      for t = floor(win0 / step) * step, win1, step do begin
        ymd = time_string(t, tformat='YYYY') + path_sep() + $
          time_string(t, tformat='MM') + path_sep() + time_string(t, tformat='DD')
        if dt eq 'ast' then begin
          pat = local_root + ymd + path_sep() + site + '_*' + path_sep() + $
            'ut*' + path_sep() + glob_suffix
        endif else begin
          pat = local_root + ymd + path_sep() + site + '_*' + path_sep() + $
            'ut' + time_string(t, tformat='hh') + path_sep() + glob_suffix
        endelse
        found = file_search(pat, count = nfound)
        if nfound gt 0 then begin
          if nf_files eq 0 then flist = found else flist = [flist, found]
          nf_files += nfound
        endif
      endfor
      if nf_files gt 0 then begin
        flist = flist[uniq(flist, sort(flist))]
        flist = thm_asi_dedup_gz(flist)   ; drop .pgm/.pgm.gz twins
        ; keep only files inside the request window -- the hour glob (or
        ; the ast day glob) catches granules outside a time= request's
        ; window, e.g. every minute file of the hour for a single frame
        flist = thm_asi_files_in_window(flist, win0, win1, count = nf_files)
      endif
    endif

    if nf_files eq 0 then begin
      dprint, dlevel=1, verbose=verbose, 'thm_asi_load_img: no ' + dt + $
        ' files for site ' + site + ' in ' + iso0 + ' .. ' + iso1
      continue
    endif

    ; ---- accumulate files / relpathnames_all
    if undefined(files) then files = flist else files = [files, flist]
    rel = flist
    for i = 0, n_elements(rel) - 1 do begin
      r = rel[i]
      pos = strpos(r, cfg.cache_subdir)
      if pos ge 0 then r = strmid(r, pos)
      rel[i] = strjoin(strsplit(r, '\', /extract), '/')
    endfor
    if undefined(relpathnames_all) then relpathnames_all = rel $
    else relpathnames_all = [relpathnames_all, rel]

    if keyword_set(downloadonly) then continue

    ; ---- read frames
    thm_asi_readfile, flist, images, meta, count = nframes, verbose = verbose
    if nframes eq 0 then begin
      dprint, dlevel=1, verbose=verbose, 'thm_asi_load_img: no frames read for ' + site
      continue
    endif
    times = thm_asi_time(meta)
    order = sort(times)
    times = times[order]

    ; drop duplicate timestamps (some summary products repeat frames)
    keep = uniq(times)
    if n_elements(keep) lt nframes then dprint, dlevel=2, verbose=verbose, $
      'thm_asi_load_img: dropped ' + strtrim(nframes - n_elements(keep), 2) + $
      ' duplicate-timestamp frame(s) for ' + site

    ; frame extraction: asf frames are 2-D images (need the pinned ORIENT
    ; transform); ast/vec1024 frames are 1-D bin vectors whose order already
    ; matches the legacy CDF's flattened 32x32 layout (verified empirically)
    frame_is_2d = (size(images, /n_dimensions) eq 3)

    if keyword_set(time) then begin
      ; single-frame mode: nearest frame within +-1.5 s (2-D output, like
      ; the legacy single-record CDF read)
      mindt = min(abs(times - t0), jj)
      if mindt gt 1.5 then begin
        dprint, dlevel=1, verbose=verbose, 'thm_asi_load_img: no frame within 1.5 s of ' + $
          time_string(t0) + ' for ' + site
        continue
      endif
      if frame_is_2d then frame = thm_asi_orient(uint(images[*, *, order[jj]])) $
      else frame = reform(uint(images[*, order[jj]]), npix, npix)
      data = {x: [times[jj]], y: frame, v1: uindgen(npix), v2: uindgen(npix)}
      src_file = flist[0]
    endif else begin
      ; clip to the requested trange (standard SPEDAS loader behavior);
      ; whole-file output is available with /no_time_clip
      if ~keyword_set(no_time_clip) then begin
        win = where(times[keep] ge tr[0] and times[keep] le tr[1], nin)
        if nin eq 0 then begin
          dprint, dlevel=1, verbose=verbose, 'thm_asi_load_img: no ' + dt + $
            ' frames within requested trange for ' + site
          continue
        endif
        keep = keep[win]
      endif
      nkeep = n_elements(keep)
      y = make_array(nkeep, npix, npix, /uint, /nozero)
      x = dblarr(nkeep)
      for k = 0, nkeep - 1 do begin
        x[k] = times[keep[k]]
        if frame_is_2d then y[k, *, *] = thm_asi_orient(uint(images[*, *, order[keep[k]]])) $
        else y[k, *, *] = reform(uint(images[*, order[keep[k]]]), npix, npix)
      endfor
      data = {x: x, y: y, v1: uindgen(npix), v2: uindgen(npix)}
      src_file = flist[0]
    endelse

    dl = thm_asi_load_img_dlimits(vname, dt, site, src_file)
    store_data, vname, data = data, dlimits = dl
    if undefined(tplotnames) then tplotnames = vname else tplotnames = [tplotnames, vname]
    dprint, dlevel=2, verbose=verbose, 'thm_asi_load_img: created ' + vname
  endfor
end
