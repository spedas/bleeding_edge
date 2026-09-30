---
related_files:
  - projects/AGENTS.md
  - projects/mms/common/AGENTS.md
  - projects/mms/particles/AGENTS.md
  - projects/mms/sitl/AGENTS.md
  - projects/mms/about_mms.txt
  - projects/mms/fgm/mms_load_fgm.pro
  - projects/mms/fgm/mms_split_fgm_data.pro
  - projects/mms/fpi/mms_load_fpi.pro
  - projects/mms/fpi/mms_get_fpi_dist.pro
  - projects/mms/hpca/mms_load_hpca.pro
  - projects/mms/mec/mms_load_mec.pro
  - projects/mms/mec_ascii/mms_load_state.pro
  - projects/mms/aspoc/mms_load_aspoc.pro
  - projects/mms/dsp/mms_load_dsp.pro
  - projects/mms/edi/mms_load_edi.pro
  - projects/mms/edp/mms_load_edp.pro
  - projects/mms/eis/mms_load_eis.pro
  - projects/mms/feeps/mms_load_feeps.pro
  - projects/mms/fsm/mms_load_fsm.pro
  - projects/mms/scm/mms_load_scm.pro
  - projects/mms/sdc/get_mms_sdc_connection.pro
  - projects/mms/sdc/get_mms_science_file.pro
  - projects/mms/common/load_data/mms_load_data.pro
  - projects/mms/common/load_data/mms_login_lasp.pro
  - projects/mms/common/load_data/mms_load_data_spdf.pro
  - projects/mms/common/load_data/mms_load_options.pro
  - projects/mms/common/mms_init.pro
  - projects/mms/common/mms_config.pro
  - projects/mms/common/tests/mms_run_all_tests.pro
  - projects/mms/common/tests/mms_python_validation_ut__define.pro
  - projects/mms/examples/basic/readme.txt
  - projects/mms/examples/basic/mms_load_fgm_crib.pro
  - projects/mms/examples/basic/mms_load_fpi_crib.pro
  - general/CDF/spd_cdf2tplot.pro
  - spedas_gui/plugins/mms_plugin.txt
maintenance: |
  Update when an instrument folder or loader is added or renamed, when the
  shared load path (mms_load_data, SDC login, SPDF fallback) or its defaults
  change, or when a subfolder gains or loses its own AGENTS.md.
---

# MMS (IDL)

Magnetospheric Multiscale: four probes (`probes='1'`...`'4'`). One folder per
instrument, each with an `mms_load_<inst>.pro` loader, all sharing one load
engine that downloads CDFs from the LASP Science Data Center (SDC).

## Layout

Own AGENTS.md: `common/` (load engine, login, config, cotrans, tests),
`particles/` (distribution products, slices), `sitl/` (burst selection, EVA).
Instrument folders have one loader each, all calling `mms_load_data`:

- `fgm/`: fluxgate magnetometer, `mms_load_fgm.pro` (`instrument='afg'` or
  `'dfg'` for ql/l1 data); `mms_split_fgm_data.pro` splits `b` into `bvec`/`btot`.
- `scm/` search coil, `fsm/` FGM+SCM merged, `edp/` electric field double
  probes, `edi/` electron drift, `dsp/` wave spectra, `aspoc/` potential control.
- `fpi/`: plasma moments and distributions (`mms_load_fpi.pro`,
  `mms_get_fpi_dist.pro`); `hpca/`: ion composition (`mms_load_hpca.pro`).
- `eis/`, `feeps/`: energetic particles, with omni, pitch-angle and spin-average
  helpers (`mms_eis_*`, `mms_feeps_*`).
- `mec/`: ephemeris, attitude and quaternions from MEC files (`mms_load_mec.pro`).
- `mec_ascii/`: `mms_load_state.pro`, definitive and predicted ephemeris and
  attitude from SDC ancillary ASCII files (not through `mms_load_data`).
- `sdc/`: SDC web-service client: connection, file queries and downloads,
  SITL selection submission (`sdc/get_mms_sdc_connection.pro`,
  `sdc/get_mms_science_file.pro`).
- `examples/`: `basic/` (public data, new users; see `examples/basic/readme.txt`),
  `advanced/`, `quicklook/`, `webinars/`.

## How mms_load_fgm loads data

1. `fgm/mms_load_fgm.pro` sets defaults and calls `mms_load_data`
   (`common/load_data/mms_load_data.pro`) with `instrument`, `data_rate`,
   `level`, `datatype`.
2. `mms_load_data` runs `mms_init` (`common/mms_init.pro`, sets `!mms`) and
   logs in with `mms_login_lasp` (`common/load_data/mms_login_lasp.pro`).
3. For each probe, rate, level and datatype it asks the SDC for matching files,
   downloads missing ones with `get_mms_science_file` into
   `<local_data_dir>/mms1/fgm/srvy/l2/YYYY/MM/` (burst: `YYYY/MM/DD`), and falls
   back to local files (then `!mms.mirror_data_dir`) when offline.
4. `spd_cdf2tplot` (`general/CDF/spd_cdf2tplot.pro`) loads the files; the
   FGM loader then sets flagged points to NaN, splits vectors and fixes
   metadata. With `/spdf`, `mms_load_data_spdf` does steps 2 to 4 instead,
   without login, from SPDF (public data only).

## Things to know

- Defaults: probe `'1'`, `data_rate='srvy'`, `level='l2'`. `mms_load_fgm`
  picks `ql` when the interval ends within the last 14 days. Rates are
  `srvy`, `fast`, `slow`, `brst`; `mms_load_options`
  (`common/load_data/mms_load_options.pro`) lists valid combinations.
- Variable names look like `mms1_fgm_b_gse_srvy_l2`; FPI uses `mms1_dis_*` and
  `mms1_des_*`. The local tree mirrors the SDC, and the `datatype` becomes a
  path level (e.g. `fpi/fast/l2/dis-moms/`), so pass it explicitly.
- Credentials: `mms_login_lasp` reads `~/mms_auth_info.sav` (then the current
  directory, then `~/.mms_sitl_login.sav`) or shows a login widget; an empty
  username means public access. The connection is cached for 24 hours (see
  `common/AGENTS.md`). `/always_prompt` forces a new login.
- `!mms.remote_data_dir` only affects SPDF loads; the SDC host is fixed in
  `sdc/`. Local paths come from `mms_config` (`common/mms_config.pro`) and the
  `MMS_DATA_DIR`, `SPEDAS_DATA_DIR` or `ROOT_DATA_DIR` environment variables.
- `about_mms.txt` notes that SDC access needs IDL 8.4 and CDF 3.6.3+ (leap
  seconds); `mms_init` prints a warning and stops (`stop`) on older CDF.
- GUI plugin: `common/gui/`, registered in `spedas_gui/plugins/mms_plugin.txt`.

## Examples and tests

Start with `examples/basic/mms_load_fgm_crib.pro`, `examples/basic/mms_load_fpi_crib.pro`.
mgunit tests: `common/tests/mms_run_all_tests.pro`; pySPEDAS comparison in
`common/tests/mms_python_validation_ut__define.pro`.
