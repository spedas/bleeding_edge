;+
; Execute the given query and return the results in an array of
; structures of the given type. 
; This may return an error code or -1 if no data are found.
;-
function execute_latis_query, path, query, struct, embedded_delimiters=embedded_delimiters

  ;Get IDLnetUrl object. May prompt for login.
  ;connection = get_mms_sitl_connection(host="sdc-web1", port="8080") ;for internal testing
  connection = get_mms_sitl_connection()
  
  ;Make the request. Get an array of comma separated value strings.
  data = execute_mms_sitl_query(connection, path, query)
  
  ;Check if we got an error code instead of string data.
  if size(data, /type) ne 7 then return, data ;return error code
  
  ;Check that we at least got some text (e.g. header) back 
  ;  so it won't break when we try to remove the header below.
  ;  Return -1 indicating that there is no data to return.
  ;Note, empty results may also have an empty line
  ;  which this test won't catch, but parse_records will skip it
  ;  returning -1 itself.
  if n_elements(data) le 1 then return, -1  ;return value implies no data

  ;Drop one line header
  data = data[1:*]
  
  ;Convert the data from a array of records  with comma separated values
  ;to an array of structures containing the data with the appropriate types.
  result = parse_records(data, struct, embedded_delimiters=embedded_delimiters)

  return, result
end