; This sorts mms filenames by start date.
; Done because the SDC may not give files in the correct order.
; 

function mms_sort_filenames_by_date, flist

; First parse filenames to get start date:

mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
  optional_descriptors, version_strings, start_strings, years, /contains_dir
  
mms_parse_start_string, start_strings, months, days, years, hours, minutes, seconds

file_juls = julday(fix(months), fix(days), fix(years), fix(hours), $
                   fix(minutes), double(seconds))

new_flist = flist(sort(file_juls))

return, new_flist

end