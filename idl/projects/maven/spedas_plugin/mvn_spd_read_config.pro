;+
;NAME:
; mvn_spd_read_config
;PURPOSE:
; Reads the thm_config file
;CALLING SEQUENCE:
; cstruct = mvn_spd_read_config()
;INPUT:
; none, the filename is hardcoded, 'mvn_spd_config.txt',and is put in a
; folder given by the routine mvn_spd_config_filedir, that uses the IDL
; routine app_user_dir to create/obtain it: my linux example:
; /disks/ice/home/jimm/.idl/themis/mvn_spd_config-4-linux
;OUTPUT:
; cstruct = a structure with the changeable fields of the !maven_spd
;           structure
;HISTORY:
; Hacked from thm_read_config.pro, 2014-12-01, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-01-11 11:54:21 -0800 (Mon, 11 Jan 2016) $
;$LastChangedRevision: 19709 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_spd_read_config.pro $
;-
Function mvn_spd_config_template

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

Function mvn_spd_read_config, header = hhh

  compile_opt idl2,hidden

; No sys variable, but a common block
  common mvn_file_source_com,  psource

  otp = -1
;First step is to get the filename
  dir = mvn_spd_config_filedir(/app_query)
  If(dir[0] Ne '') Then Begin
;Is there a trailing slash? Not for linux or windows, not sure about Mac
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Eq '/' Or ll Eq '\') Then filex = dir+'mvn_spd_config.txt' $
    Else filex = dir+'/'+'mvn_spd_config.txt'
;Does the file exist?
    If(file_search(filex) Ne '') Then Begin
      template = mvn_spd_config_template()
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
;check for slashes, add if necessary
      temp_string = strtrim(otp.local_data_dir, 2)
      ll = strmid(temp_string, strlen(temp_string)-1, 1)
      If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
      otp.local_data_dir = temporary(temp_string)
      temp_string = strtrim(otp.remote_data_dir, 2)
      ll = strmid(temp_string, strlen(temp_string)-1, 1)
      If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
      otp.remote_data_dir = temporary(temp_string)
    Endif Else message, /info, 'No Config file'
  Endif Else message, /info, 'NO APP_USER_DIR'

  Return, otp
End


