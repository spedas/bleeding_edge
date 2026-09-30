---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/sep/mvn_sep_load.pro
  - projects/maven/sep/mvn_sep_var_restore.pro
  - projects/maven/sep/purgatory/mvn_sep_cal_to_tplot.pro
  - projects/maven/sep/mvn_sep_get_cal_units.pro
  - projects/maven/sep/mvn_sep_handler.pro
  - projects/maven/sep/mvn_sep_handler_commonblock.pro
  - projects/maven/sep/mvn_pfdpu_handler_commonblock.pro
  - projects/maven/sep/mvn_lpw_handler.pro
  - projects/maven/sep/mvn_sep_anc_load.pro
  - projects/maven/sep/ancillary/mvn_sep_get_anc_data.pro
  - projects/maven/sep/mvn_sep_pad_load_tplot.pro
  - projects/maven/sep/mvn_sep_pad.pro
  - projects/maven/sep/mvn_sep_tplot.pro
  - projects/maven/sep/mvn_sep_crib.pro
  - projects/maven/sep/mvn_sep_batch.pro
  - projects/maven/sep/mvn_save_reduce_timeres.pro
  - projects/maven/sep/mvn_sep_save_reduce_timeres.pro
  - projects/maven/sep/cdf/mvn_sep_makefile.pro
  - projects/maven/sep/mvn_sep_make_kp.pro
  - projects/maven/sep/fov/mvn_sep_fov.pro
  - projects/maven/sep/mvn_sep_inst_response.pro
  - projects/maven/DPU/mvn_pfp_l0_file_read.pro
  - projects/maven/mag/mvn_mag_sts_to_sav.pro
  - projects/maven/euv/mvn_euv_l0_load.pro
maintenance: |
  Update when mvn_sep_load's formats, file paths or tplot names change, when the
  SEP common block changes, when routines move out of purgatory/, or when
  mvn_sep_batch changes what it produces.
---

# MAVEN SEP (IDL)

Code for SEP (Solar Energetic Particle): two sensors (SEP1, SEP2), each with a
forward (F) and rear (R) look direction, measuring ions and electrons. The
folder also holds the SEP L0 packet handler and the SSL batch job that makes
SEP, MAG and EUV products.

## Layout

- `mvn_sep_load.pro`: the loader (below). `mvn_sep_crib.pro` shows it with
  ancillary data, MAG and SWIA.
- `mvn_sep_var_restore.pro`: restores L1 save files into the SEP common block;
  `purgatory/mvn_sep_cal_to_tplot.pro` converts them to calibrated tplot
  variables using `mvn_sep_get_cal_units.pro`.
- `mvn_sep_handler.pro`: decodes SEP packets from L0 (also defines
  `mvn_sep_var_save` and other helpers); common block declared in
  `mvn_sep_handler_commonblock.pro`. `mvn_pfdpu_handler_commonblock.pro` and
  `mvn_lpw_handler.pro` (LPW packets) also live here.
- Ancillary (look directions, Sun/Mars angles): `mvn_sep_anc_load.pro` (CDF),
  `ancillary/mvn_sep_get_anc_data.pro` (computed with SPICE), `mvn_sep_anc_*`.
- Pitch angles: `mvn_sep_pad.pro`; L3 PAD files are read by `mvn_sep_load, /pad`
  with `mvn_sep_pad_load_tplot.pro`.
- `fov/`: field-of-view geometry, Mars shine and X-ray occultation
  (`fov/mvn_sep_fov.pro`). `mvn_sep_inst_response.pro`, `deconvolve/`, `sim/`:
  instrument response and flux fitting.
- Production (SSL): `mvn_sep_batch.pro` (cron script), `cdf/mvn_sep_makefile.pro`
  (L2 CDFs), `mvn_sep_save_reduce_timeres.pro` (5 min, 1 hr, 32 s L1 files),
  `mvn_sep_make_kp.pro`, `mvn_sep_gen_plots`, `mvn_sep_gen_ql`.
- `mvn_sep_tplot.pro`: named tplot layouts ('SUM', 'ION', 'ELEC', ...).
- `integration/`, `obsolete/`, `script_*`, `*attenuator*`: prelaunch and test
  code. `purgatory/`: retired code, except `mvn_sep_cal_to_tplot` and
  `mvn_sep_inst_response_peakeinc`, which are still called.

## How `mvn_sep_load` works

1. `/pad` restores L3 PAD save files and returns. `/ancillary` also loads the
   ancillary CDFs.
2. The format is `'L1_SAV'` (default), `'L2_CDF'` (`/l2`) or `'L0_RAW'` (`/l0`).
3. L1_SAV: `mvn_sep_var_restore` fetches
   `maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_????.sav` (or
   `sav_5min`, `sav_01hr`, `sav_32sec` with `lowres=1,2,3`), restores them into
   the common block, then `mvn_sep_cal_to_tplot` makes `mvn_SEP1F_ion_eflux`,
   `mvn_SEP1R_elec_eflux`, ... (`mvn_5min_SEP...` for low resolution,
   `mvn_arc_SEP...` for burst).
4. L2_CDF: `cdf2tplot` on
   `maven/data/sci/sep/l2/YYYY/MM/mvn_sep_l2_s<N>-cal-svy-full_YYYYMMDD_v0?_r??.cdf`
   with prefix `mvn_L2_sep<N>` (e.g. `mvn_L2_sep1f_ion_flux`); `/eflux` adds
   energy-flux variables.
5. L0_RAW: fetches the daily PFP L0 file and runs `mvn_pfp_l0_file_read`
   (`projects/maven/DPU/mvn_pfp_l0_file_read.pro`) with SEP, MAG and PFDPU
   decoding on.

## Things to know

- SEP data live in pointers in common `mav_apid_sep_handler_com`
  (`sep1_svy`, `sep2_svy`, `sep1_arc`, ...). Code includes it with
  `@mvn_sep_handler_commonblock.pro` (with the extension).
- L1 save files are decoded L0 packets, not calibrated data; calibration happens
  at load time in `mvn_sep_get_cal_units`.
- The L0 path also fills the MAG packet common block, so `mvn_sep_load, /l0`
  followed by `mvn_mag_handler` gives raw MAG data.
- `mvn_sep_batch.pro` is a main-level script (it ends with `exit`); it also runs
  `mvn_mag_sts_to_sav` (`projects/maven/mag/mvn_mag_sts_to_sav.pro`),
  `mvn_save_reduce_timeres.pro` for MAG, and `mvn_euv_l0_load`
  (`projects/maven/euv/mvn_euv_l0_load.pro`). Don't run it outside SSL.
