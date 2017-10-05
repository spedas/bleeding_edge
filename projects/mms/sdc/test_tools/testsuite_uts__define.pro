; docformat = 'rst'

;+
; Initialize object, adding all test cases.
;
; :Returns:
;   1 for success, 0 for failure
;
; :Keywords:
;   _extra : in, optional, type=keywords
;     keywords to `MGutTestSuite::init`
;-
function testsuite_uts::init, _extra=e
  compile_opt strictarr
  
  if (~self->mguttestsuite::init(_strict_extra=e)) then return, 0
  
  self->add, /all
  ; single fast test for debugging
  ; self->add, ['parse_records_ut']
  
  self->addTestingFolder, [ '..' ]
  
  return, 1
end


;+
; Define the test suite.
;-
pro testsuite_uts__define
  compile_opt strictarr
  
  define = { testsuite_uts, inherits MGutTestSuite }
end
