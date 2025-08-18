;+
;function: spd_array_equal_nan
;purpose: works like the IDL array_equal function
;   But checks that dimensions match and doesn't get tricked by NANs
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-07-27 09:49:59 -0700 (Mon, 27 Jul 2015) $
; $LastChangedRevision: 18272 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/test_support_routines/spd_array_equal_nan.pro $
;-


function spd_array_equal_nan,array1,array2


  ;dimensions not equal
  if ~array_equal(dimen(array1),dimen(array2)) then return,0
  
  ;find nans and not nans
  idx1 = where(finite(array1,/nan),comp=c1,ncomp=nc1)
  idx2 = where(finite(array2,/nan),comp=c2)
  
  ;nans not at same place
  ;If pass, this implies that all not-nans are at same place
  ;and have same number(since they're the complement of nan places)
  if ~array_equal(idx1,idx2) then return,0

  ;if any non nans, check that they're equal 
  if nc1 gt 0 && ~array_equal(array1[c1],array2[c2]) then return,0

  return,1

end