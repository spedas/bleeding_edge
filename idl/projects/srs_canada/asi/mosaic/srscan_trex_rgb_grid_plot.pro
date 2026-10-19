;+
;PROCEDURE:
;  srscan_trex_rgb_grid_plot
;
;PURPOSE:
;  Render one frame of a loaded MOSv001 grid variable
;  (srscan_trexrgb_grid) onto the srs_canada map canvas in truecolor.
;
;  The MOSv001 grids are the OFFICIAL archive mosaic rendering, so this
;  is the ground truth to compare srscan_trex_rgb_mosaic output against
;  (geometry and color).
;
;  The grid cells are regular in lon/lat, so each frame is warped to the
;  map projection with map_patch per channel and displayed with tv,/true;
;  fill cells (-999) stay transparent (map background shows through).
;
;INPUT:
;  time: time of the frame to render (string or double); the nearest
;        loaded frame is used
;
;KEYWORDS:
;  varname:  tplot variable to render (default 'srscan_trexrgb_grid')
;  minval, maxval: linear intensity stretch (same window for R,G,B;
;        default minval=0, maxval=255 -- the DN are already display-ish)
;  png_out:  write the canvas to this PNG file
;  mosaic_image: (out) rendered [3,xs,ys] image
;  no_label: skip annotation
;  and the srscan_asi_map_set canvas keywords:
;  scale, central_lat, central_lon, projection, rotation, position,
;  xsize, ysize, noerase, window, zbuffer, color_continent, color_background
;
;EXAMPLE:
;  srscan_load_trex_rgb, datatype='grid', time='2023-03-24/06:22:30'
;  srscan_trex_rgb_grid_plot, '2023-03-24/06:22:30', /zbuffer, png_out='grid.png'
;-
pro srscan_trex_rgb_grid_plot, time, varname = varname, $
  minval = minval, maxval = maxval, $
  png_out = png_out, mosaic_image = mosaic_image, no_label = no_label, $
  scale = scale, central_lat = central_lat, central_lon = central_lon, $
  projection = projection, rotation = rotation, position = position, $
  xsize = xsize, ysize = ysize, noerase = noerase, window = window, $
  zbuffer = zbuffer, color_continent = color_continent, $
  color_background = color_background

  compile_opt idl2

  if ~keyword_set(varname) then varname = 'srscan_trexrgb_grid'
  get_data, varname, data = d, dlimits = dl
  if size(d, /type) ne 8 then begin
    dprint, dlevel=0, 'srscan_trex_rgb_grid_plot: variable ' + varname + $
      ' not loaded (srscan_load_trex_rgb, datatype=''grid'' first)'
    return
  endif

  t = (size(time, /type) eq 7) ? time_double(time) : double(time)
  !null = min(abs(d.x - t), jj)
  frame = (size(d.y, /n_dimensions) eq 4) ? reform(d.y[jj, *, *, *]) : d.y  ; [3,1024,512]

  cell = 0.3515625d
  lon0 = -180d & lat0 = -90d
  fillv = -999.
  str_element, dl, 'data_att.cell_deg', cell
  str_element, dl, 'data_att.lon0', lon0
  str_element, dl, 'data_att.lat0', lat0
  str_element, dl, 'data_att.fill', fillv

  lo = n_elements(minval) gt 0 ? float(minval[0]) : 0.
  hi = n_elements(maxval) gt 0 ? float(maxval[0]) : 255.

  ; ---- crop to the data footprint (map_patch over the whole globe wastes
  ; enormous time on empty cells)
  mask = total(reform(frame[0, *, *]) ne fillv, 2) gt 0          ; lon columns with data
  wlon = where(mask, nlon)
  masklat = total(reform(frame[0, *, *]) ne fillv, 1) gt 0
  wlat = where(masklat, nlat_)
  if nlon eq 0 || nlat_ eq 0 then begin
    dprint, dlevel=1, 'srscan_trex_rgb_grid_plot: frame is all fill values'
    return
  endif
  i0 = wlon[0] > 1 & i1 = wlon[nlon-1] < 1022
  j0 = wlat[0] > 1 & j1 = wlat[nlat_-1] < 510
  ; one-cell margin so the footprint edge is not clipped
  i0 -= 1 & i1 += 1 & j0 -= 1 & j1 += 1
  sub = float(frame[*, i0:i1, j0:j1])
  wfill = where(sub eq fillv, nfill)
  if nfill gt 0 then sub[wfill] = 0.

  ; stretch to bytes (same window per channel)
  scl = (sub - lo) / ((hi - lo) > 1.) < 1. > 0.
  bsub = byte(round(scl * 255.))

  ; cell-center coordinates of the cropped block
  lons = lon0 + (dindgen(i1 - i0 + 1) + i0 + 0.5d) * cell
  lats = lat0 + (dindgen(j1 - j0 + 1) + j0 + 0.5d) * cell

  ; ---- canvas
  srscan_asi_map_set, scale = scale, central_lat = central_lat, $
    central_lon = central_lon, color_continent = color_continent, $
    color_background = color_background, position = position, $
    xsize = xsize, ysize = ysize, noerase = noerase, zbuffer = zbuffer, $
    projection = projection, window = window, rotation = rotation

  ; ---- warp each channel to device space and display in truecolor;
  ; build an alpha mask from the fill cells so empty cells stay background
  amask = byte(reform(frame[0, i0:i1, j0:j1]) ne fillv) * 255b
  wa = map_patch(amask, lons, lats, xstart = xs0, ystart = ys0, $
    xsize = wxs, ysize = wys, missing = 0)
  warped = bytarr(3, wxs, wys)
  for c = 0, 2 do begin
    wch = map_patch(reform(bsub[c, *, *]), lons, lats, xstart = xs0, $
      ystart = ys0, xsize = wxs, ysize = wys, missing = 0)
    warped[c, *, *] = wch
  endfor

  ; composite over the current canvas: read back, replace where alpha
  under = tvrd(/true)
  wshow = where(wa gt 127, nshow)
  if nshow gt 0 then begin
    for c = 0, 2 do begin
      uch = reform(under[c, xs0:xs0+wxs-1, ys0:ys0+wys-1])
      wch = reform(warped[c, *, *])
      uch[wshow] = wch[wshow]
      under[c, xs0:xs0+wxs-1, ys0:ys0+wys-1] = uch
    endfor
  endif
  tv, under, /true

  if ~keyword_set(no_label) then begin
    xyouts, 0.005, 0.018, time_string(d.x[jj]), color = 'ffffff'xl, /normal, charsize = 1.2
    xyouts, 0.005, 0.060, 'TREx RGB MOSv001 grid', color = 'ffffff'xl, /normal, charsize = 1.2
  endif

  mosaic_image = tvrd(/true)
  if keyword_set(png_out) then begin
    write_png, png_out, mosaic_image
    dprint, dlevel=1, 'srscan_trex_rgb_grid_plot: wrote ' + png_out
  endif

  if keyword_set(zbuffer) then $
    set_plot, (strlowcase(!version.os_family) eq 'windows') ? 'win' : 'x'
end
