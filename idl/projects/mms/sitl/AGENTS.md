---
related_files:
  - projects/mms/AGENTS.md
  - projects/mms/sitl/eva/eva.pro
  - projects/mms/sitl/eva/parameterSets
  - projects/mms/sitl/eva/source/cw_data/eva_data.pro
  - projects/mms/sitl/eva/source/cw_data/eva_data_load_mms.pro
  - projects/mms/sitl/eva/source/cw_sitl/eva_sitl.pro
  - projects/mms/sitl/eva/source/cw_sitl/eva_sitl_com.pro
  - projects/mms/sitl/eva/source/cw_sitl/eva_sitl_submit_fomstr.pro
  - projects/mms/sitl/eva/source/cw_sitluplink/eva_sitluplink.pro
  - projects/mms/sitl/eva/source/cw_sitlsubmit/eva_sitlsubmit.pro
  - projects/mms/sitl/eva/source/eva_config_filedir.pro
  - projects/mms/sitl/eva/source/utility/programrootdir.pro
  - projects/mms/sitl/eva/source/script/eva_script_guide.pdf
  - projects/mms/sitl/interface/mms_put_fom_structure.pro
  - projects/mms/sitl/interface/mms_check_fom_structure.pro
  - projects/mms/sitl/interface/mms_get_back_structure.pro
  - projects/mms/sitl/interface/mms_submit_back_structure.pro
  - projects/mms/sitl/interface/mms_convert_fom_tai2unix.pro
  - projects/mms/sitl/interface/mms_get_abs_fom_files.pro
  - projects/mms/sitl/interface/mms_burst_fom.pro
  - projects/mms/sitl/bss/mms_load_bss.pro
  - projects/mms/sitl/bss/core/mms_bss_load.pro
  - projects/mms/sitl/bss/core/mms_bss_query.pro
  - projects/mms/sitl/sitl_data_fetch/mms_sitl_get_dfg.pro
  - projects/mms/sitl/sitl_data_fetch/new_sitl_fetch_crib.pro
  - projects/mms/sitl/model_boundary/model_boundary_crib.pro
  - projects/mms/sitl/sitl_quick.pro
  - projects/mms/sitl/fpi_quick.pro
  - projects/mms/sdc/submit_mms_sitl_selections.pro
  - projects/mms/sdc/get_mms_sitl_connection.pro
  - projects/mms/sdc/mms_sitl_login.pro
  - projects/mms/common/mms_data_fetch/mms_data_fetch.pro
  - projects/mms/common/mms_data_fetch/mms_check_local_cache.pro
  - projects/mms/common/load_data/mms_load_data.pro
  - projects/mms/common/data_status_bar/spd_mms_load_bss.pro
  - projects/mms/common/AGENTS.md
  - projects/mms/feeps/sun
  - projects/mms/sitl/interface/mms_convert_fom_unix2tai.pro
  - projects/mms/sitl/interface/get_latest_fom_from_soc.pro
  - projects/themis/common/thm_init.pro
maintenance: |
  Update when EVA's modules or parameter sets move, when the FOM, ABS, GLS or
  back-structure submission path to the SDC changes, or when the SITL data
  loaders switch fetch routines.
---

# MMS SITL tools (IDL)

Tools for the MMS Scientist-in-the-Loop (SITL): choosing which burst data to
downlink by editing figure-of-merit (FOM) selections and submitting them to
the SDC. The main program is the EVA widget GUI. Most of this needs MMS team
SDC credentials. Burst segment status (`bss/`) is also used by
`projects/mms/common/`.

## Layout

- `eva/`: EVA. `eva/eva.pro` builds the window from modules in `eva/source/`:
  `cw_data/` (loads and plots MMS and THEMIS data; `eva_data.pro`,
  `eva_data_load_mms.pro`), `cw_sitl/` (FOM editing, validation, submission),
  `cw_sitluplink/`, `cw_sitlsubmit/`. `eva/parameterSets/*.txt` define the plot
  panel sets; `eva/source/script/` holds command-line tools and
  `eva_script_guide.pdf`; `eva/data/` has demo save files.
- `interface/`: FOM, ABS (automated burst selection), GLS (ground loop
  selection) and back-structure (burst segment status table) access:
  `mms_get_abs_fom_files.pro`, `mms_get_back_structure.pro`,
  `mms_check_fom_structure.pro` (limits before submission),
  `mms_put_fom_structure.pro`, `mms_submit_back_structure.pro`,
  `mms_burst_fom.pro`, TAI/Unix time conversion.
- `bss/`: burst segment status. `bss/core/mms_bss_load.pro` returns the
  back-structure for a time range, `bss/core/mms_bss_query.pro` filters it,
  and `bss/mms_load_bss.pro` makes the `mms_bss_*` tplot bars.
- `sitl_data_fetch/`: `mms_sitl_get_*` loaders for QL/SITL products
  (e.g. `mms_sitl_get_dfg.pro`), plus `new_sitl_*_crib.pro` examples.
- `model_boundary/`: magnetopause and bow shock models used by EVA.
- `sitl_quick.pro`, `fpi_quick.pro`: emergency scripts to edit or submit
  selections when EVA is not working.

## How a selection reaches the SDC

1. EVA loads the latest ABS/FOM selections (`get_latest_fom_from_soc`,
   `mms_get_abs_fom_files`) and the data panels; the SITL edits segments in
   `cw_sitl`, which works in Unix time.
2. `eva_sitl_submit_fomstr` converts the FOM to TAI
   (`mms_convert_fom_unix2tai`) and calls `mms_put_fom_structure`, which
   checks it with `mms_check_fom_structure` and saves it to a local file.
3. `mms_put_fom_structure` then calls `submit_mms_sitl_selections`
   (`projects/mms/sdc/submit_mms_sitl_selections.pro`), which uploads the
   file over `get_mms_sitl_connection`. `mms_submit_back_structure` does the
   same for back-structure edits.

## Things to know

- Login: `get_mms_sitl_connection` (`projects/mms/sdc/get_mms_sitl_connection.pro`)
  asks for credentials through `mms_sitl_login` (`~/.mms_sitl_login.sav`, a
  widget, or the command line) and validates them. It shares the common block
  `mms_sitl_connection` with the science loaders
  (`projects/mms/common/AGENTS.md`), so
  one login serves both for 24 hours.
- SITL loaders mostly use the older `mms_data_fetch` and
  `mms_check_local_cache` (`projects/mms/common/mms_data_fetch/`); some
  call `mms_load_data`. Files go to `!mms.local_data_dir`.
- EVA runs `thm_init` and `mms_init`, and uses common blocks
  `eva_sitl_com` (`eva/source/cw_sitl/eva_sitl_com.pro`), `eva_ctime_common` and
  `eva_tictoc`. Preferences live in `app_user_dir('eva', ...)`
  (`eva/source/eva_config_filedir.pro`).
- EVA finds `parameterSets/` relative to its own source with `ProgramRootDir`
  (`eva/source/utility/programrootdir.pro`), so keep the folder layout intact.
- FOM structures exchanged with the SDC use TAI times; convert with
  `interface/mms_convert_fom_tai2unix.pro` and `mms_convert_fom_unix2tai`.
- The `*.csv` FEEPS sector files in `sitl_data_fetch/` are not read by code;
  the FEEPS loader uses its own copies under `projects/mms/feeps/sun/`.
- `projects/mms/common/data_status_bar/spd_mms_load_bss.pro` depends on
  `bss/`, so changes there affect regular users too.
