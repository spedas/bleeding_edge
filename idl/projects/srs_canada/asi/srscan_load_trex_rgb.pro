;+
;PROCEDURE:
;  srscan_load_trex_rgb
;
;PURPOSE:
;  Load TREx RGB all-sky imager data from the data archive at
;  data.phys.ucalgary.ca (file listings via api.phys.ucalgary.ca).
;
;  Datatypes:
;    'raw'     (default) stream0 truecolor images, nominal 3-s cadence
;              -> srscan_trexrgb_<site>  {x[n], y[n,3,553,480] byte}
;              MEMORY: ~0.95 GB per site-hour; load minutes, or time=
;    'keogram' archived hourly keogram JPEGs (quicklook DN, lossy)
;              -> srscan_trexrgb_keo_<site>  {x[n], y[n,480,3] byte}
;              renders TRUECOLOR in tplot (srscan_trexrgb_keoplot routine;
;              the zrange option sets the linear stretch); channel= adds a
;              single-channel spectrogram companion
;    'grid'    pre-rendered MOSv001 global mosaic grids (selected
;              intervals only)
;              -> srscan_trexrgb_grid  {x[n], y[n,3,1024,512] float}
;
;KEYWORDS:
;  site:         4-letter site code(s): string, array, space-delimited
;                list, or 'all' (default). Ignored for datatype='grid'.
;  datatype:     'raw' (default), 'keogram', 'grid', or 'all'-style lists
;  trange:       time range (defaults to timerange()); only the file
;                granules covering the range are fetched, and the output
;                is clipped to trange unless /no_time_clip is set
;  no_time_clip: store everything in the fetched files instead of
;                clipping the output to trange (output then aligns to
;                file boundaries: 1-min for raw/grid, hourly for keogram)
;  time:         single time: load only the frame nearest this time
;                (+-1.5 s; raw only)
;  channel:      keogram only: if set to 'luma', 'r', 'g', or 'b', also
;                create a single-channel classic spectrogram companion
;                srscan_trexrgb_keo_<site>_<channel> (the main keogram
;                variable is always full RGB)
;  suffix:       appended to tplot variable names
;  downloadonly: download but do not load into tplot
;  no_download:  offline mode; use only the local cache
;  verbose:      dprint verbosity
;  files:        (out) local paths of the files used (assigned once per call)
;  relpathnames_all: (out) cache-relative paths (assigned once per call);
;                requesting this implies downloadonly + no_download
;  tplotnames:   (out) names of the tplot variables created
;  valid_names:  print/return the valid sites and datatypes without loading
;                (site and datatype keywords are assigned the valid lists)
;
;EXAMPLES:
;  timespan, '2023-03-24', 1, /day
;  srscan_load_trex_rgb, datatype='keogram'                    ; all sites
;  srscan_load_trex_rgb, site='gill', $
;    trange=['2023-03-24/06:20', '2023-03-24/06:30']           ; 10 min raw
;  srscan_load_trex_rgb, time='2023-03-24/06:22:30'            ; one frame,
;                                                              ; all sites
;
;NOTES:
;  Burst data (stream0.burst) and the early legacy-PGM era are not
;  supported. Data documentation: https://data.phys.ucalgary.ca
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-10-14 09:44:38 -0700 (Wed, 14 Oct 2026) $
;$LastChangedRevision: 34972 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/srs_canada/asi/srscan_load_trex_rgb.pro $
;-
pro srscan_load_trex_rgb, site = site, datatype = datatype, trange = trange, $
  time = time, no_time_clip = no_time_clip, channel = channel, suffix = suffix, $
  downloadonly = downloadonly, no_download = no_download, $
  verbose = verbose, files = files, relpathnames_all = relpathnames_all, $
  tplotnames = tplotnames, valid_names = valid_names

  compile_opt idl2

  vsites = (srscan_trex_rgb_sites()).uid
  vdts = ['raw', 'keogram', 'grid']

  if keyword_set(valid_names) then begin
    site = vsites
    datatype = vdts
    print, 'Valid TREx RGB sites:     ' + strjoin(vsites, ' ')
    print, 'Valid TREx RGB datatypes: ' + strjoin(vdts, ' ')
    return
  endif

  ; legacy "just tell me the filenames" mode
  if arg_present(relpathnames_all) then begin
    downloadonly = 1
    no_download = 1
  endif

  ; resolve site selection ('all', wildcards, arrays, space-delimited
  ; strings). strlowcase rather than /ignore_case: the latter assigns back
  ; into the caller's variable.
  if keyword_set(site) then begin
    my_sites = ssl_check_valid_name(strlowcase(site), vsites, /include_all)
    nsites = keyword_set(my_sites) ? n_elements(my_sites) : 0
  endif else begin
    my_sites = vsites
    nsites = n_elements(vsites)
  endelse
  if nsites eq 0 then begin
    dprint, dlevel=0, verbose=verbose, 'srscan_load_trex_rgb: no valid sites in: ' + $
      strjoin(site, ' ')
    return
  endif

  ; resolve datatype selection
  if keyword_set(datatype) then begin
    my_dts = ssl_check_valid_name(strlowcase(datatype), vdts, /include_all)
    ndts = keyword_set(my_dts) ? n_elements(my_dts) : 0
  endif else begin
    my_dts = ['raw']
    ndts = 1
  endelse
  if ndts eq 0 then begin
    dprint, dlevel=0, verbose=verbose, 'srscan_load_trex_rgb: no valid datatypes in: ' + $
      strjoin(datatype, ' ')
    return
  endif

  ; the workers APPEND to files/relpathnames_all; accumulate into locals
  ; and assign the caller's keywords exactly once at the end (the GUI
  ; reuses one variable per load, so appending here would grow it)
  for j = 0, ndts - 1 do begin
    case my_dts[j] of
      'raw': srscan_trex_rgb_load_raw, sites = my_sites, trange = trange, $
        time = time, no_time_clip = no_time_clip, suffix = suffix, $
        downloadonly = downloadonly, $
        no_download = no_download, verbose = verbose, $
        files = ucal_files, relpathnames_all = ucal_relpaths, $
        tplotnames = tplotnames
      'keogram': srscan_trex_rgb_load_keogram, sites = my_sites, trange = trange, $
        no_time_clip = no_time_clip, channel = channel, suffix = suffix, $
        downloadonly = downloadonly, $
        no_download = no_download, verbose = verbose, $
        files = ucal_files, relpathnames_all = ucal_relpaths, $
        tplotnames = tplotnames
      'grid': srscan_trex_rgb_load_grid, trange = trange, time = time, $
        no_time_clip = no_time_clip, suffix = suffix, $
        downloadonly = downloadonly, $
        no_download = no_download, verbose = verbose, $
        files = ucal_files, relpathnames_all = ucal_relpaths, $
        tplotnames = tplotnames
    endcase
  endfor

  files = (n_elements(ucal_files) gt 0) ? ucal_files : ''
  relpathnames_all = (n_elements(ucal_relpaths) gt 0) ? ucal_relpaths : ''
end
