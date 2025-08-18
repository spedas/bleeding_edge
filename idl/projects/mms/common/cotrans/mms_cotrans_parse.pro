;+
;Procedure:
;  mms_cotrans_parse
;
;Purpose:
;  Parse input coordinates stored in suffix string.
;  This should allow coordinates systems denoted non-three-character strings
;  and handle disambiguation between systems with identical substrings.
;
;Calling Sequence:
;  coord_string = mms_cotrans_parse(input_string, valid_strings)
;
;Input:
;  input_string:  The suffix to be parsed (scalar)
;  valid_strings:  Array of valid coordinate strings
;
;Output:
;  return value:  Returns recognized coordinate or empty string if none found.
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-05-25 15:38:52 -0700 (Wed, 25 May 2016) $
;$LastChangedRevision: 21208 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_cotrans_parse.pro $
;-

function mms_cotrans_parse, input, valid

    compile_opt idl2, hidden


if ~is_string(input) || ~is_string(valid) then begin
  return, ''
endif

flags = intarr(n_elements(valid))

;search for match at end of suffix to simulate legacy behavior
for i=0, n_elements(flags)-1 do begin
  flags[i] = stregex(input, valid[i]+'$', /fold, /bool)
endfor

idx = where(flags,n)

case n of 
  0: return, ''
  1: return, valid[idx]
  else: begin
    ;for coords with identical substrings assume largest match is correct
    ;  .e.g  '*agsm' is assumed to be AGSM not GSM or SM
    return, (valid[idx])[ (sort(strlen(valid[idx])))[n-1] ]
  endelse
endcase

end