;+
;Procedure generate_checksums
;Purpose: recursively creates checksum files in subdirectories.
;    These files are produced using the "shasum" program. The same program can be used to check file integrity
;    Files are not regenerated if the chksum file is newer than all of its dependents.
;Usage:
;Typical usage:
;    generate_checksums,directorypath,FILE_PATTERN='*.cdf'  
;    input:  directorypath - scaler string  filepath (must end with '/')
;    
;    FILE_PATTERN :  string(s)   file format string(s) use for search. Defaults to '*'
;    DIR_PATTERN :  string(s)   directory format to be searched  recursively  [optional]
;    
;    RECURSE_LIMIT :  default is 10.  Set to 0 to create a single checksum file containing all files found. 
;    
;    FORCE_REGEN : Set this keyword to force regeneration of all checksums
;    INCLUDE_DIRECTORY : Set this keyword to compute the checksum of the checksum files in subdirectories.
;    FULL_PATH : set this keyword to include the full path in the checksum file. (not recommended)
;    
;    VERBOSE:  set verbosity level
;
; Limitations:
;    Currently works only on Linux and MacOs systems by calling the shasum command in a shell.
;    This module is under development.
; Author: Davin Larson (davin@ssl.berkeley.edu)  copyright -October 2015
; Changes:
; License:
;   All users are granted permission to use this unaltered code.
;   It may NOT be modified without the consent of the author. However the author welcomes input for bug fixes or upgrades.
;-


function file_search_pattern,pathname,recurse_pattern,pattern=pattern,count=count,_extra = ex


  message,'Not working yet'
  dprint,pathname,recurse_pattern,pattern,/phelp
  if keyword_set(ex) then dprint,ex,phelp=2
  
  count = 0  

  if ~keyword_set(pathname) then begin     
    return, file_search(_extra=ex)
  endif

  if ~keyword_set(pattern) then begin
    return, file_search(pathname,_extra=ex)
  endif
  
  sep = ' ,:'
  if size(/n_dimension,pattern) eq 0 then begin
    if n_params() eq 1 then $
       return, file_search_pattern(pathname,pattern=strsplit(pattern,sep,/extract),count=count,_extra=ex)  
    if n_params() eq 2 then $
       return, file_search_pattern(pathname,strsplit(recurse_pattern,sep,/extract),count=count,_extra=ex) 
    messsage,'Can not happen'
  endif

; *pattern must be an array  at this point

  if n_params() eq 1 then   for i=0,n_elements(pattern)-1 do  append_array, files, file_search(pathname + pattern[i] ,_extra=ex)  , index=count
  if n_params() eq 2 then   for i=0,n_elements(recurse_pattern)-1 do append_array, files, file_search(pathname , recurse_pattern[i] ,_extra=ex)  , index=count

  append_array, files, index=count


  w = where(files ne '',count)
  files= (count eq 0)  ?  '' : files[w]

  ; should sort  and use uniq here ???

  return,files
end




pro generate_checksums,startpath,FILE_PATTERN=FILE_PATTERN,DIR_PATTERN=DIR_PATTERN,recurse_limit=recurse_limit,checksum_file=checksum_file, $
    verbose=verbose,tab=tab,force_regen=force_regen,full_path=full_path,include_directory=include_directory,delete_old_version_pattern=delete_old_version_pattern


if keyword_set(delete_old_version_pattern) then begin   ; typical pattern is '_v??_r??.???'  or '_r??.???'
  if strpos(delete_old_version_pattern,'*') ge 0 then message,'"*" not allowed in pattern:  '+old_Version_pattern
  files = file_search(local_data_dir,'*'+delete_old_version_pattern,count=count)
  bfiles = strmid(files,0,transpose(strlen(files) -strlen(delete_old_version_pattern)))
  new_ind = uniq(bfiles)    ; good files
  ind = replicate(1,n_elements(files))
  ind[new_ind] = 0
  old_ind = where(ind,n_old)
  old_files= n_old eq 0 ? '' : files[old_ind]
  count = n_old
  dprint,'files to be deleted:',old_files
; file_delete,old_files
endif

default_name = 'chksum.sha1'

if n_elements(recurse_limit) eq 0 then begin
  recurse_limit = 10
  if n_elements(checksum_file) eq 0 then checksum_file=default_name
endif 

if size(/type,FILE_PATTERN) ne 7 then FILE_PATTERN = '*'
if n_elements(tab) eq 0 then tab=''

if recurse_limit eq 0  then begin
  if n_elements(checksum_file) eq 0 then checksum_file='all_'+default_name
  if keyword_set(tab) then dprint,dlevel=1,verbose=verbose,'Exeeded recursion limit. Use the RECURSE_LIMIT keyword to increase it.'
  for i=0,n_elements(FILE_PATTERN)-1 do    append_array,  files , file_search(startpath,FILE_PATTERN[i])
  w = where(files ne '',nfiles)
  files= (nfiles eq 0)  ?  '' : files[w]
  
endif else begin
  if n_elements(checksum_file) eq 0 then checksum_file=default_name

  dprint,verbose=verbose,dlevel=4,tab+startpath

  dirs=''
  for i=0,n_elements(DIR_PATTERN)-1 do begin
    append_array, dirs, file_search(startpath + DIR_PATTERN[i] )
  endfor

  w = where( file_test(/directory,dirs), ndirs)
  dirs = (ndirs eq 0) ?  ''  :  dirs[w]
  dprint,verbose=verbose,dlevel=3,tab+strtrim(ndirs,2)+' Directories match ["'+strjoin(DIR_PATTERN,'", "')+'"]'

  for i = 0,ndirs-1 do begin
    generate_checksums,dirs[i]+'/',FILE_PATTERN=FILE_PATTERN,DIR_PATTERN=DIR_PATTERN,recurse_limit=recurse_limit-1,checksum_file=checksum_file,tab=tab+'    ',$
        full_path=full_path,force_regen=force_regen,verbose=verbose,include_directory=include_directory
  endfor

  files=''
  if keyword_set(include_directory) then for i=0,n_elements(DIR_PATTERN)-1  do begin
    append_array, files, file_search(startpath+DIR_PATTERN[i]+'/'+checksum_file)
  endfor

  for i=0,n_elements(FILE_PATTERN)-1 do begin
    append_array, files, file_search(startpath+FILE_PATTERN[i])
  endfor

  w = where( file_test(/regular, files)  and (files ne startpath+checksum_file), nfiles )
  files = nfiles eq 0 ?  ''  : files[w]

endelse


if nfiles ne 0  then begin 
  if file_test(/directory,/write,startpath) then begin
    sum_info = file_info(startpath+checksum_file)
    fi = file_info([files,startpath+'.'])    ; test of the modificaton time of directory is really the only test needed.
;    fi = file_info(files)
    last = max([fi.mtime,fi.ctime])
    if sum_info.mtime lt last  || keyword_set(force_regen) then begin
      dprint,verbose=verbose,dlevel=2,tab+startpath+':  '+strtrim(nfiles,2)+' files match ["'+strjoin(FILE_PATTERN,'",  "')+'"]'
      checksum = file_checksum(files,verbose=verbose,relative_position = keyword_set(full_path) ? 0 : strlen(startpath)  )
      if size(/type,checksum_file) eq 7 then begin
        openw,unit,/get_lun,startpath+checksum_file
        for i=0,n_elements(checksum)-1 do printf,unit,checksum[i]
        free_lun,unit
      endif
    endif    
  endif else begin
    dprint,dlevel=3,verbose=verbose,tab+startpath+' Found '+strtrim(nfiles,2)+' files, but can not write to directory. '
  endelse
endif


end

