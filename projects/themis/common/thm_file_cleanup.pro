;+
;NAME:
; thm_file_cleanup
;PURPOSE:
; returns a list of old files that may be deleted, optionally deletes files
;CALLING SEQUENCE:
;files= thm_file_cleanup(filespec,print=print, $
;    sort_atime=sort_atime,sort_mtime=sort_mtime,$
;    sort_size=sort_size,reverse=reverse, $
;    delete_files=delete_files, days_to_keep=days_to_keep)
;
;INPUT:
; filespec = what kind of file is to be deleted, the default is '*.cdf'
;OUTPUT:
; files = the list of files to be deleted
;KEYWORDS:
; print = print the list of files
; sort_atime = sort files by Atime - last access time
; sort_mtime = sort files by mtime - last modified time
; sort_size = sort by size
; days_to_keep = the number of days old, beyone which we delete the
;                files, the default is to delete files that have not
;                been accessed in the last 30 days
; Delete_files = if set, delete the files, This must be set for the
;                files to be deleted.
; Original Author: Davin Larson
;$LastChangedBy: aaflores $
;$LastChangedDate: 2012-01-06 12:37:07 -0800 (Fri, 06 Jan 2012) $
;$LastChangedRevision: 9507 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_file_cleanup.pro $
;
function thm_file_cleanup,filespec,print=print, $
    sort_atime=sort_atime,sort_mtime=sort_mtime,$
    sort_size=sort_size,reverse=reverse, $
    delete_files=delete_files, days_to_keep=days_to_keep

thm_init

if not keyword_set(filespec) then filespec = '*.{cdf,pkt}'

if file_test(!themis.local_data_dir+'.themis_master') then begin
    for i=0,2 do begin beep & wait,.5 & end
    message,'This is a master directory! Do not try to delete these files !!!!!'
endif

files = file_search(!themis.local_data_dir,filespec,/test_regular)

info = file_info(files)
;print_struct,info

srt = indgen(n_elements(info))
if keyword_set(sort_atime) then srt = sort(info.atime)
if keyword_set(sort_mtime) then srt = sort(info.mtime)
if keyword_set(sort_size) then srt = sort(info.size)
if keyword_set(reverse) then srt = reverse(srt)
info = info[srt]
files = files[srt]

If(keyword_set(days_to_keep)) Then ndys = float(days_to_keep) $
Else ndys = 30.0

test_time = systime(/sec)-ndys*3600.0d0*24.0d0
delf = where(info.atime lt test_time, ndelf)
If(ndelf Gt 0) Then Begin
  files = files[delf]
  info = info[delf]
  if keyword_set(print) then begin
    fmt = '(i5,"  ",a,"  ",a,"  ",f7.1,"    ",a)'

    for i = 0, n_elements(info)-1 do $
      dprint, i, time_string(info[i].atime, /local), $
      time_string(info[i].mtime, /local), info[i].size/1024./1024., $
      info[i].name, format = fmt
  endif

  If(keyword_set(delete_files)) Then Begin
    If(files[0] Ne '') Then file_delete, files, /quiet, /verbose
  Endif
Endif Else dprint,  'No Old files to delete'

; remove empty directories:
dirs = file_search(!themis.local_data_dir,'*',/test_directory)
If(dirs[0] Ne '') Then $
  file_delete, reverse(dirs), /quiet, /verbose

return,files

end
