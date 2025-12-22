;+ 
; FUNCTION:
; 	 FA_ALMANAC_DIR
;
; DESCRIPTION:
;
;	Function to read fast_archive.conf a parse out the almanac directory
;
; RETURN VALUE:
;
;	If successful, The almanac directory, else the string: '-error-'
;
; REVISION HISTORY:
;
;	@(#)fa_almanac_dir.pro	1.1 03/04/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Mar. '97
;
;-

FUNCTION fa_almanac_dir

; get FASTCONFIG env variable

fastconfig = getenv ('FASTCONFIG')

IF NOT keyword_set(fastconfig) THEN BEGIN
    PRINT, 'fa_almanac_dir.pro: FASTCONFIG environment variable must be set'
    RETURN, "-error-"
ENDIF

; open file and parse

OPENR, /GET_LUN,lu, fastconfig+'/fast_archive.conf'

WHILE NOT eof(lu) DO BEGIN
    line = ' '
    READF, lu, line
    
    IF strlen(line) GT 0 THEN BEGIN

        ; is the FAST_ALMANAC string in this line?

        IF strpos (line, 'FAST_ALMANAC') GE 0 THEN BEGIN ; got it

            FREE_LUN, lu
            RETURN, strcompress(strmid(line, strpos(line, '/'), strlen(line)), /REMOVE_ALL)
        ENDIF

    ENDIF
ENDWHILE

FREE_LUN, lu

; didn't find it.  error:

RETURN, '-error-'

END

