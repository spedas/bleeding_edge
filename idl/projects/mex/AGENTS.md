---
related_files:
  - projects/AGENTS.md
  - projects/vex/AGENTS.md
  - projects/mex/aspera/mex_asp_els_load.pro
  - projects/mex/aspera/mex_asp_ima_load.pro
  - projects/mex/aspera/mex_asp_swm_load.pro
  - projects/mex/aspera/mex_asp_els_get.pro
  - projects/mex/aspera/mex_asp_ima_get.pro
  - projects/mex/aspera/mex_asp_els_convert_units.pro
  - projects/mex/aspera/mex_asp_ima_bkg.pro
  - projects/mex/marsis/mex_marsis_load.pro
  - projects/mex/marsis/mex_marsis_com.pro
  - projects/mex/marsis/mex_marsis_snap.pro
  - projects/mex/marsis/mex_marsis_tplot.pro
  - projects/mex/spice/mex_spice_kernels.pro
  - projects/mex/spice/mex_spice_load.pro
  - projects/mex/spice/mex_orbit_num.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/misc/file_retrieve.pro
  - general/spice/spice_file_source.pro
maintenance: |
  Update when a MEX loader changes its data source (ESA PSA, WUSTL, U. Iowa,
  NAIF), its local cache layout or common blocks, or when an instrument or
  mission-extension dataset is added.
---

# Mars Express (MEX)

ESA's Mars Express: loaders for ASPERA-3 (ELS electrons, IMA ions, and
solar-wind moments from IMA) and MARSIS (radar sounder: ionograms, electron
density, magnetic field), plus SPICE. The ASPERA code has the same author and
design as `projects/vex/` (see `projects/vex/AGENTS.md`).

## Layout

- `aspera/`: loaders `aspera/mex_asp_els_load.pro`, `aspera/mex_asp_ima_load.pro`,
  `aspera/mex_asp_swm_load.pro`; getters `aspera/mex_asp_els_get.pro` and
  `aspera/mex_asp_ima_get.pro` (one distribution structure at a time);
  calibration and tables (`mex_asp_els_calib`, `mex_asp_els_gf`,
  `mex_asp_ima_calib`, `aspera/mex_asp_ima_bkg.pro`, `mex_asp_ima_mass`, ...);
  `aspera/mex_asp_els_convert_units.pro`.
- `marsis/`: `marsis/mex_marsis_load.pro`, the include file
  `marsis/mex_marsis_com.pro` (common blocks), and plotting and trace tools
  (`marsis/mex_marsis_tplot.pro`, `marsis/mex_marsis_snap.pro`, radargram,
  spectrogram, crosshairs).
- `spice/`: `spice/mex_spice_kernels.pro`, `spice/mex_spice_load.pro` (makes
  `mex_eph_mso`, `mex_eph_alt`, `mex_eph_sza`, ...), `spice/mex_orbit_num.pro`.

## How `mex_asp_els_load` loads data

1. `mex_asp_els_list` (same file) lists the remote folder for each day: ESA
   PSA `https://archives.esac.esa.int/psa/ftp/MARS-EXPRESS/ASPERA-3/`, dataset
   `MEX-M-ASPERA3-2-EDR-ELS[-EXTn]-V1.0` (or `3-RDR` with `/l2`), or WUSTL PDS
   Geosciences with `psa=0`. The `-EXTn` suffix comes from hard-coded
   mission-extension start dates.
2. If the file list matches the one stored in the local `.sav` cache
   (`root_data_dir()+'mex/aspera/els/l1b/sav/YYYY/MM/'`), it restores the cache;
   otherwise `mex_asp_els_read` downloads the CSV files with `spd_download`
   and reads them (`/save` writes a new cache).
3. `mex_asp_els_com` puts the data in the common block `mex_asp_dat`
   (`mex_asp_els`, `mex_asp_ima`) and the loader makes `mex_asp_els_espec`
   (counts for L1b, flux for L2).

`mex_asp_ima_load` works the same way (`mex_asp_ima_espec`);
`mex_asp_swm_load` reads the PSA SWM moments and makes `mex_asp_nsw`,
`mex_asp_vsw`, `mex_asp_tsw` and `mex_asp_qsw`.

## Things to know

- `/no_server` skips the remote listing and uses only the local cache.
- `mex_asp_els_get(time)` and `mex_asp_ima_get(time)` read the common block,
  so run the loader first. Their headers say `MVN_ASP_*`; the names are `mex_`.
- MARSIS: restricted data from `https://space.physics.uiowa.edu/plasma-wave/marsx/`
  need `MARSIS_USER_PASS` (or `marsis_user_pass=`); without it the loader uses
  the public PDS copy at `https://space.physics.uiowa.edu/pds/`. It downloads
  with `file_retrieve`/`spd_download` under `root_data_dir()+'mex/'`, keeps data
  in the common blocks from `@mex_marsis_com`, and gets orbit numbers from
  `mex_orbit_num`, which downloads the NAIF orbit file.
- SPICE kernels come from NAIF via `spice_file_source`
  (`general/spice/spice_file_source.pro`), `MEX/kernels/`, using the meta-kernel
  `MEX_OPS.TM`. Positions are in MSO.
