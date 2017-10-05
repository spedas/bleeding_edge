; Put structure 'A' into structure 'B'
; 
; By default, the same tag must exist in both structures.
; 
; If 'FORCE' keyword is set, a tag of 'A' does not necessarily be in 'B'.
; Such a tag will be forced (or newly added) into 'B'
;  
FUNCTION mms_config_push, A, B, force=force
  if n_tags(A) eq 0 then return, B; no change made to B
  if (n_tags(B) eq 0) and ~keyword_set(force) then return, B; no change made to B
  B_new = B
  tn_A = tag_names(A) ; tags in configure files
  for n=0,n_elements(tn_A)-1 do begin; scan config (may include parameters of other modules)
    str_element,B_new,tn_A[n],SUCCESS=found
    if found or keyword_set(force) then begin
      str_element,/add,B_new,tn_A[n], A.(n); then replace or add the value
    endif
  endfor
  return, B_new
END
