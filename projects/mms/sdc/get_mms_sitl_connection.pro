; Get an IDLnetUrl object with login credentials.
; The user should only be prompted once per IDL session to login.
; Use common block to manage a singleton instance of a IDLnetURL
; so it will remain alive in the IDL session unless it has expired.
function get_mms_sitl_connection, host=host, port=port, authentication=authentication, $
  group_leader=group_leader, rebuild=rebuild, username=username, password=password, $
  PROXY_AUTHENTICATION=proxy_authentication, PROXY_HOSTNAME=proxy_hostname, $
  PROXY_PASSWORD=proxy_password, PROXY_PORT=proxy_port, PROXY_USERNAME=proxy_username
  
  common mms_sitl_connection, netUrl, connection_time, login_source
  
  ; Define the length of time the login will remain valid, in seconds.
  expire_duration = 86400 ;24 hours
  
  ; Test if login has expired. If so, destroy the IDLnetURL object and replace it with -1
  ; so the login will be triggered below.
  if (n_elements(connection_time) eq 1) then begin
    duration = systime(/seconds) - connection_time
    if (duration gt expire_duration) then mms_sitl_logout
  endif
  
  if n_elements(host) eq 0 then host = "lasp.colorado.edu"  ;"sdc-web1"  ;"dmz-shib1"
  if n_elements(port) eq 0 then port = 80
  if n_elements(authentication) eq 0 then authentication = 1 ;basic
  
  ;Make sure the singleton instance has been created
  ;TODO: consider error cases, avoid leaving incomplete netURL in common block
  type = size(netUrl, /type) ;will be 11 if object has been created
  doRebuild = 0
  if (type eq 11) then begin
    if keyword_set(rebuild) then doRebuild = 1
  endif else begin
    doRebuild = 1
  endelse
  if (doRebuild eq 1) then begin
    ; Construct the IDLnetURL object and set the login properties.
    netUrl = OBJ_NEW('IDLnetUrl')
    netUrl->SetProperty, URL_HOST = host
    netUrl->SetProperty, URL_PORT = port
    
    ;If authentication is requested, get login from user and add to netURL properties
    if authentication gt 0 then begin
      ;If we have a failed or expired login, make sure we use the gui if we did last time
      if (n_elements(login_source) eq 1) then group_leader = login_source
      
      ;If the caller requested the gui login option, save that in the common block
      ;so we can use the same login mechanism if the login fails or expires.
      if n_elements(group_leader) eq 1 then login_source = group_leader
      
      if n_elements(username) eq 0 or n_elements(password) eq 0 then begin
        ;Get the login credentials
        login = mms_sitl_login(group_leader=group_leader)
        username = login.username
        password = login.password
      endif
      
      netUrl->SetProperty, URL_SCHEME = 'https'
      netUrl->SetProperty, SSL_VERIFY_HOST = 0 ;don't worry about certificate
      netUrl->SetProperty, SSL_VERIFY_PEER = 0
      ;1: basic only, 2: digest, 3: try both
      netUrl->SetProperty, AUTHENTICATION = authentication
      netUrl->SetProperty, URL_USERNAME = username
      netUrl->SetProperty, URL_PASSWORD = password

      ; if proxy_hostname is given, set up for proxy authentication
      if n_elements(proxy_hostname) gt 0 && strlen(proxy_hostname) gt 0 then begin
        if n_elements(proxy_authentication) eq 0 then begin
          ; default to trying both basic and digest
          proxy_authentication = 3
        endif
        netUrl->SetProperty, PROXY_AUTHENTICATION = proxy_authentication
        netUrl->SetProperty, PROXY_HOSTNAME = proxy_hostname
        netUrl->SetProperty, PROXY_PASSWORD = proxy_password
        netUrl->SetProperty, PROXY_PORT = proxy_port
        netUrl->SetProperty, PROXY_USERNAME = proxy_username
      endif

      ; check that the connection is valid
      ; only when authentication enabled to avoid
      ; breaking tests, which assume a single connection on a specified port
      status = validate_mms_sitl_connection(netUrl)
      if status ne 0 then begin
        ; clear the connection
        junk = size(temporary(netUrl))
        return, status
      endif
    endif
    
    ; Set the time of the login so we can make it expire.
    connection_time = systime(/seconds)
  endif
  
  ;TODO: if parameters are set and netURL already exists, reset properties

  return, netUrl
end


