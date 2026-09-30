---
related_files:
  - projects/AGENTS.md
  - general/missions/AGENTS.md
  - projects/goes/goes_load_data.pro
  - projects/goes/goes_init.pro
  - projects/goes/goes_read_config.pro
  - projects/goes/goes_write_config.pro
  - projects/goes/goes_config_filedir.pro
  - projects/goes/goes_combine_tdata.pro
  - projects/goes/goes_lib.pro
  - projects/goes/goes_load_pos.pro
  - projects/goes/goesstruct_to_cdfstruct.pro
  - projects/goes/goes_overview_plot.pro
  - projects/goes/goes_overview_plot_wrapper.pro
  - projects/goes/goes_load_crib_sheet.pro
  - projects/goes/particles/goes_part_products.pro
  - projects/goes/particles/goes_get_dist.pro
  - projects/goes/particles/goes_pgs_make_fac.pro
  - projects/goes/particles/goes_part_products_crib_sheet.pro
  - projects/goes/spedas_plugin/goes_ui_load_data.pro
  - projects/goes/spedas_plugin/goes_ui_import_data.pro
  - projects/goes/spedas_plugin/goes_fileconfig.pro
  - projects/goes/spedas_plugin/goes_ui_gen_overplot.pro
  - projects/goes/spedas_plugin/about_goes.txt
  - spedas_gui/plugins/goes_plugin.txt
  - projects/goesr/goesr_load_data.pro
  - general/missions/goes/goes_mag_load.pro
  - general/missions/goes/goes_ep_load.pro
  - general/netCDF/netcdf2tplot.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/misc/spd_default_local_data_dir.pro
  - general/cotrans/special/enp/enp_matrix_make.pro
  - external/spdfssc/spdfgetlocations.pro
maintenance: |
  Update when goes_load_data gains or drops a datatype or server, when the
  netCDF-to-tplot path or goes_combine_tdata's variable naming changes, or when
  GOES-R support moves between this folder and projects/goesr/.
---

# GOES 8-15 (IDL)

Loaders and analysis for the older GOES satellites (GOES 8 to 15): magnetometer,
particle detectors (EPS, EPEAD, MAGED, MAGPD, HEPAD) and X-ray sensor, read from
NOAA NCEI netCDF files. GOES-R (16 and later) is a separate mission folder,
`projects/goesr/` (`goesr_load_data`).

## Layout

- `goes_load_data.pro`: the loader. `goes_init.pro` sets `!goes`;
  `goes_read_config.pro`, `goes_write_config.pro` and `goes_config_filedir.pro`
  keep the saved configuration.
- `goes_combine_tdata.pro`: post-processing that merges per-channel variables
  into multi-dimensional ones (one `goes_combine_*_data` routine per datatype).
- `goes_lib.pro`: a library file of helpers (pitch angles, omni fluxes,
  contamination correction) used by overview plots and cribs.
- `goes_load_pos.pro`: spacecraft position from SSCWeb.
- `goesstruct_to_cdfstruct.pro`: converts a netCDF structure for
  `netcdf2tplot` (`general/netCDF/netcdf2tplot.pro`).
- `goes_overview_plot.pro`, `goes_overview_plot_wrapper.pro`: daily summary
  plots (the wrapper hands probes 16 and later to `goesr_overview_plot`).
- `particles/`: MAGED/MAGPD distributions for the SPEDAS particle tools:
  `particles/goes_get_dist.pro`, `particles/goes_part_products.pro`,
  `particles/goes_pgs_make_fac.pro`.
- `spedas_plugin/`: GUI tab (`spedas_plugin/goes_ui_load_data.pro`,
  `spedas_plugin/goes_ui_import_data.pro`), config panel
  (`spedas_plugin/goes_fileconfig.pro`), overview menu item
  (`spedas_plugin/goes_ui_gen_overplot.pro`) and `spedas_plugin/about_goes.txt`,
  all registered by `spedas_gui/plugins/goes_plugin.txt`.

## How `goes_load_data` works

1. `goes_init` creates `!goes` from `file_retrieve(/structure_format)`, then
   fills it from the saved config or the defaults: NCEI
   (`https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/`)
   and `spd_default_local_data_dir()` + `goes/`
   (`general/misc/spd_default_local_data_dir.pro`).
2. For each probe (default `['13','14','15']`) and datatype (`fgm`, `eps`,
   `epead`, `maged`, `magpd`, `hepad`, `xrs`) it builds netCDF path patterns
   under `full/` (native resolution, daily files) or `avg/` (`/avg_1m`,
   `/avg_5m`, monthly files).
3. `file_dailynames` expands them and `spd_download` fetches them
   (`general/misc/file_dailynames.pro`,
   `general/spedas_tools/spd_download/spd_download.pro`).
4. `netcdf2tplot` stores every variable with the prefix `gNN_` (for example
   `g15_`).
5. Unless `/noephem` is set, `goes_load_pos` adds `gNN_pos_gei` from SSCWeb
   (`external/spdfssc/spdfgetlocations.pro`).
6. `goes_combine_tdata` merges channels (for example the H components into
   `g15_H_enp_1`), sets `data_att` (units, `coord_sys`), and deletes support
   variables unless `/get_support_data` is set. The result is then time-clipped.

## Things to know

- Probes 16 and 17 are refused here with a message pointing to
  `goesr_load_data` (`projects/goesr/goesr_load_data.pro`).
- Magnetometer data are in ENP, the GOES native frame (E earthward and N
  eastward in the orbit plane, P northward, normal to it); `enp_matrix_make`
  (`general/cotrans/special/enp/enp_matrix_make.pro`) builds rotations to
  other frames.
- The `goes_lib` helpers are defined inside `goes_lib.pro`, so IDL cannot find
  them by name until that file is compiled. Call `goes_lib` first, as
  `goes_overview_plot.pro` and `goes_load_crib_sheet.pro` do.
- `goes_combine_tdata` deletes support variables by wildcard, so loading a
  second datatype without `/get_support_data` can remove support variables
  loaded earlier.
- `!goes` is a `file_retrieve` structure; if `.master` exists in the local data
  folder, `no_server` is set.
- `goes_mag_load` and `goes_ep_load` in `general/missions/goes/`
  (`general/missions/goes/goes_mag_load.pro`,
  `general/missions/goes/goes_ep_load.pro`) are older, unrelated loaders of
  SPDF key-parameter CDFs through `!istp`.

## Examples

`goes_load_crib_sheet.pro` (command-line loading and `goes_lib` post-processing)
and `particles/goes_part_products_crib_sheet.pro` (particle spectrograms).
