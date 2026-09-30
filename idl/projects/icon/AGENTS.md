---
related_files:
  - projects/AGENTS.md
  - projects/icon/about_icon.txt
  - projects/icon/load/icon_load_data.pro
  - projects/icon/load/icon_netcdf2tplot.pro
  - projects/icon/common/icon_netcdf_load_vars.pro
  - projects/icon/common/icon_struct_to_cdfstruct.pro
  - projects/icon/common/icon_dimension_fix.pro
  - projects/icon/common/icon_check_att.pro
  - projects/icon/common/icon_doy_date.pro
  - projects/icon/config/icon_init.pro
  - projects/icon/config/icon_read_config.pro
  - projects/icon/config/icon_write_config.pro
  - projects/icon/config/icon_config_filedir.pro
  - projects/icon/examples/icon_crib.pro
  - projects/icon/examples/icon_crib_euv.pro
  - projects/icon/examples/icon_crib_mighti.pro
  - projects/icon/spedas_plugin/icon_ui_load_data.pro
  - projects/icon/spedas_plugin/icon_ui_import_data.pro
  - projects/icon/spedas_plugin/icon_fileconfig.pro
  - spedas_gui/plugins/icon_plugin.txt
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
maintenance: |
  Update when icon_load_data's instrument list, path patterns or file-name
  resolution change, when the default server in icon_init changes, or when the
  netCDF reading chain in common/ is replaced.
---

# ICON (IDL)

Loader for NASA's Ionospheric Connection Explorer: FUV, IVM, EUV and MIGHTI
level 1 and level 2 netCDF files. The plugin is labelled beta
(`about_icon.txt`).

## Layout

- `load/`: `load/icon_load_data.pro` (the loader, with the helpers
  `icon_euv_filenames` and `icon_mighti_filenames` defined above it) and
  `load/icon_netcdf2tplot.pro`.
- `common/`: the netCDF reading chain. `common/icon_netcdf_load_vars.pro` reads
  files into a structure (fixing dimensions with
  `common/icon_dimension_fix.pro` and `common/icon_check_att.pro`), and
  `common/icon_struct_to_cdfstruct.pro` turns it into the structure
  `cdf_info_to_tplot` expects. `common/icon_doy_date.pro` converts dates.
- `config/`: `config/icon_init.pro` sets `!icon`; `config/icon_read_config.pro`,
  `config/icon_write_config.pro`, `config/icon_config_filedir.pro` keep the
  saved config.
- `examples/`: `examples/icon_crib.pro` (FUV and IVM),
  `examples/icon_crib_euv.pro`, `examples/icon_crib_mighti.pro`.
- `spedas_plugin/`: GUI tab and config panel, registered by
  `spedas_gui/plugins/icon_plugin.txt`.

## How `icon_load_data` works

1. `icon_init` creates `!icon` from `file_retrieve(/structure_format)` and fills
   it from the saved config or defaults.
2. `instrument` is `'fuv'` (default), `'ivm'`, `'euv'` or `'mighti'`
   (also `'mighti-a'`, `'mighti-b'`). `datal1type` or `datal2type` chooses the
   product and level; for FUV, `'*'` selects all L1 types (`lwp`, `sli`, `ssi`,
   `swp`) or all L2 types.
3. It builds patterns such as
   `LEVEL.1/FUV/YYYY/DOY/ICON_L1_FUV_LWP_YYYY-MM-DD_v??r???.NC`; `fversion` and
   `frevision` pin the version, otherwise wildcards are used.
4. `file_dailynames` expands them (`general/misc/file_dailynames.pro`). For
   L1 EUV and MIGHTI, which have several files a day, `icon_euv_filenames` and
   `icon_mighti_filenames` list the remote folder with `spd_download_expand`,
   keep the highest version and revision, and select files inside the time
   range.
5. `spd_download` (`general/spedas_tools/spd_download/spd_download.pro`)
   fetches the files into `!icon.local_data_dir`, then `icon_netcdf2tplot`
   reads them through `icon_netcdf_load_vars`, `icon_struct_to_cdfstruct` and
   `cdf_info_to_tplot`.

## Things to know

- The default `!icon.remote_data_dir` is a file-system path on the SSL network
  (`/disks/data/icon/Repository/Archive/Simulated-Data/`), and the cribs check
  for that folder and stop if it is missing. Elsewhere, set
  `!icon.remote_data_dir` (or save it with the GUI config panel) before
  loading.
- Tplot names are the netCDF variable names; no prefix is added.
- On IDL 8.4 and later the loader replaces double backslashes in the remote
  path, so Windows network paths work.
- `.NC` files are netCDF, read with IDL's `ncdf_*` routines; there is no CDF
  step.
