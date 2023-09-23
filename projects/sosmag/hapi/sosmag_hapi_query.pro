;+
; Procedure:
;  sosmag_hapi_query
;
; Purpose:
;  Sends a query to SOSMAG HAPI server.
;  Receives a json answer.
;
;
; Notes:
;  SOSMAG HAPI server is: 'https://swe.ssa.esa.int/hapi/'
;  As of 2021/12/03 the server has non-standard behavior that requires special treatment:
;    1. It requires username and password for each user.
;    2. The catalog contains 134 datasets, but only 2 are actually available.
;    3. By design, it returns Error 500 responses that cannot be parsed by json.
;  All the above may be changed in the future.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2023-09-05 16:26:53 -0700 (Tue, 05 Sep 2023) $
;$LastChangedRevision: 32080 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/sosmag/hapi/sosmag_hapi_query.pro $
;-

function sosmag_get_status_filename
  ; This function provides a filename where all HTTPS responses are written.
  dir = FILE_DIRNAME(ROUTINE_FILEPATH(), /MARK_DIRECTORY)
  sfilename = dir + 'session_cookies.txt'
  return, sfilename
end

function url_callback_s, status, progress, data
  ; Callback function for HTTP.
  ; Writes server responses to file.

  sfilename = sosmag_get_status_filename()
  status_str = string(status)
  set_cookie = status_str.Contains('Set-Cookie')
  if set_cookie eq 1 then begin
    this_cookie = status_str.Substring(status_str.IndexOf('Set-Cookie')+12, status_str.IndexOf(';')-1)
    ; write it to the file
    openw, tokenunit, sfilename, /get_lun, /append
    printf, tokenunit, this_cookie
    free_lun, tokenunit
  endif

  location = status_str.Contains('Location: ')
  if location eq 1 then begin
    ; write it to the file
    openw, tokenunit, sfilename, /get_lun, /append
    printf, tokenunit, status_str
    free_lun, tokenunit
  endif

  return, 1
end

function print_callback_s, status, progress, data
  ; Callback function for HTTP.
  ; Prints server responses to console.
  print, status
  return, 1
end

pro sosmag_reset_cookies_file
  ; Create a file to store the next 2 tokens.
  sfilename = sosmag_get_status_filename()
  openw, tokenunit, sfilename, /get_lun
  ; Close the file. We'll write the tokens to it in the IDLnetURL callback function.
  free_lun, tokenunit
end

function sosmag_get_auth_cookie, username, password
  ; Send username password, receive three cookies.

  catch, Error_status
  IF Error_status NE 0 THEN BEGIN
    dprint, 'ERROR_STATE: ', !ERROR_STATE.MSG
    dprint, 'Error: Check username and password, file: sosmag_password.txt'
    dprint, 'Username:', username.trim(), ", Password:", password.trim()
    catch, /cancel
    return, '-1'
  ENDIF

  oUrl = OBJ_NEW('IDLnetUrl')
  oUrl->SetProperty, verbose = 1
  oUrl->SetProperty, url_scheme = 'https'
  oUrl->SetProperty, ssl_verify_host = 0
  oUrl->SetProperty, ssl_verify_peer = 0
  oUrl->SetProperty, connect_timeout = 4
  oUrl->SetProperty, timeout = 4
  oUrl->SetProperty, url_host = 'sso.ssa.esa.int'
  oUrl->SetProperty, url_path = 'am/json/authenticate'
  oUrl->SetProperty, headers=["Content-Type: application/json", "X-OpenAM-Username: " + username, "X-OpenAM-Password: " + password]
  auth_cookie_data = oUrl->put("{}", /post, /buffer, /string_array)

  ; The response is going to be in json.
  cookie_json = sosmag_json_parse(auth_cookie_data)
  auth_cookie = cookie_json['tokenId']
  success_cookie = cookie_json['successUrl']

  if success_cookie eq '' then begin
    dprint, "Error: Authentication problem.'
    auth_cookie = '-1'
  endif

  ; Return the auth cookie.
  return, auth_cookie

end

function sosmag_get_session_cookie, auth_cookie
  ; Use the three cookies to request HAPI server capabilites.
  ; This is done in order to set: decision=Allow&save_consent=on.
  ; Return the three cookies.

  catch, Error_status
  IF Error_status NE 0 THEN BEGIN
    dprint, 'ERROR_STATE: ', !ERROR_STATE.MSG
    catch, /cancel
    return, '-1'
  ENDIF

  sfilename = sosmag_get_status_filename()
  sosmag_reset_cookies_file

  ; Contact HAPI server to receive session id
  hapi = OBJ_NEW('IDLnetUrl')
  hapi->SetProperty, verbose = 1
  hapi->SetProperty, url_scheme = 'https'
  hapi->SetProperty, ssl_verify_host = 0
  hapi->SetProperty, ssl_verify_peer = 0
  hapi->SetProperty, connect_timeout = 4
  hapi->SetProperty, timeout = 4
  hapi->SetProperty, url_host = 'swe.ssa.esa.int'
  hapi->SetProperty, url_path = 'hapi/capabilities'
  hapi->SetProperty, callback_function = 'url_callback_s'
  hapi->SetProperty, headers=["Cookie: iPlanetDirectoryPro=" + auth_cookie]

  init_response = hapi->get(/buffer, /string_array)

  ; Read in the XSRF-TOKEN JSESSIONID and the consent URL
  consent_url = ''
  xsrf_token = ''
  jsessionid = ''

  openr, session_file, sfilename, /get_lun
  line = ''
  while ~eof(session_file) do begin
    readf, session_file, line
    line_str = string(line)
    if line_str.Contains('XSRF-TOKEN=') and strlen(xsrf_token) eq 0 then begin
      xsrf_token = line_str.Substring(line_str.IndexOf('XSRF-TOKEN=')+11, strlen(line_str))
    endif
    if line_str.Contains('JSESSIONID=') and strlen(jsessionid) eq 0 then begin
      jsessionid = line_str.Substring(line_str.IndexOf('JSESSIONID=')+11, strlen(line_str))
    endif
  endwhile
  free_lun, session_file

  ; Receive consent_url
  sosmag_reset_cookies_file
  consent = OBJ_NEW('IDLnetUrl')
  consent->SetProperty, verbose = 1
  consent->SetProperty, ssl_verify_host = 0
  consent->SetProperty, ssl_verify_peer = 0
  consent->SetProperty, connect_timeout = 4
  consent->SetProperty, timeout = 4
  consent->SetProperty, url_scheme = 'https'
  consent->SetProperty, callback_function = 'url_callback_s'
  consent->SetProperty, url_host = 'swe.ssa.esa.int'
  consent->SetProperty, url_path = 'login/openam'
  cookies_string = "Cookie: iPlanetDirectoryPro=" + auth_cookie+"; XSRF-TOKEN=" + xsrf_token+"; JSESSIONID=" + jsessionid
  consent->SetProperty, headers=[cookies_string]
  consent_loc = consent->put('{"decision":"Allow","save_consent":"on"}', /buffer,/post)

  ; Find the first Location Header, it is the correct one
  openr, session_file, sfilename, /get_lun
  line = ''
  while ~eof(session_file) do begin
    readf, session_file, line
    line_str = string(line)
    if line_str.Contains('Location: https://sso.ssa.esa.int') then begin
      consent_url = line_str.Substring(line_str.IndexOf('Location: ')+10, strlen(line_str))
      break
    endif
  endwhile
  free_lun, session_file

  ; Send the consent along with all cookies to the consent url.
  consent = OBJ_NEW('IDLnetUrl')
  consent->SetProperty, verbose = 1
  consent->SetProperty, ssl_verify_host = 0
  consent->SetProperty, ssl_verify_peer = 0
  consent->SetProperty, connect_timeout = 4
  consent->SetProperty, timeout = 4
  consent->SetProperty, url_scheme = 'https'
  consent->SetProperty, callback_function = 'url_callback_s'
  consent->SetProperty, url_host = 'swe.ssa.esa.int'
  consent->SetProperty, url_path = strmid(consent_url, 24)
  consent->SetProperty, headers=[cookies_string]

  consent_url = consent_url + "&decision=Allow&save_consent=on"
  ; data = '{"decision":"Allow","save_consent":"on"}'
  data = '{""}'
  consent_response = consent->put(data, url=consent_url, /buffer, /string_array, /post)
  consent_response = strtrim(strjoin(consent_response), 2)
  ;dprint, consent_response

  if consent_response eq '' || ~consent_response.Contains('"message":"OK"') then begin
    ; Problem with server response.
    return, '-1'
  endif

  return, cookies_string
end

pro sosmag_hapi_query, hquery=hquery, query_response=query_response
  ; Send a query to HAPI server and get a response.

  compile_opt idl2
  query_response = ''
  catch, Error_status
  IF Error_status NE 0 THEN BEGIN
    dprint, 'ERROR_STATE: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  ENDIF

  sosmag_read_password, username=username, password=password
  if username eq '' or password eq '' then begin
    dprint, 'Error: Could not read username and/or password.'
    query_response = '-1'
    return
  endif

  ; Get the cookies
  auth_cookie = sosmag_get_auth_cookie(username, password)
  if auth_cookie eq '-1' then begin
    dprint, 'Error: Could not communicate with HAPI server.'
    return
  endif

  ; Get the capabilities to verify that communication with server is functioning
  cookies_string = sosmag_get_session_cookie(auth_cookie)
  if cookies_string eq '-1' then begin
    dprint, 'Error: Could not communicate with HAPI server.'
    return
  endif

  ; hquery can be: capabilities, info, catalog, data
  if ~keyword_set(hquery) then hquery='capabilities'
  hquery_parts = strsplit(hquery, '?', /extract)
  switch hquery_parts[0] of
    'catalog': begin
      query_str = 'catalog'
      break
    end
    'info': begin
      query_str = hquery
      break
    end
    'data': begin
      query_str = hquery
      break
    end
    'capabilities': begin
      query_str = 'capabilities'
      break
    end
    else: begin
      dprint, "Error. HAPI query has a problem. Using 'capabilities' instead."
      query_str = 'capabilities'
      break
    end
  endswitch

  ; Send the query along with all cookies to the consent url.
  hapi_query = OBJ_NEW('IDLnetUrl')
  hapi_query->SetProperty, verbose = 1
  hapi_query->SetProperty, ssl_verify_host = 0
  hapi_query->SetProperty, ssl_verify_peer = 0
  hapi_query->SetProperty, connect_timeout = 4
  hapi_query->SetProperty, timeout = 4
  hapi_query->SetProperty, url_scheme = 'https'
  hapi_query->SetProperty, callback_function = 'url_callback_s'
  hapi_query->SetProperty, url_host = 'swe.ssa.esa.int'
  hapi_query->SetProperty, url_path = 'hapi/' + query_str
  hapi_query->SetProperty, headers=[cookies_string]

  url_full = 'https://swe.ssa.esa.int/hapi/' + query_str
  query_response = hapi_query->get(/buffer, /string_array)
  query_response = strtrim(strjoin(query_response), 2)

end