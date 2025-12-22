;+
; FUNCTION:
; 	 DATETIMESEC_VAR
;
; DESCRIPTION:
;
;	function to return seconds since 1/1/1970 00:00 UT, from date and 
; 	time given as day, month, year, hour, minute, second, millisecond. 
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    
;    ; set up a date and time (21 Mar '91, 00:01:01.000)
;
;	day = 21
;	month = 3
;	year = 91
;	hour = 0
;	min = 1
;	sec = 1
;	msc = 0	
;    
;    ; convert to seconds
;    
;	sec_date_time = datetimesec_var(day, month, year, hour, min, sec, msc)
;    
;    ; print it out
;    
;	PRINT, sec_date_time
;
; --- Sample output would be 
;    
;	669517261
;    
;
; NOTES:
;
;	If any of the fields are are out of range, the value will be carried.
;	e.g. given date and time of 31/12/90, 25:01:00.1001, this will be
;	converted to   1/1/91, 01:01:01: 001
;	If any of the input values are negitive, this is an error and -1 will
; 
;	This function can return seconds of days, or seconds since 1970 only
;	by calling it with dates or times set to zero.
;
;	If input values are arrays, then an array of N_ELEMENTS(inputs vals) 
;	of date strings and remainders will be returned.  The number of
;	array elements for all input parameters must be the same
;
;
; REVISION HISTORY:
;
;	@(#)datetimesec_var.pro	1.2 07/20/95 
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Sep. '91
;
;	Revised to handle arrays of input values, JML, Mar. '92
;-


FUNCTION datetimesec_var, dayin, monin, yrin, hrin, minin, secin, mscin

; Check that all input parameters have the same dimension

IF ((N_ELEMENTS(dayin) NE N_ELEMENTS(monin))                               $
   OR (N_ELEMENTS(dayin) NE N_ELEMENTS(yrin))                              $
   OR (N_ELEMENTS(dayin) NE N_ELEMENTS(hrin))                              $
   OR (N_ELEMENTS(dayin) NE N_ELEMENTS(minin))                             $
   OR (N_ELEMENTS(dayin) NE N_ELEMENTS(secin))                             $
   OR (N_ELEMENTS(dayin) NE N_ELEMENTS(mscin)))                            $
   THEN   RETURN, -1.D

IF  (WHERE((dayin LT 0) OR (monin LT 0) OR (yrin LT 0) OR (hrin LT 0)      $
	OR (minin LT 0) OR (secin LT 0) OR (mscin LT 0)))(0) NE -1         $
	THEN	RETURN, -1.D                      ; all values must be positive


RETURN, datesec_var(dayin,monin,yrin)+secofday(hrin, minin, secin, mscin)

; done

END


