; this function can be called to determine whether the given netUrl is valid, i.e.,
; hits a valid LaTiS server with appropriate authentication
function validate_mms_sitl_connection, netUrl

  ;A simple fast call that goes through any front-end proxies
  ;and into LaTiS
  path = "mms/sdc/sitl/latis/dap/properties.txt"
  query = "version"
  
  ;Make the request. Get the text response
  data = execute_mms_sitl_query(netUrl, path, query)

  ;Check if we got an error code instead of string data.
  if size(data, /type) ne 7 then return, data ;return error code

  ;Check that we at least got some text back
  if n_elements(data) lt 1 then return, -1  ;return value implies no data

  return, 0
end
