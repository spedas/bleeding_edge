;+
; FUNCTION:
; 	 DATESEC_VAR
;
; DESCRIPTION:
;
;	function to return seconds since 1 Jan 1970, 00:00 UT corresponding
;	to beginning of given day.
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    
;    ; seconds since 1970 
;
;	day = 21
;	month = 3
;	year = 91
;    
;    ; convert to string    
;    
;	seconds_date = datesec_var(day, month, year)
;    
;    ; print it out
;    
;	PRINT, seconds_date
;
; --- Sample output would be 
;    
;	6.6951360e+08
;    
;
; NOTES:
;
;	If conversion fails, this function returns -1.
; 
;
;	If any of the fields is to large then a carry operation will occur.  
; 	i.e. 34/13/89 would come out to year 90, month 2, day 3.
;
;	If inputs are arrays, then an array of 
;	N_ELEMENTS(inputs vals) of times will be returned
;
;
; REVISION HISTORY:
;
;	@(#)datesec_var.pro	1.2 06/07/95 	
; 	Originally written by Ken Bromund,  University of 
; 	California at Berkeley, Space Sciences Lab.   May, '92
;	made to give results equivalent to datesec by Jon Loran
;	
;-

FUNCTION datesec_var, day, mon, yr

; days in year before beginning of a month for leap and non-leap years

daytable= [[0,0,31,59,90,120,151,181,212,243,273,304,334]   $
          ,[0,0,31,60,91,121,152,182,213,244,274,305,335]]

; other various constants

secinday   = 86400.D      ; seconds in a day

; set exception handling

ON_IOERROR, badconv

; check to see that we have the same number of days, years, and months
n = N_ELEMENTS(day)
IF (n NE N_ELEMENTS(mon))  	$
   OR (n NE N_ELEMENTS(yr))	$
   THEN RETURN, -1.D

IF  (WHERE((day lt 0) OR (mon lt 0) OR (yr lt 0)))(0) NE -1            $
	THEN	RETURN, -1.D                      ; all values must be positive

;    assume all input years are between 1970 and 2069.
;    make year 4 digits, and if less than 70 assume 21st century 

	over100 = where(yr GT 100, count)
	if count GT 0 then yr(over100) = yr(over100) mod 100
	yr = yr + 1900
	in21st = where(yr LT 1970, count)
	if count GT 0 then yr(in21st) = yr(in21st) + 100

;     now take care of carry problems
	
	carrymon = where(mon GT 12, count)
	if count GT 0 then begin
	  yr(carrymon) = yr(carrymon)+fix((mon(carrymon)-1)/12)
	  mon(carrymon) = (mon(carrymon)-1) mod 12 + 1
	  end

	leap = ((yr MOD 4) EQ 0) AND ((yr MOD 100) NE 0) OR $
		((yr MOD 400) EQ 0)          ; leap will be true on a leap year


	; get days from 1 Jan 1970 by taking the doy of year 
	; (the number of days from beginning
	; of year before this month and adding the day of this month) minus one
	; and adding the number of days in the years between the current
	; year and 1970 (this will be 365 * the number of years + the number
	; of these years which are leap years--nb. all years in accepted
	; input range are leap years if divisible by 4)
	; then multiply by seconds in a day.

;     all done, output this date in seconds since 1/1/1970 00:00 UT
	RETURN,(daytable(mon,leap)+day-1 + (yr-1970)*365L + fix((yr-1969)/4) )$
		* secinday




badconv:
RETURN, -1.D                     ; sorry pal's we hit an error

; all done

END                              ; DATESEC_VAR
