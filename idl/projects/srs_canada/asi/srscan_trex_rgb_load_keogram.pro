;+
;PROCEDURE:
;  srscan_trex_rgb_load_keogram
;
;PURPOSE:
;  Load TREx RGB archived hourly keograms from the data archive
;  (data.phys.ucalgary.ca), stitched across the requested range, into:
;    srscan_trexrgb_keo_<site>: {x[n], y[n,480,3] byte, v[480]}
;  The variable renders in TRUECOLOR in tplot (like the archive colour
;  quicklooks) through the srscan_trexrgb_keoplot plotting routine
;  registered in its dlimits; the zrange option sets the linear stretch.
;  With channel= set, a single-channel classic spectrogram companion
;  srscan_trexrgb_keo_<site>_<channel> {x[n], y[n,480] byte} (spec=1) is
;  created as well.
;
;  IMPORTANT -- these keograms are lossy JPEG QUICKLOOK products: the DN
;  values carry JPEG compression artifacts and display scaling, and are
;  NOT photometric. Structure and timing are correct -- they plot
;  correctly and are ideal for browsing -- but do not use the values as
;  intensities. For quantitative work build a keogram from the raw images
;  (srscan_asi_keogram on a loaded srscan_trexrgb_<site> variable).
;
;  Layout facts (pinned empirically against the archive):
;    - hourly files, 1200 columns/hour = one column per 3-s frame;
;      column j is the frame at hour_start + j*3 s (zero offset)
;    - as read by read_jpeg, row 0 = south, so the tplot spectrogram
;      (row index increasing upward) is already north-at-top; no flip
;
;  Internal worker for srscan_load_trex_rgb.
;
;KEYWORDS:
;  sites:        string array of 4-letter site codes (lowercase)
;  trange:       time range (defaults to timerange()); output is clipped
;                to trange unless /no_time_clip is set (keograms are
;                cheap; matches thm_load_ask)
;  no_time_clip: store every column of every fetched hourly file instead
;                of clipping the output to trange
;  channel:      if set to 'luma', 'r', 'g', or 'b', ALSO create a
;                single-channel spectrogram companion variable
;                srscan_trexrgb_keo_<site>_<channel> (the main variable
;                is always full RGB)
;  suffix:       appended to tplot variable names
;  downloadonly: download files but do not load into tplot
;  no_download:  do not contact server; use only the local cache
;  verbose:      dprint verbosity
;  files:        (in/out) APPENDS local file paths (assign-once handled by
;                the public loader; see srscan_trex_rgb_load_raw header)
;  relpathnames_all: (in/out) same contract
;  tplotnames:   (out) accumulates created tplot variable names
;-
pro srscan_trex_rgb_load_keogram, sites = sites, trange = trange, $
  no_time_clip = no_time_clip, channel = channel, suffix = suffix, $
  downloadonly = downloadonly, no_download = no_download, $
  verbose = verbose, files = files, relpathnames_all = relpathnames_all, $
  tplotnames = tplotnames

  compile_opt idl2

  srscan_init
  cfg = srscan_api_config()
  if ~keyword_set(suffix) then suffix = ''
  dataset = cfg.dataset_rgb_keogram
  local_root = !srs_canada.local_data_dir + dataset + path_sep()
  nrows = 480

  tr = timerange(trange)
  ; hour granules intersecting [tr0, tr1); an end time exactly on an hour
  ; boundary does not pull in the next hour
  h0 = floor(tr[0] / 3600d) * 3600d
  h1 = ceil(tr[1] / 3600d) * 3600d - 3600d
  if h1 lt h0 then h1 = h0
  iso0 = time_string(h0, tformat='YYYY-MM-DDThh:mm:ss')
  iso1 = time_string(h1 + 3599d, tformat='YYYY-MM-DDThh:mm:ss')

  for isite = 0, n_elements(sites) - 1 do begin
    site = strlowcase(sites[isite])
    vname = 'srscan_trexrgb_keo_' + site + suffix

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
      ; offline fallback: glob the local cache hour by hour (same file set
      ; as the server query resolves)
      for t = h0, h1, 3600d do begin
        ymd = time_string(t, tformat='YYYY') + path_sep() + $
          time_string(t, tformat='MM') + path_sep() + time_string(t, tformat='DD')
        hh = 'ut' + time_string(t, tformat='hh')
        pat = local_root + ymd + path_sep() + site + '_*' + path_sep() + $
          hh + path_sep() + '*keogram.jpg'
        found = file_search(pat, count = nfound)
        if nfound gt 0 then begin
          if nf_files eq 0 then flist = found else flist = [flist, found]
          nf_files += nfound
        endif
      endfor
      if nf_files gt 0 then begin
        flist = flist[uniq(flist, sort(flist))]
        nf_files = n_elements(flist)
      endif
    endif

    if nf_files eq 0 then begin
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_keogram: no keogram ' + $
        'files for ' + site + ' in ' + iso0 + ' .. ' + iso1
      continue
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

    if keyword_set(downloadonly) then continue

    ; ---- read and stitch the hourly keogram JPEGs
    x = 0d
    ytrue = 0b
    first = 1
    src_file = ''
    for i = 0, nf_files - 1 do begin
      catch, jerr
      if jerr ne 0 then begin
        catch, /cancel
        dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_keogram: failed to ' + $
          'read ' + flist[i] + ', skipping'
        continue
      endif
      read_jpeg, flist[i], img, true = 1        ; [3, ncols, nrows]
      catch, /cancel

      dims = size(img, /dimensions)
      if n_elements(dims) ne 3 || dims[0] ne 3 || dims[2] ne nrows then begin
        dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_keogram: unexpected ' + $
          'dimensions [' + strjoin(strtrim(dims, 2), ',') + '] in ' + flist[i] + ', skipping'
        continue
      endif
      ncols = dims[1]

      ; hour start from the filename (YYYYMMDD_HH_...)
      toks = strsplit(file_basename(flist[i]), '_', /extract)
      if strlen(toks[1]) ne 2 then continue
      file_t0 = time_double(strmid(toks[0],0,4) + '-' + strmid(toks[0],4,2) + $
        '-' + strmid(toks[0],6,2) + '/' + toks[1] + ':00:00')
      binw = 3600d / ncols                       ; nominally 3 s (1200 cols)
      ctimes = file_t0 + dindgen(ncols) * binw   ; zero column offset (pinned)

      ; [3, ncols, nrows] -> [ncols, nrows, 3] so columns concatenate along
      ; dimension 1 like the tplot x axis
      img = transpose(img, [1, 2, 0])

      if src_file eq '' then src_file = flist[i]
      if first then begin
        x = ctimes
        ytrue = img
        first = 0
      endif else begin
        x = [x, ctimes]
        ytrue = [ytrue, img]
      endelse
    endfor

    if first then begin
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_keogram: no keogram ' + $
        'data read for ' + site
      continue
    endif

    ; ---- sort and (unless /no_time_clip) clip to trange
    order = sort(x)
    x = x[order]
    ytrue = ytrue[order, *, *]
    if ~keyword_set(no_time_clip) then begin
      win = where(x ge tr[0] and x le tr[1], nin)
      if nin eq 0 then begin
        dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_load_keogram: no keogram ' + $
          'columns for ' + site + ' within requested time range'
        continue
      endif
      x = x[win]
      ytrue = ytrue[win, *, *]
    endif

    ; ---- store; the quicklook caveat lives in units/ytitle metadata so it
    ; survives zoom/replot (same pattern as the REGO scaled-counts caveat)
    gatt = { $
      project: 'TREx', $
      source_name: 'TREX>Transition Region Explorer', $
      discipline: ['Space Physics>Magnetospheric Science', 'Space Physics>Ionospheric Science'], $
      data_type: 'KEO>All Sky Imager, Keograms of images', $
      descriptor: strupcase(site), $
      data_version: '1', $
      pi_name: 'E. Spanswick & E. Donovan', $
      pi_affiliation: 'University of Calgary', $
      text: 'Transition Region Explorer RGB colour all-sky imager network', $
      instrument_type: 'Ground-Based Imagers, Photometrics', $
      mission_group: 'Ground-Based Observatory', $
      logical_source: 'trex_rgb_keogram', $
      logical_file_id: file_basename(src_file), $
      logical_source_description: 'Ground-based colour All Sky Imager keograms (JPEG quicklook), TREx network', $
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
      catdesc: 'Keogram images of ' + strtrim(nrows, 2) + ' pixels (JPEG quicklook DN)', $
      depend_0: vname + '_epoch', $
      display_type: 'spectrogram', $
      fieldnam: vname, $
      fillval: 255b, $
      format: 'I3', $
      lablaxis: strupcase(site), $
      units: 'quicklook_dn', $
      validmin: 0b, $
      validmax: 255b, $
      var_type: 'data' $
      }
    ; main variable: full RGB, rendered truecolor by srscan_trexrgb_keoplot
    dl = { $
      cdf: {filename: src_file, gatt: gatt, vname: vname, vatt: vatt}, $
      tplot_routine: 'srscan_trexrgb_keoplot', $
      spec: 0b, $
      log: 0b, $
      data_att: {coord_sys: '', units: 'quicklook_dn'}, $
      yrange: [0, nrows - 1], ystyle: 1, $
      ysubtitle: '[quicklook DN]' $
      }
    store_data, vname, data = {x: x, y: ytrue, v: indgen(nrows)}, dlimits = dl
    options, vname, 'ytitle', strupcase(site), /default
    if undefined(tplotnames) then tplotnames = vname else tplotnames = [tplotnames, vname]

    ; optional single-channel classic spectrogram companion
    if keyword_set(channel) then begin
      chname = strlowcase(channel[0])
      case chname of
        'r': yspec = reform(ytrue[*, *, 0])
        'g': yspec = reform(ytrue[*, *, 1])
        'b': yspec = reform(ytrue[*, *, 2])
        else: begin
          chname = 'luma'
          yspec = byte(round(0.299d * ytrue[*, *, 0] + 0.587d * ytrue[*, *, 1] + $
            0.114d * ytrue[*, *, 2]) < 255)
        end
      endcase
      dl_ch = { $
        cdf: {filename: src_file, gatt: gatt, vname: vname + '_' + chname, vatt: vatt}, $
        spec: 1b, $
        log: 0b, $
        data_att: {coord_sys: '', units: 'quicklook_dn'}, $
        ysubtitle: '', $
        ztitle: '[quicklook DN, not photometric]' $
        }
      store_data, vname + '_' + chname, data = {x: x, y: yspec, v: indgen(nrows)}, $
        dlimits = dl_ch
      options, vname + '_' + chname, 'ytitle', strupcase(site) + ' ' + chname, /default
      tplotnames = [tplotnames, vname + '_' + chname]
    endif
    made = vname
    if keyword_set(channel) then made += ', ' + vname + '_' + chname
    dprint, dlevel=2, verbose=verbose, 'srscan_trex_rgb_load_keogram: created ' + made
  endfor
end
