; Uses the MMS day_info/ancillary web service to find the best
; ancillary file for a sc_id, product, and day.
; Returns the file_name. If it needs to be downloaded,
; you can use the get_mms_ancillary_file routine to download it
; based on the file_name returned by this function.
; Product can be defeph or predeph to get the best ephemeris file,
; or defatt or predatt to get the best attitude file.
function get_mms_best_ancillary_file_name, sc_id, product, date

  if n_elements(sc_id) ne 1 then begin
    printf, -2, "Exactly one sc_id must be specified"
    return, -1
  endif
  if n_elements(product) ne 1 then begin
    printf, -2, "Exactly one product must be specified"
    return, -1
  endif
  if n_elements(date) ne 1 then begin
    printf, -2, "Exactly one date must be specified"
    return, -1
  endif
  
  ; Web API defined with lower case.
  sc_id   = strlowcase(sc_id)
  product = strlowcase(product)
 
  ; Build query.
  query_args = ["sc_id=" + sc_id]
  query_args = [query_args, "product=" + product]
  query_args = [query_args, "start_date=" + date]
  query_args = [query_args, "end_date=" + date]
  query = strjoin(query_args, "&")

  connection = get_mms_sitl_connection()

  ; get the json response with best file name
  url_path = "/mms/sdc/sitl/files/api/v1/day_info/ancillary"
  result = execute_mms_sitl_query(connection, url_path, query)
  
  ; Check for error (long integer code as opposed to json string)
  if (size(result, /type) eq 3) then return, result

  day_files = json_parse(result)
  if n_elements(day_files) gt 0 then begin
    ; there will be exactly 1 in this case
    day_file = day_files[0]
    file_name = day_file['file_name']
    return, file_name
  endif
  
  return, -1  
end
