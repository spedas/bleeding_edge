;+
;
; Unit tests for tplot2cdf
;
; To run:
;     IDL> mgunit, 'spd_tplot2cdf_data_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-04-16 18:48:24 -0700 (Mon, 16 Apr 2018) $
; $LastChangedRevision: 25059 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/mgunit/spd_tplot2cdf_data_ut__define.pro $
;-

function spd_tplot2cdf_data_ut::test_fpi_tt2000_data  
  mms_load_fpi, trange=['2015-12-15', '2015-12-15 02:00:00'], datatype='des-dist', probe=3, cdf_filenames=files
  del_data, '*'
  spd_cdf2tplot, files[0], /all, /tt2000 
  get_data, 'mms3_des_dist_fast', data=original  
  tplot2cdf, tvars='mms3_des_dist_fast', filename='test_fpi_tt2000_dist.cdf', /default, /tt2000
  del_data, '*'
  spd_cdf2tplot, 'test_fpi_tt2000_dist.cdf', /all, /tt2000  
  get_data, 'mms3_des_dist_fast', data=d
  assert, array_equal(original.Y, d.Y) && array_equal(original.v1, d.v1) && array_equal(original.v2, d.v2) && array_equal(original.v3, d.v3), 'Problem with FPI data'
  assert, array_equal(original.x, d.x) , 'Problem time of TT2000 Epoch FPI data'  
  return, 1
end

function spd_tplot2cdf_data_ut::test_fpi_multidimensional_data  
  mms_load_fpi, trange=['2015-12-15', '2015-12-16'], datatype='des-dist', probe=3
  get_data, 'mms3_des_dist_fast', data=original
  tplot2cdf, tvars='mms3_des_dist_fast', filename='test_fpi_dist.cdf', /default
  del_data, '*'
  mms_cdf2tplot, 'test_fpi_dist.cdf', /all
  get_data, 'mms3_des_dist_fast', data=d
  assert, array_equal(original.Y, d.Y) && array_equal(original.v1, d.v1) && array_equal(original.v2, d.v2) && array_equal(original.v3, d.v3), 'Problem with FPI data'
  ;assert, /SKIP, array_equal(original.x, d.x) , 'Problem time of FPI data'
  assert,  max(abs(original.x - d.x)) lt 1e-4, 'Problem time of FPI data' ; check if the difference in time is in the allowed margin
  return, 1
end

function spd_tplot2cdf_data_ut::test_hpca_multidimensional_data  
  ; This case does not work since tplot2cdf does not support v1, v2, ... etc
  mms_load_hpca, trange=['2015-12-15', '2015-12-16'], datatype='ion', probe=3
  get_data, 'mms3_hpca_hplus_phase_space_density', data=original
  tplot2cdf, tvars='mms3_hpca_hplus_phase_space_density', filename='test_hpca_dist.cdf', /default
  del_data, '*'
  mms_cdf2tplot, 'test_hpca_dist.cdf'
  get_data, 'mms3_hpca_hplus_phase_space_density', data=d
  assert, array_equal(original.Y, d.Y)  && array_equal(original.v1, d.v1) && array_equal(original.v2, d.v2), 'Problem with HPCA data'
  ;assert, /SKIP, array_equal(original.x, d.x) , 'Problem with time of HPCA data'
  assert, max(abs(original.x - d.x)) lt 1e-4, 'Problem with time of HPCA data' ; check if the difference in time is in the allowed margin
  return, 1
end

function spd_tplot2cdf_data_ut::test_rbsp_spec
  rbsp_load_rbspice, probe='a', trange=['2015-10-16', '2015-10-17'], datatype='TOFxEH', level='l3'
  get_data, 'rbspa_rbspice_l3_TOFxEH_proton_omni_spin', data=original
  tplot2cdf, tvars='rbspa_rbspice_l3_TOFxEH_proton_omni_spin', filename='rbsp_data.cdf', /default
  del_data, '*'
  mms_cdf2tplot, 'rbsp_data.cdf', /all
  get_data, 'rbspa_rbspice_l3_TOFxEH_proton_omni_spin', data=d
  assert, array_equal(original.Y, d.Y) && array_equal(original.v, d.v), 'Problem with RBSP data'
  ; assert, /SKIP, array_equal(original.X, d.X), 'Problem with time of RBSP data'
  assert, max(abs(original.X - d.X)) lt 1e-4, 'Problem with time of RBSP data' ; check if the difference in time is in the allowed margin  
  return, 1
end

pro spd_tplot2cdf_data_ut::setup
  del_data, '*'
end

function spd_tplot2cdf_data_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['tplot2cdf','spd_cdf2tplot']
  return, 1
end

pro spd_tplot2cdf_data_ut__define
  define = { spd_tplot2cdf_data_ut, inherits MGutTestCase }
end