;+
;procedure: spd_init_tests
;
; purpose: Intialize testscript
;
;Mainly sets up the variable in which test output will be stored
;
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2015-09-22 10:54:23 -0700 (Tue, 22 Sep 2015) $
; $LastChangedRevision: 18872 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/test_support_routines/spd_init_tests.pro $
;-

pro spd_init_tests

outputs = csvector('')

DEFSYSV,'!output',csvector(outputs)

; set up system variable for SPEDAS if not already set
defsysv, '!spedas', exists=exists
if not(exists) then spedas_init

end

