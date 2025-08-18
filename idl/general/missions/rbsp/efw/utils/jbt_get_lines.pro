;+
; NAME:
;   jbt_get_lines (function)
;
; PURPOSE:
;   Get all lines of a text file.
;
; CATEGORY:
;
; CALLING SEQUENCE:
;   result = jbt_get_lines(file)
;
; ARGUMENTS:
;   file: (In, required) A string of a local text file to load.
;
; KEYWORDS:
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; EXAMPLE:
;
; SEE ALSO:
;
; MODIFICATION HISTORY:
;   2011-05-27: Created by Jianbao Tao, CU/LASP.
;   2012-11-02: Initial release to TDAS. JBT, SSL/UCB.
;
;-

function jbt_get_lines, file

  ; Check existence of file.
  if ~jbt_fexist(file) then begin
    dprint, file, " doesn't exist. Exiting..."
    return, -1
  endif

  nlines = file_lines(file)
  if nlines eq 0 then begin
    dprint, 'There is no text line in ', file, '. Exiting...'
    return, -1
  endif

  ; Read all lines.
  lines = make_array(nlines, /string)
  line = ''
  openr, unit, file, /get_lun
  for i = 0L, nlines-1L do begin
    readf, unit, line
    lines[i] = line
  endfor
  free_lun, unit

  return, lines

end
