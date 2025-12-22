;+
; PROCEDURE:
;        HEAD.PRO
;
; DESCRIPTION:
;
;       Procedure to print out the head (first few elements) of an array.
;
; USAGE:
; 
; 	HEAD, input_array, [NUMBER=number-of-initial-elements]
;
; ARGUMENTS:
;	input_array 	The array to print.
;
; KEYWORDS:
;	NUMBER		The number if array elements to print.
;
; REVISION HISTORY:
;
;	@(#)head.pro	1.1 06/04/95
;       Originally written by Terry Slocum,  University of 
;       California at Berkeley, Space Sciences Lab.   Sep. '91
;
;-
 
PRO Head, array, number=number

if (keyword_set(number)) then number = number else number = 3

print, array(0:number-1)

end

