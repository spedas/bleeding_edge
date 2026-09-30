---
related_files:
  - projects/AGENTS.md
  - projects/erg/ground/AGENTS.md
  - projects/erg/satellite/AGENTS.md
  - projects/iugonet/AGENTS.md
  - projects/erg/CHANGES.txt
  - projects/erg/tools/print_str_maxlet.pro
  - projects/erg/tools/show_cdf_att.pro
  - projects/erg/satellite/erg/common/erg_init.pro
  - projects/erg/satellite/erg/examples
  - projects/erg/examples/erg_crib_gmag_isee_fluxgate.pro
  - projects/erg/examples/erg_crib_superdarn.pro
  - projects/erg/ground/geomag/erg_load_gmag_isee_fluxgate.pro
  - general/misc/root_data_dir.pro
  - general/CDF/cdf2tplot.pro
maintenance: |
  Update when the split between satellite/ and ground/ changes, when ground
  loaders start using erg_init/!erg, or when tools/ gains routines that other
  projects call.
---

# ERG (Arase) and ERG-SC ground data

Code from the ERG Science Center (ERG-SC, ISEE, Nagoya University): loaders
and analysis tools for the ERG (Arase) satellite, and loaders for the ground
networks ERG-SC distributes. It is maintained upstream as the "ERG-SC plug-in".

## Layout

- `satellite/erg/`: the Arase spacecraft, one folder per instrument plus
  orbit, attitude and coordinate transforms, and particle products. See
  `satellite/AGENTS.md`.
- `ground/`: magnetometers, OMTI all-sky imagers, riometer, VLF receivers and
  SuperDARN radars. See `ground/AGENTS.md`.
- `examples/`: cribs for the ground loaders (`erg_crib_gmag_*.pro`,
  `examples/erg_crib_superdarn.pro`, ...). Satellite cribs are in
  `satellite/erg/examples/`.
- `tools/`: `print_str_maxlet` (prints a long string wrapped to a width; most
  ERG loaders and the NIPR, WDC and EISCAT loaders of IUGONET use it for the
  data policy) and `show_cdf_att`.
- `CHANGES.txt`: dated notes on important changes, newest first.

## Satellite vs ground

| | `satellite/` | `ground/` |
|---|---|---|
| Init | `erg_init` (`satellite/erg/common/erg_init.pro`) sets `!erg` | none; each loader fills its own `file_retrieve(/struct)` |
| Local dir | `!erg.local_data_dir` (default `root_data_dir()` + `ergsc/`, or `$ERG_DATA_DIR`) | hard-coded `root_data_dir()` + `ergsc/` |
| Loader names | `erg_load_<instrument>` | `erg_load_gmag_*`, `erg_load_isee_*`, `erg_load_camera_omti_asi`, `erg_load_sdfit` |
| tplot names | `erg_<instrument>_<level>_...` | network prefix: `isee_fluxgate_`, `mm210_`, `omti_asi_`, `sd_<radar>_` |
| Credentials | `uname`/`passwd` keywords (digest auth) for restricted data | none |

Both use `file_dailynames`, `spd_download` and mostly `cdf2tplot`
(`general/CDF/cdf2tplot.pro`) with a `prefix=`. Most then print the PI
and rules-of-the-road text from the CDF global attributes (not the orbit,
attitude and SuperDARN loaders). A typical ground loader is
`ground/geomag/erg_load_gmag_isee_fluxgate.pro`.

## Things to know

- `erg_init`, `!erg`, `$ERG_DATA_DIR` and `$ERG_REMOTE_DATA_DIR` affect only
  satellite loaders; the ground loaders ignore them.
- ERG ground and IUGONET depend on each other: many `iug_load_*` routines
  forward to ERG ground loaders, `erg_load_gmag_nipr` forwards to IUGONET, and
  SuperDARN plotting uses IUGONET's `map2d` library. Keep
  `projects/iugonet/` on `!PATH` too (see `projects/iugonet/AGENTS.md`).
- `erg_init` has side effects beyond `!erg`: it sets `!prompt` to `ERG> ` and
  global tplot options (`no_interp`, `lazy_ytitle`, window 0), and loads a
  color table through `erg_graphics_config` unless `/no_color_setup`.
- The ISEE 3D viewer exists twice: `satellite/erg/particle/isee3d/` and
  `spedas_gui/isee3d/`, with some files differing. Which copy runs
  depends on `!PATH` order.
