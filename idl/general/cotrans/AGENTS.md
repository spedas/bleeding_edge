---
related_files:
  - general/AGENTS.md
  - general/cotrans/cotrans.pro
  - general/cotrans/cotrans_lib.pro
  - general/cotrans/cotrans_get_coord.pro
  - general/cotrans/cotrans_set_coord.pro
  - general/cotrans/spd_set_coord.pro
  - general/cotrans/spd_cotrans_update_dlimits.pro
  - general/cotrans/spd_cotrans_update_limits.pro
  - general/cotrans/spd_cotrans_validate_transform.pro
  - general/cotrans/spd_helio_transform.pro
  - general/cotrans/gse2hee.pro
  - general/cotrans/gei2hae.pro
  - general/cotrans/gseq2heeq.pro
  - general/cotrans/gse2agsm.pro
  - general/cotrans/agsm2gse.pro
  - general/cotrans/spg2ssl.pro
  - general/cotrans/epv00/spd_epv00.pro
  - general/cotrans/epv00/LICENSE.txt
  - general/cotrans/special/tvector_rotate.pro
  - general/cotrans/special/tinterpol_mxn.pro
  - general/cotrans/special/fac/fac_matrix_make.pro
  - general/cotrans/special/minvar/minvar_matrix_make.pro
  - general/cotrans/lmn_transform/gsm2lmn.pro
  - general/cotrans/aacgm/README.txt
  - general/cotrans/tests
  - spedas_gui/utilities/cotrans/spd_cotrans.pro
  - projects/themis/state/cotrans/thm_cotrans.pro
  - projects/mms/common/cotrans/mms_cotrans.pro
  - projects/mms/common/cotrans/mms_qcotrans.pro
maintenance: |
  Update when cotrans gains or loses a transformation keyword, when the
  data_att.coord_sys convention changes, when the heliocentric or special
  routines are added or moved, or when spd_cotrans moves out of spedas_gui.
---

# cotrans

Geophysical and heliocentric coordinate transformations of tplot vectors,
plus rotation-matrix tools (field-aligned, minimum variance, LMN) that apply
to any mission.

## Layout

- `cotrans.pro`: the single-step transformer. `cotrans_lib.pro` holds the
  math (`sub_GSE2GSM`, `subGEI2GSE`, `cdipdir_vect`, ...).
- `cotrans_get_coord.pro` / `cotrans_set_coord.pro`: read and write
  `dlimits.data_att.coord_sys`. `spd_set_coord.pro` sets it on tplot names.
- `spd_cotrans_update_dlimits.pro`, `spd_cotrans_update_limits.pro`: replace
  the coordinate name inside `ytitle`/labels after a transform.
- Heliocentric: `gse2hee.pro`, `gei2hae.pro`, `gseq2heeq.pro`, all thin
  wrappers of `spd_helio_transform.pro`, which uses `epv00/spd_epv00.pro`
  (Earth ephemeris ported from ERFA `eraEpv00`; see `epv00/LICENSE.txt`).
- Others: `gse2agsm.pro`/`agsm2gse.pro` (aberrated GSM), `geo2mag`/`mag2geo`,
  `hdz2geo`, `sm2mlt`/`tgsm2mlt`, `spg2ssl.pro` (THEMIS spin frames).
- `special/`: `tvector_rotate.pro` (apply per-sample matrices to a tplot
  vector), `tinterpol_mxn.pro` (interpolate one tplot variable onto another's
  times), `tdotp`, `tcrossp`, `tnormalize`, `ttensor_rotate`, and matrix
  builders `fac/fac_matrix_make.pro`, `minvar/minvar_matrix_make.pro`,
  `rxy/`, `sse/`, `enp/`.
- `lmn_transform/`: `gsm2lmn.pro` (boundary-normal LMN via a magnetopause model).
- `aacgm/`: pure-IDL AACGM magnetic coordinates with coefficient files
  (`aacgm/README.txt`); ELFIN and SECS plots use it.
- `tests/`: heliocentric and `spd_epv00` checks.

## How `cotrans` works

`cotrans, in_name, out_name, /gse2gsm` (or `cotrans, y, out, times, /...`
for plain arrays) does exactly one hop per call. Keywords: `/gei2gse`,
`/gse2gei`, `/gse2gsm`, `/gsm2gse`, `/gsm2sm`, `/sm2gsm`, `/gei2geo`,
`/geo2gei`, `/geo2mag`, `/mag2geo`, `/gei2j2000`, `/j20002gei`, `/gse2gseq`,
`/gseq2gse`. It calls `cotrans_lib` first (compiles the library and sets
`!cotrans_lib`), checks that `coord_sys` matches the source system (or is
`'unknown'`), converts `y` to float if needed, then stores the result with
`coord_sys` set to the target and `ytitle` removed.

For multi-hop transforms use `spd_cotrans, name, in_coord=, out_coord=`
(`spedas_gui/utilities/cotrans/spd_cotrans.pro`). It walks the graph
HEE-GSE-GEI-GEO-MAG, GSE-GSM-SM, GSE-GSEQ-HEEQ, GEI-HAE, GEI-J2000 (and GSE to
aGSM) by calling `cotrans` and the wrappers above recursively. Mission
wrappers add spacecraft frames on top: `thm_cotrans`
(`projects/themis/state/cotrans/thm_cotrans.pro`, SPG/SSL/DSL),
`mms_cotrans` and `mms_qcotrans` (`projects/mms/common/cotrans/`).

## Things to know

- Coordinate system names are lower case strings in
  `dlimits.data_att.coord_sys` (`gse`, `gsm`, `sm`, `gei`, `geo`, `mag`,
  `j2000`, `gseq`, `hee`, `hae`, `heeq`, `agsm`). Loaders set it
  (`spd_cdf2tplot` does from the CDF `COORDINATE_SYSTEM` attribute); if it
  is missing `cotrans` accepts any input. `/ignore_dlimits` skips the check.
- GEI here is true of date (TOD); J2000 is the separate `j2000` system.
- `y` must be N x 3; units are unchanged. `spd_cotrans_validate_transform`
  warns when data with `data_att.st_type = 'vel'` crosses between rotating and
  inertial frames.
- GSM/SM/MAG use an IGRF dipole axis (`cdipdir` in `cotrans_lib.pro`),
  computed for 1965-2030; other years are clamped with a warning. The
  `cotrans_lib, /nolimit_igrf` switch is reset by every `cotrans` call, which
  runs `cotrans_lib` without keywords.
- `tvector_rotate` interpolates the matrices to the data times by quaternion
  slerp when the time grids differ; matrices from `fac_matrix_make`/`minvar_matrix_make` are only valid for data
  in the coordinate system they were built from.
