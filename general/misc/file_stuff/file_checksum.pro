;+
;function FILE_CHECKSUM
;Purpose: Returns: SHA1 CHECKSUM string for a file 
;Usage:
;    output = file_checksum( filename, [/add_mtime] )
;Typical usage:
;    file_hash( file_search('*') ,/add_mtime )  ;
; Origin:  Mostly copied from file_touch
; Limitations:
;    Currently works only on Linux and MacOs systems by calling the shasum command in a shell.
;    This module is under development.
; Author: Davin Larson (davin@ssl.berkeley.edu)  copyright - March 2014
; Changes:
;    December 2014 - Name changed from file_hash to file_checksum because is better reflects its true purpose
; License:
;   All users are granted permission to use this unaltered code.
;   It may NOT be modified without the consent of the author. However the author welcomes input for bug fixes or upgrades.
;-

function file_checksum,files,method=method,add_mtime=add_mtime,mtime_format=mtime_format,verbose=verbose,executable=executable,relative_position=relative_position
common file_checksum_com, hash_init,hash_version,hash_executable,hash_error

if ~keyword_set(method) then method = 'sha1'

if ~keyword_set(hash_init)   then begin
    hash_executable = 'shasum'
    spawn,hash_executable+' --version',hash_version,hash_error
    hash_init = 4
    if keyword_set(hash_error) then begin
      dprint,dlevel=0,verbose=verbose,'checksum executable: '+hash_executable+' Error:',hash_error
      wait,3
    endif else  dprint,dlevel=1,verbose=verbose,'Using shell executable: '+hash_executable+' Version: ',hash_version[0]
endif

if size(/type,files) ne 7 then begin
    dprint,verbose=verbose,'filename required.'
    return,''
endif

commands = hash_executable
;if keyword_set(cd_to) then spawn,'cd '+cd_to
   
n_files = n_elements(files)
outputs = n_files ne 0 ? strarr(n_files) : ''
for i=0,n_files-1 do begin
  file = files[i]
  if file_test(/regular,file) eq 0 then begin
    output = 'FileDoesNotExist                          '+file
  endif else if keyword_set(hash_error) then output ='ChecksumExecutableNotAvailable            '+ file else begin
    if !version.os_family eq 'unix' then begin
      dprint,verbose=verbose,dlevel=4,commands
      if keyword_set(relative_position) then begin
         dirname = strmid(file,0,relative_position)
         bname   = strmid(file,relative_position)
         cd,dirname,current=currentdir
         spawn,[commands,bname],/noshell,/stderr,output,exit_status=status
         cd,currentdir
      endif else  spawn,[commands,file],/noshell,/stderr,output,exit_status=status
    endif else if !version.os_family eq 'Windows' then begin
      dprint,verbose=verbose,dlevel=3,'Not tested on Windows OS yet - feel free to fix this!'
      filestring = '"' + file + '"'
      command = strjoin([commands,filestring],' ')
      dprint,verbose=verbose,dlevel=4,command
      spawn,command ,/noshell,/stderr, /hide,output ,exit_status=status
    endif
  endelse
  output =output[0]
  if keyword_set(mtime_format) or keyword_set(add_mtime) then begin
    stat = file_info(file)
    output = time_string(stat.mtime,tformat=mtime_format)+string(stat.size,format='(i12)')+' '+output
  endif
  if keyword_set(output) then dprint,dlevel=3,verbose=verbose,output
  outputs[i] = output
endfor


if n_elements(files) eq 1 then outputs=outputs[0]

return,outputs
end

