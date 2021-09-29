;+
;
; Unit tests for flatten_spectra
;
; To run:
;     IDL> mgunit, 'flatten_spectra_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2021-08-19 11:49:54 -0700 (Thu, 19 Aug 2021) $
; $LastChangedRevision: 30224 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/flatten_spectra_ut__define.pro $
;-

function flatten_spectra_ut::test_xvals_yvals_multi
  tplot, ['mms3_dis_energyspectr_omni_fast']
  flatten_spectra_multi, time='2017-09-10/09:32:20', xvalues=xv, yvalues=yv
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 2.1600001, 'Problem with flatten_spectra_multi'
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 21185.219, 'Problem with flatten_spectra_multi'
  return, 1
end

function flatten_spectra_ut::test_xvals_yvals_multi_to_kev_to_flux
  options, 'mms3_dis_energyspectr_omni_fast', ysubtitle='[eV]'
  tplot, ['mms3_dis_energyspectr_omni_fast']
  flatten_spectra_multi, time='2017-09-10/09:32:20', xvalues=xv, yvalues=yv, /to_kev, /to_flux
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 0.0021600000858306885d, 'Problem with flatten_spectra_multi'
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 9807971.2537847571d, 'Problem with flatten_spectra_multi'
  return, 1
end

function flatten_spectra_ut::test_xvals_yvals_multi_to_kev
  options, 'mms3_dis_energyspectr_omni_fast', ysubtitle='[eV]'
  tplot, ['mms3_dis_energyspectr_omni_fast']
  flatten_spectra_multi, time='2017-09-10/09:32:20', xvalues=xv, yvalues=yv, /to_kev
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 0.0021600000858306885d, 'Problem with flatten_spectra_multi'
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 21185.219, 'Problem with flatten_spectra_multi'
  return, 1
end

function flatten_spectra_ut::test_xvals_yvals_multi_to_flux
  tplot, ['mms3_dis_energyspectr_omni_fast']
  flatten_spectra_multi, time='2017-09-10/09:32:20', xvalues=xv, yvalues=yv, /to_flux
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 2.1600001, 'Problem with flatten_spectra_multi'
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 9807971.2537847571d, 'Problem with flatten_spectra_multi'
  return, 1
end

function flatten_spectra_ut::test_xvals_yvals_cdf_units
  options, 'mms3_dis_energyspectr_omni_fast', ysubtitle=''
  options, 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', ysubtitle=''
  options, 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', ysubtitle=''
  options, 'mms3_hpca_hplus_flux_elev_0-360_spin', ysubtitle=''
  options, 'mms3_dis_energyspectr_omni_fast', ztitle=''
  options, 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', ztitle=''
  options, 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', ztitle=''
  options, 'mms3_hpca_hplus_flux_elev_0-360_spin', ztitle=''
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', window_time=2, xvalues=xv, yvalues=yv
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 13880317.192948064d, 'Problem with to_kev/to_flux keywords'
  assert, (yv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 14929.753766475451d, 'Problem with to_flux/to_flux keywords'
  assert, (yv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 34.081003934403000d, 'Problem with to_flux/to_flux keywords'
  assert, (yv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq 15824283.918153785d, 'Problem with to_flux/to_flux keywords'
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 0.0021600000858306885d, 'Problem with to_kev/to_flux keywords'
  assert, (xv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 12.025784797675369d, 'Problem with to_kev/to_flux keywords'
  assert, (xv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 53.032586208858419d, 'Problem with to_kev/to_flux keywords'
  assert, (xv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq  0.0013474999666213989d, 'Problem with to_kev/to_flux keywords'
  return, 1
end

function flatten_spectra_ut::test_xvals_yvals_no_conversion
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, time='2017-09-10/08:57:00', window_time=2, xvalues=xv, yvalues=yv
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 29981.486, 'Problem with flatten_spectra'
  assert, (yv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 14929.753766475451d, 'Problem with flatten_spectra'
  assert, (yv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 34.081003934403000d, 'Problem with flatten_spectra'
  assert, (yv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq 15824.283918153786d, 'Problem with flatten_spectra'
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 2.1600001, 'Problem with flatten_spectra'
  assert, (xv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 12.025784797675369d, 'Problem with flatten_spectra'
  assert, (xv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 53.032586208858419d, 'Problem with flatten_spectra'
  assert, (xv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq 1.3474999666213989d, 'Problem with flatten_spectra'
  return, 1
end

function flatten_spectra_ut::test_xvals_yvals_to_flux
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_flux, time='2017-09-10/08:57:00', window_time=2, xvalues=xv, yvalues=yv
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 13880317.192948064d, 'Problem with to_flux keyword'
  assert, (yv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 14929.753766475451d, 'Problem with to_flux keyword'
  assert, (yv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 34.081003934403000d, 'Problem with to_flux keyword'
  assert, (yv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq 15824283.918153785d, 'Problem with to_flux keyword'
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 2.1600001, 'Problem with to_flux keyword'
  assert, (xv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 12.025784797675369d, 'Problem with to_flux keyword'
  assert, (xv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 53.032586208858419d, 'Problem with to_flux keyword'
  assert, (xv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq 1.3474999666213989d, 'Problem with to_flux keyword'
  return, 1
end

function flatten_spectra_ut::test_xvals_yvals_to_kev
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, time='2017-09-10/08:57:00', window_time=2, xvalues=xv, yvalues=yv
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 29981.486, 'Problem with to_kev keyword'
  assert, (yv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 14929.753766475451d, 'Problem with to_kev keyword'
  assert, (yv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 34.081003934403000d, 'Problem with to_kev keyword'
  assert, (yv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq 15824.283918153786d, 'Problem with to_kev keyword'
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 0.0021600000858306885d, 'Problem with to_kev keyword'
  assert, (xv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 12.025784797675369d, 'Problem with to_kev keyword'
  assert, (xv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 53.032586208858419d, 'Problem with to_kev keyword'
  assert, (xv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq  0.0013474999666213989d, 'Problem with to_kev keyword'
  return, 1
end

function flatten_spectra_ut::test_xvals_yvals_to_kev_to_flux
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', window_time=2, xvalues=xv, yvalues=yv
  assert, (yv['mms3_dis_energyspectr_omni_fast'])[0] eq 13880317.192948064d, 'Problem with to_kev/to_flux keywords'
  assert, (yv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 14929.753766475451d, 'Problem with to_flux/to_flux keywords'
  assert, (yv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 34.081003934403000d, 'Problem with to_flux/to_flux keywords'
  assert, (yv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq 15824283.918153785d, 'Problem with to_flux/to_flux keywords'
  assert, (xv['mms3_dis_energyspectr_omni_fast'])[0] eq 0.0021600000858306885d, 'Problem with to_kev/to_flux keywords'
  assert, (xv['mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin'])[0] eq 12.025784797675369d, 'Problem with to_kev/to_flux keywords'
  assert, (xv['mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin'])[0] eq 53.032586208858419d, 'Problem with to_kev/to_flux keywords'
  assert, (xv['mms3_hpca_hplus_flux_elev_0-360_spin'])[0] eq  0.0013474999666213989d, 'Problem with to_kev/to_flux keywords'
  return, 1
end

function flatten_spectra_ut::test_to_kev_flux_window_time_replot
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev_flux_window_replot1', window_time=2
  flatten_spectra, /replot, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev_flux_window_replot2', window_time=2
  return, 1
end

function flatten_spectra_ut::test_to_kev_flux_samples_replot
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev_flux_samples_replot1', samples=20
  flatten_spectra, /replot, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev_flux_samples_replot2', samples=20
  return, 1
end

function flatten_spectra_ut::test_to_kev_flux_samples
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev_flux_samples', samples=20
  return, 1
end

function flatten_spectra_ut::test_to_kev_flux
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev_flux'
  return, 1
end

function flatten_spectra_ut::test_to_kev
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev'
  return, 1
end

function flatten_spectra_ut::test_to_flux
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_flux'
  return, 1
end

function flatten_spectra_ut::test_no_conversion
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms3_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_no_conversion'
  return, 1
end

pro flatten_spectra_ut::setup
  del_data, '*'
  trange=['2017-09-10/09:30:20', '2017-09-10/09:34:20']
  probe=3

  mms_load_fpi, trange=trange, datatype='dis-moms', probe=probe
  mms_load_eis, trange=trange, probe=probe, datatype=['extof', 'phxtof']
  mms_load_hpca, trange=trange, probe=probe, datatype='ion'
  mms_hpca_calc_anodes, fov=[0, 360]
  mms_hpca_spin_sum, /avg, probe=probe
end

function flatten_spectra_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['flatten_spectra', 'flatten_spectra_multi']
  
;  del_data, '*'
;  trange=['2017-09-10/09:30:20', '2017-09-10/09:34:20']
;  probe=3
;
;  mms_load_fpi, trange=trange, datatype='dis-moms', probe=probe
;  mms_load_eis, trange=trange, probe=probe, datatype=['extof', 'phxtof']
;  mms_load_hpca, trange=trange, probe=probe, datatype='ion'
;  mms_hpca_calc_anodes, fov=[0, 360]
;  mms_hpca_spin_sum, /avg, probe=probe
  return, 1
end

pro flatten_spectra_ut__define
    define = { flatten_spectra_ut, inherits MGutTestCase }
end