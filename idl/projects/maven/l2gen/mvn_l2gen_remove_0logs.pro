;+
;Remove zero length static log files from log directory
Pro mvn_l2gen_remove_0logs, dir = dir, _extra = _extra
;-
  If(~keyword_set(dir)) Then dir = '/mydisks/home/maven/stalog/'
  files = file_search(dir+'run_sta_l2*.txt*', count = nfiles)
  If(nfiles Eq 0) Then Begin
    message, /info, 'No log files in: '+dir
    Return
  Endif
    
;delete zero length files
  For j = 0, nfiles-1 Do Begin
    If(file_test(files[j], /zero_length) Eq 1) Then Begin
;remove the file
       message, /info, 'Removing: '+files[j]
       file_delete, files[j]
    Endif
  Endfor

  Return
End
