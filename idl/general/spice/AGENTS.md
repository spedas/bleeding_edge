---
related_files:
  - general/AGENTS.md
  - general/spice/spice_test.pro
  - general/spice/spice_install.pro
  - general/spice/spice_file_source.pro
  - general/spice/spice_standard_kernels.pro
  - general/spice/spice_kernel_load.pro
  - general/spice/spice_kernel_info.pro
  - general/spice/spice_valid_times.pro
  - general/spice/spice_mk_read.pro
  - general/spice/spice_body_pos.pro
  - general/spice/spice_body_vel.pro
  - general/spice/spice_body_att.pro
  - general/spice/spice_m2q.pro
  - general/spice/spice_vector_rotate.pro
  - general/spice/spice_vector_rotate_tplot.pro
  - general/spice/spice_position_to_tplot.pro
  - general/spice/spice_qrot_to_tplot.pro
  - general/spice/time_ephemeris.pro
  - general/spice/spice_crib.pro
  - general/spice/orrery.pro
  - external/IDL_ICY/README.txt
  - general/spedas_tools/spd_download/spd_download_plus.pro
  - general/misc/file_retrieve.pro
  - projects/maven/general/spice/mvn_spice_kernels.pro
  - projects/SPP/COMMON/spice/spp_spice_kernels.pro
maintenance: |
  Update when a spice_* wrapper changes its arguments or time convention, when
  the kernel download source or the list of standard kernels changes, or when
  time_ephemeris's leap-second table is updated.
---

# SPICE wrappers

Thin IDL wrappers around NAIF's ICY library (the `cspice_*` DLM): installing
ICY, downloading and loading kernels, and getting positions, velocities and
frame rotations as arrays or tplot variables, with Unix times in and out.

## Layout

- Setup: `spice_test.pro` (is ICY installed? with a pattern, lists loaded
  kernels), `spice_install.pro` (downloads the ICY DLM into `!DLM_PATH`).
- Kernels: `spice_file_source.pro` (download settings for the NAIF server),
  `spice_standard_kernels.pro` (generic LSK, PCK and planetary SPK, plus planet
  satellites with `/mars`, `/jupiter`, ...), `spice_kernel_load.pro` (furnsh
  each kernel once), `spice_kernel_info.pro` (coverage of loaded CK/SPK kernels;
  also defines `spice_bod2s`, `spice_bods2c`, `spice_bodc2s`),
  `spice_mk_read.pro` (file list from a meta-kernel), `spice_get_ck_coverage`.
- Geometry: `spice_body_pos.pro` (`cspice_spkpos`), `spice_body_vel.pro`
  (`cspice_spkezr`), `spice_body_att.pro` (`cspice_pxform`, rotation matrices or
  quaternions via `spice_m2q`), `spice_vector_rotate.pro`,
  `spice_valid_times.pro`.
- tplot wrappers: `spice_position_to_tplot.pro`, `spice_qrot_to_tplot.pro`,
  `spice_vector_rotate_tplot.pro`.
- Time: `time_ephemeris.pro` converts Unix time to/from ephemeris time (ET).
- Other: `orrery.pro` (planet orbit plot), `sza`, `sza_shadow` (solar zenith
  angle helpers), `q_angular_velocity`, `qderiv`, and the crib `spice_crib.pro`.

## How it works

1. `spice_test()` checks for the ICY DLM; the kernel routines call it first and
   return quietly if ICY is missing (the geometry wrappers don't, and fail on
   the first `cspice_*` call). ICY is not bundled:
   `external/IDL_ICY/README.txt` explains the manual install.
2. A mission kernel routine builds a file list and loads it, e.g.
   `mvn_spice_kernels`
   (`projects/maven/general/spice/mvn_spice_kernels.pro`) or
   `spp_spice_kernels` (`projects/SPP/COMMON/spice/spp_spice_kernels.pro`),
   called with `/load`. Both start from `spice_file_source()` and
   `spice_standard_kernels()`. Other missions: `mex_spice_kernels`,
   `vex_spice_kernels`, `kgy_spice_kernels`, `esc_spice_kernels`,
   `swx_spice_kernels`.
3. `spice_standard_kernels` fetches from
   `https://naif.jpl.nasa.gov/pub/naif/generic_kernels/` with
   `spd_download_plus` into `root_data_dir()` + `misc/spice/naif/`;
   `spice_file_source` builds that source with
   `file_retrieve(/default_structure)`.
4. `spice_kernel_load` calls `cspice_furnsh` for kernels not already loaded,
   then refreshes the `spice_kernel_info` cache.
5. Geometry calls take Unix times (`utc=` or a time argument), convert with
   `time_ephemeris(ut, /ut2et)`, and with `check_objects=` skip times the loaded
   kernels don't cover (NaN instead of an ICY error).

## Things to know

- Arrays from `spice_body_pos`, `spice_body_att`, `spice_vector_rotate` and
  `spice_m2q` put time in the last dimension (3xN, 3x3xN, 4xN), the opposite of
  tplot storage. The tplot wrappers transpose.
- `spice_valid_times` (used by `check_objects`) reads the cached
  `spice_kernel_info`. Load kernels through `spice_kernel_load`, not
  `cspice_furnsh` directly, or the cache is stale.
- `spice_vector_rotate_tplot` reads the source frame from the variable's
  `SPICE_FRAME` dlimits tag and sets it to the new frame; MAVEN, SPP, Kaguya,
  VEX and ESCAPADE loaders set that tag.
- `time_ephemeris` uses its own hard-coded leap-second table (common
  `time_ephemeris_com`), not the loaded LSK, and deliberately stops with an
  error after the next possible leap-second date (`disable_time`) until the
  table is updated.
- State lives in common blocks: `spice_test_com`, `spice_file_source_com`,
  `spice_standard_kernels_com`, `spice_kernel_info_com`.
- Default frame for `spice_body_pos` is `ECLIPJ2000`; positions are in km,
  velocities in km/s.
- Frames and bodies are SPICE names (`'MAVEN_MSO'`, `'IAU_MARS'`, `'SPP_RTN'`);
  they only exist after the mission's frame kernel is loaded.
