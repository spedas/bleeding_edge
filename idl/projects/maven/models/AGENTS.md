---
related_files:
  - projects/maven/AGENTS.md
  - projects/maven/models/mvn_model_bcrust_load.pro
  - projects/maven/models/mvn_model_bcrust.pro
  - projects/maven/models/mvn_model_bcrust_restore.pro
  - projects/maven/models/mvn_model_bcrust_calc.pro
  - projects/maven/models/mvn_model_bcrust_alt.pro
  - projects/maven/models/draw_crustal_fields_on_map.pro
  - projects/maven/models/martiancrustmodels.sav
  - projects/maven/models/Morschhauser_spc_dlat1.0_delon1.0_400km.sav
  - projects/maven/models/pui/mvn_pui_crib.pro
  - projects/maven/models/pui/mvn_pui_model.pro
  - projects/maven/models/pui/mvn_pui_data_load.pro
  - projects/maven/models/pui/mvn_pui_commonblock.pro
  - projects/maven/models/pui/mvn_pui_tplot.pro
  - projects/maven/models/pui/readme.txt
  - projects/maven/models/sep_elec/mvn_sep_elec_peri.pro
  - projects/maven/models/sep_elec/mvn_sep_elec_load_bcrust.pro
  - projects/maven/quicklook/mvn_ql_pfp_tplot.pro
  - projects/maven/swea/mvn_swe_com.pro
  - projects/maven/sep/mvn_sep_handler_commonblock.pro
maintenance: |
  Update when the crustal-field routines change their models, save files or
  tplot outputs, or when the pickup-ion model's entry point, data loading or
  common block changes.
---

# MAVEN models

Physical models compared with MAVEN data: Martian crustal magnetic field models
evaluated along the orbit, the pickup-ion model for SEP, SWIA and STATIC, and a
research study of SEP electrons at periapsis.

## Layout

- `mvn_model_bcrust_load.pro`: entry point for crustal fields along the orbit.
  It restores precomputed tplot save files (`mvn_model_bcrust_restore.pro`) or
  computes them (`mvn_model_bcrust.pro`, which calls
  `mvn_model_bcrust_calc.pro` for the spherical-harmonic sums).
- `mvn_model_bcrust_alt.pro`: a longitude-latitude map at a fixed altitude.
  `draw_crustal_fields_on_map.pro`: contours of a precomputed 400 km map.
- `martiancrustmodels.sav`, `Morschhauser_spc_*.sav`,
  `br_contours_Morschhauser_*.sav`: model coefficients and maps.
- `pui/`: the pickup-ion model (A. Rahmati). Entry point `pui/mvn_pui_model.pro`;
  see `pui/mvn_pui_crib.pro` and `pui/readme.txt`. `pui/old/`: superseded code.
- `sep_elec/`: study of electron flux dispersions at periapsis during the
  September 2017 SEP event (`sep_elec/mvn_sep_elec_peri.pro`).

## How `mvn_model_bcrust_load` works

1. It restores daily tplot save files from `maven/data/mod/bcrust/...` for the
   time range or `orbit=` range (`mvn_model_bcrust_restore`).
2. If none exist, it computes the field with `mvn_model_bcrust` (with `/calc`),
   asks at the terminal, or skips (`/nocalc`, for scripts).
3. `mvn_model_bcrust` gets the MAVEN position in `IAU_MARS` from SPICE and
   evaluates the chosen model. The model keywords are `/morschhauser` (default),
   `/arkani`, `/cain_2003`, `/cain_2011`, `/purucker`, `/langlais`, `/gao`.

`projects/maven/quicklook/mvn_ql_pfp_tplot.pro` calls it whenever it loads
MAG; its `bcrust` keyword becomes `calc` (0 means `/nocalc`).

## How `mvn_pui_model` works

1. `pui/mvn_pui_data_load.pro` loads MAG, SWIA, STATIC, SEP, SWEA, EUV and SPICE
   for the `timespan` range (`/nodataload` skips this; `/nomag` etc. skip one
   instrument and fall back to default drivers).
2. It solves pickup-ion trajectories in uniform upstream fields and bins the
   modeled O+ and H+ fluxes into each instrument's energy and angle response
   (`/do3d` for 3D SWIA and STATIC spectra; needs several GB of memory).
3. Results go to `common mvn_pui_com` (`pui/mvn_pui_commonblock.pro`); then
   `mvn_pui_tplot, /store, /tplot` makes model-data comparison panels.

## Things to know

- `mvn_model_bcrust` loads (and clears) SPICE kernels itself if the loaded ones
  don't cover the time range.
- The model save files are found next to the routines with
  `routine_filepath`, so they must stay in this folder.
- The pickup-ion model is valid only when MAVEN is upstream of the bow shock.
  Its common-block file also includes the SWEA
  (`projects/maven/swea/mvn_swe_com.pro`) and SEP
  (`projects/maven/sep/mvn_sep_handler_commonblock.pro`) blocks.
- `sep_elec/` restores model files from hardcoded personal paths (e.g.
  `sep_elec/mvn_sep_elec_load_bcrust.pro`); it does not run elsewhere as is.
