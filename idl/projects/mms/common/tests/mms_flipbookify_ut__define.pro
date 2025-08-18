;+
;
; Unit tests for mms_flipbookify
;
;
; NOTES:
;     - Unlike most of our other unit/regression tests, this suite creates plots and videos that
;       need to be checked for formatting issues (~/flipbook/ directory)
;       
; To run:
;     IDL> mgunit, 'mms_flipbookify_ut'
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2023-11-09 10:31:32 -0800 (Thu, 09 Nov 2023) $
; $LastChangedRevision: 32226 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_flipbookify_ut__define.pro $
;-

function mms_flipbookify_ut::test_fpi_subtract_spintone_bulk
  mms_load_fpi, datatype='des-moms', data_rate='brst', trange=['2015-10-16/13', '2015-10-16/13:10'], /time_clip
  tplot, ['mms3_des_bulkv_gse_brst', 'mms3_des_energyspectr_omni_brst']
  mms_flipbookify, probe=3, /subtract_bulk, time_step=1000
  get_data, 'mms3_dis_bulkv_gse_brst', data=d
  assert, array_equal(d.Y[0, *], [4.1067505, -17.589445, -52.619148]), 'Problem not subtracting spin-tone'
  mms_flipbookify, probe=3, /subtract_bulk, /subtract_spintone, time_step=1000
  get_data, 'mms3_dis_bulkv_gse_brst', data=d
  assert, array_equal(d.Y[0, *], [-3.0741749, -37.590820, -51.599651]), 'Problem subtracting spin-tone'
  return, 1
end

function mms_flipbookify_ut::test_fpi_subtract_err_bulk
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='i', /subtract_error, /subtract_bulk
  return, 1
end

function mms_flipbookify_ut::test_fpi_field_aligned_slices_ps
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='i', slices=['bv', 'perp', 'perp_xy'], /postscript
  return, 1
end

function mms_flipbookify_ut::test_simple_timestep_ps
  tplot, 'mms1_des_bulkv_dbcs_fast'
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', time_step=10, filename_suffix='_timestep', /postscript
  return, 1
end

function mms_flipbookify_ut::test_adding_1d_cuts_both_ps
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='e', /include_1d_vx, /include_1d_vy, filename_suffix='_1dboth', /postscript
  return, 1
end

function mms_flipbookify_ut::test_adding_1d_cuts_vy_ps
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='e', /include_1d_vy, filename_suffix='_1d_vy', /postscript
  return, 1
end

function mms_flipbookify_ut::test_adding_1d_cuts_vx_ps
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='e', /include_1d_vx, filename_suffix='_1d_vx', /postscript
  return, 1
end

function mms_flipbookify_ut::test_simple_fpi_ps
  tplot, 'mms1_des_bulkv_dbcs_fast'
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', /postscript
  return, 1
end

function mms_flipbookify_ut::test_multi_fpi_ps
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='e', /postscript
  return, 1
end

function mms_flipbookify_ut::test_fpi_field_aligned_slices
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='i', slices=['bv', 'perp', 'perp_xy']
  return, 1
end

function mms_flipbookify_ut::test_simple_timestep
  tplot, 'mms1_des_bulkv_dbcs_fast'
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', time_step=10, filename_suffix='_timestep'
  return, 1
end

function mms_flipbookify_ut::test_adding_1d_cuts_both
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='e', /include_1d_vx, /include_1d_vy, filename_suffix='_1dboth'
  return, 1
end

function mms_flipbookify_ut::test_adding_1d_cuts_vy
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='e', /include_1d_vy, filename_suffix='_1d_vy'
  return, 1
end

function mms_flipbookify_ut::test_adding_1d_cuts_vx
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='e', /include_1d_vx, filename_suffix='_1d_vx'
  return, 1
end

function mms_flipbookify_ut::test_simple_fpi
  tplot, 'mms1_des_bulkv_dbcs_fast'
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast'
  return, 1
end

function mms_flipbookify_ut::test_multi_fpi
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15/16:00', '2017-12-15/16:01'], data_rate='fast', species='e'
  return, 1
end

function mms_flipbookify_ut::test_fpi_video
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15', '2017-12-16'], data_rate='fast', species='e', /nopng, /video, time_step=500
  return, 1
end

function mms_flipbookify_ut::test_hpca_video
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15', '2017-12-16'], data_rate='srvy', species='hplus', /nopng, /video, time_step=500, instrument='hpca'
  return, 1
end

function mms_flipbookify_ut::test_fpi_video_with_lineplots
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15', '2017-12-16'], data_rate='fast', species='i', /nopng, /video, time_step=500, /include_1d_vx, /include_1d_vy, filename_suffix='_vid_with_lines'
  return, 1
end

function mms_flipbookify_ut::test_fpi_video_with_lineplots_yrange
  tplot, ['mms1_des_energyspectr_omni_fast', 'mms1_des_bulkv_dbcs_fast', 'mms1_des_pitchangdist_avg']
  mms_flipbookify, trange=['2017-12-15', '2017-12-16'], lineplot_yrange=[1e-34, 1e28], data_rate='fast', species='i', /nopng, /video, time_step=500, /include_1d_vx, /include_1d_vy, filename_suffix='_vid_with_lines_yrangeset'
  return, 1
end

pro mms_flipbookify_ut::teardown
  if (!d.name ne "Z") then window, 0 ; clear the current window
end

pro mms_flipbookify_ut::setup
  del_data, '*'
  mms_load_fpi, level='l2', data_rate='fast', trange=['2017-12-15', '2017-12-16'], datatype=['dis-moms', 'des-moms'], probe=1
  if (!d.name ne "Z") then window, 0 ; clear the current window
end

function mms_flipbookify_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_flipbookify']
  return, 1
end

pro mms_flipbookify_ut__define
  define = { mms_flipbookify_ut, inherits MGutTestCase }
end

