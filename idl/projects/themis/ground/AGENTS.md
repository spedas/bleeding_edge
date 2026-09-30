---
related_files:
  - projects/themis/AGENTS.md
  - projects/themis/ground/thm_load_gmag.pro
  - projects/themis/ground/thm_load_greenland_gmag.pro
  - projects/themis/ground/thm_load_carisma_gmag.pro
  - projects/themis/ground/thm_load_bas_gmag.pro
  - projects/themis/ground/thm_load_variometer_gmag.pro
  - projects/themis/ground/thm_load_gmag_networks.pro
  - projects/themis/ground/gmag_stations.txt
  - projects/themis/ground/thm_gmag_stations.pro
  - projects/themis/ground/GMAG-Station-Code-19700101.txt
  - projects/themis/ground/thm_asi_stations.pro
  - projects/themis/ground/thm_load_asi.pro
  - projects/themis/ground/thm_load_asi_cal.pro
  - projects/themis/ground/thm_load_ask.pro
  - projects/themis/ground/thm_load_rego.pro
  - projects/themis/ground/thm_asi_create_mosaic.pro
  - projects/themis/ground/thm_rego_create_mosaic.pro
  - projects/themis/ground/thm_asi_merge_mosaic.pro
  - projects/themis/ground/asi_mosaic/thm_mosaic_array.pro
  - projects/themis/ground/asi_mosaic/thm_map_set.pro
  - projects/themis/ground/asi_mosaic/thm_map_add.pro
  - projects/themis/ground/asi_mosaic/thm_map_add.sav
  - projects/themis/ground/thm_make_ae.pro
  - projects/themis/ground/thm_load_pseudoae.pro
  - projects/themis/ground/thm_gmag_stackplot.pro
  - projects/themis/ground/test_ask_cal2.pro
  - projects/themis/common/thm_load_xxx.pro
  - projects/bas/bas_init.pro
  - projects/themis/spedas_plugin/load_data/thm_ui_load_data_file_obs_sel.pro
  - projects/themis/examples/basic/thm_crib_gmag.pro
  - projects/themis/examples/basic/thm_crib_asi.pro
  - projects/themis/examples/advanced/thm_crib_gmag_locations.pro
  - projects/themis/examples/advanced/thm_crib_greenland_gmag.pro
  - projects/themis/examples/advanced/thm_crib_maccs_gmag.pro
  - projects/themis/examples/advanced/thm_crib_gmag_wavelet.pro
maintenance: |
  Update when a magnetometer network, data server or station list file is added
  or changed, when thm_load_gmag dispatches sites differently, or when the ASI,
  ASK, REGO or mosaic loaders change their paths or calibration source.
---

# THEMIS ground-based observatories (IDL)

Ground magnetometers (THEMIS GBO/EPO sites and many partner networks) and the
THEMIS all-sky imagers (ASI), keograms (ASK) and REGO imagers, plus station
lists, mosaics and pseudo-AE indices. Variables are prefixed `thg_`.

## Layout

- `thm_load_gmag.pro`: the magnetometer entry point. Network-specific loaders
  it calls: `thm_load_greenland_gmag.pro` (DTU/TGO), `thm_load_carisma_gmag.pro`,
  `thm_load_bas_gmag.pro`, `thm_load_variometer_gmag.pro`.
- Station lists: `gmag_stations.txt` (`|`-separated network and site codes
  and names) read by `thm_load_gmag_networks.pro`;
  `GMAG-Station-Code-19700101.txt` (locations, magnetic coordinates, midnight,
  conjugate points) read by `thm_gmag_stations.pro`; `thm_asi_stations.pro`
  has ASI sites in code. No code reads the `THEMIS_GMAG_Station_List_*.xlsx`
  spreadsheets.
- Imagers: `thm_load_asi.pro` (`asf` full images in hourly files, `ast`
  thumbnails in daily files), `thm_load_asi_cal.pro` (pointing and mapping),
  `thm_load_ask.pro` (keograms, all sites in one daily file; `/rego` for
  REGO), `thm_load_rego.pro`.
- Mosaics: `thm_asi_create_mosaic.pro`, `thm_rego_create_mosaic.pro`,
  `thm_asi_merge_mosaic.pro`; helpers in `asi_mosaic/` (`thm_mosaic_array.pro`
  loads images and cal data, `thm_map_set.pro` and `thm_map_add.pro` draw maps;
  `thm_map_add.pro` restores `asi_mosaic/thm_map_add.sav`).
- Indices: `thm_make_ae.pro` computes pseudo AE/AL/AU from loaded
  `thg_mag_*` variables; `thm_load_pseudoae.pro` loads precomputed ones.
- Plotting: `thm_gmag_stackplot.pro` and other `thm_*gmag*`/`*stackplot*` files.
- `test_ask_cal2.pro`: manual check of ASK calibration file versions.

## How thm_load_gmag works

1. Site names come from `site`, or from network keywords (`/thm_sites`,
   `/carisma_sites`, `/fmi_sites`, `/usgs_sites`, ...) that append that
   network's codes. The valid site lists are hard-coded in the routine.
2. Sites are split by network and dispatched: Greenland, CARISMA, BAS and
   variometer sites go to their loaders; all others go to `thm_load_xxx`
   (`projects/themis/common/thm_load_xxx.pro`) with `type_sname='site'`,
   giving `thg/l2/mag/<site>/YYYY/thg_l2_mag_<site>_YYYYMMDD_v01.cdf`.
3. `thm_load_gmag_post` sets labels and can subtract the average or median
   (`/subtract_average`, `/subtract_median`).

## Things to know

- Output variables are `thg_mag_<site>` with H, D, Z components in nT. AARI
  stations (`variation_site` in `thm_load_gmag.pro`) give only variations and
  are labeled dH, dD, dZ. Variometer sites also have `_100ms` 10 Hz versions.
- Servers differ by network: most sites use `!themis`; CARISMA switches
  `remote_data_dir` to its own server and stores files under
  `thg/CARISMA/`; BAS reads daily ASCII files through `!bas`
  (`projects/bas/bas_init.pro`); Greenland files sit under
  `thg/greenland_gmag/l2/`.
- Site lists are duplicated: the network loaders keep their own lists, and a
  comment in `thm_load_carisma_gmag.pro` asks that both be updated together.
  The GUI plugin reads `gmag_stations.txt` instead
  (`projects/themis/spedas_plugin/load_data/thm_ui_load_data_file_obs_sel.pro`).
- ASI paths: `thg/l1/asi/<site>/YYYY/MM/`; calibration: `thg/l2/asi/cal/`
  (`thg_l2_asc_<site>_*` or `rego_l2_asc_*`); REGO files use the `clg_`
  prefix under `thg/l1/reg/`.
- `thm_asi_create_mosaic` looks for an optional `midnight.sav` in the current
  directory for magnetic midnight lines.

## Examples

`projects/themis/examples/basic/`: `thm_crib_gmag.pro`, `thm_crib_asi.pro`;
`projects/themis/examples/advanced/`: `thm_crib_gmag_locations.pro`,
`thm_crib_greenland_gmag.pro`, `thm_crib_maccs_gmag.pro`,
`thm_crib_gmag_wavelet.pro`.
