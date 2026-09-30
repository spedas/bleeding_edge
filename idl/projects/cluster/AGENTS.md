---
related_files:
  - projects/AGENTS.md
  - projects/cluster/common/cl_load_data.pro
  - projects/cluster/common/cl_init.pro
  - projects/cluster/common/cl_config.pro
  - projects/cluster/common/cl_config_filedir.pro
  - projects/cluster/fgm/cl_load_fgm.pro
  - projects/cluster/cluster_science_archive/cl_load_csa.pro
  - projects/cluster/cluster_science_archive/cl_csa_init.pro
  - projects/cluster/cluster_science_archive/cl_csa_config.pro
  - projects/cluster/cluster_science_archive/cl_load_csa_crib.pro
  - projects/cluster/cluster_science_archive/cluster_csa_cdf_check.pro
  - projects/cluster/examples/cl_load_crib.pro
  - projects/cluster/spedas_plugin/cl_ui_load_data.pro
  - projects/cluster/spedas_plugin/cl_ui_load_data_load_pro.pro
  - projects/cluster/spedas_plugin/cl_csa_ui_load_data.pro
  - projects/cluster/spedas_plugin/cl_csa_ui_load_data_load_pro.pro
  - spedas_gui/plugins/cl_plugin.txt
  - spedas_gui/plugins/cl_csa_plugin.txt
  - general/misc/file_dailynames.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/spd_cdf2tplot.pro
maintenance: |
  Update when cl_load_data's path patterns, server or keywords change, when an
  instrument wrapper is added, or when cl_load_csa changes its CSA endpoint,
  dataset list or file handling.
---

# Cluster (IDL)

Loaders for the four Cluster spacecraft. There are two independent routes: CDFs
from NASA SPDF through `cl_load_data` and thin per-instrument wrappers, and
datasets from ESA's Cluster Science Archive (CSA) through `cl_load_csa`.

## Layout

- `common/`: `common/cl_load_data.pro` (the SPDF loader), `common/cl_init.pro`
  (sets `!cluster`), `common/cl_config.pro` and the other `cl_config_*`
  routines (saved configuration, environment variables).
- One folder per instrument, each with one wrapper `cl_load_<inst>`:
  `aspoc/`, `cis/`, `dwp/`, `edi/`, `efw/`, `fgm/`, `peace/`, `rapid/`, `staff/`,
  `wbd/`, `whisper/` (the whisper wrapper is `cl_load_whi`).
- `cluster_science_archive/`: `cluster_science_archive/cl_load_csa.pro`, its own
  init and config (`cluster_science_archive/cl_csa_init.pro`, `!cluster_csa`),
  and a crib.
- `examples/cl_load_crib.pro`: loads and plots each instrument from SPDF.
- `spedas_plugin/`: two GUI tabs, `spedas_plugin/cl_ui_load_data.pro` (SPDF) and
  `spedas_plugin/cl_csa_ui_load_data.pro` (CSA), registered by
  `spedas_gui/plugins/cl_plugin.txt` and
  `spedas_gui/plugins/cl_csa_plugin.txt`.

## How `cl_load_fgm` loads data (SPDF route)

1. `fgm/cl_load_fgm.pro` sets defaults (probe `'1'`, datatype `'up'`) and calls
   `cl_load_data` with `instrument='fgm'`. The other wrappers do the same with
   their instrument code (`'pea'`, `'rap'`, `'sta'`, `'whi'`, ...) and datatype
   `'pp'` (`'waveform'` for WBD).
2. `cl_load_data` calls `cl_init`, then builds paths such as
   `c1/up/fgm/YYYY/c1_up_fgm_YYYYMMDD_v??.cdf` (FGM `'cp'` data use
   `c1/cp/YYYY/c1_cp_fgm_spin_...`).
3. `file_dailynames` expands them and `spd_download` fetches them from the
   `remote_data_dir` keyword or, by default, the SPDF Cluster tree
   (`general/misc/file_dailynames.pro`,
   `general/spedas_tools/spd_download/spd_download.pro`).
4. `spd_cdf2tplot` (`general/CDF/spd_cdf2tplot.pro`) stores the variables
   with `/load_labels`. Time clipping happens only with `/time_clip`.

## How `cl_load_csa` works (CSA route)

`cl_load_csa` takes CSA dataset names (`CP_FGM_SPIN`, `CP_CIS-HIA_ONBOARD_MOMENTS`,
...; the list is `master_datatypes` in the file, and `/valid_names` returns it)
and probes `C1`-`C4`. It sends one request to the CSA TAP data URL
(`https://csa.esac.esa.int/csa-sl-tap/data`) with an `IDLnetURL` object, saves the
returned `.tar.gz` under `!spedas.temp_dir`, unpacks it, copies each CDF to
`!cluster_csa.local_data_dir/<probe>/<dataset>/<year>/`, and loads it with
`spd_cdf2tplot, /all`. It calls `spedas_init` if `!spedas` is missing.

## Things to know

- Tplot names come straight from the CDF variable names, with no prefix added,
  for example `B_vec_xyz_gse__C4_CP_FGM_SPIN` or `N_p__C4_PP_CIS` (see
  `examples/cl_load_crib.pro`).
- `!cluster` and `!cluster_csa` are separate `file_retrieve` structures with an
  extra `mirror_data_dir` field. Environment variables `CLUSTER_DATA_DIR`,
  `CLUSTER_REMOTE_DATA_DIR`, `SPEDAS_DATA_DIR` and `ROOT_DATA_DIR` override the
  local and remote folders (`common/cl_config.pro`); the CSA ones are read in
  `cluster_science_archive/cl_csa_config.pro`.
- `cl_load_data` ignores `!cluster.remote_data_dir`: without the
  `remote_data_dir` keyword it always uses SPDF.
- CSA dataset names are case-sensitive.
- `cluster_science_archive/cluster_csa_cdf_check.pro` is a developer script with
  hard-coded local paths; skip it.

## Examples

`examples/cl_load_crib.pro` (SPDF, all instruments) and
`cluster_science_archive/cl_load_csa_crib.pro` (CSA).
