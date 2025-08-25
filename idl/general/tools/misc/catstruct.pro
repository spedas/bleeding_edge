;+
;FUNCTION:   catstruct
;PURPOSE:
;  Concatenates two arrays of structures whose tags are not necessarily in the same order. 
;
;USAGE:
;  result = catstruct(a,b)
;
;INPUTS:
;       a:         An array of structures.
;
;       b:         Another array of structures.  Must have the same tags as a, but they
;                  can be in a different order.
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-08-22 12:45:07 -0700 (Fri, 22 Aug 2025) $
; $LastChangedRevision: 33569 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/catstruct.pro $
;
;Created by D.L. Mitchell (February 2023)
;-
function catstruct, a, b

; Make sure the inputs are structures and they are compatible

  if ((size(a,/type) ne 8) or (size(b,/type) ne 8)) then begin
    print, "catstruct: This function only works on structures."
    return, 0
  endif

  atags = tag_names(a)
  btags = tag_names(b)
  ntags = n_elements(atags)

  if (n_elements(btags) ne ntags) then begin
    print, "catstruct: Input structures have different numbers of tags."
    return, 0
  endif

  j = intarr(ntags)
  for i=0,(ntags-1) do begin
    k = where(btags eq atags[i], count)
    if (count eq 0) then begin
      print, "catstruct: Input structures have different tags."
      return, 0
    endif
    j[i] = k[0]
  endfor

; Reorder the tags of structure b to have the same order as structure a

  c = replicate(a[0], n_elements(b))
  for i=0,(ntags-1) do c.(i) = b.(j[i])

  return, [a,c]

end
