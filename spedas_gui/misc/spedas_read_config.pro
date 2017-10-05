;+
;NAME:
; spedas_read_config
;PURPOSE:
; Reads the spedas_config file
;CALLING SEQUENCE:
; cstruct = spedas_read_config()
;INPUT:
; none, for the purposes of this example the filename is hardcoded, 
; 'spedas_config.txt',and is put in a folder given by the routine 
; istp_config_filedir, that uses the IDL
; routine app_user_dir to create/obtain it: my linux example:
; /disks/ice/home/jimm/.idl/spedas/spedas_config-4-linux
;OUTPUT:
; cstruct = a structure with the changeable fields of the !istp
;           structure
; Copied from thm_read_config and tt2000_read_config lphilpott 20-jun-2012
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-03 13:50:06 -0800 (Thu, 03 Dec 2015) $
;$LastChangedRevision: 19523 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/misc/spedas_read_config.pro $
;-
Function spedas_config_template

  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {VERSION:1.00000, $
         DATASTART:3l, $
         DELIMITER:61b, $
         MISSINGVALUE:anan[0], $
         COMMENTSYMBOL:';', $
         FIELDCOUNT:2l, $
         FIELDTYPES:[7l, 7l], $
         FIELDNAMES:['FIELD1', 'FIELD2'], $
         FIELDLOCATIONS:[0l, 15l], $
         FIELDGROUPS:[0l, 1l]}

  Return, ppp
End
Function spedas_read_config, header = hhh

  ; Catch errors and return
  catch, errstats
  if errstats ne 0 then begin
    error = 1
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
    return, -1
  endif
  
  otp = -1
;First step is to get the filename
  dir = spedas_config_filedir()
  If(dir[0] Ne '') Then Begin
;Is there a trailing slash? Not for linux or windows, not sure about Mac
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Eq '/' Or ll Eq '\') Then filex = dir+'spedas_config.txt' $
    Else filex = dir + PATH_SEP() + 'spedas_config.txt'
;Does the file exist?
    If(file_search(filex) Ne '') Then Begin
      template = spedas_config_template()
      fff = file_search(filex)
      strfx = read_ascii(filex, template = template, header = hhh)
      If(size(strfx, /type) Eq 8) Then Begin
        otp = create_struct(strtrim(strfx.field1[0], 2), $
                            strtrim(strfx.field2[0], 2), $
                            strtrim(strfx.field1[1], 2), $
                            strtrim(strfx.field2[1], 2))
        For j = 2, n_elements(strfx.field1)-1 Do $
          if is_numeric(strfx.field2[j]) then begin 
            str_element, otp, strtrim(strfx.field1[j], 2), $
            fix(strfx.field2[j]), /add
          endif else str_element, otp, strtrim(strfx.field1[j], 2), strtrim(strfx.field2[j], 2), /add
      Endif
    Endif
  Endif; Else message, /info, 'NO APP_USER_DIR'
  
;check for slashes, add if necessary
;  temp_string = strtrim(!spedas.local_data_dir, 2)
;  ll = strmid(temp_string, strlen(temp_string)-1, 1)
;  If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+PATH_SEP()
;  !spedas.local_data_dir = temporary(temp_string)
;  temp_string = strtrim(!spedas.remote_data_dir, 2)
;  ll = strmid(temp_string, strlen(temp_string)-1, 1)
;  If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+PATH_SEP()
;  !spedas.remote_data_dir = temporary(temp_string)

  Return, otp
End
