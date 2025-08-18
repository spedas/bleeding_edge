;+
; NAME:
; spd_cdawlib
;
; PURPOSE:
; This procedure compiles all the files in this directory.
; These files were adapted (forked) from NASA's CDAWLib.
; They are needed by spdfCdawebChooser and spd_ui_spdfcdawebchooser.
; 
;
; MODIFICATION HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-02-25 14:58:49 -0800 (Sun, 25 Feb 2018) $
;$LastChangedRevision: 24774 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/spdfcdas/spd_cdawlib/spd_cdawlib.pro $
;-


pro spd_cdawlib
  RESOLVE_ROUTINE, 'spd_cdawlib_virtual_funcs', /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spd_cdawlib_list_mystruct', /IS_FUNCTION, /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spd_cdawlib_break_mystring', /IS_FUNCTION, /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spd_cdawlib_read_mycdf', /IS_FUNCTION, /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spd_cdawlib_replace_bad_chars', /IS_FUNCTION, /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spd_cdawlib_tagindex', /IS_FUNCTION, /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spd_cdawlib_version', /IS_FUNCTION, /COMPILE_FULL_FILE
  RESOLVE_ROUTINE, 'spdfCdawebChooser', /COMPILE_FULL_FILE
  
  spd_cdawlib_virtual_funcs
  spd_cdawlib_list_mystruct
  x1=spd_cdawlib_break_mystring('')
  spd_cdawlib_read_mycdf
  x2=spd_cdawlib_replace_bad_chars('','')
  x3=spd_cdawlib_tagindex('','')
  x4=spd_cdawlib_version()
  
end