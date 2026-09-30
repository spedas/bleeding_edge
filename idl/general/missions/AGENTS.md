---
related_files:
  - general/AGENTS.md
  - general/missions/fast/AGENTS.md
  - general/missions/rbsp/AGENTS.md
  - projects/AGENTS.md
  - projects/wind/AGENTS.md
  - projects/goes/AGENTS.md
  - projects/dscovr/AGENTS.md
  - general/missions/ISTP/omni_hro_load.pro
  - general/missions/ace/ace_init.pro
  - general/missions/ace/ace_mfi_load.pro
  - general/missions/ace/ace_swe_load.pro
  - general/missions/ace/ace_epm_load.pro
  - general/missions/ace/ace_mag_swepam_load.pro
  - general/missions/ace/noaa_ace_nrt_load.pro
  - general/missions/ace/spdf_file_source.pro
  - general/missions/goes/goes_mag_load.pro
  - general/missions/goes/goes_ep_load.pro
  - general/missions/kyoto/kyoto_load_ae.pro
  - general/missions/kyoto/kyoto_load_dst.pro
  - general/missions/kyoto/kyoto_ae_load.pro
  - general/missions/kyoto/kyoto_dst_load.pro
  - general/missions/kyoto/kyoto_crib_load_ae.pro
  - general/missions/lanl/lanl_mpa_load.pro
  - general/missions/lanl/lanl_spa_load.pro
  - general/missions/noaa/noaa_load_kp.pro
  - general/missions/stereo/stereo_init.pro
  - general/missions/stereo/st_mag_load.pro
  - general/missions/stereo/st_crib.pro
  - general/missions/wind/wind_init.pro
  - general/missions/wind/istp_init.pro
  - general/missions/wind/wi_mfi_load.pro
  - general/missions/wind/wi_swe_load.pro
  - general/missions/wind/wi_3dp_load.pro
  - general/missions/wind/wi_or_load.pro
  - general/missions/wind/wi_waves_load.pro
  - general/missions/wind/wi_crib.pro
  - general/missions/wind/waves/wi_tds_dustimpact_load.pro
  - projects/ace/spedas_plugin/ace_ui_import_data.pro
  - projects/fast/spedas_plugin/fast_ui_import_data.pro
  - projects/wind/spedas_plugin/wind_ui_import_data.pro
  - projects/geom_indices/spedas_plugin/idx_ui_import_data.pro
  - projects/omni/omni_load_data.pro
  - general/misc/file_retrieve.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/CDF/cdf2tplot.pro
maintenance: |
  Update when a mission folder is added here, removed, or moved to
  projects/, when a loader's system variable (!istp, !wind, !ace, !stereo)
  changes, or when a projects/ plugin starts calling different loaders here.
---

# general/missions/

Loaders for missions and indices that predate the `projects/` layout. Most
are single-file loaders of SPDF CDFs; FAST and RBSP are large and have their own
AGENTS.md.

## Folders

- `ISTP/`: only `ISTP/omni_hro_load.pro` (OMNI 1-min/5-min CDFs from SPDF via
  `!istp`). `istp_init` itself is in `wind/`. The newer OMNI loader is
  `projects/omni/omni_load_data.pro` (`!omni`).
- `ace/`: `ace/ace_mfi_load.pro`, `ace/ace_swe_load.pro`, `ace/ace_epm_load.pro`
  (SPDF via `!istp`); `ace/ace_mag_swepam_load.pro` and
  `ace/noaa_ace_nrt_load.pro` (NOAA real-time 1-minute text files via `!ace`,
  set by `ace/ace_init.pro`). `ace/spdf_file_source.pro` is a generic helper
  despite its location.
- `fast/`: FAST auroral satellite, about 600 files. See `fast/AGENTS.md`.
- `goes/`: `goes/goes_mag_load.pro` and `goes/goes_ep_load.pro`, SPDF
  key-parameter CDFs via `!istp`.
- `kyoto/`: Kyoto WDC geomagnetic indices. `kyoto/kyoto_load_ae.pro` and
  `kyoto/kyoto_load_dst.pro` are current (`spd_download`);
  `kyoto/kyoto_ae_load.pro` and `kyoto/kyoto_dst_load.pro` are older
  (`file_retrieve`). Cribs: `kyoto_crib_*.pro`.
- `lanl/`: `lanl/lanl_mpa_load.pro`, `lanl/lanl_spa_load.pro` (LANL
  geosynchronous plasma and particle data, SPDF via `!istp`).
- `noaa/`: `noaa/noaa_load_kp.pro` (Kp and Ap from NOAA NGDC).
- `rbsp/`: Van Allen Probes (EFW, EMFISIS, RBSPICE, ECT, state). See
  `rbsp/AGENTS.md`.
- `stereo/`: `stereo/stereo_init.pro` (`!stereo`) and `st_*_load` loaders
  (`stereo/st_mag_load.pro`, PLASTIC, SWEA, STE, SWAVES, position), crib
  `stereo/st_crib.pro`, and `analysis/`.
- `wind/`: `wind/wind_init.pro` (`!wind`), `wind/istp_init.pro` (`!istp`, used
  by all the SPDF loaders above), `wi_*_load` loaders (`wind/wi_mfi_load.pro`,
  `wind/wi_swe_load.pro`, `wind/wi_3dp_load.pro`, `wind/wi_or_load.pro`,
  `wind/wi_waves_load.pro`), crib `wind/wi_crib.pro`, and `waves/`
  (`wind/waves/wi_tds_dustimpact_load.pro` plus two generic `spd_*` helpers).

## Missions that also exist under projects/

- ACE: `projects/ace/` holds only the GUI plugin;
  `projects/ace/spedas_plugin/ace_ui_import_data.pro` calls `ace_mfi_load`
  and `ace_swe_load` from here.
- FAST: `projects/fast/` holds only the GUI plugin
  (`projects/fast/spedas_plugin/fast_ui_import_data.pro`), which calls the
  loaders in `fast/`.
- Wind: `projects/wind/` holds the GUI plugin
  (`projects/wind/spedas_plugin/wind_ui_import_data.pro`, calling the
  `wi_*_load` routines here) and the 3DP level-zero reader, which calls
  `wind_init` from here. See `projects/wind/AGENTS.md`.
- GOES: the two copies are independent. `projects/goes/` has the main
  loader `goes_load_data` (NCEI netCDF, `!goes`); the `goes/` loaders here read
  older SPDF CDFs. See `projects/goes/AGENTS.md`.

Code in `projects/` also calls loaders here: the geomagnetic-index GUI
plugin (`projects/geom_indices/spedas_plugin/idx_ui_import_data.pro`) calls
`kyoto_load_ae`, `kyoto_load_dst`, `noaa_load_kp` and `omni_hro_load`, and the
DSCOVR mission-compare tool calls the ACE and Wind loaders (see
`projects/dscovr/AGENTS.md`).

## Things to know

- The SPDF loaders share one pattern: `istp_init`, then per-day paths with
  `file_dailynames`, `spd_download` from `!istp.remote_data_dir`
  (`https://spdf.gsfc.nasa.gov/pub/data/`), and `cdf2tplot`
  (`general/CDF/cdf2tplot.pro`, not `spd_cdf2tplot`), with a
  `prefix` such as `wi_h0_mfi_` or `ace_k0_mfi_`.
- `!istp`, `!wind`, `!ace` and `!stereo` are `file_retrieve` structures
  (`general/misc/file_retrieve.pro`). Some older loaders here still
  download with `file_retrieve` rather than `spd_download`
  (`general/spedas_tools/spd_download/spd_download.pro`).
- Name overlap: `general/key_param/` has other, older ACE and Wind loaders
  (`load_wi_*`, `load_ace_*`) that are unrelated to these.
