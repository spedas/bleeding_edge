---
related_files:
  - projects/AGENTS.md
  - projects/mex/AGENTS.md
  - projects/vex/aspera/vex_asp_els_load.pro
  - projects/vex/aspera/vex_asp_ima_load.pro
  - projects/vex/aspera/vex_asp_swm_load.pro
  - projects/vex/aspera/vex_asp_els_pad_load.pro
  - projects/vex/aspera/vex_asp_els_pad__define.pro
  - projects/vex/aspera/vex_asp_els_bkg.pro
  - projects/vex/aspera/vex_asp_els_get.pro
  - projects/vex/aspera/vex_asp_els_energy.pro
  - projects/vex/aspera/vex_asp_els_gf.pro
  - projects/vex/aspera/vex_asp_els_convert_units.pro
  - projects/vex/aspera/vex_asp_ima_ene_theta.pro
  - projects/vex/mag/vex_mag_load.pro
  - projects/vex/spice/vex_spice_kernels.pro
  - projects/vex/spice/vex_spice_load.pro
  - projects/maven/general/mvn_file_source.pro
  - projects/maven/general/mvn_pfp_spd_download.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/spice/spice_file_source.pro
maintenance: |
  Update when a VEX loader changes its data source (ESA PSA, NASA PDS PPI,
  NAIF), local cache layout, tplot names or common blocks, or when the PAD
  loader stops depending on MAVEN routines.
---

# Venus Express (VEX)

ESA's Venus Express: loaders for ASPERA-4 (ELS electrons, IMA ions, IMA
solar-wind moments, ELS pitch-angle distributions) and MAG, plus SPICE. Same
author and design as the MEX ASPERA code (`projects/mex/AGENTS.md`).

## Layout

- `aspera/`: loaders `aspera/vex_asp_els_load.pro`, `aspera/vex_asp_ima_load.pro`,
  `aspera/vex_asp_swm_load.pro`, `aspera/vex_asp_els_pad_load.pro` (with the
  class `aspera/vex_asp_els_pad__define.pro`); `aspera/vex_asp_els_bkg.pro`
  (NASA PDS source); getter `aspera/vex_asp_els_get.pro`; tables and units
  (`aspera/vex_asp_els_energy.pro`, `aspera/vex_asp_els_gf.pro`,
  `aspera/vex_asp_els_convert_units.pro`, `aspera/vex_asp_ima_ene_theta.pro`).
- `mag/vex_mag_load.pro`: MAG loader.
- `spice/`: `spice/vex_spice_kernels.pro`, `spice/vex_spice_load.pro` (makes
  `vex_eph_vso`, `vex_eph_lat`, `vex_eph_lon`, `vex_eph_alt`, `vex_eph_sza`).

## How the loaders work

- ELS and IMA: list the ESA PSA folders under
  `https://archives.esac.esa.int/psa/ftp/VENUS-EXPRESS/ASPERA4/`, download
  the files with `spd_download`, and cache them as `.sav` under
  `root_data_dir()+'vex/aspera/els/sav/YYYY/MM/'` (IMA likewise). Data go into
  the common block `vex_asp_dat` (`vex_asp_els`, `vex_asp_ima`); tplot gets
  `vex_asp_els_espec` (and `vex_asp_els_nsweep`), `vex_asp_ima_espec`,
  `vex_asp_ima_polar`. `vex_asp_els_load, /pds` reads from NASA PDS PPI
  (`https://pds-ppi.igpp.ucla.edu/data/vex-aspera4-els/`) via `vex_asp_els_bkg`.
- `vex_asp_swm_load`: PSA SWM moments to `vex_asp_nsw`, `vex_asp_vsw`,
  `vex_asp_tsw`, `vex_asp_qsw`.
- `vex_asp_els_pad_load`: PAD CSV files from PDS PPI (`vex-aspera4-els-pad`),
  fetched with MAVEN's `mvn_file_source` and `mvn_pfp_spd_download`
  (`projects/maven/general/`), returned as a `vex_asp_els_pad` object.
- `vex_mag_load`: default L3 at 1 s; `/l4` for 4 s, `/l2, hz=1|32|128` for
  full resolution. It downloads PSA `VENUS-EXPRESS/MAG/` `.TAB` files into
  `root_data_dir()+'vex/mag/<level>/'` and makes `vex_mag_<lvl>_bvso_<res>` and
  `vex_mag_<lvl>_btot_<res>`. L2 gives spacecraft-frame fields for the inboard
  and outboard sensors (`_bsc_is_`, `_bsc_os_`; `/vso` rotates them). `/pos`
  adds `vex_eph_vso_<res>` (Venus radii) and `vex_eph_alt_<res>` from the files.

## Things to know

- `vex_asp_els_get(time)` reads the common block, so run the loader first.
- `vex_asp_els_pad_load` needs `projects/maven/` on `!PATH`.
- Positions are in VSO. `vex_mag_load` uses a Venus radius of 6052 km;
  `vex_spice_load` takes the radii from the SPICE kernels.
- SPICE kernels come from NAIF via `spice_file_source`
  (`general/spice/spice_file_source.pro`), `VEX/kernels/`.
