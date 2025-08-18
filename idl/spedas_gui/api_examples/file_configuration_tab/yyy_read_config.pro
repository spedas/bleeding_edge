;+
; NAME:
;   yyy_read_config
;   
; PURPOSE:
;   Reads the plug-in configuration file (yyy_config.txt). Feel free to copy+paste
;   this for your new plug-in, and change 'yyy' to your mission acronym throughout
;   
; CALLING SEQUENCE:
;   cstruct = yyy_read_config()
; 
; INPUT:
;   none, for the purposes of this example the filename is hardcoded, 
;   'yyy_config.txt', and is put in a folder given by the routine 
;   istp_config_filedir, that uses the IDL
;   routine app_user_dir to create/obtain it: my linux example:
;   /disks/ice/home/jimm/.idl/spedas/yyy_config-4-linux
; 
; OUTPUT:
;   cstruct = a structure with the changeable fields of the !istp
;           structure
; 
; HISTORY:
;   Cleaned up for new plug-ins by egrimes 14-may-2018
;   Copied from thm_read_config and tt2000_read_config lphilpott 20-jun-2012
;   
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-05-14 16:49:20 -0700 (Mon, 14 May 2018) $
;$LastChangedRevision: 25221 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/api_examples/file_configuration_tab/yyy_read_config.pro $
;-

function yyy_config_template
  config_template = {VERSION:1.00000, $
         DATASTART:3l, $
         DELIMITER:61b, $
         MISSINGVALUE: !values.f_nan, $
         COMMENTSYMBOL:';', $
         FIELDCOUNT:2l, $
         FIELDTYPES:[7l, 7l], $
         FIELDNAMES:['FIELD1', 'FIELD2'], $
         FIELDLOCATIONS:[0l, 15l], $
         FIELDGROUPS:[0l, 1l]}
  return, config_template
end

function yyy_read_config, header = hhh
  otp = -1
  ; first step is to get the filename
  ; for this example the directory name has been hard coded
  dir = 'C:\Users\clrussell\.idl\yyy\'
  if dir[0] ne '' then begin
    filex = spd_addslash(dir) + 'yyy_config.txt'
    
    ; does the file exist?
    if file_search(filex) ne '' then begin
      template = yyy_config_template()
      strfx = read_ascii(filex, template = template, header = hhh)
      if size(strfx, /type) Eq 8 then begin
        otp = create_struct(strtrim(strfx.field1[0], 2), $
                            strtrim(strfx.field2[0], 2), $
                            strtrim(strfx.field1[1], 2), $
                            strtrim(strfx.field2[1], 2))
        for j = 2, n_elements(strfx.field1)-1 do $
          if is_numeric(strfx.field2[j]) then begin 
            str_element, otp, strtrim(strfx.field1[j], 2), $
            fix(strfx.field2[j]), /add
          endif else str_element, otp, strtrim(strfx.field1[j], 2), strtrim(strfx.field2[j], 2), /add
      endif
    endif
  endif

  ; check for slashes, add if necessary
  !yyy.local_data_dir = spd_addslash(!yyy.local_data_dir)
  !yyy.remote_data_dir = spd_addslash(!yyy.remote_data_dir)
  return, otp
end
