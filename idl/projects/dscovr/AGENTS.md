---
related_files:
  - projects/AGENTS.md
  - projects/dscovr/config/dsc_init.pro
  - projects/dscovr/config/dsc_read_config.pro
  - projects/dscovr/config/dsc_write_config.pro
  - projects/dscovr/config/dsc_config_filedir.pro
  - projects/dscovr/load/dsc_load_mag.pro
  - projects/dscovr/load/dsc_load_fc.pro
  - projects/dscovr/load/dsc_load_or.pro
  - projects/dscovr/load/dsc_load_att.pro
  - projects/dscovr/load/dsc_load_all.pro
  - projects/dscovr/misc/dsc_ezname.pro
  - projects/dscovr/misc/dsc_getrname.pro
  - projects/dscovr/misc/dsc_set_ytitle.pro
  - projects/dscovr/plot/dsc_overview.pro
  - projects/dscovr/plot/dsc_dyplot.pro
  - projects/dscovr/mission_compare/dsc_mission_compare__define.pro
  - projects/dscovr/mission_compare/dsc_mission_compare__plot.pro
  - projects/dscovr/mission_compare/helpers/ace_ezname.pro
  - projects/dscovr/mission_compare/helpers/wi_ezname.pro
  - projects/dscovr/examples/dsc_crib.pro
  - projects/dscovr/examples/dsc_mission_compare_crib.pro
  - projects/dscovr/QA/dsc_cltestsuite.pro
  - projects/dscovr/spedas_plugin/dsc_ui_load_data.pro
  - projects/dscovr/spedas_plugin/spd_ui_dsc_fileconfig.pro
  - spedas_gui/plugins/dsc_plugin.txt
  - spedas_gui/utilities/test_support_routines/spd_init_tests.pro
  - general/CDF/cdf2tplot.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/missions/wind/wi_mfi_load.pro
  - general/missions/ace/ace_mfi_load.pro
maintenance: |
  Update when a DSCOVR loader, its tplot prefix or bad-data handling changes,
  when !dsc gains or loses fields, or when the mission-compare object supports
  another mission.
---

# DSCOVR (IDL)

Loaders and plots for DSCOVR at L1: the fluxgate magnetometer, the Faraday cup
(solar wind protons), and orbit and attitude, all as daily CDFs from SPDF. Also
an object for comparing DSCOVR with Wind or ACE.

## Layout

- `config/`: `config/dsc_init.pro` sets `!dsc`;
  `config/dsc_read_config.pro`, `config/dsc_write_config.pro`,
  `config/dsc_config_filedir.pro` keep the saved configuration.
- `load/`: `load/dsc_load_mag.pro`, `load/dsc_load_fc.pro`,
  `load/dsc_load_or.pro`, `load/dsc_load_att.pro`, and `load/dsc_load_all.pro`
  which calls all four.
- `misc/`: helpers. `misc/dsc_ezname.pro` maps short names (`'bx'`, `'np'`,
  `'pos'`, ...) to full tplot names; `misc/dsc_getrname.pro` returns the caller's
  name for messages; `misc/dsc_set_ytitle.pro` sets axis titles.
- `plot/`: `plot/dsc_overview.pro` (daily summary) and `plot/dsc_dyplot.pro`
  (plots with a shaded confidence band).
- `mission_compare/`: the `dsc_mission_compare` object
  (`mission_compare/dsc_mission_compare__define.pro`); the `helpers/` folder has
  `ace_ezname` and `wi_ezname`.
- `examples/`: `examples/dsc_crib.pro`, `examples/dsc_mission_compare_crib.pro`.
- `QA/`: command-line tests and reference PNGs (see Tests).
- `spedas_plugin/`: GUI tab (`spedas_plugin/dsc_ui_load_data.pro`), config panel
  (`spedas_plugin/spd_ui_dsc_fileconfig.pro`), overview menu item and about
  text, registered by `spedas_gui/plugins/dsc_plugin.txt`.

## How `dsc_load_mag` works

1. `dsc_init` defines `!dsc` if it does not exist yet.
2. `type` defaults to `'h0'` (1-second data); the path is
   `dscovr/h0/mag/YYYY/dscovr_h0_mag_YYYYMMDD_v??.cdf`. `file_dailynames` and
   `spd_download` fetch it from `!dsc.remote_data_dir`
   (`general/misc/file_dailynames.pro`,
   `general/spedas_tools/spd_download/spd_download.pro`).
3. `cdf2tplot` (`general/CDF/cdf2tplot.pro`) stores the variables with the
   prefix `dsc_h0_mag_`.
4. Unless `/keep_bad` is set, samples whose `FLAG1` is nonzero are removed and
   the flag variable is deleted. Vector variables are split into components,
   and `_PHI`/`_THETA` angle variables are added for `B1GSE`.

The other loaders follow the same steps with prefixes `dsc_h1_fc_`,
`dsc_orbit_` and `dsc_att_`. `dsc_load_fc` removes points flagged by `DQF` and,
for each quantity with an uncertainty, adds `+DY` and `-DY` variables and a
`_wCONF` compound variable used by `dsc_dyplot`.

## Things to know

- `!dsc` is its own structure (`local_data_dir`, `remote_data_dir`,
  `save_plots_dir`, `no_download`, `no_update`, `verbose`), not a
  `file_retrieve` structure; there is no `init` flag, so `dsc_init` does
  nothing once `!dsc` exists unless `/reset` is given. On first use without a
  saved config it writes a default one (SPDF, `root_data_dir()` + `dsc/`,
  or `SPEDAS_DATA_DIR` + `dsc/`).
- Loader keywords `no_download`, `no_update` and `verbose` default to the
  `!dsc` values.
- Vector components are GSE (also RTN for the magnetometer).
- `dsc_mission_compare__plot.pro` loads comparison data by calling
  `wi_mfi_load`/`wi_swe_load` or `ace_mfi_load`/`ace_swe_load` through
  `call_procedure`, and the `*_ezname` helpers through `call_function`; those
  loaders are in `general/missions/wind/` and `general/missions/ace/`
  (`general/missions/wind/wi_mfi_load.pro`,
  `general/missions/ace/ace_mfi_load.pro`).

## Tests

`QA/dsc_cltestsuite.pro` runs the `QA/dsc_ut_*.pro` scripts with
`spd_init_tests` (`spedas_gui/utilities/test_support_routines/spd_init_tests.pro`).
It points `!dsc.local_data_dir` at a `qa/` subfolder of your data folder and
deletes that subfolder first, so it downloads everything again. Generated plots
must be compared by eye with `QA/ComparisonPlots/`.
