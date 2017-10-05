;+
;NAME:
; mvn_set_userpass,username,password
;PURPOSE:
; Sets the username and password for automatic file retrieval
;Typical Usage:  
;  mvn_set_userpass,'joe@gmail.com','passwd!'[,/TEMPORARY]   ; This line is typically put in your IDL_STARTUP routine.
;Keywords:
;  TEMPORARY:   Set this keyword to prevent the username and password from being stored in an environment variable 
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro mvn_set_userpass,username,password,TEMPORARY=TEMPORARY
   if ~keyword_set(TEMPORARY) then setenv,'MAVENPFP_USER_PASS=' + idl_base64( byte( username+':'+password) )
   s = mvn_file_source(/set,USER_PASS = idl_base64( byte( username+':'+password)) )
end
