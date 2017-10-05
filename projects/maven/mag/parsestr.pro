pro parsestr, strin, array, DELIMITER=delimit, HELPME=help
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;parsestr.pro								;
;									;
; Procedure takes a string and places separate columns (separated by	;
;  a delimiter) into an output string array				;
;									;									;
; Passed Variables							;
;	strin		-	String to parse				;
;	delimit		-	String delimiter			;
;  	array		-	Output array of parsed items 		;
;  	HELPME		-	keyword: Prints a help screen		;
;									;
; Called Routines:							;
;									;
; Written by:		Monte Kaelberer					;
; Last Modified: 	Oct 16, 1998	(Dave Brain)			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Check for help keyword.
IF keyword_set(help) THEN BEGIN
  print,' '
  print,'Parses string into separate items using delimiter.'
  print,' '
  print,'Syntax:'
  print,'parsestr, strin, array, DELIMITER=delimit, /HELPME'
  print,'strin		-   string to parse (required input).'
  print,'array		-   array of parsed items (output).'
  print,'DELIMITER	-   Keyword to set delimiter string'
  print,'           	    (default is space).'
  print,'HELPME		-   Keyword to get this screen.'
  return
ENDIF

;Copy the input.
str = strin

;Check for delimiter keyword.
IF NOT keyword_set(delimit) THEN delimit = ' '

;Remove leading & trailing spaces.
str = strtrim(str,2)

;Compress multiple spaces down to single spaces.
str = strcompress(str)

;Separate string into components.
array = str_sep(str, delimit)

end
