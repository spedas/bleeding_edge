;+
;
; Unit tests for tplot_add_cdf_structure
;
; To run:
;     IDL> mgunit, 'spd_tplot_add_cdf_structure_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-03-05 19:24:23 -0800 (Mon, 05 Mar 2018) $
; $LastChangedRevision: 24832 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/mgunit/spd_tplot_add_cdf_structure_ut__define.pro $
;-

function spd_tplot_add_cdf_structure_ut::test_cdf
  store_data, 'test_xy', data={x: double(1), y: indgen(1)}
  tplot_add_cdf_structure, 'test_xy'
  get_data, 'test_xy', limits=s
  assert, ~undefined(s.CDF), 'No CDF structure'
  assert, ~undefined(s.CDF.DEPEND_0) && ~undefined(s.CDF.VARS), 'No CDF fields' 
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_v
  store_data, 'test_xyv', data={x: double(indgen(2)), y: indgen(2,2)}
  tplot_add_cdf_structure, 'test_xyv'
  get_data, 'test_xyv', limits=s, data=d  
  assert, ~undefined(s.CDF.DEPEND_1), 'No DEPEND_1 CDF field'
  assert, ~undefined(d.v), 'No v created'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_v12
  store_data, 'test_xyv12', data={x: double(indgen(2)), y: indgen(2,2,2)}
  tplot_add_cdf_structure, 'test_xyv12'
  get_data, 'test_xyv12', limits=s, data=d
  assert, ~undefined(s.CDF.DEPEND_1) && ~undefined(s.CDF.DEPEND_2), 'No DEPENDs CDF field'
  assert, ~undefined(d.v1) && ~undefined(d.v2), 'No v#'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_v123
  store_data, 'test_xyv123', data={x: double(indgen(2)), y: indgen(2,2,2,2)}
  tplot_add_cdf_structure, 'test_xyv123'
  get_data, 'test_xyv123', limits=s, data=d
  assert, ~undefined(s.CDF.DEPEND_1) && ~undefined(s.CDF.DEPEND_2) && ~undefined(s.CDF.DEPEND_3), 'No DEPENDs CDF field'
  assert, ~undefined(d.v1) && ~undefined(d.v2) && ~undefined(d.v3), 'No v#'
  return, 1
end
function spd_tplot_add_cdf_structure_ut::test_v_epoch
  store_data, 'test_v_epoch', data={x: double(indgen(2)), y: indgen(2,2), v:indgen(2,2)}
  tplot_add_cdf_structure, 'test_v_epoch'
  get_data, 'test_v_epoch', limits=s, data=d
  assert, ~undefined((*(s.CDF.DEPEND_1.ATTRPTR)).DEPEND_0), 'No Epoch in v attribues'  
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_v123_epoch
  store_data, 'test_v123_epoch', data={x: double(indgen(2)), y: indgen(2,2,2,2,2), v1:indgen(2,2), v2:indgen(2,2), v3:indgen(2,2)}
  tplot_add_cdf_structure, 'test_v123_epoch'
  get_data, 'test_v123_epoch', limits=s, data=d
  assert, ~undefined((*(s.CDF.DEPEND_1.ATTRPTR)).DEPEND_0), 'No Epoch in v1 attribues'
  assert, ~undefined((*(s.CDF.DEPEND_2.ATTRPTR)).DEPEND_0), 'No Epoch in v2 attribues'
  assert, ~undefined((*(s.CDF.DEPEND_3.ATTRPTR)).DEPEND_0), 'No Epoch in v3 attribues'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_tt2000
  store_data, 'test_tt2000', data={x: CDF_PARSE_TT2000('2005-12-04T20:19:18.176214648') }
  tplot_add_cdf_structure, 'test_tt2000', /tt2000
  get_data, 'test_tt2000', limits=s, data=d  
  assert, size(d.x,/type) eq 14, 'TT2000 Epoch is not LONG64'
  assert, s.CDF.VARS.DATATYPE eq 'CDF_TIME_TT2000', 'Wrong TT2000 datatype'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_tt2000_double
  store_data, 'test_tt2000_double', data={x: double(indgen(2)) }
  tplot_add_cdf_structure, 'test_tt2000_double', /tt2000
  get_data, 'test_tt2000_double', limits=s, data=d
  assert, size(d.x,/type) eq 14, 'TT2000 Epoch is not converted from double to LONG64'
  assert, s.CDF.VARS.DATATYPE eq 'CDF_TIME_TT2000', 'Wrong TT2000 datatype'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_tt2000_double_and_vars
  store_data, 'test_tt2000_double_and_vars1', data={x: double(indgen(2)), y:double(indgen(2)+10)}
  get_data, 'test_tt2000_double_and_vars1', data=original_d    
  tplot_add_cdf_structure, 'test_tt2000_double_and_vars1', /tt2000  
  get_data, 'test_tt2000_double_and_vars1', data=d
  assert, size(d.x,/type) eq 14, 'TT2000 Epoch is not converted from double to LONG64'
  assert, ARRAY_EQUAL(d.y,original_d.y), 'TT2000 flag does not trasfer the data'
  
  store_data, 'test_tt2000_double_and_vars2', data={x: double(indgen(2)), y:double(indgen(2,3)+10), v:indgen(3)}
  get_data, 'test_tt2000_double_and_vars2', data=original_d
  tplot_add_cdf_structure, 'test_tt2000_double_and_vars2', /tt2000
  get_data, 'test_tt2000_double_and_vars2', data=d
  assert, size(d.x,/type) eq 14, 'TT2000 Epoch is not converted from double to LONG64'
  assert, ARRAY_EQUAL(d.y,original_d.y) and ARRAY_EQUAL(d.v,original_d.v), 'TT2000 flag does not trasfer the data'
  
  store_data, 'test_tt2000_double_and_vars3', data={x: double(indgen(2)), y:double(indgen(2,3,4)+10), v1:indgen(3), v2:indgen(2,4)+5}
  get_data, 'test_tt2000_double_and_vars3', data=original_d
  tplot_add_cdf_structure, 'test_tt2000_double_and_vars3', /tt2000
  get_data, 'test_tt2000_double_and_vars3',  data=d
  assert, size(d.x,/type) eq 14, 'TT2000 Epoch is not converted from double to LONG64'
  assert, ARRAY_EQUAL(d.y,original_d.y) and ARRAY_EQUAL(d.v1,original_d.v1) and ARRAY_EQUAL(d.v2,original_d.v2), 'TT2000 flag does not trasfer the data'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_new
    del_data, '*'
    store_data, 'test_tt2000_new', data={x: double(indgen(2))}
    tplot_add_cdf_structure, 'test_tt2000_new'
    get_data, 'test_tt2000_new',  limits=s   
    assert, s.CDF.VARS.DATATYPE eq 'CDF_EPOCH', 'Unexpected type of Epoch'    
    store_data, 'test_tt2000_new', data={x: LONG64(indgen(2))}
    tplot_add_cdf_structure, 'test_tt2000_new', /tt2000, /new
    get_data, 'test_tt2000_new',  limits=s    
    assert, s.CDF.VARS.DATATYPE eq 'CDF_TIME_TT2000', 'CDF structure was not recreated'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_labl_ptr_1
  metadata = {units:'#', labels:['x','y','z'], ytitle:'3 components'}
  store_data, 'test_labl_ptr_1', data={x: time_double('2018-01-01')+[1, 2, 3], y: [[5,5,5],[6,6,6],[7,7,7]]}, dlimits=metadata
  tplot_add_cdf_structure, 'test_labl_ptr_1' 
  get_data, 'test_labl_ptr_1', alim=s, data=d

  assert, ARRAY_EQUAL(d.v, metadata.labels, /QUIET), 'Problem with v variable'  
  assert, ~undefined((*s.CDF.VARS.ATTRPTR).LABL_PTR_1), 'Problem with LABL_PTR_1'
  assert, (*s.CDF.VARS.ATTRPTR).UNITS eq metadata.units, 'Problem with units in attrptr'
  assert, (*s.CDF.VARS.ATTRPTR).LABLAXIS eq metadata.ytitle, 'Problem with ytitle in attrptr'
  return, 1
end



pro spd_tplot_add_cdf_structure_ut::setup
  del_data, '*'
end

function spd_tplot_add_cdf_structure_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['tplot_add_cdf_structure']
  return, 1
end

pro spd_tplot_add_cdf_structure_ut__define
  define = { spd_tplot_add_cdf_structure_ut, inherits MGutTestCase }
end