;+
; NAME:
;   FILE_ARCHIVE
; PURPOSE:
;   Archives files by renaming them and optionally moving them to another directory.
;   No action is taken if neither ARCHIVE_EXT or ARCHIVE_DIR is set.
; CALLING SEQUENCE:
;   FILE_ARCHIVE,'old_file',archive_ext = '.arc'
; KEYWORDS:
;   ARCHIVE_EXT = '.arc'
;   ARCHIVE_DIR = 'archive_dir/'  ; name of subdirectory to move files into.
;   VERBOSE
;   DLEVEL
;   MAX_ARCS = n  ; max number of archives to produce
; Author:
;   Davin Larson  June 2013   
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2015-10-19 16:17:21 -0700 (Mon, 19 Oct 2015) $
; $LastChangedRevision: 19109 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_archive.pro $
;-
 

pro file_archive,filename,archive_ext=archive_ext,archive_dir=archive_dir,verbose=verbose,dlevel=dlevel  ,max_arcs=max_arcs
  if ~keyword_set(archive_ext) && ~keyword_set(archive_dir) then return
;  if size(/type,archive_ext) ne 7 then archive_ext = ''
;  if size(/type,archive_dir) ne 7 then archive_dir = ''
  dl = n_elements(dlevel) ne 0 ? dlevel : 3
  if n_elements(max_arcs) eq 0 then max_arcs = 99
  
for i = 0L,n_elements(filename)-1 do begin
  fi = file_info(filename[i])
  if fi.exists eq 0 then begin
     dprint,verbose=verbose,dlevel=dl,fi.name+ ' does not exist.'
     continue   ; no file to archive
  endif
  dir = file_dirname(fi.name)+'/'
  bname = file_basename(fi.name)
  if size(/type,archive_dir) eq 7 then dir = (strmid(archive_dir,0,1) eq '/') ? archive_dir : dir+archive_dir
  if size(/type,archive_ext) eq 7 then  begin
    arc_format = dir+bname+archive_ext
    arc_names = file_search(arc_format+'*',count=n_arc)
    if n_arc ne 0 then begin
       arc_nums = fix( strmid(arc_names,strlen(arc_format) ) )
       n_arc = max(arc_nums) + 1
       dprint,verbose=verbose,dlevel=dl+1,'Consider deleting '+strtrim(n_arc,2)+" archived files: '"+arc_format+"*'"
    endif
    arc_name = arc_format+strtrim(n_arc < max_arcs,2)
  endif else arc_name = dir+bname
  dprint,verbose=verbose,dlevel=dl,'Archiving old file: '+fi.name+' moved to '+arc_name
  if keyword_set(archive_dir) then file_mkdir2,dir,mode='777'o
  file_move,fi.name,arc_name               ;   rename old file
endfor

end



