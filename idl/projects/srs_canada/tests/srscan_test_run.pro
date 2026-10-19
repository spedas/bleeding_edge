;+
;PROCEDURE:
;  srscan_test_run
;
;PURPOSE:
;  Minimal, dependency-free test runner for the srs_canada project.
;  Takes a list of test PROCEDURE names, runs each under a CATCH
;  handler, and prints one PASS/FAIL/SKIP line per test plus a summary.
;
;  A test fails by throwing any error -- normally via srscan_test_assert.
;  A test skips by calling srscan_test_skip (unmet precondition, e.g.
;  local test data not cached). A test that returns normally passes.
;
;  The runner is deliberately generic (nothing TREx-specific): suites
;  for other instruments (THEMIS ASI, REGO, ...) can reuse it as-is by
;  passing their own test lists.
;
;INPUT:
;  tests: string array of test procedure names
;
;KEYWORDS:
;  title:  label used in the banner/summary lines
;  npass:  (out) number of tests passed
;  nfail:  (out) number of tests failed
;  nskip:  (out) number of tests skipped
;  failed: (out) names of the failed tests ('' if none)
;
;EXAMPLE:
;  srscan_test_run, srscan_trex_rgb_test_offline(), title = 'TREx RGB offline'
;-
pro srscan_test_run, tests, title = title, npass = npass, nfail = nfail, $
  nskip = nskip, failed = failed

  compile_opt idl2

  npass = 0 & nfail = 0 & nskip = 0
  failed = ''
  nt = n_elements(tests)
  if ~keyword_set(title) then title = 'srscan tests'
  print, '=== ' + title + ': running ' + strtrim(nt, 2) + ' test(s) ==='

  for i = 0, nt - 1 do begin
    t = tests[i]
    tstart = systime(/seconds)

    catch, err
    if err ne 0 then begin
      catch, /cancel
      emsg = !error_state.msg
      if strpos(emsg, 'SRSCAN_TEST_SKIP') ge 0 then begin
        nskip += 1
        print, 'SKIP: ' + t + ' -- ' + emsg
      endif else begin
        nfail += 1
        if failed[0] eq '' then failed = [t] else failed = [failed, t]
        print, 'FAIL: ' + t + ' -- ' + emsg
      endelse
      continue
    endif

    call_procedure, t
    catch, /cancel

    npass += 1
    print, 'PASS: ' + t + '  (' + $
      string(systime(/seconds) - tstart, format = '(f0.1)') + ' s)'
  endfor

  print, '=== ' + title + ': ' + strtrim(npass, 2) + ' passed, ' + $
    strtrim(nfail, 2) + ' failed, ' + strtrim(nskip, 2) + ' skipped ==='
  if nfail gt 0 then begin
    print, 'FAILED tests: ' + strjoin(failed, ' ')
    print, 'RESULT: FAIL'
  endif else print, 'RESULT: PASS'
end
