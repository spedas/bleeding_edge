---
related_files:
  - general/missions/AGENTS.md
  - general/missions/rbsp/efw/rbsp_efw_init.pro
  - general/missions/rbsp/efw/rbsp_efw_config.pro
  - general/missions/rbsp/efw/rbsp_load_efw_waveform.pro
  - general/missions/rbsp/efw/rbsp_load_efw_waveform_l2.pro
  - general/missions/rbsp/efw/rbsp_load_efw_waveform_l3.pro
  - general/missions/rbsp/efw/rbsp_efw_cal_waveform.pro
  - general/missions/rbsp/efw/rbsp_efw_get_cal_params.pro
  - general/missions/rbsp/efw/rbsp_efw_deconvol_inst_resp.pro
  - general/missions/rbsp/efw/rbsp_efw_get_gain_results.pro
  - general/missions/rbsp/efw/rbsp_gse2mgse.pro
  - general/missions/rbsp/efw/rbsp_uvw_to_mgse.pro
  - general/missions/rbsp/efw/examples/rbsp_efw_waveform_crib.pro
  - general/missions/rbsp/efw/calibration_files/rbsp_efw_get_gain_results.pro
  - general/missions/rbsp/efw/calibration_files/rbsp_efw_deconvol_inst_resp.pro
  - general/missions/rbsp/efw/cdf_partial_load/rbsp_load_efw_waveform_partial.pro
  - general/missions/rbsp/efw/findpath.pro
  - general/missions/rbsp/efw/utils/findpath.pro
  - general/missions/rbsp/efw/rbsp_phasef/rbsp_efw_phasef_get_server.pro
  - general/missions/rbsp/emfisis/rbsp_emfisis_init.pro
  - general/missions/rbsp/emfisis/rbsp_load_emfisis.pro
  - general/missions/rbsp/rbspice/rbsp_rbspice_init.pro
  - general/missions/rbsp/rbspice/rbsp_rbspice_config.pro
  - general/missions/rbsp/rbspice/rbsp_load_rbspice.pro
  - general/missions/rbsp/rbspice/rbsp_load_rbspice_crib.pro
  - general/missions/rbsp/ect/rbsp_ect_init.pro
  - general/missions/rbsp/ect/rbsp_load_ect_l3.pro
  - general/missions/rbsp/ect/rbsp_load_mageis_l2.pro
  - general/missions/rbsp/ect/examples/rbsp_mageis_example_crib.pro
  - general/missions/rbsp/spacecraft/rbsp_load_state.pro
  - general/missions/rbsp/spacecraft/rbsp_load_spice_state.pro
  - general/missions/rbsp/spacecraft/rbsp_spice_init.pro
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/cdf2tplot.pro
  - general/CDF/spd_cdf2tplot.pro
maintenance: |
  Update when an RBSP loader, init routine or server changes, when duplicate
  files inside efw/ are removed or diverge further, or when rbsp_phasef/
  becomes runnable from SPEDAS alone.
---

# Van Allen Probes / RBSP (IDL)

Loaders and analysis for the two Van Allen Probes (RBSP-A and -B, 2012-2019),
one folder per instrument team. There is no `projects/rbsp/` folder and no
GUI plugin.

## Layout

- `efw/` (electric fields, about 400 files): `rbsp_efw_init` (`!rbsp_efw`),
  loaders (`rbsp_load_efw_waveform`, `_l2`, `_l3`, `rbsp_load_efw_spec`,
  `_fbk`, ...), calibration (`rbsp_efw_cal_*`), spin fits and coordinate
  routines. Subfolders: `calibration_files/` (response functions, event
  tables), `cdf_file_production/` and `l1_to_l2/` (team code that writes
  L2/L3 CDFs), `cdf_partial_load/`, `examples/` (about 30 cribs), `utils/`,
  `rbsp_phasef/` (see Things to know).
- `emfisis/` (`emfisis/rbsp_load_emfisis.pro`, `!rbsp_emfisis`), `rbspice/`
  (`rbspice/rbsp_load_rbspice.pro`, `!rbsp_rbspice`), `ect/`
  (`ect/rbsp_load_ect_l3.pro` for HOPE, MagEIS and REPT L3,
  `ect/rbsp_load_mageis_l2.pro`, `!rbsp_ect`): one init/config set and loader
  per instrument.
- `spacecraft/`: `spacecraft/rbsp_load_state.pro` (downloaded state files) and
  the SPICE-based `spacecraft/rbsp_load_spice_state.pro` (`!rbsp_spice`).

## How `rbsp_load_efw_waveform` loads data

1. `rbsp_efw_init` creates `!rbsp_efw` and calls `rbsp_efw_config`
   (`efw/rbsp_efw_config.pro`): server `http://themis.ssl.berkeley.edu/data/rbsp/`,
   local `root_data_dir()` + `rbsp/`, overridden by the saved config and
   `RBSP_EFW_DATA_DIR` / `RBSP_EFW_REMOTE_DATA_DIR`.
2. For each probe and datatype (`esvy`, `vsvy`, `eb1`, `mscb1`, ...) it builds
   `rbspX/l1/<type>/YYYY/rbspX_l1_<type>_YYYYMMDD_v*.cdf` with `file_dailynames`
   (`general/misc/file_dailynames.pro`) and fetches each file with
   `spd_download` (`general/spedas_tools/spd_download/spd_download.pro`).
3. `cdf2tplot` (`general/CDF/cdf2tplot.pro`) stores `rbspX_efw_<type>`.
4. With the default `type='calibrated'` it calls `rbsp_efw_cal_waveform`
   (`efw/rbsp_efw_cal_waveform.pro`), which takes gains and offsets from
   `rbsp_efw_get_cal_params` and, for burst data, removes the instrument
   response with `rbsp_efw_deconvol_inst_resp`.

The other instruments follow the same init-then-download pattern with their own
system variable. ECT uses `spd_cdf2tplot` (`general/CDF/spd_cdf2tplot.pro`)
from SPDF; EMFISIS downloads from `https://emfisis.physics.uiowa.edu/`.

## Duplicate file names (which copy is live)

IDL runs whichever same-named file comes first on `!PATH`; check with
`file_which` before editing.

- `efw/` top level versus `efw/calibration_files/`: ten response and
  calibration routines exist in both (`rbsp_adc_response`,
  `rbsp_efw_deconvol_inst_resp`, `rbsp_efw_get_gain_results`, ...). The
  `efw/calibration_files/` copies are the maintained ones (revised in 2020;
  the top-level copies date from 2012-2014). Most differ only in comments, but
  `efw/calibration_files/rbsp_efw_get_gain_results.pro` adds search-coil phase
  curves that `efw/rbsp_efw_get_gain_results.pro` lacks.
- `efw/cdf_file_production/` versus `efw/l1_to_l2/`: seven files
  (`rbsp_efw_make_l2_*`, `rbsp_efw_make_l3`, `rbsp_efw_get_flag_values`); the
  `cdf_file_production/` versions are newer and substantially different.
- Inside `efw/rbsp_phasef/`, `obsolete/` repeats many files from `misc/` and
  `file_production/`; skip `obsolete/`. `efw/findpath.pro` and
  `efw/utils/findpath.pro` are identical.

## Things to know

- Coordinates: EFW data start in spinning UVW; DSC is the despun frame; MGSE
  (modified GSE: x along the spin axis, y in the ecliptic plane and duskward,
  equal to GSE when the spin axis points at the Sun) is the usual output
  (`efw/rbsp_uvw_to_mgse.pro`, `efw/rbsp_gse2mgse.pro`).
- `!rbsp_rbspice` stores its server and local folder with a `?` that
  `rbsp_load_rbspice` replaces with the probe letter
  (`rbspice/rbsp_rbspice_config.pro`), and it reads files with
  `mms_cdf2tplot`, so the MMS code must be on the path.
- `rbsp_load_spice_state` needs the ICY SPICE library (`icy_test`).
- `efw/rbsp_phasef/` is the team's final (Phase F) reprocessing code. It calls
  helper functions that are not in this repository (`join_path`,
  `get_var_data`, `prepare_files`, ...), and reads from
  `http://rbsp.space.umn.edu/rbsp_efw` (`rbsp_efw_phasef_get_server`), so most
  of it does not run in a plain SPEDAS install.
- Probes are `'a'` and `'b'`; tplot names start with `rbspa_`/`rbspb_` and the
  instrument (`rbspa_efw_esvy`, `rbspb_emfisis_...`).

## Examples

`efw/examples/rbsp_efw_waveform_crib.pro` and the other EFW cribs,
`rbspice/rbsp_load_rbspice_crib.pro`, `ect/examples/rbsp_mageis_example_crib.pro`.
