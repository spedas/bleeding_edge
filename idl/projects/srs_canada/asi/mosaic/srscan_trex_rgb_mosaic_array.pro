;+
;PROCEDURE:
;  srscan_trex_rgb_mosaic_array
;
;PURPOSE:
;  Build the per-site pixel arrays a TREx RGB mosaic is rendered from:
;  for every requested site, load the frame nearest the requested time,
;  fetch the site's skymap, and emit flattened per-pixel image values,
;  geographic corner polygons, elevations, and an illuminated flag.
;
;  Skymaps are consumed NATIVELY (full_map_latitude/longitude corner grids
;  at 110 km, full_elevation) -- no THEMIS-style calibration adapter.
;  All arrays get the one srscan_trex_rgb_orient transform so images and
;  geometry stay aligned.
;
;INPUT:
;  time:   'YYYY-MM-DD/hh:mm:ss' (or unix double) -- frame nearest this
;          time (+-1.5 s) is used per site
;  sites:  string array of site uids to include
;
;OUTPUT (positional):
;  img1:   fltarr[n1, 3, n_sites]  dark-subtracted RGB pixel values
;  cor1:   fltarr[n1, 4, 2, n_sites]  corner (lon,lat) polygons at 110 km
;  ele1:   fltarr[n1, n_sites]  pixel elevation angles (deg)
;  www1:   intarr[n1, n_sites]  1 = pixel imaged and corners finite, -1 = not
;  n_sites: number of sites in the arrays (= n_elements(sites))
;  (n1 = 553*480; rows are sorted by increasing elevation per site so the
;   driver paints low-elevation pixels first and overlaps favor the
;   higher-elevation view)
;
;KEYWORDS:
;  exclude:     site uid(s) to skip
;  no_download: offline mode passthrough
;  verbose:     dprint verbosity
;
;NOTES:
;  Corner extraction uses ALL-ARRAY subscripts: in IDL,
;  arr[scalar, ivec, jvec] is a CROSS PRODUCT of the subscript vectors;
;  element-wise pairing requires every subscript to be an array, which is
;  why the corner lookups below are done with full index arrays into the
;  flattened [554,481] grids.
;-
pro srscan_trex_rgb_mosaic_array, time, sites, img1, cor1, ele1, www1, n_sites, $
  exclude = exclude, no_download = no_download, verbose = verbose

  compile_opt idl2

  nx = 553L
  ny = 480L
  n1 = nx * ny
  n_sites = n_elements(sites)

  img1 = fltarr(n1, 3, n_sites)
  cor1 = fltarr(n1, 4, 2, n_sites)
  ele1 = fltarr(n1, n_sites)
  www1 = intarr(n1, n_sites) - 1

  ; index arrays for vectorized corner extraction from the [554,481]
  ; corner grids (linear index = i + j*554)
  ii = rebin(lindgen(nx), nx, ny)                      ; pixel column
  jj = rebin(transpose(lindgen(ny)), nx, ny)           ; pixel row
  k00 = (ii + jj * 554L)[*]                            ; corner (i  , j  )
  k01 = (ii + (jj + 1L) * 554L)[*]                     ; corner (i  , j+1)
  k11 = ((ii + 1L) + (jj + 1L) * 554L)[*]              ; corner (i+1, j+1)
  k10 = ((ii + 1L) + jj * 554L)[*]                     ; corner (i+1, j  )

  for i_site = 0, n_sites - 1 do begin
    site = strlowcase(sites[i_site])

    if keyword_set(exclude) then begin
      w = where(strlowcase(exclude) eq site, nex)
      if nex gt 0 then continue
    endif

    ; ---- image: frame nearest the requested time
    vname = 'srscan_trexrgb_' + site
    if tnames(vname) ne '' then store_data, vname, /delete
    srscan_load_trex_rgb, site = site, time = time, no_download = no_download, $
      verbose = verbose
    if tnames(vname) eq '' then begin
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_mosaic_array: no image for ' + $
        site + ' at ' + time_string(time)
      continue
    endif
    get_data, vname, data = dat
    if size(dat, /type) ne 8 then continue
    u = float(dat.y)                                   ; [3,553,480], ORIENTed

    ; ---- skymap geometry (native), ORIENTed to match the image
    sky = srscan_trex_rgb_skymap(site, time, no_download = no_download, $
      verbose = verbose)
    if size(sky, /type) ne 8 then begin
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_mosaic_array: no skymap for ' + $
        site + ', skipping'
      continue
    endif
    ; corner grids at 110 km (altitude index 1 of [90,110,150] km)
    x = srscan_trex_rgb_orient(reform(sky.full_map_longitude[*, *, 1]))   ; [554,481]
    y = srscan_trex_rgb_orient(reform(sky.full_map_latitude[*, *, 1]))
    elev = srscan_trex_rgb_orient(sky.full_elevation)                     ; [553,480]
    ; map_set wants -180..180 east longitude
    wlon = where(x gt 180., nlon)
    if nlon gt 0 then x[wlon] -= 360.

    ; ---- crude dark subtraction per channel (unexposed corner of the CCD)
    for c = 0, 2 do begin
      dark = mean(u[c, 0:10, 0:10])
      u[c, *, *] = (u[c, *, *] - dark) > 0.
    endfor

    ; ---- flatten: pixel k = i + j*553
    img = transpose(reform(u, 3, n1))                  ; [n1,3]
    ele = elev[*]

    ; corners, vectorized (see NOTES); order (i,j),(i,j+1),(i+1,j+1),(i+1,j)
    cor = fltarr(n1, 4, 2)
    cor[*, 0, 0] = x[k00] & cor[*, 1, 0] = x[k01]
    cor[*, 2, 0] = x[k11] & cor[*, 3, 0] = x[k10]
    cor[*, 0, 1] = y[k00] & cor[*, 1, 1] = y[k01]
    cor[*, 2, 1] = y[k11] & cor[*, 3, 1] = y[k10]

    ; illuminated = all four corners finite (off-sky pixels have NaN corners)
    www = intarr(n1) - 1
    wgood = where(finite(x[k00]) and finite(x[k01]) and finite(x[k11]) and $
      finite(x[k10]) and finite(y[k00]) and finite(y[k01]) and $
      finite(y[k11]) and finite(y[k10]), ngood)
    if ngood gt 0 then www[wgood] = 1

    ; ---- sort by increasing elevation (all channels on the same index)
    a = sort(ele)
    img1[*, *, i_site] = img[a, *]
    cor1[*, *, *, i_site] = cor[a, *, *]
    ele1[*, i_site] = ele[a]
    www1[*, i_site] = www[a]
  endfor
end
