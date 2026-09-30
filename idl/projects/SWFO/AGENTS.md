---
related_files:
  - projects/AGENTS.md
  - projects/SWFO/STIS/AGENTS.md
  - projects/SPP/COMMON/AGENTS.md
  - projects/SWFO/swfo_load.pro
  - projects/SWFO/swfo_noaa_load.pro
  - projects/SWFO/swfo_ccsds_frame_read.pro
  - projects/SWFO/swfo_aws_nc2sav_makefile.pro
  - projects/SWFO/swfo_quicklook.pro
  - projects/SWFO/swfo_ql_browser.shtml
  - projects/SWFO/ncdf2struct.pro
  - projects/SWFO/struct2ncdf.pro
  - projects/SWFO/swfo_sc_100_apdat__define.pro
  - projects/SWFO/mag/swfo_mag_sci_apdat__define.pro
  - projects/SWFO/mag/swfo_mag_decom.pro
  - projects/SWFO/STIS/swfo_stis_load.pro
  - projects/SWFO/STIS/swfo_stis_apdat_init.pro
  - projects/SWFO/STIS/swfo_ncdf_read.pro
  - projects/SWFO/STIS/swfo_stis_sci_level_2.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/misc/file_retrieve.pro
  - general/tools/misc/dynamicarray__define.pro
  - general/tplot/store_data.pro
maintenance: |
  Update when a SWFO loader changes its server, file layout, defaults or
  credential handling, when NOAA public products are added to swfo_noaa_load,
  or when code moves between this folder and STIS/.
---

# SWFO-L1 (SOLAR-1)

NOAA's Space Weather Follow On - Lagrange 1 spacecraft, called SOLAR-1 after
launch (both names appear in files and variables). SSL built its STIS particle
instrument; this is SSL's ground-processing code: L0 frame reading and
decommutation, spacecraft and magnetometer packets, STIS products, loaders,
quicklook plots, and a loader for NOAA's public data.

## Layout

- `STIS/`: STIS and the packet framework the whole mission uses (readers, APID
  registry, level processing, `swfo_stis_load`). See `STIS/AGENTS.md`.
- `mag/`: `mag/swfo_mag_sci_apdat__define.pro` (MAG packets) and
  `mag/swfo_mag_decom.pro` (1 s and high-rate products).
- `swfo_sc_<apid>_apdat__define.pro` (APIDs 100-170): spacecraft housekeeping classes.
- `swfo_load.pro`: loads processed NetCDF files from SSL; `make=` creates them.
- `swfo_ccsds_frame_read.pro`: fetches L0 frame files by ground station,
  decommutates them, and by default computes STIS L0b to L1b.
- `swfo_aws_nc2sav_makefile.pro`: turns L0 frame files into decommutated
  `.sav` files and restores them (used by `swfo_stis_load`).
- `swfo_noaa_load.pro`: public NOAA data. `swfo_quicklook.pro`: writes
  quicklook PNGs shown by `swfo_ql_browser.shtml`.
- `ncdf2struct.pro`, `struct2ncdf.pro`: NetCDF to structure and back.

## Which loader

| Need | Routine | Source | Login |
|---|---|---|---|
| Public MAG L3 (1 min, GSE) | `swfo_noaa_load` (default `type='sci_mag-l3'`) | NOAA NCEI file API, then `spd_download` | none |
| SWPC real-time plasma and MAG (1 min) | `swfo_noaa_load, type='swpc'` | SWPC HAPI via `curl` | none |
| Processed STIS/MAG files (team) | `swfo_load` | `http://sprg.ssl.berkeley.edu/data/swfo/data/test3/NCDF/` | `SWFO_USER_PASS` |
| L0 frames, L0a to L1b | `swfo_ccsds_frame_read`, `swfo_stis_load` | sprg `swfo/aws/...` | `SWFO_USER_PASS` |

## How `swfo_load` works

- Load (no `make`): types default to `['stis_l1b']`, with `_30s` appended for
  `lowres=1` (default), `_300s` for 2, nothing for 0. For each type
  `file_retrieve` fetches `swfo/data/test3/NCDF/<type>/DAY/YYYY/MM/<type>_YYYY-MM-DD.nc`
  under `root_data_dir()`, `swfo_ncdf_read` (`STIS/swfo_ncdf_read.pro`) reads it
  into a `dynamicarray`, and `swfo_load_tplot_store` (above `swfo_load` in the
  same file) makes `swfo_<type>_<TAG>` tplot variables straight from the
  dynamic array (`store_data, tagnames=`). L1b also runs
  `swfo_stis_sci_level_2`, giving unprefixed `stis_l2_*` variables.
- `make=2` loops over days: `swfo_ccsds_frame_read`, then `swfo_load, make=1`,
  which writes each decommutated product to the NetCDF tree. `make=3` with
  `/mk_l0b`, `/mk_l1a`, `/mk_l1b`, `/mk_mag` rebuilds those products and their
  30 s/300 s reductions when the inputs are newer.

## Things to know

- Login: `user_pass=` or `SWFO_USER_PASS` (`user:password`). Without either,
  `swfo_ccsds_frame_read` and `swfo_aws_nc2sav_makefile` build a user name and
  password from the login name and host and print them.
- `swfo_ccsds_frame_read` keeps its reader in a common block and skips files
  it has already read; default time range is the last `current` hours (8),
  station `'WCD'` (also `'CBU'`, `'RXWCD'`, `'RXCBU'`).
- APIDs for the whole mission are registered in `STIS/swfo_stis_apdat_init.pro`;
  playback packets get APID + 0x800 and a `pb_` prefix (`pb_swfo_sc_100`).
- SWFO shares PSP's common blocks (`spp_apdat_info_com`, `spp_file_source_com`);
  see `projects/SPP/COMMON/AGENTS.md`.
- `swfo_load` sets the tplot title to "SWFO Prelimary Data - Do not
  disseminate"; `swfo_quicklook` refuses dates before 2025-09-30.
