;+
; FUNCTION:
; 	 TIME_TO_STR
;
; DESCRIPTION:
;
;	function to return a date-time string from the number of seconds since
;	1970, Jan. 1 00:00.  Output format is controled by the keyword
;	FMT.  This function will return a string in the format:
; 	
;	FMT=0 	 YYYY-MM-DD/HH:MM:SS.MSC   (e.g. "1991-03-21/10:35:22.156");   
;	FMT NE 0 DD MMM YY HH:MM:SS.MSC    (e.g. " 3 Mar 91 10:35:22.156");   
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    
;    ; seconds since 1970 
;
;	seconds_date_time = 6.6951720e+08           ; 21 Mar 91, 01:00:00.000
;    
;    ; convert to string    
;    
;	date_time_string = time_to_str(seconds_date_time, FMT=0)
;    
;    ; print it out
;    
;	PRINT, date_time_string
;
; --- Sample output would be 
;    
;	1991-03-21/10:35:22.156
;    
; KEYWORDS:
;
;	FMT	Controls the output string format.  See description above.
;       MSEC    returns string with millisec accuracy if set.
;
; NOTES:
;
;	The seconds parameter should be double precision.
;
;	If seconds is given negitive, this is an error and the string 'ERROR'
;	is returned.
;
;	If input seconds is an array, then an array of 
;	N_ELEMENTS(inputs vals) of date strings will be returned.
;
;	This function relies upon the secdate and sectime functions
;
; 	Credits: adapted from The C Programming Lanuage, by Kernighan and 
; 	Ritchie, 2nd Ed. page 111
;
; REVISION HISTORY:
;
;	@(#)time_to_str.pro	1.1 31 Jul 1995
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Jul. '95
;-


FUNCTION time_to_str, secin, FMT=fmt, MSEC = msec, dateonly=dateonly

; make sure there are some elements in secin

   IF N_ELEMENTS (secin) EQ 0 THEN     RETURN, 'ERROR'
   
; check for validity of input (all input values GE 0.)

   IF (WHERE(secin LT 0.))(0) NE -1 THEN    RETURN, 'ERROR' 

; set date/time delimiter
   
   IF KEYWORD_SET (fmt) THEN BEGIN 
      delim = '_'
   ENDIF ELSE BEGIN
      delim = '/'
   ENDELSE
   
; now just use secdate and sectime functions to get result
   fullstr = secdate(secin,rem,FMT=fmt) + delim + sectime(rem)
   if not keyword_set(msec) then fullstr = strmid(fullstr,0,19)
   if keyword_set(dateonly) then fullstr = strmid(fullstr,0,10)


   RETURN, fullstr
   
END                              ; SECDATE
