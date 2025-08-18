;+
;Procedure:
;  spd_download_mkdir
;
;Purpose:
;  Manually create any non-existent directories in a local path 
;  so that file permissions can be set.
;
;Calling Sequence:
;  spd_download_mkdir, path, mode
;
;Input:
;  path:  Local path (full or relative) to the requested file's destination.
;         The filename is assumed to be included.
;  mode:  Bit mask specifying permissions for any created directories.
;         See file_chmod documentation for more information.
;
;Output:
;  error:  Flag output from recursive calls denoting that no
;          directories should be created.
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-01-13 11:24:43 -0800 (Fri, 13 Jan 2017) $
;$LastChangedRevision: 22594 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_download_mkdir.pro $
;
;-

pro spd_download_mkdir, path, mode, error=error

    compile_opt idl2, hidden


if undefined(path) then begin
  return
endif

info = file_info(path)

;already exists; nothing to do
if info.exists then begin
  return
endif

parent = file_dirname(path)

;generally this happens when there are no higher level directories,
;practically it could signify that something is wrong with the path
if parent eq path then begin
  error = 1
  return
endif

parent_info = file_info(parent)

;if parent does not exist then recurse
if not parent_info.exists then begin
  spd_download_mkdir, parent, mode, error=error
endif

;make directory and set permissions
if ~keyword_set(error) then begin
  file_mkdir, path
  if ~undefined(mode) then begin
    file_chmod, path, mode
  endif
endif


end