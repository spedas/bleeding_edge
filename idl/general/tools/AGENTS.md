---
related_files:
  - general/AGENTS.md
  - general/tools/fitting/fit.pro
  - general/tools/fitting/fit_crib.pro
  - general/tools/fitting/gaussian.pro
  - general/tools/misc/dynamicarray__define.pro
  - general/tools/tplot/add_data.pro
  - general/tools/tplot/dif_data.pro
  - general/tools/tplot/mult_data.pro
  - general/tools/tplot/div_data.pro
  - general/tools/tplot/avg_data.pro
  - general/tools/tplot/deriv_data.pro
  - general/tools/tplot/wvlt/wav_data.pro
  - general/tools/tplot/wvlt/wavelet.pro
  - general/tools/tplot/xtplot/xtplot.pro
  - general/tools/tplot/xtplot/xtplot_com.pro
  - general/tools/tplot/xtplot/xtplot_options_tplot.pro
  - general/tools/tplot/xtplot/xtplot_example.pro
  - general/tools/tplot/tplot_window/tplot_window.pro
  - general/tools/tplot/tplottool.pro
  - general/tools/tplot/load_wilcox.pro
  - general/tplot/data_cut.pro
  - general/misc/interp.pro
  - general/mini/calc.pro
maintenance: |
  Update when a subfolder is added or removed, when the fit/model-function
  convention or the default names made by the *_data arithmetic routines change,
  or when xtplot's common block changes.
---

# General tools

Older utility routines: curve fitting, small array and structure helpers, and
simple operations on tplot variables. Most tplot-variable processing lives
elsewhere (see Things to know).

## Layout

- `fitting/`: `fit` (`fitting/fit.pro`), a nonlinear least-squares fitter, and
  model functions for it (`gaussian`, `gauss`, `mgauss`, `power_law`, `kappa`,
  `polycurve`, `exponential`, `tempfit*`). Crib: `fitting/fit_crib.pro`.
- `misc/`: generic helpers (`average`, `struct`, `print_struct`, `read_asc`,
  `fill_nan`, `rot_mat`, `tmean`), the `dynamicarray` object
  (`misc/dynamicarray__define.pro`), and the widget tools `exec` and `recorder`.
- `tplot/`: tplot-variable arithmetic (`add_data`, `dif_data`, `mult_data`,
  `div_data`, `ang_data`, `avg_data`, `deriv_data`, `delta_data`), sampling
  (`tsample`, `tdexists`), output (`tplot_ascii`, `tprint`), and old loaders.
- `tplot/wvlt/`: `wav_data` (`tplot/wvlt/wav_data.pro`), a Morlet wavelet
  transform of a tplot variable, built on the Torrence and Compo `wavelet`.
  Its `.BAK` and `.old` files are dead copies.
- `tplot/xtplot/`: `xtplot`, a widget wrapper called like `tplot`
  (`tplot/xtplot/xtplot.pro`, example `tplot/xtplot/xtplot_example.pro`).
  `tplot/tplot_window/` and `tplot/tplottool.pro` are other tplot widgets.
- `python_validate/`: scripts that write `.tplot`/`.sav`/CDF reference files for
  pySPEDAS tests (`avg_data`, `minvar`, `wavpol`, `tinterpol_mxn`, THEMIS
  state and cotrans, T89). They generate data; they are not tests.

## How it works

- `fit, x, y, parameters=p` fits the function named in `p.func` (or the
  `function_name` keyword; default `FUNC`) through `call_function`. A model
  function called with no arguments returns its default parameter structure,
  `func` tag included (`p = gaussian()`). `names='h w x0'` fits a subset.
- The two-variable routines take tplot names, interpolate the second variable
  onto the first one's times, and `store_data` the result: `add_data`,
  `dif_data` and `ang_data` use `data_cut` (`general/tplot/data_cut.pro`),
  `mult_data` and `div_data` use `interp` (`general/misc/interp.pro`).
- `avg_data, name, res` bins to `res` seconds (default 60) and stores
  `name+'_avg'` unless `newname` or `append` is set.

## Things to know

- Default output names contain operator characters: `n1+'+'+n2`,
  `n1+'-'+n2`, `n1+'^'+n2` (`mult_data`), `n1+'/'+n2`, `n1+'@'+n2`
  (`ang_data`). Pass `newname` if the name will be globbed or used in a file.
- For expressions use `calc` (`general/mini/calc.pro`). Common processing
  routines are not here: `tinterpol_mxn` and `tvector_rotate` are in
  `general/cotrans/special/`; `tdeflag`, `tclip`, `tdpwrspc`, `time_clip`
  in `general/misc/`; `split_vec`, `join_vec` in `general/tplot/`.
- Folder names repeat: `tplot/` here is not the core `general/tplot/`,
  `misc/` is not `general/misc/`, and `python_validate/` is not
  `general/spedas_tools/python_validation/`.
- Common blocks: `xtplot_com` (`tplot/xtplot/xtplot_com.pro`, included with
  `@xtplot_com`, also by the MMS EVA tool) and `fit_com` in `fit`.
  `tplot/xtplot/xtplot_options_tplot.pro` declares `common tplot_com1` directly
  instead of using `@tplot_com`.
- `load_wilcox` (`tplot/load_wilcox.pro`) reads a hard-coded personal path, and
  `load_wi_elpd5`/`load_wi_pdfit` use the old `loadallcdf` master-file scheme.
  Wind loaders are in `general/missions/wind/` and `projects/wind/`.
