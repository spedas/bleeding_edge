---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/swea/mvn_swe_crib.pro
  - projects/maven/swea/mvn_swe_load_l2.pro
  - projects/maven/swea/mvn_swe_load_l0.pro
  - projects/maven/swea/mvn_swe_read_l0.pro
  - projects/maven/swea/mvn_swe_readcdf_3d.pro
  - projects/maven/swea/mvn_swe_com.pro
  - projects/maven/swea/mvn_swe_init.pro
  - projects/maven/swea/mvn_swe_config.pro
  - projects/maven/swea/mvn_swe_calib.pro
  - projects/maven/swea/mvn_swe_struct.pro
  - projects/maven/swea/mvn_swe_spice_init.pro
  - projects/maven/swea/mvn_swe_get3d.pro
  - projects/maven/swea/mvn_swe_getpad.pro
  - projects/maven/swea/mvn_swe_getspec.pro
  - projects/maven/swea/mvn_swe_convert_units.pro
  - projects/maven/swea/mvn_swe_sumplot.pro
  - projects/maven/swea/mvn_swe_sciplot.pro
  - projects/maven/swea/mvn_swe_addmag.pro
  - projects/maven/swea/mvn_swe_n1d.pro
  - projects/maven/swea/mvn_swe_pad_resample.pro
  - projects/maven/swea/mvn_swe_pad_restore.pro
  - projects/maven/swea/mvn_swe_sc_pot.pro
  - projects/maven/swea/mvn_swe_sc_negpot.pro
  - projects/maven/swea/mvn_swe_edit_quality.pro
  - projects/maven/swea/swe_engy_snap.pro
  - projects/maven/swea/swe_pad_snap.pro
  - projects/maven/swea/swe_3d_snap.pro
  - projects/maven/swea/mvn_swe_makecdf_3d.pro
  - projects/maven/swea/crib_l0_to_l2.txt
  - projects/maven/swea/Test/mvn_swe_load_l2a.pro
  - projects/maven/swea/mvn_sta_coldion.pro
  - projects/maven/swea/mvn_lpw_load_dlm.pro
  - projects/maven/swea/mvn_mag_tplot.pro
  - projects/maven/general/mvn_scpot.pro
  - projects/maven/general/mvn_pfp_file_retrieve.pro
  - projects/maven/l2gen/mvn_swe_l2gen.pro
maintenance: |
  Update when mvn_swe_load_l2 or mvn_swe_load_l0 change keywords, products or
  file paths, when the SWEA common blocks (mvn_swe_com.pro) change, or when the
  quality-flag scheme changes.
---

# MAVEN SWEA (IDL)

Code for SWEA (Solar Wind Electron Analyzer, 3 eV to 4.6 keV electrons). It
loads L0 or L2 data into common blocks, returns 3D, pitch-angle (PAD) and energy
(SPEC) data structures, makes summary tplots, and computes moments, spacecraft
potential and resampled PADs. The folder also holds some non-SWEA code.

## Layout

- `mvn_swe_crib.pro`: start here. It gives the full workflow and data caveats.
- Loading: `mvn_swe_load_l2.pro` (L2 CDF, read by `mvn_swe_readcdf_3d.pro` and its
  `_pad`, `_spec` siblings) and `mvn_swe_load_l0.pro` (L0, read by
  `mvn_swe_read_l0.pro`). `mvn_swe_com.pro` declares the common blocks;
  `mvn_swe_init.pro`, `mvn_swe_config.pro`, `mvn_swe_calib.pro` and
  `mvn_swe_struct.pro` fill calibration, configuration history and templates.
- Data access: `mvn_swe_get3d.pro`, `mvn_swe_getpad.pro`, `mvn_swe_getspec.pro`;
  units in `mvn_swe_convert_units.pro`.
- Tplot: `mvn_swe_sumplot.pro` (instrument summary), `mvn_swe_sciplot.pro`
  (science summary); `mvn_swe_add*` load other instruments as tplot panels (SWIA,
  STATIC, LPW, SEP, EUV) or put MAG vectors (`mvn_swe_addmag.pro`) and composite
  potentials into the SWEA common blocks.
- Analysis: moments `mvn_swe_n1d.pro`, `mvn_swe_n3d`; pitch angles
  `mvn_swe_pad_resample.pro` and precomputed `mvn_swe_pad_restore.pro`; potential
  `mvn_swe_sc_pot.pro` (positive), `mvn_swe_sc_negpot.pro` (negative); shape
  parameters `mvn_swe_shape_par*`; quality flags `mvn_swe_set_quality`,
  `mvn_swe_edit_quality.pro`.
- Snapshots from a tplot click: `swe_engy_snap.pro`, `swe_pad_snap.pro`,
  `swe_3d_snap.pro`, and other `swe_*_snap` routines.
- Production: L2 CDF writers `mvn_swe_makecdf_*` (e.g. `mvn_swe_makecdf_3d.pro`),
  key parameters `mvn_swe_kp`, notes in `crib_l0_to_l2.txt`; daily drivers are in
  `projects/maven/l2gen/` (e.g. `projects/maven/l2gen/mvn_swe_l2gen.pro`).
- `Test/`: team-only version 5 variants (`Test/mvn_swe_load_l2a.pro`, `*5.pro`).
- Not SWEA: STATIC cold-ion outflow (`mvn_sta_coldion.pro`, `mvn_sta_cio_*`),
  `mvn_lpw_load_dlm.pro`, `mvn_mag_tplot.pro`, and generic helpers (`bindata`,
  `nibble`, `sigfig`, `ctime2`).

## How `mvn_swe_load_l2` works

1. Products are chosen with `apid=` or `prod=`: a0 svy3d, a1 arc3d (3D, 64E x 16
   azimuths x 6 deflections), a2 svypad, a3 arcpad (64E x 16 pitch angles), a4
   svyspec (64E). a4 is always loaded; "arc" means burst (archive) data.
2. Files `maven/data/sci/swe/l2/YYYY/MM/mvn_swe_l2_<prod>_YYYYMMDD_v??_r??.cdf` come
   from `mvn_pfp_file_retrieve` (`projects/maven/general/mvn_pfp_file_retrieve.pro`).
3. It clears the common blocks (unless `/noerase`), checks SPICE with
   `mvn_spice_stat` and may call `mvn_swe_spice_init`, then runs `mvn_swe_init` and
   `mvn_swe_config`.
4. `mvn_swe_readcdf_*` read the files; the arrays go to `mvn_swe_3d`,
   `mvn_swe_3d_arc`, `mvn_swe_pad`, `mvn_swe_pad_arc`, `mvn_swe_engy` in common
   `swe_dat`. No tplot variables are made unless `/sumplot`.

A typical session (from the crib): `timespan`, `mvn_swe_spice_init`,
`maven_orbit_tplot`, `mvn_swe_load_l2`, `mvn_swe_sciplot`, then `mvn_scpot`
(`projects/maven/general/mvn_scpot.pro`).

## Things to know

- Code includes the common blocks with `@mvn_swe_com` (blocks `swe_raw`,
  `swe_dat`, `swe_cal`). `mvn_scpot` and the pickup-ion model also read them.
- The getters and plots work the same after an L0 or L2 load. L2 needs about six
  times the memory (a day of survey data is about 4 GB).
- If the loaded SPICE kernels don't cover the requested time, the loaders prompt
  at the terminal (`read`). Set `spiceinit=1` or `2`, or `/nospice`, in scripts.
- Quality flags: 0 = affected by the low-energy anomaly, 1 = unknown, 2 = good.
  Moment and potential routines take `qlevel=`.
- Energies near the spacecraft potential are wrong unless it is known; run
  `mvn_scpot` first. PADs need MAG data (`mvn_swe_addmag` rotates it to the SWEA
  frame).
- Structures carry `units_procedure = 'mvn_swe_convert_units'`.
