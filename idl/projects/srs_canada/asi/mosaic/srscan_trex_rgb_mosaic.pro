;+
;PROCEDURE:
;  srscan_trex_rgb_mosaic
;
;PURPOSE:
;  Render a TRUECOLOR mosaic of the TREx RGB all-sky imager array at a
;  given time: each camera's frame is projected onto a geographic map
;  through its skymap (110 km), painted pixel-by-pixel with 24-bit
;  decomposed color so the RGB data keep their real colors.
;
;INPUT:
;  time: 'YYYY-MM-DD/hh:mm:ss' (19 characters)
;
;KEYWORDS (selection):
;  sites:    site uid(s) to include (default: all from srscan_trex_rgb_sites)
;  exclude:  site uid(s) to skip
;  minimum_elevation: don't paint pixels below this elevation (default 8 deg)
;
;KEYWORDS (intensity scaling; same window applied to R,G,B to preserve
;color balance):
;  minval, maxval: linear stretch window (DN); scalars. Default: per-site
;                  auto stretch anchored at the median illuminated luma.
;
;KEYWORDS (map/canvas, passed to srscan_asi_map_set):
;  scale, central_lat, central_lon, projection, rotation, position,
;  xsize, ysize, noerase, window, zbuffer,
;  color_continent, color_background
;
;KEYWORDS (multi-frame):
;  stoptime:  'YYYY-MM-DD/hh:mm:ss'; render frames from time to stoptime
;  timestep:  seconds between frames (default 3)
;
;KEYWORDS (output/annotation):
;  png_out:  string filename -> write a PNG; with stoptime, one PNG per
;            frame named MOSA.<timestamp>.png in png_dir
;  png_dir:  output directory for the stoptime PNG series (default '.')
;  mosaic_image: (out) the rendered [3, xsize, ysize] truecolor image
;  no_grid:  skip the geographic grid overlay
;  no_label: skip the timestamp/network annotation
;  no_download, verbose: passthrough
;
;EXAMPLES:
;  srscan_trex_rgb_mosaic, '2023-03-24/06:22:30'
;  srscan_trex_rgb_mosaic, '2023-03-24/06:22:30', /zbuffer, $
;    png_out='mosaic.png', minval=15, maxval=120
;
;NOTES:
;  Pixels are painted in order of increasing elevation per site, so where
;  fields of view overlap the higher-elevation (better) view wins.
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-10-14 09:44:38 -0700 (Wed, 14 Oct 2026) $
;$LastChangedRevision: 34972 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/srs_canada/asi/mosaic/srscan_trex_rgb_mosaic.pro $
;-

; geographic grid overlay in 24-bit color (parallels/meridians via map_set
; coordinates; kept internal so the mosaic has no THEMIS dependencies)
pro srscan_trex_rgb_mosaic_grid, color = color
  compile_opt idl2, hidden
  if n_elements(color) eq 0 then color = '505050'xl
  for glat = 30, 80, 10 do $
    plots, findgen(361) - 180., fltarr(361) + glat, color = color, linestyle = 1, /data
  for glon = 0, 350, 10 do $
    plots, fltarr(51) + (glon - 180.), findgen(51) * 1.2 + 20., color = color, $
      linestyle = 1, /data
end

pro srscan_trex_rgb_mosaic, time, $
  sites = sites, exclude = exclude, minimum_elevation = minimum_elevation, $
  minval = minval, maxval = maxval, $
  scale = scale, central_lat = central_lat, central_lon = central_lon, $
  projection = projection, rotation = rotation, position = position, $
  xsize = xsize, ysize = ysize, noerase = noerase, window = window, $
  zbuffer = zbuffer, color_continent = color_continent, $
  color_background = color_background, $
  stoptime = stoptime, timestep = timestep, $
  png_out = png_out, png_dir = png_dir, mosaic_image = mosaic_image, $
  no_grid = no_grid, no_label = no_label, $
  no_download = no_download, verbose = verbose

  compile_opt idl2

  srscan_init

  ; validate the time argument like the THEMIS mosaic drivers do
  if size(time, /type) ne 7 || strlen(time) ne 19 then begin
    dprint, dlevel=0, 'srscan_trex_rgb_mosaic: time must be a 19-character string, ' + $
      'e.g. ''2023-03-24/06:22:30'''
    return
  endif

  if ~keyword_set(sites) then sites = (srscan_trex_rgb_sites()).uid
  min_ele = keyword_set(minimum_elevation) ? float(minimum_elevation) : 8.
  tstep = keyword_set(timestep) ? double(timestep) : 3d

  t = time_double(time)
  t_end = keyword_set(stoptime) ? time_double(stoptime) : t
  iframe = 0l

  while t le t_end do begin

    ; ---- per-site pixel arrays for this frame
    srscan_trex_rgb_mosaic_array, t, sites, img, cor, ele, www, n_sites, $
      exclude = exclude, no_download = no_download, verbose = verbose

    ; any data at all?
    wima = where(www eq 1, nima)
    if nima eq 0 then begin
      dprint, dlevel=0, verbose=verbose, 'srscan_trex_rgb_mosaic: no images for ' + $
        time_string(t)
      if keyword_set(stoptime) then begin
        t += tstep
        iframe += 1
        continue
      endif else return
    endif

    ; ---- intensity scaling: one window for all three channels
    n1 = (size(img, /dimensions))[0]
    rgb = bytarr(n1, 3, n_sites)
    for i = 0, n_sites - 1 do begin
      wgood = where(www[*, i] eq 1 and ele[*, i] gt min_ele, ngood)
      if ngood eq 0 then continue
      if n_elements(minval) gt 0 && n_elements(maxval) gt 0 then begin
        lo = float(minval[0])
        hi = float(maxval[0])
      endif else begin
        ; auto stretch: anchor at the median illuminated luma of this site
        luma = 0.299 * img[wgood, 0, i] + 0.587 * img[wgood, 1, i] + $
          0.114 * img[wgood, 2, i]
        med = median(luma) > 1.
        lo = 0.
        hi = (med * 2.8) > 24.
      endelse
      scl = (float(img[*, *, i]) - lo) / ((hi - lo) > 1.) < 1. > 0.
      rgb[*, *, i] = byte(round(scl * 255.))
    endfor

    ; ---- map canvas
    srscan_asi_map_set, scale = scale, central_lat = central_lat, $
      central_lon = central_lon, color_continent = color_continent, $
      color_background = color_background, position = position, $
      xsize = xsize, ysize = ysize, noerase = noerase, zbuffer = zbuffer, $
      projection = projection, window = window, rotation = rotation

    ; ---- paint: 24-bit decomposed polyfill, R + 256*G + 65536*B.
    ; Pixels from ALL sites are merged and sorted by elevation so that in
    ; overlapping fields of view the higher-elevation (better) view paints
    ; last and wins, regardless of site order.
    npaint = 0l
    for i = 0, n_sites - 1 do begin
      wpix = where(www[*, i] eq 1 and ele[*, i] gt min_ele, npix)
      if npix eq 0 then continue
      cols = long(rgb[wpix, 0, i]) + 256L * long(rgb[wpix, 1, i]) + $
        65536L * long(rgb[wpix, 2, i])
      if npaint eq 0 then begin
        all_cols = cols
        all_ele = ele[wpix, i]
        all_x = cor[wpix, *, 0, i]
        all_y = cor[wpix, *, 1, i]
      endif else begin
        all_cols = [all_cols, cols]
        all_ele = [all_ele, ele[wpix, i]]
        all_x = [all_x, cor[wpix, *, 0, i]]
        all_y = [all_y, cor[wpix, *, 1, i]]
      endelse
      npaint += npix
    endfor
    if npaint gt 0 then begin
      a = sort(all_ele)
      for p = 0l, npaint - 1 do begin
        k = a[p]
        polyfill, all_x[k, [0, 1, 2, 3, 0]], all_y[k, [0, 1, 2, 3, 0]], $
          color = all_cols[k]
      endfor
    endif else begin
      ; illuminated pixels exist (nima > 0) but none clear min_ele
      dprint, dlevel=0, verbose=verbose, 'srscan_trex_rgb_mosaic: no pixels above ' + $
        'minimum elevation ' + strtrim(min_ele, 2) + ' deg for ' + time_string(t)
    endelse

    ; ---- overlays
    if ~keyword_set(no_grid) then srscan_trex_rgb_mosaic_grid
    if ~keyword_set(no_label) then begin
      xyouts, 0.005, 0.018, time_string(t), color = 'ffffff'xl, /normal, charsize = 1.2
      xyouts, 0.005, 0.060, 'TREx RGB', color = 'ffffff'xl, /normal, charsize = 1.2
    endif

    ; ---- output
    mosaic_image = tvrd(/true)
    if keyword_set(png_out) then begin
      if keyword_set(stoptime) then begin
        gdir = keyword_set(png_dir) ? png_dir : '.'
        fname = gdir + path_sep() + 'MOSA.' + $
          time_string(t, tformat='YYYY.MM.DD.hh.mm.ss') + '.png'
      endif else fname = png_out
      write_png, fname, mosaic_image
      dprint, dlevel=1, verbose=verbose, 'srscan_trex_rgb_mosaic: wrote ' + fname
    endif

    if ~keyword_set(stoptime) then break
    t += tstep
    iframe += 1
  endwhile

  ; restore the interactive graphics device after z-buffer rendering
  if keyword_set(zbuffer) then $
    set_plot, (strlowcase(!version.os_family) eq 'windows') ? 'win' : 'x'
end
