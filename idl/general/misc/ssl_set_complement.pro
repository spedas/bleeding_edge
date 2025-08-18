;+
;Purpose: Calculates the complement of l2 - l1
;          (ie set difference)
;
;Arguments: l1 subset,l2 superset
;          
;
;Notes: empty set is -1L
;       all inputs must be empty set or arrays
;       all outputs will be empty set or arrays
;       Arrays must be of homogenous type
;
;-

function ssl_set_complement, l1, l2

  if(size(l1, /n_dim) eq 0 && l1 eq -1L) then return, l2

  if(size(l2, /n_dim) eq 0 && l2 eq -1L) then return, -1L

  if(size(l2, /n_dim) eq 0) then begin 
    dprint, 'argument l2 to ssl_set_complement should be of type array'
    return, -1L
  endif

  if(size(l1, /n_dim) eq 0) then begin
    dprint, 'argument l1 to ssl_set_complement should be of type array'
    return, -1L
  endif

  ;probably is a better implementation
  xs = array_cross(l1, l2)

  idx = where(xs[0, *] eq xs[1, *], cnt)

  if(cnt eq 0) then return, l2

  n_l2 = n_elements(l2)

  ;indices where the elements are equal
  idx = idx mod(n_elements(l2))

  ;now use index to mask out the proper elements
  
  mask = ul64indgen(n_l2)

  mask[idx] = -1L

  mask = where(mask ne -1L)

  if(size(mask, /n_dim) eq 0 && mask eq -1L) then return, -1L

  out = l2[mask]

  ;sort out to use uniq
;  out = out[sort(out)]

 ; out = out[uniq(out)]

  if(size(out, /n_dim) eq 0) then return, [out]

  return, out

end    
  
