FUNCTION datesec_doy, yr, doy
;+
; FUNCTION:
; 	 DATESEC_DOY
;
; DESCRIPTION:
;
; 	take args for year and day of year and return 
;	(double float) seconds since 1 Jan 1970, 00:00 UT.
;
; USAGE:
; 
;    	print, datesec_doy(75, 134)
;    
;	gives result:
;	 1.6925760e+08
;
; NOTES:
;	does not handle years past 1999; year must be two digit.
;
; REVISION HISTORY:
;
;	@(#)datesec_doy.pro	1.3 01/26/99
; 	written by Ken Bromund, Space Sciences Lab, Berkeley.  May, 1991
;-

IF yr LT 70 THEN yr = yr + 100
WHILE yr GE 200 DO yr = yr - 100
return, (doy-1 + (yr - 70) * 365 + fix((yr - 69) / 4))*86400.d

end
