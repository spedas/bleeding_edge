;+
;NAME:
; ssl_check_valid_name
;
;
;PURPOSE:
; Checks a string or array input against another array to find matches.
;
;
;CALLING SEQUENCE:
; ok_names = ssl_check_valid_name(names, valid_names)
;
;
;INPUT:
; names:  String or string array to be checked
; valid_names:  String array specifying valid values
;
;
;OUTPUT:
; return value: String array containing the subset set of input names determined
;               to be valid.  A null string is returned if no matches are found.
;
;
;KEYWORDS:
; include_all:  if set, include 'all' in the possible datanames
; ignore_case: if set converts all inputs 
; loose_interpretation:  if set, adds wild card '*'s to each end of
;                        the input names
; no_warning:  if set, do not issue a warning if the input is invalid
; invalid: returns string array containing non-valid names or a
;           null string returned if all match, if the TYPE keyword
;           is set then a full error message will be returned
; type:  input string denoting what type of input is being check,
;        will be used for error reporting 
;        (e.g. 'data type', 'probe', ...)
;
;
;HISTORY:
; 22-jan-2007, jmm, jimm@ssl.berkeley.edu
; 11-feb-2007, jmm, Added loose_interpretation keyword
; 30-apr-2015,  af, Moved to general branch
;
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-30 15:31:31 -0700 (Thu, 30 Apr 2015) $
; $LastChangedRevision: 17459 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/ssl_check_valid_name.pro $
;-
Function ssl_check_valid_name, names_in, valid_names, include_all = include_all, $
                               ignore_case = ignore_case, invalid=invalid, $
                               loose_interpretation = loose_interpretation, $
                               type=type, no_warning = no_warning

  if keyword_set(ignore_case) then begin
    names_in = strlowcase(names_in)
    valid_names = strlowcase(valid_names)
  endif

  otp = ''
  invalid = ''
  If(size(/type, names_in[0]) ne 7  Or $
     size(/type, valid_names[0]) ne 7) Then Return, otp
  If(keyword_set(include_all)) Then vn = ['all', valid_names] $
  Else vn = valid_names
  
  ;check type
  if keyword_set(type) && size(/type,type) ne 7 then type = 'input'
  
;string compression to eliminate space padding errors
  vn = strcompress(vn, /remove_all)

;this line prevents input mutation
  ni = names_in
  
  if(size(names_in, /n_dim) ne 0) then ni = strcompress(ni, /remove_all)
  
  ;add wild cards
  ;NOTE: this will only work correctly if "names_in" contains single entry
  If(keyword_set(loose_interpretation)) Then ni = '*'+ni+'*'

  otp = strfilter(vn, ni, delimiter = ' ', /string, no_match=no_match)
  
  ;return error if no matches found
  If(not keyword_set(otp)) Then Begin
    If(not keyword_set(no_warning)) Then Begin
      dprint, 'Input: '+strjoin(strtrim(names_in,2),' ')+' is not valid.'
      if keyword_set(include_all) then $
        dprint, 'Input must be one or more of the following strings:' $
      else $
        dprint, 'Input must be one of the following strings:' 
      print, vn
    Endif
    Return, ''
  Endif
  
  ;check for incorrect output and pass messages or list back
  invalid = keyword_set(no_match) ? no_match:''
  if keyword_set(invalid) && keyword_set(type) then begin
    invalid = 'Invalid '+type+' detected: '+strjoin(invalid,', ')
  endif
  
  If(keyword_set(include_all)) Then Begin
    all = where(otp Eq 'all', nall)
    If nall gt 0 Then otp = valid_names
  Endif

  Return, otp
End

