;+
;function: spd_data_exists
;
; purpose: Checks to see if a tplot variable exists and if its data passes some minimum tests 
;
;
; set dims to assert the number of dimensions of y (ie dims = 3 implies 3 dimensional vector)
; setting dims means if n_elements(size(d.y,/dimensions)) gt 2 it returns 0
; if you pass multiple names it will return 0 if any of the tests are failed or they don't exist
; if you use globbing it will return 0 if a data type matches your glob, but fails one of the tests
; but it cannot be sure that all the datatypes you expect the glob to match necessarily exist
;
;
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-07-27 09:56:49 -0700 (Mon, 27 Jul 2015) $
; $LastChangedRevision: 18279 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/test_support_routines/spd_data_exists.pro $
;-

function spd_data_exists,tvarname,start_time,end_time,dims=dims

  compile_opt idl2

  ;function deprecated, calls duplicate version
  return,tdexists(tvarname,start_time,end_time,dims=dims)
  
end

