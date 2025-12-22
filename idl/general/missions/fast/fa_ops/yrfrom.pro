;+
; FUNCTION:
; 	 YRFROM
;
; DESCRIPTION:
;
;	 Function to build an array of strings of the format:
; 
;	'YR-1-1' 
;
;	given a start time in seconds since 1970.  
;
;	The date in each string increases monotonically, in one year
;	increments for the number of strings requested, from the 
;	start time given.
;
; 	Input parameters are the time to start the strings in seconds 
;	since 1970, Jan 1, 00:00, and the number of strings to output.
;
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    ; set an array of strings to month and year date representions
;
;	date_strings = yrfrom(16156800.0,8)       ; 8 dates starting at 
;                                                 ; 7 Jul 1970 0:0:0.00
;    ; output result
;
;	PRINT, date_strings
;
; --- Sample output would be
;
;	70-1-1 71-1-1 72-1-1 73-1-1 74-1-1 75-1-1 76-1-1 77-1-1
;
; NOTES:
;
; 	The start time in seconds is normally a float type, though
;	this isn't necessary.
;
;	If the input start time is negitive, this is an error, and the string
;	'ERROR' is returned.
;
;	If an array of start times is given, then a two dimensional array
;	of dimensions (n_dates,N_ELEMENTS(inputs vals)) of stings will 
;	be returned.
;
;	This routine calls the function "secdate".
;
; REVISION HISTORY:
;
;	@(#)yrfrom.pro	1.3 08/18/95 	
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Feb. '92
;
;-


FUNCTION yrfrom,start_time,n_strings

; set up error break

;ON_ERROR, 2

; check for validity of input (all input values GE 0.)

IF (WHERE(start_time LT 0.))(0) NE -1 THEN    RETURN, 'ERROR' 

; set up output buf

output = STRARR(n_strings,N_ELEMENTS(start_time))

; Now loop through all input values

FOR i=0,N_ELEMENTS(start_time)-1 DO BEGIN

;     get start yr

	year = FIX(STRMID(secdate(start_time(i),/FMT),7,2)) 

;     Now loop through selected for number of dates

	FOR j=0, n_strings-1 DO BEGIN
		output(j,i) = STRCOMPRESS(STRTRIM(STRING(year) + '-1-1',2) $
		,REMOVE_ALL=1)
		year = year + 1
		IF year GE 100 THEN year = year - 100
	ENDFOR

ENDFOR                                  ; main loop

RETURN, output                          ; normal return

END                                     ; YRFROM

