;+
; Driver to test MMS sitl_tools.
; May be used for nightly CI testing or on personal workstation if the
; IDL_PATH is configured to include all dependent files.
; 
; To execute from shell, use testing_script.pro.
; 
; :Keywords:
;    VERBOSE : in, optional, type=boolean
;        If set, tests will generate more output.  Defaults to FALSE.
;
; :Examples:
;    run_idl_tests
; 
; :Author:
;    Alexia Newgord, Nicholas Lindholm, Ed Hartnett, Taylor Graham
;-
pro run_idl_tests, VERBOSE=VERBOSE, FORMAL_TESTING=FORMAL_TESTING
  if KEYWORD_SET(verbose) eq 0 then defsysv, '!VERBOSE', 0 else defsysv, '!VERBOSE', 1

  start=systime(1)
  if keyword_set(verbose) then print, "ROUTINE INFO - ", ROUTINE_INFO(/SOURCE)
  mgunit, 'testsuite_uts', nfail=nfail, filename=['sitl_tools_junit.xml', '', 'sitl_tools_coverage.xml'], runners=['MGutJunitRunner', 'MGutCliRunner', 'MGutCoberturaRunner']
  elapsed=systime(1)-start
  print, "TIME ELAPSED - " + strcompress(elapsed/60) + " minutes"

  ; fail the build by returning a non-zero exit code.
  print, 'All tests were run'
  if keyword_set(FORMAL_TESTING) then begin
    if nfail gt 0 then exit, status=1
  endif
end
