;+
; PROCEDURE:
;     mms_run_all_tests
;     
; PURPOSE
;     Run all the unit tests for the MMS load routines
;
;
;     
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-01-22 12:01:22 -0800 (Tue, 22 Jan 2019) $
; $LastChangedRevision: 26491 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_run_all_tests.pro $
;-

pro mms_run_all_tests
    test_suites = ['mms_cdf2tplot_ut', $
                   'mms_cotrans_ut', $
                   'mms_load_data_ut', $
                   'mms_load_fgm_ut', $
                   'mms_load_hpca_ut', $
                   'mms_load_state_ut', $
                   'mms_load_fpi_ut', $
                   'mms_load_scm_ut', $
                   'mms_load_eis_ut', $
                   'mms_load_edp_ut', $
                   'mms_load_dsp_ut', $
                   'mms_load_mec_ut', $
                   'mms_load_feeps_ut', $
                   'mms_load_edi_ut', $
                   'mms_load_aspoc_ut', $
                   ;'mms_part_products_ut', $
                   'mms_part_getspec_ut', $
                   'mms_pgs_regressions_ut', $
                   'mms_load_coverage_ut', $
                   'mms_load_brst_segments_ut', $
                   'mms_load_fast_segments_ut', $
                   'mms_file_filter_ut', $
                   'mms_init_ut', $
                   'mms_curlometer_ut', $
                   'mms_flipbookify_ut', $
                   'mms_part_slice2d_ut', $
                   'flatten_spectra_ut', $
                   'tplot_stuff_ut']
    
    file_out =   'mms_tests_output_'+time_string(systime(/sec), tformat='YYYYMMDD_hhmm')+'.txt'
    
    mgunit, test_suites, filename=file_out, nfail=nfail, npass=npass, nskip=nskip
    
    console_out = '('+strcompress(string(npass), /rem)+' passed, '+strcompress(string(nfail), /rem)+$
      ' failed, '+strcompress(string(nskip), /rem)+ ' skipped)'
      
    if nfail ne 0 then begin
        dprint, dlevel = 0, 'Error! Problems found while running the testsuite! '+console_out
        ; need 32-bit IDL 8.5 and send_test_notify.py to send an email via python
        if !version.release ge 8.5 && !version.arch eq 'x86' then begin
            sendemail = Python.Import('send_test_notify')
            sent = sendemail.send_test_notify('egrimes@igpp.ucla.edu', 'Problems found while testing', console_out)
        endif
    endif else begin
        dprint, dlevel = 1, 'Done testing! No problems found '+console_out
    endelse
end