---
related_files:
  - projects/SPP/AGENTS.md
  - projects/SPP/COMMON/AGENTS.md
  - projects/SPP/COMMON/psp_fld_load.pro
  - projects/SPP/COMMON/spp_fld_load.pro
  - projects/SPP/COMMON/spp_file_retrieve.pro
  - projects/SPP/fields/common/spp_fld_load_l1.pro
  - projects/SPP/fields/common/spp_fld_tmlib_init.pro
  - projects/SPP/fields/common/spp_fld_config.pro
  - projects/SPP/fields/l1/l1_mag_survey/spp_fld_mago_survey_load_l1.pro
  - projects/SPP/fields/l2/load/psp_fld_rfs_load_l2.pro
  - projects/SPP/fields/l2/load/psp_fld_tds_wf_load_l2.pro
  - projects/SPP/fields/l2/load/psp_fld_dfb_spec_load_l2.pro
  - projects/SPP/fields/l2/psp_fld_aeb_mplot.pro
  - projects/SPP/fields/util/spp_fld_rfs_freqs.pro
  - projects/SPP/fields/util/spp_fld_timespan.pro
  - projects/SPP/fields/util/spp_fld_make_or_retrieve_cdf.pro
  - projects/SPP/fields/util/misc/psp_fld_qf_filter.pro
  - projects/SPP/fields/util/misc/psp_fld_common.pro
  - projects/SPP/fields/crib/psp_fld_examples.pro
  - projects/SPP/fields/csv/rfs_csv_dummy.pro
  - projects/SPP/fields/colors/spp_colors_dummy.pro
  - projects/SPP/fields/colors/spp_fld_colors.tbl
  - projects/SPP/fields/l2/load/old
  - projects/SPP/fields/crib/test_crib
  - general/CDF/cdf2tplot.pro
maintenance: |
  Update when spp_fld_load changes how it picks the level, path or loader for a
  type, when an L1 product folder or special L2 loader is added, or when the
  quality-flag bits or the psp_/spp_ wrapper split change.
---

# PSP FIELDS

Support code for PSP/FIELDS (MAG, SCM, DFB, RFS, TDS, AEB, ...). The entry
points `psp_fld_load` and `spp_fld_load` are in `projects/SPP/COMMON/`;
this folder holds the L1 loaders, special L2 loaders, utilities and cribs they
call. The FIELDS SOC also uses it to load the non-public L1 and L1b files.

## Layout

- `l1/l1_<product>/` (29 folders): `spp_fld_<product>_load_l1.pro` per product,
  sometimes a `*_convert.pro`.
- `l2/load/`: `l2/load/psp_fld_rfs_load_l2.pro`, `l2/load/psp_fld_tds_wf_load_l2.pro`,
  and the standalone `l2/load/psp_fld_dfb_spec_load_l2.pro` (takes file names;
  `spp_fld_load` does not call it). `l2/load/old/`: older `psp_load_*`
  loaders; skip. `l2/psp_fld_aeb_mplot.pro` is the `tplot_routine` for AEB panels.
- `common/`: `common/spp_fld_load_l1.pro` (L1 dispatcher),
  `common/spp_fld_tmlib_init.pro`, `common/spp_fld_config.pro` (color setup).
- `util/`: frequency tables (`util/spp_fld_rfs_freqs.pro`, `spp_fld_dfb_frequencies`),
  orbit and encounter time ranges (`util/spp_fld_timespan.pro`:
  `spp_fld_timespan, 1, /encounter`), MDE readers, plot helpers (`psp_fld_popen`,
  `psp_fld_tplot_pdf`). `util/misc/psp_fld_qf_filter.pro` filters by quality
  flag; `util/misc/psp_fld_common.pro` is its include file.
- `crib/`: `crib/psp_fld_examples.pro` (start here), more examples; `crib/test_crib/`:
  SOC ground tests. `colors/`: color tables. `csv/`: RFS (and LuSEE) frequencies.

## How `psp_fld_load` loads data

1. `psp_fld_load` (`projects/SPP/COMMON/psp_fld_load.pro`) passes its
   keywords to `spp_fld_load` (`projects/SPP/COMMON/spp_fld_load.pro`);
   both default to `level=2` and skip the retired `/staging/` tree.
2. `spp_fld_load` overrides the level for some types: L1 for `ephem*`,
   `sc_hk_*`, `mago_survey` and others in its `l1_types` list; 1.5 (L1b) for
   `magi_*` (not `magi_survey`, `magi_hk`), `dfb_wf_b*`, `dfb_dbm_b*`; L3 for
   `merged_scam_wf`, `sqtn_rfs_V1V2`, `sqtn_rfs_V3V4`, `rfs_lfr_qtn`. Other L3
   types (`rfs_lfr`, `rfs_hfr`, `dust`) need `level=3`.
3. It builds `psp/data/sci/fields/l2/<type>/YYYY/MM/psp_fld_l2_<type>_YYYYMMDD_v??.cdf`.
   `mag_RTN`, `mag_SC`, `mag_VSO` and several `dfb_wf_*`/`dfb_dbm_*` types have
   four 6-hour files per day (`YYYYMMDDhh`). A bare `dfb_ac_spec`, `dfb_dc_xspec`,
   `dfb_ac_bpf` etc. loops over every sensor source. `spp_file_retrieve(key='FIELDS')`
   downloads the files (see `projects/SPP/COMMON/AGENTS.md`).
4. L2/L3 files go to `cdf2tplot` (`general/CDF/cdf2tplot.pro`, all variables),
   except `rfs_?fr` (`psp_fld_rfs_load_l2`, which skips empty variables) and
   `tds_wf`. L1 files go to `spp_fld_load_l1`, which reads the CDF global
   attribute `Logical_source` (e.g. `SPP_FLD_MAGO_SURVEY`), drops trailing
   digits and runs `<logical_source>_load_l1` with `call_procedure`, e.g.
   `l1/l1_mag_survey/spp_fld_mago_survey_load_l1.pro`.
5. It sets plot options per type and makes `psp_fld_l?_quality_flags` a `bitplot`.

## Things to know

- tplot names are the CDF variable names: `psp_fld_l2_mag_RTN_4_Sa_per_Cyc`,
  `psp_fld_l2_rfs_hfr_auto_averages_ch0_V1V2`, `psp_fld_l2_quality_flags`.
  L1 names start with `spp_fld_` (`spp_fld_mago_survey_nT`).
- Where `util/` has both `psp_fld_<x>` and `spp_fld_<x>`, the `psp_` one is a
  thin wrapper or copy of the `spp_` one.
- `psp_fld_qf_filter, tvar, flags` (MAG RTN/SC, RFS, AEB variables) makes
  `<tvar>_<flags>`. Bits: 1 bias sweep, 2 thruster firing, 4 SCM calibration,
  8 MAG roll, 16 MAG calibration, 32 SPC electron mode, 64 SLS test, 128
  off-umbra pointing; `0` keeps unflagged data, `-1` also keeps 128-only.
  `spp_fld_load` labels three higher bits the filter does not accept.
- The CSV and `.tbl` files are found by searching every `!PATH` directory by
  name. `csv/rfs_csv_dummy.pro` and `colors/spp_colors_dummy.pro` are empty
  routines that put those folders on `!PATH`; keep them.
- The first L1 load runs `spp_fld_tmlib_init` if `!SPP_FLD_TMLIB` is undefined;
  it reads `SPP_FLD_CDF_DIR` and resets `!p.background` and `!p.color`.
- L2 and L3 are public; L1 and L1b need `FIELDS_USER_PASS`.
- Nothing in SPEDAS calls the `l1/*_convert.pro` routines; the SOC CDF
  production code (`spp_fld_make_cdf_l1`) is not in this repository.
  `util/spp_fld_make_or_retrieve_cdf.pro` is marked outdated.
