;+
; Procedure:
;  check_esa_hapi_connection
;
; Purpose:
;  Functions to connect and retrive data from the ESA HAPI server.
;
;
; Example use:
; 
;   RESOLVE_ROUTINE, 'check_esa_hapi_connection', /COMPILE_FULL_FILE, /EITHER
;   url = "https://swe.ssa.esa.int/hapi/catalog/"
;   if check_esa_hapi_connection() eq 1 then res=get_esa_hapi_data(url)
;   dprint, res
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-03-19 10:51:14 -0700 (Thu, 19 Mar 2026) $
;$LastChangedRevision: 34275 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/check_esa_hapi_connection.pro $
;-


FUNCTION esa_hapi__is_hash, value
  COMPILE_OPT IDL2

  tname = STRUPCASE(SIZE(value, /TNAME))

  ; Some IDL versions represent parsed JSON objects as HASH/ORDEREDHASH directly.
  IF (tname EQ 'HASH') OR (tname EQ 'ORDEREDHASH') THEN RETURN, 1B

  IF tname NE 'OBJREF' THEN RETURN, 0B
  IF ~OBJ_VALID(value) THEN RETURN, 0B

  cls = STRUPCASE(OBJ_CLASS(value))
  RETURN, (cls EQ 'HASH') OR (cls EQ 'ORDEREDHASH')
END


FUNCTION esa_hapi__is_json_object, value
  COMPILE_OPT IDL2

  tname = STRUPCASE(SIZE(value, /TNAME))
  IF tname EQ 'STRUCT' THEN RETURN, 1B
  IF esa_hapi__is_hash(value) THEN RETURN, 1B
  RETURN, 0B
END


FUNCTION esa_hapi__has_key, obj, key
  COMPILE_OPT IDL2

  key_u = STRUPCASE(key)

  IF esa_hapi__is_hash(obj) THEN RETURN, obj.HASKEY(key)

  IF STRUPCASE(SIZE(obj, /TNAME)) EQ 'STRUCT' THEN BEGIN
    tags = STRUPCASE(TAG_NAMES(obj))
    idx = WHERE(tags EQ key_u, count)
    RETURN, (count GT 0)
  ENDIF

  RETURN, 0B
END


FUNCTION esa_hapi__get_value, obj, key, FOUND=found
  COMPILE_OPT IDL2

  found = 0B
  key_u = STRUPCASE(key)

  IF esa_hapi__is_hash(obj) THEN BEGIN
    IF obj.HASKEY(key) THEN BEGIN
      found = 1B
      RETURN, obj[key]
    ENDIF
    RETURN, ''
  ENDIF

  IF STRUPCASE(SIZE(obj, /TNAME)) EQ 'STRUCT' THEN BEGIN
    tags = STRUPCASE(TAG_NAMES(obj))
    idx = WHERE(tags EQ key_u, count)
    IF count GT 0 THEN BEGIN
      found = 1B
      RETURN, obj.(idx[0])
    ENDIF
  ENDIF

  RETURN, ''
END


FUNCTION esa_hapi__http_request, url, METHOD=method, HEADER=header, POST_FIELDS=post_fields, STATUS_CODE=status_code
  COMPILE_OPT IDL2

  IF N_ELEMENTS(method) EQ 0 THEN BEGIN
    method_lc = 'get'
  ENDIF ELSE BEGIN
    method_lc = STRLOWCASE(STRTRIM(method, 2))
    IF method_lc EQ '' THEN method_lc = 'get'
  ENDELSE

  cmd = 'curl -sS -L --max-time 30 -w "\n__HTTP_STATUS__:%{http_code}"'

  IF method_lc EQ 'post' THEN cmd += ' -X POST'

  IF N_ELEMENTS(header) GT 0 THEN BEGIN
    IF STRTRIM(header, 2) NE '' THEN cmd += ' -H "' + header + '"'
  ENDIF

  IF N_ELEMENTS(post_fields) GT 0 THEN BEGIN
    IF STRTRIM(post_fields, 2) NE '' THEN cmd += ' --data "' + post_fields + '"'
  ENDIF

  cmd += ' "' + url + '"'

  output = ''
  exit_status = 1L
  SPAWN, cmd, output, /SH, EXIT_STATUS=exit_status

  status_code = 0L
  IF exit_status NE 0 THEN RETURN, ''

  n = N_ELEMENTS(output)
  IF n LE 0 THEN RETURN, ''

  last_line = output[n - 1]
  marker = '__HTTP_STATUS__:'
  marker_pos = STRPOS(last_line, marker)
  IF marker_pos NE 0 THEN RETURN, ''

  code_str = STRMID(last_line, STRLEN(marker))
  status_code = LONG(code_str)

  IF n EQ 1 THEN RETURN, ''
  RETURN, STRJOIN(output[0:n - 2], STRING(10B))
END


FUNCTION get_esa_hapi_connection
  COMPILE_OPT IDL2

  issuer = 'https://sso.s2p.esa.int/realms/swe/.well-known/openid-configuration'
  scope = 'openid swe_hapiserver'
  ; The following values are temporary. 
  ; Users should obtain and use their own "client_id" and "client_secret" as described in the readme file.
  client_id = 'd2908e964bbfc8cd25bdf2dcaa4e5e1b'
  client_secret = 'y3akZhgnoj9cDDsPRPATrPBjgo2pNpRU'

  metadata_text = esa_hapi__http_request(issuer, STATUS_CODE=metadata_status)
  IF (metadata_status LT 200) OR (metadata_status GE 300) THEN BEGIN
    PRINT, 'Error creating ESA connection: failed to fetch OIDC metadata.'
    RETURN, ''
  ENDIF

  metadata = JSON_PARSE(metadata_text)
  IF ~esa_hapi__is_json_object(metadata) THEN BEGIN
    PRINT, 'Error creating ESA connection: invalid OIDC metadata.'
    RETURN, ''
  ENDIF
  IF ~esa_hapi__has_key(metadata, 'token_endpoint') THEN BEGIN
    PRINT, 'Error creating ESA connection: token endpoint not found.'
    RETURN, ''
  ENDIF
  token_url = esa_hapi__get_value(metadata, 'token_endpoint')

  ; STRREPLACE is not available in some IDL versions; use fixed encoded scope.
  scope_enc = 'openid%20swe_hapiserver'
  form_data = 'grant_type=client_credentials' + $
    '&scope=' + scope_enc + $
    '&client_id=' + client_id + $
    '&client_secret=' + client_secret

  token_text = esa_hapi__http_request(token_url, METHOD='POST', $
    HEADER='Content-Type: application/x-www-form-urlencoded', $
    POST_FIELDS=form_data, STATUS_CODE=token_status)

  IF (token_status LT 200) OR (token_status GE 300) THEN BEGIN
    PRINT, 'Error creating ESA connection: failed to fetch token.'
    RETURN, ''
  ENDIF

  token_json = JSON_PARSE(token_text)
  IF ~esa_hapi__is_json_object(token_json) THEN BEGIN
    PRINT, 'Error creating ESA connection: invalid token response.'
    RETURN, ''
  ENDIF
  IF ~esa_hapi__has_key(token_json, 'access_token') THEN BEGIN
    PRINT, 'Error creating ESA connection: access_token missing.'
    RETURN, ''
  ENDIF

  token = esa_hapi__get_value(token_json, 'access_token')
  RETURN, 'Authorization: Bearer ' + token
END


FUNCTION get_esa_hapi_data, url
  COMPILE_OPT IDL2

  auth_header = get_esa_hapi_connection()
  IF STRTRIM(auth_header, 2) EQ '' THEN RETURN, ''

  response_text = esa_hapi__http_request(url, HEADER=auth_header, STATUS_CODE=http_status)
  IF (http_status LT 200) OR (http_status GE 300) THEN BEGIN
    PRINT, 'Error getting data from ' + url + ': HTTP request failed.'
    RETURN, ''
  ENDIF

  RETURN, response_text
END


function check_esa_hapi_connection
  COMPILE_OPT IDL2

  capabilities_url = 'https://swe.ssa.esa.int/hapi/capabilities/'
  capabilities_text = get_esa_hapi_data(capabilities_url)
  ; print, capabilities_text
  IF STRTRIM(capabilities_text, 2) EQ '' THEN RETURN, 0B

  capabilities = JSON_PARSE(capabilities_text)
  IF ~esa_hapi__is_json_object(capabilities) THEN RETURN, 0B
  IF ~esa_hapi__has_key(capabilities, 'status') THEN RETURN, 0B

  status = esa_hapi__get_value(capabilities, 'status')
  IF ~esa_hapi__is_json_object(status) THEN RETURN, 0B

  message_ok = 0B
  code_ok = 0B

  IF esa_hapi__has_key(status, 'message') THEN message_ok = (esa_hapi__get_value(status, 'message') EQ 'OK')
  IF esa_hapi__has_key(status, 'code') THEN code_ok = (FIX(esa_hapi__get_value(status, 'code')) EQ 1200)

  RETURN, (message_ok OR code_ok)
END


