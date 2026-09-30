---
related_files:
  - projects/themis/AGENTS.md
  - projects/themis/state/thm_load_state.pro
  - projects/themis/state/thm_load_state_relpath.pro
  - projects/themis/state/thm_load_state2.pro
  - projects/themis/state/thm_load_state3.pro
  - projects/themis/state/apply_spinaxis_corrections.pro
  - projects/themis/state/thm_autoload_support.pro
  - projects/themis/state/thm_load_slp.pro
  - projects/themis/state/thm_load_ssc.pro
  - projects/themis/state/thm_interpolate_state.pro
  - projects/themis/state/thm_sunpulse.pro
  - projects/themis/state/thm_spin_phase.pro
  - projects/themis/state/cotrans/thm_cotrans.pro
  - projects/themis/state/cotrans/ssl2dsl.pro
  - projects/themis/state/cotrans/dsl2gse.pro
  - projects/themis/state/cotrans/gse2sse.pro
  - projects/themis/state/cotrans/sse2sel.pro
  - projects/themis/state/cotrans/thm_cotrans_lmn.pro
  - projects/themis/state/cotrans/thm_gsm2lmn_wrap.pro
  - projects/themis/state/cotrans/thm_fac_matrix_make.pro
  - projects/themis/state/cotrans/thm_cotrans_matrix.pro
  - projects/themis/state/cotrans/thm_cotrans_tensor.pro
  - projects/themis/common/thm_load_xxx.pro
  - projects/themis/spin
  - projects/themis/spin/spinmodel_post_process.pro
  - projects/themis/spin/spinmodel_get_ptr.pro
  - projects/themis/spin/thm_load_spin.pro
  - general/cotrans/cotrans.pro
  - general/cotrans/spg2ssl.pro
  - general/cotrans/cotrans_set_coord.pro
  - projects/mms/common/cotrans/dmpa2gse.pro
  - projects/themis/spacecraft/fields/thm_spinfit.pro
  - projects/themis/examples/basic/thm_crib_state.pro
  - projects/themis/examples/basic/thm_crib_cotrans.pro
  - projects/themis/examples/advanced/thm_crib_slp_sse.pro
  - projects/themis/examples/advanced/thm_crib_cotrans_lmn.pro
  - projects/themis/examples/advanced/thm_crib_fac.pro
maintenance: |
  Update when thm_load_state's datatypes, file naming or spin-model handling
  change, when thm_cotrans gains or loses a coordinate system or support
  variable, or when a state or cotrans routine is added, removed or retired.
---

# THEMIS state and coordinate transforms (IDL)

THEMIS/ARTEMIS orbit and attitude ("state"), sun and moon ephemeris, and
`thm_cotrans`, which converts vectors between spacecraft, geophysical and lunar
frames. The spin model itself is in `projects/themis/spin/`.

## Layout

- `thm_load_state.pro`: main loader; `thm_load_state_relpath.pro` builds its
  file paths. `apply_spinaxis_corrections.pro` makes the corrected spin axis.
- `thm_autoload_support.pro`: loads state (spin model, spin axis) or sun/moon
  data only if a variable's time range is not already covered.
- `thm_load_slp.pro`: sun and moon position and lunar attitude (`slp_*`
  variables, GEI true of date), needed for `sse` and `sel`.
- `thm_load_ssc.pro`: orbits, including predicted ones, from SSCWeb/CDAWeb.
- `thm_interpolate_state.pro`, `thm_sunpulse.pro`, `thm_spin_phase.pro`:
  interpolate the 1-minute spin period and phase (`ssl2dsl /interpolate_state`,
  `projects/themis/spacecraft/fields/thm_spinfit.pro`, and MMS
  `projects/mms/common/cotrans/dmpa2gse.pro` use them).
- `thm_load_state2.pro`, `thm_load_state3.pro`: unused variants.
- `cotrans/`: `thm_cotrans.pro` and its single steps (`ssl2dsl.pro`,
  `dsl2gse.pro`, `gse2sse.pro`, `sse2sel.pro`); boundary-normal coordinates
  (`thm_cotrans_lmn.pro`, `thm_gsm2lmn_wrap.pro`); field-aligned matrices
  (`thm_fac_matrix_make.pro`); `thm_cotrans_matrix.pro` (3x3 rotation matrix
  per sample); `thm_cotrans_tensor.pro` (pressure and momentum-flux tensors).

## How thm_load_state works

1. `thm_load_state` turns the requested datatypes into a list (default
   `pos vel`; `/get_support_data` adds the spin and attitude variables) and
   calls `thm_load_xxx` (`projects/themis/common/thm_load_xxx.pro`) with
   `midfix='state_'`, so variables are named `th?_state_<datatype>`.
2. `thm_load_state_relpath` gives `th?/l1/state/YYYY/th?_l1_state_YYYYMMDD.cdf`
   (no version unless `version` is set), or `_v0?.cdf` names when
   `!themis.remote_data_dir` points to SPDF or CDAWeb.
3. `thm_load_state_post` builds the spin model with `spinmodel_post_process`
   (`projects/themis/spin/spinmodel_post_process.pro`) when support data
   is loaded, deletes the raw `th?_state_spin_*` variables unless
   `/keep_spin_data`, applies the spin-axis corrections, sets coordinate
   metadata, and runs `thm_cotrans` on `pos`/`vel` if `coord` is set.

## Things to know

- Native frames: `pos` (km), `vel` (km/s), `spinras`, `spindec` are GEI;
  `spinalpha`, `spinbeta` are `spg`. `thm_cotrans` warns that it ignores the
  rotational term when transforming velocities.
- The spin model is global state: objects in the common block
  `spinmodel_common` (`projects/themis/spin/spinmodel_get_ptr.pro`),
  filled by `thm_load_state, /get_support_data` (unless `/no_spin`) or by
  `thm_load_spin` (`projects/themis/spin/thm_load_spin.pro`). `ssl`/`dsl`
  transforms and L1 calibration read it through `spinmodel_get_ptr`.
- `thm_cotrans` loads nothing: first run `thm_load_state, /get_support_data`
  (spin model, `th?_state_spinras`/`spindec` and their `_corrected` versions)
  and `thm_load_slp` for `sse`/`sel`, or use `thm_autoload_support`.
- Frame chain: `spg`-`ssl`-`dsl`-`gse`-`sse`-`sel`, with `gsm`, `sm`, `gei`,
  `geo`, `mag` reached from `gse` through `general/cotrans/cotrans.pro`
  (`spg2ssl` is in `general/cotrans/spg2ssl.pro`). Each call does one step
  and recurses until the target frame.
- The input frame comes from `dlimits.data_att.coord_sys` (set with
  `cotrans_set_coord`, `general/cotrans/cotrans_set_coord.pro`); `in_coord`
  must agree with it unless `/ignore_dlimits`.
- `use_spinaxis_correction`, `use_spinphase_correction` and
  `use_eclipse_corrections` (0, 1, 2) select correction variants;
  `thm_cal_fgm` and `thm_cal_efi` turn the first two on.

## Examples

`projects/themis/examples/basic/`: `thm_crib_state.pro`,
`thm_crib_cotrans.pro`; `projects/themis/examples/advanced/`:
`thm_crib_slp_sse.pro`, `thm_crib_cotrans_lmn.pro`, `thm_crib_fac.pro`.
