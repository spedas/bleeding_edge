;+
;PROCEDURE:   mvn_swe_save
;PURPOSE:
;  Saves the SWEA common block to a save file.
;
;INPUTS:
;       None.
;
;KEYWORDS:
;       FILENAME:   Full path and name for save file.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-19 14:50:07 -0700 (Thu, 19 Jun 2025) $
; $LastChangedRevision: 33395 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_save.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_swe_save.pro
;-
pro mvn_swe_save, filename=filename

  @mvn_swe_com

  if (size(filename,/type) ne 7) then begin
    print,"You must supply a filename."
    return
  endif

  save, /comm, /variables, file=filename
  print,"Created save file: ", filename

end
