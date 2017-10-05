;+
;Purpose: Performs an intersection of two sets
;Parameters: l1,l2 sets(arrays) for which the intersection is
;calculated
;
;Returns: -1L on empty set, otherwise intersection of the two sets
;
;Notes: empty set is -1L
;       Input arrays cannot contain repeated values
;       all inputs must be empty set or arrays
;       all outputs will be empty set or arrays
;       Arrays must be of homogenous type
;
;-
function ssl_set_intersection, l1, l2

  if(size(l1, /n_dim) eq 0 && l1 eq -1L) then return, -1L

  if(size(l2, /n_dim) eq 0 && l2 eq -1L) then return, -1L

  if(size(l2, /n_dim) eq 0) then begin 
    dprint, 'argument l2 to ssl_set_intersection should be of type array'
    return, -1L
  endif

  if(size(l1, /n_dim) eq 0) then begin
    dprint, 'argument l1 to ssl_set_intersection should be of type array'
    return, -1L
  endif

  ;concatenate and sort
  l3 = [l1, l2]

  l3 = l3[bsort(l3)]

  ;subtract
  id = where(l3 eq shift(l3, 1L), cnt)

  ;if its not an array ie empty intersection
  if cnt eq 0 then return, id

  ;permute
  l3 = l3[id]

  ;remove repeated elements and return
  s = l3[uniq(l3)]

  if(size(s, /n_dim) eq 0) then return, [s]

  return, s

end
