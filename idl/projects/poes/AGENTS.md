---
related_files:
  - projects/AGENTS.md
  - projects/poes/poes_load_data.pro
  - projects/poes/poes_init.pro
  - projects/poes/poes_read_config.pro
  - projects/poes/poes_write_config.pro
  - projects/poes/poes_config_filedir.pro
  - projects/poes/poes_cdf2tplot.pro
  - projects/poes/poes_netcdf2tplot.pro
  - projects/poes/poes_contamination_removal.pro
  - projects/poes/poes_overview_plot.pro
  - projects/poes/poes_overview_plot_wrapper.pro
  - projects/poes/spedas_plugin/poes_ui_load_data.pro
  - projects/poes/spedas_plugin/poes_ui_import_data.pro
  - projects/poes/spedas_plugin/poes_fileconfig.pro
  - projects/poes/spedas_plugin/poes_ui_gen_overplot.pro
  - spedas_gui/plugins/poes_plugin.txt
  - general/CDF/cdf2tplot.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
maintenance: |
  Update when poes_load_data's datatypes, servers (SPDF, NCEI L2, NCEI L1b) or
  the variable renaming and telescope splitting change, or when the POES
  readers are replaced by the shared CDF/netCDF routines.
---

# NOAA POES and MetOp (IDL)

Loader for the Space Environment Monitor (SEM-2) on the NOAA POES and EUMETSAT
MetOp satellites: the Total Energy Detector (TED) and the Medium Energy Proton
and Electron Detector (MEPED), plus footprint and L-shell ephemeris.

## Layout

- `poes_load_data.pro`: the loader. Helper routines are defined above it in the
  same file (`poes_split_telescope_data`, `poes_fix_metadata`,
  `poes_fix_ted_flux_vars`, `poes_join_vec`, `poes_fix_metop_tplotnames`).
- `poes_init.pro`: sets `!poes`; `poes_read_config.pro`,
  `poes_write_config.pro`, `poes_config_filedir.pro` keep the saved config.
- `poes_cdf2tplot.pro`: a POES-specific fork of `cdf2tplot`
  (`general/CDF/cdf2tplot.pro`) that renames the `time` variable first.
- `poes_netcdf2tplot.pro`: reads the NCEI L1b netCDF files.
- `poes_contamination_removal.pro`: MEPED proton-contamination correction for
  electron fluxes, applied to tplot variables you name; nothing calls it
  automatically.
- `poes_overview_plot.pro`, `poes_overview_plot_wrapper.pro`: daily summary
  plots.
- `spedas_plugin/`: GUI tab, config panel and overview menu item, registered by
  `spedas_gui/plugins/poes_plugin.txt`.

## How `poes_load_data` works

1. `poes_init` creates `!poes` from `file_retrieve(/structure_format)`, with
   defaults `https://cdaweb.gsfc.nasa.gov/istp_public/data/` and
   `spd_default_local_data_dir()`.
2. `remote_source` picks the server: `'spdf'` (default, daily
   `noaa/<probe>/sem2_fluxes-2sec/YYYY/<probe>_poes-sem2_fluxes-2sec_YYYYMMDD_v01.cdf`),
   `'ncei_l2'` (also set by `/ncei_server`, NCEI L2 CDFs) or `'ncei_l1b'` (NCEI
   L1b netCDF). The NCEI URLs are written in the routine, not in `!poes`.
3. Each requested datatype (`ted_ele_flux`, `mep_pro_flux`, ...; the header
   lists them) becomes a CDF `varformat` pattern; ephemeris variables
   (`mag_lat_sat`, `mag_lon_sat`, `l_igrf`, `mlt`) are added unless `/noephem`.
4. `file_dailynames` and `spd_download` fetch the files
   (`general/misc/file_dailynames.pro`,
   `general/spedas_tools/spd_download/spd_download.pro`).
5. CDFs go through `poes_cdf2tplot`; L1b netCDF goes through
   `poes_netcdf2tplot`, then `poes_join_vec` joins per-channel variables and
   `poes_fix_metop_tplotnames` renames them to the SPDF-style names
   (`..._flux_tel0` instead of `..._tel0_flux`).
6. Two-telescope arrays are split into `_tel0`/`_tel90` (MEPED) and
   `_tel0`/`_tel30` (TED) variables and `poes_fix_metadata` sets labels and
   units. TED flux variables are replaced by `_fixed` copies in which `-1`
   values become NaN and are then filled by linear interpolation (`tdeflag`).
   The result is time-clipped.

## Things to know

- Probes are names, not numbers: `'noaa15'`, `'noaa18'`, `'noaa19'` (default),
  `'metop1'`, `'metop2'`, and so on. Tplot names start with the probe name, for
  example `noaa19_ted_ele_flux_tel0_fixed`.
- Because the split and fix steps rename variables, the names you get differ
  from the CDF variable names; use the `tplotnames` keyword to see them.
- `datatype` defaults to `'*'` (every variable in the file).
- The GUI tab (`spedas_plugin/poes_ui_import_data.pro`) calls `poes_load_data`
  with the default SPDF source.
