;+
;NAME: geom_indices_read_config
;
;DESCRIPTION: Reads the geom_indices_config file
;
;REQUIRED INPUTS:
; none (filename is hardcoded, 'geom_indices_config.txt', and is put in a folder
;   given by the routine 'geom_indices_config_filedir', that uses the IDL routine
;   app_user_dir to create/obtain it:
; e.g. (MacOS X)
;   /Users/username/.idl/spedas/geom_indices_config-4_darwin
;
;KEYWORD ARGUMENTS (OPTIONAL):
; none
;
;OUTPUT:
; cstruct = a structure with the changeable fields of the !geom_indices
;       structure
;
;STATUS:
;
;TO BE ADDED: n/a
;
;EXAMPLE:
;
;REVISION HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-11-18 14:02:09 -0800 (Wed, 18 Nov 2015) $
;$LastChangedRevision: 19410 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geom_indices/geom_indices_read_config.pro $
;-

function geom_indices_config_template

  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {VERSION:1.00000,$
    DATASTART:3l, $
    DELIMITER:61b, $
    MISSINGVALUE:anan[0], $
    COMMENTSYMBOL:';', $
    FIELDCOUNT:2l, $
    FIELDTYPES:[7l,7l], $
    FIELDNAMES:['FIELD1','FIELD2'], $
    FIELDLOCATIONS:[0l,15l], $
    FIELDGROUPS:[0l,1l]}

  RETURN, ppp
END

function geom_indices_read_config, header = hhh
  otp = -1    ; return -1 if fails to find config file

  ; first step, get the filename
  dir = geom_indices_config_filedir(/app_query)
  if (dir[0] NE '') then begin

    ; check for trailing characters
    ll = strmid(dir, strlen(dir)-1,1)
    if (ll EQ '/' or ll EQ '\') then filex = dir+'geom_indices_config.txt' $
    else filex = dir + PATH_SEP() + 'geom_indices_config.txt'

    ; does the file exist?
    if (file_search(filex) NE '') then begin
      template = geom_indices_config_template()
      fff = file_search(filex)
      strfx = read_ascii(filex, template=template, header=hhh)
      if (size(strfx, /type) EQ 8) then begin
        otp = create_struct(strtrim(strfx.field1[0], 2), $
          strtrim(strfx.field2[0], 2), $
          strtrim(strfx.field1[1], 2), $
          strtrim(strfx.field2[1], 2))
        For j = 2, n_elements(strfx.field1)-1 Do $
          if is_numeric(strfx.field2[j]) then begin
          str_element, otp, strtrim(strfx.field1[j], 2), $
            fix(strfx.field2[j]), /add
        endif else str_element, otp, strtrim(strfx.field1[j], 2), strtrim(strfx.field2[j], 2), /add
      endif
    endif
  endif        ; else MESSAGE, /INFO, 'NO APP_USER_DIR'

  ; check for path separators, add if necessary
  temp_string = strtrim(!geom_indices.local_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string)-1, 1)
  if ~(ll EQ '/' OR ll EQ '\') then temp_string = temp_string + PATH_SEP()
  !geom_indices.local_data_dir = temporary(temp_string)

  temp_string = strtrim(!geom_indices.remote_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string)-1, 1)
  if ~(ll EQ '/' or ll EQ '\') then temp_string = temp_string + '/'
  !geom_indices.remote_data_dir = temporary(temp_string)

  RETURN, otp
END
