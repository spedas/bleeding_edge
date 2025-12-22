;+
; FUNCTION:
; 	 SECTIME
;
; DESCRIPTION:
;
;	function to return a time string from time of day given in seconds---
;	Given an input time in the seconds of the day, this function will
;	return a string in the format:
;
;		HH:MM:SS.MSC
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    
;    ; seconds of the day
;
;	seconds_day = 43200.00           ; 12 noon    
;    
;    ; convert to string    
;    
;	time_string = sectime(seconds_day)
;    
;    ; print it out
;    
;	PRINT, time_string
;
; --- Sample output would be 
;    
;	12:00:00.000
;    
;
; NOTES:
;
;	The seconds parameter should be of a floating point type (i.e float
;	or double)                                                                  
;
;	If the input is greater than 86400. (24 hours), time will be subtracted
;	in 24 hour chunks, until the time is less than 24 hours.
;
;	If seconds is given negative, this is an error and the string 'ERROR' is     
;	returned.                                                                    
;
;	If input seconds is an array, then an array of 
;	N_ELEMENTS(inputs vals) of time strings will be returned.
;
;
; REVISION HISTORY:
;
;	@(#)sectime.pro	1.2 06/30/95 	
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Sep. '91
;
;	Revised to handle arrays of input values, JML, Dec. '91
;       Added "carry" to seconds, S. Claflin, June, 97.
;-


FUNCTION  sectime,insec

; set up error break

;ON_ERROR, 2

; check for validity of input (all input values GE 0.)

IF (WHERE(insec LT 0.))(0) NE -1 THEN    RETURN, 'ERROR' 

; set up first output buf

outproto = 'HH:MM:SS.MSC'
output = outproto

;     break seconds into integer seconds and fraction of seconds)

	seconds = LONG(insec)
	frac = (insec mod 1.D) + .0005      ; add 1/2 msc to get nearest value
        carry = byte(frac)     ; carry one second if frac GE 1

;     get milliseconds

	msc = STRTRIM(STRING(frac))+'000'
        FOR i = 0, N_ELEMENTS(msc)-1 DO $
          msc(i) = STRMID(msc(i), strpos(msc(i), '.'), 4)

;     and then hour, minute, second

	hrs = seconds/3600
	min = (seconds - hrs*3600) / 60
	sec = seconds - (hrs*3600 + min*60) + carry

;     get time within 24 hours

	hrs = hrs mod 24

;     put leading 0's on if necessary, and make time strings

	shrs = STRTRIM(STRING(hrs),2)
	onedigit = where( STRLEN(shrs) LT 2)
	if onedigit(0) NE -1 then shrs(onedigit) = '0'+shrs(onedigit)

	smin = STRTRIM(STRING(min),2)
	onedigit = where( STRLEN(smin) LT 2)
	if onedigit(0) NE -1 then smin(onedigit) = '0'+smin(onedigit)

	ssec = STRTRIM(STRING(sec),2)
	onedigit = where( STRLEN(ssec) LT 2)
	IF onedigit(0) NE -1 THEN ssec(onedigit) = '0'+ssec(onedigit)

;     build final time string

	output =  shrs + ':' + smin + ':' + ssec + msc 

RETURN, output                          ; normal return

END                                     ; SECTIME


