---
related_files:
  - projects/mms/AGENTS.md
  - projects/mms/common/mms_init.pro
  - projects/mms/common/mms_config.pro
  - projects/mms/common/mms_config_filedir.pro
  - projects/mms/common/mms_config_read.pro
  - projects/mms/common/mms_proxy.pro
  - projects/mms/common/load_data/mms_load_data.pro
  - projects/mms/common/load_data/mms_login_lasp.pro
  - projects/mms/common/load_data/mms_load_options.pro
  - projects/mms/common/load_data/mms_load_data_spdf.pro
  - projects/mms/common/load_data/mms_get_local_files.pro
  - projects/mms/common/load_data/mms_files_in_interval.pro
  - projects/mms/common/load_data/mms_check_file_exists.pro
  - projects/mms/common/load_data/mms_parse_json.pro
  - projects/mms/common/mms_data_fetch/mms_get_science_file_info.pro
  - projects/mms/common/mms_data_fetch/mms_data_fetch.pro
  - projects/mms/common/mms_data_fetch/mms_check_local_cache.pro
  - projects/mms/common/cdf/mms_cdf2tplot.pro
  - projects/mms/common/cdf/unh_mms_file_filter.pro
  - projects/mms/common/cotrans/mms_cotrans.pro
  - projects/mms/common/cotrans/mms_qcotrans.pro
  - projects/mms/common/cotrans/mms_cotrans_lmn.pro
  - projects/mms/common/cotrans/dmpa2gse.pro
  - projects/mms/common/cotrans/dmpa2dsl.pro
  - projects/mms/common/curlometer/mms_curl.pro
  - projects/mms/common/curlometer/mms_lingradest.pro
  - projects/mms/common/data_status_bar/mms_load_brst_segments.pro
  - projects/mms/common/data_status_bar/spd_mms_load_bss.pro
  - projects/mms/common/events/mms_event_search.pro
  - projects/mms/common/util/mms_jdote.pro
  - projects/mms/common/util/flatten_spectra.pro
  - projects/mms/common/tests/mms_run_all_tests.pro
  - projects/mms/common/tests/mms_python_validation_ut__define.pro
  - projects/mms/sdc/get_mms_sdc_connection.pro
  - projects/mms/sdc/get_mms_sitl_connection.pro
  - projects/mms/sdc/get_mms_file_info.pro
  - projects/mms/sdc/get_mms_science_file.pro
  - projects/mms/sdc/mms_sitl_logout.pro
  - projects/mms/sitl/bss/core/mms_bss_load.pro
  - projects/mms/mec_ascii/mms_load_state.pro
  - projects/mms/mec/mms_load_mec.pro
  - projects/themis/state/thm_interpolate_state.pro
  - general/CDF/spd_cdf2tplot.pro
  - general/misc/file_retrieve.pro
  - spedas_gui/utilities/spd_ui_login_widget.pro
  - spedas_gui/plugins/mms_plugin.txt
  - projects/mms/examples/basic/mms_config_crib.pro
  - projects/mms/examples/basic/mms_cotrans_crib.pro
  - projects/mms/examples/basic/mms_qcotrans_crib.pro
  - projects/mms/examples/basic/mms_curlometer_crib.pro
maintenance: |
  Update when mms_load_data, the SDC login or connection handling, the !mms
  configuration (fields, environment variables, config file) or the cotrans
  support-variable names change, or when a subfolder of common/ is added or removed.
---

# MMS common (IDL)

Code shared by all MMS instruments: `!mms` setup, SDC login, the load engine
`mms_load_data`, coordinate transforms, multi-spacecraft tools and tests.

## Layout

- Root: `mms_init.pro` (defines `!mms`), `mms_config.pro` with
  `mms_config_*.pro` (config file), `mms_proxy.pro` (proxy setup), and tools
  such as `mms_flipbookify`, `mms_timing_method`, `mms_find_perigee_times`.
- `load_data/`: `mms_load_data.pro` (engine), `mms_login_lasp.pro`,
  `mms_load_options.pro` (valid rate/level/datatype per instrument),
  `mms_load_data_spdf.pro` (`/spdf` path), `mms_get_local_files.pro` (offline
  search), `mms_files_in_interval.pro`, `mms_check_file_exists.pro`.
- `mms_data_fetch/`: SDC queries. `mms_get_science_file_info.pro` is used by
  `mms_load_data`; `mms_data_fetch.pro` and `mms_check_local_cache.pro` are
  an older fetcher still used by the SITL loaders in `projects/mms/sitl/`.
- `cdf/`: `mms_cdf2tplot.pro` (MMS variant used by the SPDF and SITL paths;
  the main path uses `spd_cdf2tplot`), `unh_mms_file_filter.pro` (version
  filtering for `cdf_version`, `min_version`, `latest_version`).
- `cotrans/` (`mms_cotrans.pro`, `mms_qcotrans.pro`, `mms_cotrans_lmn.pro`,
  `dmpa2gse.pro`, `dmpa2dsl.pro`), `curlometer/` (`mms_curl.pro`,
  `mms_lingradest.pro`), `util/` (`flatten_spectra.pro`, `mms_jdote.pro`,
  velocity frames), `tai/` (helpers for `mms_jdote`), `events/mms_event_search.pro`.
- `data_status_bar/`: burst, fast and SROI segment bars (`mms_load_brst_segments.pro`,
  `spd_mms_load_bss.pro`); uses `mms_bss_load` from `projects/mms/sitl/bss/`.
- `gui/`: SPEDAS GUI plugin (`spedas_gui/plugins/mms_plugin.txt`);
  `quicklook/`, `validation/`: plots and SDC comparisons; `tests/`: mgunit
  tests run by `tests/mms_run_all_tests.pro`.

## How mms_load_data works

1. `mms_init` builds `!mms` from `file_retrieve(/structure_format)`
   (`general/misc/file_retrieve.pro`) plus `mirror_data_dir`, then
   `mms_config` reads the config file and environment variables.
2. Unless offline or `/spdf`, `mms_login_lasp` gets credentials and calls
   `get_mms_sdc_connection` (`projects/mms/sdc/get_mms_sdc_connection.pro`).
3. Loop over probe, rate, level, datatype: `mms_get_science_file_info` queries
   the SDC, `mms_parse_json` and `mms_files_in_interval` select files,
   `mms_check_file_exists` compares with local copies, and
   `get_mms_science_file` (`projects/mms/sdc/get_mms_science_file.pro`)
   downloads the rest. Without a server answer, `mms_get_local_files` searches
   `local_data_dir`, then `!mms.mirror_data_dir`.
4. `spd_cdf2tplot` (`general/CDF/spd_cdf2tplot.pro`) loads the files;
   `/time_clip` clips to `trange`. `/available` only lists files and sizes.

## Things to know

- Global state: `!mms` (`local_data_dir`, `remote_data_dir`,
  `mirror_data_dir`, `no_download`, ...). The SDC session is an `IDLnetURL`
  object in common block `mms_sitl_connection`, shared with the SITL code
  (`projects/mms/sdc/get_mms_sitl_connection.pro`); it expires after 24 hours, and
  `mms_sitl_logout` clears it. `mms_event_search` caches in common `MMSEVENTS`.
- Credential files: `~/mms_auth_info.sav` (struct `auth_info` with `user` and
  `password`), then `./mms_auth_info.sav`, then `~/.mms_sitl_login.sav`;
  otherwise `spd_ui_login_widget` prompts. Blank username = public data.
- Config file: `mms_config_filedir` uses `app_user_dir('mms', ...)`.
  `MMS_DATA_DIR` overrides `SPEDAS_DATA_DIR`, which overrides `ROOT_DATA_DIR`.
  `mms_load_data` expands `local_data_dir` with a shell `echo`. `mms_init`
  stops (`stop`) when the CDF library is older than 3.6.30.
- Coordinates: `mms_cotrans` (DMPA, DSL, geophysical) needs
  `mms<p>_defatt_spinras`/`spindec` from `mms_load_state` for DMPA;
  `mms_qcotrans` needs MEC quaternions `mms<p>_mec_quat_eci_to_<coord>` from
  `mms_load_mec`. Neither loads them. `cotrans/dmpa2gse.pro` calls THEMIS
  `thm_interpolate_state`.

## Examples

`projects/mms/examples/basic/`: `mms_config_crib.pro`, `mms_cotrans_crib.pro`,
`mms_qcotrans_crib.pro`, `mms_curlometer_crib.pro`.
