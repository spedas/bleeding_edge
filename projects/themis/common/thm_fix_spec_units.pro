
;+
;Procedure:
;  thm_fix_spec_units
;
;Purpose:
;  CDF2TPLOT automatically places the units in the y axis subtitle
;  regardless of whether the variable is scpectrographic.
;  This simply moves the y subtitle to the z axis title.
;
;Calling Sequence:
;  thm_fix_spec_units
;
;Input:
;  names: Array or scalar containing tplot variable names
;
;Output:
;  none
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-05-23 12:38:29 -0700 (Fri, 23 May 2014) $
;$LastChangedRevision: 15224 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_fix_spec_units.pro $
;
;-
pro thm_fix_spec_units, names

    compile_opt idl2, hidden

  
  if ~is_string(names,/blank) then return
  
  ;loop over input names
  for i=0, n_elements(names)-1 do begin

    if tnames(names[i]) eq '' then continue

    get_data, names[i], dlimits=dl
    
    if ~is_struct(dl) then continue
    
    str_element, dl, 'ysubtitle', ysubtitle
    
    ;move subtitle, if one exists, and store
    if ~undefined(ysubtitle) && ysubtitle ne '' then begin
      
      str_element, dl, 'ztitle', ysubtitle, /add
      
      str_element, dl, 'ysubtitle', '', /add
      
      store_data, names[i], dlimits=dl
      
    endif
  
  endfor
  
end
