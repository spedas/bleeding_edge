---
related_files:
  - projects/AGENTS.md
  - projects/erg/AGENTS.md
  - projects/iugonet/ReadMe.txt
  - projects/iugonet/load/iug_load_ear.pro
  - projects/iugonet/load/iug_load_ear_trop_nc.pro
  - projects/iugonet/load/iug_load_mu_trop_nc.pro
  - projects/iugonet/load/iug_load_gmag_nipr.pro
  - projects/iugonet/load/iug_load_gmag_mm210.pro
  - projects/iugonet/load/iug_load_gmag_wdc.pro
  - projects/iugonet/load/file_dailynames_iug.pro
  - projects/iugonet/load/ascii2tplot/ascii2tplot.pro
  - projects/iugonet/load/ascii2tplot/spd_ui_load_spedas_ascii.pro
  - projects/iugonet/gui/iug_init.pro
  - projects/iugonet/gui/iug_ui_load_data.pro
  - projects/iugonet/gui/iug_ui_load_data_load_pro.pro
  - projects/iugonet/gui/gui_acknowledgement.pro
  - projects/iugonet/plot/map2d/map2d_init.pro
  - projects/iugonet/tools/mddb/iug_get_obsinfo.pro
  - projects/iugonet/examples/iug_crib_ear.pro
  - projects/iugonet/examples/iug_crib_map2d.pro
  - projects/erg/tools/print_str_maxlet.pro
  - projects/erg/ground/geomag/erg_load_gmag_nipr.pro
  - projects/erg/ground/radar/superdarn/sd_init.pro
  - general/misc/ssl_check_valid_name.pro
  - general/misc/root_data_dir.pro
  - general/cotrans/aacgm/aacgmidl.pro
  - general/missions/kyoto
  - spedas_gui/plugins/iugonet_plugin.txt
  - spedas_gui/spd_gui.pro
maintenance: |
  Update when loaders are added, renamed or change their download/read pattern,
  when an iug_load_* alias starts or stops forwarding to an ERG loader, or when
  the GUI panel, !iugonet or the map2d library change.
---

# IUGONET (UDAS)

UDAS, the IUGONET plug-in: loaders and plots for ground-based upper-atmosphere
and geospace data from Japanese institutions (RISH and WDC at Kyoto, NIPR,
Tohoku, ISEE Nagoya, Kyushu ICSWSE, Kwasan/Hida) and EISCAT, developed with the
ERG Science Center. `ReadMe.txt` describes every loader in one line.

## Layout

- `load/`: most of the code, about 110 loaders named
  `iug_load_<instrument>[_<site or region>][_<format>]`, plus helpers
  (`file_dailynames_iug`, `conv3d`, `iug_ant_fits2tplot`).
- `load/ascii2tplot/`: the reader `ascii2tplot` and the GUI's ASCII dialog.
- `gui/`: the GUI load panel (`iug_ui_load_data`, `iug_ui_load_data_load_pro`),
  `iug_init` and the data-policy dialog `gui_acknowledgement`.
- `plot/`: instrument plots (`iug_plot2d_*`), all-sky image maps
  (`plot_map_asi_nipr`, `overlay_map_thmasi`), GPS TEC maps (`atec_*`).
  `plot/map2d/`: map-projection library (`map2d_init`, `map2d_set`, ...).
- `tools/`: `mddb/` searches the IUGONET metadata database (`iug_get_obsinfo`);
  `statistical_package/` has general statistics (trend, change point,
  coherence, S-transform) and a PDF manual.
- `examples/`: one crib per data set, e.g. `examples/iug_crib_ear.pro`;
  `examples/iug_crib_map2d.pro` covers the map library.

## How loaders work

1. A dispatcher named after the instrument, e.g. `load/iug_load_ear.pro`,
   checks `site`, `datatype` and `parameter` with `ssl_check_valid_name`
   (`general/misc/ssl_check_valid_name.pro`; default `'all'`) and calls
   one reader per data type (`iug_load_ear_trop_nc`, `iug_load_ear_iono_er_nc`, ...).
2. The reader (`load/iug_load_ear_trop_nc.pro`) fills a `file_retrieve(/struct)`
   source by hand: local directory `root_data_dir()` + `iugonet/<institution>/...`,
   server hard-coded (no credentials). It builds names with
   `file_dailynames`, downloads with `spd_download`, reads CDF with
   `cdf2tplot` or netCDF and text by hand (`ncdf_*`, `read_ascii`), and calls
   `store_data`.
3. It prints the data-use policy: RISH readers with `print`, the NIPR, WDC and
   EISCAT readers with `print_str_maxlet` (`projects/erg/tools/print_str_maxlet.pro`).

The GUI (`gui/iug_ui_load_data_load_pro.pro`) calls the same loaders, then
shows `gui_acknowledgement` for each new variable and keeps it only if the
user accepts; `!iugonet` (`gui/iug_init.pro`) remembers accepted policies.

## Things to know

- IUGONET and ERG ground code call each other; keep both on `!PATH`. Several
  `iug_load_*` files only forward to ERG loaders (`iug_load_gmag_mm210`,
  `iug_load_gmag_isee_fluxgate`, `iug_load_sdfit`, `iug_load_isee_vlf`, ...),
  whose code is in `projects/erg/ground/` (see `projects/erg/AGENTS.md`).
  The other way, `erg_load_gmag_nipr`
  (`projects/erg/ground/geomag/erg_load_gmag_nipr.pro`) calls
  `iug_load_gmag_nipr`, and ERG SuperDARN plots use `map2d`
  (`projects/erg/ground/radar/superdarn/sd_init.pro` calls `map2d_init`).
- Where a data set has both a netCDF reader and a `_txt`/`_csv` one, the
  dispatcher calls the `_nc` one.
- Many RISH readers shift the global `timespan` (EAR by 7 h, MU by 9 h)
  because the files are in local time, then restore it and `time_clip`
  (`load/iug_load_mu_trop_nc.pro`).
- tplot names mostly start with `iug_`; NIPR uses `nipr_`, EISCAT `eiscat_`,
  GPS radio occultation `gps_`, IPRT `iprt_`.
- `!map2d` (`plot/map2d/map2d_init.pro`) holds the map time, the coordinate
  flag (0 geographic, 1 AACGM) and whether the AACGM DLM exists; without it
  `map2d_init` runs `aacgmidl` (`general/cotrans/aacgm/aacgmidl.pro`).
- The main GUI (`spedas_gui/spd_gui.pro`) calls
  `load/ascii2tplot/spd_ui_load_spedas_ascii.pro`. The IUGONET panel is
  registered in `spedas_gui/plugins/iugonet_plugin.txt`.
- `iug_load_gmag_wdc` (`load/iug_load_gmag_wdc.pro`, server
  `wdc-data.iugonet.org`) is separate from the Kyoto index loaders in
  `general/missions/kyoto`.
