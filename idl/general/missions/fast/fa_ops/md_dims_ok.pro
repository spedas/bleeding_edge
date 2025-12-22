;+
; FUNCTION:
; 	 MD_DIMS_OK
;
; DESCRIPTION:
;
;
;	function to check that the array descriptors have the correct
;	number of elements.  This function assumes that all dimensions
;	should have array descriptors.
;
;	
; CALLING SEQUENCE:
;
; 	ok = md_dims_ok(dat)
;
; ARGUMENTS:
;
;	dat		the structure returned from the
;			get_md_from_sdt routine.
;
; RETURN VALUE:
;
;	Upon success, 1 is returned, else 0
;
; REVISION HISTORY:
;
;	@(#)md_dims_ok.pro	1.1 09/04/96
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Sep. '96
;-

FUNCTION md_dims_ok, dat

        ; check each array descriptor array for the correct number of
        ; elements

	IF dimen1 (dat.min1) NE dat.dimsizes (0) OR              $
           dimen1 (dat.max1) NE dat.dimsizes (0) THEN  RETURN, 0

	IF (dat.ndims GE 2) AND                                      $
           ((dimen1 (dat.min2) NE dat.dimsizes (1)) OR           $
           (dimen1 (dat.max2) NE dat.dimsizes (1))) THEN  RETURN, 0

	IF (dat.ndims EQ 3) AND                                      $
	   ((dimen1 (dat.min3) NE dat.dimsizes (2)) OR           $
           (dimen1 (dat.max3) NE dat.dimsizes (2))) THEN  RETURN, 0

        RETURN, 1
END

            
