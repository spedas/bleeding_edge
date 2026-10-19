;+
;FUNCTION:
;  srscan_trex_rgb_skymap
;
;PURPOSE:
;  Locate, download, and restore the best TREx RGB skymap for a site at a
;  given time (latest validity start at or before the time; see
;  srscan_skymap for the selection rule).
;
;  The returned structure is the native skymap: fields include
;  full_map_latitude/full_map_longitude ([554,481,n_alt] corner grids at
;  the project altitudes), full_elevation/full_azimuth ([553,480]),
;  site_map_latitude/site_map_longitude, generation info, etc.
;
;  NOTE: the arrays are in ARCHIVE orientation; apply
;  srscan_trex_rgb_orient to any array with a pixel-y dimension before
;  combining with ORIENTed images.
;
;INPUT:
;  site: 4-letter site code, e.g. 'gill' (string)
;  time: requested time (double unix time or string)
;
;KEYWORDS:
;  no_download: use only the local cache
;  verbose:     dprint verbosity
;  filename:    (out) local path of the restored skymap file
;
;OUTPUT:
;  the restored skymap structure, or -1 if none could be obtained
;
;EXAMPLE:
;  sky = srscan_trex_rgb_skymap('gill', '2023-03-24')
;  help, sky, /structure
;-
function srscan_trex_rgb_skymap, site, time, $
  no_download = no_download, verbose = verbose, filename = filename

  compile_opt idl2

  cfg = srscan_api_config()
  return, srscan_skymap(cfg.dataset_rgb_skymap, site, time, $
    no_download = no_download, verbose = verbose, filename = filename)
end
