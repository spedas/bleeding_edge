;+
;PROCEDURE:   mvn_swe_restore
;PURPOSE:
;  Restores SWEA save files and updates the SWEA common blocks.
;
;INPUTS:
;       None.
;
;KEYWORDS:
;       FILENAME:   Full path and name of save file.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-19 14:50:07 -0700 (Thu, 19 Jun 2025) $
; $LastChangedRevision: 33395 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_restore.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_swe_restore.pro
;-
pro mvn_swe_restore, filename=filename

  @mvn_swe_com

  finfo = file_info(filename)
  if (~finfo.exists) then begin
    print, "Save file does not exist: ", filename
    return
  endif

  restore, file=filename

end
