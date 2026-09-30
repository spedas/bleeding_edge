---
related_files:
  - general/AGENTS.md
  - general/tplot/tplot_com.pro
  - general/tplot/tplot_quant__define.pro
  - general/tplot/store_data.pro
  - general/tplot/get_data.pro
  - general/tplot/find_handle.pro
  - general/tplot/tnames.pro
  - general/tplot/options.pro
  - general/tplot/tplot.pro
  - general/tplot/tplot_options.pro
  - general/tplot/timespan.pro
  - general/tplot/timerange.pro
  - general/tplot/mplot.pro
  - general/tplot/specplot.pro
  - general/tplot/tplot_save.pro
  - general/tplot/tplot_restore.pro
  - general/tplot/_tplot_example.pro
  - general/tplot/_get_example_dat.pro
  - general/tplot/tplot_file.pro
  - general/tplot/makefile
  - general/misc/time/time_double.pro
  - general/tools/misc/dynamicarray__define.pro
  - general/tplot/help.html
  - general/tplot/3dp_ref_man.html
  - general/misc/str_element.pro
  - general/qa_tools/mgunit/tplot_ut__define.pro
maintenance: |
  Update when the tplot_com1 common block, the {tplot_quant} record or the
  dtype codes change, when store_data/get_data/tnames/options/tplot change
  keywords or semantics, or when plotting routines are added or renamed here.
---

# tplot

The tplot system: in-memory storage of named time series ("tplot variables"),
their plot options, and the routines that plot them. Almost every SPEDAS
loader ends by calling `store_data`, and almost every analysis routine starts
with `get_data`.

## Layout

- Storage: `store_data.pro`, `get_data.pro`, `find_handle.pro`, `tnames.pro`,
  plus `copy_data`, `del_data`, `tplot_rename`, `split_vec`, `join_vec`,
  `tplot_sort`, `tplot_force_monotonic`.
- Options: `options.pro` (per variable), `tplot_options.pro` (global),
  `xlim`/`ylim`/`zlim`/`tlimit`.
- Time range: `timespan.pro` sets it, `timerange.pro` and `get_timespan` read it.
- Plotting: `tplot.pro`, which calls `mplot.pro` (lines) or `specplot.pro`
  (spectrograms); also `bitplot`, `strplot`, `pmplot`, `tplotxy`, `tplot3d`,
  `tplot_multiaxis`. Cursor tools: `ctime`, `tzoom`, `timebar`, `crosshairs`.
- Files: `tplot_save.pro` / `tplot_restore.pro` write and read IDL save files
  with a `.tplot` suffix. `tplot_file.pro` is the obsolete predecessor.
- `_tplot_example.pro` (crib sheet), `_get_example_dat.pro` (fake data).
  `makefile`, `help.html`, `3dp_ref_man.html`: 1990s Wind/3DP leftovers.

## How storage works

- `tplot_com.pro` declares `common tplot_com1, data_quants, tplot_vars, ...`.
  Routines include it with `@tplot_com` (or `@tplot_com.pro`).
- `data_quants` is an array of `{tplot_quant}` (`tplot_quant__define.pro`):
  `name`, pointers `dh` (data), `lh` (limits), `dl` (dlimits), `trange`,
  `dtype`, `create_time`. Element 0 is a dummy: `find_handle` returns 0 for
  "not found", so real variables start at index 1.
- `store_data, name, data={x:times, y:values [, v:bins]}, dlimits=, limits=`.
  Each data tag is stored as its own pointer. `x` is double Unix seconds; the
  first dimension of `y` must equal `n_elements(x)` (a mismatch only warns).
  `/delete`, `newname=`, `/append` and `tagnames=` (split an array of
  structures into several variables) are handled in the same routine.
- `dtype`: 1 = normal x/y; 2 = obsolete array of structures; 3 = pseudo
  variable (data is a list of other tplot names, overplotted in one panel);
  4 = a `dynamicarray` object (`general/tools/misc/dynamicarray__define.pro`),
  used by SPP and SWFO packet-decommutation code.
- `get_data, name, t, y, v` or `get_data, name, data=d, dlimits=dl, limits=l,
  alimits=al`. The real keywords are `data_str`, `dlimits_str`, ...; the short
  forms work by IDL keyword abbreviation. `alimits` merges dlimits then
  limits. A missing variable returns 0 (or `!null` with `/null`), not an
  error; test with `tnames(name)` or `index=`.
- `tnames(pattern, n)` returns matching names (`*`/`?` wildcards; a
  space-separated string is several patterns) and `''` when nothing matches.

## How `tplot` works

`tplot, names` resolves names with `tnames`, stores the panel list and time
range in `tplot_vars`, then for each panel merges dlimits and limits and calls
the plot routine with `call_procedure`: `specplot` if the `spec` option is
set, else `mplot`, unless the variable sets `tplot_routine` (e.g. `'bitplot'`,
`'strplot'`, `'pmplot'`, or a mission routine). Pseudo variables (dtype 3)
loop over their components with overplot.

## Things to know

- `limits` (set by `options`) survive reloads; `dlimits` are overwritten by
  each `store_data` from a loader. `options, name, /default` edits dlimits.
  `options` accepts wildcards, so `options, '*', ...` changes every variable.
- Names may not contain spaces or `* ? [ ] \`; `store_data` replaces them
  with `$`.
- `timerange()` with no argument and no `timespan` set calls `timespan`, which
  prompts on stdin. Loaders call `timerange(trange)`, so pass `trange=` or run
  `timespan` first in batch scripts.
- Helpers live in `general/misc/`: `time_double`
  (`general/misc/time/time_double.pro`) and `str_element`
  (`general/misc/str_element.pro`), which edits option structures.
- Tests: `general/qa_tools/mgunit/tplot_ut__define.pro`.
