---
related_files:
  - AGENTS.md
  - projects/SPP/AGENTS.md
  - projects/SWFO/AGENTS.md
  - projects/barrel/AGENTS.md
  - projects/cluster/AGENTS.md
  - projects/dscovr/AGENTS.md
  - projects/elfin/AGENTS.md
  - projects/emm/AGENTS.md
  - projects/erg/AGENTS.md
  - projects/escapade/AGENTS.md
  - projects/goes/AGENTS.md
  - projects/icon/AGENTS.md
  - projects/iugonet/AGENTS.md
  - projects/kaguya/AGENTS.md
  - projects/maven/AGENTS.md
  - projects/mex/AGENTS.md
  - projects/mms/AGENTS.md
  - projects/poes/AGENTS.md
  - projects/secs/AGENTS.md
  - projects/swx/AGENTS.md
  - projects/themis/AGENTS.md
  - projects/vex/AGENTS.md
  - projects/wind/AGENTS.md
  - general/missions/AGENTS.md
  - general/CDF/AGENTS.md
  - projects/ace/spedas_plugin/ace_ui_import_data.pro
  - projects/akebono/orb/akb_load_orb.pro
  - projects/akebono/pws/akb_load_pws.pro
  - projects/akebono/rdm/akb_load_rdm.pro
  - projects/bas/bas_load_data.pro
  - projects/bas/bas_init.pro
  - projects/cassini/das2dlm_load_cassini_mag_mag.pro
  - projects/fast/spedas_plugin/fast_ui_import_data.pro
  - projects/geom_indices/geom_indices_init.pro
  - projects/geom_indices/spedas_plugin/idx_ui_import_data.pro
  - projects/geotail/geotail_load_data.pro
  - projects/goesr/goesr_load_data.pro
  - projects/goesr/goesr_init.pro
  - projects/hermes/hermes_init_realtime.pro
  - projects/juno/juno_load_data.pro
  - projects/juno/das2tplot.pro
  - projects/kompsat/kompsat_load_data.pro
  - projects/kompsat/kompsat_readme.txt
  - projects/kompsat/check_esa_hapi_connection.pro
  - projects/ksem/ksem_init.pro
  - projects/lomonosov/lomo_load_data.pro
  - projects/lomonosov/lomo_init.pro
  - projects/lusee/lusee_load.pro
  - projects/mica/mica_load_induction.pro
  - projects/omni/omni_load_data.pro
  - projects/omni/omni_solarwind_load.pro
  - projects/tracers/load_data/tracers_load_data.pro
  - projects/tracers/common/tracers_init.pro
  - projects/goes/goes_init.pro
  - projects/goes/goes_read_config.pro
  - projects/goes/goes_config_filedir.pro
  - projects/goes/goes_load_data.pro
  - projects/themis/common/thm_load_xxx.pro
  - projects/maven/general/mvn_file_source.pro
  - general/misc/file_retrieve.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/spd_cdf2tplot.pro
  - general/CDF/cdf2tplot.pro
  - general/netCDF/netcdf2tplot.pro
  - general/hdf/hdf2tplot.pro
  - spedas_gui/plugins/goes_plugin.txt
  - spedas_gui/objects/spd_ui_plugin_manager__define.pro
maintenance: |
  Update when a mission folder is added to, removed from or renamed in
  projects/, when a mission gets or loses its own AGENTS.md, or when the
  shared loader pattern (init routine, spd_download, CDF reader, GUI plugin
  registration) changes.
---

# projects/

One folder per mission (39 folders). Each loads its data into tplot variables;
some also hold team analysis code, instrument ground-support software or a GUI
plugin. Older missions and indices (RBSP, STEREO, LANL, Kyoto, NOAA, ISTP, and
the loaders for ACE, FAST and Wind) are in `general/missions/` instead; see
`general/missions/AGENTS.md`.

## Missions

Folders with their own AGENTS.md:

- `SPP/`: Parker Solar Probe (FIELDS, SWEAP, ISOIS). `SPP/AGENTS.md`.
- `SWFO/`: SWFO-L1 / SOLAR-1, STIS ground processing. `SWFO/AGENTS.md`.
- `barrel/`: BARREL balloons. `barrel/AGENTS.md`.
- `cluster/`: Cluster, from SPDF and from ESA's CSA. `cluster/AGENTS.md`.
- `dscovr/`: DSCOVR magnetometer and Faraday cup. `dscovr/AGENTS.md`.
- `elfin/`: ELFIN CubeSats. `elfin/AGENTS.md`.
- `emm/`: Emirates Mars Mission (EMUS). `emm/AGENTS.md`.
- `erg/`: ERG (Arase) and ERG-SC ground networks. `erg/AGENTS.md`.
- `escapade/`: ESCAPADE Mars orbiters. `escapade/AGENTS.md`.
- `goes/`: GOES 8-15. `goes/AGENTS.md`.
- `icon/`: ICON. `icon/AGENTS.md`.
- `iugonet/`: IUGONET/UDAS ground-based data. `iugonet/AGENTS.md`.
- `kaguya/`: Kaguya (SELENE). `kaguya/AGENTS.md`.
- `maven/`: MAVEN. `maven/AGENTS.md`.
- `mex/`: Mars Express. `mex/AGENTS.md`.
- `mms/`: MMS. `mms/AGENTS.md`.
- `poes/`: NOAA POES and MetOp. `poes/AGENTS.md`.
- `secs/`: SECS ionospheric current maps. `secs/AGENTS.md`.
- `swx/`: SWX prelaunch telemetry decoding. `swx/AGENTS.md`.
- `themis/`: THEMIS and ARTEMIS. `themis/AGENTS.md`.
- `vex/`: Venus Express. `vex/AGENTS.md`.
- `wind/`: Wind 3DP level-zero reader and GUI plugin. `wind/AGENTS.md`.

Other folders (entry point first):

- `ace/`: GUI plugin only (`ace/spedas_plugin/ace_ui_import_data.pro`); the
  loaders (`ace_mfi_load`, `ace_swe_load`) are in `general/missions/ace/`.
- `akebono/`: `akebono/orb/akb_load_orb.pro`, `akebono/pws/akb_load_pws.pro`,
  `akebono/rdm/akb_load_rdm.pro` (ISAS DARTS); no init routine.
- `bas/`: `bas/bas_load_data.pro`, British Antarctic Survey ground
  magnetometers (ASCII); `!bas` from `bas/bas_init.pro`.
- `cassini/`: `das2dlm_load_cassini_*` (e.g.
  `cassini/das2dlm_load_cassini_mag_mag.pro`), MAG and RPWS streamed from the
  Iowa das2 server with the das2dlm library (`external/das2dlm/`).
- `fast/`: GUI plugin only (`fast/spedas_plugin/fast_ui_import_data.pro`); the
  code is in `general/missions/fast/`.
- `geom_indices/`: GUI plugin and `!geom_indices`
  (`geom_indices/geom_indices_init.pro`) for Kp, AE, Dst and OMNI;
  `geom_indices/spedas_plugin/idx_ui_import_data.pro` calls `noaa_load_kp`,
  `kyoto_load_ae`, `kyoto_load_dst` and `omni_hro_load` from
  `general/missions/`.
- `geotail/`: `geotail/geotail_load_data.pro` (LEP, MGF, orbit from SPDF).
- `goesr/`: `goesr/goesr_load_data.pro`, GOES-16 to 19 plus reprocessed
  high-resolution GOES 8-15 data (NOAA netCDF via `hdf2tplot`); `!goesr` from
  `goesr/goesr_init.pro`.
- `hermes/`: only `hermes/hermes_init_realtime.pro`, a prelaunch GSE recorder
  built on SPP code.
- `juno/`: `juno/juno_load_data.pro`, das2 streams from Iowa read by
  `juno/das2tplot.pro`.
- `kompsat/`: `kompsat/kompsat_load_data.pro`, GEO-KOMPSAT-2A SOSMAG and KSEM
  data from ESA's HAPI server (IDL 9.1 or later). The server needs a
  registered client ID and secret, set in
  `kompsat/check_esa_hapi_connection.pro` (see `kompsat/kompsat_readme.txt`).
- `ksem/`: `ksem/ksem_init.pro`, packet decoding for the KSEM instrument; no
  data loader.
- `lomonosov/`: `lomonosov/lomo_load_data.pro` (ELFIN-L on Lomonosov); `!lomo`
  from `lomonosov/lomo_init.pro`.
- `lusee/`: `lusee/lusee_load.pro`, LuSEE-Night L1 test files read through the
  PSP FIELDS L1 reader in `SPP/`.
- `mica/`: `mica/mica_load_induction.pro`, UNH induction-coil magnetometers.
- `omni/`: `omni/omni_load_data.pro` (OMNI HRO CDFs from SPDF, `!omni`) and
  `omni/omni_solarwind_load.pro` (pressure and Bz for LMN transforms).
- `tracers/`: `tracers/load_data/tracers_load_data.pro`; `!tracers` from
  `tracers/common/tracers_init.pro`.

## The usual loader pattern

Most missions follow the pattern of `goes/goes_load_data.pro`:

1. An init routine (`goes/goes_init.pro`) creates a system variable (`!goes`)
   from `file_retrieve(/structure_format)`
   (`general/misc/file_retrieve.pro`), with `local_data_dir`,
   `remote_data_dir`, `no_download`, `no_update`, `no_server`, `verbose` and
   `init`, filled from a saved config (`goes/goes_read_config.pro`, stored in
   the per-user folder from `goes/goes_config_filedir.pro`) or defaults. Once
   `init` is set, later calls return at once; `/reset` starts over. A `.master`
   file in the local data folder marks it as the server copy (no downloads).
2. The loader builds per-day relative paths with `file_dailynames`
   (`general/misc/file_dailynames.pro`) and fetches them with
   `spd_download` (`general/spedas_tools/spd_download/spd_download.pro`),
   passing the system variable's folders.
3. A reader stores tplot variables: `spd_cdf2tplot` or the older `cdf2tplot`
   (`general/CDF/spd_cdf2tplot.pro`, `general/CDF/cdf2tplot.pro`; see
   `general/CDF/AGENTS.md` for the differences), or `netcdf2tplot` /
   `hdf2tplot` for netCDF (`general/netCDF/netcdf2tplot.pro`,
   `general/hdf/hdf2tplot.pro`).
4. Mission code then renames, merges or calibrates variables and time-clips.
5. An optional GUI plugin in `<mission>/spedas_plugin/`
   (`<prefix>_ui_load_data`, `_ui_import_data`, `_fileconfig`) is registered by
   a text file in `spedas_gui/plugins/` such as
   `spedas_gui/plugins/goes_plugin.txt`; the plugin manager
   (`spedas_gui/objects/spd_ui_plugin_manager__define.pro`) reads every
   `.txt` file there.

## Missions that deviate

- THEMIS (`thm_load_xxx`, `themis/common/thm_load_xxx.pro`), MMS
  (`mms_load_data`) and ELFIN (`elf_load_data`) send every instrument loader
  through one shared load engine; see their AGENTS.md. MMS data come from the
  LASP SDC, which can ask for a login.
- MAVEN, SPP, Kaguya, ESCAPADE and SWFO: no system variable; a
  `<prefix>_file_source` function keeps the source structure in a common block
  (e.g. `maven/general/mvn_file_source.pro`), and `<prefix>_file_retrieve`
  downloads with `file_retrieve`. BARREL also downloads with `file_retrieve`.
- DSCOVR: `!dsc` is its own structure, not a `file_retrieve` one.
- No init at all: Akebono, MICA, MEX and VEX build sources or URLs inside each
  loader.
- Non-CDF data: netCDF (GOES, GOES-R, ICON, POES L1b), ASCII (SECS, BAS), das2
  streams (Cassini, Juno), HAPI (KOMPSAT), CSA tar archives (Cluster).
- No public-data loader: SWX, HERMES and KSEM (and parts of SPP, SWFO and
  ESCAPADE) decode instrument packets from ground tests or real-time sockets.
- ACE, FAST and Wind keep their loaders in `general/missions/`; GOES has
  independent loaders in both places.

## Things to know

- Mission folders often call code from other missions: THEMIS routines are used
  widely (`thm_init` for colors, ASI mosaics in SECS), RBSPICE uses
  `mms_cdf2tplot`, and LuSEE uses the SPP FIELDS reader.
- `*_spd_doc_list.html` files beside the folders are generated documentation.
