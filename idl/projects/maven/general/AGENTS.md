---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/general/mvn_pfp_file_retrieve.pro
  - projects/maven/general/mvn_file_source.pro
  - projects/maven/general/mvn_pfp_spd_download.pro
  - projects/maven/general/mvn_set_userpass.pro
  - projects/maven/general/mvn_file_retrieve.pro
  - projects/maven/general/spice/mvn_spice_kernels.pro
  - projects/maven/general/spice/mvn_spice_load.pro
  - projects/maven/general/spice/mvn_spice_stat.pro
  - projects/maven/general/spice/mvn_spice_valid_times.pro
  - projects/maven/general/spice/mvn_spice_crib.pro
  - projects/maven/general/spice/mvn_spice_kernels_update.pro
  - projects/maven/general/mvn_orbit_num.pro
  - projects/maven/general/mvn_getorb.pro
  - projects/maven/general/mvn_frame_name.pro
  - projects/maven/general/mvn_altitude.pro
  - projects/maven/general/mvn_sundir.pro
  - projects/maven/general/mvn_ramdir.pro
  - projects/maven/general/mvn_nadir.pro
  - projects/maven/general/mvn_earthdir.pro
  - projects/maven/general/mvn_appdir.pro
  - projects/maven/general/mvn_topography.pro
  - projects/maven/general/mvn_ls.pro
  - projects/maven/general/mvn_mars_year.pro
  - projects/maven/general/mvn_mars_season2utc.pro
  - projects/maven/general/mvn_scpot.pro
  - projects/maven/general/mvn_scpot_com.pro
  - projects/maven/general/mvn_scpot_defaults.pro
  - projects/maven/general/mvn_scpot_restore.pro
  - projects/maven/general/mvn_get_scpot.pro
  - projects/maven/general/mvn_scpot_comp_dailysave.pro
  - projects/maven/general/mvn_scpot_survey.pro
  - projects/maven/general/anc/mvn_spc_anc_reactionwheels.pro
  - projects/maven/general/anc/mvn_spc_fov_blockage.pro
  - projects/maven/general/mvn_spc_unixtime_to_met.pro
  - projects/maven/mvn_spc_met_to_unixtime.pro
  - projects/maven/general/mvn_common_l0_file_transfer.pro
  - projects/maven/general/mso2lt.pro
  - general/misc/mso2lt.pro
  - general/misc/file_retrieve.pro
  - general/spice/spice_file_source.pro
  - general/spedas_tools/spd_download/spd_download_plus.pro
  - projects/maven/swea/mvn_swe_com.pro
maintenance: |
  Update when mvn_pfp_file_retrieve, mvn_file_source or mvn_spice_kernels change
  their keywords, defaults, server or kernel lists, or when the spacecraft
  potential (mvn_scpot*) routines or their common block change.
---

# MAVEN shared code (general)

Routines all MAVEN instrument code relies on: file retrieval from the SSL server,
SPICE kernels, orbit numbers, spacecraft geometry, and the spacecraft potential.

## Layout

- `mvn_pfp_file_retrieve.pro`, `mvn_file_source.pro`, `mvn_pfp_spd_download.pro`,
  `mvn_set_userpass.pro`: file retrieval (below). `mvn_file_retrieve.pro` is deprecated.
- `spice/`: `spice/mvn_spice_kernels.pro` (find and download kernels),
  `spice/mvn_spice_load.pro` (load them, make position tplot variables), coverage
  checks `spice/mvn_spice_stat.pro` and `spice/mvn_spice_valid_times.pro`,
  `spice/mvn_spice_crib.pro`, and the cron job `spice/mvn_spice_kernels_update.pro`.
  `spice/kernels/fk/`, `spice/kernels/ik/`: bundled frame and instrument kernels.
- `mvn_orbit_num.pro`, `mvn_getorb.pro` (quiet wrapper): orbit number <-> time.
  Mars season: `mvn_ls.pro`, `mvn_mars_year.pro`, `mvn_mars_season2utc.pro`.
- Geometry as tplot variables (need SPICE): `mvn_altitude.pro`, `mvn_sundir.pro`,
  `mvn_ramdir.pro`, `mvn_nadir.pro`, `mvn_earthdir.pro`, `mvn_appdir.pro` (APP
  gimbals), `mvn_topography.pro`; `mvn_frame_name.pro` expands frame fragments.
- Spacecraft potential: `mvn_scpot.pro`, `mvn_scpot_com.pro`, `mvn_scpot_defaults.pro`,
  `mvn_scpot_restore.pro`, `mvn_get_scpot.pro`; production and survey tools
  `mvn_scpot_comp_dailysave.pro`, `mvn_scpot_survey.pro`.
- `anc/`: spacecraft engineering files (e.g. `anc/mvn_spc_anc_reactionwheels.pro`)
  and a vertex model for field-of-view blockage (`anc/mvn_spc_fov_blockage.pro`).
- `mvn_spc_unixtime_to_met.pro`: inverse of `mvn_spc_met_to_unixtime`
  (`projects/maven/mvn_spc_met_to_unixtime.pro`, one level up).
- Generic helpers with non-MAVEN names (`file_search_plus`, `roundst`, `num2string`,
  `mso2lt`, ...); SSL-only `mvn_common_l0_file_transfer.pro`.

## How `mvn_pfp_file_retrieve` finds files

1. A loader passes a path relative to the data root, such as
   `maven/data/sci/euv/l2/YYYY/MM/mvn_euv_l2_bands_YYYYMMDD_v??_r??.cdf`, plus
   `/daily_names` (or `/hourly_names`, `/orbit_names`) and `trange`; without
   `trange` it calls `timerange()`, i.e. the `timespan` range.
2. It turns the pattern into one name per day and gets options from
   `mvn_file_source`: a structure in common `mvn_file_source_com` with
   `local_data_dir` = `root_data_dir()`, remote `http://sprg.ssl.berkeley.edu/data/`,
   `user_pass`, and `last_version=1`.
3. `file_retrieve` (`general/misc/file_retrieve.pro`) downloads if needed and
   resolves `v??_r??` to the newest file. Pass `/valid_only` to drop days with no
   file; otherwise the unmatched pattern (with `?`) is returned.
4. `/L0`, or no pathname, selects the daily all-PFP L0 file
   `maven/data/sci/pfp/l0_all/YYYY/MM/mvn_pfp_all_l0_YYYYMMDD_v???.dat`.

`mvn_pfp_spd_download` works the same but downloads with `spd_download_plus`
(`general/spedas_tools/spd_download/spd_download_plus.pro`); STATIC L2 and
SPICE C kernels use it.

## Things to know

- There is no MAVEN system variable or init routine. `mvn_file_source(/set, ...)`
  changes options for the session; its header forbids `/set` and `/reset` in
  distributed code. If `<root>/maven/.master` exists, nothing is downloaded.
- Credentials: `mvn_set_userpass` or env `MAVENPFP_USER_PASS` (base64 of
  `user:pass`; default derived from `$USER`). L0 and other team files need them.
- `mvn_spice_kernels` takes kernel types 'STD','SCK','FRM','IK','SPK','CK',
  'CK_APP','CK_SWE'. Most come from NAIF via `spice_file_source`
  (`general/spice/spice_file_source.pro`); FRM and IK are the bundled files whose
  versions are hardcoded in `spice/mvn_spice_kernels.pro`. Its header warns not to use
  `/load` inside load routines; `mvn_spice_load` clears all loaded kernels first.
- Orbit numbers follow the NAIF convention (increment at periapsis).
  `mvn_orbit_num` caches NAIF `.orb` files in common `mvn_orbit_num_com`.
- `mvn_scpot` reads SWEA spectra from the SWEA common blocks
  (`projects/maven/swea/mvn_swe_com.pro`) and stores results in `mvn_scpot_com`
  (included with `@mvn_scpot_com`). By default it restores precomputed composite
  potentials (`mvn_scpot_restore`); other code reads them with `mvn_get_scpot(time)`.
- `mso2lt.pro` also exists as `general/misc/mso2lt.pro` with a different fourth
  argument (Ls here, subsolar latitude there); `!PATH` order decides which runs.
