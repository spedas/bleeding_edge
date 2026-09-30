---
related_files:
  - projects/AGENTS.md
  - projects/SPP/COMMON/AGENTS.md
  - projects/SPP/fields/AGENTS.md
  - projects/SPP/sweap/AGENTS.md
  - projects/SPP/COMMON/psp_fld_load.pro
  - projects/SPP/COMMON/spp_fld_load.pro
  - projects/SPP/COMMON/spp_file_retrieve.pro
  - projects/SPP/COMMON/spp_ccsds_pkt_handler.pro
  - projects/SPP/COMMON/spp_apid_data.pro
  - projects/SPP/COMMON/spice/spp_swp_spice.pro
  - projects/SPP/sweap/SPAN/electron/spp_swp_spe_load.pro
  - projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro
  - projects/SPP/sweap/SPC/spp_swp_spc_load.pro
  - projects/SPP/sweap/SPC/L3i/load/psp_load_swp.pro
  - projects/SPP/sweap/COMMON/spp_swp_load.pro
  - projects/SPP/sweap/COMMON/spp_swp_crib.pro
  - projects/SPP/isois/spp_isois_load.pro
  - projects/SPP/fields/crib/psp_fld_examples.pro
  - projects/SPP/sweap/BACKUP
  - projects/SPP/sweap/COMMON/obsolete
  - projects/SPP/sweap/SPAN/ion/DEPRECATED
  - projects/SPP/fields/l2/load/old
  - projects/swx
  - projects/SWFO
  - projects/escapade
maintenance: |
  Update when a PSP instrument loader is added, renamed or moved, when a
  subfolder gets or loses its own AGENTS.md, or when other projects stop (or
  start) reusing SPP routines and common blocks.
---

# Parker Solar Probe (SPP)

PSP code, in a folder named after the mission's pre-launch name, Solar Probe
Plus. It has loaders for FIELDS, SWEAP and ISOIS data, and the SWEAP and FIELDS
team tools: packet decommutation, sweep tables, flight configuration, CDF
production, and the SPP EVA burst-selection GUI.

## Layout

- `COMMON/`: shared code: the download wrapper `spp_file_retrieve`, the FIELDS
  entry points, the L0 packet framework, SPICE, SPP EVA. See `COMMON/AGENTS.md`.
- `fields/`: FIELDS L1 loaders, L2 helpers, utilities, cribs. See
  `fields/AGENTS.md`.
- `sweap/`: SWEAP (SPAN-e, SPAN-i, SPC, SWEM). See `sweap/AGENTS.md`.
- `isois/spp_isois_load.pro`: ISOIS L2 summary CDFs from the SWEAP team
  server (`data_private/` area) via `spp_file_retrieve`.
- `*_spd_doc_list.html`: generated documentation; skip.

## Entry points

| Data | Routine | File |
|---|---|---|
| FIELDS L2/L3 | `psp_fld_load, type=...` | `COMMON/psp_fld_load.pro` (wraps `COMMON/spp_fld_load.pro`) |
| SPAN-e | `spp_swp_spe_load` | `sweap/SPAN/electron/spp_swp_spe_load.pro` |
| SPAN-i | `spp_swp_spi_load` | `sweap/SPAN/ion/spp_swp_spi_load.pro` |
| SPC, team server | `spp_swp_spc_load` | `sweap/SPC/spp_swp_spc_load.pro` |
| SPC L3i, public (SPDF) | `psp_load_swp` | `sweap/SPC/L3i/load/psp_load_swp.pro` |
| Several at once | `spp_swp_load, /spe, /spi, /spc, /fld` | `sweap/COMMON/spp_swp_load.pro` |
| Ephemeris, attitude | `spp_swp_spice` | `COMMON/spice/spp_swp_spice.pro` |

The instrument loaders except `psp_load_swp` download from
`http://sprg.ssl.berkeley.edu/data/` through `spp_file_retrieve`. Cribs: `sweap/COMMON/spp_swp_crib.pro` and
`fields/crib/psp_fld_examples.pro`.

## Things to know

- Two prefixes. Most routines are `spp_`; newer public wrappers are `psp_`
  (`psp_fld_load` calls `spp_fld_load`, `psp_fld_timespan` calls
  `spp_fld_timespan`). tplot variables from CDFs are `psp_` (`psp_fld_l2_mag_RTN`,
  `psp_swp_spi_sf00_L3_DENS`, `psp_swp_spc_l3i_np_moment`), while packet
  decommutation makes `spp_` variables. Search for both.
- Folder names differ in case: `COMMON/` here and in `sweap/COMMON/`, but
  `fields/common/`, `sweap/SPAN/common/` and `sweap/decom/common/`.
- Settings are not in a `!` system variable: server and login sit in the
  `spp_file_source` common block (see `COMMON/AGENTS.md`). Exceptions:
  `!psp_sweap` (only for `psp_load_swp`) and `!SPP_FLD_TMLIB` (FIELDS L1).
- Local files mirror the server under `root_data_dir()`, e.g.
  `psp/data/sci/fields/l2/...` and `psp/data/sci/sweap/...`.
- Skip `sweap/BACKUP/`, `sweap/COMMON/obsolete/`, `sweap/SPAN/ion/DEPRECATED/`,
  `fields/l2/load/old/`, and `COMMON/spp_ccsds_pkt_handler.pro` and
  `COMMON/spp_apid_data.pro` (marked obsolete; they do not compile).
- Other projects reuse this code. `projects/swx/` and `projects/SWFO/`
  share the SPP common blocks and APID classes, and `projects/escapade/`
  calls `spp_swp_word_decom` and `spp_spc_met_to_unixtime`. A change to an
  `spp_` routine can break them.
- Quality flags differ by instrument: FIELDS `psp_fld_l2_quality_flags`
  (filter with `psp_fld_qf_filter`), SPAN `QUALITY_FLAG` (plotted by
  `spp_swp_qf`), SPC `DQF`.
