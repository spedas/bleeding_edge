---
related_files:
  - projects/AGENTS.md
  - projects/escapade/general/esc_file_source.pro
  - projects/escapade/general/esc_file_retrieve.pro
  - projects/escapade/general/esc_l0_file_retrieve.pro
  - projects/escapade/general/esc_mission_phase.pro
  - projects/escapade/general/esc_gen_crib.pro
  - projects/escapade/emag/esc_emag_load.pro
  - projects/escapade/emag/esc_emag_angle.pro
  - projects/escapade/elp/esc_elp_load.pro
  - projects/escapade/esa/electron/esc_eesa_load.pro
  - projects/escapade/esa/electron/esc_eesa_tplot.pro
  - projects/escapade/esa/ion/esc_iesa_load.pro
  - projects/escapade/esa/ion/esc_iesa_tplot.pro
  - projects/escapade/esa/ion/esc_iesa_flight_mas.pro
  - projects/escapade/esa/common/esc_esa_hk_load.pro
  - projects/escapade/esa/common/esc_apdat_info.pro
  - projects/escapade/esa/common/esc_raw_file_read.pro
  - projects/escapade/esa/common/esc_esatm_reader__define.pro
  - projects/escapade/esa/common/esc_ccsds_decom.pro
  - projects/escapade/esa/common/esc_ahkp_apdat__define.pro
  - projects/escapade/spice/esc_spice_kernels.pro
  - projects/escapade/spice/esc_spice_load.pro
  - projects/escapade/spice/esc_eph_load.pro
  - projects/escapade/quicklook/esc_ql_tplot.pro
  - projects/escapade/misc/esc_tplot.pro
  - projects/SPP/AGENTS.md
  - projects/SWFO/AGENTS.md
  - general/misc/file_retrieve.pro
  - general/CDF/cdf2tplot.pro
maintenance: |
  Update when the ESCAPADE server layout, mission-phase dates or credential
  handling change, when an instrument loader is added or starts writing tplot
  variables directly, or when the dependencies on SPP/SWFO routines change.
---

# ESCAPADE

NASA's twin Mars orbiters Blue and Gold. Loaders for the L1 CDFs of EMAG
(magnetometer), EESA-e and EESA-i (electron and ion analyzers), ELP,
housekeeping and ephemeris, plus SPICE, raw L0 packet tools and quicklook
plots. Every routine starts with `esc_`.

## Layout

- `general/`: `general/esc_file_source.pro`, `general/esc_file_retrieve.pro`
  (downloads), `general/esc_l0_file_retrieve.pro` (raw L0 files by APID),
  `general/esc_mission_phase.pro`, and the crib `general/esc_gen_crib.pro` (start here).
- `emag/`: `emag/esc_emag_load.pro`, `emag/esc_emag_angle.pro` (cone/clock angles).
  `elp/`: `elp/esc_elp_load.pro`.
- `esa/electron/`: `esa/electron/esc_eesa_load.pro`, `esa/electron/esc_eesa_tplot.pro`.
- `esa/ion/`: `esa/ion/esc_iesa_load.pro`, `esa/ion/esc_iesa_tplot.pro`, getters
  `esc_iesa_get_f4d`/`_fm`/`_sw`, flight tables (`esc_iesa_flight_*`, `esc_iesa_fm1_*`).
- `esa/common/`: `esa/common/esc_esa_hk_load.pro`, and packet tools for raw and GSE
  data (`esa/common/esc_apdat_info.pro`, `esa/common/esc_raw_file_read.pro`,
  `esa/common/esc_esatm_reader__define.pro`, `esc_init_realtime`).
- `spice/`: `spice/esc_spice_kernels.pro`, `spice/esc_spice_load.pro`, and
  `spice/esc_eph_load.pro` (ancillary ephemeris CDFs).
- `quicklook/`: `quicklook/esc_ql_tplot.pro` (overview plots, PNGs), `esc_ql_eph`.
  `misc/`: `misc/esc_tplot.pro` (mplot/specplot wrapper) and tplot helpers.

## How `esc_emag_load` loads data

1. Time range from the argument or `timespan`; `/blue`, `/gold` pick the
   probes (default both).
2. Per day it looks for `<phase>/<probe>/emag/l1/YYYY/MM/esc-<b|g>_emag_l1_YYYY-MM-DD_*.cdf`.
   The phase comes from `esc_mission_phase` (prelaunch until 2025-11-13/20:55:01,
   commissioning until 2026-02-26, then science) unless `/prelaunch`,
   `/commissioning` or `/science` is set.
3. `esc_file_retrieve` expands the dates and calls `file_retrieve`
   (`general/misc/file_retrieve.pro`) with `esc_file_source()`: remote
   `http://sprg.ssl.berkeley.edu/data/escapade/data/`, local
   `root_data_dir()+'escapade/data/'`. Its `remote_data_dir=` keyword is a
   subfolder added after date expansion, so it must not contain time codes.
4. `cdf2tplot, prefix='esc'` makes `escb_emag_<frame>` and `escg_emag_<frame>`,
   then `esc?_emag_tot` and, for both probes, `esc_emag_tot`.

`ipath=` reads local files instead. `esc_elp_load`, `esc_eph_load`,
`esc_esa_hk_load`, `esc_eesa_load` and `esc_iesa_load` follow the same steps.

## Things to know

- Login: `esc_file_source` takes `user_pass=`, else builds one from the login
  name (`$USER`, `$USERNAME` or `$LOGNAME`) and returns 0 if none is set. The
  source is cached in the common block `esc_file_source_com` (`/reset`
  rebuilds). If `root_data_dir()+'escapade/science/tools/.hidden/.master'`
  exists, the local tree is the server.
- The ESA loaders fill common blocks, not tplot: `esc_eesa_load` fills
  `esc_eesa_{spec,pad,f3d,pot}_com` (`escb_eesa_f3d`, `escg_eesa_f3d`, ...),
  `esc_iesa_load` fills `esc_iesa_{fe,fm,f4d,sw}_com`, `esc_esa_hk_load` fills
  `esc_esa_ahk_com`/`esc_esa_dhk_com`. Run `esc_eesa_tplot` or `esc_iesa_tplot`
  afterwards; they read the blocks by name with `SCOPE_VARFETCH`. Default
  products: `f3d` (EESA-e), `f4d` (EESA-i).
- ESCAPADE needs SPP and SWFO code on `!PATH`: `esa/common/esc_ccsds_decom.pro`
  calls `spp_spc_met_to_unixtime`, `esa/common/esc_ahkp_apdat__define.pro` calls
  `spp_swp_word_decom`, the TM reader calls `swfo_data_select`, and
  `esc_ql_tplot` calls `swfo_noaa_load` (see `projects/SPP/AGENTS.md`,
  `projects/SWFO/AGENTS.md`).
- `esa/ion/esc_iesa_flight_mas.pro` defines two routines with PSP names,
  `spp_swp_spi_flight_mas_lut_even` and `spp_swp_spi_flight_mlim_lut_even`.
- `esc_emag_load` for both probes calls `line_colors, 5`, changing the colors.
