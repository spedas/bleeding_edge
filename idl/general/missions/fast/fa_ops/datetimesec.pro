;+
; FUNCTION:
; 	 DATETIMESEC
;
; DESCRIPTION:
;
;	function to parse out a date/time string with date format of
;	either the form DD-MM-YY (e.g. '1-10-89'), DD/MM/YY (e.g. '1/10/89'),
;	DD MMM YY (e.g. '1 Oct 89' or '1 OCT 89', case ingnored) or YYYY/MM/DD
;	OR YYYY-MM-DD (e.g. 1989/10/01, where the first field is greater than
;	31), and time format of with format HH:MM:SS.MSC where the least
; 	significant entries may be omitted (e.g. HH:MM is legal), but at least
;	one colon must remain.  There must be some delimiter between the date
;	and the time, which must be different than the delimiter between the
;	fields within the date string portion.  The RETURN value is double
;	float in seconds since 1 Jan 1970, 00:00 UT.
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;    
;    ; seconds since 1970 
;
;	string_date_time = '1991-03-21/04:04:04'
;    
;    ; convert to string    
;    
;	seconds_date = datetimesec(string_date_time)
;    
;    ; print it out
;    
;	PRINT, seconds_date
;
; --- Sample output would be 
;    
;	6.6952824e+08
;    
;
; NOTES:
;
;	If conversion fails, this function returns -1.
; 
;	For the forth date input format to work (YYYY/MM/DD), the year
;	specified must be greater than 31, otherwise the DD/MM/YY
;	format assumed.
;
; 	Note that NO combination of date input formats will work.  Also, all
; 	three date fields must be present.  
;
;	If any of the fields is to large then a carry operation will
;	occur.  i.e. 34/13/89 would come out to year 90, month 2, day 3.
;	The same is true of the time portion.
;
;	If the date or time portion of the input string are omitted, then
;	this function will behave like the datesec() or timesec() respectively.
;
;	If input seconds is an array, then an array of 
;	N_ELEMENTS(inputs vals) of date strings and remainders will be
;	returned.
;
;
; REVISION HISTORY:
;
;	@(#)datetimesec.pro	1.2 07/20/95 
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Sep. '91
;
;	Revised to handle arrays of input values, JML, Jan. '92
;-




FUNCTION datetimesec, stringin

   ; just use datesec and timesec to parse string

   secsOut = 0.D
   secsTime = -1.D
   secsDate = datesec(stringin) 
   IF STRPOS (stringin, ':') GE 0 THEN  secsTime = timesec(stringin)

   IF secsDate GT 0.D THEN secsOut = secsOut + secsDate
   IF secsTime GT 0.D THEN secsOut = secsOut + secsTime

   RETURN, secsOut

END
