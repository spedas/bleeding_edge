;+
;PROCEDURE:
;  thm_asi_load_ask
;
;PURPOSE:
;  Load THEMIS ASI or REGO keograms ('ask') from the data archive
;  (data.phys.ucalgary.ca) into tplot variables compatible with the legacy Berkeley ask
;  CDF loader output:
;    thg_ask_<site>: {x: double[n], y: uint[n,256], v: [256]}  (spec=1)
;    clg_ask_<site>: {x: double[n], y: uint[n,512], v: [512]}  (/rego)
;
;  THEMIS: hourly keogram PGMs (THEMIS_ASI_HOURLY_KEOGRAM_PGM) are
;  stitched across the requested range -- 600 columns/hour = one column
;  per 6 s vs one per 3-s frame in the legacy CDFs (visually equivalent,
;  corr 0.98-0.99 at matched times, not byte-identical). Use the default
;  Berkeley CDF path of thm_load_ask (omit /ucalgary_pgm) if exact legacy
;  values are required.
;
;  REGO (/rego): hourly keograms are 1200 columns/hour = the full 3-s
;  cadence, read from the 16-bit grayscale PNG product
;  (REGO_HOURLY_KEOGRAM_PNG), which covers the whole mission -- the PGM
;  twin only exists from ~Oct 2016 and is bit-identical where both exist.
;
;  IMPORTANT -- REGO keogram values are NOT counts. Unlike the THEMIS
;  keogram products, which are plain counts, the REGO ones are display-
;  scaled by the onsite generator: a fixed count window is mapped linearly
;  onto 0-65535 and everything outside it is clipped, so faint pixels
;  bottom out at 0 and bright aurora saturates at 65535. Structure and
;  timing are correct -- the keograms plot correctly -- but the values are
;  not photometric and must not be used as intensities. This is flagged in
;  the variable's units ('scaled_counts', in both data_att and the CDF
;  vatt), in the color-bar title set by thm_load_ask, and by a dprint at
;  load time. Use the default Berkeley CDF path of thm_load_ask (omit
;  /ucalgary_pgm) for count-accurate keograms, or load the raw images with
;  thm_load_rego to apply a scaling of your own.
;
;  The same scaling is used throughout the REGO dataset -- every site,
;  every date -- so keograms are directly comparable across stations and
;  nights and there is no per-file scale factor to track. Characterised
;  empirically against REGO_RAW, the map is
;    archived = round((counts - 280) * 65535/1030.7), clipped to 0-65535
;  which is one-to-one inside the window. It is deliberately not inverted
;  here: the clipped tails are unrecoverable either way, and the default
;  Berkeley CDF path is the supported path to counts.
;
;  Empirical alignment vs the legacy CDFs: PGM rows are stored opposite
;  to the legacy orientation (reverse the 2nd dimension) while the REGO
;  PNGs are already legacy-ordered; column j represents the frame at
;  hour_start + j*binw (zero offset).
;
;  Internal worker for thm_load_ask; users should keep calling thm_load_ask.
;
;KEYWORDS:
;  sites:        string array of 4-letter site codes (lowercase)
;  trange:       time range (defaults to timerange()); output IS clipped
;                to trange, like the legacy ask loader
;  suffix:       appended to tplot variable names
;  rego:         load REGO keograms (clg_ask_*) instead of THEMIS ASI
;  downloadonly: download files but do not load into tplot
;  no_download:  do not contact server; use only the local cache
;  verbose:      dprint verbosity
;  files:        (in/out) accumulates local file paths across the sites in
;                this call. NOTE the public loader (thm_load_ask) collects
;                these in a local and ASSIGNS its own files keyword once, so
;                that repeated calls replace rather than grow the caller's
;                variable -- the legacy thm_load_xxx contract, which the
;                SPEDAS GUI relies on (it reuses one variable per load).
;  relpathnames_all: (in/out) accumulates cache-relative paths, same contract
;  tplotnames:   (out) accumulates created tplot variable names
;-
pro thm_asi_load_ask, sites = sites, trange = trange, suffix = suffix, $
  rego = rego, downloadonly = downloadonly, no_download = no_download, $
  verbose = verbose, files = files, relpathnames_all = relpathnames_all, $
  tplotnames = tplotnames

  compile_opt idl2

  thm_init
  cfg = thm_asi_config()
  if ~keyword_set(suffix) then suffix = ''
  if keyword_set(rego) then begin
    dataset = cfg.dataset_rego_ask
    vprefix = 'clg_ask_'
    nrows = 512
    glob_suffix = '*keogram.png'
  endif else begin
    dataset = cfg.dataset_ask
    vprefix = 'thg_ask_'
    nrows = 256
    glob_suffix = '*keogram.pgm*'
  endelse
  local_root = !themis.local_data_dir + cfg.cache_subdir + dataset + path_sep()
  nmade = 0

  tr = timerange(trange)
  ; hour granules intersecting [tr0, tr1); an end time exactly on an hour
  ; boundary does not pull in the next hour (matches legacy day-file scope)
  h0 = floor(tr[0] / 3600d) * 3600d
  h1 = ceil(tr[1] / 3600d) * 3600d - 3600d
  if h1 lt h0 then h1 = h0
  iso0 = time_string(h0, tformat='YYYY-MM-DDThh:mm:ss')
  iso1 = time_string(h1 + 3599d, tformat='YYYY-MM-DDThh:mm:ss')

  for isite = 0, n_elements(sites) - 1 do begin
    site = strlowcase(sites[isite])
    vname = vprefix + site + suffix

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
      ; offline fallback: glob the local cache hour by hour (same file set
      ; as the server query resolves)
      for t = h0, h1, 3600d do begin
        ymd = time_string(t, tformat='YYYY') + path_sep() + $
          time_string(t, tformat='MM') + path_sep() + time_string(t, tformat='DD')
        hh = 'ut' + time_string(t, tformat='hh')
        pat = local_root + ymd + path_sep() + site + '_*' + path_sep() + $
          hh + path_sep() + glob_suffix
        found = file_search(pat, count = nfound)
        if nfound gt 0 then begin
          if nf_files eq 0 then flist = found else flist = [flist, found]
          nf_files += nfound
        endif
      endfor
      if nf_files gt 0 then begin
        flist = flist[uniq(flist, sort(flist))]
        flist = thm_asi_dedup_gz(flist)   ; drop .pgm/.pgm.gz twins
        nf_files = n_elements(flist)
      endif
    endif

    if nf_files eq 0 then begin
      dprint, dlevel=1, verbose=verbose, 'thm_asi_load_ask: no keogram files for ' + $
        site + ' in ' + iso0 + ' .. ' + iso1
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

    ; ---- read and stitch the hourly keograms
    x = 0d
    y = 0us
    first = 1
    src_file = ''
    time_res = keyword_set(rego) ? '3s' : '6s'
    for i = 0, nf_files - 1 do begin
      is_png = strmatch(flist[i], '*.png')
      if is_png then begin
        img = read_png(flist[i])
        if size(img, /n_dimensions) ne 2 then continue
        img = uint(img)
      endif else begin
        thm_asi_readfile, flist[i], img, meta, count = nfr, /no_metadata, $
          verbose = verbose
        if nfr eq 0 then continue
        img = reform(img)                       ; [ncols, nrows] (columns = time)
      endelse
      dims = size(img, /dimensions)
      if n_elements(dims) ne 2 then continue
      if dims[1] ne nrows then continue
      ncols = dims[0]

      ; hour start from the filename (YYYYMMDD_HH_...)
      toks = strsplit(file_basename(flist[i]), '_', /extract)
      if strlen(toks[1]) eq 2 then begin
        file_t0 = time_double(strmid(toks[0],0,4) + '-' + strmid(toks[0],4,2) + $
          '-' + strmid(toks[0],6,2) + '/' + toks[1] + ':00:00')
        file_span = 3600d
        coff = 0d                                 ; hourly: zero column offset
      endif else begin
        ; daily-keogram fallback (if config points at the daily product)
        file_t0 = time_double(strmid(toks[0],0,4) + '-' + strmid(toks[0],4,2) + $
          '-' + strmid(toks[0],6,2))
        file_span = 86400d
        coff = 30d                                ; daily: empirical +30 s
      endelse
      binw = file_span / ncols
      ctimes = file_t0 + dindgen(ncols) * binw + coff
      time_res = strtrim(string(round(binw)), 2) + 's'

      ; archived PGM row direction is opposite to the legacy convention;
      ; the REGO PNG-era keograms are already stored in legacy orientation
      ; (both pinned empirically vs the legacy ask CDFs)
      if ~is_png then img = reverse(img, 2)

      ; drop all-zero columns (daylight / camera off), mimicking legacy gaps
      colsum = total(img, 2)
      wgood = where(colsum gt 0, ngood)
      if ngood eq 0 then continue

      if src_file eq '' then src_file = flist[i]
      if first then begin
        x = ctimes[wgood]
        y = uint(img[wgood, *])
        first = 0
      endif else begin
        x = [x, ctimes[wgood]]
        y = [y, uint(img[wgood, *])]
      endelse
    endfor

    if first then begin
      dprint, dlevel=1, verbose=verbose, 'thm_asi_load_ask: no keogram data read for ' + site
      continue
    endif

    ; ---- sort and time clip to trange (legacy ask is clipped)
    order = sort(x)
    x = x[order]
    y = y[order, *]
    win = where(x ge tr[0] and x le tr[1], nin)
    if nin eq 0 then begin
      dprint, dlevel=1, verbose=verbose, 'thm_asi_load_ask: no keogram columns for ' + $
        site + ' within requested time range'
      continue
    endif
    x = x[win]
    y = y[win, *]

    ; ---- store with legacy-compatible structure and dlimits
    if keyword_set(rego) then begin
      gatt = { $
        project: 'REGO', $
        source_name: 'CLG_L1>Redline Emission Geospace Observatory', $
        discipline: ['Space Physics>Magnetospheric Science', 'Space Physics>Ionospheric Science'], $
        data_type: 'ASK>All Sky Imager, Keograms of images, High resolution', $
        descriptor: strupcase(site), $
        data_version: '1', $
        pi_name: 'E. Donovan', $
        pi_affiliation: 'Univ of Calgary', $
        text: 'UCalgary Ground Based Instrument part of the CSA GO Canada Program', $
        instrument_type: 'Ground-Based VLF/ELF/ULF, Photometrics', $
        mission_group: 'Groundbased Obaservatory', $
        logical_source: 'clg_l1_ask', $
        logical_file_id: file_basename(src_file), $
        logical_source_description: 'Ground-based All Sky Imager keograms, REGO network', $
        time_resolution: time_res, $
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
    endif else begin
      gatt = { $
        project: 'THEMIS', $
        source_name: 'THG_L1>THEMIS Ground Based Observatory', $
        discipline: ['Space Physics>Magnetospheric Science', 'Space Physics>Ionospheric Science'], $
        data_type: 'ASK>All Sky Imager, Keograms of images, High resolution', $
        descriptor: strupcase(site), $
        data_version: '1', $
        pi_name: 'V. Angelopoulos, S. Mende & E. Donovan', $
        pi_affiliation: 'UCB & Univ of Calgary respectively, NASA NAS5-02099', $
        text: 'THEMIS Ground Based Observatory part of the THEMIS GBO effort', $
        instrument_type: 'Ground-Based VLF/ELF/ULF, Photometrics', $
        mission_group: 'THEMIS', $
        logical_source: 'thg_l1_ask', $
        logical_file_id: file_basename(src_file), $
        logical_source_description: 'Ground-based All Sky Imager keograms, THEMIS GBO network', $
        time_resolution: time_res, $
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
    endelse
    ; REGO archive keograms are display-scaled, not counts (see header)
    dunits = keyword_set(rego) ? 'scaled_counts' : 'counts'
    ; the caveat belongs on the Z (color) axis: tplot appends ysubtitle to
    ; the Y TITLE, which would label the pixel-row axis with image units
    dzsub = keyword_set(rego) ? 'Scaled counts' : ''
    vatt = { $
      catdesc: 'Keogram images of ' + strtrim(nrows, 2) + ' pixels', $
      depend_0: vname + '_epoch', $
      depend_1: vprefix + 'row', $
      display_type: 'spectrogram', $
      fieldnam: vname, $
      fillval: 65535us, $
      format: 'I5', $
      lablaxis: strupcase(site), $
      units: dunits, $
      validmin: 0us, $
      validmax: 65535us, $
      var_type: 'data', $
      depend_time: vname + '_time', $
      depend_epoch0: vname + '_epoch0' $
      }
    dl = { $
      cdf: {filename: src_file, gatt: gatt, vname: vname, vatt: vatt}, $
      spec: 1b, $
      log: 0b, $
      data_att: {coord_sys: '', units: dunits}, $
      ysubtitle: '', $
      zsubtitle: dzsub $
      }

    store_data, vname, data = {x: x, y: y, v: uindgen(nrows)}, dlimits = dl
    if undefined(tplotnames) then tplotnames = vname else tplotnames = [tplotnames, vname]
    nmade += 1
    dprint, dlevel=2, verbose=verbose, 'thm_asi_load_ask: created ' + vname
  endfor

  ; ---- one caveat message per call, not per site (REGO only)
  if keyword_set(rego) && nmade gt 0 then $
    dprint, dlevel=1, verbose=verbose, 'thm_asi_load_ask: NOTE: REGO ' + $
      'archive keograms are display-scaled, not counts -- the generator maps a ' + $
      'fixed count window onto 0-65535 and clips outside it, so faint pixels ' + $
      'bottom out at 0 and bright aurora saturates at 65535. Structure and ' + $
      'timing are correct; use thm_load_ask,/rego without /ucalgary_pgm ' + $
      '(the default Berkeley CDF path) for counts.'
end
