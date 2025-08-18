;Given data in the form of an array of records (e.g. row of an ASCII table)
;split each record by the optional delimiter (default is ",") and map the 
;values to the given structure.
;Return an array of structures (one for each sample) containing the data.
function parse_samples, samples, struct, delimiter=delimiter

  ;Make sure we have a delimiter defined.
  if not keyword_set(delimiter) then delimiter = ","
  
  ;Get the number of samples.
  nsamp = n_elements(samples)
  
  ;Construct an array of structures to contain the parsed data.
  result = replicate(struct, nsamp)

  ;Keep an array of variable types to help with parsing.
  ;Do it once here instead of repeating for every sample.
  nvar = n_tags(struct)
  types = intarr(nvar)
  for ivar = 0, nvar-1 do begin
    types[ivar] = size(struct.(ivar), /type)
  endfor
  
  ;parse each row, put values into data structure
  for i = 0, nsamp-1 do begin
    ss = strsplit(samples[i], delimiter, /extract)
    ;TODO: if n_elements(ss) ne nvar then skip? error?
    for ivar = 0, n_elements(ss)-1 do begin
      if types[ivar] eq 7 then result[i].(ivar) = ss[ivar]  $ ;string value
      else result[i].(ivar) = double(ss[ivar]) ;assume value is numeric
      ;Note, this type test and cast to double is needed because scientific 
      ;notation won't be parsed correctly when assigned to an integer type.
    endfor
  endfor
  
  return, result

end