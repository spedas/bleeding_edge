function thm_probe_num,name 
;+
;Function: thm_probe_num
;
;Purpose:  Converts probe letters into probe numbers and vice versa.  Provide a single 
; character or number to this routine, or an array of characters and numbers and it will
; return those values but converted into the alternative representation.
;
;Inputs: name:  Either an array or a single element.  Can be either numbers or letters.
;
; Outputs: A single element or an array of elements converted to the alternative representation.
;
;
;Example:
;   print,thm_probe_num(['a','b','c','d','e'])
; 5           1           2           3           4
;   print,thm_probe_num([1,2,3,4,5])
; b c d e a
;Notes:
; 
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-06-30 16:26:54 -0700 (Mon, 30 Jun 2008) $
; $LastChangedRevision: 3229 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_probe_num.pro $
;-

  compile_opt idl2

  probe_list = ['b','c','d','e','a']

  if is_num(name[0],/real) then begin
  
    idx = where(name lt 1 or name gt 5,c)
   
    if c ne 0 then begin
      dprint,'Illegal numeric probe designator' + strcompress(string(name)),dlevel = 2
      return,-1
    endif
  
    return, probe_list[name-1]
  
  endif
  
  if is_string(name) then begin
  
    var = reform(byte(strlowcase(name)))-93
  
    idx = where(var lt 4 or var gt 8,c)
  
    if c ne 0 then begin
      dprint,'Wrong string probe designator ' + name,dlevel = 2
      return,-1
    endif
    
    d = dimen(var)
    
    if n_elements(d) eq 1 && d[0] eq 1 && ndimen(name) eq 0 then begin
      return, var[0] mod 5 + 1
    endif else begin
      return, var mod 5 + 1
    endelse
   
  endif
  
  dprint,'Illegal probe designator type' + name,dlevel = 2
  return,-1L

end