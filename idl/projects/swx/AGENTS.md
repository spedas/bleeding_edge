---
related_files:
  - projects/AGENTS.md
  - projects/SWFO/AGENTS.md
  - projects/SPP/AGENTS.md
  - projects/swx/swx_test_crib.pro
  - projects/swx/swx_apdat_init.pro
  - projects/swx/swx_sst_apdat_init.pro
  - projects/swx/swx_apdat_info.pro
  - projects/swx/swx_apdat.pro
  - projects/swx/swx_ccsds_spkt_handler.pro
  - projects/swx/swx_ccsds_decom.pro
  - projects/swx/swx_ccsds_data.pro
  - projects/swx/swx_spc_met_to_unixtime.pro
  - projects/swx/swx_gen_apdat__define.pro
  - projects/swx/swx_gen_apdat_stats__define.pro
  - projects/swx/swx_swem_wrapper_apdat__define.pro
  - projects/swx/swx_swem_part_decompress_data.pro
  - projects/swx/swx_swem_events_strings.pro
  - projects/swx/swx_swem_events_apdat__define.pro
  - projects/swx/swx_init_realtime.pro
  - projects/swx/swx_spane_file_retrieve.pro
  - projects/SWFO/STIS/ptp_reader__define.pro
  - projects/SWFO/STIS/swfo_apdat_info.pro
  - projects/SWFO/STIS/swfo_stis_sci_apdat__define.pro
  - projects/SPP/COMMON/spp_apdat_info.pro
  - projects/SPP/COMMON/spp_file_source.pro
  - projects/SPP/COMMON/spp_ptp_recorder.pro
  - projects/SPP/sweap/SWEM/spp_swp_swem_events_strings.pro
  - projects/SPP/sweap/COMMON/spp_swp_data_select.pro
  - general/misc/generic_apdat__define.pro
  - general/misc/file_retrieve.pro
maintenance: |
  Update when the APID table in swx_apdat_init changes, when SWX stops
  sharing classes or the spp_apdat_info_com common block with SPP and SWFO,
  or when the packet path (ptp_reader, swx_ccsds_spkt_handler) changes.
---

# SWX

Ground-test (prelaunch) telemetry decoding for SWX: a SWEM electronics box
with a STIS/SST particle sensor and a SPAN-E electron analyzer. It turns
CCSDS packets from PTP files or GSE sockets into tplot variables. The code is
built from the PSP SWEAP and SWFO STIS packet libraries and reuses many of
their classes (see `projects/SPP/AGENTS.md`, `projects/SWFO/AGENTS.md`).

## Layout

All files are at the top level.

- Setup: `swx_apdat_init.pro` (the APID table), `swx_sst_apdat_init.pro` (an
  older copy with `swx_stis_*` tplot names), `swx_apdat_info.pro` (creates and
  manages the per-APID objects), `swx_apdat.pro` (looks one up).
- Packets: `swx_ccsds_spkt_handler.pro`, `swx_ccsds_decom.pro`,
  `swx_ccsds_data.pro`, `swx_spc_met_to_unixtime.pro`.
- Per-APID classes: `swx_gen_apdat__define.pro` (base, inherits
  `generic_apdat` from `general/misc/generic_apdat__define.pro`),
  `swx_gen_apdat_stats__define.pro` (APID 0, packet statistics), and
  `swx_swem_*_apdat__define.pro` for SWEM housekeeping, events, memory dumps,
  timing and wrapper packets.
- Files and real time: `swx_spane_file_retrieve.pro`, `swx_init_realtime.pro`.
- `swx_test_crib.pro`: the example.

## How a PTP file is decoded

1. `swx_test_crib.pro` calls `swx_apdat_init`, gets files with
   `file_retrieve` from `sprg.ssl.berkeley.edu`, and runs
   `ptp_reader(mission='SWX')` (`projects/SWFO/STIS/ptp_reader__define.pro`),
   which sets its decom procedure to the string `'swx_ccsds_spkt_handler'`.
2. `swx_ccsds_spkt_handler` calls `swx_ccsds_decom` to read the header, APID
   and MET, and converts MET with `swx_spc_met_to_unixtime` (epoch 2010-01-01
   minus 3 leap seconds; SPICE clock-drift correction is off by default).
3. `swx_apdat(apid)` returns the object that `swx_apdat_init` registered with
   `swx_apdat_info, apid, apid_obj='<class>', tname=...`; its `handler` method
   decodes the packet (`decom`), appends it to the tplot variable `tname` when
   `rt_flag` is set, and stores it when `save_flag` is set.
4. Wrapper packets (APIDs 0x348-0x34F, `swx_swem_wrapper_apdat`) decompress
   their content with `swx_swem_part_decompress_data` and pass the inner
   packet back to `swx_ccsds_spkt_handler`.
5. `swx_apdat_info, /finish` makes tplot variables from saved data;
   `/print, /all` lists the APIDs.

## Things to know

- APID ranges: SWEM 0x340-0x34F, STIS 0x350-0x35F, SPAN-A/B 0x360-0x37F, GSE
  0x7C0 and 0x7C4. STIS APIDs use SWFO classes (`swfo_stis_sci_apdat`, ...) and
  SPAN APIDs are registered through `spp_apdat_info` with SPP classes, so both
  `projects/SWFO/` and `projects/SPP/` must be on `!PATH`.
- `swx_apdat_info`, `spp_apdat_info` and `swfo_apdat_info` all use the common
  block `spp_apdat_info_com`: SWX, SPP and SWFO share one APID table in a
  session, and whichever init runs last owns each APID.
- `swx_apdat_init` and `swx_sst_apdat_init` share the flag in common
  `swx_stis_apdat_init`, so only the first call does anything unless `/reset`.
- Classes are created by name from strings (`obj_new(apid_obj)`); grep for the
  class name in quotes.
- `swx_swem_events_strings.pro` defines `spp_swp_swem_events_strings`, the same
  name as the SPP routine, which is what `swx_swem_events_apdat` calls.
- Local data use SPP paths: `swx_spane_file_retrieve` takes its source from
  `spp_file_source`, and `swx_init_realtime` records GSE streams under
  `root_data_dir()` + `spp/data/sci/sweap/prelaunch/` with `spp_ptp_recorder`.
