---
related_files:
  - projects/AGENTS.md
  - projects/barrel/README.txt
  - projects/barrel/barrel_load_data.pro
  - projects/barrel/barrel_preload_actions.pro
  - projects/barrel/barrel_load_fspc.pro
  - projects/barrel/barrel_load_mspc.pro
  - projects/barrel/barrel_load_sspc.pro
  - projects/barrel/barrel_load_magn.pro
  - projects/barrel/barrel_load_ephm.pro
  - projects/barrel/barrel_init.pro
  - projects/barrel/barrel_read_config.pro
  - projects/barrel/barrel_write_config.pro
  - projects/barrel/barrel_config_filedir.pro
  - projects/barrel/barrel_crib_basic_usage.pro
  - projects/barrel/brl_makeedges.pro
  - projects/barrel/brl_makebkgd.pro
  - projects/barrel/barrel_sp_v3.7/barrel_spectroscopy.pro
  - projects/barrel/barrel_sp_v3.7/barrel_spectroscopy_crib.pro
  - projects/barrel/barrel_sp_v3.7/barrel_find_file.pro
  - projects/barrel/spedas_plugin/barrel_ui_load_data.pro
  - projects/barrel/spedas_plugin/barrel_ui_import_data.pro
  - projects/barrel/spedas_plugin/barrel_fileconfig.pro
  - spedas_gui/plugins/barrel_plugin.txt
  - general/misc/file_dailynames.pro
  - general/misc/file_retrieve.pro
  - general/CDF/cdf2tplot.pro
maintenance: |
  Update when the payload list, default data version or file layout in
  barrel_preload_actions changes, when a datatype loader is added, or when the
  spectroscopy package in barrel_sp_v3.7/ is replaced by a new version.
---

# BARREL (IDL)

BARREL (Balloon Array for RBSP Relativistic Electron Losses) flew X-ray
balloon payloads in several campaigns (launch-order IDs 1xx to 4xx). This
folder loads their CDFs (X-ray spectra, magnetometer, GPS ephemeris,
housekeeping) and has a separate package for spectral fitting.

## Layout

- `barrel_load_data.pro`: the entry point; it calls one loader per datatype:
  `barrel_load_fspc.pro`, `barrel_load_mspc.pro`, `barrel_load_sspc.pro`
  (fast, medium and slow spectra), `barrel_load_magn.pro`,
  `barrel_load_ephm.pro`, plus `hkpg`, `misc` and `rcnt` loaders.
- `barrel_preload_actions.pro`: the shared download-and-read step every
  datatype loader calls first.
- `barrel_init.pro`: sets `!barrel`; `barrel_read_config.pro`,
  `barrel_write_config.pro`, `barrel_config_filedir.pro` keep the saved config.
- `brl_*.pro`: calibration helpers; `brl_makeedges.pro` gives the energy-bin
  edges used when L1 spectra are converted, `brl_makebkgd.pro` a background
  model.
- `barrel_sp_v3.7/`: the spectroscopy package (`barrel_sp_v3.7/barrel_spectroscopy.pro`
  and its crib), with response tables in `dbase/`.
- `spedas_plugin/`: GUI tab and config panel, registered by
  `spedas_gui/plugins/barrel_plugin.txt`.
- `README.txt`: 2013 usage notes; some examples in it predate the current
  variable names.

## How `barrel_load_data` works

1. `barrel_load_data` expands `datatype` aliases (`'MAG'` for `MAGN`,
   `'SPECTRUM'` for all three spectra, `'ALL'`, ...) and calls each
   `barrel_load_<type>` it needs. `version` defaults to `'v05'`.
2. Each loader calls `barrel_preload_actions`, which runs `barrel_init`,
   matches `probe` against the payload table in the file (launch-order IDs
   such as `'101'`, or build IDs such as `'1D'`), and builds paths
   `<version>/<level>/<ID>/<yyMMDD>/bar_<ID>_<level>_<type>_YYYYMMDD_<version>.cdf`
   with `file_dailynames` (`general/misc/file_dailynames.pro`).
3. `file_retrieve` (`general/misc/file_retrieve.pro`) downloads them with
   the `!barrel` settings, and `cdf2tplot` (`general/CDF/cdf2tplot.pro`)
   stores them with prefix `brl<ID>_`, for example `brl1D_FSPC3` or
   `brl1D_MAG_X`.
4. The datatype loader then post-processes: FSPC sums `FSPC1a/b/c` into
   `FSPC1`, and with `/convert_l1_to_physical_units` L1 counts are converted
   (for example a `brl<ID>_Total` field magnitude from the magnetometer, or
   spectra binned with `brl_makeedges`).

## Things to know

- `level` defaults to `'l2'`; L1 data need the conversion keyword to get
  physical units.
- `!barrel` is a `file_retrieve` structure; on first use without a saved
  config, `barrel_init` writes one (server
  `http://barreldata.ucsc.edu/data_products/`, local `root_data_dir()` +
  `barrel/`). It re-initializes only when `!barrel` is missing or with `/reset`.
- The payload table in `barrel_preload_actions.pro` must list a payload before
  it can be loaded.
- `barrel_find_file` (`barrel_sp_v3.7/barrel_find_file.pro`) finds the
  spectroscopy response tables by searching `!PATH` for a folder whose name
  contains `barrel_sp_v3.7`, so that folder and `dbase/` must stay on the path
  and keep their names.

## Examples

`barrel_crib_basic_usage.pro` (loading and plotting) and
`barrel_sp_v3.7/barrel_spectroscopy_crib.pro` (spectral fits).
