;+
;srscan_crib_trex_rgb_mosaic.pro
;usage:
; .run srscan_crib_trex_rgb_mosaic
;
;Purpose: demonstrate TREx RGB mosaics.
;
; srscan_trex_rgb_mosaic projects each camera's frame onto a geographic
; map through its skymap (110 km assumed emission height) and paints in
; 24-bit decomposed colour. Where fields of view overlap, the camera viewing
; that patch of sky at the higher elevation angle (closer to its zenith,
; i.e. less obliquely) wins. Therefore, near-horizon views are stretched
; and smeared, so the least-distorted view paints on top.
;
; The MOSv001 grid product is the verified archive mosaic rendering of the
; same data. More information can be found in the TREx RGB dataset description
; at https://data.phys.ucalgary.ca.
;
;Written by: Darren Chaddock, 2026-08-18
;-

; load data for a timestamp of all sites during 2023-03-24 storm
srscan_load_trex_rgb, time='2023-03-24/06:22:30'
tplot_names, 'srscan_trexrgb_????'
stop

; plot mosaic for all instruments
;
; NOTE: with no minval/maxval set, each site's image is auto-scaled
; INDEPENDENTLY (anchored at that site's median illuminated brightness),
; so brightness is not comparable between sites. We recommend setting
; minval/maxval to scale all sites with one common window (see next example).
srscan_trex_rgb_mosaic, '2023-03-24/06:22:30', /verbose
stop

; explicit intensity scaling
;
; a linear scaling window, applied identically to all three channels (to preserve
; colour balance)
srscan_trex_rgb_mosaic, '2023-03-24/06:22:30', minval=15, maxval=120
stop

; subset of sites, recentered and zoomed, and a higher minimum elevation (trims
; the distorted low-elevation pixels)
;
;
; NOTE: map_set's scale= is a physical scale interpreted through the display's
; pixels-per-cm, so the framing varies a little with monitor DPI. Adjust
; scale to taste.
srscan_trex_rgb_mosaic, '2023-03-24/06:22:30', sites=['rabb', 'luck'], $
  central_lat=55, central_lon=-105.5, scale=1.4e7, minimum_elevation=15
stop

; exclude a site instead (gill was overcast this night)
srscan_trex_rgb_mosaic, '2023-03-24/06:22:30', exclude='gill'
stop

; z-buffer + PNG output works headless (no window pops up), and the rendered
; image also comes back in mosaic_image ([3,xsize,ysize])
srscan_trex_rgb_mosaic, '2023-03-24/06:22:30', /zbuffer, $
  png_out='trex_rgb_mosaic_20230324_062230.png', mosaic_image=mimg
help, mimg
stop

; the verified pre-generated mosaic rendering:
;   load the MOSv001 grid for the same frame and plot it
;   geometry and colours should agree with our mosaic
;
; for more information about the gridded data, see the TREx RGB dataset
; description at https://data.phys.ucalgary.ca
srscan_load_trex_rgb, datatype='grid', time='2023-03-24/06:22:30'
srscan_trex_rgb_grid_plot, '2023-03-24/06:22:30', scale=4e7
stop

end
