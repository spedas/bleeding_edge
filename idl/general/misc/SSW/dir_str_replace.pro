;+
;NAME:
; dir_str_replace
;PURPOSE:
; take all of the files in a given directory and replace strings
; works recursively. Also renames files
;CALLING SEQUENCE:
; dir_str_replace, directory, string, replacement, filter=filter
;INPUT:
; directory = a directory name, scalar
; string = a string to replace, can be vector
; replacement = the replacement string, can be a vector the same size
;               as the input string
; no_svn = if set, do the string replacement to the output filename,
;          but don't mess with svn.
; move_it = if set, use svn mv, and not svn cp
;HISTORY:
; 5-Jan-2010, jmm, jimm@ssl.berkeley.edu
;-
Pro dir_str_replace,  dir_in, string_in, string_out, $
                          no_svn = no_svn, $
                          move_it = move_it, $
                          _extra = _extra

;error checking
dir = file_search(dir_in, /test_directory, /mark_directory)
If(is_string(dir) Eq 0) Then Begin
    message, /info, 'Missing Directory: '+dir_in
    Return
Endif
files = file_search(dir+'*', /test_read, /test_write)
;If the files exist, then replace for each one:
If(is_string(files) Eq 0) Then Begin
    message, /info, 'No replaceable files found in: '+dir
    Return
Endif
nfiles = n_elements(files)
For j = 0L, nfiles-1 Do Begin
    dj = file_search(files[j], /test_directory)
    If(is_string(dj)) Then Begin
;        print, 'Called: dir_str_replace, '+dj+' string_in, string_out'
        dir_str_replace, dj, string_in, string_out, no_svn = no_svn, $
          move_it = move_it, _extra = _extra
    Endif Else Begin
;        print, 'Called: svn_file_str_replace, '+files[j]+' string_in, string_out'
        file_str_replace, files[j], string_in, string_out, no_svn = no_svn, $
          move_it = move_it, _extra = _extra
    Endelse
Endfor
;You may need to change the directory name:
x1 = file_dirname(dir)
x2 = file_basename(dir)
x20 = x2
n = n_elements(string_in)
For k = 0, n-1 Do x2 = ssw_str_replace(x2, string_in[k], string_out[k])
If(x2 Eq x20) Then Begin
    same_name = 1b
Endif Else same_name = 0b
dir_out = x1+'/'+x2
If(~same_name) Then Begin       ;if the name is unchanged, do nothing
    print, 'Copying: '+dir_out
;It's important to be sure that dir_out does not exist. Otherwise the
;copy commands are different
    If(file_exist(dir_out)) Then Begin
        spawn, 'chmod -R u+w '+dir+out
        spawn, 'rm -rf '+dir_out
    Endif
    If(keyword_set(no_svn)) Then Begin
        If(keyword_set(move_it)) Then Begin
            spawn, '/bin/mv -r '+dir+' '+dir_out
        Endif Else spawn, '/bin/cp -r '+dir+' '+dir_out
    Endif Else Begin
        If(keyword_set(move_it)) Then Begin
            spawn, 'svn mv '+dir+' '+dir_out
        Endif Else spawn, 'svn cp '+dir+' '+dir_out
    Endelse
Endif

Return
End

