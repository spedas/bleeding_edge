;+
;NAME:
; spd_string_replacen
;
;PURPOSE:
; Find and replace for strings.
; 
;KEYWORDS:
; inString {in} {type=string}
;            input string.
; findString {in} {type=string}
;            find string. It can be a regular expression.
; replaceString {in} {type=string}
;            replace string.
;
;HISTORY:
;
;$LastChangedBy:  $
;$LastChangedDate:$
;$LastChangedRevision:  $
;$URL: $
;--------------------------------------------------------------------------------

function spd_string_replacen, inString, findString, replaceString
  if STRLEN(inString) le 0 then return, inString
  if STRLEN(inString) lt STRLEN(findString) then return, inString
  return, StrJoin( StrSplit(inString, findString, /Regex, /Extract, /Preserve_Null), replaceString)
end