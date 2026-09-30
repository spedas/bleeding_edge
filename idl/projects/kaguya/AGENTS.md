---
related_files:
  - projects/AGENTS.md
  - projects/kaguya/kgy_crib.pro
  - projects/kaguya/map/kgy_map_load.pro
  - projects/kaguya/map/kgy_map_make_tplot.pro
  - projects/kaguya/map/kgy_map_make_pad.pro
  - projects/kaguya/map/kgy_clear_com.pro
  - projects/kaguya/map/pace/kgy_pace_com.pro
  - projects/kaguya/map/pace/kgy_read_pbf.pro
  - projects/kaguya/map/pace/kgy_read_inf.pro
  - projects/kaguya/map/pace/kgy_esa1_get3d.pro
  - projects/kaguya/map/pace/kgy_pace_convert_units.pro
  - projects/kaguya/map/pace/kgy_n_3d.pro
  - projects/kaguya/map/lmag/kgy_lmag_com.pro
  - projects/kaguya/map/lmag/kgy_read_lmag.pro
  - projects/kaguya/map/lmag/kgy_svm_com.pro
  - projects/kaguya/map/lmag/kgy_svm_load.pro
  - projects/kaguya/lrs/kgy_lrs_load.pro
  - projects/kaguya/general/kgy_file_retrieve.pro
  - projects/kaguya/general/kgy_file_source.pro
  - projects/kaguya/general/spice/kgy_spice_kernels.pro
  - projects/kaguya/general/spice/kgy_ck_gaps.pro
  - projects/kaguya/general/spice/kgy_spk_gaps.pro
  - projects/kaguya/general/spice/kernels/fk/SSE_080125.tf
  - projects/kaguya/general/spice/kernels/fk/GSE_080125.tf
  - general/spedas_tools/spd_download/spd_download.pro
  - general/spice/spice_vector_rotate.pro
maintenance: |
  Update when kgy_map_load or kgy_lrs_load change their flow, default data
  versions or servers, when the PACE/LMAG common blocks change, or when a
  sensor or instrument is added.
---

# Kaguya (SELENE)

Loaders and analysis for the Kaguya lunar orbiter: MAP-PACE particle sensors
(ESA-S1 and ESA-S2 electrons, IMA and IEA ions), the LMAG magnetometer, the
LRS radio sounder, and SPICE geometry. `kgy_crib.pro` walks through all of it.

## Layout

- `map/`: `kgy_map_load` (PACE + LMAG + SPICE), `kgy_map_make_tplot`,
  `kgy_map_make_pad` (pitch-angle spectra), `kgy_clear_com`, `kgy_map_ql_dl`
  (quicklook PNGs).
- `map/pace/`: file readers (`kgy_read_pbf`, `kgy_read_inf`, `kgy_read_fov`,
  `kgy_read_tof`), 3-D structures (`kgy_esa1_get3d`, `kgy_esa2_get3d`,
  `kgy_ima_get3d`, `kgy_iea_get3d`), units and frames
  (`kgy_pace_convert_units`, `kgy_pace_convert_frame`), moments (`kgy_n_3d`,
  `kgy_v_3d`, ..., `kgy_mom_calc`), and IMA mass spectra.
- `map/lmag/`: `kgy_read_lmag`; the SVM crustal-field model of Tsunakawa et
  al. 2015 (`kgy_svm_load`, `kgy_svm_get`, `kgy_svm_pred`); `kgy_calc_bcon`.
- `lrs/`: `kgy_lrs_load` (NPW and WFC spectra from CDF).
- `general/`: `kgy_file_source`, `kgy_file_retrieve`, `kgy_orbit_snap`.
  `general/spice/`: `kgy_spice_kernels`, `kgy_ck_gaps`, `kgy_spk_gaps`, and
  `kernels/fk/` with the SSE and GSE frame kernels.

## How `kgy_map_load` works

1. `map/kgy_map_load.pro` clears the data arrays with `kgy_clear_com, /onlydata`
   unless `/append`. `sensor` selects 0 ESA-S1, 1 ESA-S2, 2 IMA, 3 IEA,
   4 LMAG (default all).
2. For PACE it first loads the instrument tables with `kgy_read_fov`,
   `kgy_read_inf` and `kgy_read_tof` (`/load` downloads them from the
   author's server at Kyoto University).
3. For each sensor it builds a DARTS PDS3 path pattern and calls
   `kgy_file_retrieve(..., /public)` (`general/kgy_file_retrieve.pro`), which
   takes its source from `kgy_file_source` and downloads with `spd_download`.
   `kgy_read_pbf` or `kgy_read_lmag` then fill the common blocks.
4. `kgy_map_make_tplot` turns the common blocks into tplot variables
   (`kgy_esa1_en_eflux`, `kgy_ima_en_counts`, `kgy_lmag_Bgse`, ...).
5. Unless `/nospice`, `kgy_spice_kernels(/load)` fetches kernels from DARTS,
   and the loader uses `spice_vector_rotate` to add `kgy_lmag_Bsat`,
   `kgy_lmag_Bsse`, `kgy_lmag_Rsse`, `kgy_lmag_alt` and `kgy_lmag_sza`,
   skipping times in the kernel gaps listed by `kgy_ck_gaps`/`kgy_spk_gaps`.

With `public=0` it instead reads files already on disk under the private
layout (`pace/`, `lmag/` below the local data directory).

## Things to know

- Data live in common blocks, not only in tplot: `@kgy_pace_com`
  (`map/pace/kgy_pace_com.pro`), `@kgy_lmag_com`, `@kgy_svm_com`. The `get3d`
  functions read from them, so load before calling them. `kgy_map_make_pad`,
  `kgy_mom_calc` and `kgy_pace_plot3d_snap` pick the `get3d` function by name
  with `call_function`.
- `get3d` returns SSL-style 3-D structures in `Counts` with
  `units_procedure='kgy_pace_convert_units'`, so `conv_units` and the
  `kgy_*_3d` moment functions work on them. The `_en_eflux` tplot variables
  ignore relative sensitivity and count corrections.
- Data versions are fixed defaults because the loaders can't search versions:
  PBF `003` and LMAG `1.0` in `kgy_map_load`, LRS `010` in `kgy_lrs_load`.
- `kgy_lrs_load` deletes existing `kgy_lrs_*` variables unless `/append`, and
  loads WFC only for even hours.
- Frames: LMAG files give ME (Moon mean-Earth) and GSE; SSE comes from
  `general/spice/kernels/fk/SSE_080125.tf`. Altitude uses a lunar radius of
  1737.4 km.
- Local data go to the default data directory + `kaguya/` (`kaguya/public/`
  for DARTS files); `kgy_file_source, /set` changes the default for the
  session through the common block `kgy_file_source_com`.
