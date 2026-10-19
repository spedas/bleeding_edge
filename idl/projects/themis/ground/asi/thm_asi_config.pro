;+
;FUNCTION:
;  thm_asi_config
;
;PURPOSE:
;  Central configuration for the THEMIS ASI and REGO data loading path.
;  All dataset names, endpoints, and cache conventions used by the
;  thm_asi_* routines live here so that product/dataset changes are
;  one-line edits.
;
;  The API base URL can be overridden with the THM_ASI_API_URL
;  environment variable (useful for testing against staging servers).
;
;OUTPUT:
;  Structure of configuration constants.
;
;NOTES:
;  Data documentation: https://data.phys.ucalgary.ca
;  API documentation:  https://api.phys.ucalgary.ca
;
;  Data files are cached under !themis.local_data_dir + 'thg/asi/' +
;  <DATASET_NAME>, mirroring the archive tree below each dataset's
;  data_tree_url. Caches from before the 2026-08 rename (thg/ucalgary/)
;  are migrated automatically on first use.
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-10-14 09:46:28 -0700 (Wed, 14 Oct 2026) $
; $LastChangedRevision: 34973 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi/thm_asi_config.pro $
;-

; one-time migration of caches from before the 2026-08 rename: files under
; thg/ucalgary/ move to thg/asi/ so nothing has to be re-downloaded.
; Checked once per session (and it is a single cheap file_test after the
; migration has happened once).
pro thm_asi_config_migrate_cache
  compile_opt idl2, hidden
  common thm_asi_config_migrate, checked
  if keyword_set(checked) then return
  checked = 1
  defsysv, '!themis', exists = exists
  if ~keyword_set(exists) then return
  old_root = !themis.local_data_dir + 'thg' + path_sep() + 'ucalgary'
  if ~file_test(old_root, /directory) then return
  new_root = !themis.local_data_dir + 'thg' + path_sep() + 'asi'
  file_mkdir, new_root
  children = file_search(old_root + path_sep() + '*', /mark_directory, count = nc)
  moved = 0
  for i = 0, nc - 1 do begin
    base = file_basename(children[i])
    target = new_root + path_sep() + base
    if file_test(target) then continue   ; already present in the new tree
    file_move, children[i], target
    moved += 1
  endfor
  ; remove the old root if everything moved out
  leftover = file_search(old_root + path_sep() + '*', count = nleft)
  if nleft eq 0 then file_delete, old_root, /quiet
  if moved gt 0 then dprint, dlevel=1, 'thm_asi_config: migrated ' + $
    strtrim(moved, 2) + ' cache item(s) from thg' + path_sep() + 'ucalgary to ' + new_root
end

function thm_asi_config

  compile_opt idl2

  thm_asi_config_migrate_cache

  api_host = getenv('THM_ASI_API_URL')
  if api_host eq '' then api_host = 'api.phys.ucalgary.ca'
  ; allow the env var to be specified with a scheme prefix
  api_host = (api_host.replace('https://', '')).replace('http://', '')

  return, { $
    api_host: api_host, $
    urls_endpoint: 'api/v1/data_distribution/urls', $
    user_agent: 'spedas-thm-asi/1.0', $
    cache_subdir: 'thg' + path_sep() + 'asi' + path_sep(), $   ; below !themis.local_data_dir
    ; THEMIS ASI dataset names on the data archive (data.phys.ucalgary.ca).
    ; NOTE: ast uses THEMIS_ASI_VEC1024, not THEMIS_ASI_THUMB32 -- the
    ; legacy Berkeley ast CDFs contain the 1024-superpixel *bin* product
    ; (which pairs with the thg_ast_* [4,1024] bin-corner calibration),
    ; and vec1024 is that same product (verified: correlation 0.99+ with
    ; legacy ast, legacy ~ 33x the byte values). THUMB32 is a raster
    ; downsample with different geometry and would break /thumb mosaics.
    ; NOTE: ask keograms are stitched from the archived HOURLY keogram
    ; product (600 columns/hour = 6-s cadence; the legacy Berkeley CDFs
    ; carried one column per 3-s frame -- visually equivalent, values not
    ; byte-identical; the default Berkeley CDF path gives exact legacy
    ; values).
    dataset_asf: 'THEMIS_ASI_RAW', $
    dataset_ast: 'THEMIS_ASI_VEC1024', $
    dataset_ask: 'THEMIS_ASI_HOURLY_KEOGRAM_PGM', $
    dataset_skymap: 'THEMIS_ASI_SKYMAP_IDLSAV', $
    ; static aux file for thm_asi_merge_mosaic (all-pairs camera blending
    ; weights, ~302 MB, one-time download; previously on Berkeley)
    url_true_weights: 'https://data.phys.ucalgary.ca/sort_by_project/THEMIS/asi/skymaps/z_spedas/true_weights_new.sav', $
    ; REGO (Redline Geospace Observatory) datasets. REGO raw is 512x512
    ; uint16 at 3-s cadence (20 frames per 1-min pgm.gz). Archived hourly
    ; keograms are 1200 columns/hour = full 3-s cadence; the 16-bit
    ; grayscale PNG container is used because it covers the WHOLE mission
    ; (the PGM twin only exists from ~Oct 2016, and where both exist they
    ; are bit-identical modulo row order -- verified).
    ; NOTE: the REGO keogram products are display-scaled, not counts (the
    ; THEMIS keogram products ARE counts). The generator maps a fixed count
    ; window onto the 16-bit container and clips outside it:
    ;   archived = round((counts - 280) * 65535/1030.7), clipped to 0..65535
    ; (pinned against REGO_RAW; one-to-one inside the window). The same
    ; scaling is used for every site and every date in the dataset, so no
    ; per-file scale factor has to be tracked. thm_asi_load_ask
    ; labels the values 'scaled_counts' and warns at load; the default
    ; Berkeley CDF path gives counts.
    dataset_rego_raw: 'REGO_RAW', $
    dataset_rego_ask: 'REGO_HOURLY_KEOGRAM_PNG', $
    dataset_rego_skymap: 'REGO_SKYMAP_IDLSAV' $
  }
end
