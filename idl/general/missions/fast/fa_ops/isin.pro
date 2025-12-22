;+
; FUNCTION:
;        ISIN.PRO
;
; DESCRIPTION:
;
; 	Function to return an array of values in array "a" that are inclusive
; 	of array "b".  We assume that array's "a" and "b" are of the same type.
; 	If no matchs are found, -1 is returned
;
; USAGE:
; 
; 	result = ISIN (a, b)
;
; ARGUMENTS:
;	a 	First array to search
;	b 	Second array to search
;
; REVISION HISTORY:
;
;	@(#)isin.pro	1.1 06/04/95       
;       Originally written by Jonathan M Loran,  University of 
;       California at Berkeley, Space Sciences Lab.   Oct. '91
;
;-
 

; Function to return an array of values in array "a" that are inclusive
; of array "b".  We assume that array's "a" and "b" are of the same type.
; If no matchs are found, -1 is returned

FUNCTION isin, a, b

error = "AN ERROR"     
IF N_ELEMENTS(a) EQ 0 THEN RETURN,error     ; No "a", a clear error

IF N_ELEMENTS(a) EQ 0 THEN RETURN,error     ; nothing in "b", so also error

FOR i=0, N_ELEMENTS(a)-1 DO BEGIN            ; check all values of "a"
	found=0                                  ; reset found and element flag
	FOR j=0,N_ELEMENTS(b)-1 DO BEGIN         ; check in all of "b"
		IF a(i) EQ b(j) THEN found = 1   ; found a "b" in "a"
	ENDFOR
	IF found EQ 1 THEN BEGIN                 ; something found, so we have
	                                         ; an element
		IF N_ELEMENTS(c) EQ 0 THEN $     ; init output array
			c=a(i)  $
		ELSE   $                         ; else add to output array
			c=[c,a(i)]
	ENDIF
ENDFOR                                       ; done checking

IF N_ELEMENTS(c) EQ 0 THEN c = -1            ; return -1 if no matches

RETURN,c                                     ;return what we did find in "b"

END

