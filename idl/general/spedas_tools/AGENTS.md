---
related_files:
  - general/AGENTS.md
  - general/spedas_tools/README.txt
  - general/spedas_tools/spd_download/spd_download.pro
  - general/spedas_tools/spd_download/spd_download_file.pro
  - general/spedas_tools/spd_download/spd_download_expand.pro
  - general/spedas_tools/spd_download/spd_download_extract.pro
  - general/spedas_tools/spd_download/spd_download_plus.pro
  - general/spedas_tools/spd_download/spd_download_handler.pro
  - general/spedas_tools/spd_download/spd_copy_file.pro
  - general/spedas_tools/spd_download/spd_get_proxy.pro
  - general/spedas_tools/spd_download/spd_cdf_check_delete.pro
  - general/spedas_tools/hapi/hapi_load_data.pro
  - general/spedas_tools/hapi/hapi_load_data_ut__define.pro
  - general/spedas_tools/flipbookify/spd_flipbookify.pro
  - general/spedas_tools/python_validation/spd_run_py_validation.pro
  - general/spedas_tools/python_validation/general_validation_ut__define.pro
  - general/spedas_tools/tplot2ap/tplot2ap.pro
  - general/spedas_tools/tplot2ap/ap2tplot.pro
  - general/spedas_tools/tplot2ap/crib_tplot2ap.pro
  - general/spedas_tools/spd_extract_tvar_metadata.pro
  - general/spedas_tools/spd_read_current_version.pro
  - general/misc/file_retrieve.pro
  - general/CDF/spd_cdf2tplot.pro
  - general/CDF/tplot2cdf.pro
  - general/CDF/tplot_add_cdf_structure.pro
  - general/science/spd_slice2d/spd_slice2d.pro
  - spedas_gui/utilities/spd_addslash.pro
maintenance: |
  Update when spd_download's keywords, return value or helper chain change, when
  a subfolder is added, or when hapi_load_data or tplot2ap change how they fetch
  data or name tplot variables.
---

# SPEDAS tools

Self-contained tools shared by all missions, above all the downloader
`spd_download`. `README.txt` asks that code here run with only `general/`
on the path and that changes get QA testing, since much code depends on it.

## Layout

- `spd_download/`: `spd_download` and its helpers (below).
- `hapi/`: `hapi_load_data` (`hapi/hapi_load_data.pro`), a HAPI client that
  stores parameters as tplot variables; test `hapi/hapi_load_data_ut__define.pro`.
- `flipbookify/`: `spd_flipbookify` (`flipbookify/spd_flipbookify.pro`) steps
  through the current tplot window's times, adding three `spd_slice2d` slices
  per frame (PNG, PostScript or `/video`). THEMIS and MMS wrap it.
- `tplot2ap/`: `tplot2ap` and `ap2tplot` exchange variables with Autoplot's
  server (port 12345) through temporary CDFs (`tplot2cdf`, `spd_cdf2tplot`).
  Crib: `tplot2ap/crib_tplot2ap.pro`.
- `python_validation/`: `spd_run_py_validation`
  (`python_validation/spd_run_py_validation.pro`) writes a Python script, runs it
  with `spawn`, and compares its tplot variables with those loaded in IDL;
  mgunit tests such as `python_validation/general_validation_ut__define.pro`.
- Top level: `spd_extract_tvar_metadata` (titles and units from limits, dlimits,
  then CDF attributes; used by `tplot2ap` and `tplot_add_cdf_structure`),
  `spd_get_color`, `spd_get_sym`, `spd_get_spectra_units`, and
  `spd_read_current_version`, which reads the revision from the top-level
  svn_version_info.txt. The build of the bleeding-edge zip writes that file;
  an SVN working copy has none, and there the function returns -1.

## How spd_download works

`paths = spd_download(remote_file=..., remote_path=..., local_path=...)`
(`spd_download/spd_download.pro`):

1. URLs are `remote_path + remote_file`, local files `local_path + local_file`.
   `local_file` defaults to `remote_file` minus `remote_path`, or to the bare
   file name when `remote_path` is empty.
2. Wildcards (`*`, `?`, `[ ]`) in the file name are expanded by
   `spd_download_expand`, which reads the directory's HTML index through
   `spd_download_extract`. `/last_version` keeps the lexically last match;
   `/no_wildcards` skips expansion.
3. `http(s)://` and `ftp(s)://` URLs go to `spd_download_file`; anything else
   is treated as a local path and copied by `spd_copy_file`.
4. `spd_download_file` uses an `IDLnetURL` object. For an existing file it sends
   `If-Modified-Since` (none with `/no_update`, which returns the local file,
   or `/force_download`). It downloads to a temporary name, rejects HTML saved as
   `.cdf`/`.nc`, and deletes files `spd_cdf_check_delete` cannot open (unless
   `/disable_cdfcheck`). `spd_download_handler` reports HTTP errors.
5. Files that did not download are searched for locally, so `/no_download`
   works offline.

## Things to know

- Without `/valid_only`, the result includes paths to files that do not exist
  (kept for `file_retrieve` compatibility). Pass it or check with `file_test`.
- Credentials and other `IDLnetURL` properties (`url_username`, `url_password`,
  `headers`, proxy settings) pass through `_extra`; `spd_get_proxy` reads the
  `http_proxy` environment variable. SSL peer and host checks are off by default.
- The old keywords `local_data_dir`, `remote_data_dir`, `no_server` and
  `no_clobber` are mapped to the new ones. `file_retrieve`
  (`general/misc/file_retrieve.pro`) is the older downloader and expands
  `YYYY`/`MM`/`DD` patterns from `trange` itself; `spd_download` needs full
  paths, usually built with `file_dailynames`.
- `spd_download_plus` wraps `spd_download`; when that returns nothing or a path
  still holding a wildcard, it searches `local_path` for the remote file name.
- `hapi_load_data` calls `IDLnetURL` directly, not `spd_download`. It saves CSV
  under `local_data_dir` (default `hapi/`, relative to the current directory),
  names variables `prefix + lowercase(parameter) + suffix`, and needs IDL 8.3+.
- Despite `README.txt`, `hapi_load_data` and `spd_run_py_validation` call
  `spd_addslash` (`spedas_gui/utilities/spd_addslash.pro`), and
  `spd_flipbookify` needs `spd_slice2d`
  (`general/science/spd_slice2d/spd_slice2d.pro`).
