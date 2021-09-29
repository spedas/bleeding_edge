;+
;
; Unit tests for thm_python_validation_ut
;
; To run:
;     IDL> mgunit, 'thm_python_validation_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-04-13 12:16:00 -0700 (Mon, 13 Apr 2020) $
; $LastChangedRevision: 28565 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/tests/thm_python_validation_ut__define.pro $
;-

function thm_python_validation_ut::test_fgm_l2_default
  thm_load_fgm, probe='c', level='l2'
  spawn, self.py_exe_dir+'python -m pyspedas.themis.tests.validation.fgm', output

  get_data, 'thc_fgs_dsl', data=d
  assert, self.compare(d.y[20000, *], self.str_to_arr(output[-1])), 'Problem with THEMIS FGM'
  assert, self.compare(d.y[10000, *], self.str_to_arr(output[-2])), 'Problem with THEMIS FGM'
  assert, self.compare(d.y[5000, *], self.str_to_arr(output[-3])), 'Problem with THEMIS FGM'
  assert, self.compare(d.y[1000, *], self.str_to_arr(output[-4])), 'Problem with THEMIS FGM'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-5])), 'Problem with THEMIS FGM'
  
  return, 1
end

function thm_python_validation_ut::test_dsl2gse
    thm_load_state, probe='a', /get_support_data 
    thm_load_fgm, level='l2', probe='a'
    dsl2gse, 'tha_fgs_dsl', 'tha_state_spinras', 'tha_state_spindec', 'tha_fgs_gse_cotrans'
    spawn, self.py_exe_dir+'python -m pyspedas.themis.tests.validation.dsl2gse', output
    
    get_data, 'tha_fgs_gse_cotrans', data=d
    
    assert, self.compare(d.y[20000, *], self.str_to_arr(output[-1])), 'Problem with THEMIS dsl2gse'
    assert, self.compare(d.y[10000, *], self.str_to_arr(output[-2])), 'Problem with THEMIS dsl2gse'
    assert, self.compare(d.y[5000, *], self.str_to_arr(output[-3])), 'Problem with THEMIS dsl2gse'
    assert, self.compare(d.y[1000, *], self.str_to_arr(output[-4])), 'Problem with THEMIS dsl2gse'
    assert, self.compare(d.x[0:9], self.str_to_arr(output[-5])), 'Problem with THEMIS dsl2gse'
  return, 1
end

function thm_python_validation_ut::compare, idl_result, py_result
  notused = where(abs(idl_result-py_result) ge 1e-6, bad_count)
  return, bad_count eq 0 ? 1 : 0
end

; converts an array stored in a string to an actual array
function thm_python_validation_ut::str_to_arr, str
  return, strsplit(strmid(str[-1], 1, strlen(str[-1])-2), ', ', /extract)
end

;; the following are for debugging/developing the tests
;function compare, idl_result, py_result
;  notused = where(abs(idl_result-py_result) ge 1e-6, bad_count)
;  return, bad_count eq 0 ? 1 : 0
;end
;; converts an array stored in a string to an actual array
;function str_to_arr, str
;  return, strsplit(strmid(str[-1], 1, strlen(str[-1])-2), ', ', /extract)
;end

pro thm_python_validation_ut::setup
  del_data, '*'
  timespan, '2007-3-23', 1, /day
  self.py_exe_dir = '/Users/eric/anaconda3/bin/'
  ; the pyspedas package is installed in my ~/pyspedas folder
  cd, 'pyspedas'
end

pro thm_python_validation_ut::teardown
  cd, ''
end
pro thm_python_validation_ut__define
  define = { thm_python_validation_ut, inherits MGutTestCase, py_exe_dir: '' }
end