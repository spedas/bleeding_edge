;+
;srscan_crib_trex_rgb.pro
;usage:
; .run srscan_crib_trex_rgb
;
;Purpose: demonstrate loading and displaying data from the TREx RGB
; (Transition Region Explorer) full-colour all-sky imager array.
;
; TREx RGB data is loaded from the UCalgary Space Remote Sensing (SRS)
; Open Science Platform, located at https://data.phys.ucalgary.ca.
;
; Datatypes:
;   'raw'     stream0 color raw images (byte [n,3,553,480], 3s cadence)
;   'keogram' archived hourly keograms (lossy JPEG quicklooks, intensity pre-scaled)
;   'grid'    pre-rendered mosaic grids (selected intervals only)
;
; Routing downloads through an HTTP proxy is supported. To use this, set
; the standard SPEDAS http_proxy environment variable before loading, e.g.
;   setenv, 'http_proxy=http://proxy.example.org:3128'
;
;Written by: Darren Chaddock, 2026-08-18
;-

; the night of 2023-03-23/24 was a strong storm with aurora at all TREx RGB sites
timespan, '2023-03-24', 1, /day

; load keograms for all available stations
;
; NOTE: the archived TREx RGB keograms are lossy JPEG quicklook products.
; The DN values carry compression artifacts and already-applied display scaling,
; allowing them to be ideal only for browsing. For quantitative work, we recommend
; building a keogram from the raw images (demonstrated at the end of this crib).
srscan_load_trex_rgb, datatype='keogram', /verbose
print, 'Data exists for the following stations: '
tplot_names, 'srscan_trexrgb_keo_*'
stop

; every loaded variable carries the dataset metadata -- PI, attribution,
; rules of use, and the citation DOI -- in dlimits.cdf.gatt, mirroring
; the global attributes of an ISTP-compliant CDF
get_data, 'srscan_trexrgb_keo_pina', dlimits=dl
help, dl.cdf.gatt, /structure
print, 'dataset DOI: ', dl.cdf.gatt.doi
stop

; plot keograms of a few stations for the full day
window, 0, xsize=1100, ysize=850
zlim, 'srscan_trexrgb_keo_*', 0, 255
tplot_options, 'title', 'TREx RGB keogram examples'
tplot, ['srscan_trexrgb_keo_pina', 'srscan_trexrgb_keo_rabb', 'srscan_trexrgb_keo_yknf']
stop

; zoom into the keogram
timespan, '2023-03-24/04:00:00', 4, /hours
tplot, ['srscan_trexrgb_keo_pina', 'srscan_trexrgb_keo_rabb', 'srscan_trexrgb_keo_yknf'], $
  title='Zoom'
stop

; brighten a keogram further with zlim
;
; we apply linear DN scaling (display only, the stored DN values are
; untouched), with the same adjustment applied to all three channels
; so the colour balance is preserved
copy_data, 'srscan_trexrgb_keo_yknf', 'srscan_trexrgb_keo_yknf_bright'
zlim, 'srscan_trexrgb_keo_yknf_bright', 0, 120
tplot, ['srscan_trexrgb_keo_yknf', 'srscan_trexrgb_keo_yknf_bright'], $
  title='default pre-applied scaling (top) vs further brightened zlim (bottom)'
stop

; load 10 minutes of full-resolution images for Rabbit Lake
;
; only the 1-min archive files covering the requested range are
; downloaded and read, and the loaded frames are clipped to the range --
; this 10-minute request fetches 10 files, not the whole hour (set
; /no_time_clip for whole-file output; see the advanced crib for example).
;
; MEMORY NOTE: raw TREx RGB data can be >1GB per site-hour; load short
; windows like this, or single frames with time=
timespan, '2023-03-24', 1, /day
srscan_load_trex_rgb, site='rabb', trange=['2023-03-24/06:20', '2023-03-24/06:30']
tplot_names, 'srscan_trexrgb_rabb'
stop

; display a single frame: y[i,*,*,*] is [3,553,480]. Images are oriented north-up
; and east-right, ready for tv,/true
get_data, 'srscan_trexrgb_rabb', data=d
window, 1, xsize=553, ysize=480
device, decomposed=1
dummy = min(abs(d.x - time_double('2023-03-24/06:22:30')), index)
tv, bytscl(reform(d.y[index,*,*,*]), min=15, max=120), /true
xyouts, 10, 10, 'srscan_trexrgb_rabb  ' + time_string(d.x[index]), /device, $
  color='ffffff'xl
device, decomposed=0  ; restore index-color mode
stop

; single-time load across ALL sites
srscan_load_trex_rgb, time='2023-03-24/06:22:30'
tplot_names, 'srscan_trexrgb_????'
stop

; build a keogram from the raw images and compare with the quicklook keogram
; for the same interval
;
; NOTE: since the quicklook keogram has brightening applied to it already, we use
; the same scaling parameters for the raw images version of the keogram so they
; match; min=15, max=120.
srscan_load_trex_rgb, site='rabb', trange=['2023-03-24/07:00', '2023-03-24/08:00']
srscan_asi_keogram, 'srscan_trexrgb_rabb'
zlim, 'srscan_trexrgb_rabb_keo', 15, 120
timespan, '2023-03-24/07:00', 1, /hours
window, 0, xsize=1100, ysize=850
tplot, ['srscan_trexrgb_rabb_keo', 'srscan_trexrgb_keo_rabb'], $
  title='raw-built (top) vs archived quicklook (bottom)'
stop

end
