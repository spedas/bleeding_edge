function submit_mms_sitl_selections, local_file
  ;make sure file is valid
  catch, error_status
  if (error_status ne 0) then begin
    printf, -2, "ERROR: " + !ERROR_STATE.MSG
    catch, /cancel
    return, -1
  endif
  
  restore,local_file
  catch, /cancel
  
  ;TODO: check file name format
  ; e.g. sitl_selections_2013-05-01-00-00-00.sav, bdm_sitl_changes...?
  
  ; Make sure save file has valid contents.
  ; It should have a FOMSTR structure.
  if (size(fomstr,/type) ne 8) then begin
    printf, -2, "ERROR: Not a valid SITL save file: " + local_file
    return, -1
  endif
  

  ; Make sure we have just the file name, not its path.
  file = file_basename(local_file)
  
  size = (file_info(local_file)).size
  ;TODO: check if too large? or just let service tell us
  
  url_path = "/mms/sdc/sitl/files/api/v1/upload"
  query = "file=" + file

  ;connection = get_mms_sitl_connection(host='sdc-web1', authentication=0)
  connection = get_mms_sitl_connection()
  connection->SetProperty, URL_PATH=url_path
  connection->SetProperty, URL_QUERY=query
  connection->SetProperty, HEADERS="Content-Length: " + strtrim(size,2)
  
  catch, error_status
  if (error_status ne 0) then begin
    connection->GetProperty, RESPONSE_CODE=code
    case code of
      401: begin
        mms_sitl_logout
        printf, -2, "ERROR: Login failed. Try again."
      end
      411: printf, -2, "ERROR: The HTTP request header does not include the Content-Length."
      413: printf, -2, "ERROR: The file size ("+strtrim(size,2)+" bytes) exceeds the maximum size." 
      400: printf, -2, "ERROR: Invalid file name."  ;TODO: add guidance
      500: printf, -2, "ERROR: The server was not able to handle this request."
      else: begin
        printf, -2, "ERROR: Service request failed with error code: " + strtrim(code,2)
        help, !error_state
      end
    endcase
    catch, /cancel
    return, -1
  endif

  result = connection->Put(local_file, /POST)
  ;The result is the name of the file containing the status.
  ;IDLnetURL property: RESPONSE_FILENAME  but can't set it!
  
  catch, /cancel
  return, 0
end
