;+
;NAME:
; file_str_replace
;PURPOSE:
; read a file, find a substring and replace it in an SVN working copy
; using str_replace function. Only do this for files with '.txt',
; '.pro' extensions.
;CALLING SEQUENCE:
; file_str_replace, file, string, replacement, out_filename=out_filename
;INPUT:
; file = a filename, note that the file will be rewritten unless
;        the out_filename is set
; string = a string to replace, can be a vector
; replacement = the replacement string, can be a vector, with the same
;               number of elements as the other string.
;KEYWORDS:
; out_filename = if set, then write to this file
;          if not set, svn cp the original file to the output file prior
;          to replacement. In this case the string in will be replaced
;          in the filename by the new string, if present.
; no_svn = if set, do the string replacement to the output filename,
;          but don't mess with svn.
; move_it = if set, use svn mv, and not svn cp
;HISTORY:
; 1-aug-2013, jmm, jimm@ssl.berkeley.edu
;-
Pro file_str_replace, file_in, string_in, string_out, $
                      out_filename = out_filename, $
                      no_svn = no_svn, $
                      move_it = move_it, $
                      _extra = _extra

;error checking
file = file_search(file_in, /test_regular)
If(is_string(file) Eq 0) Then Begin
    message, /info, 'Missing File: '+file_in
    Return
Endif
file = file[0]

n = n_elements(string_in)
n1 = n_elements(string_out)

If(n Ne n1) Then Begin
    message, /info, 'String mismatch'
    Return
Endif

;Get the number of lines
nlines = file_lines(file)
If(nlines Eq 0) Then Begin
    message, /info, 'Zero Length File: '+file
    Return
Endif

;Check for .txt or .pro extension
ext = strmid(file, strlen(file)-4)

If(ext Ne '.pro' && ext ne '.txt') Then Begin
    message, /info, 'Not text or IDL : '+file
    copy_only = 1b
Endif Else copy_only = 0b

;read in the text file, line by line
If(~copy_only) Then Begin
    openr, unit, file, /get_lun
    in_line = strarr(nlines)
    For j = 0, nlines-1 Do Begin
        xj = ''
        readf, unit, xj
        in_line[j] = xj
    Endfor
    free_lun, unit
  
;Do the replacement here before messing with the filenames
    out_line = strarr(nlines)
    For j = 0, nlines-1 Do Begin
        xj = in_line[j]
        For k = 0, n-1 Do Begin
            xj = ssw_str_replace(xj, string_in[k], string_out[k])
        Endfor
        out_line[j] = xj
    Endfor
Endif

If(keyword_set(out_filename)) Then Begin
    file_out = out_filename[0]
Endif Else Begin
    x1 = file_dirname(file)
    x2 = file_basename(file)
    x20 = x2
    For k = 0, n-1 Do x2 = ssw_str_replace(x2, string_in[k], string_out[k])
    If(x2 Eq x20) Then Begin
        same_name = 1b
    Endif Else same_name = 0b
    file_out = x1+'/'+x2
Endelse

If(copy_only) Then Begin ;no changes to the file, but the filename itself may change
    If(~same_name) Then Begin   ;if the name is unchanged, do nothing
        print, 'Copying: '+file_out
        If(keyword_set(no_svn)) Then Begin
            If(keyword_set(move_it)) Then Begin
                spawn, '/bin/mv '+file_in+' '+file_out
            Endif Else spawn, '/bin/cp '+file_in+' '+file_out
        Endif Else Begin
            If(keyword_set(move_it)) Then Begin
                spawn, 'svn mv '+file_in+' '+file_out
            Endif Else spawn, 'svn cp '+file_in+' '+file_out
        Endelse
    Endif
Endif Else Begin
    If(~keyword_set(no_svn) && ~same_name) Then Begin
        If(keyword_set(move_it)) Then Begin
            spawn, 'svn mv '+file_in+' '+file_out
;Use svn copy to retain file history
        Endif Else spawn, 'svn cp '+file_in+' '+file_out
    Endif
;now write out the new file.
    print, 'Writing: '+file_out
    openw, ounit, file_out, /get_lun
    For j = 0, nlines-1 Do printf, ounit, out_line[j]
    free_lun, ounit
Endelse

Return
End


  
  

