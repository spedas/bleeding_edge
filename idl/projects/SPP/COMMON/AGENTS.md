---
related_files:
  - projects/SPP/AGENTS.md
  - projects/SPP/fields/AGENTS.md
  - projects/SPP/COMMON/spp_file_retrieve.pro
  - projects/SPP/COMMON/spp_file_source.pro
  - projects/SPP/COMMON/ssl_password.sav
  - projects/SPP/COMMON/psp_fld_load.pro
  - projects/SPP/COMMON/spp_fld_load.pro
  - projects/SPP/COMMON/spp_swp_mag_load.pro
  - projects/SPP/COMMON/spp_fld_mag_load.pro
  - projects/SPP/COMMON/spp_ssr_file_read.pro
  - projects/SPP/COMMON/spp_ssr_lun_read.pro
  - projects/SPP/COMMON/spp_ptp_file_read.pro
  - projects/SPP/COMMON/spp_init_realtime.pro
  - projects/SPP/COMMON/spp_apdat_info.pro
  - projects/SPP/COMMON/spp_apdat.pro
  - projects/SPP/COMMON/spp_gen_apdat__define.pro
  - projects/SPP/COMMON/spp_ccsds_pkt_handler.pro
  - projects/SPP/COMMON/spp_apid_data.pro
  - projects/SPP/COMMON/cdf_tools__define.pro
  - projects/SPP/COMMON/sc
  - projects/SPP/COMMON/spice/spp_spice_kernels.pro
  - projects/SPP/COMMON/spice/spp_swp_spice.pro
  - projects/SPP/COMMON/sppeva/sppeva.pro
  - projects/SPP/sweap/COMMON/spp_swp_apdat_init.pro
  - projects/SPP/sweap/COMMON/spp_ccsds_spkt_handler.pro
  - projects/SPP/sweap/SPC/L3i/load/psp_load_swp.pro
  - projects/SWFO/STIS/swfo_file_source.pro
  - projects/SWFO/STIS/swfo_apdat_info.pro
  - projects/swx/swx_apdat_info.pro
  - general/misc/file_retrieve.pro
  - general/misc/root_data_dir.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
maintenance: |
  Update when spp_file_retrieve or spp_file_source change keywords, server,
  source keys or credential variables, when the packet-reading chain changes,
  or when SWFO/swx stop sharing this folder's common blocks.
---

# PSP shared code (SPP/COMMON)

Code shared by the SWEAP and FIELDS teams: the download wrapper
`spp_file_retrieve`/`spp_file_source`, the FIELDS load entry points, the CCSDS
packet (L0) framework, spacecraft housekeeping, SPICE, and the SPP EVA GUI.

## Layout

- `spp_file_retrieve.pro`, `spp_file_source.pro`: SSL downloads (below).
- `psp_fld_load.pro`, `spp_fld_load.pro`: the FIELDS loaders live here; see
  `projects/SPP/fields/AGENTS.md`. `spp_swp_mag_load.pro` and
  `spp_fld_mag_load.pro` are early-mission MAG loaders; use `psp_fld_load`.
- Packet (L0) reading: `spp_ssr_file_read.pro` (SSR files), `spp_ptp_file_read.pro`
  (PTP files), `spp_init_realtime.pro` (GSE sockets), APID registry
  `spp_apdat_info.pro`/`spp_apdat.pro`, base class `spp_gen_apdat__define.pro`.
- `sc/`: spacecraft housekeeping APID classes. `spice/`: `spice/spp_spice_kernels.pro`
  and `spice/spp_swp_spice.pro` (position and attitude tplot variables).
  `sppeva/`: burst-selection GUI (`sppeva/sppeva.pro`). `cdf_tools__define.pro`:
  CDF read/write object, used by the SPAN-e and SPC loaders.

## How `spp_file_retrieve` works

1. The caller passes one template relative to the data root (e.g.
   `psp/data/sci/sweap/spi/L3/spi_sf00/YYYY/MM/psp_swp_spi_sf00_L3*_YYYYMMDD_v??.cdf`)
   with `/daily_names` or `/hourly_names`, `trange`, `/last_version`, `/valid_only`.
2. It gets the cached source structure from `spp_file_source(source_key=key)`:
   key `'SWEAP'` unless the caller passes `key='FIELDS'`. A new source starts
   from `file_retrieve(/struct)`: local root `root_data_dir()`, remote
   `http://sprg.ssl.berkeley.edu/data/`, or `no_server` when
   `root_data_dir()+'psp/data/sci/sweap/.master'` exists (local tree = server).
3. It expands the template into one path per day or hour with `time_string`
   and passes them to `file_retrieve` (`general/misc/file_retrieve.pro`),
   which matches globs (`*`, `?`, `v??`) against the server listing.
   `/create_dir` only builds local paths and directories.

## Credentials

- Read from the environment once, when a key's source is first built. `'SWEAP'`
  (and any other key) uses `SPP_USER_PASS` (`user:password`). `'FIELDS'` uses
  `FIELDS_USER_PASS`, first overwritten with `PSP_STAGING_ID:PSP_STAGING_PW`
  (or `$USER:PSP_STAGING_PW`) when `PSP_STAGING_PW` is set. The value goes
  through `ssl_password`, which exists only compiled in `ssl_password.sav`.
- `spp_file_retrieve` has no `user_pass` keyword. To change the login in a
  session: `s = spp_file_source(source_key='FIELDS', user_pass='u:p', /reset)`.
  The file header warns not to use `/set` or `/reset` in distributed code.

## Compared with `spd_download`

- `spd_download` (`general/spedas_tools/spd_download/spd_download.pro`)
  takes `remote_path`/`local_path` and names already expanded (e.g. by
  `file_dailynames`). `spp_file_retrieve` expands dates itself and keeps server,
  local root and login in a common block, not in arguments or a `!` variable.
  In SPP only `projects/SPP/sweap/SPC/L3i/load/psp_load_swp.pro` uses `spd_download`.
- `YYYY MM DD hh mm ss DOY .f` are time codes, so a literal `ss` must be
  written `s\s` (`spp_fld_load` does this for `rfs_hfr_cross`).

## Things to know

- `spp_file_source_com` is also used by `projects/SWFO/STIS/swfo_file_source.pro`,
  with the same default key `'SWEAP'`; whichever runs first defines that source
  for both. The APID registry `spp_apdat_info_com` is shared with
  `projects/SWFO/STIS/swfo_apdat_info.pro` and `projects/swx/swx_apdat_info.pro`.
- `spp_ccsds_pkt_handler.pro` and `spp_apid_data.pro` begin with a bare text
  line ("obsolete", "deprecated") and do not compile. The working chain is
  `spp_ssr_file_read` -> `spp_swp_apdat_init`
  (`projects/SPP/sweap/COMMON/spp_swp_apdat_init.pro`) -> `spp_ssr_lun_read`
  -> `spp_ccsds_spkt_handler` (`projects/SPP/sweap/COMMON/spp_ccsds_spkt_handler.pro`).
- APID classes are registered as strings (`apid_obj='spp_sc_hk_0x081_apdat'`);
  grep for the quoted name. Decommutated tplot variables are `spp_*`.
