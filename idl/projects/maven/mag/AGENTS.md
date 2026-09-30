---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/mag/mvn_mag_load.pro
  - projects/maven/mag/mvn_mag_sts_read.pro
  - projects/maven/mag/mvn_mag_l1_sts_read.pro
  - projects/maven/mag/mvn_mag_sts_to_sav.pro
  - projects/maven/mag/mvn_mag_gen_l1_sav.pro
  - projects/maven/mag/mvn_mag_gen_sav.pro
  - projects/maven/mag/mvn_mag_batch.pro
  - projects/maven/mag/mvn_mag_load_ql.pro
  - projects/maven/mag/mvn_mag_handler.pro
  - projects/maven/mag/mav_apid_mag_handler.pro
  - projects/maven/mag/mvn_mag_crib.pro
  - projects/maven/mag/mvn_mag_geom.pro
  - projects/maven/mag/mvn_mag_trace.pro
  - projects/maven/mag/mvn_mag_ql.pro
  - projects/maven/mag/mvn_mag_ql_tsmaker.pro
  - projects/maven/mag/maven_mag_pkts_read.pro
  - projects/maven/general/mvn_pfp_file_retrieve.pro
  - projects/maven/general/mvn_frame_name.pro
  - projects/maven/sep/mvn_sep_batch.pro
  - projects/maven/sep/mvn_save_reduce_timeres.pro
  - projects/maven/DPU/mvn_pfp_l0_file_read.pro
  - projects/maven/swea/mvn_mag_tplot.pro
  - projects/maven/swea/mvn_swe_addmag.pro
maintenance: |
  Update when mvn_mag_load's formats, frames, file paths or tplot names change,
  or when the server-side STS-to-save conversion moves or changes its output.
---

# MAVEN MAG (IDL)

Code for the MAVEN magnetometers (two sensors: MAG1 outboard, MAG2 inboard).
Users load the save files made from the MAG team's STS files with
`mvn_mag_load`; the rest decodes L0 packets, makes those save files, or computes
field geometry.

## Layout

- `mvn_mag_load.pro`: the loader for all formats (below).
- `mvn_mag_sts_read.pro`, `mvn_mag_l1_sts_read.pro`: read STS text files.
- `mvn_mag_sts_to_sav.pro`: server-side conversion of STS files to daily IDL save
  files, run from `projects/maven/sep/mvn_sep_batch.pro` together with
  `mvn_save_reduce_timeres` (`projects/maven/sep/mvn_save_reduce_timeres.pro`),
  which makes the 1 s and 30 s files. `mvn_mag_gen_l1_sav.pro`,
  `mvn_mag_gen_sav.pro`, `mvn_mag_batch.pro` and `mvn_mag_load_ql.pro` are
  obsolete (they stop or say so).
- L0 packets: `mvn_mag_handler.pro` decodes MAG packets during
  `mvn_pfp_l0_file_read, /mag` (`projects/maven/DPU/mvn_pfp_l0_file_read.pro`)
  (e.g. from `mvn_sep_load, /l0`) into common `mav_apid_mag_handler_com`;
  `mvn_mag_crib.pro` is an early example. `mav_apid_mag_handler.pro` is the
  prelaunch version.
- `mvn_mag_geom.pro`, `mvn_mag_trace.pro`: field angles in the local horizontal
  frame and straight-line tracing to an altitude (need ephemeris).
- `mvn_mag_ql.pro`, `mvn_mag_ql_tsmaker.pro`, `maven_mag_pkts_read.pro` and small
  helpers (`bitlis`, `checksum_16bits`, `marker_search`, `parsestr`, `cmsystime`):
  the MAG team's quicklook from raw packet files.

## How `mvn_mag_load` works

1. `format` (first argument) is `LEVEL_RES`: level `L1` or `L2`, resolution
   `FULL`, `1SEC` or `30SEC`. The default is `'L2_1SEC'`. Other formats:
   `'L2_STS'`, `'L1_STS'`, `'L1_CDF'`, `'L1_SAV'`.
2. For save files the path is
   `maven/data/sci/mag/<level>/sav/<res>/YYYY/MM/mvn_mag_<level>_<frame>_<res>_YYYYMMDD.sav`,
   fetched with `mvn_pfp_file_retrieve`
   (`projects/maven/general/mvn_pfp_file_retrieve.pro`).
3. If no L2 file is found it falls back to L1 (prints that L1 may not be used for
   publication) unless `/l2only`.
4. It restores each file (for L2 picking the sensor, `mag_product='MAG1'` or
   `'MAG2'`) and stores `mvn_B_<res>` (e.g. `mvn_B_1sec`) in nT with a
   `spice_frame` dlimit.
5. `spice_frame=` (any name `mvn_frame_name` understands, e.g. 'MSO') also stores
   `mvn_B_<res>_<FRAME>` rotated with SPICE; kernels must already be loaded.

## Things to know

- `mag_frame` selects the file: 'pl' = payload (`MAVEN_SPACECRAFT`, default),
  'pc' = planetocentric (`IAU_MARS`), 'ss' = `MAVEN_SSO`. The batch job only makes
  pl and pc save files.
- The 1 s and 30 s files are time averages of the full-resolution files.
- STS reads (`L1_STS`, `L2_STS`) only read the first file of the range.
- Other MAG tools live elsewhere: `projects/maven/swea/mvn_mag_tplot.pro`
  (log-amplitude panels) and `projects/maven/swea/mvn_swe_addmag.pro`
  (MAG in the SWEA frame for pitch angles).
