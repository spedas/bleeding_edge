---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/sta/mvn_sta_l2_load.pro
  - projects/maven/sta/mvn_sta_l2_tplot.pro
  - projects/maven/sta/mvn_sta_l2_crib.pro
  - projects/maven/sta/mvn_sta_l3_load.pro
  - projects/maven/sta/mvn_sta_l3_load_dlm.pro
  - projects/maven/sta/mvn_sta_l0_load.pro
  - projects/maven/sta/mvn_sta_l0_crib.pro
  - projects/maven/sta/mvn_sta_handler.pro
  - projects/maven/sta/mvn_sta_prod_cal.pro
  - projects/maven/sta/mvn_sta_stat.pro
  - projects/maven/sta/mvn_sta_current_sw_version.pro
  - projects/maven/sta/mvn_sta_functions/mvn_sta_get.pro
  - projects/maven/sta/mvn_sta_functions/mvn_sta_get_c6.pro
  - projects/maven/sta/mvn_sta_functions/mvn_sta_convert_units.pro
  - projects/maven/sta/l2util/mvn_sta_cmn_l2read.pro
  - projects/maven/sta/l2util/mvn_sta_l2gen.pro
  - projects/maven/sta/l2analysis/flow_vectors/mvn_sta_flow.pro
  - projects/maven/sta/L3_DO_NOT_USE/nbc_4d.pro
  - projects/maven/sta/STATIC readme.doc
  - projects/maven/general/mvn_pfp_spd_download.pro
  - projects/maven/DPU/mvn_pfp_l0_file_read.pro
  - projects/maven/swea/mvn_sta_coldion.pro
maintenance: |
  Update when mvn_sta_l2_load's keywords, file paths or common blocks change,
  when the L2 software version logic changes, or when a subfolder is added,
  removed or repurposed.
---

# MAVEN STATIC (IDL)

Code for STATIC (SupraThermal And Thermal Ion Composition), the ion mass
spectrometer: L2 loading into per-product common blocks, tplot, 4D distributions
and moments, L0 decoding and calibration, and the team's L2/L3 production.

## Layout

- `mvn_sta_l2_load.pro`: the main loader (L2 CDF -> common blocks);
  `mvn_sta_l2_tplot.pro` makes `mvn_sta_*` tplot variables from the common blocks;
  `mvn_sta_l2_crib.pro` shows typical use. `mvn_sta_stat.pro` reports what is loaded.
- `mvn_sta_l3_load.pro`: L3 densities and O2+ temperatures into tplot
  (`mvn_sta_l3_load_dlm.pro` is a disabled test copy).
- L0: `mvn_sta_l0_load.pro` (see `mvn_sta_l0_crib.pro`), packet decoding in
  `mvn_sta_handler.pro` and `mvn_sta_*_decom.pro`, calibration in
  `mvn_sta_prod_cal.pro` (7000 lines, sweep tables and configuration dates).
- `mvn_sta_functions/`: `mvn_sta_get_<apid>` and `mvn_sta_get` return 4D data
  structures; moments and plots (`n_4d`, `v_4d`, `t_4d`, `j_4d`, `nb_4d`, `vb_4d`,
  `contour4d`, `spec4d`, ...); `mvn_sta_functions/mvn_sta_convert_units.pro`.
- `mvn_sta_programs/`: fill extra fields of the loaded data: background
  (`mvn_sta_bkg_load`), dead time, quality flags (`mvn_sta_qf_load`), ephemeris,
  MAG, spacecraft potential (`mvn_sta_scpot_load`), blocked bins.
- `mvn_sta_gen_snapshot/`: cursor-driven snapshot plots (`mvn_sta_3d_snap`,
  `mvn_sta_slice2d_snap`, ...). `mvn_sta_gen_tplot_var/`: directional spectra.
- `l2analysis/`: analysis tools by topic (FOV, flow vectors in
  `l2analysis/flow_vectors/mvn_sta_flow.pro`, frame transforms, spectra).
- `l2util/`: L2 production and reading (`l2util/mvn_sta_l2gen.pro`,
  `l2util/mvn_sta_cmn_l2read.pro`, background "iv" levels, cron `.sh` scripts).
  `l3util/`: L3 file helper.
- `mvn_sta_tables/`: mass look-up tables read by `mvn_sta_prod_cal.pro`.
- `L3_DO_NOT_USE/`: L3 production code; skip it (but see below).
- `STATIC readme.doc`: a Word document from the instrument team.

## How `mvn_sta_l2_load` works

1. It builds the day list from `trange` (or `timerange()`) and the product list
   from `sta_apid` (array or space-separated string; `c?`, `d?` expand). The
   default is all products: 2a, c0-cf, d0-db.
2. For each product and day it fetches
   `maven/data/sci/sta/l2/YYYY/MM/mvn_sta_l2_<apid>*_YYYYMMDD_vNN.cdf` with
   `mvn_pfp_spd_download` (`projects/maven/general/mvn_pfp_spd_download.pro`),
   where NN comes from `mvn_sta_current_sw_version()`. `/no_update` only looks locally.
3. `mvn_sta_cmn_l2read` reads each file into an array of structures; days are
   concatenated and clipped to the time range.
4. Each product goes into its own common block, e.g.
   `common mvn_c6, mvn_c6_ind, mvn_c6_dat`. Tplot variables are made only with
   `/tplot_vars_create` (which calls `mvn_sta_l2_tplot`).
5. `iv_level=N` also reads and subtracts background from `maven/data/sci/sta/ivN/`.

`mvn_sta_l0_load` instead reads the daily PFP L0 file through
`projects/maven/DPU/mvn_pfp_l0_file_read.pro` with `/static`; `mvn_sta_prod_cal`
then fills the same common blocks, followed by dead-time and quality-flag loads.

## Things to know

- Products are named by packet ID (APID) and dimensions: c0 = 64 energies x 2
  masses, c6 = 32E x 64M, d0/d1 = 32E x 4 deflections x 16 anodes x 8M. Tplot
  names carry them (`mvn_sta_c6_M`, `mvn_sta_c0_E`).
- The common blocks `mvn_2a`, `mvn_c0` ... `mvn_db` are shared by all STATIC code.
  `mvn_sta_get('c6')` calls `'mvn_sta_get_'+apid` with `call_function` and sums
  over a time range; without `tt=` it asks for two clicks in the tplot window.
- 4D structures carry `units_procedure = 'mvn_sta_convert_units'`, so generic
  `conv_units` works. Moment functions take `mass=` and `m_int=`; `n_4d`, `nb_4d`
  and `j_4d` correct for the structure's `sc_pot` (STATIC's own estimate in L2).
- The loader only finds files of the current software version; to read an older
  version pass `l2_version_in`.
- `L3_DO_NOT_USE/` is still on the path: `nbc_4d` there is called by name from
  `projects/maven/swea/mvn_sta_coldion.pro`. STATIC cold-ion outflow code
  (`mvn_sta_coldion`, `mvn_sta_cio_*`) lives in `projects/maven/swea/`.
