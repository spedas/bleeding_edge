---
related_files:
  - general/missions/AGENTS.md
  - general/missions/fast/fa_general/fa_init.pro
  - general/missions/fast/fa_general/fa_pathnames.pro
  - general/missions/fast/fa_general/fa_config.pro
  - general/missions/fast/fa_general/fa_orbit_to_time.pro
  - general/missions/fast/fa_general/fa_time_to_orbit.pro
  - general/missions/fast/fa_general/fa_orbitrange.pro
  - general/missions/fast/fa_esa/l2util/fa_esa_load_l2.pro
  - general/missions/fast/fa_esa/l2util/fa_esa_l2_tplot.pro
  - general/missions/fast/fa_esa/l2util/fa_esa_l2_pad.pro
  - general/missions/fast/fa_esa/l2util/fa_esa_l2_edist.pro
  - general/missions/fast/fa_esa/l2util/fa_esa_l2gen.pro
  - general/missions/fast/fa_esa/get_l2/get_fa2_ies.pro
  - general/missions/fast/fa_esa/cdf_load/fa_load_esa_l1.pro
  - general/missions/fast/fa_esa/fa_esa_init.pro
  - general/missions/fast/fa_esa/functions/get_2dt.pro
  - general/missions/fast/fa_fields/fa_despun_e_load.pro
  - general/missions/fast/fa_fields/fa_dsp_load.pro
  - general/missions/fast/fa_fields/fa_sfa_load.pro
  - general/missions/fast/fa_fields/fa_load_mag_hr_dcb.pro
  - general/missions/fast/fa_fields/fa_fields_crib.pro
  - general/missions/fast/fa_k0/fa_k0_load.pro
  - general/missions/fast/fa_k0/istp_fa_k0_load.pro
  - general/missions/fast/fa_ops/README.pro
  - general/missions/fast/fa_ops/get_md_from_sdt.pro
  - general/missions/fast/fa_file_source.pro
  - general/missions/fast/fa_orbit_time.pro
  - general/missions/fast/fast_demo_l2.pro
  - general/missions/fast/fast_demo.crib
  - general/missions/fast/fast_orbit_times.sav
  - projects/fast/spedas_plugin/fast_ui_load_data.pro
  - projects/fast/spedas_plugin/fast_ui_import_data.pro
  - spedas_gui/plugins/fast_plugin.txt
  - general/misc/file_retrieve.pro
  - general/CDF/cdf2tplot.pro
maintenance: |
  Update when fa_init's servers or startup downloads change, when an ESA or
  fields loader is added or changes its file layout, or when fa_ops/ (the
  SDT-era code) is removed or split out.
---

# FAST (IDL)

Software for the FAST auroral satellite (1996-2009): loaders for ESA particle
data (L1 and L2), EFI/magnetometer fields data and key parameters, plus a large
body of original mission-operations code. The GUI plugin is separate, in
`projects/fast/spedas_plugin/`.

## Layout

- `fa_general/`: `fa_general/fa_init.pro`, `fa_general/fa_pathnames.pro`,
  `fa_general/fa_config.pro`, orbit/time conversion
  (`fa_general/fa_orbit_to_time.pro`, `fa_general/fa_time_to_orbit.pro`,
  `fa_general/fa_orbitrange.pro`) and `fast_orbit/` plotting helpers.
- `fa_esa/`: ESA electron and ion analyzers. `l2util/` holds the L2 loader
  `fa_esa/l2util/fa_esa_load_l2.pro`, tplot and pitch-angle/energy products and
  the L2 file generator; `get_l2/` and `get_l1/` hold `get_fa2_*` and `get_fa1_*`
  accessors; `cdf_load/` holds L1 loaders (`fa_esa/cdf_load/fa_load_esa_l1.pro`);
  `functions/` holds moment functions (`n_2d_new`, `j_2d_new`, ...) and
  `fa_esa/functions/get_2dt.pro`.
- `fa_fields/`: L2 fields loaders `fa_fields/fa_despun_e_load.pro`,
  `fa_fields/fa_dsp_load.pro`, `fa_fields/fa_sfa_load.pro`, the SPDF
  magnetometer loader `fa_fields/fa_load_mag_hr_dcb.pro`, a crib, and
  `l2util/` CDF writers. The `temp_fa_load_sfa_*.pro` files are drafts.
- `fa_k0/`: key-parameter loaders `fa_k0/fa_k0_load.pro` (SSL server) and
  `fa_k0/istp_fa_k0_load.pro` (SPDF).
- `fa_ops/`: about 480 files of the original operations software, which read
  data through SDT (see Things to know). `obsolete/`: skip.
- Top level: demos (see Examples), `fa_orbit_time.pro`, `fa_file_source.pro`,
  `fast_orbit_times.sav`.

## How `fa_esa_load_l2` works

1. It calls `fa_esa_init` (`fa_esa/fa_esa_init.pro`), which calls `fa_init`.
   `fa_init` creates `!fast` from `file_retrieve(/structure_format)`, picks the
   first reachable of `http://themis.ssl.berkeley.edu/data/fast/` and
   `http://sprg.ssl.berkeley.edu/data/fast/`, and loads
   `information/fasttimes.cdf` (orbit times) and `information/fastconfig` from
   it into the `fa_information` common block.
2. The time range, or `orbit=`, is converted to orbit numbers. Paths are per
   orbit, not per day: `l2/<type>/<NN000>/fa_esa_l2_<type>_*_<orbit>_vNN.cdf`,
   where `type` is `ies`, `ees`, `ieb` or `eeb`.
3. `file_retrieve` (`general/misc/file_retrieve.pro`) fetches them with
   `_extra=!fast`, and `fa_esa_cmn_l2read` reads each file.
4. The data go into common blocks, one per type (`fa_ies_l2`, `fa_ees_l2`,
   `fa_ieb_l2`, `fa_eeb_l2`), not into tplot. `get_fa2_ies()` and the other
   `get_fa2_*` functions return one time sample from them
   (`fa_esa/get_l2/get_fa2_ies.pro`).
5. With `/tplot`, `fa_esa_l2_tplot` makes quick-look spectrograms;
   `fa_esa_l2_pad` and `fa_esa_l2_edist` make pitch-angle and energy
   distributions.

The fields loaders use the same orbit-based paths but load with `cdf2tplot`
(`general/CDF/cdf2tplot.pro`), so their output is in tplot.
`fa_load_mag_hr_dcb` is different: it downloads from SPDF through `!istp`.

## Things to know

- Global state: `!fast`, the `fa_information` common block, and the per-type
  ESA common blocks; `fa_esa_init` also loads ESA lookup tables from
  `information/`. The first `fa_init` in a session needs the server, even for
  orbit/time conversion alone. `.fast_master` in the local data folder turns
  downloads off; `SPEDAS_DATA_DIR` and `FAST_REMOTE_DATA_DIR` override folders.
- Orbit numbers run from 1 to 51315.
- `fa_ops/` needs SDT (Science Data Tool) and its shared library: routines such
  as `fa_ops/get_md_from_sdt.pro` use `call_external` on `loadSDTBufLib.so`, so
  they fail in a normal IDL session. `fa_ops/README.pro` says to put the folder
  first on the path for SDT batch runs. Most `get_fa_*` names there (without the
  `1`/`2` suffix) are these SDT readers, not the CDF accessors.
- The GUI tab (`projects/fast/spedas_plugin/fast_ui_load_data.pro`,
  registered by `spedas_gui/plugins/fast_plugin.txt`) calls
  `fa_esa_load_l2`, `fa_esa_l2_pad`, `fa_esa_l2_edist` and `fa_load_mag_hr_dcb`
  from `projects/fast/spedas_plugin/fast_ui_import_data.pro`.

## Examples

`fast_demo_l2.pro` (ESA L2 loading, `get_fa2_*`, moments with `get_2dt`),
`fast_demo.crib` (ESA L1) and `fa_fields/fa_fields_crib.pro` (fields).
