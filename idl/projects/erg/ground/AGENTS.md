---
related_files:
  - projects/erg/AGENTS.md
  - projects/iugonet/AGENTS.md
  - projects/erg/ground/geomag/erg_load_gmag_isee_fluxgate.pro
  - projects/erg/ground/geomag/erg_load_gmag_nipr.pro
  - projects/erg/ground/geomag/erg_load_gmag_magdas_1sec.pro
  - projects/erg/ground/geomag/erg_load_gmag_stel_fluxgate.pro
  - projects/erg/ground/camera/erg_load_camera_omti_asi.pro
  - projects/erg/ground/radar/superdarn/erg_load_sdfit.pro
  - projects/erg/ground/radar/superdarn/sd_init.pro
  - projects/erg/ground/radar/superdarn/sd_map_set.pro
  - projects/erg/ground/radar/superdarn/overlay_map_sdfit.pro
  - projects/erg/ground/radar/superdarn/loadct_sd.pro
  - projects/erg/ground/radar/superdarn/splitbeam.pro
  - projects/erg/ground/radar/superdarn/sd_world_data
  - projects/erg/ground/radar/superdarn/sdaacgmlib/aacgmfindcoeffile.pro
  - projects/erg/ground/radar/superdarn/sdfovlib/overlay_map_precal_sdfov.pro
  - projects/erg/examples/erg_crib_superdarn.pro
  - projects/erg/examples/erg_crib_gmag_isee_fluxgate.pro
  - projects/iugonet/plot/map2d/map2d_init.pro
  - projects/iugonet/load/iug_load_gmag_nipr.pro
  - general/misc/ssl_check_valid_name.pro
  - general/misc/root_data_dir.pro
  - general/CDF/cdf2tplot.pro
  - general/cotrans/aacgm/aacgmidl.pro
maintenance: |
  Update when a ground loader is added, renamed or turned into an alias, when
  the ground loaders start using !erg, or when SuperDARN plotting stops
  depending on map2d or changes its data tables.
---

# ERG-SC ground data

Loaders and plotting for the ground networks that ERG-SC (ISEE, Nagoya
University) distributes as CDF: magnetometers, OMTI all-sky imagers, a
riometer, VLF receivers and SuperDARN radars.

## Layout

- `geomag/`: `erg_load_gmag_isee_fluxgate`, `erg_load_gmag_isee_induction`
  (response correction in `isee_induction_cal_resp`), `erg_load_gmag_mm210`,
  `erg_load_gmag_magdas_1sec`, `erg_load_gmag_nipr`. The `_stel_` loaders are
  old names that call the `_isee_` ones.
- `camera/`: `erg_load_camera_omti_asi` plus OMTI image tools: absolute
  intensity (`tabsint`), star removal, mapping to geographic coordinates
  (`tasi2gmap`, `plot_omti_gmap`), keograms (`keogram_image`).
- `riometer/`: `erg_load_isee_brio`. `vlf/`: `erg_load_isee_vlf`.
- `radar/superdarn/`: `erg_load_sdfit` (fitacf CDF), `sd_init`, map plots
  (`sd_map_set`, `overlay_map_sdfit`, `overlay_map_sdfov`,
  `overlay_map_coast`), and tplot tools (`splitbeam`, `set_coords`,
  `get_sd_ave`, `get_sd_vlshell`, `get_fixed_pixel_graph`).
  - `sdaacgmlib/`: AACGM conversions (`aacgmconvcoord`, `aacgmmlt`).
  - `sdfovlib/`: `overlay_map_precal_sdfov` and precomputed radar
    field-of-view tables (`sdfovtbl_<radar>.sav`).
  - `col_tbl/`: color tables for `loadct_sd`; `sd_world_data`: coastlines.
- Cribs are in `projects/erg/examples/`, e.g.
  `projects/erg/examples/erg_crib_superdarn.pro`.

## How `erg_load_gmag_isee_fluxgate` loads data

1. `geomag/erg_load_gmag_isee_fluxgate.pro` checks `site` and `datatype`
   (`64hz`, `1sec`, `1min`, `1h`) with `ssl_check_valid_name`
   (`general/misc/ssl_check_valid_name.pro`); both default to `'all'`.
2. It fills a `file_retrieve(/struct)` source with the local directory
   `root_data_dir()` + `ergsc/` and the remote
   `https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/`, both hard-coded.
3. `file_dailynames` builds paths under `ground/geomag/isee/fluxgate/`
   (hourly files for 64 Hz, daily otherwise) and `spd_download` fetches them.
4. `cdf2tplot` (`general/CDF/cdf2tplot.pro`) loads them with
   `prefix='isee_fluxgate_'`; the loader renames the result to
   `isee_fluxgate_mag_<site>_<res>_hdz`, clips fill values, and prints the PI
   and data policy from the CDF attributes.

Other loaders follow the same steps. tplot names start with the network:
`isee_induction_`, `mm210_`, `magdas_`, `omti_asi_<site>_<wavelength>_`,
`isee_vlf_<site>_`, `sd_<radar>_` (e.g. `sd_hok_vlos_bothscat_1`).

## Things to know

- These loaders don't call `erg_init` and ignore `!erg` and `$ERG_DATA_DIR`.
  `erg_load_gmag_magdas_1sec` looks at `!erg` if it exists but still ends
  up with the same hard-coded directories.
- IUGONET calls these loaders through aliases (`iug_load_gmag_mm210` and
  others), and `erg_load_gmag_nipr` only forwards to `iug_load_gmag_nipr`
  (`projects/iugonet/load/iug_load_gmag_nipr.pro`). See
  `projects/iugonet/AGENTS.md`.
- SuperDARN plotting needs IUGONET's map library: `sd_init` calls `map2d_init`
  (`projects/iugonet/plot/map2d/map2d_init.pro`), and `sd_time`,
  `sd_map_set` and `overlay_map_sdfit` read and set `!map2d` (time and
  geographic/AACGM flag). `sd_init` also creates `!sdarn` (remote directory,
  AACGM coefficient files that `sdaacgmlib/aacgmfindcoeffile.pro` finds next
  to `general/cotrans/aacgm/aacgmidl.pro`).
- `erg_load_sdfit` also stores pixel positions (`sd_<radar>_position_tbl_<n>`),
  which the map routines read; `splitbeam` (`radar/superdarn/splitbeam.pro`)
  makes one variable per beam (`..._azim04`).
