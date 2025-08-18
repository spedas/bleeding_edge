pro mms_sitl_logout
  common mms_sitl_connection, netUrl, connection_time
  
  obj_destroy, netUrl
  ; note from egrimes@igpp: undefining netUrl here leads to a crash 
  ; in get_mms_sitl_connection when the user gives an incorrect 
  ; password
  netUrl = 0  ; & dummy = temporary(netUrl)
  connection_time = 0 & dummy = temporary(connection_time)
end
