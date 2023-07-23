function n_finite, array
  wh = where(finite(array) eq 1)
  if wh[0] eq -1 then return, 0 else return, n_elements(wh)
end
