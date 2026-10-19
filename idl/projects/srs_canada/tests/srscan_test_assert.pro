;+
;PROCEDURE:
;  srscan_test_assert
;
;PURPOSE:
;  Minimal assertion for the srs_canada test suite: if condition is not
;  true, throw an error (via MESSAGE) that the test runner
;  (srscan_test_run) catches and records as a FAIL for the current test.
;
;INPUT:
;  condition: scalar truth value (arrays: element 0 is tested; combine
;             array comparisons with array_equal/total first)
;  msg:       description of what was being asserted, shown on failure
;
;EXAMPLE:
;  srscan_test_assert, n_elements(x) eq 3, 'expected 3 files'
;-
pro srscan_test_assert, condition, msg

  compile_opt idl2

  ok = 0b
  if n_elements(condition) gt 0 then ok = condition[0] ne 0
  if ~ok then begin
    m = (n_elements(msg) gt 0) ? msg : 'condition false'
    message, 'assertion failed: ' + m
  endif
end
