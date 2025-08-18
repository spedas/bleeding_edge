;+
; PROCEDURE:
;         array_contains
;
; PURPOSE:
;         Boolean check for a value inside an array; returns 1 
;           if str_to_check exists inside array_input
;
; INPUT:
;         array_input: the array to be searched
;         str_to_check: value to search for
;
; KEYWORDS:
;         allow_wildcards: allow wild cards ([], *, ?) to be used in the input string
;         
; EXAMPLE:
;     IDL> print, array_contains(['hello', 'world'], 'hello')
;         1
;         
;   Note that this also works on other types:
; 
;     IDL> print, array_contains([1, 4, 66], 66)
;         1
;     IDL> print, array_contains([1, 4, 66], 65)
;         0
; HISTORY:
;   created by egrimes@igpp
;   
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-11-20 16:04:09 -0800 (Mon, 20 Nov 2017) $
;$LastChangedRevision: 24327 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/array_contains.pro $
;-

function array_contains, array_input, str_to_check, allow_wildcards=allow_wildcards
    if undefined(allow_wildcards) then begin
      str_replace, str_to_check, '*', '\*'
      str_replace, str_to_check, '[', '\['
      str_replace, str_to_check, ']', '\]'
      str_replace, str_to_check, '?', '\?'
    endif
    return, total(strmatch(array_input, str_to_check)) ge 1.0
end