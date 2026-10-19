;+
;PROCEDURE:
;  srscan_test_skip
;
;PURPOSE:
;  Skip the current test: throws an error whose message carries this
;  routine's name, which the test runner (srscan_test_run) recognizes and
;  records as a SKIP rather than a FAIL. Use for tests whose
;  preconditions are absent (e.g. local test data not cached) so the
;  suite stays green on machines without the data.
;
;EXAMPLE:
;  if ~file_test(dir, /directory) then $
;    srscan_test_skip, 'test data not in local cache'
;-
pro srscan_test_skip, reason

  compile_opt idl2

  message, (n_elements(reason) gt 0) ? reason : 'precondition not met'
end
