;+
; NAME:
;   cl_csa_read_config
;   
; PURPOSE:
;   Reads the plug-in configuration file (cl_config.txt) for Cluster
;   
; CALLING SEQUENCE:
;   cstruct = cl_csa_read_config()
; 
; OUTPUT:
;   cstruct = a structure with the changeable fields of the !istp
;           structure
; 
; HISTORY:
;   Cleaned up for new plug-ins by egrimes 14-may-2018
;   Copied from thm_read_config and tt2000_read_config lphilpott 20-jun-2012
;   
;$LastChangedBy: jwl $
;$LastChangedDate: 2021-05-20 17:50:46 -0700 (Thu, 20 May 2021) $
;$LastChangedRevision: 29980 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/cluster_science_archive/cl_csa_read_config.pro $
;-

function cl_csa_config_template
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

function cl_csa_read_config, header = hhh
  otp = -1
  ; first step is to get the filename

  dir = cl_csa_config_filedir(/app_query)
  if dir[0] ne '' then begin
    filex = spd_addslash(dir) + 'cl_csa_config.txt'
    
    ; does the file exist?
    if file_search(filex) ne '' then begin
      template = cl_csa_config_template()
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
  !cluster_csa.local_data_dir = spd_addslash(!cluster_csa.local_data_dir)
  !cluster_csa.remote_data_dir = spd_addslash(!cluster_csa.remote_data_dir)
  return, otp
end
