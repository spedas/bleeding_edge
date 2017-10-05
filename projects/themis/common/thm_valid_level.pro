;+
;function thm_valid_level
;purpose:
;  for thm_load routines to validate the level keyword and set it to a standard
;  format ('l1', 'l2', etc.).  Only a single level is allowed.
;keywords:
;  level:  level keyword input from thm_load routine
;  vlevels: a space-separated string, like 'l1 l2'
;  deflevel: a string like 'l2'.  defaults to 'l1'
;example:
;        lvl = thm_valid_level('l1','l1 l2','l1')
;
;-


function thm_valid_level, level, vlevels, deflevel

;valid data levels
  vlevels = strsplit(vlevels, ' ', /extract)

; parse out data level
  if keyword_set(deflevel) then lvl = deflevel else lvl = 'l1'
  if n_elements(level) gt 0 then begin
    if size(level, /type) Eq 7 then begin
      If(level[0] Ne '') then lvl = strcompress(strlowcase(level), /remove_all)
    endif else lvl = 'l'+strcompress(string(fix(level)), /remove_all)
  endif
  lvls = ssl_check_valid_name(strlowcase(lvl), vlevels)
  if not keyword_set(lvls) then begin 
    dprint, dlevel = -1, $
      'level name invalid' + lvl
    return, -1L
  endif
  if n_elements(lvls) gt 1 then begin
     dprint, dlevel = -1, $
       'only one value may be specified for level'
     return, -1L
   endif

   return, lvls[0]

end
