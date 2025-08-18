; Download ground-loop selections files.
; This is just like ABS selections, except that the GLS files can also be
; categorized with an algorithm type. The default algorithm type is
; "mp-dl-unh". Algorithm name must not contain '_'.
; If no start_time, end_time, or filename is specified, only the latest file
; with given algorithm type is downloaded.
function get_mms_gls_selections, start_time=start_time, end_time=end_time,  $
  local_dir=local_dir, filename= filename, algorithm=algorithm
  
  if n_elements(algorithm) eq 0 then algorithm = "mp-dl-unh"
  type = "gls_selections_" + algorithm

  status = get_mms_selections_file(type, start_time=start_time, $
    end_time=end_time, local_dir=local_dir, filename=filename)

  return, status  
end

