; Execute a IDLnetURL query with the given netURL, url_path and query.
; If 'filename' is set, this will download the result to the given filename
; and return the path to the downloaded file.
; If 'filename' is not set, this will return the results as an array of strings.
; If an error occurs, a message will be printed and an error code (LONG) returned.
;
function execute_mms_sitl_query, netURL, url_path, query, filename=filename

  ; Check for bad netURL -- if not an object, simply return it
  if (size(netURL, /type) ne 11) then return, netURL

  ;TODO: reuse for Put? diff set of error codes to look for

  catch, error_status
  if (error_status ne 0) then begin
    catch, /cancel ; Cancel catch so other errors don't get caught here.
    netURL->GetProperty, RESPONSE_CODE=code

    ;TODO: let callers print messages?
    case code of
      0: begin
        printf, -2, "ERROR connecting to the LASP SDC."
        printf, -2, "This ERROR is likely due to an issue with the LASP load balancer."
        printf, -2, "The full URL throwing this error is:"
        netURL->GetProperty, url_host=error_host
        netURL->GetProperty, url_path=error_path
        netURL->GetProperty, url_query=error_query
        netURL->GetProperty, url_scheme=error_scheme
        printf, -2, error_scheme + "://" + error_host + "/" + error_path + "?" + error_query
        stop
      end
      200: begin
        ; false error, one known case is an empty file
        catch, /cancel
        return, 0L
      end
      204: printf, -2, "WARNING in execute_mms_sitl_query: No results found."
      206: printf, -2, "WARNING in execute_mms_sitl_query: Only partial results were returned."
      404: begin
        printf, -2, "ERROR in execute_mms_sitl_query: Service not found."
      end
      401: begin
        mms_sitl_logout
        printf, -2, "ERROR in execute_mms_sitl_query: Login failed. Try again."
      end
      500: printf, -2, "ERROR in execute_mms_sitl_query: Service failed to handle the query: " + url_path + '?' + query
      23: printf, -2, "ERROR in execute_mms_sitl_query: Not able to save result to: " + filename
      else: begin
         printf, -2, "ERROR in execute_mms_sitl_query: Service request failed with IDL error code: " + strtrim(error_status,2) + $
           " and http response: " + strtrim(code, 2)   
        ; help, !error_state
        error_map = spd_neturl_error2msg()
        if code lt n_elements(error_map) then dprint, dlevel = 0, 'HTTPS Error: ' + error_map[code] else help, !error_state
      end
    endcase
    return, code ;the http or other IDLnetURL error code (http://www.exelisvis.com/docs/IDLnetURL.html#objects_network_1009015_1417867)
  endif

  ; Set the path and query for the request.
  netURL->SetProperty, URL_PATH=url_path
  netURL->SetProperty, URL_QUERY=query
  netURL->SetProperty, timeout=5400

  ; Make the request.
  ; If the 'filename' parameter is set, assume we want to download a file.
  ; Otherwise, get the results as a string array.
  if (n_elements(filename) eq 1) then result = netURL->Get(filename=filename)  $  ;download file, result should be path of file
  else result = netURL->Get(/string_array)  ;get results as array of comma separated values

  ; Cancel catch so other errors don't get caught here.
  catch, /cancel

  return, result
end