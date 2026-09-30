---
related_files:
  - projects/AGENTS.md
  - general/missions/AGENTS.md
  - general/science/AGENTS.md
  - projects/wind/3dp/README.txt
  - projects/wind/3dp/idl_3dp.init
  - projects/wind/3dp/idl/load_3dp_data.pro
  - projects/wind/3dp/idl/init_wind_lib.pro
  - projects/wind/3dp/idl/wind_com.pro
  - projects/wind/3dp/idl/get_el.pro
  - projects/wind/3dp/idl/get_spec.pro
  - projects/wind/3dp/idl/get_pmom2.pro
  - projects/wind/3dp/idl/get_pmom_lt.pro
  - projects/wind/3dp/idl/start3dp.pro
  - projects/wind/3dp/wind_lib/makefile
  - projects/wind/3dp/wind_lib/wind_idl.c
  - projects/wind/spedas_plugin/wind_ui_load_data.pro
  - projects/wind/spedas_plugin/wind_ui_import_data.pro
  - projects/wind/spedas_plugin/wind_fileconfig.pro
  - spedas_gui/plugins/wind_plugin.txt
  - general/missions/wind/wind_init.pro
  - general/missions/wind/wi_mfi_load.pro
  - general/missions/wind/wi_swe_load.pro
  - general/missions/wind/wi_3dp_load.pro
  - general/missions/wind/wi_or_load.pro
  - general/missions/wind/wi_crib.pro
  - general/science/convert_esa_units.pro
  - general/science/wind/get_pmom_lt.pro
  - general/misc/file_dailynames.pro
  - general/misc/file_retrieve.pro
maintenance: |
  Update when the 3DP level-zero reader (load_3dp_data, init_wind_lib, the
  wind_com block or the shared-library naming) changes, when the Wind GUI
  plugin calls different loaders, or when Wind CDF loaders move between
  general/missions/wind/ and this folder.
---

# Wind (IDL, projects part)

This folder holds only two pieces of Wind support: the 3DP level-zero (raw
telemetry) reader, which calls a compiled C decommutator, and the SPEDAS GUI
plugin. The CDF loaders most users want (`wi_mfi_load`, `wi_swe_load`,
`wi_3dp_load`, `wi_or_load`) and `wind_init` live in `general/missions/wind/`
(see `general/missions/AGENTS.md`).

## Layout

- `3dp/idl/`: IDL side of the 3DP level-zero reader: `load_3dp_data`,
  `init_wind_lib`, the `wind_com` common block, about 60 `get_*` functions that
  return one 3D distribution or moment set, and the prebuilt libraries
  `wind3dp_lib_<os>_<arch>.so`.
- `3dp/wind_lib/`: C source of the decommutator (`3dp/wind_lib/makefile`,
  `3dp/wind_lib/wind_idl.c` and the `*_dcm.c` decoders) plus old binaries.
- `3dp/README.txt`, `3dp/idl_3dp.init`: notes and a csh setup script from the
  original Berkeley install (sets `WIND_DATA_DIR` and related variables).
- `spedas_plugin/`: GUI load tab. `spedas_plugin/wind_ui_load_data.pro` builds it,
  `spedas_plugin/wind_ui_import_data.pro` calls the loaders, and
  `spedas_plugin/wind_fileconfig.pro` edits `!wind`. It is registered by
  `spedas_gui/plugins/wind_plugin.txt`.

## How `load_3dp_data` works

1. `3dp/idl/load_3dp_data.pro` takes a start time and a length in hours
   (default 24), includes `@wind_com.pro` and `@tplot_com.pro`, and calls
   `init_wind_lib`.
2. `3dp/idl/init_wind_lib.pro` fills the `wind_com` common block
   (`3dp/idl/wind_com.pro`): the master index file
   `$WIND_DATA_DIR/wi_lz_3dp_files`, and the library path, built from the folder
   holding `init_wind_lib.pro` plus `wind3dp_lib_` + `!version.os` + `_` +
   `!version.arch` + `.so`.
3. If the master index does not exist, `load_3dp_data` calls `wind_init`
   (`general/missions/wind/wind_init.pro`), fetches daily
   `wi_lz_3dp_YYYYMMDD_v0?.dat` files with `file_dailynames` and `file_retrieve`
   (`general/misc/file_dailynames.pro`, `general/misc/file_retrieve.pro`)
   using `!wind`, and writes a temporary index under `IDL_TMPDIR`.
4. `call_external(wind_lib, 'load_data_files_idl', ...)` loads the decoded
   packets into the library's memory. Nothing is stored in tplot yet.
5. Each `get_*` function (for example `3dp/idl/get_el.pro` for EESA Low) calls
   the library again with `call_external` and returns one 3D structure; the
   structure's `UNITS_PROCEDURE` names the unit converter, such as
   `convert_esa_units` (`general/science/convert_esa_units.pro`).
   `3dp/idl/get_spec.pro` builds `'get_' + name` and runs it with
   `call_function` to make energy spectra in tplot; `3dp/idl/get_pmom2.pro` and
   `get_emom` store moments.

## Things to know

- The 3DP reader only runs where a matching `.so` exists: darwin i386, ppc and
  x86_64, linux x86 and x86_64, and sunos sparc. There is none for arm64 Macs or
  Windows; rebuilding needs `3dp/wind_lib/`.
- State lives in the `wind_com` common block, not a system variable, and
  `load_3dp_data` must be called before any `get_*` function.
- The GUI tab loads CDF data only: `wind_ui_import_data` calls `wi_or_load`,
  `wi_mfi_load`, `wi_swe_load` and `wi_3dp_load` from
  `general/missions/wind/`. They download from SPDF through `!istp`
  (`istp_init`); `wi_3dp_load` (`general/missions/wind/wi_3dp_load.pro`)
  switches to `!wind` only when the local data folder is a master copy.
- 3D analysis routines that work on the `get_*` structures (`n_3d`, `get_3dt`,
  unit conversion) are in `general/science/` (see
  `general/science/AGENTS.md`).
- `3dp/idl/get_pmom_lt.pro` and `general/science/wind/get_pmom_lt.pro` are
  different routines with the same file name; which one runs depends on
  `!PATH` order.
- `3dp/idl/start3dp.pro` is an `@`-include batch file that sets the prompt and
  colors; it is not a procedure.

## Examples

`general/missions/wind/wi_crib.pro` shows the CDF loaders. There is no crib
for the level-zero reader; the `;+` headers of `get_el`, `get_spec` and
`load_3dp_data` are the documentation.
