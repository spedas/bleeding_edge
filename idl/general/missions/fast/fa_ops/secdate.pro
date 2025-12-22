;+
; FUNCTION:
; 	 SECDATE
;
; DESCRIPTION:
;
;	function to return a date string from the number of seconds since
;	1970, Jan. 1 00:00.  Output format is controled by the keyword
;	FMT.  This function will return a string in the format:
; 	
;	FMT=0 		YYYY-MM-DD  		(e.g. "1991-03-21");   
;	FMT NE 0 	DD MMM YY  		(e.g. " 3 Mar 91");   
;
;	In addition, the remander in seconds of the day are returned through
;	the remainder formal, which can be used in a subsiquent call to the 
;	function sectime if the full representation of time in date/time is
; 	desired.
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    
;    ; seconds since 1970 
;
;	seconds_date = 6.6951720e+08           ; 21 Mar 91, 01:00:00.000
;    
;    ; convert to string    
;    
;	date_string = secdate(seconds_date,remainder, FMT=0)
;    
;    ; print it out
;    
;	PRINT, date_string, remainder
;
; --- Sample output would be 
;    
;	1991-03-21, 3600.
;    
; KEYWORDS:
;
;	FMT	Controls the output string format.  See description above.
;
; NOTES:
;
;	The seconds and remainder parameters should be double precision.
;
;	If seconds is given negitive, this is an error and the string 'ERROR' is 
;	returned.
;
;	If seconds is greater than 5e9, this is past the year 2100,
;	and this is considered an error, and 'ERROR' is returned. 
;	(I hope this code doesn't last past the year 2100!)
;
;	If input seconds is an array, then an array of 
;	N_ELEMENTS(inputs vals) of date strings and remainders will be returned.
;
; 	Credits: adapted from The C Programming Lanuage, by Kernighan and 
; 	Ritchie, 2nd Ed. page 111
;
; REVISION HISTORY:
;
;	@(#)secdate.pro	1.6 02/10/97 	
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Sep. '91
;
;	Revised to handle arrays of input values, JML, Jan. '91
; 
; 	Revised to check for time too large.  Before it would
;	go into a rediculously long loop finding the year.
;-


FUNCTION secdate, secin, remainder, FMT=fmt

; set up error break

;ON_ERROR, 2

; check for validity of input (all input values GE 0.)

IF (WHERE(secin LT 0.))(0) NE -1 THEN    BEGIN
    remainder = 0
    RETURN, 'ERROR' 
ENDIF

; check for input greater than 5e9

IF (WHERE(secin GT 5e9))(0) NE -1 THEN   BEGIN
    remainder = 0
    RETURN, 'ERROR' 
ENDIF

; set up first output buf

IF KEYWORD_SET (fmt) THEN outproto = 'DD MMM YY'         $
  ELSE outproto = 'YYYY-MM-DD'

output = outproto
remainder = 0.0D

; months as strings

IF KEYWORD_SET (fmt) THEN BEGIN
   months = $                   ; months in string form, fmt=1
     ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
ENDIF ELSE BEGIN
   months = $                   ; months in string form, fmt=0
     ['01','02','03','04','05','06','07','08','09','10','11','12']
ENDELSE

; days in a month for leap and non-leap years

daytable= [[0,31,28,31,30,31,30,31,31,30,31,30,31] $
          ,[0,31,29,31,30,31,30,31,31,30,31,30,31]]

; other various constants

secleap    = 31622400.D   ; seconds in a leap year
secnonleap = 31536000.D   ; seconds in a non-leap year

secinday   = 86400.D      ; seconds in a day

; Now loop through all input values

FOR i=0,N_ELEMENTS(secin)-1 DO BEGIN

;     extend output arrays, if necessary

	IF i GT 0 THEN   BEGIN
		output = [output,outproto]
		remainder = [remainder,0.0D]
	ENDIF

;     if seconds equals 0, we know what the date is:

	IF secin(i) EQ 0D THEN BEGIN
		remainder(i) = 0D
                IF KEYWORD_SET (fmt) THEN output(i) =  ' 1 Jan 70' $
                  ELSE output(i) =  '1970-01-01' 
	ENDIF ELSE BEGIN

;     don't want change secin from caller

		seconds = DOUBLE(secin(i) ) 

;     first find the year, 

		yr=69                ; start with 1969 (we imediately incr yr 
		                     ;to 70 in loop)
		sec=seconds          ; save seconds for later

		WHILE sec GE 0 DO BEGIN               ; until no seconds left
			seconds = sec
			yr = yr + 1                   ; increment year
			leap = (((yr+1900) MOD 4) EQ 0) $
				AND (((yr+1900) MOD 100) NE 0) $
				OR (((yr+1900) MOD 400) EQ 0) ; leap will be 
				                              ; true on ..
				                              ; a leap year
			IF leap THEN sec = sec - secleap $    ; - one leap 
			                                      ; years worth ..
			                                      ; of secs
			ELSE         sec = sec - secnonleap   ; or non-leap 
			                                      ;years worth
		ENDWHILE

;     seconds now holds seconds in this year, yr is the current year, and leap
;     will be true if this is a leap year.

;     now find month in a similar fashion

		month=0           ; start with month being 0 (it will 
		                  ; be imediately set to 1 in loop)
	
		sec=seconds       ; save seconds as above

		WHILE sec GE 0 DO BEGIN                  ; again, until 
		                                         ; no seconds left
			seconds = sec
			month = month + 1                ; increment month
			sec = sec - secinday*daytable(                     $
				month,leap)              ; - sec in this..
			                                 ; month
		ENDWHILE

;     seconds now holds seconds in this month, month is the current month.
;     now find the day of month and remainder 

		day = FIX(seconds/secinday) + 1           ; our day of month
		remainder(i) = seconds - (day-1)*secinday ; and remainder

;     build date as string and we will be outa' here, for this entry

                IF KEYWORD_SET (fmt) THEN BEGIN 
                   output(i) =  STRMID(STRTRIM(STRING(day), 0)                $
			     ,STRLEN(STRTRIM(STRING(day),0))-2,2) +           $
			     ' ' +months(month-1) + ' '                       $
			     + STRMID(STRTRIM(STRING(yr),0)                   $
			     ,STRLEN(STRTRIM(STRING(yr),0))-2,2)
                ENDIF ELSE BEGIN
                   yrplus = '19'
                   IF yr GE 100 THEN yrplus = '20'
                   IF day LT 10 THEN sday = '0' + STRTRIM(day, 2)             $
                     ELSE sday = STRTRIM(day, 2)
                   output(i) = yrplus + STRMID(STRTRIM(STRING(yr),0)          $
			     ,STRLEN(STRTRIM(STRING(yr),0))-2,2) +            $
                             '-' +  months(month-1) + '-'                     $
                             + sday
                ENDELSE 
             ENDELSE

ENDFOR                           ; end of main loop

RETURN, output                   ; normal return

END                              ; SECDATE
