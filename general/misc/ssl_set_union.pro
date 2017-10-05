;+
;FUNCTION ssl_set_union(set1,set2)
;
;Purpose: returns the union of two sets
;
;
;Notes: empty set is -1L
;       all inputs must be empty set or arrays
;       all outputs will be empty set or arrays
;       Arrays must be of homogenous type
;-

function ssl_set_union, set1, set2
  
  if(size(set1, /n_dim) eq 0 && set1 eq -1L) then return, set2

  if(size(set2, /n_dim) eq 0 && set2 eq -1L) then return, set1

  if(size(set1, /n_dim) eq 0) then begin
    dprint, 'Set1 passed to ssl_set_union is not an array'
    return, -1L
  endif

  if(size(set2, /n_dim) eq 0) then begin
    dprint, 'Set2 passed to ssl_set_union is not an array'
    return, -1L
  endif

  u = [set1, set2]

  u = u[bsort(u)]

  idx = where(u ne shift(u, 1L),count)

  if (count EQ 0) then begin
    ; special case: if all elements of u are identical, idx will be -1
    ; return first element (coerced to 1-element array)
    return, [u[0]]
  endif else begin
    return, u[idx]
  endelse

end
