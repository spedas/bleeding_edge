; May 2021 Ali
; $LastChangedBy: ali $
; $LastChangedDate: 2021-06-14 10:41:49 -0700 (Mon, 14 Jun 2021) $
; $LastChangedRevision: 30044 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/file_stuff/file_info_string.pro $

function file_info_string,files,name=name,size=size,mtime=mtime,ctime=ctime,atime=atime,mode=mode

  if n_elements(name) eq 0 then name=1
  if n_elements(size) eq 0 then size=1
  if n_elements(mtime) eq 0 then mtime=1

  nfiles=n_elements(files)
  if nfiles eq 0 then return,'No files selected!'
  strings=replicate('',nfiles)
  for j=0,nfiles-1 do begin
    info=file_info(files[j])
    if keyword_set(name) then strings[j]+='"'+files[j]+'"'
    if ~info.exists then begin
      strings[j]+=' does not exist!'
      continue
    endif
    if keyword_set(size) then begin
      sizeunit=['','k','M','G','T','noway!']
      size0=info.size
      i=0
      while size0 gt 1e3 do begin
        size0/=1e3
        i++
      endwhile
      strings[j]+=' Size('+sizeunit[i]+'B):'+strtrim(size0,2)
    endif
    if keyword_set(mtime) then strings[j]+=' mtime(UTC):'+time_string(info.mtime)
    if keyword_set(ctime) then strings[j]+=' ctime(UTC):'+time_string(info.ctime)
    if keyword_set(atime) then strings[j]+=' atime(UTC):'+time_string(info.atime)
    if keyword_set(mode) then strings[j]+=' mode:'+strtrim(info.mode,2)
  endfor

  return,strings
end