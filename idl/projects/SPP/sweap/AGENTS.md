---
related_files:
  - projects/SPP/AGENTS.md
  - projects/SPP/COMMON/AGENTS.md
  - projects/SPP/COMMON/spp_file_retrieve.pro
  - projects/SPP/sweap/SPAN/electron/spp_swp_spe_load.pro
  - projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro
  - projects/SPP/sweap/SPAN/ion/CDF/psp_swp_spi_make_cdf_l2.pro
  - projects/SPP/sweap/SPAN/spp_swp_qf.pro
  - projects/SPP/sweap/SPAN/spp_swp_spe_prod_apdat__define.pro
  - projects/SPP/sweap/SPAN/spp_swp_spi_prod_apdat__define.pro
  - projects/SPP/sweap/SPAN/common/spp_swp_span_crib.pro
  - projects/SPP/sweap/SPC/spp_swp_spc_load.pro
  - projects/SPP/sweap/SPC/L3i/load/psp_load_swp.pro
  - projects/SPP/sweap/SPC/L3i/config/psp_swp_init.pro
  - projects/SPP/sweap/SPC/L3i/plot/psp_dyplot.pro
  - projects/SPP/sweap/SPC/L3i/misc/psp_filter_swp.pro
  - projects/SPP/sweap/SWEM/spp_swp_swem_load.pro
  - projects/SPP/sweap/COMMON/spp_swp_load.pro
  - projects/SPP/sweap/COMMON/spp_swp_apdat_init.pro
  - projects/SPP/sweap/COMMON/spp_ccsds_spkt_handler.pro
  - projects/SPP/sweap/COMMON/spp_swp_crib.pro
  - projects/SPP/sweap/COMMON/TABLES
  - projects/SPP/sweap/COMMON/obsolete
  - projects/SPP/sweap/SPAN/ion/DEPRECATED
  - projects/SPP/sweap/BACKUP
  - projects/SPP/sweap/spp_swp_functions.pro
  - projects/SPP/sweap/spp_swp_startup.pro
  - general/spedas_tools/spd_download/spd_download.pro
maintenance: |
  Update when a SWEAP loader changes its defaults, server, file layout or
  tplot prefix, when the SPC loaders are merged or renamed, or when the
  SPAN/SPC/SWEM subfolders are reorganized.
---

# PSP SWEAP

Loaders and team tools for SWEAP: SPAN-e (electron analyzers SPAN-A and
SPAN-B), SPAN-i (ion analyzer with time-of-flight), SPC (Faraday cup) and SWEM
(electronics module). Most non-loader code is team tooling: packet
decommutation, sweep tables, flight configuration, calibration.

## Layout

- `SPAN/electron/`, `SPAN/ion/`: the loaders `SPAN/electron/spp_swp_spe_load.pro`
  and `SPAN/ion/spp_swp_spi_load.pro`; SPAN-i flight tables and configuration
  (`spp_swp_spi_flight_*`, `spp_swp_spi_config_*`); L2 production
  `SPAN/ion/CDF/psp_swp_spi_make_cdf_l2.pro`; `SPAN/ion/DEPRECATED/` (skip).
- `SPAN/`: `SPAN/spp_swp_qf.pro` (quality-flag plot options), product APID classes
  (`SPAN/spp_swp_spe_prod_apdat__define.pro`, `SPAN/spp_swp_spi_prod_apdat__define.pro`);
  `SPAN/common/spp_swp_span_crib.pro` explains SPAN-e product names.
- `SPC/`: team loader and decom; `SPC/L3i/` is a separate public-data package.
- `SWEM/`: SWEM APID classes and the L1 housekeeping loader `SWEM/spp_swp_swem_load.pro`.
- `COMMON/`: `COMMON/spp_swp_load.pro`, the APID table `COMMON/spp_swp_apdat_init.pro`,
  `COMMON/spp_ccsds_spkt_handler.pro`, the crib `COMMON/spp_swp_crib.pro`.
  `COMMON/TABLES/`: older sweep-table code; `COMMON/obsolete/`: skip.
- `decom/`: packet decommutators, one file per flight-software version in
  `decom/spane/` and `decom/spani/`. `tables/`: sweep-table generation.
- `magSwing/`, `wpc/`: pre-launch ground-test code. `BACKUP/`: skip.
  `spp_swp_functions.pro`, `spp_swp_startup.pro`: old, mostly superseded.

## Loaders

All use `spp_file_retrieve` (SSL server, `SPP_USER_PASS`; see
`projects/SPP/COMMON/AGENTS.md`) except `psp_load_swp`.

- `spp_swp_spe_load`: default `level='L3'`, `types='sf0'`, `spxs='spe'` (SPAN-A
  and B merged, `spe/L3/spe_sf0_pad/` files). L3 is read with `cdf_tools`, not
  `cdf2tplot`, into pitch-angle spectra at energy steps `esteps`
  (`EFLUX_VS_PA_E<n>`, normalized `NFLUX_VS_PA_E<n>`). With `level='L2'`,
  `spxs` becomes `['spa','spb']` and `cdf2tplot` is used. Prefix
  `psp_swp_<spx>_<type>_<level>_`.
- `spp_swp_spi_load`: default `level='L3'`, `types='sf00'`; prefix
  `psp_swp_spi_<type>_<level>_` (e.g. `psp_swp_spi_sf00_L3_DENS`). Type code:
  survey/archive (`s`/`a`), full/targeted sweep (`f`/`t`), product number,
  species (`0` protons; `1` and `a` treated as m/q = 2). `rtn_frame=1..3` adds
  RTN velocities, Alfven speed, Venus geometry (SPICE); `/overlay` adds overlays.
- SPC has two unrelated loaders:
  - `spp_swp_spc_load` (`SPC/spp_swp_spc_load.pro`), team server: default
    `type='l3i'` from `psp/data/sci/sweap/spc/L3/` (also `l2`, `l1`), prefix
    `psp_swp_spc_<type>_`. It makes `DQF_bits`; `/nul_bad` sets flagged samples
    to NaN; `/extras` derives temperatures and SPAN-i-frame angles. `/peaktrack`,
    `/fullscan`, `/flowangle` restore daily tplot save files instead.
  - `psp_load_swp` (`SPC/L3i/load/psp_load_swp.pro`), public: L3i from SPDF
    (`https://spdf.gsfc.nasa.gov/pub/data/psp/sweap/spc/l3/l3i/`) with
    `spd_download`, settings in `!psp_sweap` from `SPC/L3i/config/psp_swp_init.pro`
    (kept in `psp_sweap_config.txt` in the IDL user directory), prefix
    `psp_spc_`. Uncertainties go in `dy` (or `dyL`/`dyH`) for
    `SPC/L3i/plot/psp_dyplot.pro`; `SPC/L3i/misc/psp_filter_swp.pro` filters by DQF.
- `spp_swp_load, /spe, /spi, /spc, /fld`: calls those loaders, then always runs
  its own loop over `spxs` (default SPAN-A, SPAN-B, SPAN-i, SWEM; level L1; all
  types) and sets `ystyle=3` on every tplot variable.

## Things to know

- `SPAN/ion/spp_swp_spi_load.pro` also defines `diagonalize_tensor` and
  `rotate_t_tensor` above the loader. They have generic names, exist only
  after this file compiles, and the loader does not call them.
- `spp_swp_spc_load, /extras` writes unprefixed tplot names (`Density`,
  `Velocity_mag`, `Temperature`, ...) that can overwrite other variables.
- `spp_swp_spi_load, /overlay, /spcname` expects `psp_swp_spc_l3i_vp_moment_SC`,
  a `spp_swp_spc_load` name, not a `psp_load_swp` one.
- `COMMON/spp_swp_apdat_init.pro` names APID classes (`apid_obj='spp_swp_spi_tof_apdat'`)
  and decom routines (`routine='spp_swp_spani_event_decom'`) as strings.
