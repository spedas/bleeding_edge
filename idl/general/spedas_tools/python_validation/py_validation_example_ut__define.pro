;+
;
; OBJECT:
;       py_validation_example_ut
;       
; PURPOSE:
;       This object is an example of using MGunit to build unit tests that validate Python code
; 
; NOTES:
;       To run:
;         IDL> mgunit, 'py_validation_example_ut'
;       
;       For the MMS validation tests, see:
;         projects/mms/common/tests/mms_python_validation_ut__define.pro
;         
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-10-08 10:37:39 -0700 (Thu, 08 Oct 2020) $
; $LastChangedRevision: 29225 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/python_validation/py_validation_example_ut__define.pro $
;-

; the individual unit tests are implemented as methods that start with "test_"
function py_validation_example_ut::test_example
  ; first run IDL code to produce some tplot variables
  store_data, 'tplot_variable', data={x: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], y: [0, 0, 1, 0, 0, 2, 2, 1, 0, 1]}
  
  ; next, create an array containing a script to run in Python that should produce the same variables as above
  pyscript = ["from pytplot import store_data", $
              "store_data('tplot_variable', data={'x': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 'y': [0, 0, 1, 0, 0, 2, 2, 1, 0, 1]})"]
              
  ; next, create an array containing the variables you would like to check
  vars = ['tplot_variable']
  
  ; the unit tests must return 1 if they pass, 0 if they fail
  ; spd_run_py_validation returns 1 if the variables in the array 'vars' match 
  ; in both IDL and Python, and 0 if differences are found
  ; note: for performance reasons, only N data points are checked, where N is specified
  ; by the points_to_check keyword (default: 10)
  ; the maximum difference is specified by the tolerance keyword (default: 1e-6)
  return, spd_run_py_validation(pyscript, vars)
end

; the setup procedure runs before each test runs
pro py_validation_example_ut::setup
  del_data, '*'
end

pro py_validation_example_ut__define
  define = { py_validation_example_ut, inherits MGutTestCase }
end