---
related_files:
  - AGENTS.md
  - external/IDL_GEOPACK/README.txt
  - external/IDL_GEOPACK/igp_test.pro
  - external/IDL_GEOPACK/ts07/ts07_download.pro
  - external/IDL_GEOPACK/ta16/ta16_setpath.pro
  - external/IDL_GEOPACK/ta16/TA16_RBF.par
  - external/IDL_ICY/README.txt
  - external/IDL_ICY/icy_test.pro
  - external/aacgm_v2/README.txt
  - external/aacgm_v2/aacgmidl_v2.pro
  - external/astron/fits/mrdfits.pro
  - external/das2pro/README.md
  - external/developers/solarwind/solarwind_load.pro
  - external/misc/savetomain.pro
  - external/spdfcdas/spedas_spdf_readme.txt
  - external/spdfcdas/spd_cdawlib/spd_cdawlib_readme.txt
  - external/spdfssc/spdfgetlocations.pro
  - spedas_gui/panels/spd_ui_field_models.pro
  - spedas_gui/panels/spd_ui_spdfcdawebchooser.pro
  - general/spice/spice_test.pro
  - general/misc/neutral_sheet.pro
  - general/cotrans/aacgm/aacgmidl.pro
  - general/cotrans/lmn_transform/gsm2lmn_wrap.pro
  - projects/mms/common/cotrans/mms_cotrans_lmn.pro
  - projects/cassini/das2dlm_cassini_init.pro
  - projects/iugonet/load/iug_load_smart.pro
  - projects/goes/goes_load_pos.pro
maintenance: |
  Update when a library is added to, removed from or upgraded in external/,
  or when the SPEDAS routines that call into it change.
---

# External libraries

Third-party IDL code that SPEDAS ships, plus SPEDAS wrappers for libraries that
must be installed separately as IDL DLMs (compiled modules). Treat it as
vendored: don't edit it, and send fixes to the library's authors or upstream
SPEDAS.

## Layout

- `IDL_GEOPACK/`: SPEDAS wrappers for Haje Korth's IDL Geopack DLM (Tsyganenko
  field models). `t89/`, `t96/`, `t01/`, `t04s/`, `ts07/`, `ta15/`, `ta16/` each
  hold a model function (`t89`) and a tplot wrapper (`tt89`); `trace/` has
  `trace2iono`/`trace2equator` and their tplot versions. The DLM itself is not in
  the repository; `IDL_GEOPACK/README.txt` explains how to install it.
- `IDL_ICY/`: only `IDL_ICY/icy_test.pro` and install notes for NAIF's ICY
  (SPICE) DLM. The SPICE wrappers are in `general/spice/`.
- `aacgm_v2/`: AACGM-v2 magnetic coordinates (S. G. Shepherd), pure IDL, with its
  coefficient files. The older AACGM v1 used by most callers is a separate copy,
  `general/cotrans/aacgm/aacgmidl.pro`.
- `astron/`: FITS readers and writers from the IDL Astronomy Library
  (`astron/fits/mrdfits.pro`, `readfits`, `sxpar`, `fxb*`).
- `das2dlm/`: SPEDAS helpers (`das2dlm_*`) around the das2 DLM, whose `das2c_*`
  functions must be installed separately.
- `das2pro/`: pure-IDL das2 client (MIT license, `das2pro/README.md`). No SPEDAS
  routine calls it.
- `developers/`: routines contributed outside the core team: `solarwind/`
  (`solarwind_load`, OMNI/Wind solar wind shifted to the bow shock) and
  `outliers_and_convolution/`.
- `misc/savetomain.pro`: Coyote library debugging helper.
- `spdfcdas/`: NASA SPDF CDAS web-services client (`Spdf*` classes, NOSA
  license) and `spdfcdas/spd_cdawlib/`, a renamed fork of CDAWlib. The local
  changes are listed in `spdfcdas/spedas_spdf_readme.txt` and
  `spdfcdas/spd_cdawlib/spd_cdawlib_readme.txt`.
- `spdfssc/`: NASA SPDF Satellite Situation Center web-services client.

## Who calls what

- Geopack: `igp_test` (`IDL_GEOPACK/igp_test.pro`) checks that the DLM is
  installed before each model runs. Callers include the GUI field-model panel
  (`spedas_gui/panels/spd_ui_field_models.pro`), ELFIN and RBSP code, and
  `general/misc/neutral_sheet.pro`, which calls `geopack_recalc` directly.
- ICY: `spice_test` (`general/spice/spice_test.pro`) checks the DLM; the
  `cspice_*` calls are in `general/spice/`, MAVEN and RBSP code.
- AACGM-v2: call `aacgmidl_v2` first; it sets the `AACGM_v2_DAT_PREFIX` and
  `IGRF_COEFFS` environment variables to the bundled files and compiles the
  library. Only an ELFIN crib sheet uses it; ELFIN and SECS plots use the v1
  copy, and ERG SuperDARN has its own AACGM code in
  `projects/erg/ground/radar/superdarn/sdaacgmlib/`.
- FITS: IUGONET loaders (e.g. `projects/iugonet/load/iug_load_smart.pro`)
  and EMM EMUS code.
- das2dlm: the Cassini loaders (`projects/cassini/das2dlm_cassini_init.pro`
  and the other `das2dlm_load_cassini_*`).
- `solarwind_load`: the LMN transforms,
  `general/cotrans/lmn_transform/gsm2lmn_wrap.pro` and
  `projects/mms/common/cotrans/mms_cotrans_lmn.pro`.
- CDAS and CDAWlib: the GUI's CDAWeb loader,
  `spedas_gui/panels/spd_ui_spdfcdawebchooser.pro`.
- SSC: `projects/goes/goes_load_pos.pro` calls `spdfgetlocations`
  (`spdfssc/spdfgetlocations.pro`).

## Things to know

- TS07 and TA16 need parameter files: `IDL_GEOPACK/ts07/ts07_download.pro`
  fetches TS07 files into `!spedas.geopack_param_dir`, and
  `IDL_GEOPACK/ta16/ta16_setpath.pro` points the DLM at the bundled
  `TA16_RBF.par`.
- `astron/`, `spdfcdas/` and `spdfssc/` define common names (`readfits`,
  `sxpar`, `Spdf*` classes); check `!PATH` order before adding a routine with
  the same name elsewhere.
