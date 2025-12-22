;+ 
; FUNCTION:
; 	 FA_WEB_PATH
;
; DESCRIPTION:
;
;	Function to generate a pathname where one would write world wide
;	web files for the FAST project.	
;
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;	base_path = '/disks/cdstudio/WWWSUM'
;	time = str_to_time ('1997-1-1/00:00:00')
;	data_level = 'k0'
;	type = 'ees'
;	orbit = 100
;	auroral_cross = 'is'
;	ext = 'gif'
;	path = fa_web_path( base_path, time, data_level, type, orbit,  $
;	                    auroral_cross, ext)
;	print, path
;
;  --- output would be:
;
;	/disks/cdstudio/WWWSUM/1997_01_01_00100/fa_k0_ees_00100_is.gif
;
; ARGUMENTS:
;
;	base_path:     STRING, this is the to level directory where
;	               the www files reside.
;	time:          Any standard time type: the start time of the
;	               data.
;	data_level:    STRING, the data level.  For example: k0, ql.
;	type:          STRING, one of 'ees', 'ies', 'dcf', 'acf', 'tms'
;	orbit:         The orbit of the data.
;	auroral_cross: STRING, this is one of 'in', 'on', 'is', 'os'
;	ext:           STRING: The file type, must be one of 'gif',
;	               'ps', ''.  (The empty string means no extension.)
;
; RETURN VALUE:
;
;	The path for the web file as given above will be
;	returned, unless  an error occurs, in which case the 
;	string: "INVALID" is returned.
;
; REVISION HISTORY:
;
;	@(#)fa_web_path.pro	1.4 10/08/96
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Oct. '96
;
;-




FUNCTION fa_web_path, bp, t, dl, type, orb, ac, ext

   ; check input parameters

   IF N_PARAMS () NE 7 THEN BEGIN
       PRINT, 'fa_web_path.pro: Too few parameters.  Usage:'
       doc_library, 'fa_web_path'
       RETURN, 'INVALID'
   ENDIF

   IF ac NE 'in' AND ac NE 'on' AND ac NE 'is' AND ac NE 'os' THEN BEGIN
       PRINT, 'fa_web_path.pro: auroral crossing parameter must be one of:'
       PRINT, '   in, on, is, os'
       RETURN, 'INVALID'
   ENDIF

   IF ext NE 'gif' AND ext NE 'ps' AND STRLEN(ext) GT 0 THEN BEGIN
       PRINT, 'fa_web_path.pro: file extension must be one of:'
       PRINT, '   gif, ps, or empty'
       RETURN, 'INVALID'
   ENDIF

   IF STRLEN(dl) EQ 0 THEN BEGIN
       PRINT, 'fa_web_path.pro: The data-level parameter must have non-zero length'
       RETURN, 'INVALID'
   ENDIF

   IF type NE 'ees' AND type NE 'ies' AND type NE 'dcf' AND type NE 'acf' $
     AND type NE 'tms' THEN BEGIN
       PRINT, 'fa_web_path.pro: type parameter must be one of:
       PRINT, '   ees, ies, dcf, acf, tms'
       RETURN, 'INVALID'
   ENDIF

   IF orb LT 0 THEN BEGIN
       PRINT, 'fa_web_path.pro: Orbit must be >= 0'
       RETURN, 'INVALID'
   ENDIF

   ; get orbit as string

   orbit = STRMID( STRCOMPRESS( orb + 1000000, /RE), 2, 5)

   ; parse out the input time

   secs = gettime(t)

   IF (t LE 0.D) THEN BEGIN                 ; format error in time
      PRINT, 'fa_web_path.pro: Invalid input time: ', t
      RETURN, 'INVALID'
   ENDIF

   ds = datestruct(secdate(secs))

   ; build up directory part of path

   year = STRMID( STRCOMPRESS( ds.year + 100000, /RE), 2, 4)
   mon = STRMID( STRCOMPRESS( ds.month + 1000, /RE), 2, 2)
   day = STRMID( STRCOMPRESS( ds.monthday + 1000, /RE), 2, 2)
   IF STRLEN(ext) GT 0 THEN   ext = '.' + ext
       
   path = bp + '/' + year + '_' + mon + '_' + day + '_' + orbit + '/'

   ; return the path

   RETURN, path + 'fa_' + dl + '_' + type + '_' + orbit + '_' + ac + ext

END
