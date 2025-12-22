;+
; NAME:
;	notin
;
; PURPOSE:
; 	Function to return an array of values in array "a" that are exclusive
; 	of array "b".  We assume that array's "a" and "b" are of the same type.
;
; CALLING SEQUENCE:
;	c = notin (a, b)
;
; ARGUMENTS:
;	a 	First array to search
;	b 	Second array to search
;
; SIDE EFFECTS:
;	none
;
; INPUTS:
;	two arrays: a and b both of the same type.
;	
; MODIFICATION HISTORY:
;
;	@(#)notin.pro	1.1 06/04/95
;	Written By Jonathan Loran, UCB Feb. 25 '92
;-


FUNCTION notin, a, b

error = "AN ERROR"     
IF N_ELEMENTS(a) EQ 0 THEN RETURN,error     ; No "a", a clear error

IF N_ELEMENTS(b) EQ 0 THEN RETURN,a         ; nothing in "b", so all of "a" 
                                            ; isn't in "b"

FOR i=0, N_ELEMENTS(a)-1 DO BEGIN            ; check all values of "a"
	found=0                                  ; reset found and element flag
	FOR j=0,N_ELEMENTS(b)-1 DO BEGIN         ; check in all of "b"
		IF a(i) EQ b(j) THEN found = 1   ; found a "b" in "a"
	ENDFOR
	IF found EQ 0 THEN BEGIN                 ; nothing found, so we have
	                                         ; an element
		IF N_ELEMENTS(c) EQ 0 THEN $     ; init output array
			c=a(i)  $
		ELSE   $                         ; else add to output array
			c=[c,a(i)]
	ENDIF
ENDFOR                                       ; done checking

RETURN,c                                     ;return what we didn't find in "b"

END


