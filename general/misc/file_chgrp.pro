;+
;PROCEDURE  file_chgrp
;
;PURPOSE:  Changes the group ownership of a directory or file.  Caller must be the owner
;          and a group member.  Works only in UNIX-like environments.
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
;   None
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-18 09:54:44 -0700 (Fri, 18 Aug 2023) $
; $LastChangedRevision: 32028 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_chgrp.pro $
;-
pro file_chgrp, files, group

  if (strupcase(!version.os_family) ne 'UNIX') then begin
    print,'OS family is not unix.  Can''t change group.'
    return
  endif

  spawn, 'groups', mygroups
  mygroups = str_sep(mygroups,' ')
  i = where(mygroups eq group, count)
  if (count eq 0L) then begin
    print,'I''m not in the group (' + group + ').  Can''t change group.'
    return
  endif

  for i=0,n_elements(files)-1  do begin
    file = files[i]
    if (file_test(file,/user)) then spawn, 'chgrp ' + group + ' ' + file $
                               else print,'I''m not the owner.  Can''t change group'
  endfor

end

