;+
;FUNCTION:
;  thm_asi_get_urls
;
;PURPOSE:
;  Retrieve the URLs of files available for download from the data
;  archive for a given dataset, timeframe, and optional site.
;  This is the file-listing step of this loading path for
;  THEMIS ASI data; the file GETs themselves are done by
;  thm_asi_download.
;
;INPUT:
;  dataset_name: dataset to list, e.g. 'THEMIS_ASI_RAW' (string)
;  start_ts:     start timestamp, ISO format YYYY-MM-DDTHH:MM:SS (string)
;  end_ts:       end timestamp (inclusive), same format (string)
;
;KEYWORDS:
;  site_uid:   4-letter site UID to filter on, e.g. 'fykn' (string)
;  device_uid: device UID to filter on, e.g. 'themis08' (string)
;  verbose:    dprint verbosity passthrough
;
;OUTPUT:
;  Structure with tags urls (list of full https URLs), count, path_prefix,
;  and dataset (struct with data_tree_url etc.), as returned by the API.
;  Returns !null on any request/parse failure.
;
;EXAMPLE:
;  u = thm_asi_get_urls('THEMIS_ASI_RAW', $
;        '2008-02-10T07:00:00','2008-02-10T07:59:59', site_uid='fykn')
;
;NOTES:
;  Proxies are resolved by thm_asi_proxy, so a proxy configured the
;  usual SPEDAS way works here with no extra setup:
;    setenv, 'http_proxy=http://proxy.example.org:3128'
;-
function thm_asi_get_urls, dataset_name, start_ts, end_ts, $
  site_uid = site_uid, device_uid = device_uid, verbose = verbose

  compile_opt idl2

  cfg = thm_asi_config()

  ; build query string
  param_str = '?include_total_bytes=true'
  param_str += '&name=' + dataset_name
  param_str += '&start=' + start_ts
  param_str += '&end=' + end_ts
  if keyword_set(site_uid) then param_str += '&site_uid=' + strlowcase(site_uid)
  if keyword_set(device_uid) then param_str += '&device_uid=' + device_uid

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = cfg.api_host
  req.setProperty, url_path = cfg.urls_endpoint + param_str
  req.setProperty, headers = 'User-Agent: ' + cfg.user_agent

  ; honor the same proxy configuration the rest of SPEDAS uses for downloads
  ; (http_proxy, via spd_get_proxy), as well as the idl-aurorax
  ; AURORAX_PROXY_* variables; thm_asi_proxy resolves between them
  proxy_props = thm_asi_proxy(verbose = verbose)
  if is_struct(proxy_props) then req.setProperty, _extra = proxy_props

  ; trap request errors
  catch, error_status
  if (error_status ne 0) then begin
    catch, /cancel
    req.getProperty, response_code = response_code
    dprint, dlevel=0, verbose=verbose, 'thm_asi_get_urls: API request failed, ' + $
      'HTTP response code ' + strtrim(response_code, 2) + ' (' + !error_state.msg + ')'
    obj_destroy, req
    return, !null
  endif

  ; make request, read body directly as strings
  output = req.get(/string_array)
  req.getProperty, response_code = response_code
  catch, /cancel
  obj_destroy, req

  if (response_code ne 200) then begin
    dprint, dlevel=0, verbose=verbose, 'thm_asi_get_urls: unexpected HTTP response code ' + $
      strtrim(response_code, 2)
    return, !null
  endif

  ; serialize into struct; a non-JSON body (e.g. an intercepting proxy or
  ; captive portal answering 200 with HTML) must fail soft like any other
  ; request failure, so the parse is trapped too
  catch, parse_error
  if (parse_error ne 0) then begin
    catch, /cancel
    dprint, dlevel=0, verbose=verbose, 'thm_asi_get_urls: could not parse API ' + $
      'response (' + !error_state.msg + ')'
    return, !null
  endif
  result = json_parse(strjoin(output), /tostruct)

  dprint, dlevel=3, verbose=verbose, 'thm_asi_get_urls: ' + $
    strtrim(result.count, 2) + ' file(s) listed for ' + dataset_name
  catch, /cancel

  return, result
end
