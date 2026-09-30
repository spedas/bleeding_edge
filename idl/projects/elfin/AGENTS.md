---
related_files:
  - projects/AGENTS.md
  - projects/elfin/common/elf_init.pro
  - projects/elfin/common/elf_config.pro
  - projects/elfin/common/elf_init_public.pro
  - projects/elfin/load_data/elf_load_data.pro
  - projects/elfin/load_data/elf_load_fgm.pro
  - projects/elfin/load_data/elf_load_epd.pro
  - projects/elfin/load_data/elf_load_state.pro
  - projects/elfin/load_data/elf_load_options.pro
  - projects/elfin/load_data/elf_get_local_files.pro
  - projects/elfin/load_data/elf_epd_l1_postproc.pro
  - projects/elfin/load_data/elf_cdf2tplot.pro
  - projects/elfin/load_data/elf_getspec.pro
  - projects/elfin/load_data/elf_get_phase_delays.pro
  - projects/elfin/cal_data/elf_cal_epd.pro
  - projects/elfin/cal_data/elf_cal_fgm.pro
  - projects/elfin/cal_data/elf_read_epd_cal_data.pro
  - projects/elfin/elf_load_prm.pro
  - projects/elfin/examples/elf_load_epd_crib.pro
  - projects/elfin/examples/elf_getspec_crib.pro
  - projects/elfin/tests/elf_fgm_load_cltestsuite.pro
  - spedas_gui/plugins/elfin_plugin.txt
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/spd_cdf2tplot.pro
  - general/misc/spd_default_local_data_dir.pro
maintenance: |
  Update when elf_load_data's paths, server or file naming change, when
  elf_init's handling of data directories changes, or when an instrument
  loader or the EPD calibration chain is added or reworked.
---

# ELFIN

Loaders and analysis for the two ELFIN CubeSats (probes `a` and `b`): the
fluxgate magnetometer (FGM), energetic particle detectors (EPD; `pef`/`pes`
electrons, `pif`/`pis` ions), magnetoresistive magnetometers (MRMa, MRMi),
state and attitude, plus plot production for the ELFIN web site.

## Layout

- `common/`: `elf_init` (sets `!elf`), `elf_config*`, `elf_init_public`.
- `load_data/`: `elf_load_data` (the shared engine) and the loaders
  `elf_load_fgm`, `elf_load_epd`, `elf_load_state`, `elf_load_mrma`,
  `elf_load_mrmi`, `elf_load_eng`, `elf_load_att`; index loaders
  (`elf_load_kp`, `elf_load_dst`, `elf_load_proxy_ae`); EPD processing
  (`elf_epd_l1_postproc`, `elf_getspec`, L2 CDF production); phase delays and
  data-availability tables.
- `cal_data/`: `elf_cal_fgm`, `elf_cal_epd`, `elf_cal_mrma`, `elf_cal_mrmi` and
  the EPD calibration readers.
- `plots/`: overview and orbit plots for the web site
  (`epde_plot_overviews`, `elf_plot_multispec_overviews`,
  `elf_map_state_t96_intervals*`, `run_summaries`); `plots/ovals/`: auroral
  oval tables for `ovalget`.
- `phase_delay/`, `gen4_scizones/`: team tools (EPD phase delays, zone stats).
- `spedas_plugin/`: the GUI load panel (`elf_ui_load_data`), registered in
  `spedas_gui/plugins/elfin_plugin.txt`.
- `examples/`: cribs (`examples/elf_load_epd_crib.pro`, ...). `tests/`:
  command-line scripts (`tests/elf_fgm_load_cltestsuite.pro`) run with `.go`.
- `elf_load_prm.pro`: local ELFIN-L data from Lomonosov (standalone).
  Skip `load_data/obsolete/` and `plots/obsolete/`.

## How `elf_load_epd` loads data

1. `load_data/elf_load_epd.pro` sets defaults (level `l1`, all four datatypes,
   `type='nflux'`) and calls `elf_load_data` with `instrument='epd'`.
2. `elf_load_data` (`load_data/elf_load_data.pro`) runs `elf_init` if `!elf`
   is missing, then for each probe, level and datatype builds names like
   `ela_l1_epdef_YYYYMMDD_v01.cdf` from `file_dailynames`, under
   `<probe>/<level>/<instrument>/<subdir>/<year>/`. It fetches each file with
   `spd_download` from `!elf.remote_data_dir` (or from SPDF with `/spdf`),
   and falls back to `elf_get_local_files` when a download fails or
   `/no_download` is set.
3. `spd_cdf2tplot` stores the files (L2 EPD uses `elf_cdf2tplot`), then
   `elf_load_data` time-clips, sorts and removes duplicate times.
4. For L1, `elf_epd_l1_postproc` converts the spin period and calls
   `elf_cal_epd`, which gets calibration from `elf_get_epd_calibration` and
   `elf_read_epd_cal_data` (a text file downloaded from
   `<probe>/calibration_files/` on the server).

FGM, MRM and state follow the same engine; `elf_load_fgm` then runs
`elf_cal_fgm` and converts spin-resolution data from GEI to NDW and OBW.

## Things to know

- `elf_init` always sets `!elf.local_data_dir` to
  `spd_default_local_data_dir()` + `elfin/` (`~/data/elfin/`) and the remote to
  `https://data.elfin.ucla.edu/`, overriding `ROOT_DATA_DIR`, `ELF_DATA_DIR`,
  `ELF_REMOTE_DATA_DIR` and the config file read by `elf_config`. Loaders use
  `!elf.local_data_dir`, not their `local_data_dir` keyword; change `!elf`
  after `elf_init` to use another directory.
- tplot names start with `ela_`/`elb_` (`ela_fgs`, `ela_pef_nflux`,
  `ela_pos_gei`). State and attitude are in GEI.
- `elf_getspec` (`load_data/elf_getspec.pro`) needs EPD, `el?_att_gei` and
  `el?_pos_gei` already loaded and the GEOPACK DLM (it calls `tt89`); it makes
  energy and pitch-angle spectra, including precipitating and trapped fluxes
  (see `examples/elf_getspec_crib.pro`). It aligns sectors using phase delays
  from `elf_find_phase_delay`, which reads `<probe>_<instrument>_phase_delays.csv`
  from the server (`load_data/elf_get_phase_delays.pro`).
- `plots/` defines unprefixed helpers (`atan2`, `where_array`,
  `find_interval`, `get_vec_ang`) that are visible to all of SPEDAS.
