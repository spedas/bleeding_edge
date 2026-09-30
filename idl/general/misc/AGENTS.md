---
related_files:
  - general/AGENTS.md
  - general/misc/time/time_double.pro
  - general/misc/time/time_string.pro
  - general/misc/time/time_struct.pro
  - general/misc/time/TT2000/cdf_leap_second_init.pro
  - general/misc/file_dailynames.pro
  - general/misc/file_retrieve.pro
  - general/misc/file_http_copy.pro
  - general/misc/root_data_dir.pro
  - general/misc/spd_default_local_data_dir.pro
  - general/misc/str_element.pro
  - general/misc/strfilter.pro
  - general/misc/SSW/dprint.pro
  - general/misc/system/initct.pro
  - general/misc/system/wget/ssl_wget.pro
  - general/misc/popen.pro
  - general/misc/tinterpol.pro
  - general/misc/mso2lt.pro
  - projects/maven/general/mso2lt.pro
  - general/spedas_tools/spd_download/spd_download.pro
  - general/tools/tplot
  - general/cotrans/special/tinterpol_mxn.pro
maintenance: |
  Update when time conversion, file_dailynames, file_retrieve, root_data_dir or
  dprint change behavior or keywords, when a subfolder is added, or when
  routines move between misc/ and tools/.
---

# misc

Low-level utilities that the rest of SPEDAS depends on: time conversion,
structure and array helpers, file naming and downloading, debug printing,
color and plot-device setup, quaternions, and a first set of tplot-variable
tools.

## Layout

- `time/`: `time_double`, `time_string`, `time_struct`, `time_parse`,
  `time_epoch`, `time_pb5`. `time/TT2000/`: CDF TT2000 conversions and the
  leap-second table (`cdf_leap_second_init`). `time/deprecated/`: skip.
- `SSW/`: small routines copied from SolarSoft (`dprint`, `debug`,
  `undefine`, `tag_exist`, `is_struct`, ...).
- `system/`: color tables and devices (`initct`, `loadct2`, `line_colors`,
  `init_devices`), `CSV_Color_Tables/`, `libs` (prints where a routine's source
  is), `system/wget/ssl_wget.pro`.
- `quaternion/`: `qmult`, `qconj`, `qtom`, `mtoq`, `qslerp`, ...
- `math/` (`cosd`, `sind`, `sign`), `file_stuff/` (checksums, socket
  reader/recorder objects).
- Top level (~180 files): everything else, grouped below.

## Main groups

- Time: all SPEDAS times are double Unix seconds (`time_double`). Strings
  default to `YYYY-MM-DD/hh:mm:ss`; `time_string(t, tformat=...)` and
  `time_double(s, tformat=...)` share format tokens (`YYYY`, `MM`, `DD`, `DOY`,
  `hh`, `.fff`, ...), which `file_dailynames` and `file_retrieve` also use.
- File names: `file_dailynames(dir, prefix, suffix, trange=)` (`file_dailynames.pro`)
  returns one path per day (or per hour with `/hour_res`) covering `trange`.
- Downloading: `file_retrieve` (`file_retrieve.pro`) is the older downloader.
  It takes a source structure (`file_retrieve(/structure_format)`), expands
  date tokens in the path when `trange=` is given, and copies with
  `file_http_copy`. Newer loaders use `spd_download`
  (`general/spedas_tools/spd_download/spd_download.pro`); both are in wide
  use (IUGONET, RBSP, MAVEN, SPP still call `file_retrieve`).
- Local data root: `root_data_dir()` returns `$ROOT_DATA_DIR` if set, else
  `/disks/data/` if it exists, else `~/data/`. `spd_default_local_data_dir()`
  always returns `~/data/` and ignores the environment variable.
- Structures and arrays: `str_element` (get/add/delete a tag; nested names
  like `'options.trange'` work), `struct_value`, `extract_tags`,
  `append_array`, `minmax`, `dimen`/`ndimen`, `array_union`, and `strfilter`
  (the wildcard matcher behind `tnames`).
- Messages: `dprint, dlevel=n, ...` (`SSW/dprint.pro`) prints when `dlevel`
  is at or below the caller's `verbose=` or else the global level (default 2,
  or `$IDL_DEBUG`), set with `dprint, setdebug=n` and kept in `dprint_com`.
- tplot tools: `tinterpol`, `tdeflag`, `tdegap`, `tclip`, `time_clip`,
  `tsmooth_in_time`, `tdpwrspc`, `tsub_average`, `tkm2re`. More are in
  `general/tools/tplot`; `tinterpol_mxn` is in
  `general/cotrans/special/tinterpol_mxn.pro`.
- Output: `popen`/`pclose` (PostScript), `makepng`, `makegif`, `makejpg`.
- Space physics helpers: bow shock and magnetopause models (`bshock_2`,
  `mpause_2`, `mpause_t96`), `neutral_sheet`, `cart2spc`/`spc2cart`.

## Things to know

- Common blocks: `dprint_com`, `file_retrieve_com` (after a failed connection
  `file_retrieve` stops trying until `no_internet_until`), `root_data_dir_com`,
  `colors_com`, `popen_com`.
- TT2000 conversions need `!CDF_LEAP_SECONDS`, set by `cdf_leap_second_init`,
  which downloads `CDFLeapSeconds.txt` from https://cdf.gsfc.nasa.gov/html/
  into `root_data_dir()+'misc/'`.
- `initct` loads IDL tables (`loadct2`) below 1000 and CSV tables from
  `system/CSV_Color_Tables/` at 1000 and above; tplot's `color_table` option
  goes through it.
- Names are short and generic (`minmax`, `interp`, `box`, `win`, `ls`, `cwd`)
  and may clash with other libraries on `!PATH`. `mso2lt.pro` also exists in
  `projects/maven/general/mso2lt.pro`.
