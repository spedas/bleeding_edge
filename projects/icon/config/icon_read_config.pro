;+
;NAME:
;   icon_read_config
;
;PURPOSE:
;   Reads the icon_config file
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-05-10 10:41:33 -0700 (Thu, 10 May 2018) $
;$LastChangedRevision: 25192 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/config/icon_read_config.pro $
;
;-------------------------------------------------------------------

function icon_config_template

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

Function icon_read_config, header = hhh
  otp = -1
  ;First step is to get the filename
  dir = icon_config_filedir(/app_query)
  If(dir[0] Ne '') Then Begin
    ;Is there a trailing slash? Not for linux or windows, not sure about Mac
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Eq '/' Or ll Eq '\') Then filex = dir+'icon_config.txt' $
    Else filex = dir+'/'+'icon_config.txt'
    ;Does the file exist?
    If(file_search(filex) Ne '') Then Begin
      template = icon_config_template()
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
  temp_string = strtrim(!icon.local_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string)-1, 1)
  If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
  !icon.local_data_dir = temporary(temp_string)
  temp_string = strtrim(!icon.remote_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string)-1, 1)
  If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
  !icon.remote_data_dir = temporary(temp_string)

  Return, otp
End
