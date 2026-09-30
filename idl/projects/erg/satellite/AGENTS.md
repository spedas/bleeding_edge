---
related_files:
  - projects/erg/AGENTS.md
  - projects/erg/satellite/erg/common/erg_init.pro
  - projects/erg/satellite/erg/common/erg_graphics_config.pro
  - projects/erg/satellite/erg/common/erg_export_filever.pro
  - projects/erg/satellite/erg/common/erg_version_table.pro
  - projects/erg/satellite/erg/common/set_erg_var_label.pro
  - projects/erg/satellite/erg/common/cotrans/erg_cotrans.pro
  - projects/erg/satellite/erg/common/cotrans/erg_load_att.pro
  - projects/erg/satellite/erg/common/cotrans/erg_interpolate_att.pro
  - projects/erg/satellite/erg/common/cotrans/dsi2j2000.pro
  - projects/erg/satellite/erg/common/cotrans/tmpl_erg_att_l2.sav
  - projects/erg/satellite/erg/mgf/erg_load_mgf.pro
  - projects/erg/satellite/erg/mgf/erg_load_mgf_pre.pro
  - projects/erg/satellite/erg/lepe/erg_load_lepe.pro
  - projects/erg/satellite/erg/particle/erg_mep_part_products.pro
  - projects/erg/satellite/erg/particle/erg_mepe_get_dist.pro
  - projects/erg/satellite/erg/particle/erg_lep_part_products.pro
  - projects/erg/satellite/erg/particle/erg_pgs_make_fac.pro
  - projects/erg/satellite/erg/particle/isee3d
  - projects/erg/satellite/erg/examples/erg_crib_mgf.pro
  - projects/erg/satellite/erg/examples/erg_crib_mepe.pro
  - projects/erg/tools/print_str_maxlet.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/cdf2tplot.pro
  - spedas_gui/isee3d
maintenance: |
  Update when erg_init or the common loader pattern (paths, authentication,
  prefixes) changes, when an instrument folder or loader is added or renamed,
  or when erg_cotrans or the particle-products chain changes.
---

# ERG (Arase) satellite

Loaders, coordinate transforms and particle tools for the Arase spacecraft.
All code is under `erg/`.

## Layout

- `erg/common/`: `erg_init` (sets `!erg`), `erg_graphics_config`,
  `erg_export_filever`/`erg_version_table` (file versions), `set_erg_var_label`
  (orbit labels on the time axis), `overlay_map_sc_ifoot` (footprint maps).
- `erg/common/cotrans/`: `erg_cotrans` and its steps `sga2sgi`, `sgi2dsi`,
  `dsi2j2000`; attitude via `erg_load_att` and `erg_interpolate_att`.
- `erg/mgf/` (magnetometer), `erg/pwe/` (waves: `erg_load_pwe_efd`, `_hfa`,
  `_ofa`, `_wfc`), `erg/orb/` (orbit: `erg_load_orb`, `_l3`, `_predict`).
- `erg/lepe/`, `erg/lepi/`, `erg/mep/`, `erg/hep/`, `erg/xep/`: particles
  (`erg_load_lepe`, `erg_load_lepi_nml`, `erg_load_mepe`, `erg_load_mepi_nml`,
  `erg_load_mepi_tof`, `erg_load_hep`, `erg_load_xep`).
- `erg/particle/`: `erg_<instrument>_get_dist`, `erg_*_part_products` and
  `erg_pgs_*` helpers. `erg/particle/isee3d/`: the ISEE 3D viewer.
- `erg/examples/`: one crib per instrument, e.g. `erg/examples/erg_crib_mgf.pro`.
- `*_pre` loaders (`erg_load_mgf_pre`, `erg_load_mep_pre`, ...) read
  provisional CDFs from `l2pre`-type directories and need credentials.

## How `erg_load_mgf` loads data

1. `erg/mgf/erg_load_mgf.pro` calls `erg_init` (`erg/common/erg_init.pro`),
   which creates `!erg` once: local `root_data_dir()` + `ergsc/` (or
   `$ERG_DATA_DIR`), remote `https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/`
   (or `$ERG_REMOTE_DATA_DIR`).
2. It checks `datatype` (`8sec` default, `64hz`, `128hz`, `256hz`) and `coord`
   (default `sm`), and appends `satellite/erg/mgf/l2/` to the `!erg` dirs.
3. `file_dailynames` builds daily (8 s) or hourly relative paths;
   `spd_download` fetches them with `authentication=2` (HTTP digest) and the
   `uname`/`passwd` keywords.
4. `cdf2tplot` (`general/CDF/cdf2tplot.pro`) stores the variables with
   `prefix='erg_mgf_l2_'`; the loader then `tclip`s fill values.
5. `/get_filever` makes `erg_export_filever` record file versions in the tplot
   variable `erg_load_datalist` (a hash; `erg_version_table` prints it). Last,
   it prints the PI and rules of the road with `print_str_maxlet`
   (`projects/erg/tools/print_str_maxlet.pro`).

Other `erg_load_*` routines follow these steps with their own paths and
prefixes (`erg_<instrument>_<level>_<datatype>_`); LEP-e and PWE/WFC use
`spd_cdf2tplot`.

## Particle products

Load 3-D flux (`erg_load_mepe, datatype='3dflux'` gives
`erg_mepe_l2_3dflux_FEDU`; see `erg/examples/erg_crib_mepe.pro`), then call
`erg_mep_part_products` with `outputs` (`energy`, `phi`, `theta`, `pa`, `gyro`,
`moments`). It calls `erg_mepe_get_dist` per time and the shared `spd_pgs_*`
routines. `pa`, `gyro` and `moments` need `mag_name` (normally
`erg_mgf_l2_mag_8sec_dsi`) and `pos_name`; `erg_pgs_make_fac` uses
`erg_cotrans`. `erg_lep_part_products` handles LEP-e and LEP-i;
`erg_lepe_part_products` and `erg_lepi_part_products` are one-instrument versions.

## Things to know

- SGA and SGI spin with the spacecraft; DSI is despun. `erg_cotrans` chains
  SGA - SGI - DSI - J2000, taking the system from the last `_xxx` of the tplot
  name; use the general `cotrans` from J2000 to GSE/GSM.
- Unless `/noload`, `erg_cotrans` downloads attitude (`erg_load_att`, text
  files read with the template `erg/common/cotrans/tmpl_erg_att_l2.sav`) when
  the `erg_att_*` variables don't cover the input, and for DSI-J2000
  (`erg/common/cotrans/dsi2j2000.pro`) orbit data for the current `timespan`.
- `erg_load_lepe` sorts LEP-e energies in ascending order (true order in
  `FEDU_Energy`) and renames version-5 lower-case variables to the older names
  (`FEDU`, `FEDO`, `Count_Rate`).
- `erg/particle/isee3d/` also exists, slightly different, as `spedas_gui/isee3d/`.
