---
related_files:
  - projects/AGENTS.md
  - projects/themis/spacecraft/fields/AGENTS.md
  - projects/themis/spacecraft/particles/AGENTS.md
  - projects/themis/state/AGENTS.md
  - projects/themis/ground/AGENTS.md
  - projects/themis/spacecraft/fields/thm_load_fgm.pro
  - projects/themis/common/thm_load_xxx.pro
  - projects/themis/common/thm_init.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/spd_cdf2tplot.pro
  - projects/themis/examples/basic/thm_crib_fgm.pro
  - projects/themis/tests/thm_python_validation_ut__define.pro
maintenance: |
  Update when thm_load_xxx's keywords or flow change, when a THEMIS loader is
  added or renamed, or when a subfolder gets its own AGENTS.md.
---

# THEMIS / ARTEMIS (IDL)

## Layout

- `spacecraft/fields/`, `spacecraft/particles/`: instrument loaders
  (`thm_load_<instrument>.pro`) and calibration (`thm_cal_<instrument>.pro`).
  Each has its own AGENTS.md.
- `ground/`: ground magnetometers and all-sky imagers (own AGENTS.md).
- `state/`: orbit and attitude (`thm_load_state`; own AGENTS.md). `spin/`: the spin model.
- `common/`: `thm_init` (sets the `!themis` system variable), the shared load
  engine `thm_load_xxx`, and plotting helpers.
- `examples/basic/`, `examples/advanced/`: crib sheets (`thm_crib_*.pro`), the
  quickest way to see how a routine is meant to be called.
- `tests/`: mgunit tests, e.g. `tests/thm_python_validation_ut__define.pro`,
  which compares results with pySPEDAS.
- `deprecated/`: old code; skip it.

## How `thm_load_fgm` loads data

1. `spacecraft/fields/thm_load_fgm.pro` defines two helpers above its main
   routine, `thm_load_fgm_relpath` and `thm_load_fgm_post`, then calls
   `thm_load_xxx` (`common/thm_load_xxx.pro`), passing the helper names as
   strings.
2. `thm_load_xxx` runs the path helper with `call_function`; it builds per-day
   file paths with `file_dailynames` (`general/misc/file_dailynames.pro`).
3. `spd_download` (`general/spedas_tools/spd_download/spd_download.pro`)
   fetches the files, using the server settings in `!themis` from `thm_init`
   (`common/thm_init.pro`).
4. `spd_cdf2tplot` (`general/CDF/spd_cdf2tplot.pro`) stores the files as tplot
   variables; a caller can swap in another routine with the `cdf_to_tplot`
   keyword.
5. `thm_load_xxx` runs the post-processing helper with `call_procedure`. For FGM
   this calibrates L1 data (`thm_cal_fgm`) and handles coordinates.

The other instrument loaders follow the same pattern, so a loader's path and
post-processing helpers are usually inside its own file. The example
`examples/basic/thm_crib_fgm.pro` shows typical calls.
