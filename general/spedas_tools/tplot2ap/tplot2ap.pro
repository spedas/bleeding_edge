;+
;
; PROCEDURE:
;         tplot2ap
;
; PURPOSE:
;         Send tplot variables to Autoplot
;         
; INPUT:
;         tvars:  string or array of tplot variables to send to Autoplot
;         
; KEYWORDS:
;         port: Autoplot server port (default: 12345)
;         connect_timeout: connection timeout time in seconds (default: 6s)
;         read_timeout: read timeout time in seconds (default: 30s)
;         local_data_dir: set the local data directory
;         clear_cache: delete all temporary CDF files stored in the local data directory
;
; EXAMPLE:
;         IDL> tplot2ap, 'tplot_variable'
;         
; NOTES:
;         For this to work, you'll need to open Autoplot and enable the 'Server' feature via
;         the 'Options' menu with the default port (12345)
;         
;         This routine sends the tplot data to Autoplot via a CDF file stored in your 
;         default local data directory (so this creates a 'temporary' file every time you
;         send data to Autoplot)
;
;         On Windows, you'll have to allow Autoplot / SPEDAS to have access to the 
;         local network via the Firewall (it should prompt automatically, simply 
;         click 'Allow' for private networks)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-05-22 08:38:07 -0700 (Tue, 22 May 2018) $
; $LastChangedRevision: 25244 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/tplot2ap/tplot2ap.pro $
;-

pro tplot2ap, tvars, port=port, connect_timeout=connect_timeout, read_timeout=read_timeout, local_data_dir=local_data_dir, clear_cache=clear_cache
  if undefined(port) then port = 12345
  if undefined(connect_timeout) then connect_timeout = 6 ; seconds
  if undefined(read_timeout) then read_timeout = 30 ; seconds
  
  if undefined(local_data_dir) then local_data_dir = spd_default_local_data_dir() + 'autoplot/'
  
  if keyword_set(clear_cache) then begin ; here be dragons
    file_delete, local_data_dir, /recursive
    return
  endif
  
  if undefined(tvars) then begin
    dprint, dlevel=0, 'Error - no tplot variables specified'
    dprint, dlevel=0, 'Syntax: tplot2ap, ["variable"]'
    return
  endif
  
  ; allow the user to input tplot #s instead of the full names
  for tvar_idx=0, n_elements(tvars)-1 do begin
    tvars_test = tnames(tvars[tvar_idx])
    append_array, tvars_input, tvars_test
  endfor
  
  if ~undefined(tvars_input) then tvars = tvars_input
  
  ; make sure to create the local data directory if it doesn't already exist
  dir_exists = file_test(local_data_dir, /directory)
  if ~dir_exists then file_mkdir2, local_data_dir
  
  cdf_filename = local_data_dir+'tplot2ap' + strcompress(string(randomu(seed, 1, /long)), /rem)
  tplot2cdf, filename=cdf_filename, tvars=tvars, /default
  
  socket, unit, '127.0.0.1', port, /get_lun, error=error, read_timeout=read_timeout, connect_timeout=connect_timeout
  
  if error ne 0 then begin
    dprint, dlevel=0, 'Error - problem connecting to Autoplot'
    dprint, dlevel=0, 'Ensure the server feature is enabled'
    return
  endif
  
  ; the directory needs to be escaped prior to sending to Autoplot on Windows machines
  cdf_filename = strjoin(strsplit(cdf_filename, '\', /extract), '\\')
  
  for tvar_idx=0, n_elements(tvars)-1 do begin
    extra_str = ''
    metadata = spd_extract_tvar_metadata(tvars[tvar_idx])
    if metadata.ylog eq 1b then extra_str += ', ylog="1"' else extra_str += ', ylog="0"'
    if metadata.zlog eq 1b then extra_str += ', zlog="1"' else extra_str += ', zlog="0"'
    if ~array_equal(metadata.yrange, [0, 0]) then extra_str += ', yrange=['+strcompress(string(metadata.yrange[0]), /rem)+', '+strcompress(string(metadata.yrange[1]), /rem)+']'
    if ~array_equal(metadata.zrange, [0, 0]) then extra_str += ', zrange=['+strcompress(string(metadata.zrange[0]), /rem)+', '+strcompress(string(metadata.zrange[1]), /rem)+']'

    printf, unit, 'plotx('+strcompress(string(tvar_idx), /rem)+', "'+cdf_filename+'.cdf?'+tvars[tvar_idx]+'", title="'+metadata.catdesc+'", ztitle="'+metadata.ztitle+'", ytitle="'+metadata.ytitle+'"'+extra_str+');'
  endfor

  ; pause required on Windows before freeing the handle, otherwise the previous plot() command fails
  wait, 1
  free_lun, unit
end