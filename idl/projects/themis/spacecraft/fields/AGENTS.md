---
related_files:
  - projects/themis/AGENTS.md
  - projects/themis/spacecraft/fields/thm_load_fgm.pro
  - projects/themis/spacecraft/fields/thm_load_efi.pro
  - projects/themis/spacecraft/fields/thm_load_efi_l2.pro
  - projects/themis/spacecraft/fields/thm_load_scm.pro
  - projects/themis/spacecraft/fields/thm_load_fft.pro
  - projects/themis/spacecraft/fields/thm_load_fbk.pro
  - projects/themis/spacecraft/fields/thm_load_fit.pro
  - projects/themis/spacecraft/fields/thm_cal_fgm.pro
  - projects/themis/spacecraft/fields/thm_cal_efi.pro
  - projects/themis/spacecraft/fields/thm_cal_scm.pro
  - projects/themis/spacecraft/fields/thm_cal_fft.pro
  - projects/themis/spacecraft/fields/thm_cal_fbk.pro
  - projects/themis/spacecraft/fields/thm_cal_fit.pro
  - projects/themis/spacecraft/fields/thm_cal_fgm_dac_offset.pro
  - projects/themis/spacecraft/fields/thm_fgm_dac_corrections.dat
  - projects/themis/spacecraft/fields/thm_cal_fgm_spin_harmonics.pro
  - projects/themis/spacecraft/fields/spin_harmonic_template.dat
  - projects/themis/spacecraft/fields/thm_cal_fgm_spintone_removal.pro
  - projects/themis/spacecraft/fields/fgm_bad_bz.pro
  - projects/themis/spacecraft/fields/thm_get_efi_cal_pars.pro
  - projects/themis/spacecraft/fields/thm_efi_despin.pro
  - projects/themis/spacecraft/fields/thm_cal_efi_nonTD.pro
  - projects/themis/spacecraft/fields/thm_get_efi_cal_pars_nonTD.pro
  - projects/themis/spacecraft/fields/scm_cleanup_ccc.pro
  - projects/themis/spacecraft/fields/spin_tones_cleaning_vector_v5.pro
  - projects/themis/spacecraft/fields/thm_get_fft_cal_pars.pro
  - projects/themis/spacecraft/fields/thm_get_fbk_cal_pars.pro
  - projects/themis/spacecraft/fields/thm_fft_decompress.pro
  - projects/themis/spacecraft/fields/thm_fbk_decompress.pro
  - projects/themis/spacecraft/fields/spinfit.pro
  - projects/themis/spacecraft/fields/thm_spinfit.pro
  - projects/themis/spacecraft/fields/thm_spinavg.pro
  - projects/themis/spacecraft/fields/LASP
  - projects/themis/spacecraft/fields/LASP/thm_efi_clean_efp.pro
  - projects/themis/spacecraft/fields/LASP/thm_efi_clean_efw.pro
  - projects/themis/spacecraft/fields/fgm_wave_survey/make_fgm_wave_survey_dynspec.pro
  - projects/themis/common/thm_load_xxx.pro
  - projects/themis/common/thm_load_proc_arg.pro
  - projects/themis/state/thm_autoload_support.pro
  - projects/themis/state/cotrans/thm_cotrans.pro
  - projects/themis/examples/basic/thm_crib_fgm.pro
  - projects/themis/examples/basic/thm_crib_efi.pro
  - projects/themis/examples/basic/thm_crib_scm.pro
  - projects/themis/examples/basic/thm_crib_fft.pro
  - projects/themis/examples/basic/thm_crib_fbk.pro
  - projects/themis/examples/basic/thm_crib_fit.pro
  - projects/themis/examples/advanced/thm_crib_efi_cal.pro
  - projects/themis/examples/advanced/thm_crib_spinfit.pro
  - projects/themis/examples/advanced/thm_crib_cleanefp.pro
  - projects/themis/examples/advanced/thm_crib_cleanefw.pro
maintenance: |
  Update when a fields loader or calibration routine is added, renamed or
  changes its call path (thm_load_xxx versus its own loop), when calibration
  files move on the server, or when the default level, type or coord changes.
---

# THEMIS fields instruments (IDL)

Loaders and calibration for the THEMIS/ARTEMIS fields instruments: FGM, EFI,
SCM, and the on-board products FFT (spectra), FBK (filter banks) and FIT (spin
fits). L1 files hold raw ADC counts; loaders calibrate them unless `type='raw'`.

## Layout

- `thm_load_{fgm,efi,scm,fft,fbk,fit}.pro`: loaders, each with its `_post`
  (and sometimes `_relpath`) helper above the main routine.
- `thm_cal_<inst>.pro`: L1 calibration. Helpers: FGM
  `thm_cal_fgm_dac_offset.pro`, `thm_cal_fgm_spin_harmonics.pro`,
  `thm_cal_fgm_spintone_removal.pro`, `fgm_bad_bz.pro`; EFI
  `thm_get_efi_cal_pars.pro`, `thm_efi_despin.pro`; SCM `thm_scm_*.pro`,
  `scm_cleanup_ccc.pro`, `spin_tones_cleaning_vector_v5.pro`; FFT/FBK
  `thm_get_fft_cal_pars.pro`, `thm_get_fbk_cal_pars.pro`,
  `thm_fft_decompress.pro`, `thm_fbk_decompress.pro`, `thm_comp_*_response.pro`.
- `spinfit.pro`, `thm_spinfit.pro`, `thm_spinavg.pro`: spin fits and spin
  averages of loaded E or B variables.
- `LASP/`: EFI burst cleanup (`LASP/thm_efi_clean_efp.pro`,
  `LASP/thm_efi_clean_efw.pro`, `thm_lsp_*`); meant for particle or wave
  bursts, not whole orbits.
- `fgm_wave_survey/make_fgm_wave_survey_dynspec.pro`: FGM wave survey plots.
- `thm_cal_efi_nonTD.pro`, `thm_get_efi_cal_pars_nonTD.pro`: deprecated stubs.

## How the loaders work

- FGM, SCM, FFT, FBK and FIT call `thm_load_xxx`
  (`projects/themis/common/thm_load_xxx.pro`) as the parent describes; the
  `vdatatypes`/`vL2datatypes` strings they pass are the valid datatypes.
- EFI does not. `thm_load_efi.pro` checks arguments with `thm_load_proc_arg`
  (`projects/themis/common/thm_load_proc_arg.pro`) and runs its own loop
  (`file_dailynames`, `spd_download`, `spd_cdf2tplot`). Raw variables get the
  temporary prefix `veryunusualprefixtempfoo_`, `thm_cal_efi` runs, then they
  are renamed or deleted. `level='l2'` goes to `thm_load_efi_l2.pro`.
- Calibrated L1 forces `get_support_data` (the `_hed` variables are needed),
  calls `thm_cal_<inst>` from the post helper, then drops unrequested support.
- `thm_cal_fgm` converts to nT, applies DAC nonlinearity, spin-harmonic and
  spin-tone corrections (`cal_dac_offset=0`, `cal_spin_harmonics=0`,
  `cal_tone_removal=0` turn them off), stores `ssl`, then calls `thm_cotrans`
  (`projects/themis/state/cotrans/thm_cotrans.pro`) for other `coord`s.

## Things to know

- Calibration tables are not in the repo: `spd_download(..., _extra=!themis)`
  fetches them from `th?/l1/<fgm|eff|scm>/0000/` on the THEMIS server
  (`th?_fgmcal.txt`, `th?_efi_calib_params.txt`, `THEMIS_SCM?.cal`,
  `spin_cal/*_avgdist.txt`). FFT/FBK gains are computed in code.
- Two `.dat` files are code: `thm_fgm_dac_corrections.dat` is IDL source
  included with `@` by `thm_cal_fgm_dac_offset.pro`; `spin_harmonic_template.dat`
  is a save file restored by `thm_cal_fgm_spin_harmonics.pro`.
- Calibration needs the spin model: `thm_cal_fgm` and `thm_cal_efi` call
  `thm_autoload_support` (`projects/themis/state/thm_autoload_support.pro`),
  `thm_cal_scm` calls `thm_load_state`. `use_eclipse_corrections` (0, 1, 2)
  picks the spin model variant. EFI `_dot0` (Ez from E.B=0) loads FGM itself.
- `thm_load_fgm` defaults to `coord='dsl'`. Units: raw ADC; calibrated nT (FGM,
  SCM) or mV/m (EFI). EFI labels are `e12 e34 e56` in `ssl`/`spg`, else `Ex Ey Ez`.
- Loaders read whole days. For L1, `thm_load_fgm` widens requests under 10
  minutes (spin calibration); `thm_load_efi` pads 30 minutes and clips back.
- Datatypes: FGM `fgl fgh fge` (`fgs` at L2), EFI `vaf vap vaw vbf vbp vbw`
  and `eff efp efw` plus `_0`, `_dot0`; SCM `scf scp scw`; FBK `fb1 fb2 fbh`;
  FFT `fff_16`...`ffw_64`; FIT `fgs efs`. Variables are `th<probe>_<datatype>`.
- SCM options (`cleanup`, `step`, `fcut`, ...) pass through to `thm_cal_scm`.

## Examples

In `projects/themis/examples/basic/`: `thm_crib_fgm.pro`, `thm_crib_efi.pro`,
`thm_crib_scm.pro`, `thm_crib_fft.pro`, `thm_crib_fbk.pro`, `thm_crib_fit.pro`.
In `projects/themis/examples/advanced/`: `thm_crib_efi_cal.pro`,
`thm_crib_spinfit.pro`, `thm_crib_cleanefp.pro`, `thm_crib_cleanefw.pro` (LASP).
