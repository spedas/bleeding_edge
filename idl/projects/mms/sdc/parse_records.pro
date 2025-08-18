;Given data in the form of an array of records (e.g. row of an ASCII table)
;split each record by the optional delimiter (default is ",") and map the 
;values to the given structure.
;Return an array of structures (one for each record) containing the data.
;If embedded delimiters is set, extra fields in the last column are combined into a single field
function parse_records, records, struct, delimiter=delimiter, embedded_delimiters=embedded_delimiters

  ;Make a copy of the struct that we can mutate.
  tmp_struct = replicate(struct, 1)

  ;Make sure we have a delimiter defined.
  if not keyword_set(delimiter) then delimiter = ","
  
  ;Get the number of records.
  nsamp = n_elements(records)

  ;Keep an array of variable types to help with parsing.
  ;Do it once here instead of repeating for every sample.
  nvar = n_tags(struct)
  types = intarr(nvar)
  for ivar = 0, nvar-1 do begin
    types[ivar] = size(struct.(ivar), /type)
  endfor
  
  ;Start with the result set to -1 indicating no valid records parsed.
  result = -1
  
  ;parse each record, put values into data structure
  for i = 0, nsamp-1 do begin
    ;Skip this record if we get a double conversion error
    on_ioerror, skip
      
    ;Split the record into values.
    ss = strsplit(records[i], delimiter, /extract, /preserve_null)

    ;Skip invalid records where the number of values != number of variables.
    if n_elements(ss) ne nvar then begin
      if keyword_set(embedded_delimiters) && n_elements(ss) gt nvar then begin
        ;Combine the extra fields into the last field
        last = ss[nvar-1]
        for l=nvar,n_elements(ss)-1 do begin
          last += delimiter + ss[l]
        endfor
        ss = [ss[0:nvar-2], last]
      endif else begin
        ;print,'skipping ' + records[i]
        continue
      endelse
    endif
    
    for ivar = 0, n_elements(ss)-1 do begin
      if types[ivar] eq 7 then tmp_struct.(ivar) = ss[ivar]  $ ;string value
      else tmp_struct.(ivar) = double(ss[ivar]) ;assume value is numeric
      ;Note, this type test and cast to double is needed because scientific 
      ;notation won't be parsed correctly when assigned to an integer type.
    endfor
    
    if size(result, /type) ne 8 then result = tmp_struct  $  ;first valid sample
    else result = [result, tmp_struct]  ;append sample
    goto, ok
    
    skip: ;sent here if we get a double conversion error
      ;print, 'skipping ' + records[i]
    ok:
  endfor
  
  return, result
end