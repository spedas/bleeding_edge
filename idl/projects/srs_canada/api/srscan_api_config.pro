;+
;FUNCTION:
;  srscan_api_config
;
;PURPOSE:
;  Central configuration for the srs_canada data loading path. All
;  dataset names, endpoints, and cache conventions used by the srscan_*
;  routines live here so that product/dataset changes are one-line edits.
;
;  The API base URL can be overridden with the SRSCAN_API_URL
;  environment variable (useful for testing against staging servers);
;  the HAPI server URL (hapi_url) follows the same host.
;
;OUTPUT:
;  Structure of configuration constants.
;
;NOTES:
;  Data documentation: https://data.phys.ucalgary.ca
;  API documentation:  https://api.phys.ucalgary.ca
;
;  Data files are cached under !srs_canada.local_data_dir + <DATASET_NAME>,
;  mirroring the archive tree below each dataset's data_tree_url.
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-10-14 09:44:38 -0700 (Wed, 14 Oct 2026) $
; $LastChangedRevision: 34972 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/srs_canada/api/srscan_api_config.pro $
;-
function srscan_api_config

  compile_opt idl2

  api_host = getenv('SRSCAN_API_URL')
  if api_host eq '' then api_host = 'api.phys.ucalgary.ca'
  ; allow the env var to be specified with a scheme prefix
  api_host = (api_host.replace('https://', '')).replace('http://', '')

  return, { $
    api_host: api_host, $
    urls_endpoint: 'api/v1/data_distribution/urls', $
    user_agent: 'spedas-srs-canada/1.0', $
    ; HAPI server (HAPI 3.x, csv/binary/json) for the riometer time
    ; series: NORSTAR_RIOMETER_K0/K2@<SITE> and SWAN_HSR_K0@<SITE>. Load
    ; with the generic SPEDAS client, e.g.
    ;   hapi_load_data, server=(srscan_api_config()).hapi_url, $
    ;     dataset='NORSTAR_RIOMETER_K2@GILL', trange=tr, prefix='gill_'
    hapi_url: 'https://' + api_host + '/hapi', $
    ; TREx RGB (Transition Region Explorer, color imagers) datasets.
    ; Raw is 1-min HDF5 files at nominal 3-s cadence (20 [3,553,480] byte
    ; frames per file). Burst (stream0.burst) and the early legacy-PGM era
    ; are deliberately not supported here.
    ; NOTE: the archived hourly keograms are lossy JPEG quicklook products
    ; (display DN, not photometric); srscan_trex_rgb_load_keogram labels
    ; them accordingly in the variable metadata.
    dataset_rgb_raw: 'TREX_RGB_RAW_NOMINAL', $
    dataset_rgb_keogram: 'TREX_RGB_HOURLY_KEOGRAM', $
    dataset_rgb_skymap: 'TREX_RGB_SKYMAP_IDLSAV', $
    ; pre-rendered global mosaic grids (1024x512 lon x lat, 0.3515625
    ; deg/cell, fill -999); produced only for selected intervals
    dataset_rgb_grid: 'TREX_RGB_GRID_MOSV001' $
  }
end
