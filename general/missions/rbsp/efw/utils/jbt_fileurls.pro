;+
; NAME:
;
; PURPOSE:
;   Retrieve a list of files on a remote directory accessible via http.
;
; CATEGORIES:
;   Utilities
;
; CALLING SEQUENCE:
;   result = jbt_fileurls(remote_dir, verbose = verbose)
;
;     remote_dir must a valid http directory, such as:
;     http://themis.ssl.berkeley.edu/data/rbsp/teams/spice/mk/
;
; ARGUMENTS:
;   remote_dir: (In, required) See above.
;
; KEYWORDS:
;   verbose: Set this keyword to 0 if one wants to suppress verbose screen
;         output.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-10-27: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-02: Initial release to TDAS.
;
;
; VERSION:
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-04-29 11:59:00 -0700 (Fri, 29 Apr 2016) $
; $LastChangedRevision: 20979 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/jbt_fileurls.pro $
;
;-

function jbt_fileurls, remote_dir, verbose = verbose, localdir = localdir


compile_opt idl2

; Get the tmp dir.
callback_stack = scope_traceback(/structure)
level = scope_level()
levelstr = callback_stack[level-1]

If(~keyword_set(localdir)) Then Begin
    tmp_dir = file_dirname(levelstr.filename) + path_sep() + $
      'jbt_fileurls_tmp' + path_sep()
    localdir = tmp_dir
    file_mkdir, localdir
Endif

file_http_copy,remote_dir $
  , localdir=localdir $
  , verbose=verbose $
  , links=links 

;I think that there has been a subtle change in file_http_copy, and the
;first elements of the links output is the null string. Not willing to
;touch file_http_copy, so strip out null links here, jmm, 2016-04-29

nlinks = n_elements(links)
ok_links = bytarr(nlinks)+1b
For j = 0, nlinks-1 Do If(~is_string(links[j])) Then ok_links[j] = 0b
keep = where(ok_links, nkeep)

If(nkeep Gt 0) Then links = links[keep] $
Else Begin
   dprint, 'No good file links: '
   dprint, 'remote_dir: '+remote_dir
   links = ''
Endelse

; print, time_string(url_info.mtime)
head = strmid(links[0], 0, 4)
if strcmp(head, 'http') then urls = links else urls = remote_dir + links
return, urls
end
