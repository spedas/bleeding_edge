;+
;Procedure:
;  spd_str_split
;
;Purpose:
;  Splits strings and arrays of strings.
;  Returns a string or an array of strings.
;
;Calling Sequence:
;  result = spd_str_split(str, pattern, /extract)
;
;Input:
;  str: (string) A string to be splitted
;  pattern: (optional string) A patern to find and split (usually a single character).
;                   If not given,
;                   If the /extract keyword is used, the patern is not included in the result.
;
;
;Output:
;  Return Value: (string) An array of strings
;
;Notes:
;  Use spd_str_split instead of the IDL strsplit to split string arrays in SPEDAS.
;  In IDL 8.x the strsplit function, when applied to an array of strings returns a LIST.
;  LIST is a new type of variable that was introduced in IDL 8.0.
;  SPEDAS has to be compatible with IDL 6.4 and IDL 7.x, so it cannot use LIST variables.
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-04-25 10:54:54 -0700 (Mon, 25 Apr 2016) $
;$LastChangedRevision: 20909 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_str_split.pro $
;
;-

function spd_str_split, str, pattern, _extra = ex

  if ~keyword_set(pattern) then pattern=' '
  if (size(str, /type) eq 7) && ((n_elements(str)) gt 1) then begin
    for i=0, n_elements(str)-1 do begin
      partresult = STRSPLIT(str[i], pattern, _extra = ex)
      if i eq 0 then begin
        result = [partresult]
      endif else begin
        result = [result, partresult]
      endelse
    endfor
  endif else begin
    result = STRSPLIT(str[0], pattern, _extra = ex)
  endelse
  
  return, result

end