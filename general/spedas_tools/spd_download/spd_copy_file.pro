;+
;Procedure:
;  spd_copy_file
;
;
;Purpose:
;  Primarily a helper function for spd_download.  This function will
;  copy a single file and return the path to the copy.  Existing files
;  will only be overwritten if the source is newer.
;
;
;Calling Sequence:
;  path = spd_copy_file( source=source, destination=destination 
;                       [,no_update=no_update] [,force_copy=force_copy] )
;
;
;Input:
;  source:  Path to source file
;  destination:  Path to destination file
;  no_update:  Flag to not overwrite existing file 
;  force_copy:  Flag to always overwrite existing file
;  file_mode:  Bit mask specifying permissions for new files (see file_chmod)
;  dir_mode:  Bit mask specifying permissions for new directories (see file_chmod)
;  
; 
;
;Output:
;  return value:  Full path to destination file if successful, empty string otherwise
;
;
;Notes:
;  -precedence of boolean keywords:
;     force_download > no_update > default behavior
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-01-13 11:24:43 -0800 (Fri, 13 Jan 2017) $
;$LastChangedRevision: 22594 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_copy_file.pro $
;
;-

function spd_copy_file, $

                  source=source, $
                  destination=destination, $

                  file_mode=file_mode, $
                  dir_mode=dir_mode, $

                  no_update=no_update, $
                  force_copy = force_copy


    compile_opt idl2, hidden


output = ''


;require both inputs
if ~is_string(source) || ~is_string(destination) then begin
  dprint, dlevel=1, 'No source file supplied'
  return, output
endif

;require singular inputs
if n_elements(source) gt 1 || n_elements(destination) gt 1 then begin
  dprint, dlevel=1, 'Single file operations only, use SPD_DOWNLOAD for multiple files'
  return, output
endif


source_info = file_info(source)
destination_info = file_info(destination)


;check that source exists
if ~source_info.exists then begin
  dprint, dlevel=1, 'Cannot find source file:  ' + source
  return, output
endif


;check if an existing file is to be overwritten
if ~keyword_set(force_copy) && destination_info.exists then begin

  if keyword_set(no_update) then begin
    dprint, dlevel=2, 'Found existing file:  ' + destination_info.name
    return, destination_info.name
  endif

  if destination_info.mtime ge source_info.mtime then begin
    dprint, dlevel=2, 'File is current:  ' + destination_info.name
    return, destination_info.name
  endif

endif


dprint, dlevel=2, 'Copying:  ' + source_info.name

;make parent directory if it doesn't exist
spd_download_mkdir, file_dirname(destination_info.name), dir_mode

;copy file
file_copy, source_info.name, destination_info.name, /overwrite

if ~undefined(file_mode)then begin
  file_chmod, destination_info.name, file_mode
endif

dprint, dlevel=2, 'Copy complete:  ' + destination_info.name


return, destination_info.name

end