---
related_files:
  - projects/themis/AGENTS.md
  - projects/themis/spacecraft/particles/thm_part_products/thm_part_products.pro
  - projects/themis/spacecraft/particles/thm_part_products/thm_part_load.pro
  - projects/themis/spacecraft/particles/thm_part_dist.pro
  - projects/themis/spacecraft/particles/thm_part_dist_array.pro
  - projects/themis/spacecraft/particles/thm_part_getspec.pro
  - projects/themis/spacecraft/particles/thm_part_check_trange.pro
  - projects/themis/spacecraft/particles/thm_load_esa.pro
  - projects/themis/spacecraft/particles/thm_cal_mom.pro
  - projects/themis/spacecraft/particles/data_cache.pro
  - projects/themis/spacecraft/particles/ESA/packet/thm_load_esa_pkt.pro
  - projects/themis/spacecraft/particles/ESA/packet/get_tha_peif.pro
  - projects/themis/spacecraft/particles/ESA/packet/thm_load_esa_cal.pro
  - projects/themis/spacecraft/particles/ESA/packet/thm_convert_esa_units.pro
  - projects/themis/spacecraft/particles/ESA/clear_esa_common_blocks.pro
  - projects/themis/spacecraft/particles/ESA/thm_load_l2_esadist.pro
  - projects/themis/spacecraft/particles/ESA/thm_get_l2_esadist.pro
  - projects/themis/spacecraft/particles/ESA/background/thm_load_esa_bkg.pro
  - projects/themis/spacecraft/particles/SST/thm_load_sst.pro
  - projects/themis/spacecraft/particles/SST/thm_sst_psif.pro
  - projects/themis/spacecraft/particles/SST/thm_sst_convert_units.pro
  - projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_load_sst2.pro
  - projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_part_dist2.pro
  - projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_read_calib_params.pro
  - projects/themis/spacecraft/particles/SST/SST_cal_workdir/cal_files/README.txt
  - projects/themis/spacecraft/particles/moments/thm_load_mom.pro
  - projects/themis/spacecraft/particles/moments/thm_load_mom_l2.pro
  - projects/themis/spacecraft/particles/moments/thm_read_mom_cal_file.pro
  - projects/themis/spacecraft/particles/moments/thm_load_gmom.pro
  - projects/themis/spacecraft/particles/moments/thm_part_moments.pro
  - projects/themis/spacecraft/particles/moments/README
  - projects/themis/spacecraft/particles/combined/thm_part_combine.pro
  - projects/themis/spacecraft/particles/slices/thm_part_slice2d.pro
  - projects/themis/spacecraft/particles/slices/thm_part_slice1d.pro
  - projects/themis/spacecraft/particles/deprecated
  - projects/themis/common/thm_load_xxx.pro
  - general/science/spd_part_products
  - general/science/spd_slice2d/spd_slice2d.pro
  - projects/themis/examples/basic/thm_crib_esa.pro
  - projects/themis/examples/basic/thm_crib_sst.pro
  - projects/themis/examples/basic/thm_crib_mom.pro
  - projects/themis/examples/basic/thm_crib_gmom.pro
  - projects/themis/examples/basic/thm_crib_part_products.pro
  - projects/themis/examples/basic/thm_crib_part_slice2d.pro
  - projects/themis/examples/advanced/thm_crib_part_combine.pro
  - projects/themis/examples/advanced/thm_crib_esa_bgnd_remove.pro
  - projects/themis/examples/advanced/thm_crib_sst_load_calibrate.pro
maintenance: |
  Update when the distribution load path changes (thm_part_load, the ESA packet
  common blocks, the SST calibrated loader), when thm_part_products gains or
  loses outputs or support-data defaults, or when a subfolder is added or retired.
---

# THEMIS particles (IDL)

THEMIS/ARTEMIS ESA (electrostatic analyzer) and SST (solid state telescope):
loaders, 3D distribution access, and spectrogram, moment and slice tools.

## Layout

- `thm_part_products/`: `thm_part_products.pro` (spectra and moments),
  `thm_part_load.pro` (loads distributions), `thm_pgs_*` helpers.
- Root: `thm_part_dist.pro`, `thm_part_dist_array.pro` (distribution access),
  `thm_part_*` helpers, `thm_load_esa.pro` (L2 only: ESA moments and spectra
  via `thm_load_xxx`), `thm_part_getspec.pro` (compatibility wrapper).
- `ESA/`: `ESA/packet/` decodes L0 packets (`thm_load_esa_pkt.pro`,
  per-probe getters like `get_tha_peif.pro`, `*_3d_new.pro` moments in
  `ESA/packet/functions/`); `ESA/background/`; potential and Bz estimators
  (`thm_esa_*2scpot.pro`, `thm_esa_dist2bz*.pro`); L2 distribution files
  (`thm_load_l2_esadist.pro`, `thm_get_l2_esadist.pro`).
- `SST/`: L1 loader `thm_load_sst.pro`, getters `thm_sst_ps??.pro`.
  `SST/SST_cal_workdir/` is not scratch: its `thm_load_sst2.pro` and
  `thm_part_dist2.pro` are the default (calibrated) path.
- `moments/`: on-board moments `thm_load_mom.pro` (L2 via
  `thm_load_mom_l2.pro`), ground moments `thm_load_gmom.pro`,
  `thm_part_moments.pro` (wrapper). `moments/README` explains `th?_pxxm_pot`.
- `combined/thm_part_combine.pro`: merged ESA+SST distributions (`dist_array`).
- `slices/`: `thm_part_slice2d.pro` (wraps `spd_slice2d`), `thm_part_slice1d.pro`;
  `slices/core/` serves only `thm_part_slice2d_old`.
- `deprecated/`, `thm_cal_mom.pro`: old code; skip.

## How thm_part_products works

1. `thm_part_load, probe=, datatype=, trange=` loads distributions unless
   `thm_part_check_trange` finds them present. ESA goes to `thm_load_esa_pkt`,
   which downloads L0 `th?/l0/YYYY/MM/DD/th?_l0_<apid>_YYYYMMDD.pkt` files and
   decodes them into common blocks; it warns above two days. SST full/burst
   goes to `thm_load_sst2` (`sst_cal=0` selects the older `thm_load_sst`).
2. `thm_part_products` gets times and each distribution from `thm_part_dist`,
   or from a `dist_array` made by `thm_part_dist_array` or `thm_part_combine`.
   `thm_part_dist` calls `get_th<p>_pe??` (ESA) or `thm_sst_ps??` /
   `thm_part_dist2` (SST) by name from strings.
3. `thm_pgs_clean_esa`/`_sst`/`_cmb` convert units (each structure names its
   converter in `units_procedure`, e.g. `thm_convert_esa_units`), then the
   shared `spd_pgs_*` routines (`general/science/spd_part_products/`) build
   spectra and moments, stored by `thm_pgs_make_tplot`/`thm_pgs_moments_tplot`.

## Things to know

- Datatypes: `p` + `e`/`s` (ESA/SST) + `i`/`e` (ions/electrons) + `f`/`r`/`b`
  (full/reduced/burst), e.g. `peif`, `psef`. ESA APIDs 454 to 459.
- Global state: decoded ESA packets sit in common blocks `th<p>_<apid>` (e.g.
  `tha_454`) and `tha_esa_cal` (`thm_load_esa_cal.pro`); `clear_esa_common_blocks`
  empties them. The old SST loader caches in `data_cache` (`data_cache.pro`);
  `thm_load_sst2` keeps data in tplot variables `th?_ps??_data`.
- `thm_part_products` loads no support data. FAC outputs and moments read
  `th?_fgs` (`thm_load_fgm`), `th?_state_pos` (`thm_load_state`) and
  `th?_pxxm_pot` (`thm_load_mom`) unless `mag_name`, `pos_name`, `sc_pot_name`
  say otherwise. Units default to `eflux`, which moments require. ESA
  background removal needs `thm_load_esa_bkg` first.
- Calibration files come from the THEMIS server via `spd_download`: SST
  `th?/l1/sst/0000/th?_ps?f_calib_params_v02.txt`, moments
  `th?/l1/mom/0000/th?_l1_mom_cal_v03.txt`. `SST/SST_cal_workdir/cal_files/`
  holds reference copies only (`README.txt`).
- `thm_part_getspec` and `thm_part_moments` only wrap `thm_part_products`.

## Examples

`projects/themis/examples/basic/`: `thm_crib_esa.pro`, `thm_crib_sst.pro`,
`thm_crib_mom.pro`, `thm_crib_gmom.pro`, `thm_crib_part_products.pro`,
`thm_crib_part_slice2d.pro`; `projects/themis/examples/advanced/`:
`thm_crib_part_combine.pro`, `thm_crib_esa_bgnd_remove.pro`,
`thm_crib_sst_load_calibrate.pro`.
