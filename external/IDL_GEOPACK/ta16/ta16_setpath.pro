;+
; ta16_setpath
;
; Purpose: Set the GEOPACK internal path for the TA16_RBF.par file required by TA16 model.
;
; Notes:
;   2022-05-23: Geopack DLM v10.9 is a beta version:
;               https://www.korthhaus.com/index.php/idl-software/idl-geopack-dlm/
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2022-05-29 14:31:21 -0700 (Sun, 29 May 2022) $
; $LastChangedRevision: 30837 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta16/ta16_supported.pro $
;-

pro ta16_setpath

    ; requires file TA16_RBF.par in the same directory
    dir = FILE_DIRNAME(ROUTINE_FILEPATH(), /MARK_DIRECTORY)
    file = dir + 'TA16_RBF.par'
    if FILE_TEST(file, /read) then begin
      GEOPACK_TA16_SETPATH, dir
    endif else begin
      dprint, "TA16 model requires file TA16_RBF.par. It was not found in IDL_GEOPACK/ta16 directory."
    endelse

end