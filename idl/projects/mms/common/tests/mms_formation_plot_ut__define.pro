;+
;
; Regression tests for mms_mec_formation_plot
;
; To run:
;     IDL> mgunit, 'mms_formation_plot_ut'
;     
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-04-03 17:43:10 -0700 (Fri, 03 Apr 2020) $
; $LastChangedRevision: 28497 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_formation_plot_ut__define.pro $
;-
  
function mms_formation_plot_ut::test_user_vectors
  mms_mec_formation_plot, '2016-1-08/2:36', vector_x=[[0, 1], [0, 7]], vector_y=[[0, 1], [0, 1]], vector_z=[[0, 5], [0, 1]], vector_colors=[[255, 0, 0], [0, 0, 255]]
  return, 1
end

function mms_formation_plot_ut::test_projections
  mms_mec_formation_plot, '2015-12-15/06:00', /projection
  return, 1
end

function mms_formation_plot_ut::test_sc_vectors
  mms_mec_formation_plot,'2016-1-08/2:36',fpi_data_rate='fast',fpi_normalization=0.1d,fgm_normalization=1.d,/dis_sc,/des_sc,/bfield_sc,/projection,plotmargin=1.0,sc_size=2.0,sundir='left'
  return, 1
end

function mms_formation_plot_ut::test_center_vectors
  mms_mec_formation_plot,'2016-1-08/2:36',fpi_data_rate='fast',fpi_normalization=0.1d,fgm_normalization=1.d,/dis_center,/des_center,/bfield_center,/projection,plotmargin=1.0,sc_size=2.0,sundir='left'
  return, 1
end

function mms_formation_plot_ut::test_xyz
  mms_mec_formation_plot, '2016-1-08/2:36', /xy_projection, coord='gse', xyz=[[0.00,0.00,1.00],[0.00,-1.00,0.00],[1.00,0.00,0.00]], sundir='left'
  return, 1
end

function mms_formation_plot_ut::test_lmn
  mms_mec_formation_plot, '2016-1-08/2:36', /xy_projection, coord='gse', lmn=[[0.00,0.00,1.00],[0.00,-1.00,0.00],[1.00,0.00,0.00]], sundir='left'
  return, 1
end

function mms_formation_plot_ut::test_sundir
  mms_mec_formation_plot, '2015-12-15/06:00', sundir='left'
  return, 1
end

function mms_formation_plot_ut::test_tqf
  mms_mec_formation_plot, '2015-12-15/06:00', /quality_factor
  return, 1
end

function mms_formation_plot_ut::test_sc_size
  mms_mec_formation_plot, '2015-12-15/06:00', sc_size=0.5
  return, 1
end

function mms_formation_plot_ut::test_coord
  mms_mec_formation_plot, '2015-12-15/06:00', coord='sm'
  return, 1
end

function mms_formation_plot_ut::test_basic
  mms_mec_formation_plot, '2015-12-15/06:00'
  return, 1
end

pro mms_formation_plot_ut::setup
  ; do some setup for the tests
end

function mms_formation_plot_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_mec_formation_plot']
  return, 1
end

pro mms_formation_plot_ut__define
  compile_opt strictarr

  define = { mms_formation_plot_ut, inherits MGutTestCase }
end