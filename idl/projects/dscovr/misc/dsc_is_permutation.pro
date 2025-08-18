;+
;NAME: DSC_IS_PERMUTATION
;
;DESCRIPTION:
; Returns !TRUE if ARR2 is a permutation of the elements of ARR1
; ARR1 must be a STR or (INT/LONG), non-empty array with unique values.
;
;INPUT:
; ARR1,ARR2:  Arrays to compare.  (STR or INT/LONG) 
;
;KEYWORDS: (NONE)
;
;OUTPUTS: 
; Returns BOOLEAN
;
;EXAMPLE:
; a = [4,2,6,7]
; b = [7,2,6,4]
; c = [3,2,7,2]
; dsc_is_permutation(a,b)
;   ==> true
; dsc_is_permutation(a,c)
;   ==> false
;   
;CREATED BY: Ayris Narock (ADNET/GSFC) 2018
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_is_permutation.pro $
;-

FUNCTION DSC_IS_PERMUTATION,ARR1,ARR2
	compile_opt idl2
	
	if isa(arr1,'UNDEFINED') || ~(isa(arr1,/array,/str) || isa(arr1,/array,/int)) || (arr1.length eq 0) || $
		 isa(arr2,'UNDEFINED') || ~(isa(arr2,/array,/str) || isa(arr2,/array,/int)) || (arr2.length eq 0) then return,!FALSE
	
	if isa(arr1,/int) then arr1 = long(arr1)
	if isa(arr2,/int) then arr2 = long(arr2)
	if (size(arr1,/type) ne size(arr2,/type)) || (arr1.length ne arr2.length) then return,!FALSE
	a1sort = arr1[sort(arr1)]
	a2sort = arr2[sort(arr2)]
	r = where(a1sort eq a2sort,count)
	if count ne arr1.length then return,!FALSE else return,!TRUE
END