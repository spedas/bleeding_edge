;+
; Procedure:
;  kompsat_read_password
;
; Purpose:
;  Read the username and password for ESA HAPI server.
;
;
; Notes:
;   ESA HAPI server requires a username and password for each user.
;   These should be saved in a file 'kompsat_password.txt'
;   that resides in the same directory as the present file.
;   It should contain the username and password separated by =,
;   for example:
;     username=spedas
;     password=adg4kgpGf9Bh26v2
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2024-11-09 15:31:36 -0800 (Sat, 09 Nov 2024) $
;$LastChangedRevision: 32939 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/kompsat_read_password.pro $
;-

pro kompsat_read_password, username=username, password=password

  compile_opt idl2
  username = ''
  password = ''
  line = ''

  catch, Error_status
  IF Error_status NE 0 THEN BEGIN
    dprint, 'ERROR_STATE: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  ENDIF

  ; Open the password file, should reside in same directory
  dir = FILE_DIRNAME(ROUTINE_FILEPATH(), /MARK_DIRECTORY)
  file = dir + 'kompsat_password.txt'
  OPENR, lun, file, /GET_LUN

  ; Read one line at a time, check for 'username', 'passoword'
  WHILE NOT EOF(lun) DO BEGIN
    READF, lun, line
    line = line.Replace("'", "")
    line = line.Replace('"', '')
    linewords = strsplit(line, '=', /extract)
    if n_elements(linewords) gt 1 then begin
      if linewords[0].trim() eq 'username' then username = linewords[1].trim()
      if linewords[0].trim() eq 'password' then password = linewords[1].trim()
    endif
  ENDWHILE
  ; Close the file and free the file unit
  FREE_LUN, lun

end