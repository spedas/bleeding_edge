;+
;function thm_valid_input
;purpose:
;  for thm_load routines to validate the input keyword and set it to a standard
;  format ('l1', 'l2', etc.).  
;parameters:
;  input:  keyword input to be validated from thm_load routine: array or scalar
;  label:  name of input keyword that is being validated
;keywords:
;  vinputs: a space-separated string, like 'l1 l2'
;  definput: a string like 'l2'.  Required.
;  include_all:  if set will accept multiple values on input, and include 'all'
;                as a valid input. 'all' is equivalent to '*'
;  verbose: to maintain control of verbosity 
;  format: format to use to convert numerical input to string.  Numerical input
;          disallowed if absent.  examples: "('l',I1)" or "('v', I02)"
; return value:
;    a scalar string, e.g. 'l1'
;    if /include_all: an array of strings
;    on error: empty string: ''
;example:
;        lvl = thm_valid_input(level,'Level',vinputs='l1 l2',definput='l1',$
;                               foramt="('l', I1)", verbose=verbose)
;        if lvl eq '' then return                             
;
;-


function thm_valid_input, input, label, vinputs=vinputs, definput=definput, include_all=include_all, format=format, verbose=verbose,no_download=no_download

  thm_init,no_download=no_download
  vb = size(verbose, /type) ne 0 ? verbose : !themis.verbose

;valid data inputs
; don't alter value passed in: for now, thm_load_xxx still will  expect
; a space-separated string
  vinp = strsplit(vinputs, ' ', /extract)

; parse out data input
  if keyword_set(definput) then inp = definput else message, 'definput keyword required'
  if n_elements(input) gt 0 then begin
     if size(input, /type) eq 7 then begin
        if keyword_set(input) then inp = input
     endif else begin
        inp = string(input, format=format)
     endelse
  endif
  inps = ssl_check_valid_name(strlowcase(inp), vinp, include_all=include_all)
  if not keyword_set(inps) then begin 
     dprint, dlevel = -1, $
              'Invalid '+strlowcase(label)+ ' input.'
     return, ''
  endif
  ;; don't allow multiple input unless /include_all
  if ~keyword_set(include_all) && n_elements(inps) gt 1 then begin
     dprint, dlevel = -1, $
              'Only one value may be specified for '+strlowcase(label)
     return, ''
  endif
  if keyword_set(vb) then printdat, inps, /value, varname=label

  return, keyword_set(include_all) ? inps : inps[0] 

end
