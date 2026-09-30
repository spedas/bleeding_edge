---
related_files:
  - general/AGENTS.md
  - general/science/3d_structure.pro
  - general/science/conv_units.pro
  - general/science/convert_esa_units.pro
  - general/science/convert_flux_units.pro
  - general/science/get_3dt.pro
  - general/science/sphere_to_cart.pro
  - general/science/wind/moments_3d.pro
  - general/science/dist3d/dist3d__define.pro
  - general/science/spd_part_products/spd_pgs_moments.pro
  - general/science/spd_part_products/spd_pgs_do_fac.pro
  - general/science/spd_part_products/spd_pgs_moments_tplot.pro
  - general/science/spd_slice2d/spd_slice2d.pro
  - general/science/spd_slice2d/spd_slice2d_plot.pro
  - general/science/wavpol/wavpol.pro
  - general/science/wavpol/twavpol.pro
  - general/science/spd_mtm/spd_mtm.pro
  - general/science/spd_mtm/tplot_spd_mtm.pro
  - general/science/spd_mtm/README.txt
  - general/science/spd_mtm/spd_mtm_fitmodel.pro
  - general/science/spd_mtm/spd_mtm_modelgof.pro
  - projects/themis/spacecraft/particles/thm_part_products/thm_part_products.pro
  - projects/themis/spacecraft/particles/thm_part_products/thm_pgs_clean_esa.pro
  - projects/themis/spacecraft/particles/slices/thm_part_slice2d.pro
  - projects/mms/particles/mms_part_products.pro
  - projects/mms/particles/mms_pgs_clean_data.pro
  - projects/mms/particles/mms_part_slice2d.pro
  - projects/mms/common/tests/mms_pgs_regressions_ut__define.pro
  - projects/mms/common/tests/mms_part_slice2d_ut__define.pro
maintenance: |
  Update when a spd_pgs_* or spd_slice2d routine changes its inputs, when the
  3D or sanitized particle structure gains or loses required tags, or when a
  new subfolder or mission part_products wrapper is added.
---

# General science routines

Mission-independent analysis code: particle distribution tools (the "3D
structure", unit conversion, moments, spectrograms, 2D slices), wave
polarization and multitaper spectral analysis.

## Layout

- Top level: 3D-structure routines from Wind 3DP. `3d_structure.pro` is
  documentation only. Units: `conv_units`, `convert_esa_units`,
  `convert_flux_units`. Moments: `n_3d`, `v_3d`, `p_3d`, `t_3d`, `j_3d`;
  `get_3dt` runs one over a time series. Plots: `spec3d`, `plot3d`, `padplot`,
  the old `slice2d`.
- `wind/`: more 3D-structure routines, notably `moments_3d`
  (`wind/moments_3d.pro`), the moment engine behind particle products; the rest
  are Wind 3DP drivers that call `get_el`, `get_pl` etc. from
  `projects/wind/3dp/idl/`.
- `spd_part_products/`: `spd_pgs_*` building blocks for spectrograms and
  moments. There is no `spd_part_products` routine; missions write the driver.
- `spd_slice2d/`: `spd_slice2d` and `spd_slice2d_plot`; `core/` and `plotting/`
  hold their helpers.
- `wavpol/`: `wavpol` (arrays) and `twavpol` (tplot wrapper).
- `spd_mtm/`: SPD_MTM multitaper spectral analysis (Di Matteo et al. 2020),
  stand-alone and Apache-2.0 licensed (`spd_mtm/README.txt`); `tplot_spd_mtm`
  runs `spd_mtm` on a tplot variable.
- `dist3d/`: `dist3d__define.pro`, a base struct/class inherited by THEMIS SST
  (`thm_sst_dist3d_*__define`) and STEREO SWEA classes.

## How particle products work

Mission drivers (`thm_part_products`, `mms_part_products`,
`erg_*_part_products`, `goes_part_products`) loop over time samples; see
`projects/themis/spacecraft/particles/thm_part_products/thm_part_products.pro`.

1. Mission code converts one 3D structure to a "sanitized" one with 2-D
   (energy x angle) `data`, `energy`, `phi`, `theta`, `bins`, ... arrays
   (`thm_pgs_clean_esa`, `projects/mms/particles/mms_pgs_clean_data.pro`).
2. `spd_pgs_limit_range`, then `spd_pgs_moments` (calls `moments_3d` with
   `/no_unit_conv`, so data must already be in eflux), `spd_pgs_make_e_spec`,
   `spd_pgs_make_theta_spec`, `spd_pgs_make_phi_spec`. Each call appends one
   sample to the spectrogram arrays.
3. Field-aligned outputs: `spd_pgs_do_fac` rotates angles with a 3x3 matrix the
   mission builds (`thm_pgs_make_fac`, `mms_pgs_make_fac`), `spd_pgs_regrid`
   regrids, and `spd_pgs_make_theta_spec, /colatitude` gives pitch angle.
4. `spd_pgs_make_tplot` and `spd_pgs_moments_tplot` store the results; missions
   often use their own copies (`thm_pgs_make_tplot`, `mms_pgs_make_tplot`).

`spd_slice2d(dist)` takes pointers to arrays of 3D structures (from
`mms_get_dist`, `thm_part_dist_array`), averages over a time window, rotates
(`rotation='BV'`, `'xy'`, ... with `mag_data`/`vel_data`), interpolates and
returns a slice for `spd_slice2d_plot`. It keeps the input units;
`thm_part_slice2d` and `mms_part_slice2d` convert units first.

## Things to know

- 3D structure: `data` is [nenergy, nbins] (MMS: [energy, phi, theta]), energy
  in eV, angles in degrees, theta as latitude (`sphere_to_cart.pro`), `mass` in
  eV/(km/s)^2.
- `conv_units` calls the structure's `units_procedure` tag by name with
  `call_procedure` (e.g. `thm_convert_esa_units`, `mvn_sta_convert_units`,
  `mms_part_conv_units`). Grep for those names in quotes.
- `get_3dt` and the `wind/` drivers call getters by name (`'get_'+type`).
- THEMIS keeps older copies of the slice helpers (`thm_part_slice2d_*`), but
  `thm_part_slice2d` itself calls `spd_slice2d`.
- `twavpol` expects input already in field-aligned coordinates (Z along B)
  and stores `<prefix>_powspec`, `_degpol`, `_waveangle`, ... variables.
- SPD_MTM uses common blocks `max_lklh` and `gammaj`, and calls functions by
  name (`spd_mtm_fitmodel.pro`, `execute` in `spd_mtm_modelgof.pro`).
- Minimum variance (`minvar`) and FAC matrices (`fac_matrix_make`) are in
  `general/cotrans/`; field models (T89/T96) are in
  `external/IDL_GEOPACK/`.

## Tests

MMS mgunit tests in `projects/mms/common/tests/` cover this code
(`projects/mms/common/tests/mms_pgs_regressions_ut__define.pro`,
`projects/mms/common/tests/mms_part_slice2d_ut__define.pro`).
