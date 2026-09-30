---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/lpw/crib_mvn_lpw_example.pro
  - projects/maven/lpw/mvn_lpw_load_l2.pro
  - projects/maven/lpw/mvn_lpw_cdf_read.pro
  - projects/maven/lpw/mvn_lpw_cdf_latest_file.pro
  - projects/maven/lpw/mvn_lpw_cdf_read_file.pro
  - projects/maven/lpw/mvn_lpw_cdf_cdf2tplot.pro
  - projects/maven/lpw/mvn_lpw_cdf_read_extras.pro
  - projects/maven/lpw/mvn_lpw_load_l0.pro
  - projects/maven/lpw/mvn_lpw_load.pro
  - projects/maven/lpw/mvn_lpw_load_file.pro
  - projects/maven/lpw/mvn_lpw_r_header_l0.pro
  - projects/maven/lpw/mvn_lpw_pkt_instrument_constants.pro
  - projects/maven/lpw/mvn_lpw_anc_get_spice_kernels.pro
  - projects/maven/lpw/mvn_lpw_anc_spacecraft.pro
  - projects/maven/lpw/mvn_lpw_anc_boom.pro
  - projects/maven/lpw/mvn_lpw_cal_read_bias.pro
  - projects/maven/lpw/mvn_lpw_cdf_write.pro
  - projects/maven/lpw/mvn_lpw_cdf_produce_l2.pro
  - projects/maven/lpw/mvn_lpw_save_l0.pro
  - projects/maven/general/mvn_pfp_file_retrieve.pro
  - projects/maven/sep/mvn_lpw_handler.pro
  - projects/maven/swea/mvn_lpw_load_dlm.pro
  - projects/maven/euv/mvn_euv_load.pro
maintenance: |
  Update when mvn_lpw_load_l2 or mvn_lpw_cdf_read change product codes, tplot
  names or file paths, when the L0 load chain changes, or when the calibration
  files or the mvn_lpw_software variable handling change.
---

# MAVEN LPW (IDL)

Code for LPW (Langmuir Probe and Waves). It loads L2 (and L1a/L1b) CDF files
into tplot, decodes L0 packets into L1-like tplot variables, and produces the
derived L1b/L2 products (Langmuir-probe fits, wave spectra, densities, spacecraft
potential). Written by the LPW team at LASP (C. Fowler, L. Andersson).

## Layout

- `crib_mvn_lpw_example.pro`: start here.
- L2 loading: `mvn_lpw_load_l2.pro` (time range) -> `mvn_lpw_cdf_read.pro` (one
  date; picks the newest file with `mvn_lpw_cdf_latest_file.pro`) ->
  `mvn_lpw_cdf_read_file.pro` (exact files) -> `mvn_lpw_cdf_cdf2tplot.pro` and
  `mvn_lpw_cdf_read_extras.pro` (splits Ne, Te, Vsc).
- L0 loading: `mvn_lpw_load_l0.pro` (time range) -> `mvn_lpw_load.pro` (one day;
  downloads the PFP L0 file and SPICE kernels) -> `mvn_lpw_load_file.pro`, which
  reads headers (`mvn_lpw_r_header_l0.pro`, other `mvn_lpw_r_*`) and runs one
  `mvn_lpw_pkt_<type>` decoder per packet type (atr, euv, adr, hsk, e12_dc, swp,
  spectra, hsbm, htime) with constants from `mvn_lpw_pkt_instrument_constants.pro`.
- `mvn_lpw_prd_*`: derived products: Langmuir probe I-V fits
  (`mvn_lpw_prd_lp_*`), waves and plasma-line density (`mvn_lpw_prd_w_*`), merged
  products such as spacecraft potential (`mvn_lpw_prd_mrg_*`), EUV.
- `mvn_lpw_anc_*`: ancillary data: SPICE kernels
  (`mvn_lpw_anc_get_spice_kernels.pro`), position and attitude
  (`mvn_lpw_anc_spacecraft.pro`), boom shadow and wake (`mvn_lpw_anc_boom.pro`).
- `mvn_lpw_cal_*` and `mvn_lpw_cal_files/`: calibration tables (text files).
- CDF production: `mvn_lpw_cdf_write.pro`, `mvn_lpw_cdf_produce_l2.pro`,
  `mvn_lpw_cdf_save_vars`. `mvn_lpw_save_l0.pro`: SSL daily tplot saves of L0.

## How `mvn_lpw_load_l2` works

1. `vars` are product codes; the default is `['lpnt', 'wspecact', 'wspecpas']`.
   The header lists all codes and their tplot names, e.g. 'lpnt' ->
   `mvn_lpw_lp_ne_l2`, `mvn_lpw_lp_te_l2`, `mvn_lpw_lp_vsc_l2`; 'wn' ->
   `mvn_lpw_w_n_l2`; 'mrgscpot' -> `mvn_lpw_mrg_sc_pot_l2`.
2. It loops over the days of the range and calls `mvn_lpw_cdf_read, date,
   vars=..., level='l2'` for each, then joins the days into one variable each.
3. `mvn_lpw_cdf_read` fetches
   `maven/data/sci/lpw/<level>/YYYY/MM/mvn_lpw_<level>_<var>_YYYYMMDD_v??_r??.cdf`
   with `mvn_pfp_file_retrieve`
   (`projects/maven/general/mvn_pfp_file_retrieve.pro`).
4. `success=` returns one status per requested code (1 loaded, 0 no data,
   negative for bad input).

## Things to know

- If `trange` is given, `mvn_lpw_load_l2` calls `timespan` and overwrites the
  session time range.
- 'euv' reads EUV files from `maven/data/sci/euv/` and must be requested in a
  separate call; `projects/maven/euv/mvn_euv_load.pro` is the EUV team loader.
- L0-derived data are not science quality (see the crib); use L2 for publication.
- Calibration readers find `mvn_lpw_cal_files/` through the environment variable
  `mvn_lpw_software`. `mvn_lpw_load` sets it to this folder if it is empty; the
  readers (e.g. `mvn_lpw_cal_read_bias.pro`) only warn.
- `mvn_lpw_load` needs `MAVENPFP_USER_PASS` for L0 files; outside LASP use its
  `/notatlasp` and `/noserver` keywords as the header describes.
- LPW packets in the shared L0 dispatcher are handled by
  `projects/maven/sep/mvn_lpw_handler.pro` (currently commented out there);
  `projects/maven/swea/mvn_lpw_load_dlm.pro` is another author's variant of
  `mvn_lpw_load`.
