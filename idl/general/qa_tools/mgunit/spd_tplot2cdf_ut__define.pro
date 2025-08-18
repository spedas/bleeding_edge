;+
;
; Unit tests for tplot2cdf
;
; To run:
;     IDL> mgunit, 'spd_tplot2cdf_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-03-12 18:09:07 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24881 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/mgunit/spd_tplot2cdf_ut__define.pro $
;-

function spd_tplot2cdf_ut::test_save_1d_time
  store_data, 'test_1d_time', data=time_double('2018-01-01')+[1, 2, 3, 4]
  tplot2cdf, tvars='test_1d_time', filename='test_1d_time.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_1d_time.cdf'
  get_data, 'test_1d_time', data=d
  ; Note, that cdf2tplot ignores the load of the data if only Epoch is defined 
  ; So, in the CDF files there is data that is equal to Epoch.
   assert, array_equal(d.X, time_double('2018-01-01')+[1, 2, 3, 4]), 'Problem with times in CDF file saved by tplot2cdf'
  return, 1
end


function spd_tplot2cdf_ut::test_save_times
  store_data, 'test_times', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: [5, 5, 5, 5]}
  tplot2cdf, tvars='test_times', filename='test_times.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_times.cdf'
  get_data, 'test_times', data=d
  assert, array_equal(d.X, time_double('2018-01-01')+[1, 2, 3, 4]), 'Problem with times in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_largenum
  store_data, 'test_largenum', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: [999999999999999999, 5, 5, 5]}
  tplot2cdf, tvars='test_largenum', filename='test_largenum.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_largenum.cdf'
  get_data, 'test_largenum', data=d
  assert, array_equal(d.Y, [999999999999999999, 5, 5, 5]), 'Problem with large number in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_float
  floatvals = indgen(4, /float)
  store_data, 'test_float', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: indgen(4, /float)}
  tplot2cdf, tvars='test_float', filename='test_float.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_float.cdf'
  get_data, 'test_float', data=d
  assert, array_equal(d.Y, floatvals), 'Problem with floats in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_share_time
  floatvals1 = indgen(4, /float)
  floatvals2 = indgen(4, /float)+1.
  sharetime = time_double('2018-01-01')+[1, 2, 3, 4]
  store_data, 'test_sharetime1', data={x: sharetime, y: floatvals1 }
  store_data, 'test_sharetime2', data={x: sharetime, y: floatvals2 }
  tplot2cdf, tvars=['test_sharetime1','test_sharetime2'], filename='test_sharetime.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_sharetime.cdf'
  get_data, 'test_sharetime1', data=d1
  get_data, 'test_sharetime2', data=d2  
  assert, array_equal(d1.Y, floatvals1) && array_equal(d2.Y, floatvals2) && array_equal(d1.x, sharetime) && array_equal(d2.x, sharetime), 'Problem with shared time in CDF file saved by tplot2cdf'  
  return, 1
end

function spd_tplot2cdf_ut::test_save_share_multidimention
  data1 = RANDOMU(!NULL,2,3,4,5,/DOUBLE)
  data2 = RANDOMU(!NULL,2,3,4,5,/DOUBLE)
  v1 = RANDOMU(!NULL,2,3,/DOUBLE)
  v2 = RANDOMU(!NULL,2,4,/DOUBLE)  
  v3 = RANDOMU(!NULL,2,5,/DOUBLE)
  sharetime = time_double('2018-01-01')+[1, 2]
  
  store_data, 'test_mshare1', data={x: sharetime, y: data1, v1:v1, v2:v2 , v3:v3}
  store_data, 'test_mshare2', data={x: sharetime, y: data2, v1:v1, v2:v2 , v3:v3}
  tplot2cdf, tvars=['test_mshare1','test_mshare2'], filename='test_mshare.cdf', /default
  del_data, '*'
  mms_cdf2tplot, 'test_mshare.cdf'
  get_data, 'test_mshare1', data=d1
  get_data, 'test_mshare2', data=d2
  assert, array_equal(d1.Y, data1) && array_equal(d1.x, sharetime) && array_equal(d1.v1, v1) && array_equal(d1.v2, v2) && array_equal(d1.v3, v3) &&$
          array_equal(d2.Y, data2) && array_equal(d2.x, sharetime) && array_equal(d2.v1, v1) && array_equal(d2.v2, v2) && array_equal(d2.v3, v3)$
    , 'Problem with shared multidimentional data in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_spectrogram
  data = RANDOMU(!NULL,4,5,/DOUBLE)  
  v = indgen(5)
  time = time_double('2018-01-01')+indgen(4)
  store_data, 'test_spectr', data={x: time, y: data, v:v}, dlimits={spec:1} 
  tplot2cdf, tvars=['test_spectr'], filename='test_spectr.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_spectr.cdf'
  get_data, 'test_spectr', data=d, dlimit=s
  assert, array_equal(d.Y, data) && array_equal(d.x, time) && array_equal(d.v, v) && s.spec eq 1 $    
    , 'Problem with spectrum data in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_share_support_data
  data1 = RANDOMU(!NULL,2,3,4,/DOUBLE)
  data2 = RANDOMU(!NULL,2,3,4,/DOUBLE)
  v1 = INDGEN(3)+1
  v2 = INDGEN(4)+2  
  sharetime = time_double('2018-01-01')+[1, 2]
  
  store_data, 'test_share1', data={x: sharetime, y: data1, v1:v1, v2:v2 }
  store_data, 'test_share2', data={x: sharetime, y: data2, v1:v1, v2:v2 }
  tplot2cdf, tvars=['test_share1','test_share2'], filename='test_share.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_share.cdf'
  get_data, 'test_share1', data=d1
  get_data, 'test_share2', data=d2
  assert, array_equal(d1.Y, data1) && array_equal(d1.x, sharetime) && array_equal(d1.v1, v1) && array_equal(d1.v2, v2) && $
          array_equal(d2.Y, data2) && array_equal(d2.x, sharetime) && array_equal(d2.v1, v1) && array_equal(d2.v2, v2) $
    , 'Problem with shared data in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_tt2000  
  store_data, 'test_tt2000', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: indgen(4)}
  tplot2cdf, tvars='test_tt2000', filename='test_tt2000.cdf', /default, /tt2000
  del_data, '*'
  id = CDF_OPEN('test_tt2000.cdf')
  CDF_VARGET, id, 'Epoch', Epoch
  CDF_CLOSE, id
  assert, size(Epoch, /type) eq 14, 'Saved TT2000 Epoch is not in LONG64 format'
  return, 1
end

function spd_tplot2cdf_ut::test_save_tt2000_long64
  EpochL = CDF_PARSE_TT2000('2005-12-04T20:19:18.176214648') + long64(indgen(4))
  Y = indgen(4)
  store_data, 'test_save_tt2000_long64', data={x: EpochL, y: Y}
  tplot2cdf, tvars='test_save_tt2000_long64', filename='test_save_tt2000_long64.cdf', /default, /tt2000
  del_data, '*'
  id = CDF_OPEN('test_save_tt2000_long64.cdf')
  CDF_VARGET, id, 'Epoch', Epoch_cdf, REC_COUNT=4
  CDF_VARGET, id, 'test_save_tt2000_long64', Y_cdf, REC_COUNT=4
  CDF_CLOSE, id
  assert, size(Epoch_cdf, /type) eq 14, 'Saved TT2000 Epoch is not in LONG64 format'
  assert, array_equal(EpochL, Epoch_cdf) and array_equal(Y, Y_cdf), 'Saved in CDF file data is different from tplot data'
  return, 1
end

function spd_tplot2cdf_ut::test_dlimits_metadata
  metadata = {units:'#', labels:['x','y','z'], ytitle:'3 components'}
  store_data, 'test_metadata', data={x: time_double('2018-01-01')+[1, 2, 3], y: [[5,5,5],[6,6,6],[7,7,7]]}, dlimits=metadata
  tplot2cdf, tvars='test_metadata', filename='test_metadata.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_metadata.cdf'
  get_data, 'test_metadata', dl=s
  id = CDF_OPEN('test_metadata.cdf')
  CDF_VARGET, id, 'test_metadata_v', test_metadata_v, /string
  CDF_CLOSE, id
  assert, array_equal(s.CDF.VATT[0].UNITS, metadata.units, /QUIET), 'Problem with units in CDF metadata'
  assert, array_equal(s.CDF.VATT[0].LABLAXIS, metadata.ytitle, /QUIET), 'Problem with label axis in CDF metadata'
  assert, array_equal(s.CDF.VATT[0].LABL_PTR_1, 'test_metadata_v', /QUIET), 'Problem with LABL_PTR_1 in CDF file'
  assert, ARRAY_EQUAL(test_metadata_v, metadata.labels), 'Problem with labels in CDF metadata'  
  return, 1
end

function spd_tplot2cdf_ut::test_v
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

function spd_tplot2cdf_ut::test_v_creation
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

function spd_tplot2cdf_ut::test_v12
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

function spd_tplot2cdf_ut::test_v_time
  store_data, 'test_v_time', data={x: time_double('2018-01-01')+[1, 2, 3], y: indgen(3,2), v:indgen(3,2)+10}
  tplot2cdf, tvars='test_v_time', filename='test_v_time.cdf', /default
  get_data, 'test_v_time', data=d_original
  del_data, '*'
  cdf2tplot, 'test_v_time.cdf'
  get_data, 'test_v_time', data=d
  assert, array_equal(d.X, d_original.X) && array_equal(d.y, d_original.y) && array_equal(d.v, d_original.v), 'Problem with saved by tplot2cdf variables'
  return, 1
end

function spd_tplot2cdf_ut::test_v12_time
  store_data, 'test_v12_time', data={x: time_double('2018-01-01')+[1, 2, 3], y: indgen(3,2,5), v1:indgen(3,2)+10, v2:indgen(3,5)+10}
  tplot2cdf, tvars='test_v12_time', filename='test_v12_time.cdf', /default
  get_data, 'test_v12_time', data=d_original
  del_data, '*'
  cdf2tplot, 'test_v12_time.cdf'
  get_data, 'test_v12_time', data=d
  assert, array_equal(d.X, d_original.X) && array_equal(d.y, d_original.y) && array_equal(d.v1, d_original.v1) && array_equal(d.v2, d_original.v2), 'Problem with saved by tplot2cdf variables'
  return, 1
end


pro spd_tplot2cdf_ut::setup
  del_data, '*'
end

function spd_tplot2cdf_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['tplot2cdf']
  return, 1
end

pro spd_tplot2cdf_ut__define
  define = { spd_tplot2cdf_ut, inherits MGutTestCase }
end