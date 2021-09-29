;+
;
; Unit tests for generla function base on mgunit 
;
; see more ditales here: http://michaelgalloy.com/wp-content/uploads/2013/11/testing-with-idl.pdf
; or here: github.com/mgalloy/mgunit
;
; To run:
;     IDL> mgunit, 'general_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2017-12-22 00:18:46 -0800 (Fri, 22 Dec 2017) $
; $LastChangedRevision: 24455 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/mgunit/general_ut__define.pro $
;-

; --- find_nearest_neighbor2 test---
function general_ut::test_find_nearest_neighbor2_basic
  assert, find_nearest_neighbor2([1,2,3,4,5,6,7,8,9], 4.6) eq 5, 'find_nearest_neighbor2 returns wrong time'
  assert, find_nearest_neighbor2([5,4,3,7,8,2,4,6,7], 7.6, /sort) eq 8, 'find_nearest_neighbor2 experience a problem with sorting'
  return, 1
end

function general_ut::test_find_nearest_neighbor2_vs_find_nearest_neighbor_random
  a  = DINDGEN(1000)
  a0 =  RANDOMU(systime(1),  /DOUBLE)*(1000-1)
  assert, find_nearest_neighbor(a, a0) eq find_nearest_neighbor2(a, a0)  , 'Results of find_nearest_neighbor2 != find_nearest_neighbor'
  return, 1
end

function general_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  return, 1
end

pro general_ut__define
  define = { general_ut, inherits MGutTestCase }
end