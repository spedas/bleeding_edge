pro aacgmfindcoeffile, prefix, coefyrlist

  map2d_init
  
  prefix0 = getenv('AACGM_DAT_PREFIX')
  prefix = '' ;Initialize
  coefyrlist = [0] ; Initialize
  
  if strlen(prefix0) gt 1 then begin  ; If AACGM_DAT_PREFIX env. variable is set
  
    if strpos(prefix0, '\\') ne -1 then begin ;Windows path
      prefix = strjoin( strsplit(prefix0, '\\', /ext), '/' )
    endif else prefix = prefix0
    
  endif else begin  ; If not set, then set the coef. dir in SPEDAS tree.
  
    cmd_paths = strsplit( !path, path_sep(/search), /ext )
    for i=0L, n_elements(cmd_paths)-1 do begin
      cmd_path = cmd_paths[i]
      if file_test(cmd_path+'/aacgmidl.pro') then break
    endfor
    if i eq n_elements(cmd_paths) then begin
      print, 'Cannot find aacgmidl.pro!'
      print, 'Seems that the SPEDAS tree is not properly installed...'
      return
    endif
    
    prefix = cmd_path+'/coef/aacgm_coeffs'
    
  endelse
  
  
  coeffpath = file_search(prefix+'????.asc', /fold_case)
  if strlen(coeffpath[0]) lt 1 then begin
    if strlen(prefix0) gt 1 then begin
      print, 'Cannot find any file at the prefix dir ... try to look for the coef files in SPEDAS tree.' 
      setenv, 'AACGM_DAT_PREFIX=' ;Clear the env. variable 
      aacgmfindcoeffile, prefix, coefyrlist ;Call it recursively 
      return
    endif
    print, 'Cannot find any AACGM coefficient file at the following prefix dir.'
    print, '---> '+prefix+'????.asc'
    return
  endif
  
  coefyrlist = fix( strmid( coeffpath, 7, 4, /rev ) )
  
  if !map2d.aacgm_dlm_exists and strlen(prefix0) lt 1 then begin
    if !version.os_family ne 'Windows' then begin
      setenv, 'AACGM_DAT_PREFIX='+prefix
    endif else begin
      setenv, 'AACGM_DAT_PREFIX='+strjoin( strsplit(prefix,'/',/ext), '\\' )
    endelse
  endif
  
  print, 'AACGM coef path: '+prefix
  print, 'Year list of coef. files available: ', coefyrlist
  
  return
end

