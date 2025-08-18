;+
;procedure: spd_end_tests
;
; purpose: Terminates testscript
;
;Clears memory in which test output is stored
;and prints the test result to the screen.
;
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-07-27 10:17:12 -0700 (Mon, 27 Jul 2015) $
; $LastChangedRevision: 18283 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/test_support_routines/spd_end_tests.pro $
;-
pro spd_end_tests

compile_opt idl2

print,"-------------------------------------"
print,"Begin Error Report"

outputs = csvector(0,!output,/read)

tmp = csvector(!output,/free)

for i=0,csvector(outputs,/len)-1L do print,csvector(i,outputs,/read)

print,"-------------------------------------"
print,"End Error Report"

tmp = csvector(outputs,/free)

end