function eva_replace_string, input_string, old, new, remove = remove
  compile_opt idl2

  a_split = strsplit(a, '_', /extract)

  nmax = n_elements(remove)
  for n = 0, nmax - 1 do begin
    idx = where(strmatch(a_split, remove[n], /fold_case), complement = cidx, ncomp = ncomp)
    a_split = a_split[cidx]
  endfor
  a = strjoin(a_split, '!C')
  return, a

  ; -------------------
  ; Replace substrings
  ; -------------------
  output_string = input_string
  pos = strpos(output_string, old)

  while pos ne -1 do begin
    ; Replace the old-substring with new-substring
    output_string = strmid(output_string, 0, pos) + new + strmid(output_string, pos + 1, strlen(output_string) - pos - 1)
    ; Find the next old-substring
    pos = strpos(output_string, old)
  endwhile

  RETURN, output_string
end