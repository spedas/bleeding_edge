;+
;PROCEDURE:
;  srscan_asi_map_set
;
;PURPOSE:
;  Prepare a map canvas for srs_canada all-sky imager mosaics.
;
;  Unlike the THEMIS thm_map_set (8-bit color-table graphics), this canvas
;  runs in DECOMPOSED 24-bit color throughout, which is what lets truecolor
;  (RGB) imager data render with real colors: continents, background, grid
;  and annotations are 24-bit long values ('BBGGRR'x), and the mosaic
;  drivers polyfill with R + 256L*G + 65536L*B.
;
;  Defaults center on the TREx array (computed from srscan_trex_rgb_sites).
;
;KEYWORDS:
;  scale:            map_set scale (default 14e6)
;  central_lat:      geographic latitude of plot center (default: TREx centroid)
;  central_lon:      geographic longitude of plot center (default: TREx centroid)
;  color_continent:  24-bit fill color for land (default dark gray)
;  color_background: 24-bit background color (default near-black)
;  position:         plot position in normal coordinates
;  xsize, ysize:     window/buffer size in pixels (default 800x600)
;  noerase:          do not erase the current window
;  zbuffer:          render into the Z buffer (headless-safe)
;  projection:       map_set projection name (default 'mercator')
;  window:           direct-graphics window number
;  rotation:         map rotation (degrees)
;-
pro srscan_asi_map_set, scale = scale, $
  central_lat = central_lat, central_lon = central_lon, $
  color_continent = color_continent, color_background = color_background, $
  position = position, xsize = xsize, ysize = ysize, noerase = noerase, $
  zbuffer = zbuffer, projection = projection, window = window, $
  rotation = rotation

  compile_opt idl2

  ; defaults centered on the TREx RGB array
  sites = srscan_trex_rgb_sites()
  lat1 = mean(sites.glat) + 2.       ; nudge north: FOVs project poleward
  lon1 = mean(sites.glon)
  if n_elements(central_lat) gt 0 then lat1 = central_lat
  if n_elements(central_lon) gt 0 then lon1 = central_lon

  scale1 = 14e6
  if keyword_set(scale) then scale1 = scale

  background_color = '141414'xl
  continent_color = '3c3c3c'xl
  if n_elements(color_background) gt 0 then background_color = long(color_background)
  if n_elements(color_continent) gt 0 then continent_color = long(color_continent)

  pa1 = [0., 0., 1., 1.]
  if keyword_set(position) then pa1 = position

  xs = keyword_set(xsize) ? xsize : 800
  ys = keyword_set(ysize) ? ysize : 600

  if keyword_set(zbuffer) then begin
    set_plot, 'z'
    device, set_resolution = [xs, ys], set_pixel_depth = 24, decomposed = 1
  endif else begin
    if !d.name eq 'WIN' or !d.name eq 'X' then device, decomposed = 1
    if ~keyword_set(noerase) then begin
      win_num = keyword_set(window) ? window : 0
      window, win_num, xsize = xs, ysize = ys
    endif
  endelse

  name = keyword_set(projection) ? projection : 'mercator'
  rot = keyword_set(rotation) ? rotation : 0.

  map_set, name = name, lat1, lon1, rot, scale = scale1, position = pa1, $
    noerase = noerase
  if ~keyword_set(noerase) then erase, background_color
  map_continents, /fill_continents, color = continent_color
  map_continents, color = continent_color + '181818'xl   ; subtle coastlines
end
