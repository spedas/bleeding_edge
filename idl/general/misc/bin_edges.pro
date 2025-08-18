;This function takes an array of length n, assumes its elements are
;midpoint values for bins and returns an n+1-element array of bin
;edges. 
; created by Robert Lillis

function bin_edges, x, min = min, max = max

  n = n_elements(x)
  diff = 0.5*(x[1:*]-x[0:n-2])
  y = [x[0], x[0:n-2] + diff, x[n-1]]
  
  if keyword_set(min) then y[0] = min
  if keyword_set(max) then y[n]  = max
  return, y
end
