;+
;Procedure:
;  spd_download_handler
;
;
;Purpose:
;  Handle errors thrown by the IDLnetURL object used in spd_download_file.
;  HTTP responses will be caught and handled.  All other exceptions will 
;  be reissued for a higher level error handler to catch.
;
;
;Calling Sequence:
;  spd_download_handler, net_object=net_object, url=url, filename=filename
;
;
;Input:
;  net_object:  Reference to IDLnetURL object
;  url:  String specifying URL of remote file
;  filename:  String specifying path (full or partial) to (requested) local file
;  callback_error:  Flag denoting that an exception occurred in the callback function
;
;
;Output:
;  None 
;
;
;Notes:
;
;   egrimes, 3/20/17 - no longer reissuing last error, now meaningful printing error 
;                      msg from spd_neturl_error2msg map
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-20 10:49:45 -0700 (Mon, 20 Mar 2017) $
;$LastChangedRevision: 22996 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_download_handler.pro $
;
;-

pro spd_download_handler, net_object=net_object, $
                          url=url, $
                          filename=filename, $
                          callback_error=callback_error

    compile_opt idl2, hidden


;catch exceptions from idlneturl callback function and reissue
;  -if caught normally the file will remain locked by idl
if keyword_set(callback_error) then begin
  message, 'Error in callback function; scroll up for details'
  return  
endif

;get response code and header
net_object->getproperty, response_code=response_code, response_header=response_header, url_scheme=url_scheme


;Handle http responses.
;  -handle common responses separately, other's will be printed with header
;  -if there's no valid http response then it is likely a programmatic error;
case response_code of
 
  ;  0: message, /reissue_last
    
    2: dprint, dlevel=0, sublevel=1, 'Unknown error initializing; cannot download:  '+url

   42: dprint, dlevel=2, sublevel=1, 'Download canceled by user: '+url

  301: dprint, dlevel=1, sublevel=1, 'File "'+url+'" permanently moved: ', response_header
  304: dprint, dlevel=2, sublevel=1, 'File is current:  '+filename
  400: dprint, dlevel=0, sublevel=1, 'Bad request; cannot download:  '+url
  401: dprint, dlevel=1, sublevel=1, 'Unauthorized to access:  '+url
  403: dprint, dlevel=1, sublevel=1, 'Access forbidden:  '+url
  404: dprint, dlevel=1, sublevel=1, 'File not found:  '+url
  405: dprint, dlevel=1, sublevel=1, 'Method not allowed: ' + url
  406: dprint, dlevel=1, sublevel=1, 'Response not acceptable: '+url
  407: dprint, dlevel=1, sublevel=1, 'Proxy authentication required: ' + url
  408: dprint, dlevel=1, sublevel=1, 'Request timeout: ' + url
  409: dprint, dlevel=1, sublevel=1, 'Conflict: ' + url
  410: dprint, dlevel=1, sublevel=1, 'Gone: ' + url
  500: dprint, dlevel=1, sublevel=1, 'Internal server error: ' + url
  501: dprint, dlevel=1, sublevel=1, 'Not implemented: ' + url
  502: dprint, dlevel=1, sublevel=1, 'Bad gateway: ' + url
  503: dprint, dlevel=1, sublevel=1, 'Service unavailable: ' + url
  504: dprint, dlevel=1, sublevel=1, 'Gateway timeout: ' + url
  509: dprint, dlevel=1, sublevel=1, 'Bandwidth limit exceeded: ' + url

  else: begin
    error_map = spd_neturl_error2msg()
    dprint, dlevel=1, sublevel=1,  'Unable to download file:  '+url
    if response_code lt n_elements(error_map) then begin
      dprint, dlevel=1, sublevel=1, strupcase(url_scheme)+' Error: ' + error_map[response_code]
    endif else begin
      dprint, dlevel=2, sublevel=1,  strupcase(url_scheme)+' Response: '+strtrim(response_code,2)
      dprint, dlevel=2, sublevel=1,  strupcase(url_scheme)+' Header: '+response_header
    endelse
  endelse

endcase


end