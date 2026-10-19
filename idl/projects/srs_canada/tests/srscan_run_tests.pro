;+
;PROCEDURE:
;  srscan_run_tests
;
;PURPOSE:
;  Run the srs_canada test suite and print a PASS/FAIL/SKIP line per
;  test plus a summary. Tiers:
;    offline: TREx RGB pure-logic tests, no network and no data cache
;    data:    TREx RGB loader tests against the local cache for the
;             reference night 2023-03-24 (run with /no_download; tests
;             SKIP when the needed dataset is not cached)
;    network: riometer HAPI server tests through hapi_load_data (opt-in
;             via /network; tests SKIP when the server is unreachable)
;  By default nothing touches the network, so the suite is deterministic
;  and safe to run anywhere.
;
;KEYWORDS:
;  offline_only: run only the pure-logic tests
;  data_only:    run only the cache-backed loader tests
;  network:      also run the HAPI server tests (combines with
;                /offline_only or /data_only)
;  network_only: run only the HAPI server tests
;  exit_status:  exit IDL when done with status 0 (all passed) or 1
;                (failures), for batch/CI runs. CAUTION: Windows IDL
;                does not honor EXIT's STATUS keyword (observed: always
;                exit code 3, IDL 9.0) -- on Windows check the
;                'RESULT: PASS/FAIL' line instead, or have the batch
;                command write nfail= to a file (batch IDL on Windows
;                can also drop the last buffered stdout lines at exit,
;                so a results file is the most reliable option)
;  npass, nfail, nskip, failed: (out) totals from srscan_test_run
;
;EXAMPLES:
;  IDL> srscan_run_tests
;  IDL> srscan_run_tests, /offline_only
;  IDL> srscan_run_tests, /network_only
;  batch: idl -e "srscan_run_tests, /exit_status"
;
;NOTES:
;  Future instrument suites (THEMIS ASI, REGO, ...) can plug in here as
;  extra test-list functions; the runner (srscan_test_run) is generic.
;  The HAPI server URL comes from srscan_api_config (hapi_url), so
;  SRSCAN_API_URL also points the network tier at a staging server.
;-
pro srscan_run_tests, offline_only = offline_only, data_only = data_only, $
  network = network, network_only = network_only, exit_status = exit_status, $
  npass = npass, nfail = nfail, nskip = nskip, failed = failed

  compile_opt idl2

  if ~keyword_set(network_only) then begin
    if ~keyword_set(data_only) then tests = srscan_trex_rgb_test_offline()
    if ~keyword_set(offline_only) then begin
      dtests = srscan_trex_rgb_test_data()
      tests = undefined(tests) ? dtests : [tests, dtests]
    endif
  endif
  if keyword_set(network) || keyword_set(network_only) then begin
    ntests = srscan_hapi_test_network()
    tests = undefined(tests) ? ntests : [tests, ntests]
  endif

  srscan_test_run, tests, title = 'srs_canada', $
    npass = npass, nfail = nfail, nskip = nskip, failed = failed

  if keyword_set(exit_status) then begin
    flush, -1
    exit, status = (nfail gt 0) ? 1 : 0
  endif
end
