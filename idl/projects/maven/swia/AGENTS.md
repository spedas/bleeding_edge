---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/swia/mvn_swia_crib.pro
  - projects/maven/swia/mvn_swia_load_l2_data.pro
  - projects/maven/swia/mvn_swia_load_l0_data.pro
  - projects/maven/swia/mvn_swia_make_info_str.pro
  - projects/maven/swia/mvn_swia_get_3dc.pro
  - projects/maven/swia/mvn_swia_get_3df.pro
  - projects/maven/swia/mvn_swia_get_3ds.pro
  - projects/maven/swia/mvn_swia_convert_units.pro
  - projects/maven/swia/mvn_swia_common_units.pro
  - projects/maven/swia/mvn_swia_part_moments.pro
  - projects/maven/swia/mvn_swia_protonalphamoms.pro
  - projects/maven/swia/mvn_swia_add_magf.pro
  - projects/maven/swia/mvn_swia_inst2mso.pro
  - projects/maven/swia/mvn_swia_regid.pro
  - projects/maven/swia/mvn_swia_upstream_ave.pro
  - projects/maven/swia/mvn_swia_3d_snap.pro
  - projects/maven/swia/mvn_swia_slice2d_snap.pro
  - projects/maven/swia/mvn_swia_make_l2_data.pro
  - projects/maven/swia/mvn_swia_plot_packets.pro
  - projects/maven/general/mvn_pfp_file_retrieve.pro
maintenance: |
  Update when mvn_swia_load_l2_data's keywords, file names or the mvn_swia_data
  common block change, or when new SWIA products or analysis routines are added.
---

# MAVEN SWIA (IDL)

Code for SWIA (Solar Wind Ion Analyzer). It loads L0 or L2 data into the
`mvn_swia_data` common block and tplot, builds 3D data structures for the
generic particle routines, computes moments (including separate proton and alpha
moments), and makes the L2 CDF files. Written by the SWIA team (J. Halekas).

## Layout

- `mvn_swia_crib.pro`: start here.
- `mvn_swia_load_l2_data.pro`: the main loader. `mvn_swia_load_l0_data.pro`: L0
  loader (reads the daily PFP L0 file with `mvn_swia_read_compressed_packets`;
  packet decoders are `mvn_swia_define_apid29` ... `mvn_swia_define_apid87`).
- `mvn_swia_make_info_str.pro`: energy, angle and sensitivity tables (`info_str`).
- `mvn_swia_get_3dc.pro`, `mvn_swia_get_3df.pro`, `mvn_swia_get_3ds.pro`: coarse,
  fine and spectra 3D structures at one time; `/archive` (coarse and fine) for
  burst data.
- `mvn_swia_convert_units.pro` (per structure), `mvn_swia_common_units.pro`
  (converts the whole common block; slow).
- Moments: `mvn_swia_part_moments.pro` (partial moments into tplot),
  `mvn_swia_protonalphamoms.pro` and its `_mag`, `_minf` variants,
  `mvn_swia_inst2mso.pro` (rotate onboard moments to MSO).
- Magnetic field and context: `mvn_swia_add_magf.pro` (MAG into the common
  block), `mvn_swia_regid.pro` (plasma region), `mvn_swia_upstream_ave.pro`,
  `mvn_swia_swindave`, `mvn_swia_penprot*` (penetrating protons).
- Plots: `mvn_swia_3d_snap.pro`, `mvn_swia_slice2d_snap.pro`, `mvn_swia_diret*`
  (directional spectrograms).
- Production: `mvn_swia_make_l2_data.pro` with `mvn_swia_make_sw*_str` and
  `mvn_swia_make_sw*_cdf`; `mvn_swia_plot_packets.pro` makes tplot from packets.
- `obsolete/`: prelaunch code; skip.

## How `mvn_swia_load_l2_data` works

1. The day list comes from `trange` (or `timerange()`) unless a `files` argument
   of `YYYYMMDD` strings is given.
2. `mvn_swia_make_info_str` fills `info_str`.
3. For each day and requested type (`/loadmom`, `/loadspec`, `/loadfine`,
   `/loadcoarse`, or `/loadall`) it gets
   `maven/data/sci/swi/l2/YYYY/MM/mvn_swi_l2_<type>_YYYYMMDD_v??_r??.cdf` with
   `mvn_pfp_file_retrieve` (`projects/maven/general/mvn_pfp_file_retrieve.pro`).
   Types: onboardsvymom, onboardsvyspec, finesvy3d, finearc3d, coarsesvy3d,
   coarsearc3d. `/no_server` only looks locally.
4. The CDFs are read into arrays of structures in
   `common mvn_swia_data, info_str, swihsk, swics, swica, swifs, swifa, swim, swis`.
5. With `/tplot` it makes `mvn_swim_*` (moments), `mvn_swis_*` (spectra),
   `mvn_swifs_*`, `mvn_swifa_*`, `mvn_swics_*`, `mvn_swica_*` variables. `qlevel=`
   (default 0.5) hides low-quality moments and spectra; `/eflux` loads energy flux
   instead of counts.

## Things to know

- File names use `mvn_swi_`, routines and tplot names use `mvn_swia_` or
  `mvn_swi<x>_`.
- The 3D structures have `units_procedure = 'mvn_swia_convert_units'`, so
  `conv_units`, `n_3d`, `v_3d`, `plot3d_new` and `spec3d` work on them. Their
  angles are in instrument coordinates. Onboard moments come as
  `mvn_swim_velocity` (instrument frame) and `mvn_swim_velocity_mso`.
- Solar wind temperatures from full distributions include alphas; use the
  proton/alpha routines to separate them.
- SWIA does not measure below about 25 eV (see the SWEA crib).
