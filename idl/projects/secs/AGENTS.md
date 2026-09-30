---
related_files:
  - projects/AGENTS.md
  - projects/themis/ground/AGENTS.md
  - projects/secs/secs_load_data.pro
  - projects/secs/secs_init.pro
  - projects/secs/secs_read_config.pro
  - projects/secs/secs_write_config.pro
  - projects/secs/secs_config_filedir.pro
  - projects/secs/secs_fileconfig.pro
  - projects/secs/eic_ascii2tplot.pro
  - projects/secs/eic_read_ascii_data.pro
  - projects/secs/sec_ascii2tplot.pro
  - projects/secs/sec_read_ascii_data.pro
  - projects/secs/secs_stations2tplot.pro
  - projects/secs/secs_read_stations.pro
  - projects/secs/eics_overlay_plots.pro
  - projects/secs/seca_overlay_plots.pro
  - projects/secs/examples/secs_load_data_crib.pro
  - projects/secs/examples/secs_mosaic_plot_crib.pro
  - projects/secs/spedas_plugin/secs_ui_load_data.pro
  - projects/secs/spedas_plugin/secs_ui_import_data.pro
  - projects/secs/spedas_plugin/secs_ui_overview_plots.pro
  - spedas_gui/plugins/secs_plugin.txt
  - projects/themis/ground/thm_asi_create_mosaic.pro
  - general/spedas_tools/spd_download/spd_download.pro
maintenance: |
  Update when the SECS file naming, server or ASCII format handled by
  secs_load_data and the *_ascii2tplot readers changes, or when the overlay
  plots change their THEMIS ASI dependency.
---

# SECS (IDL)

Spherical Elementary Current Systems maps of the northern high-latitude
ionosphere, derived from ground magnetometers (archive by J. Weygand, served
from the UCLA Virtual Magnetospheric Observatory). Two products: EICS
(equivalent ionospheric currents, horizontal Jx/Jy) and SECA (current
amplitudes). Data are ASCII files, not CDF.

## Layout

- `secs_load_data.pro`: the loader. `secs_init.pro` sets `!secs`;
  `secs_read_config.pro`, `secs_write_config.pro`, `secs_config_filedir.pro`
  and the GUI panel `secs_fileconfig.pro` manage the saved configuration.
- Readers: `eic_ascii2tplot.pro` with `eic_read_ascii_data.pro` (EICS),
  `sec_ascii2tplot.pro` with `sec_read_ascii_data.pro` (SECA),
  `secs_stations2tplot.pro` with `secs_read_stations.pro` (station list).
- `eics_overlay_plots.pro`, `seca_overlay_plots.pro`: map plots of the currents
  over a THEMIS all-sky-imager mosaic.
- `examples/`: `examples/secs_load_data_crib.pro`,
  `examples/secs_mosaic_plot_crib.pro`.
- `spedas_plugin/`: GUI load tab and overview-plot menu item, registered by
  `spedas_gui/plugins/secs_plugin.txt`.

## How `secs_load_data` works

1. It calls `secs_init` if `!secs` does not exist. Defaults: remote
   `http://vmo.igpp.ucla.edu/data1/SECS/`, local `root_data_dir()` + `secs/`.
2. `datatype` defaults to both `'eics'` and `'seca'`.
3. It builds one file name per 10 seconds from the start time, such as
   `EICS/YYYY/MM/DD/EICSYYYYMMDD_hhmmss.dat`, and fetches them with
   `spd_download` (`general/spedas_tools/spd_download/spd_download.pro`).
4. `eic_ascii2tplot` or `sec_ascii2tplot` reads all files into one array and
   stores `secs_eics_latlong` and `secs_eics_jxy`, or `secs_seca_latlong` and
   `secs_seca_amp` (with any `prefix`/`suffix`).
5. With `/get_stations` it also fetches the daily `Stations/.../StatYYYYMMDD.dat`
   file and stores `secs_stations`.

## Things to know

- File names are computed from the time of day of the start and end times only,
  so a request must stay within one UTC day; there is no time clipping.
- Each file is a whole map, and the readers append one row per grid point: `x`
  repeats the file's time for every point, and `y` holds that point's values.
  These are not ordinary time series, and even minutes of data are large.
- Coordinates are geographic: `*_latlong` is geographic latitude and longitude
  (`coord_sys` `'geo'`). EICS currents are in mA/m (Jx north, Jy east); SECA
  amplitudes are in A.
- The overlay plots call `secs_load_data` themselves and then
  `thm_asi_create_mosaic` (`projects/themis/ground/thm_asi_create_mosaic.pro`),
  so they need THEMIS ASI data and the THEMIS code on the path (see
  `projects/themis/ground/AGENTS.md`).
