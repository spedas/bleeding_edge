;+
;PROCEDURE  file_chgrp
;
;PURPOSE:  Changes the group ownership of a directory or file.  Caller must own the
;          file and be a group member.  Works only in UNIX-like environments.
;
;          This routine is intended for one or a small number of files.  Changing
;          the group ownership of a large number of files, or descending though a 
;          directory structure is much better done in a unix shell.  See the manual
;          page for chgrp.
;
;USAGE:
;   file_chgrp, files, group
;
;INPUTS:
;   files:      One or more file names.  Caller must own these files.
;
;   group:      Desired group ownership for files.  Caller must be a member
;               of this group.
;
;KEYWORDS:
;   SUCCESS:    An integer array containing a success flag for each file.
;
;   ERRCODE:    An integer or integer array containing error code(s):
;
;                 0 = normal completion, no errors
;                 1 = OS family is not UNIX
;                 2 = file name not specified
;                 3 = target group not specified
;                 4 = caller is not a member of the target group
;                 5 = caller does not own file
;                 6 = file does not exist
;
;               For errors that affect the entire operation (1-4), a single
;               code is returned.  Otherwise, an array of codes, one for
;               each file, is returned.
;
;   SILENT:     Suppress messages.  Exit status is returned via ERRCODE.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-04-05 14:33:09 -0700 (Sat, 05 Apr 2025) $
; $LastChangedRevision: 33229 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_chgrp.pro $
;-
pro file_chgrp, files, group, success=ok, errcode=err, silent=silent

  blab = ~keyword_set(silent)
  ok = 0
  err = 0

  if (strupcase(!version.os_family) ne 'UNIX') then begin
    if (blab) then print, 'OS family is not unix.'
    err = 1
    return
  endif

  if (size(files,/type) ne 7) then begin
    if (blab) then print, 'You must specify one or more file names.'
    err = 2
    return
  endif

  if (size(group,/type) ne 7) then begin
    if (blab) then print, 'You must specify a group.'
    err = 3
    return
  endif
  group = group[0]  ; only one group is allowed

  spawn, 'groups', mygroups
  mygroups = strsplit(mygroups, ' ', /extract)
  i = where(mygroups eq group, count)
  if (count eq 0L) then begin
    if (blab) then print, 'I''m not a member of the group: ' + group
    err = 4
    return
  endif

  nfiles = n_elements(files)
  ok = replicate(0, nfiles)
  err = ok

  for i=0, nfiles-1 do begin
    file = files[i]
    if (file_test(file, /user)) then begin
      spawn, 'chgrp ' + group + ' ''' + file + ''''
      ok[i] = 1  ; assume success if you get this far
    endif else begin
      finfo = file_info(file)
      if (finfo.exists) then begin
        if (blab) then print, 'I''m not the owner: ' + file
        err[i] = 5
      endif else begin
        if (blab) then print, 'File does not exist: ' + file
        err[i] = 6
      endelse
    endelse
  endfor

end
