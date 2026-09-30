---
related_files:
  - projects/SWFO/AGENTS.md
  - projects/SPP/COMMON/AGENTS.md
  - projects/SWFO/STIS/swfo_stis_load.pro
  - projects/SWFO/swfo_aws_nc2sav_makefile.pro
  - projects/SWFO/swfo_ccsds_frame_read.pro
  - projects/SWFO/STIS/swfo_apdat_info.pro
  - projects/SWFO/STIS/swfo_apdat.pro
  - projects/SWFO/STIS/swfo_stis_apdat_init.pro
  - projects/SWFO/STIS/swfo_gen_apdat__define.pro
  - projects/SWFO/STIS/ccsds_frame_reader__define.pro
  - projects/SWFO/STIS/ccsds_reader__define.pro
  - projects/SWFO/STIS/cmblk_reader__define.pro
  - projects/SWFO/STIS/gsemsg_reader__define.pro
  - projects/SWFO/STIS/ptp_reader__define.pro
  - projects/SWFO/STIS/swfo_stis_sci_apdat__define.pro
  - projects/SWFO/STIS/swfo_stis_nse_apdat__define.pro
  - projects/SWFO/STIS/swfo_stis_hkp_apdat__define.pro
  - projects/SWFO/STIS/swfo_stis_sci_level_0b.pro
  - projects/SWFO/STIS/swfo_stis_sci_level_1a.pro
  - projects/SWFO/STIS/swfo_stis_sci_level_1b.pro
  - projects/SWFO/STIS/swfo_stis_sci_level_2.pro
  - projects/SWFO/STIS/swfo_stis_sci_level_0b_defunct.pro
  - projects/SWFO/STIS/swfo_stis_inst_response_calval.pro
  - projects/SWFO/STIS/swfo_stis_adc_map.pro
  - projects/SWFO/STIS/swfo_stis_write_ground_lut_from_calval.pro
  - projects/SWFO/STIS/groundlut_template.sh
  - projects/SWFO/STIS/templates/sfwo_stis_l0b_MASTER.nc
  - projects/SWFO/STIS/swfo_ncdf_read.pro
  - projects/SWFO/STIS/swfo_ncdf_create.pro
  - projects/SWFO/STIS/swfo_stis_tplot.pro
  - projects/SWFO/STIS/swfo_stis_plot.pro
  - projects/SWFO/STIS/swfo_stis_crib.pro
  - projects/SWFO/STIS/swfo_stis_sci_l1b_crib.pro
  - projects/SWFO/STIS/swfo_init_realtime.pro
  - projects/SWFO/STIS/swfo_file_retrieve.pro
  - projects/SWFO/STIS/swfo_file_source.pro
  - projects/SWFO/STIS/ace_load.pro
  - general/misc/file_stuff/socket_reader__define.pro
  - general/tools/misc/dynamicarray__define.pro
maintenance: |
  Update when the STIS level chain (L0b, L1a, L1b, L2) or its calibration
  source changes, when swfo_stis_load gains or drops file types, or when the
  APID table or the reader classes change.
---

# SWFO STIS

Ground processing for STIS, SSL's ion and electron sensor on SWFO-L1
(SOLAR-1), plus the packet framework the whole SWFO folder uses. It is a copy
of the PSP SWEAP framework (`projects/SPP/COMMON/`), renamed `swfo_`.

## Layout (one flat folder)

- Readers, subclasses of `socket_reader` (`general/misc/file_stuff/socket_reader__define.pro`):
  `ccsds_frame_reader__define.pro` (L0 transfer frames), `ccsds_reader__define.pro`,
  `cmblk_reader__define.pro` (SSL "common block" GSE files), `gsemsg_reader__define.pro`,
  `ptp_reader__define.pro`, JSON/ASCII readers, and lab-equipment readers (`gse_*`).
- APID registry: `swfo_apdat_info.pro`, `swfo_apdat.pro`, base class
  `swfo_gen_apdat__define.pro`. `swfo_stis_apdat_init.pro` registers every
  mission APID: spacecraft 100-170, STIS 0x350-0x35F, MAG 1253/1254.
- STIS packet classes: `swfo_stis_sci_apdat__define.pro`,
  `swfo_stis_nse_apdat__define.pro` (noise), `swfo_stis_hkp_apdat__define.pro`, ...
- Level products: `swfo_stis_sci_level_0b.pro` -> `swfo_stis_sci_level_1a.pro`
  -> `swfo_stis_sci_level_1b.pro` -> `swfo_stis_sci_level_2.pro`.
  `swfo_stis_sci_level_0b_defunct.pro` is superseded.
- Calibration: `swfo_stis_inst_response_calval.pro` (constants dictionary),
  `swfo_stis_adc_map.pro`, response modeling (`swfo_stis_inst_response*.pro`,
  `swfo_stis_response_*.pro`), ground LUTs (`groundlut_*.nc`, `groundlut_template.sh`,
  `swfo_stis_write_ground_lut_from_calval.pro`).
- NetCDF: `swfo_ncdf_read.pro`, `swfo_ncdf_create.pro`, L0b template
  `templates/sfwo_stis_l0b_MASTER.nc`.
- Plotting: `swfo_stis_tplot.pro` (`/setlim`), `swfo_stis_plot.pro`
  (interactive spectra via `ctime`). Cribs: `swfo_stis_crib.pro`,
  `swfo_stis_sci_l1b_crib.pro` and other `*_crib.pro`.
- `ace_load.pro`: ACE real-time EPAM loader for comparison plots.

## How `swfo_stis_load` works

1. Default `file_type='aws'`: `swfo_aws_nc2sav_makefile, /load_sav`
   (`projects/SWFO/swfo_aws_nc2sav_makefile.pro`) restores decommutated
   `.sav` files from sprg `swfo/data/sci/aws/.sav/` for one station (default
   `WCD`); `daily=1` (default) uses daily files, `lowres=1`/`2` their 1-min or
   30-min averages.
2. `swfo_apdat_info, /cr, /print, /sort, /uniq, /merge` (`/cr` is
   `create_tplot_vars`) makes L0a tplot variables (`swfo_stis_sci_*`, ...).
3. `/l0b`, `/l1a`, `/l1b`, `/l2` compute each level in memory with the
   `cal=` dictionary from `swfo_stis_inst_response_calval` and store
   `swfo_stis_L0b`, `swfo_stis_L1a`, `swfo_stis_L1b`, `swfo_stis_L2`.
4. `swfo_stis_tplot, /setlim, cal=cal` sets plot limits.

Other `file_type`s (`gsemsg`, `cmblk`, `ccsds`, `ptp`, `ncdf`) with a
`station` (`S0`-`S3`, `Ball`, `STIS`, ...) read pre-launch GSE files or
connect to GSE hosts, as does `swfo_init_realtime`.

## Things to know

- L0b gathers sci, noise and housekeeping fields into one structure per sample;
  L1a sorts counts by detector (O1-O3, F1-F3), energy bins and noise; L1b
  merges small and large pixels into ion and electron fluxes and adds
  quality bits. Each is an array of structures in a `dynamicarray`; tplot
  variables point at it (`store_data, tagnames=`, `val_tag` for energies).
- `swfo_stis_inst_response_calval` caches its dictionary in a common block;
  `/reset` rebuilds it.
- Shared state with PSP: `swfo_apdat_info` uses `spp_apdat_info_com` and
  `swfo_file_source` uses `spp_file_source_com` (default key `'SWEAP'`, with
  a built-in test login); see `projects/SPP/COMMON/AGENTS.md`.
  `swfo_file_retrieve.pro` and `swfo_file_source.pro` are pre-launch copies of
  the PSP download wrapper, used only by GSE code.
- `swfo_stis_apdat_init, /swem` registers PSP SWEM classes
  (`spp_swp_swem_dhkp_apdat`, ...), which need `projects/SPP/` on `!PATH`.
