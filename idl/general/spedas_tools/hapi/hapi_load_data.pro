;+
; PROCEDURE:
;         hapi_load_data
;
; PURPOSE:
;         Load data and query information from a Heliophysics API server
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         capabilities: describes relevant capabilities for the HAPI server (optional)
;         catalog:      provides a list of datasets available from the HAPI server (optional)
;         info:         provides information on a given dataset (optional)
;         dataset:      dataset to load (optional)
;         
;         server:       HAPI server to connect to (e.g, 'http://datashop.elasticbeanstalk.com/hapi')
;         parameters:   limit the requested parameters to a string or array of strings (works in 
;                       conjunction with /info and trange= keywords) (optional)
;
; EXAMPLES:
;  List server capabilities:
;    IDL> hapi_load_data, /capabilities, server='http://datashop.elasticbeanstalk.com/hapi'
;    HAPI v1.1
;    Output formats: csv, binary, json
;  
;  List the datasets available on this server:
;    IDL> hapi_load_data, /catalog, server='http://datashop.elasticbeanstalk.com/hapi'
;    HAPI v1.1
;    1: CASSINI_LEMMS_PHA_CHANNEL_1_SEC
;    2: CASSINI_LEMMS_REG_CHANNEL_PITCH_ANGLE_10_MIN_AVG
;    ....
;  
;  Get info on a dataset:
;    IDL> hapi_load_data, /info, dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H', server='http://datashop.elasticbeanstalk.com/hapi'
;    HAPI v1.1
;    Dataset: spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H
;    Start: 1977-09-07T00:00:00.000
;    End: 2017-05-02T21:38:00.000
;    Parameters: Epoch, year, doy, hr, dec_year, dec_doy, flux, flux_uncert
;  
;  Load and plot the Voyager flux data:
;    IDL> hapi_load_data, trange=['77-09-27', '78-01-20'], dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H', server='http://datashop.elasticbeanstalk.com/hapi'
;    IDL> tplot, 'flux'
;    
;  Load and plot the Voyager flux data (limit the request to the 'flux' variable via the parameters keyword):
;    IDL> hapi_load_data, parameter='flux', trange=['77-09-27', '78-01-20'], dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H', server='http://datashop.elasticbeanstalk.com/hapi'
;    IDL> tplot, 'flux'
;  
; NOTES:
;         - capabilities, catalog, info keywords are informational
;         - Requires IDL 8.3 or later due to json_parse + orderedhash usage
;         
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2022-02-11 14:35:22 -0800 (Fri, 11 Feb 2022) $
;$LastChangedRevision: 30578 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/hapi/hapi_load_data.pro $
;-

function hapi_get_json, neturl
  neturl->getProperty, url_path=url_path
  table = json_parse(string(neturl->get(/buffer)))
  if table.HasKey('HAPI') then dprint, dlevel = 2,  'HAPI v' + table['HAPI']  + ' (' + url_path + ')'
  if table.HasKey('status') then begin
    if table['status'].hasKey('code') && table['status'].hasKey('message') then begin
      dprint, dlevel = 2, 'HAPI ' + strcompress(string((table['status'])['code']), /rem) + ' ' + (table['status'])['message']  + ' (' + url_path + ')'
    endif
  endif
  return, table
end

pro hapi_load_data, trange=trange, capabilities=capabilities, catalog=catalog, info=info, server=server, $
  dataset=dataset, path=path, port=port, scheme=scheme, prefix=prefix, tplotnames=tplotnames, timeout=timeout, $
  connect_timeout=connect_timeout, parameters=parameters, local_data_dir=local_data_dir, suffix=suffix

  t0 = systime(/seconds)
  dt_info_query = 0
  dt_download = 0
  
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    dprint, dlevel=0, !error_state.msg
    return
  endif
  if undefined(server) then begin
    ; https://github.com/hapi-server/servers/blob/master/all.txt
    dprint, dlevel = 0, 'Error, no server specified; example servers include:'
    dprint, dlevel = 0, '- https://cdaweb.gsfc.nasa.gov/hapi'
    dprint, dlevel = 0, '- https://pds-ppi.igpp.ucla.edu/hapi'
    dprint, dlevel = 0, '- http://planet.physics.uiowa.edu/das/das2Server/hapi'
    dprint, dlevel = 0, '- https://iswa.gsfc.nasa.gov/IswaSystemWebApp/hapi'
    dprint, dlevel = 0, '- http://lasp.colorado.edu/lisird/hapi'
    return
  endif else begin
    url_parts = parse_url(server)
    ; just in case the user specified a server without the scheme
    if url_parts.scheme eq '' then url_parts = parse_url('http://'+server)
    url_host = url_parts.host
    url_port = url_parts.port
    url_path = url_parts.path
    url_scheme = url_parts.scheme
  endelse
  
  if undefined(timeout) then timeout = 3600 ; 1 hour
  if undefined(connect_timeout) then connect_timeout = 360 ; 6 minutes
  
  if undefined(capabilities) and undefined(catalog) and undefined(info) and undefined(trange) then begin
    trange = timerange()
  endif
  
  if !version.release lt '8.3' then begin
    dprint, dlevel = 0, 'Error, this routine only supports IDL 8.3 and later due to  json_parse + orderedhash usage'
    return
  endif
  
  if undefined(path) then path = url_path
  if undefined(port) then port = url_port
  if undefined(scheme) then scheme = url_scheme
  if undefined(local_data_dir) then local_data_dir = 'hapi/'
  if undefined(suffix) then suffix = ''
  if undefined(prefix) then prefix=''
        
  ; the user specified a list of parameters
  if ~undefined(parameters) then begin
    para = strjoin(parameters, ',')
  endif
  
  dataset_table = hash()
  if keyword_set(dataset) then info_dataset = dataset else info_dataset = ''
  neturl = obj_new('IDLnetURL')
  param_names = []
  spd_graphics_config

  neturl->SetProperty, URL_HOST = url_host
  neturl->SetProperty, URL_PORT = port
  neturl->SetProperty, URL_SCHEME = scheme
  neturl->SetProperty, CONNECT_TIMEOUT = connect_timeout
  neturl->SetProperty, TIMEOUT = timeout
  neturl->SetProperty, ssl_verify_peer=0
  neturl->SetProperty, ssl_verify_host=0
  
  if keyword_set(capabilities) then begin
    neturl->SetProperty, URL_PATH=path+'/capabilities'
    capabilities = hapi_get_json(neturl)
    print, 'Output formats: ' + strjoin(capabilities['outputFormats'].toArray(), ', ')
  endif
  
  if keyword_set(catalog) or keyword_set(info) or keyword_set(trange) and info_dataset eq '' then begin
    neturl->SetProperty, URL_PATH=path+'/catalog'
    catalog = hapi_get_json(neturl)
    available_datasets = catalog['catalog']
    for dataset_idx = 0, n_elements(available_datasets)-1 do begin
      print, strcompress(string(dataset_idx+1), /rem) + ': ' + (available_datasets[dataset_idx])['id']
      dataset_table[strcompress(string(dataset_idx+1), /rem)] = (available_datasets[dataset_idx])['id']
    endfor
  endif
  
  if keyword_set(info) or keyword_set(trange) then begin
    if info_dataset eq '' then begin
      read, info_dataset, prompt='Select a dataset: '
      if dataset_table.hasKey(info_dataset) then info_dataset = dataset_table[info_dataset]
    endif
    
    if undefined(para) then $
      neturl->SetProperty, URL_PATH=path+'/info?id='+info_dataset $
    else $
      neturl->SetProperty, URL_PATH=path+'/info?id='+info_dataset+'&parameters='+para
    
    dt_info_t0 = systime(/sec)
    info = hapi_get_json(neturl)
    dt_info_query = systime(/sec)-dt_info_t0
    
    for param_idx = 0, n_elements(info['parameters'])-1 do begin
      append_array, param_names, ((info['parameters'])[param_idx])['name']
    endfor
    print, 'Dataset: ' + info_dataset
    print, 'Start: ' + info['startDate']
    print, 'End: ' + info['stopDate']
    print, 'Parameters: ' + strjoin(param_names, ', ')
  endif
  
  if keyword_set(trange) then begin
    time_min = time_string(time_double_ordinal(trange[0]), tformat='YYYY-MM-DDThh:mm:ss.fff')
    time_max = time_string(time_double_ordinal(trange[1]), tformat='YYYY-MM-DDThh:mm:ss.fff')

    if time_double(time_min) ge time_double_ordinal(info['startDate']) and time_double(time_max) le time_double_ordinal(info['stopDate']) then begin
      if undefined(para) then $
        neturl->SetProperty, URL_PATH=path+'/data?id='+info_dataset+'&time.min='+time_min+'&time.max='+time_max $
      else $
        neturl->SetProperty, URL_PATH=path+'/data?id='+info_dataset+'&time.min='+time_min+'&time.max='+time_max+'&parameters='+para
    endif else begin
      dprint, dlevel=0, 'No data available for this trange; data availability for '+info_dataset+' is limited to: ' + info['startDate'] + ' - ' + info['stopDate']
      return
    endelse

    data_directory = spd_addslash(local_data_dir) + spd_addslash(scheme) + spd_addslash(url_host) + spd_addslash(url_path) + 'data/' + spd_addslash(info_dataset)
    
    ; make sure no :'s show up in the directory
    data_directory = strjoin(strsplit(data_directory, ':', /extract))
    
    dir_exists = file_test(data_directory)
    if ~dir_exists then file_mkdir2, data_directory
    
    dt_t0 = systime(/sec)
    csv_data = neturl->get(filename=data_directory+'hapidata')
    dt_download = systime(/sec)-dt_t0
    
    csv = read_csv(csv_data)
    
    var_count = 0
    var_map = hash() ; maps variable name to variable index (index of the variable in the 'variables' variable..)
    
    ; extract the data
    for param_idx = 0, n_elements(info['parameters'])-1 do begin
      variable = (info['parameters'])[param_idx]
      variable['epoch'] = time_double_ordinal(csv.(0))

      if (info['parameters'])[param_idx].hasKey('size') then begin
        data = dblarr(n_elements(csv.(param_idx)), (((info['parameters'])[param_idx])['size'])[0])
        for data_idx = 0, (((info['parameters'])[param_idx])['size'])[0]-1 do begin
          thedata = csv.(param_idx+data_idx)
          if (info['parameters'])[param_idx].hasKey('fill') then begin
            datanofill = where(thedata le ((info['parameters'])[param_idx])['fill'], count)
            if count ne 0 then thedata[datanofill] = !values.d_nan
          endif
          data[*, data_idx] = thedata
        endfor
      endif else begin
        data = csv.(param_idx)
        if (info['parameters'])[param_idx].hasKey('fill') && ((info['parameters'])[param_idx])['fill'] ne !null then begin
          datanofill = where(data le ((info['parameters'])[param_idx])['fill'], count)
          if count ne 0 then data[datanofill] = !values.d_nan
        endif
      endelse
      
      ; check for spectra variables
      if (info['parameters'])[param_idx].hasKey('bins') then begin
        bin_data = ((info['parameters'])[param_idx])['bins']
        
        ; bins is specified as an array, presumably for multi-dimensional data
        if n_elements(bin_data) eq 1 then begin
          bin_centers = ((((info['parameters'])[param_idx])['bins'])[0])['centers']
          
          ; if the bins are specified as a list, assume these are the bin values
          if isa(bin_centers, 'list') then begin
            variable['v'] = bin_centers.ToArray()
          endif
          
          ; if the bins are specified as a string, assume this is a reference to the bin values
          ; store as the name of the parameter containing the V data for now; we'll look up the 
          ; actual values when creating the variable
          if isa(bin_centers, 'string') then begin
            variable['v'] = bin_centers
          endif
        endif
      endif
      
      variable['data'] = data
      var_map[variable['name']] = var_count
      
      append_array, variables, variable
      var_count += 1
    endfor
    
    ; turn the variable tables into proper tplot variables
    for var_idx = 0, n_elements(variables)-1 do begin
      if variables[var_idx].hasKey('name') and variables[var_idx].hasKey('epoch') and (variables[var_idx])['data'] ne !null then begin
        tname = prefix + strlowcase((variables[var_idx])['name']) + suffix
        
        if variables[var_idx].hasKey('v') then begin
          if isa((variables[var_idx])['v'], 'string') then begin 
            ; the y-values for the spectra are stored in another parameter
            bins = (variables[var_map[(variables[var_idx])['v']]])['data']
            store_data, tname, data={x: (variables[var_idx])['epoch'], y: (variables[var_idx])['data'], v: bins}
          endif else begin
            ; the y-values are stored in the info response
            store_data, tname, data={x: (variables[var_idx])['epoch'], y: (variables[var_idx])['data'], v: (variables[var_idx])['v']}
          endelse
          options, tname, 'spec', 1, /def
        endif else begin
          store_data, tname, data={x: (variables[var_idx])['epoch'], y: (variables[var_idx])['data']}
        endelse
        append_array, tplotnames, tname
      endif
    endfor
  endif
  
  dprint, dlevel=2, 'Time spent querying info from the server: ' + strtrim(dt_info_query, 2) + ' sec'
  dprint, dlevel=2, 'Time spent downloading the CSV data: ' + strtrim(dt_download, 2) + ' sec'
  dprint, dlevel=2, 'Total load time: ' + strtrim(systime(/sec)-t0, 2) + ' sec'
end