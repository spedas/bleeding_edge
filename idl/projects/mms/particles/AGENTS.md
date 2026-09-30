---
related_files:
  - projects/mms/AGENTS.md
  - projects/mms/particles/mms_part_products.pro
  - projects/mms/particles/mms_part_getspec.pro
  - projects/mms/particles/mms_part_getpad.pro
  - projects/mms/particles/mms_part_slice2d.pro
  - projects/mms/particles/mms_part_isee3d.pro
  - projects/mms/particles/mms_get_dist.pro
  - projects/mms/particles/mms_convert_flux_units.pro
  - projects/mms/particles/mms_part_conv_units.pro
  - projects/mms/particles/mms_part_des_photoelectrons.pro
  - projects/mms/particles/mms_pgs_clean_data.pro
  - projects/mms/particles/mms_pgs_clean_support.pro
  - projects/mms/particles/mms_pgs_make_fac.pro
  - projects/mms/particles/mms_pgs_split_hpca.pro
  - projects/mms/particles/mms_slice1d_plot_fpi.pro
  - projects/mms/particles/moka
  - projects/mms/particles/moka/moka_mms_part_products.pro
  - projects/mms/particles/moka/moka_mms_pad_fpi.pro
  - projects/mms/particles/deprecated
  - projects/mms/fpi/mms_get_fpi_dist.pro
  - projects/mms/fpi/mms_fpi_remove_sw.pro
  - projects/mms/hpca/mms_get_hpca_dist.pro
  - projects/mms/common/load_data/mms_load_data.pro
  - projects/mms/common/cdf/mms_cdf2tplot.pro
  - general/science/spd_part_products
  - general/science/spd_slice2d/spd_slice2d.pro
  - spedas_gui/isee3d/isee_3d.pro
  - projects/mms/common/tests/mms_part_products_ut__define.pro
  - projects/mms/common/tests/mms_part_getspec_ut__define.pro
  - projects/mms/common/tests/mms_part_slice2d_ut__define.pro
  - projects/mms/common/tests/mms_pgs_validation_ut__define.pro
  - projects/mms/examples/advanced/mms_part_getspec_crib.pro
  - projects/mms/examples/advanced/mms_part_getspec_adv_crib.pro
  - projects/mms/examples/advanced/mms_slice2d_fpi_crib.pro
  - projects/mms/examples/advanced/mms_slice2d_hpca_crib.pro
  - projects/mms/examples/advanced/mms_isee_3d_crib.pro
maintenance: |
  Update when mms_part_products or mms_part_getspec change outputs, units,
  support-variable defaults or photoelectron handling, when the FPI/HPCA
  distribution getters change, or when moka/ or deprecated/ code is promoted
  or removed.
---

# MMS particle distributions (IDL)

Products from FPI and HPCA 3D distributions: energy, angle, pitch-angle and
gyrophase spectrograms, moments, pitch-angle distributions, 2D slices and 3D
views. The heavy lifting is the mission-independent `spd_pgs_*` code in
`general/science/spd_part_products/`.

## Layout

- `mms_part_getspec.pro`: the usual entry point. Loads the distribution and
  support data if missing, then calls `mms_part_products` per probe.
- `mms_part_products.pro`: core routine; takes the name of a tplot variable
  holding FPI or HPCA distributions (e.g. `mms1_dis_dist_brst`).
- `mms_get_dist.pro`: returns per-sample 3D structures, dispatching to
  `mms_get_fpi_dist` (`projects/mms/fpi/mms_get_fpi_dist.pro`) or
  `mms_get_hpca_dist` (`projects/mms/hpca/mms_get_hpca_dist.pro`).
- `mms_pgs_*.pro`: MMS-specific steps (`mms_pgs_clean_data.pro`,
  `mms_pgs_clean_support.pro`, `mms_pgs_make_fac.pro`, spectra builders,
  `mms_pgs_split_hpca.pro`).
- `mms_convert_flux_units.pro`, `mms_part_conv_units.pro`: unit conversion.
- `mms_part_des_photoelectrons.pro`: FPI-DES photoelectron model.
- `mms_part_getpad.pro`: pitch-angle distributions from the `multipad` output.
- `mms_part_slice2d.pro`: loads data and wraps `spd_slice2d`
  (`general/science/spd_slice2d/spd_slice2d.pro`) and its plotter;
  `mms_slice1d_plot_fpi.pro` plots 1D cuts.
- `mms_part_isee3d.pro`: loads data and opens `isee_3d`
  (`spedas_gui/isee3d/isee_3d.pro`).
- `moka/`: Mitsuo Oka's variants (`moka/moka_mms_part_products.pro` for many
  spectrograms, `moka/moka_mms_pad_fpi.pro`), with their own cribs.
- `deprecated/`: old versions (`mms_part_products_old`, ...); skip.

## How mms_part_getspec works

1. It loads, only when not already present, the distribution
   (`mms_load_fpi` `d?s-dist` or `mms_load_hpca` `ion`), FGM L2
   `mms?_fgm_b_gse_*_bvec`, MEC position, EDP spacecraft potential (for
   moments or photoelectron corrections) and bulk velocity (`/subtract_bulk`).
   Support data span the request plus 60 s on each side.
2. `mms_part_products` gets sample times and structures from `mms_get_dist`,
   cleans them (`mms_pgs_clean_data`), applies the DES photoelectron model
   when requested, and interpolates or transforms support data
   (`mms_pgs_clean_support`, `mms_pgs_make_fac`).
3. Shared `spd_pgs_*` routines limit ranges, regrid, rotate to field-aligned
   coordinates, and build spectra and moments; results are stored as tplot
   variables named after the input with `_energy`, `_pa`, `_gyro`, ... appended.

## Things to know

- `mms_get_dist` parses probe, instrument and species from the tplot name, so
  keep the original name or pass `probe`, `species`, `instrument`.
- Units: `eflux` (default, required for moments), `flux`, `df_cm`, `df_km`;
  plain `df` is rejected. HPCA input units come from the name or `input_units`.
- DES photoelectron correction downloads the model CDF from the public SDC
  (`.../mms/sdc/public/data/models/fpi/`) into `!mms.local_data_dir` and reads
  it with `mms_cdf2tplot`. `mms_part_getspec` turns it on by default for DES
  moments.
- HPCA is forced to `center_measurement`. `/remove_fpi_sw` uses
  `projects/mms/fpi/mms_fpi_remove_sw.pro`; `/sdc_units` gives SDC units
  (nPa, mW/m^2) for pressure and heat flux.
- PGS moments can differ slightly from the official FPI/HPCA moments; the
  header of `mms_part_products.pro` says to use the official ones for science.

## Examples and tests

Cribs in `projects/mms/examples/advanced/`: `mms_part_getspec_crib.pro`,
`mms_part_getspec_adv_crib.pro`, `mms_slice2d_fpi_crib.pro`,
`mms_slice2d_hpca_crib.pro`, `mms_isee_3d_crib.pro`. Tests in
`projects/mms/common/tests/`: `mms_part_products_ut__define.pro`,
`mms_part_getspec_ut__define.pro`, `mms_part_slice2d_ut__define.pro`,
`mms_pgs_validation_ut__define.pro`.
