;+
; PROCEDURE:
;        TAIL.PRO
;
; DESCRIPTION:
;
;       Procedure to print out the tail (last few elements) of an array.
;
; USAGE:
; 
; 	TAIL, input_array, [NUMBER=number-of-final-elements]
;
; ARGUMENTS:
;	input_array 	The array to print.
;
; KEYWORDS:
;	NUMBER		The number if array elements to print.
;
; REVISION HISTORY:
;
;	@(#)tail.pro	1.1 06/04/95
;       Originally written by Terry Slocum,  University of 
;       California at Berkeley, Space Sciences Lab.   Sep. '91
;
;-

proc tail, array, number = number

if (keyword_set(number)) number = number else number = 3

size = n_elements(array)
print, array(size-number:size-1)

end


