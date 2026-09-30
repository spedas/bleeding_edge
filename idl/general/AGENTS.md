---
related_files:
  - AGENTS.md
  - general/CDF/AGENTS.md
  - general/cotrans/AGENTS.md
  - general/misc/AGENTS.md
  - general/missions/AGENTS.md
  - general/science/AGENTS.md
  - general/spedas_tools/AGENTS.md
  - general/spice/AGENTS.md
  - general/tools/AGENTS.md
  - general/tplot/AGENTS.md
  - general/tplot/store_data.pro
  - general/tplot/get_data.pro
  - general/tplot/tplot.pro
  - general/misc/file_dailynames.pro
  - general/misc/file_retrieve.pro
  - general/misc/time/time_double.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/spd_cdf2tplot.pro
  - general/CDF/cdf2tplot.pro
  - general/cotrans/cotrans.pro
  - spedas_gui/utilities/cotrans/spd_cotrans.pro
  - general/mini/calc.pro
  - general/examples/crib_calc.pro
  - general/examples/crib_tplot.pro
  - general/hdf/hdf2tplot.pro
  - general/netCDF/netcdf2tplot.pro
  - general/qa_tools/mgunit/tplot_ut__define.pro
  - general/data3d_doc/data3d.txt
  - general/conv_units_doc/conv_units_doc.txt
maintenance: |
  Update when a subfolder of general/ is added, removed or gets its own
  AGENTS.md, or when a core entry point (store_data, spd_download,
  spd_cdf2tplot, cotrans) moves to another folder.
---

# general/

Mission-independent libraries used by every SPEDAS mission: tplot storage and
plotting, time and file utilities, downloading, CDF I/O, coordinate
transforms, particle and wave analysis, and SPICE. Older mission loaders that
never moved to `projects/` are here too, in `missions/`.

## Layout

Folders with their own AGENTS.md:

- `tplot/`: tplot variables (`store_data`, `get_data`, `tnames`, `options`)
  and plotting (`tplot`). See `tplot/AGENTS.md`.
- `misc/`: time conversion (`time_double`, `time_string`), `file_dailynames`,
  the older downloader `file_retrieve`, `str_element`, `dprint`, color
  tables, quaternions. See `misc/AGENTS.md`.
- `spedas_tools/`: the shared downloader `spd_download`, HAPI client, Autoplot
  bridge, Python validation. See `spedas_tools/AGENTS.md`.
- `CDF/`: `cdf2tplot` and `spd_cdf2tplot` (read), `tplot2cdf` (write). See
  `CDF/AGENTS.md`.
- `cotrans/`: `cotrans` (GEI/GSE/GSM/SM/GEO/MAG/J2000/GSEQ), heliocentric
  transforms, `tvector_rotate`, `minvar_matrix_make`, `fac_matrix_make`. See
  `cotrans/AGENTS.md`.
- `science/`: 3D particle distributions, `spd_pgs_*` particle products,
  `spd_slice2d`, `wavpol`, `spd_mtm`. See `science/AGENTS.md`.
- `spice/`: wrappers around NAIF ICY (kernels, positions, frames). See
  `spice/AGENTS.md`.
- `tools/`: curve fitting (`fit`), tplot arithmetic (`add_data`, `avg_data`),
  wavelets, `xtplot`. See `tools/AGENTS.md`.
- `missions/`: RBSP, FAST, STEREO, LANL, NOAA, Kyoto, ISTP, and parts of ACE,
  GOES and Wind. See `missions/AGENTS.md`.

Other folders:

- `examples/`: general crib sheets (`crib_tplot.pro` and 29 others: tplot
  layout, annotations, `tplot2cdf`, HAPI, `calc`).
- `mini/`: the `calc` mini-language (`mini/calc.pro`) for arithmetic on tplot
  variables, e.g. `calc, '"tha_pos_re" = "tha_state_pos"/6371.2'`; its parse
  tables are precompiled `.sav` files. Crib: `examples/crib_calc.pro`.
- `key_param/`: 1990s ISTP key-parameter loaders (`load_wi_*`, `load_ace_*`,
  `load_kp`, `load_dst`); most read through `loadallcdf` from
  `CDF/obsolete/`.
- `hdf/`: `hdf2tplot` (`hdf/hdf2tplot.pro`) for HDF-5/netCDF-4 files.
- `netCDF/`: `netcdf2tplot` (`netCDF/netcdf2tplot.pro`), used by the GOES
  loaders.
- `qa_tools/mgunit/`: mgunit test classes for tplot and `tplot2cdf`
  (e.g. `qa_tools/mgunit/tplot_ut__define.pro`). The mgunit framework itself is
  not in the repository.
- `data3d_doc/`, `conv_units_doc/`: text descriptions of the 3D distribution
  structure (`data3d_doc/data3d.txt`) and unit conversion.
- `obsolete/`: two old routines; skip.

## Things to know

- The typical loader chain crosses four folders: `file_dailynames` (misc) ->
  `spd_download` (spedas_tools) -> `spd_cdf2tplot` or `cdf2tplot` (CDF) ->
  `store_data` (tplot).
- Times everywhere are double Unix seconds (`time_double`), and coordinate
  systems are tracked in `dlimits.data_att.coord_sys`.
- Folder names repeat: `tools/tplot/` and `tools/misc/` are different from
  `tplot/` and `misc/`. The multi-hop `spd_cotrans` is in
  `spedas_gui/utilities/cotrans/spd_cotrans.pro`, not in `cotrans/`.
- `*_spd_doc_list.html` files next to each folder are generated documentation;
  skip them when searching.
