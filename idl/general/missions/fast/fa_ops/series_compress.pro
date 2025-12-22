;+
; FUNCTION:
;        SERIES_COMPRESS.PRO
;
; DESCRIPTION:
;
; 	Routine to return a series of numbers as a string in a compressed
;	(abreviated) format.  Contiguous series of numbers (n and m, in a
;	subarray) are displayed as:
;
;		n<delimiter>..m
;
; 	If the series is not contiguous, they are displayed as:
;
;		n<delimiter>m
;
; 	The string delimiter is specified by the user with the delimit
;	parameter.  The series must be a numeric type.
;       
; USAGE:
; 
; 	SERIES_COMPRESS, input_array, delimit
;
; ARGUMENTS:
;	input_array 	The input series, as an array to compress.
;	delimit		The delimiter to use between values
;
; REVISION HISTORY:
;
;	@(#)series_compress.pro	1.1 06/04/95
;       Originally written by Jonathan M. Loran,  University of 
;       California at Berkeley, Space Sciences Lab.   Sep. '91
;
;-

FUNCTION series_compress,series,delimit

ret_string = STRCOMPRESS(series(0),/REMOVE_ALL)
 inseries = 0                        ; we start assuming that there's no series

FOR i=1,N_ELEMENTS(series)-1 DO BEGIN
   ret_string = ret_string + delimit              ; put on delimiter
   IF i LT N_ELEMENTS(series)-1 THEN BEGIN
      WHILE ((i LT N_ELEMENTS(series)-1) AND (series(i-1)+1 EQ series(i))    $
         AND (series(i) EQ  series(i+1)-1)) DO BEGIN
            i = i + 1                        ; number contigous, goto next
            inseries = 1                     ; flag contigous number found
            IF i EQ N_ELEMENTS(series)-1 THEN GOTO, break
      ENDWHILE
   ENDIF
   break:
   IF(inseries) THEN ret_string = ret_string + '..'            ; add ellipsis
   inseries = 0                                           ; flag out of series
   ret_string = ret_string + STRCOMPRESS(STRING(series(i)),/REMOVE_ALL) 
ENDFOR

; that's it

RETURN, ret_string
END
