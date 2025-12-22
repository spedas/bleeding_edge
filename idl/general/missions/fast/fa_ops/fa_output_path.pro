;+ 
; FUNCTION:
; 	 FA_OUTPUT_PATH
;
; DESCRIPTION:
;
;	Function to generate a pathname for output files for the FAST project.
;
;
; USAGE (SAMPLE CODE FRAGMENT):
; 
;	base_path = '/disks/juneau/scratch'
;	data_level = k0
;	type = 'ees'
;	orbit = 100
;	further_desc = 'is'
;	ext = 'gif'
;	path = fa_output_path( base_path, data_level, type, orbit, $
;	                       further_desc, ext)
;	print, path
;
;  --- output would be:
;
;	/disks/juneau/scratch/fa_k0_ees_00100_is.gif
;
; ARGUMENTS:
;
;	base_path:     STRING, base path component of the output filename
;	data_level:    STRING, the data level.  For example: k0, ql.
;	type:          STRING, usually one of 'ees', 'ies', 'dcf', 'acf', 'tms'
;	orbit:         The orbit of the data.
;	further_desc:  STRING, this will be inserted in the filename after
;	               the orbit. 
;	ext:           STRING: The filename extension.  If it is the
;	               empty string it means ther is no extension.
;
; RETURN VALUE:
;
;	The path for the output file as given above will be
;	returned, unless  an error occurs, in which case the 
;	string: "INVALID" is returned.
;
; REVISION HISTORY:
;
;	@(#)fa_output_path.pro	1.1 10/08/96
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Oct. '96
;
;-




FUNCTION fa_output_path, bp, dl, type, orb, fd, ext

   ; check input parameters

   IF N_PARAMS () NE 6 THEN BEGIN
       PRINT, 'fa_output_path.pro: Too few parameters.  Usage:'
       doc_library, 'fa_output_path'
       RETURN, 'INVALID'
   ENDIF

   IF STRLEN(type) EQ 0 OR STRLEN(dl) EQ 0 THEN BEGIN
       PRINT, 'fa_output_path.pro: data-level and type parameters must have non-zero length'
       RETURN, 'INVALID'
   ENDIF

   IF orb LT 0 THEN BEGIN
       PRINT, 'fa_output_path.pro: Orbit must be >= 0'
       RETURN, 'INVALID'
   ENDIF

   ; get orbit as string

   orbit = STRMID( STRCOMPRESS( orb + 1000000, /RE), 2, 5)

   ; build up directory part of path

   IF STRLEN(bp) GT 0 THEN path = bp + '/'  ELSE path = './'
   IF STRLEN(ext) GT 0 THEN   ext = '.' + ext
   IF STRLEN(fd) GT 0 THEN   fd = '_' + fd

   ; return the path

   RETURN, path + 'fa_k0_' + type + '_' + orbit + fd + ext

END
