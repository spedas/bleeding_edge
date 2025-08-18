;Returns 1 if two arrays are equal within a specified tolerance.
;Returns 0 if two arrays are not equal or have different dimensions.
;Written by Dillon Wong.  Last Modified May 25, 2010.

function equal_arrays,array1,array2,tolerance=tolerance,silence=silence,ignore=ignore

if NOT keyword_set(tolerance) then tolerance=0.

if NOT keyword_set(ignore) then begin
	
	size_of_array1=size(array1,/dimensions)
	size_of_array2=size(array2,/dimensions)
	
	dimensions1=n_elements(size_of_array1)
	dimensions2=n_elements(size_of_array2)
	
	if dimensions1 EQ dimensions2 then begin
		if (where((size_of_array1-size_of_array2) NE 0))[0] NE -1 then begin
			if NOT keyword_set(silence) then print,'Dimensions do not agree!'
			return,0
		endif
	endif else begin
		if NOT keyword_set(silence) then print,'Dimensions do not agree!'
		return,0
	endelse
	
endif

if (where(abs(array1-array2) GT tolerance))[0] EQ -1 then return,1 else return,0

end