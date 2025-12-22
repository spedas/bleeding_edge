;+
; FUNCTION: FA_NADIR_FROM_HORIZ
;
; PURPOSE:
;	Calculate the earth nadir from horizon crossing times for FAST.
;
; CALLING SEQUENCE:
;	nadir = fa_nadir_from_horiz (horizCross, orbData)
; 
; INPUTS:
;	horizCross:	And array of the structure: 
;			{setime: double, estime: double}, where setime
;			and estime are seconds since 1970.  These are
;			the horizon crossing times.
;	orbData:	The orbit data from get_fa_orbit that covers
;			the times given in horizCross.
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;	nadir:		The array of earth nadir times derived.
;
; MODIFICATION HISTORY:
;	@(#)fa_nadir_from_horiz.pro	1.1 02/12/98
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Oct '97
;-

FUNCTION fa_nadir_from_horiz, horizCross, orbData

   ; (For now we, will take this as the mid angle)

RETURN, (horizCross.setime + horizCross.estime)/2.

END
