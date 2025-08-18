function array, min, max, n
  return, min + ((max - min)/(n-1))*dindgen(n)
end
