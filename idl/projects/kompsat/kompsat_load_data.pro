;+
; Procedure:
;  kompsat_load_data
;
; Purpose:
;  Load data from KOMPSAT.
;  This code works only for IDL 9.1 or higher.
;
; Keywords:
;     trange:     Time range of interest (array with 2 elements, start and end time)
;     dataset:    Four datasets are available: recalib (default), 1m, p, e
;                 Two datasets for SOSMAG magnetometer: recalib (recalibrated, default) and 1m (1 min, real-time):
;                      'spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_recalib'
;                      'spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_1m'
;                 Two datasets for particle detector: e (electrons), p (protons):
;                      'spase://SSA/NumericalData/GEO-KOMPSAT-2A/kma_gk2a_ksem_pd_e_l1'
;                      'spase://SSA/NumericalData/GEO-KOMPSAT-2A/kma_gk2a_ksem_pd_p_l1'
;     prefix:     String to append to the beginning of the loaded tplot variable names
;     suffix:     String to append to the end of the loaded tplot variable names
;     tplotvars:  Returned array of strings, with the tplot variables that were loaded
;
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2025-03-14 13:38:31 -0700 (Fri, 14 Mar 2025) $
;$LastChangedRevision: 33177 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/kompsat_load_data.pro $
;-


pro esa_hapi_auth, token=token
  ; This function requires IDL 9.1 or higher to work correctly

  compile_opt idl2
  token = '' ; indicates error during connection

  ; Catch errors.
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    token = ''
    dprint, ' Error while trying to connect to ESA HAPI server. '
    dprint, !error_state.msg
    return
  endif

  authURL = 'https://sso.ssa.esa.int/am/json/authenticate'
  kompsat_read_password, username=username, password=password

  authHeaders = orderedhash("Content-type","application/json", $
    "X-OpenAM-Username", username, $
    "X-OpenAM-Password", password)

  authResponse = HTTPREQUEST.POST(authURL,headers=authHeaders)

  if (authResponse.ok) then dprint,'POST request for token completed!' else dprint,'POST request for token failed'
  ; dprint,authResponse.text

  token = ((JSON_PARSE(authResponse.text)).Values())[0]

  infoURL = 'https://swe.ssa.esa.int/hapi/capabilities/'
  infoHeaders = orderedhash("Cookie", "iPlanetDirectoryPro="+token)
  curlOptions = orderedhash("COOKIEJAR", "", "UNRESTRICTED_AUTH", 1)

  infoResponse = HTTPREQUEST.GET(infoURL,headers=infoHeaders,options=curlOptions)
  if (infoResponse.ok) then dprint,'GET request for server info completed!' else dprint,'GET request for server info failed'
  ; dprint,infoResponse.text

  result = STRMATCH(infoResponse.text, '*"message":"OK"*')
  if result eq 1 then begin
    dprint, 'Connected to ESA HAPI Server.'
  endif else begin
    token = ''
    dprint, 'Could not connect to ESA HAPI Server.'
  endelse

end

pro esa_hapi_server_parse, datastr=datastr, dataset=dataset, prefix=prefix, suffix=suffix, tplotvars=tplotvars
  ; Parse the data returned by the ESA HAPI server and create tplot variables
  ; Return the names of created tplot variables with tplotvars

  compile_opt idl2

  tplotvars = ''

  ; Catch errors.
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    dprint, ' Error while trying to parse data returned by ESA HAPI server. '
    dprint, !error_state.msg
    return
  endif

  data_json = json_parse(datastr)
  ; Save data into tplot variables.
  if data_json.haskey("data") then begin
    d = data_json["data"]
    if data_json.haskey("parameters") then param = data_json["parameters"] else param=''
    if data_json.haskey("description") then desc = data_json["description"] else desc=''
    nd = n_elements(d)
    if nd gt 0 then begin
      if n_elements(param) eq n_elements(d[0]) &&  n_elements(param) gt 1 then begin
        dd = d.toarray()
        kompsat_to_tplot, dd, param=param, desc=desc, dataset=dataset,prefix=prefix, suffix=suffix, tplotvars=tplotvars

      endif else begin
        dprint, 'There is a problem with the parameters of the data received from the server.'
      endelse
    endif else begin
      dprint, "Empty data was received from server."
    endelse
  endif else begin
    dprint, "No data was received from server."
  endelse

  dprint, 'tplotvars: ', tplotvars

end

pro kompsat_load_data, trange=trange, dataset=dataset, prefix=prefix, suffix=suffix, tplotvars=tplotvars

  compile_opt idl2

  ; Catch errors.
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    dprint, ' Error while trying to download data from ESA HAPI server. '
    dprint, !error_state.msg
    return
  endif

  ; Set default values to parameters
  tplotvars = '' ; returned tplot variables loaded
  if undefined(prefix) then prefix=''
  if undefined(suffix) then suffix=''
  ; Set a default date if none is given.
  if ~keyword_set(trange) || n_elements(trange) ne 2 then begin
    trange = ['2024-04-23/00:00:00', '2024-04-24/00:00:00']
  endif
  t0 = time_string(trange[0], precision=3)
  timemin = t0.replace('/', 'T') + "Z"
  t1 = time_string(trange[1], precision=3)
  timemax= t1.replace('/', 'T') + "Z"

  ; Get the IDL version
  version = !VERSION.RELEASE

  ; Convert version string to float for comparison
  version_num = FLOAT(version)

  ; Check if version is less than 9.1
  if version_num lt 9.1 then begin
    dprint, 'Error: This procedure requires IDL version 9.1 or higher. ' + $
      'Your current version is ' + version + '.'
    dprint, 'You can download data manually as CSV, and then use kompsat_load_csv.pro to load the file into tplot.'
    return
  endif

  ; Connect to server and get a token
  esa_hapi_auth, token=token
  if token eq '' then return

  ; Format the string
  if undefined(dataset) then dataset = 'recalib'
  if dataset eq 'p' then begin
    dataid = 'spase://SSA/NumericalData/GEO-KOMPSAT-2A/kma_gk2a_ksem_pd_p_l1'
  endif else if dataset eq 'e' then begin
    dataid = 'spase://SSA/NumericalData/GEO-KOMPSAT-2A/kma_gk2a_ksem_pd_e_l1'
  endif else if dataset eq '1m' || dataset eq '1min' then begin
    dataid = 'spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_1m'
  endif else dataid = 'spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_recalib'

  dataURL = 'https://swe.ssa.esa.int/hapi/data?id=' + dataid + '&time.min=' + timemin + '&time.max=' + timemax + '&format=json'

  infoHeaders = orderedhash("Cookie", "iPlanetDirectoryPro="+token)
  curlOptions = orderedhash("COOKIEJAR", "", "UNRESTRICTED_AUTH", 1)
  dataResponse = HTTPREQUEST.GET(dataURL,headers=infoHeaders,options=curlOptions)

  if (dataResponse.ok) then begin
    dprint,'GET data request for server data completed!'
  endif else begin
    print,'GET data request for server data failed'
    return
  endelse

  if strlen(dataResponse.text) le 10 then begin
    dprint, 'No data for the given parameters.'
    return
  endif

  esa_hapi_server_parse, datastr=dataResponse.text, dataset=dataset, prefix=prefix, suffix=suffix, tplotvars=tplotvars

end

