---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/quicklook/mvn_ql_pfp_tplot.pro
  - projects/maven/quicklook/mvn_ql_pfp_tplot2.pro
  - projects/maven/quicklook/mvn_ql_pfp_tplot_save.pro
  - projects/maven/quicklook/mvn_ql_pfp_tplot_restore.pro
  - projects/maven/quicklook/mvn_attitude_bar.pro
  - projects/maven/quicklook/mvn_qlook_burst_bar.pro
  - projects/maven/quicklook/mvn_spaceweather.pro
  - projects/maven/quicklook/mvn_qlook_load_kp.pro
  - projects/maven/quicklook/mvn_qlook_kp_read.pro
  - projects/maven/quicklook/mvn_over_shell.pro
  - projects/maven/quicklook/mvn_load_all_qlook.pro
  - projects/maven/quicklook/mvn_l0_db2file.pro
  - projects/maven/quicklook/mvn_gen_overplot.pro
  - projects/maven/quicklook/mvn_qlook_init.pro
  - projects/maven/quicklook/mvn_call_pfpl2plot.pro
  - projects/maven/quicklook/mvn_pfpl2_overplot.pro
  - projects/maven/quicklook/mvn_gen_multipngplot.pro
  - projects/maven/quicklook/mvn_ngi_read_csv.pro
  - projects/maven/quicklook/browser/maven_ql_browser.shtml
  - projects/maven/spedas_plugin/mvn_kp_ui_import_data.pro
  - projects/maven/models/mvn_model_bcrust_load.pro
maintenance: |
  Update when mvn_ql_pfp_tplot's keywords, loaders or panels change, when the
  overview-plot production chain changes, or when the KP in-situ reader moves.
---

# MAVEN quicklook

Multi-instrument summary plots. `mvn_ql_pfp_tplot` is the user routine that
loads L2 data from all Particles and Fields (PFP) instruments into one tplot
page; most other files are SSL production code for the daily overview PNGs, the
space-weather page, and the KP in-situ reader used by the GUI.

## Layout

- `mvn_ql_pfp_tplot.pro`: the user summary (below). `mvn_ql_pfp_tplot2.pro` is a
  near copy used by the production routine `mvn_pfpl2_overplot.pro`;
  `mvn_ql_pfp_tplot_ytickname_*` are its tick helpers.
- `mvn_ql_pfp_tplot_save.pro`, `mvn_ql_pfp_tplot_restore.pro`: daily "Tohban"
  (burst-request duty) tplot save files under `maven/anc/tohban/YYYY/MM/`.
- Bars for tplot: `mvn_attitude_bar.pro` (spacecraft attitude),
  `mvn_qlook_burst_bar.pro` (burst data available), `mvn_qlook_static_d1_bar`.
- `mvn_spaceweather.pro`: space-weather tplot variables; `mvn_spaceweather_*` make
  and reprocess its plots.
- `mvn_qlook_load_kp.pro` (with `mvn_qlook_kp_read.pro`): reads the KP in-situ
  text files `maven/data/sci/kp/insitu/YYYY/MM/mvn_kp_insitu_*`; the GUI plugin
  calls it (`projects/maven/spedas_plugin/mvn_kp_ui_import_data.pro`).
- L0 overview production: `mvn_over_shell.pro` (adapted from THEMIS's
  `thm_over_shell`) runs `mvn_qlook_init.pro`,
  loads everything once with `mvn_load_all_qlook.pro` (L0 file found by
  `mvn_l0_db2file.pro`; NGIMS CSV via `mvn_ngi_read_csv.pro`), then
  `mvn_gen_overplot.pro` and `mvn_<inst>_overplot` for lpw, mag, sep, sta, swe,
  swia, writing PNGs.
- L2 overview production: `mvn_call_pfpl2plot.pro` -> `mvn_pfpl2_overplot.pro`,
  `mvn_pfpl2_longplot`, and orbit plots in `mvn_gen_multipngplot.pro`;
  `*_1day.pro` reprocess date ranges; `run_*.pro` and `.sh` files are cron
  wrappers with lock files.
- `browser/maven_ql_browser.shtml`: the web page that shows the PNGs.
- `test_*`, `jmm_test_overplot`, `muser_mvn_overplot`: developer scripts.

## How `mvn_ql_pfp_tplot` works

1. It deletes all existing tplot variables unless `/no_delete`.
2. The time range comes from the argument, `orbit=`, or the current `timespan`.
   `/restore` restores the Tohban save files instead and returns.
3. If SPICE doesn't cover the range it downloads kernels (`mvn_spice_load,
   /download_only`).
4. It loads each instrument with its own loader, switched by keywords
   (`swia=`, `swea=`, `static=`, `sep=`, `mag=`, `lpw=` default on, `euv=` off):
   `mvn_swe_load_l2`, `mvn_swia_load_l2_data`, `mvn_sta_l2_load` (c0, c6),
   `mvn_sep_load` (L2, falling back to L1), `mvn_mag_load`, `mvn_euv_load`; LPW
   I-V curves are read directly with `mvn_lpw_cdf_cdf2tplot`. With MAG it also runs `mvn_model_bcrust_load`
   (`projects/maven/models/mvn_model_bcrust_load.pro`).
5. `/tohban` adds burst availability, Phobos distance and Sun direction panels;
   `/spaceweather` switches to a space-weather set; `/tplot` plots, `tname`
   returns the panel names.

## Things to know

- Production routines write to SSL disks (`/disks/data/...` defaults) and use
  the Z device; they are not meant for users.
- `mvn_ql_pfp_tplot` calls the SEP loader through `execute` strings; search for
  `'mvn_sep_load` in quotes when tracing it.
- The `tobhan` misspelling of `/tohban` is accepted on purpose.
