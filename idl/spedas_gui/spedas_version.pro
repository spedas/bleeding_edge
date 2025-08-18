;+
;
;NAME:
; spedas_version
;
;PURPOSE:
; Display SPEDAS Version and date
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-10-29 12:54:05 -0700 (Mon, 29 Oct 2018) $
;$LastChangedRevision: 26023 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/spedas_version.pro $
;-

pro spedas_version, spd_ver=spd_ver, spd_date=spd_date

  compile_opt hidden,idl2
  
  GETRESOURCEPATH, path ; start at the resources folder
  ; File spedas_version.txt should contain two lines, version and date
  ver_txt_file = path + PATH_SEP(/PARENT_DIRECTORY) + PATH_SEP() + 'spedas_version.txt'
  str_array = ''
  if file_test(ver_txt_file, /read) then begin
    openr, lun, ver_txt_file, /GET_LUN
    line = ''
    WHILE NOT EOF(lun) DO BEGIN
      readf, lun, line
      str_array = [str_array, line]
    ENDWHILE
    free_lun, lun
  endif
  
  if n_elements(str_array) gt 2 then begin
    spd_ver = str_array[1]
    spd_date = str_array[2]
  endif else begin
    spd_ver = 'Unknown'
    spd_date = 'Unknown'
  endelse

  print, 'SPEDAS Version ', spd_ver, ', ', spd_date

end