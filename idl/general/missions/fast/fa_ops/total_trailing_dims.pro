;+
; FUNCTION: total_trailing_dims
;
; PURPOSE: totals the input array over all dimensions other than the first
;
; INPUT:
;     array:
;         any numerical input array
;
; OUTPUT:
;     return value:
;         1 dimensional array of size equal to the first dimension of 'array',
;         formed by summing 'array' over all other dimensions.
;
; EXAMPLE:
;     IDL> x = [[1,2],[3,4]]     
;     IDL> y = total_trailing_dims(x)
;
;     Then y will equal the array [4.0, 6.0].
;
; VERSION: @(#)total_trailing_dims.pro	1.1 03/16/97
;-


; if value is 1-dimensional, return it
; if value has more than one dimension, total the array over all but the first dimension
; and return the result.
; return value will always be 1-dimensional with size equal to the first dimen of value
function total_trailing_dims, value
result = reform(value)
while ndimen(result) gt 1 do result = reform(total(result,2))
return, result
end

