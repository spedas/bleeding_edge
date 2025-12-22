;+
; FUNCTION:
; 	 MONTHYRFROM
;
; DESCRIPTION:
;
;	 Function to build an array of strings of the format:
; 
;	'YR-MN-1' 
;
;	given a start time in seconds since 1970.  
;
;	The date in each string increases monotonically, in the specified
;	number of months increments for the number of strings requested, 
;	from the start time given.
;
; 	Input parameters are the time to start the strings in seconds 
;	since 1970, Jan 1, 00:00, the number of strings to output, and
;	the number of months to increment by.
;
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    ; set an array of strings to month and year date representions
;
;	date_strings = monthyrfrom(16156800.0,8,2)  ; 8 dates, in 2 month
;	                                            ; increments, starting at 
;                                                   ; 7 Jul 1970 0:0:0.00
;    ; output result
;
;	PRINT, date_strings
;
; --- Sample output would be
;
;	70-7-1 70-9-1 70-11-1 70-1-1 70-3-1 70-5-1 70-7-1 70-9-1
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
;	the increment can have any sign.
;
;	This routine calls the function "secdate".
;
; REVISION HISTORY:
;
;	@(#)monthyrfrom.pro	1.3 08/18/95 	
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Feb. '92
;
;-


FUNCTION monthyrfrom,start_time,n_strings,increment

; set up error break

;ON_ERROR, 2

; check for validity of input (all input values GE 0.)

IF (WHERE(start_time LT 0.))(0) NE -1 THEN    RETURN, 'ERROR' 

; months as strings

months= $   ; months in upper case string form
  ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

; set up output buf

output = STRARR(n_strings,N_ELEMENTS(start_time))

; Now loop through all input values

FOR i=0,N_ELEMENTS(start_time)-1 DO BEGIN

;     get start month yr

	month = (FIX(WHERE((STRMID(secdate(start_time(i),/FMT),3,3)           $
		EQ months))+1))(0)
	year = FIX(STRMID(secdate(start_time(i),/FMT),7,2)) 

;     Now loop through selected for number of dates

	FOR j=0, n_strings-1 DO BEGIN
		output(j,i) = STRCOMPRESS(STRTRIM(                         $
		STRING(year) + '-' + STRING(month) + '-1' ,2),/REMOVE_ALL)
		month = month + increment
		WHILE month GT 12 DO BEGIN
			month = month - 12
			year = year + 1
		ENDWHILE
	ENDFOR

ENDFOR                                  ; main loop

RETURN, output                          ; normal return

END                                     ; MONTHYRFROM

