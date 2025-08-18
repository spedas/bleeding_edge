;+
;
; Unit tests for mms_part_slice2d
;
; To run:
;     IDL> mgunit, 'mms_part_slice2d_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-11-13 11:48:04 -0800 (Tue, 13 Nov 2018) $
; $LastChangedRevision: 26116 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_part_slice2d_ut__define.pro $
;-
function mms_part_slice2d_ut::test_plotsun_regression
  mms_part_slice2d, probe=4, /plotsun, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_rot_bv', rotation='bv'
  assert, spd_data_exists('mms4_mec_r_sun_de421_gse', '2015-12-15', '2015-12-15/0:01'), 'Problem with plotsun regression'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_rot_bv
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_rot_bv', rotation='bv'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_rot_be
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_rot_be', rotation='be'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_rot_perp
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_rot_perp', rotation='perp'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_log
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_log', /log
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_energy
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_energy', /energy
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_sum_angle
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_sum_angle', /geo, sum_angle=[0, 90]
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_basic'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_units
  mms_part_slice2d, units='eflux', trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export=self.output_folder+'test_fpi_i_units'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_burst
  mms_part_slice2d, trange=['2015-10-16/13:06', '2015-10-16/13:06:05'], instrument='fpi', species='i', data_rate='brst', export=self.output_folder+'test_fpi_i_burst'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_subtract_bulk
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', /subtract_bulk, export=self.output_folder+'test_fpi_i_subtract_bulk'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_e_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='e', export=self.output_folder+'test_fpi_e_basic'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_hplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='hplus', export=self.output_folder+'test_hpca_hplus_basic'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_oplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='oplus', export=self.output_folder+'test_hpca_oplus_basic'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_heplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='heplus', export=self.output_folder+'test_hpca_heplus_basic'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_heplusplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='heplusplus', export=self.output_folder+'test_hpca_heplusplus_basic'
  return, 1
end

pro mms_part_slice2d_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /min
end

function mms_part_slice2d_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['spd_slice2d', 'mms_part_slice2d']
  self.output_folder = 'mms_part_slice2d_tests/'
  return, 1
end

pro mms_part_slice2d_ut__define
  define = { mms_part_slice2d_ut, output_folder: '', inherits MGutTestCase }
end