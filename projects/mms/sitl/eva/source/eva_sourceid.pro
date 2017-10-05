FUNCTION eva_sourceid
  compile_opt idl2
  common mms_sitl_connection, netUrl, connection_time, login_source
  
  type = size(netUrl, /type) ;will be 11 if object has been created
  if (type eq 11) then begin
    netUrl->GetProperty, URL_USERNAME = username
  endif else begin
    message,'Something is wrong'
  endelse
  return, username+'(EVA)'
END
