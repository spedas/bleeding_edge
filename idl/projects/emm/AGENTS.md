---
related_files:
  - projects/AGENTS.md
  - projects/emm/emm_file_retrieve.pro
  - projects/emm/emm_emus_examine_disk.pro
  - projects/emm/emm_emus_binning.pro
  - projects/emm/emm_emus_image_bar.pro
  - projects/emm/emm_emus_image_lon_bar.pro
  - projects/emm/emm_emus_maven_ql.pro
  - projects/emm/emm_emus_map_disk.pro
  - projects/emm/emm_emu_map_disk.pro
  - projects/emm/emm_emus_mvn_joint_images.pro
  - projects/emm/emm_emu_maven_orbit_plot.pro
  - projects/emm/emm_int_simple.pro
  - projects/emm/fixed_map_grid.pro
  - projects/emm/mvn_emm_crib.pro
  - projects/emm/OrbitGeometryPlotFiles
  - projects/emm/OrbitGeometryPlotFiles/mvn_orbproj_panel_emus.pro
  - projects/emm/OrbitGeometryPlotFiles/mvn_orbproj_panel_brain.pro
  - projects/emm/OrbitGeometryPlotFiles/plot_mpb.pro
  - projects/emm/OrbitGeometryPlotFiles/plot_shock.pro
  - projects/emm/OrbitGeometryPlotFiles/script_test_orbit.pro
  - projects/emm/OrbitGeometryPlotFiles/._ctload.pro
  - projects/emm/OrbitGeometryPlotFiles/._br_360x180_pc.sav
  - projects/emm/OrbitGeometryPlotFiles/br_contours_Morschhauser_spc_dlat1.0_delon1.0_400km.sav
  - projects/maven/maven_orbit_tplot/mvn_sun_bar.pro
  - projects/maven/mvn_orb_ql/mvn_orbql_cylplot_panel.pro
  - projects/maven/iuvs/mvn_iuv_file_retrieve.pro
  - projects/maven/general/roundst.pro
  - external/astron/fits/mrdfits.pro
maintenance: |
  Update when EMUS files get a downloader or a new default location, when the
  main entry point or the disk structure changes, or when the routine-name
  clashes with MAVEN code are resolved.
---

# Emirates Mars Mission (EMM)

Tools for EMUS, the ultraviolet spectrometer on the Emirates Mars Mission
(Hope): disk images of UV emissions, made to compare with MAVEN in-situ data.
There is no downloader; the FITS files must already be on disk.

## Layout

- `emm_file_retrieve.pro`: finds local EMUS files for a time range, `level`
  (default `l2b`) and `mode` (required: `os1`, `os2`, `osr`, `os3`, `os4`, ...).
- `emm_emus_examine_disk.pro`: the main entry. Finds files per mode, reads
  them with `mrdfits` (`external/astron/fits/mrdfits.pro`), bins them
  (`emm_emus_binning.pro`), returns the `disk` structure array, and can
  write images.
- `emm_emus_image_bar.pro`: tplot bars from `disk`. `emm_emus_maven_ql.pro`:
  MAVEN quicklook panels alongside them.
- `emm_emus_map_disk.pro`, `emm_emu_map_disk.pro`, `emm_emus_mvn_joint_images.pro`,
  `emm_emu_maven_orbit_plot.pro`: maps and joint EMUS/MAVEN plots.
- `emm_int_simple.pro` (simple integrator), `fixed_map_grid.pro` (modified
  copy of IDL's MAP_GRID).
- `mvn_emm_crib.pro`: the crib, with the MAVEN-EMM data-sharing rules; start here.
- `OrbitGeometryPlotFiles/`: MAVEN orbit-geometry plot panels (`mvn_*_panel*`),
  generic helpers (`ps_set`, `symcat`, `colorscale`, `plotposn`, ...), and a
  crustal-field contour file
  (`OrbitGeometryPlotFiles/br_contours_Morschhauser_spc_dlat1.0_delon1.0_400km.sav`).

## Things to know

- `emm_file_retrieve` defaults `local_path` to `/disks/hope/data/emm/data/`
  (SSL network). Elsewhere pass `local_path=` to a copy with the layout
  `<instrument>/<level>/<mode>/YYYY/MM/emm_emu_<level>_*.fits.gz`.
- It lists folders by spawning `ls` into `./temp_list_file.txt` in the
  current directory, so it needs a Unix shell and a writable working directory.
- MAVEN code must be on `!PATH`: `roundst` (`projects/maven/general/roundst.pro`),
  `mvn_spice_kernels`, and the MAVEN quicklook loaders.
- Routine names clash with MAVEN code; whichever file compiles last wins:
  - `emm_emus_image_lon_bar.pro` defines `mvn_sun_bar`, not a routine named
    after the file; MAVEN's is `projects/maven/maven_orbit_tplot/mvn_sun_bar.pro`.
  - `OrbitGeometryPlotFiles/mvn_orbproj_panel_emus.pro` defines
    `mvn_orbproj_panel_brain`, as does `OrbitGeometryPlotFiles/mvn_orbproj_panel_brain.pro`.
  - `plot_mpb` and `plot_shock` (`OrbitGeometryPlotFiles/plot_mpb.pro`,
    `OrbitGeometryPlotFiles/plot_shock.pro`) are also defined in
    `projects/maven/mvn_orb_ql/mvn_orbql_cylplot_panel.pro`.
  - `emm_file_retrieve.pro` defines `get_file_name_string` and
    `numbered_filestring`, which `projects/maven/iuvs/mvn_iuv_file_retrieve.pro`
    also defines.
- `OrbitGeometryPlotFiles/._ctload.pro` and `OrbitGeometryPlotFiles/._br_360x180_pc.sav`
  are macOS AppleDouble metadata, not code. `ctload`, named in comments, is
  not in the repository.
- `OrbitGeometryPlotFiles/script_test_orbit.pro` is a batch script (`.r` lines),
  not a routine.
