---
related_files:
  - projects/AGENTS.md
  - projects/maven/general/AGENTS.md
  - projects/maven/lpw/AGENTS.md
  - projects/maven/mag/AGENTS.md
  - projects/maven/models/AGENTS.md
  - projects/maven/quicklook/AGENTS.md
  - projects/maven/sep/AGENTS.md
  - projects/maven/sta/AGENTS.md
  - projects/maven/swea/AGENTS.md
  - projects/maven/swia/AGENTS.md
  - projects/maven/general/mvn_pfp_file_retrieve.pro
  - projects/maven/general/mvn_file_source.pro
  - projects/maven/general/mvn_set_userpass.pro
  - projects/maven/general/mvn_orbit_num.pro
  - projects/maven/general/spice/mvn_spice_load.pro
  - projects/maven/euv/mvn_euv_load.pro
  - projects/maven/euv/mvn_euv_l3_load.pro
  - projects/maven/ngi/mvn_ngi_load.pro
  - projects/maven/iuvs/mvn_iuv_file_retrieve.pro
  - projects/maven/acc/mvn_acc_load_l3.pro
  - projects/maven/kp/mvn_kp_insitu_check_for_new_l2_files.pro
  - projects/maven/quicklook/mvn_qlook_load_kp.pro
  - projects/maven/eph/get_mvn_eph.pro
  - projects/maven/eph/mvn_pfp_cotrans.pro
  - projects/maven/maven_orbit_tplot/maven_orbit_tplot.pro
  - projects/maven/maven_orbit_tplot/maven_orbit_snap.pro
  - projects/maven/mvn_orb_ql/mvn_orb_ql.pro
  - projects/maven/mvn_orb_ql/mvn_orb_ql_crib.pro
  - projects/maven/DPU/mvn_pfp_l0_file_read.pro
  - projects/maven/DPU/mvn_pfdpu_cmnblk_handler.pro
  - spedas_gui/plugins/maven_pfp_plugin.txt
  - projects/maven/mav_gse_structure_append.pro
  - projects/maven/mvn_spc_met_to_unixtime.pro
  - projects/maven/mvn_spc_apid_file_read.pro
  - projects/maven/mvn_pf_make_cdf.pro
  - projects/maven/morbit.pro
  - projects/maven/swea/mvn_swe_crib.pro
  - projects/maven/sep/mvn_lpw_handler.pro
  - projects/maven/swea/mvn_sta_coldion.pro
  - projects/maven/swea/mvn_mag_tplot.pro
maintenance: |
  Update when a MAVEN instrument folder is added, removed or gets its own
  AGENTS.md, when an instrument's main loader is renamed, or when the shared
  retrieval routines (mvn_pfp_file_retrieve, mvn_file_source) or the L0 dispatch
  in DPU/ change.
---

# MAVEN (IDL)

Code for MAVEN (Mars Atmosphere and Volatile EvolutioN). Each instrument team
wrote its own loaders, common blocks and conventions; there is no shared load
engine like THEMIS's `thm_load_xxx`. What the instruments share is file
retrieval, SPICE and orbit tools in `general/`.

## Layout

The first nine entries have their own AGENTS.md.

- `sta/`: STATIC ion mass spectrometer (`mvn_sta_l2_load`).
- `swea/`: SWEA electrons (`mvn_swe_load_l2`); also STATIC cold-ion code.
- `swia/`: SWIA solar wind ions (`mvn_swia_load_l2_data`).
- `sep/`: SEP energetic particles (`mvn_sep_load`); also the SSL batch job.
- `mag/`: magnetometer (`mvn_mag_load`).
- `lpw/`: Langmuir probe and waves (`mvn_lpw_load_l2`).
- `general/`: shared retrieval, SPICE, orbit numbers, geometry, `mvn_scpot`.
- `models/`: crustal magnetic field models and the pickup-ion model.
- `quicklook/`: summary page `mvn_ql_pfp_tplot`, KP reader, SSL overview plots.
- `euv/`: EUV monitor. `mvn_euv_load` reads L2 band irradiances into
  `mvn_euv_*`; `mvn_euv_l3_load` loads L3 (FISM) daily or minute spectra.
- `ngi/`: NGIMS. `mvn_ngi_load` reads L2 (or L1b, L3) CSV files into
  `mvn_ngi_<filetype>_<focusmode>_*` variables.
- `iuvs/`: no loader; `mvn_iuv_file_retrieve` only lists files under the SSL
  path `/disks/data/maven/data/sci/iuv/`.
- `acc/`: accelerometer L3 (`mvn_acc_load_l3`; needs SPICE).
- `kp/`: SSL-side KP maintenance; read KP files with `quicklook/mvn_qlook_load_kp.pro`.
- `eph/`: older ephemeris tools: `get_mvn_eph` (SPICE, common `mvn_eph_com`),
  `mvn_pfp_cotrans` (rotate SWIA/SWEA/STATIC angles), `mvn_phobos_tplot`.
- `maven_orbit_tplot/`: `maven_orbit_tplot` makes orbit and plasma-region tplot
  variables from save files in `maven/anc/spice/sav/`; `maven_orbit_snap` plots.
- `mvn_orb_ql/`: one-orbit geometry plot (`mvn_orb_ql/mvn_orb_ql_crib.pro`).
- `DPU/`: L0 decoding for the PFP data processing unit
  (`DPU/mvn_pfp_l0_file_read.pro`, `DPU/mvn_pfdpu_cmnblk_handler.pro`).
- `l2gen/`: SSL L2 production drivers (mostly SWEA) and cron scripts.
- `spedas_plugin/`: GUI plugin for KP data (`spedas_gui/plugins/maven_pfp_plugin.txt`).
- `misg/`, `obsolete/`, top-level `gseos_*` and `tek*`: prelaunch ground-test
  code; skip.
- Top level: `mvn_spc_met_to_unixtime.pro` (spacecraft clock to Unix time),
  `mvn_spc_apid_file_read.pro` (packet file reader), `mav_gse_structure_append.pro`
  (live despite its name: packet handlers append decoded data with it),
  `mvn_pf_make_cdf.pro` (generic PDS CDF writer), `morbit.pro` (Kepler orbits).

## How loading works

1. Set the range with `timespan` (loaders take `trange` or call `timerange()`),
   and load SPICE (`mvn_spice_load` or `mvn_swe_spice_init`) if needed.
2. A loader builds a pattern such as
   `maven/data/sci/<inst>/l2/YYYY/MM/mvn_<inst>_l2_<type>_YYYYMMDD_v??_r??.cdf` and
   calls `mvn_pfp_file_retrieve` (`general/mvn_pfp_file_retrieve.pro`), which
   downloads from `http://sprg.ssl.berkeley.edu/data/` into `root_data_dir()` and
   keeps the newest version (details in `general/AGENTS.md`).
3. The loader reads the files itself: CDFs into common blocks (SWEA, SWIA,
   STATIC), IDL save files (MAG, SEP L1), `cdf2tplot` (EUV, SEP L2), CSV (NGIMS).
4. L0 is one daily file of all PFP packets. `DPU/mvn_pfp_l0_file_read.pro` hands
   each packet to the MAG, SEP, STATIC and PFDPU handlers; SWEA, SWIA and LPW
   read the file with their own readers.

`swea/mvn_swe_crib.pro` walks through a full session.

## Things to know

- Names: `mvn_<inst>_` with sta, swe, swia (files `mvn_swi_`), sep, mag, lpw,
  euv, ngi, iuv, acc; `mvn_spc_` spacecraft, `mvn_pfp_`/`mvn_pfdpu_` the PFP
  suite and its DPU; `mav_` mostly prelaunch code. Some routines sit in another team's
  folder (`sep/mvn_lpw_handler.pro`, `swea/mvn_sta_coldion.pro`,
  `swea/mvn_mag_tplot.pro`); search by name. `projects/emm/` has `mvn_*` files too.
- No MAVEN system variable: download settings live in common
  `mvn_file_source_com` (`general/mvn_file_source.pro`). L0 and other team data
  need credentials from `MAVENPFP_USER_PASS` or `mvn_set_userpass`.
- SWEA, SWIA and STATIC load into common blocks and make tplot variables only on
  request; their 3D structures carry `units_procedure` for `conv_units`.
- Orbit numbers follow NAIF (increment at periapsis): `general/mvn_orbit_num.pro`.
- Skip `obsolete/` folders, `sta/L3_DO_NOT_USE/` (one routine there is still
  called; see `sta/AGENTS.md`), `models/pui/old/` and `*_spd_doc_list.html`.
  `sep/purgatory/` still holds live routines.
- Code with `/disks/data/` paths, `.sh` and `*_batch.pro` scripts runs only at SSL.
