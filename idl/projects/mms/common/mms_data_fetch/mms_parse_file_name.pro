; This routine will parse the names of a list of files and obtain relevant info
; for caching MMS data.
; NOTE: we are assuming the directory path is ALREADY truncated off of each
; file name, unless "contains_dir" keyword is set.


pro mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
                         optional_descriptors, version_strings, start_strings, years, $
                         contains_dir = contains_dir

sc_ids = strarr(n_elements(flist))
inst_ids = sc_ids
modes = sc_ids
levels = sc_ids
optional_descriptors = sc_ids
version_strings = sc_ids
start_strings = sc_ids
years = sc_ids

for i = 0, n_elements(flist)-1 do begin
  
  temp = flist(i)
  
  if keyword_set(contains_dir) then begin
    first_slash = strpos(flist(i), path_sep(), /reverse_search)
    temp = strmid(flist(i), first_slash+1, strlen(flist(i)))
  endif
  
  field_array = strsplit(temp, '_', /extract)
  sc_ids(i) = field_array(0)
  inst_ids(i) = field_array(1)
  modes(i) = field_array(2)
  levels(i) = field_array(3)
  
  ; Check for optional descriptors
  if n_elements(field_array) eq 7 then begin
    optional_descriptors(i) = field_array(4)
    start_strings(i) = field_array(5)
    version_base = field_array(6)
  endif else begin
    optional_descriptors(i) = ''
    start_strings(i) = field_array(4)
    version_base = field_array(5)
  endelse
  
  ; Extract version string by removing '.cdf'
  dot = strpos(version_base, '.', /reverse_search)
  version_strings(i) = strmid(version_base, 0, dot)  
  
  years(i) = strmid(start_strings(i), 0, 4)

endfor

end