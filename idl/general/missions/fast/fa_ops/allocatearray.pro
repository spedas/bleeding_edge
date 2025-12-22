;+
; FUNCTION:
; 	 ALLOCATEARRAY
;
; DESCRIPTION:
;
;	function to allocate an array of a given type and size.  The
; 	types are those defined for the FAST SDT to IDL interface.
;
; CALLING SEQUENCE:
;
; 	data = allocatearray (type, nDims, dim(3))
;
; ARGUMENTS:
;
;	type: Specifies the type of array to allocate:
;		1 = BYTE
;		2 = INT
;		3 = LONG
;		4 = FLOAT
;		5 = DOUBLE
;	nDims: gives the number of dimensions for the output array, 3 max.
;	dims(3): gives the size of each dimension.
;
; RETURN VALUE:
;
;	Upon success, the resulting array is returned, filled with 0's.
;	Upon failure, scaler INT is returned set to -1 
;
; REVISION HISTORY:
;
;	@(#)allocatearray.pro	1.1 06/15/95
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   June '95
;-


FUNCTION Allocatearray, type, nDims, dim

   ; check that there are enough elements in dim:

   IF N_ELEMENTS (dim) LT nDims THEN RETURN, -1
   
   ; first get the total dimension size we will need.  We will first
   ; allocate the array as 1-D, and the reform it.
   
   totalDimSize = 1

   FOR i = 0, nDims-1 DO BEGIN
      totalDimSize = totalDimSize * dim(i)
   ENDFOR

   ; allocate the array

   CASE type OF
      0: RETURN, -1
      1: ret = BYTARR (totalDimSize)
      2: ret = INTARR (totalDimSize)
      3: ret = LONARR (totalDimSize)
      4: ret = FLTARR (totalDimSize)
      5: ret = DBLARR (totalDimSize)
      ELSE: RETURN, -1
   ENDCASE

   ; redim return array
   
   CASE nDims OF
      0: RETURN, -1
      1: ret = REFORM (ret, dim(0))
      2: ret = REFORM (ret, dim(0), dim(1))
      3: ret = REFORM (ret, dim(0), dim(1), dim(2))
      ELSE: RETURN, -1
   ENDCASE
   
   ; done

   RETURN, ret

END

