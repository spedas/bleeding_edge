;+
;
; PROCEDURE:
;         ap2tplot
;
; PURPOSE:
;         Loads the data from the current Autoplot window into tplot variables
;
; KEYWORDS:
;         port: Autoplot server port (default: 12345)
;         connect_timeout: connection timeout time in seconds (default: 6s)
;         read_timeout: read timeout time in seconds (default: 30s)
;         local_data_dir: set the local data directory
;         clear_cache: delete all temporary CDF files stored in the local data directory
;
; EXAMPLE:
;         IDL> ap2tplot
;
; NOTES:
;         This routine is very experimental; please report problems/comments/etc to:  egrimes@igpp.ucla.edu
;         
;         Please use the latest devel release of Autoplot: http://autoplot.org/jnlp/devel/
;         
;         For this to work, you'll need to open Autoplot and enable the 'Server' feature via
;         the 'Options' menu with the default port (12345)
;
;         This routine sends the Autoplot data to tplot via a CDF file stored in your
;         default local data directory (so this creates a 'temporary' file every time you
;         send data to Autoplot)
;
;         On Windows, you'll have to allow Autoplot / SPEDAS to have access to the
;         local network via the Firewall (it should prompt automatically, simply
;         click 'Allow' for private networks)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-04-15 14:00:43 -0700 (Mon, 15 Apr 2019) $
; $LastChangedRevision: 27020 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/tplot2ap/ap2tplot.pro $
;-

pro ap2tplot, port=port, connect_timeout=connect_timeout, read_timeout=read_timeout, local_data_dir=local_data_dir, clear_cache=clear_cache
  if undefined(port) then port = 12345
  if undefined(connect_timeout) then connect_timeout = 6 ; seconds
  if undefined(read_timeout) then read_timeout = 30 ; seconds

  if undefined(local_data_dir) then local_data_dir = spd_default_local_data_dir() + 'autoplot/'
  
  if keyword_set(clear_cache) then begin ; here be dragons
    file_delete, local_data_dir, /recursive
    return
  endif
  
  ; check that the output directory exists
  dir_test = file_test(local_data_dir, /directory)
  
  if ~dir_test then begin
    file_mkdir2, local_data_dir
  endif
  
  spd_graphics_config ; setup the standard SPEDAS graphics config
  
  socket, unit, '127.0.0.1', port, /get_lun, error=error, read_timeout=read_timeout, connect_timeout=connect_timeout

  if (n_elements(unit) eq 0) then begin
    dprint, dlevel=0, 'Unable to connect to Autoplot, see Options->Enable Feature->Server'
    return
  endif
  
  ; wait for the connection
  wait, 0.1
  
  ; get the number of plots in the canvas
  printf, unit, "print len(dom.plots)"
  len_plots = ''
  readf, unit, len_plots
  
  if (strlen(len_plots) eq 0) then begin
    readf, unit, len_plots
  endif
  
  len_plots = (strsplit(len_plots, 'autoplot> ', /extract))[0]
  len_plots = fix(len_plots)
  
  ; Reset the prompt to start with a newline.
  printf, unit, "dom.controller.applicationModel.prompt='\nautoplot> '"     ; WRITE
 ; wait, 1
  ap_var = ''
  readf, unit, ap_var
  readf, unit, ap_var
  
  for i=0l, len_plots-1 do begin
    printf, unit, "print guessName(dom.plotElements["+strcompress(string(i), /rem)+"].controller.dataSet)" 
    ap_var = ''
    readf, unit, ap_var
    readf, unit, ap_var

    ; variable name returned with autoplot>
    var_name = strmid(ap_var, 10, strlen(ap_var)-1)
    
    if var_name eq 'None' then var_name = 'unknown'
    
    local_data_dir = strjoin(strsplit(local_data_dir, '\', /extract), '/')
    tmp_filename = local_data_dir + 'ap2tplot'+strcompress(string(randomu(seed, 1, /long)), /rem)+'.cdf'
    wait, 1
    printf, unit, "formatDataSet(dom.plotElements["+strcompress(string(i), /rem)+"].controller.dataSet, '"+tmp_filename+"?"+var_name+"')"

    readf, unit, ap_var                                          ; READ
    
    spd_cdf2tplot, tmp_filename, /all
    
    undefine, var_name
    
  endfor

  close, unit
end