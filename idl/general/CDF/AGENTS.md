---
related_files:
  - general/AGENTS.md
  - general/CDF/spd_cdf2tplot.pro
  - general/CDF/spd_mms_cdf_load_vars.pro
  - general/CDF/spd_cdf_info_to_tplot.pro
  - general/CDF/spd_unh_mms_file_filter.pro
  - general/CDF/cdf2tplot.pro
  - general/CDF/cdf_load_vars.pro
  - general/CDF/cdf_info_to_tplot.pro
  - general/CDF/cdf_info.pro
  - general/CDF/tplot2cdf.pro
  - general/CDF/tplot_add_cdf_structure.pro
  - general/CDF/tplot2cdf_save_vars.pro
  - general/CDF/cdf_default_cdfi_structure.pro
  - general/CDF/cdf_save_vars.pro
  - general/CDF/make_cdf_index.pro
  - general/CDF/obsolete
  - general/spedas_tools/spd_download/spd_cdf_check_delete.pro
  - general/misc/time/TT2000/cdf_leap_second_init.pro
  - projects/mms/common/cdf/mms_cdf2tplot.pro
  - general/examples/crib_tplot2cdf_basic.pro
  - general/qa_tools/mgunit/spd_tplot2cdf_ut__define.pro
maintenance: |
  Update when cdf2tplot or spd_cdf2tplot change their call chain, keywords or
  the dlimits they build, when tplot2cdf changes, or when routines in
  obsolete/ lose their last callers.
---

# CDF

Reading CDF files into tplot variables and writing tplot variables back to
CDF. Two parallel read chains exist: the original `cdf2tplot` and the newer
`spd_cdf2tplot`, forked from the MMS loader.

## Layout

- Read, original: `cdf2tplot.pro` -> `cdf_load_vars.pro` (uses `cdf_info.pro`)
  -> `cdf_info_to_tplot.pro`.
- Read, SPEDAS: `spd_cdf2tplot.pro` -> `spd_mms_cdf_load_vars.pro` ->
  `spd_cdf_info_to_tplot.pro`, with `spd_unh_mms_file_filter.pro` for
  version filtering.
- Write: `tplot2cdf.pro`, `tplot_add_cdf_structure.pro`,
  `tplot2cdf_save_vars.pro`, `cdf_default_cdfi_structure.pro`; `cdf_save_vars.pro`
  writes a `cdf_load_vars` structure back out.
- Utilities: `cdf_var_atts`, `print_cdf_info`, `cdf2idltype`/`idl2cdftype`,
  `cdf_set_cdf27` (CDF 2.7 backward-compatible output), `make_cdf_index.pro`.
- `obsolete/`: older readers and writers (`loadallcdf`, `loadcdfstr`,
  `loadcdf2`, `makecdf`, `cdf_to_tplot`). Not dead: Wind, FAST, STEREO code
  and `make_cdf_index.pro` still call them.

## How the readers work

Both take `files` plus `varformat=` (wildcards), `prefix=`, `suffix=`,
`midfix=`, `/get_support_data`, `/all`, `tplotnames=` (output) and
`varnames=` (output). The loader reads every matching variable and its
`DEPEND_0/1/2` into a `cdfi` structure of pointers, then the `*_info_to_tplot`
step converts times and calls `store_data` once per data variable. Time
variables (CDF_EPOCH, EPOCH16, TT2000) become Unix seconds via `time_double`;
`FILLVAL` values in float and double variables become NaN.

Differences:

- `spd_cdf2tplot` first filters files by version (`min_version=`,
  `version=`, `/latest_version`, `/major_version`, MMS-style `vX.Y.Z` names)
  and runs `spd_cdf_check_delete`
  (`general/spedas_tools/spd_download/spd_cdf_check_delete.pro`), which
  renames unreadable files to `*.todelete` unless `/disable_cdfcheck`.
- `spd_cdf2tplot` adds `data_att: {coord_sys, units}` to dlimits, taking
  `coord_sys` from the `COORDINATE_SYSTEM` attribute. `cotrans` and other
  tools read `data_att.coord_sys`; `cdf2tplot` does not set it.
- `spd_cdf2tplot` supports `/center_measurement` (shift times by
  `DELTA_PLUS_VAR`/`DELTA_MINUS_VAR`) and `/tt2000` (keep raw TT2000);
  `cdf2tplot` supports `/smex_epoch` (seconds since 1968-05-24, for FAST SDT
  files).
- `cdf2tplot` is far more widely called (general/missions, SPP, ERG,
  IUGONET, MAVEN); THEMIS (`thm_load_xxx`), Cluster and ELFIN use
  `spd_cdf2tplot`. MMS uses its own copy,
  `projects/mms/common/cdf/mms_cdf2tplot.pro`.

## Things to know

- Both chains set `dlimits.cdf = {filename, gatt, vname, vatt}`; the CDF
  global and variable attributes of a loaded variable are there.
- Plot options come from the `DISPLAY_TYPE`, `SCALETYP` and `UNITS`
  attributes: `spec` and `ysubtitle` in both; `cdf2tplot` also sets
  `ylog`/`zlog`/`ztitle`, while `spd_cdf2tplot` stores a `log` tag instead.
- TT2000 conversion drops leap seconds and needs `!CDF_LEAP_SECONDS`
  (`cdf_leap_second_init`, `general/misc/time/TT2000/cdf_leap_second_init.pro`).
- `tplot2cdf, filename=, tvars=` needs a CDF structure in each variable's
  limits; it adds a default one (`tplot_add_cdf_structure`) unless
  `default_cdf_structure=0`. Crib: `general/examples/crib_tplot2cdf_basic.pro`.
  Tests: `general/qa_tools/mgunit/spd_tplot2cdf_ut__define.pro` and
  siblings.
