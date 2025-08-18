;+
; FUNCTION:
; 	 SECOFDAY
;
; DESCRIPTION:
;
; Function to return seconds of a day, given the time in hours, minutes, 
; seconds and milliseconds.
;
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    
;    ; set up a time (00:01:01.001)
;
;	hour = 0.
;	min = 1.
;	sec = 1.
;	msc = 1.
;
;    ; convert to seconds
;    
;	seconds = secofday(hour, min, sec, msc)
;    
;    ; print it out
;    
;	PRINT, seconds
;
; --- Sample output would be 
;    
;	61.001
;    
;
; NOTES:
;
;	If input seconds is an array, then an array of N_ELEMENTS(inputs vals) 
;	of date strings and remainders will be returned.
;
;	The number of array elements for all input parameters must be the same
;
; REVISION HISTORY:
;
;	@(#)secofday.pro	1.2 06/04/95 	
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Sep. '91
;
;	Revised to handle arrays of input values, JML, Jan. '92
;-

FUNCTION secofday, hour, min, sec, milsec

RETURN, hour*60.D*60.D + min*60.D + sec + DOUBLE(milsec/1000)

END

