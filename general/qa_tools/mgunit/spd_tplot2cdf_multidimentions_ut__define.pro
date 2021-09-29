;+
;
; Unit tests for tplot2cdf
;
; To run:
;     IDL> mgunit, 'spd_tplot2cdf_multidimentions_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-02-07 21:19:49 -0800 (Wed, 07 Feb 2018) $
; $LastChangedRevision: 24668 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/mgunit/spd_tplot2cdf_multidimentions_ut__define.pro $
;-

function spd_tplot2cdf_multidimentions_ut::test_v
  store_data, 'test_v', data={x: time_double('2018-01-01')+[1, 2, 3], y: indgen(3,2), v:[3, 4]}  
  tplot2cdf, tvars='test_v', filename='test_v.cdf', /default
  get_data, 'test_v', data=d_original
  del_data, '*'
  cdf2tplot, 'test_v.cdf'
  get_data, 'test_v', data=d
  assert, ~undefined(d.v), 'cdf2tplot does not return v variable'
  assert, array_equal(d.X, d_original.X) && array_equal(d.y, d_original.y) && array_equal(d.v, d_original.v), 'Problem with saved by tplot2cdf variables'
  return, 1
end

function spd_tplot2cdf_multidimentions_ut::test_v_creation
  store_data, 'test_v', data={x: time_double('2018-01-01')+[1, 2, 3], y: indgen(3,2)}  
  tplot2cdf, tvars='test_v', filename='test_v.cdf', /default
  get_data, 'test_v', data=d_original
  del_data, '*'
  cdf2tplot, 'test_v.cdf'
  get_data, 'test_v', data=d
  assert, ~undefined(d.v), 'cdf2tplot does not return v variable'
  assert, array_equal(d.X, d_original.X) && array_equal(d.y, d_original.y) && array_equal(d.v, indgen(2)), 'Problem with saved by tplot2cdf variables'
  return, 1
end

function spd_tplot2cdf_multidimentions_ut::test_v12
  store_data, 'test_v12', data={x: time_double('2018-01-01')+[1, 2, 3], y: indgen(3,2,4)}  
  tplot2cdf, tvars='test_v12', filename='test_v12.cdf', /default
  get_data, 'test_v12', data=d_original
  del_data, '*'
  cdf2tplot, 'test_v12.cdf'
  get_data, 'test_v12', data=d
  assert, ~undefined(d.v1) and ~undefined(d.v2), 'cdf2tplot does not return v# variable'
  assert, array_equal(d.X, d_original.X) && array_equal(d.y, d_original.y) && array_equal(d.v1, indgen(2)) && array_equal(d.v2, indgen(4)), 'Problem with saved by tplot2cdf variables'
  return, 1
end

function spd_tplot2cdf_multidimentions_ut::test_v_time
  store_data, 'test_v_time', data={x: time_double('2018-01-01')+[1, 2, 3], y: indgen(3,2), v:indgen(3,2)+10}
  tplot2cdf, tvars='test_v_time', filename='test_v_time.cdf', /default
  get_data, 'test_v_time', data=d_original
  del_data, '*'
  cdf2tplot, 'test_v_time.cdf'
  get_data, 'test_v_time', data=d  
  assert, array_equal(d.X, d_original.X) && array_equal(d.y, d_original.y) && array_equal(d.v, d_original.v), 'Problem with saved by tplot2cdf variables'
  return, 1
end

function spd_tplot2cdf_multidimentions_ut::test_v12_time
  store_data, 'test_v12_time', data={x: time_double('2018-01-01')+[1, 2, 3], y: indgen(3,2,5), v1:indgen(3,2)+10, v2:indgen(3,5)+10}
  tplot2cdf, tvars='test_v12_time', filename='test_v12_time.cdf', /default
  get_data, 'test_v12_time', data=d_original
  del_data, '*'
  cdf2tplot, 'test_v12_time.cdf'
  get_data, 'test_v12_time', data=d
  assert, array_equal(d.X, d_original.X) && array_equal(d.y, d_original.y) && array_equal(d.v1, d_original.v1) && array_equal(d.v2, d_original.v2), 'Problem with saved by tplot2cdf variables'
  return, 1
end

pro spd_tplot2cdf_multidimentions_ut::setup
  del_data, '*'
end

function spd_tplot2cdf_multidimentions_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['tplot2cdf']
  return, 1
end

pro spd_tplot2cdf_multidimentions_ut__define
  define = { spd_tplot2cdf_multidimentions_ut, inherits MGutTestCase }
end