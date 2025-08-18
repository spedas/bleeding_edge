;+
;NAME: barrel_read_config
;DESCRIPTION: Reads the barrel_config file
;
;REQUIRED INPUTS:
; none (filename is hardcoded, 'barrel_config.txt', and is put in a folder
;   given by the routine 'barrel_config_filedir', that uses the IDL routine
;   app_user_dir to create/obtain it:
; e.g. (MacOS X)
;   /Users/username/.idl/themis/barrel_config-4_darwin
;
;KEYWORD ARGUMENTS (OPTIONAL):
; none
;
;OUTPUT:
; cstruct = a structure with the changeable fields of the !BARREL
;       structure
;
;STATUS:
;
;TO BE ADDED: n/a
;
;EXAMPLE:
;
;REVISION HISTORY:
;Version 0.90a KBY 04/19/2013 no changes (note that '/' functions as univeral PATH_SEP)
;Version 0.85 KBY 12/09/2012 fixed trailing character bug (Windows only)
;Version 0.84 KBY 12/04/2012 added header 
;Version 0.83 KBY 12/04/2012 initial beta release
;Version 0.80 KBY 10/29/2012 from 'goesmag/goes_read_config.pro' by JWL(?)
;-

function barrel_config_template

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

function barrel_read_config, header = hhh
    otp = -1    ; return -1 if fails to find config file

    ; first step, get the filename
    dir = barrel_config_filedir(/app_query)
    if (dir[0] NE '') then begin
    
        ; check for trailing characters
        ll = strmid(dir, strlen(dir)-1,1)
        if (ll EQ '/' or ll EQ '\') then filex = dir+'barrel_config.txt' $
                else filex = dir + PATH_SEP() + 'barrel_config.txt'

        ; does the file exist?
        if (file_search(filex) NE '') then begin
            template = barrel_config_template()
            fff = file_search(filex)
            strfx = read_ascii(filex, template=template, header=hhh)
            if (size(strfx, /type) EQ 8) then begin
                otp = create_struct(strtrim(strfx.field1[0], 2), $
                                    strtrim(strfx.field2[0], 2), $
                                    strtrim(strfx.field1[1], 2), $
                                    strtrim(strfx.field2[1], 2))
                for j=2, n_elements(strfx.field1)-1 do $
                    str_element, otp, strtrim(strfx.field1[j],2), $
                        fix(strfx.field2[j]), /add
            endif
        endif
    endif        ; else MESSAGE, /INFO, 'NO APP_USER_DIR'

    ; check for path separators, add if necessary
    temp_string = strtrim(!barrel.local_data_dir, 2)
    ll = strmid(temp_string, strlen(temp_string)-1, 1)
    if ~(ll EQ '/' OR ll EQ '\') then temp_string = temp_string + PATH_SEP()
    !barrel.local_data_dir = temporary(temp_string)

    temp_string = strtrim(!barrel.remote_data_dir, 2)
    ll = strmid(temp_string, strlen(temp_string)-1, 1)
    if ~(ll EQ '/' or ll EQ '\') then temp_string = temp_string + '/'
    !barrel.remote_data_dir = temporary(temp_string)

    RETURN, otp
END
