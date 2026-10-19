;+
;srscan_crib_trex_rgb_advanced.pro
;usage:
; .run srscan_crib_trex_rgb_advanced
;
;Purpose: advanced TREx RGB topics -- skymaps and pixel geolocation, raw
; intensity analysis, sub-hour loading and time clipping, offline/cache
; workflows, and configuration.
;
;Written by: Darren Chaddock, 2026-08-18
;-

; ---------- skymaps ----------
; fetch the best skymap for a site/time (latest validity start at or
; before the time). The structure is the native skymap: corner
; grids full_map_latitude/longitude are [554,481,3] at the assumed
; emission heights [90,110,150] km; full_elevation/azimuth are [553,480].
sky = srscan_trex_rgb_skymap('rabb', '2023-03-24', filename=fn)
print, 'skymap file: ', fn
help, sky, /structure
stop

; IMPORTANT: skymap arrays are stored in archive orientation (y increases
; southward). Apply srscan_trex_rgb_orient -- the same transform the
; loaders apply to images -- to anything with a pixel-y dimension before
; combining with loaded data:
elev = srscan_trex_rgb_orient(sky.full_elevation)              ; [553,480]
glat = srscan_trex_rgb_orient(reform(sky.full_map_latitude[*,*,1]))   ; 110 km
glon = srscan_trex_rgb_orient(reform(sky.full_map_longitude[*,*,1]))  ; [554,481]

; overlay elevation contours on an oriented frame: the rings must be
; concentric with the fisheye circle (this is the visual orientation check)
srscan_load_trex_rgb, site='rabb', time='2023-03-24/06:22:30'
get_data, 'srscan_trexrgb_rabb', data=d
window, 0, xsize=553, ysize=480
device, decomposed=1
tv, bytscl(d.y, min=0, max=180), /true
; /noerase + a full-window position draws the contours in image pixel
; coordinates on top of the tv'd frame (tv establishes no coordinate
; system, so /overplot would have nothing to overplot onto)
contour, elev, /noerase, levels=[10,30,50,70], color='c0c0c0'xl, $
  c_labels=[1,1,1,1], position=[0,0,1,1], xstyle=5, ystyle=5
; restore index-color mode for the tplot panels below (with decomposed=1
; left on, tplot's color-table indices are read as 24-bit values)
device, decomposed=0
stop

; ---------- pixel geolocation ----------
; where does pixel (i,j) map at 110 km? (corner grids are [554,481]: cell
; (i,j) is bounded by corners (i:i+1, j:j+1); average the 4 corners for a
; center estimate)
i = 276 & j = 240
print, 'pixel (276,240) center: lat ', mean(glat[i:i+1, j:j+1]), $
  '  lon ', mean(glon[i:i+1, j:j+1])

; inverse: which pixel is nearest a geographic point? NOTE the IDL
; subscript gotcha: arr[scalar, vec, vec] is a CROSS PRODUCT -- for
; element-wise pairing every subscript must be an array, so work on the
; flattened arrays with a computed distance:
target_lat = 58.0 & target_lon = -104.0
dist2 = (glat[0:552, 0:479] - target_lat)^2 + $
  ((glon[0:552, 0:479] - target_lon) * cos(target_lat * !dtor))^2
dummy = min(dist2, kmin, /nan)
ij = array_indices([553, 480], kmin, /dimensions)
print, 'nearest pixel to (58N, 104W): ', ij
print, 'elevation there: ', elev[ij[0], ij[1]]
stop

; ---------- raw intensity analysis ----------
; zenith R/G/B time series across an hour: average a 5x5 patch of pixels
; around zenith per channel. The green/blue ratio tracks precipitating
; electron energy (see the TREx RGB literature).
srscan_load_trex_rgb, site='rabb', trange=['2023-03-24/06:00', '2023-03-24/07:00']
get_data, 'srscan_trexrgb_rabb', data=d
; zenith pixel from the skymap = highest elevation
dummy = max(elev, kzen, /nan)
zij = array_indices([553, 480], kzen, /dimensions)
zi = (zij[0] > 2) < 550 & zj = (zij[1] > 2) < 477
rgbz = fltarr(n_elements(d.x), 3)
for c = 0, 2 do rgbz[*, c] = $
  total(total(d.y[*, c, zi-2:zi+2, zj-2:zj+2], 4), 3) / 25.
store_data, 'trexrgb_rabb_zenith', data={x: d.x, y: rgbz, v: [0,1,2]}, $
  dlimits={colors: [250, 135, 80], labels: ['R','G','B'], labflag: 1, $
  ytitle: 'rabb zenith', ysubtitle: '[counts, 5x5 avg]'}
; the archived keogram for context in the second panel
srscan_load_trex_rgb, site='rabb', datatype='keogram', $
  trange=['2023-03-24/06:00', '2023-03-24/07:00']
timespan, '2023-03-24/06:00', 1, /hours
window, 0, xsize=1100, ysize=600
tplot, ['trexrgb_rabb_zenith', 'srscan_trexrgb_keo_rabb']
stop

; ---------- sub-hour loading / time clipping ----------
; the archive stores raw data in 1-minute files, and the loader fetches
; only the files covering the requested trange, then clips the loaded
; frames to it (standard SPEDAS loader behavior). Therefore, a 100-second
; request costs 3 small files, not a whole hour.
srscan_load_trex_rgb, site='rabb', files=ff, $
  trange=['2023-03-24/06:20:30', '2023-03-24/06:22:10']
get_data, 'srscan_trexrgb_rabb', data=d
print, n_elements(ff), ' file(s) fetched'
print, 'clipped frames span:      ', time_string(minmax(d.x))

; /no_time_clip stores every frame of the fetched files instead; the
; output then aligns to 1-min file boundaries (raw/grid; the archived
; keograms are hourly files, so their unclipped output spans whole hours)
srscan_load_trex_rgb, site='rabb', /no_time_clip, $
  trange=['2023-03-24/06:20:30', '2023-03-24/06:22:10']
get_data, 'srscan_trexrgb_rabb', data=d
print, 'with /no_time_clip spans: ', time_string(minmax(d.x))
stop

; ---------- offline / cache workflows ----------
; downloadonly fetches files into the local cache without loading;
; no_download then loads purely from the cache (field work, planes, ...)
del_data, 'srscan_trexrgb_luck'
srscan_load_trex_rgb, site='luck', time='2023-03-24/06:22:30', /downloadonly
srscan_load_trex_rgb, site='luck', time='2023-03-24/06:22:30', /no_download
tplot_names, 'srscan_trexrgb_luck'

; files= returns the local paths used; it is assigned (not appended) on
; every call, so reusing one variable across calls is safe:
srscan_load_trex_rgb, site='luck', time='2023-03-24/06:22:30', files=ff, /downloadonly
print, 'first call:  ', n_elements(ff), ' file(s)'
srscan_load_trex_rgb, site='luck', time='2023-03-24/06:22:30', files=ff, /downloadonly
print, 'second call: ', n_elements(ff), ' file(s)  (unchanged)'
stop

; ---------- configuration ----------
; the data cache root is !srs_canada.local_data_dir (default
; root_data_dir() + 'srs_canada/', e.g. C:\data\srs_canada). To persist a
; different location:
;   !srs_canada.local_data_dir = 'D:/bigdisk/srs_canada/'
;   srscan_write_config
; and to go back to defaults:
;   srscan_init, /reset
print, 'current local_data_dir: ', !srs_canada.local_data_dir
stop

end
