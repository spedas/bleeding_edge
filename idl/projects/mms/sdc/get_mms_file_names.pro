function get_mms_file_names, type, query=query, public=public
  ;type: science, ancillary, sitl_selection

  url_path = keyword_set(public) ? "mms/sdc/public/files/api/v1/file_names/" + type : "mms/sdc/sitl/files/api/v1/file_names/" + type
  if n_elements(query) eq 0 then query = ""
  
  connection = get_mms_sitl_connection()
  result = execute_mms_sitl_query(connection, url_path, query)
  ; Check for error (long integer code as opposed to array of strings)
  if (size(result, /type) eq 3) then return, result
  ;Note: empty array = !NULL not supported before IDL8

  names = strsplit(result, ",", /extract)
  
  return, names
end
