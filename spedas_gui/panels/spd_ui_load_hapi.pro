;+
;
;NAME:
; spd_ui_load_hapi
;
;PURPOSE:
; Load data from a HAPI server
;
;NOTES:
; 2021-12-05: Added ESA server for SOSMAG data.
;   Currently, this server does not behave as a standard HAPI server in some aspects
;   (needs passowrd, catalog contains non-available datasets, error 500 responses from server).
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 11:48:01 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30648 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_load_hapi.pro $
;-

function hapi_include_sosmag
  ; SOSMAG HAPI server is: 'https://swe.ssa.esa.int/hapi/'
  ; As of 2021/12/05 the server has non-standard behavior that requires special treatment:
  ; 1. It requires username and password for each user.
  ; 2. The catalog contains 134 datasets, but only 2 are actually available.
  ; 3. By design, it returns Error 500 responses for some queries (those cannot be parsed by json).
  ; The sosmag plugin is required for this server.

  addsosmag = 1

  ; Check if the sosmag directory exists.
  GETRESOURCEPATH, path ; start at the resources folder
  sosmag_dir = path + PATH_SEP(/PARENT_DIRECTORY)+ PATH_SEP() + PATH_SEP(/PARENT_DIRECTORY) + PATH_SEP() +  'projects'+ PATH_SEP() + 'sosmag' +PATH_SEP()

  if ~file_test(sosmag_dir, /read) then begin
    ; If that failed, try to find password file in current dir
    dir = FILE_DIRNAME(ROUTINE_FILEPATH(), /MARK_DIRECTORY)
    passfile = dir + 'sosmag_password.txt'
    if ~file_test(passfile, /read) then begin
      addsosmag = 0
    endif
  endif

  return, addsosmag

end

function hapi_server_is_sosmag, server
  ; Check if the server selected is sosmag server (ESA)
  if hapi_include_sosmag() ne 1 then return, 0

  if server eq 'https://swe.ssa.esa.int/hapi/' then return, 1

  return, 0
end

function hapi_sosmag_capabilities
  ; Return HAPI capabilities for SOSMAG
  hquery = 'capabilities'
  server_capabilities = ''

  sosmag_hapi_query, hquery=hquery, query_response=query_response
  if query_response eq '-1' || query_response eq '' then begin
    server_capabilities = ''
  endif else begin
    server_capabilities = sosmag_json_parse(query_response)
  endelse

  return, server_capabilities
end

function hapi_sosmag_datasets
  ; Return HAPI catalog datasets, only for SOSMAG datasets
  sosmag_datasets = []
  hquery = 'catalog'
  sosmag_hapi_query, hquery=hquery, query_response=query_response

  if query_response eq '-1' || query_response eq '' then begin
    sosmag_datasets = []
  endif else begin
    catalog = sosmag_json_parse(query_response)
    available_datasets = catalog['catalog']
    for i=0, n_elements(available_datasets)-1 do begin
      d = available_datasets[i]
      if n_elements(d) eq 2 && d.haskey('id') then begin
        d0 = strlowcase(d['id'])
        if d0[0].contains('sosmag') then begin
          sosmag_datasets = [sosmag_datasets, d]
        endif
      endif
    endfor
  endelse

  return, sosmag_datasets
end

function hapi_sosmag_info, dataset
  ; Return HAPI info for SOSMAG

  info_str = ''
  ;There is a problem for some ESA datasets
  catch, Error_status
  IF Error_status NE 0 THEN BEGIN
    dprint, 'ERROR_STATE: ', !ERROR_STATE.MSG
    dinfo = 'Error: No info available.'
    catch, /cancel
    return, dinfo
  ENDIF

  hquery = 'info?id='+dataset
  sosmag_hapi_query, hquery=hquery, query_response=query_response
  if query_response eq '-1' || query_response eq '' then begin
    info_str = ''
  endif else begin
    info_str = sosmag_json_parse(query_response)
  endelse

  return, info_str
end

pro hapi_sosmag_load_data, trange=trange, dataset=dataset, server=server, tplotnames=tplotvars, prefix=prefix
  ; Load HAPI data for SOSMAG
  sosmag_hapi_load_data, trange=trange, dataset=dataset, tplotnames=tplotvars, prefix=prefix
end

pro spd_ui_hapi_set_server, server, neturl=neturl

  url_parts = parse_url(server)
  if url_parts.scheme eq '' then url_parts = parse_url('http://'+server)
  url_host = url_parts.host
  url_port = url_parts.port
  url_path = url_parts.path
  url_scheme = url_parts.scheme

  neturl = obj_new('IDLnetURL')
  neturl->SetProperty, URL_HOST = url_host
  neturl->SetProperty, URL_PORT = url_port
  neturl->SetProperty, URL_SCHEME = url_scheme
  neturl->SetProperty, URL_PATH=url_path
  neturl->SetProperty, ssl_verify_peer=0
  neturl->SetProperty, ssl_verify_host=0


end

pro spd_ui_hapi_get_capabilities, server, capabilities=capabilities

  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
  capabilities = ''

  spd_ui_hapi_set_server, server, neturl=neturl

  neturl->GetProperty, URL_PATH=url_path
  neturl->SetProperty, URL_PATH=url_path+'/capabilities'

  if hapi_server_is_sosmag(server) then begin
    server_capabilities = hapi_sosmag_capabilities()
    if size(server_capabilities, /type) eq 11 then begin
      hversion = server_capabilities['version']
      outputFormats = strjoin(server_capabilities['outputFormats'].toArray(), ', ')
      capabilities = 'HAPI v' + hversion + newline + 'Output formats: ' + outputFormats
    endif else capabilities = 'Error communicating with server.' + newline + 'Check username and password.' + newline + 'File: sosmag_password.txt'
  endif else begin
    capabilities_str = string(neturl->get(/buffer))
    server_capabilities = json_parse(capabilities_str)
    hversion = server_capabilities['HAPI']
    outputFormats = strjoin(server_capabilities['outputFormats'].toArray(), ', ')
    capabilities = 'HAPI v' + hversion + newline + 'Output formats: ' + outputFormats
  endelse

end

pro spd_ui_hapi_get_datasets, server, datasets=datasets

  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)

  if hapi_server_is_sosmag(server) then begin
    available_datasets = hapi_sosmag_datasets()
  endif else begin
    spd_ui_hapi_set_server, server, neturl=neturl
    neturl->GetProperty, URL_PATH=url_path
    neturl->SetProperty, URL_PATH=url_path+'/catalog'
    catalog_str = string(neturl->get(/buffer))
    catalog = json_parse(catalog_str)
    available_datasets = catalog['catalog']
  endelse

  datasets = []
  for dataset_idx = 0, n_elements(available_datasets)-1 do begin
    datasets = [datasets, (available_datasets[dataset_idx])['id']]
  endfor
end

pro spd_ui_hapi_get_dataset_info, server, dataset, dinfo=dinfo

  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)

  ; If dataset is empty return an error message
  if dataset eq '' then begin
    dinfo = 'Error: please select a dataset from the list.'
    return
  endif

  if hapi_server_is_sosmag(server) then begin
    info = hapi_sosmag_info(dataset)
  endif else begin
    spd_ui_hapi_set_server, server, neturl=neturl
    neturl->GetProperty, URL_PATH=url_path
    neturl->SetProperty, URL_PATH=url_path+'/info?id='+dataset
    info_str = string(neturl->get(/buffer))
    info = json_parse(info_str)
  endelse

  if info eq '' then begin
    dinfo = 'Error: please refresh the dataset list.'
    return
  endif


  param_names = []
  for param_idx = 0, n_elements(info['parameters'])-1 do begin
    append_array, param_names, ((info['parameters'])[param_idx])['name']
  endfor
  dinfo = ''
  dinfo = dinfo + 'HAPI v' + info['HAPI'] + newline
  dinfo = dinfo + 'Dataset: ' + dataset + newline
  dinfo = dinfo + 'Start: ' + info['startDate'] + newline
  dinfo = dinfo + 'End: ' + info['stopDate'] + newline
  dinfo = dinfo + 'Parameters: ' + strjoin(param_names, ', ')

end

Pro spd_ui_load_hapi_event, ev

  widget_control, ev.id, get_uvalue=uval
  if undefined(uval) then return

  Widget_Control, ev.TOP, Get_UValue=state
  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)


  case uval of
    'SERVERLIST' : begin
      widget_control, state.selectedServer, get_value=oldserver
      index = ev.index
      server=state.hapi_servers[index]
      server = STRTRIM(server, 2)

      widget_control, state.selectedServer, set_value=server

      ; If the server changed, clear all textboxes
      if oldserver ne server then begin
        widget_control, state.capabilitiesLabel, set_value=''
        widget_control, state.datasetList, set_value=''
        widget_control, state.selectedDataset, set_value=''
        widget_control, state.dataInfoShowLabel, set_value=''
      endif

    end
    'SERVERINFO' : begin
      widget_control, state.selectedServer, get_value=server
      server = STRTRIM(server, 2)
      if server eq '' then begin
        msgshow = DIALOG_MESSAGE('Please select a HAPI server.')
        break
      endif
      spd_ui_hapi_get_capabilities, server, capabilities=capabilities
      widget_control, state.capabilitiesLabel, set_value=capabilities
    end
    'LOADSETS' : begin
      widget_control, state.selectedServer, get_value=server
      server = STRTRIM(server, 2)
      if server eq '' then begin
        msg = DIALOG_MESSAGE('Please select a HAPI server.')
        break
      endif
      spd_ui_hapi_get_datasets, server, datasets=datasets
      widget_control, state.datasetList, set_value=datasets
      state.datasets = ptr_new(datasets)
      Widget_Control, state.mainBase, Set_UValue=state
    end
    'DATASETLIST' : begin
      widget_control, state.selectedDataset, get_value=old_selected_dataset
      index = ev.index
      x = state.datasets
      sd = *x
      selected_dataset = sd[index]
      selected_dataset = STRTRIM(selected_dataset, 2)
      widget_control, state.selectedDataset, set_value=selected_dataset

      if old_selected_dataset ne selected_dataset then begin
        widget_control, state.dataInfoShowLabel, set_value=''
      endif

    end
    'DATAINFO' : begin
      widget_control, state.selectedServer, get_value=server
      server = STRTRIM(server, 2)
      widget_control, state.selectedDataset, get_value=selected_dataset
      selected_dataset = STRTRIM(selected_dataset, 2)
      spd_ui_hapi_get_dataset_info, server[0], selected_dataset[0], dinfo=dinfo
      widget_control, state.dataInfoShowLabel, set_value=dinfo

    end
    'LOADDATA': begin
      widget_control, state.selectedServer, get_value=server
      server = STRTRIM(server[0], 2)
      widget_control, state.selectedDataset, get_value=dataset
      dataset = STRTRIM(dataset[0], 2)
      widget_control, state.prefixText, get_value=prefix
      prefix = STRTRIM(prefix[0], 2)
      widget_control, state.timeWidget, get_value=timerange
      starttime = timerange.GetStartTime()
      endtime = timerange.getendtime()

      if hapi_server_is_sosmag(server) then begin
        if dataset[0] eq '' then begin
          msgshow = DIALOG_MESSAGE('Please select a dataset.', /information)
          break
        endif
        hapi_sosmag_load_data, trange=[starttime, endtime], dataset=dataset, server=server, tplotnames=tplotvars, prefix=prefix
      endif else begin
        hapi_load_data, trange=[starttime, endtime], dataset=dataset, server=server, tplotnames=tplotvars, prefix=prefix
      endelse

      if undefined(tplotvars) || n_elements(tplotvars) lt 1 then begin
        msgshow = DIALOG_MESSAGE('No variables could be loaded.', /information)
        break
      endif else begin
        spd_ui_tplot_gui_load_tvars, tplotvars
        msg = 'Loaded the following tplot variables: ' + newline + newline + strjoin(tplotvars, ', ')
        msgshow = DIALOG_MESSAGE(msg, /information)
        break
      endelse

    end
    'PREFIXTEXT': begin

    end
    'QUIT' : begin
      widget_control, ev.top, /destroy
    end


  endcase

end

Pro spd_ui_load_hapi, gui_id, historywin, statusbar,timeRangeObj=timeRangeObj

  mainBase = widget_base(/column, title = 'Load Data using HAPI', /modal, Group_Leader=gui_id)

  topBase = widget_base(mainbase, col=2, /align_top)
  bottomBase = widget_base(mainbase, col=2, /align_top)

  upLeftBase = widget_base(topBase, /col, /align_top)
  upRightBase = widget_base(topBase, /col, /align_top)

  botLeftBase = widget_base(bottomBase, /col, /align_top)
  botRightBase = widget_base(bottomBase, /col, /align_top)

  ;Select hapi server
  selectServerLabel = widget_label(upLeftBase, value='1. Select HAPI server', /align_top)
  ; https://github.com/hapi-server/servers/blob/master/all.txt
  hapi_servers=['https://cdaweb.gsfc.nasa.gov/hapi','https://pds-ppi.igpp.ucla.edu/hapi', $
    'http://planet.physics.uiowa.edu/das/das2Server/hapi','https://iswa.gsfc.nasa.gov/IswaSystemWebApp/hapi', $
    'http://lasp.colorado.edu/lisird/hapi']
  ; If there is a SOSMAG plugin, also include the ESA HAPI server which requires special treatment due to irregularities.
  if hapi_include_sosmag() eq 1 then hapi_servers=[hapi_servers, 'https://swe.ssa.esa.int/hapi/']

  serverList = widget_list(upLeftBase, value=hapi_servers, /align_top, ysize=n_elements(hapi_servers),uvalue='SERVERLIST', uname='SERVERLIST')
  selectServerLabelEmpty11 = widget_label(upLeftBase, value=' ', /align_top, /dynamic_resize)
  selectServerLabel = widget_label(upLeftBase, value='Selected HAPI server:', /align_top, /dynamic_resize)
  selectedServer = widget_text(upLeftBase, value=' ', /editable, /align_top, scr_xsize = 250 )
  selectServerLabelEmpty12 = widget_label(upLeftBase, value=' ', /align_top, scr_xsize = 250)
  getServerInfoButton = widget_button(upLeftBase, value = 'Get HAPI server info ', uvalue= 'SERVERINFO', /align_top)
  capabilitiesLabel = widget_label(upLeftBase, value=' ', /align_top, scr_xsize = 250, scr_ysize = 40, /dynamic_resize )

  ;Datasets
  listDatasetsLabel = widget_label(upRightBase, value='2. List datasets', /align_top)
  ;selectServerLabelEmpty21 = widget_label(upRightBase, value=' ', /align_top, scr_xsize = 250)
  loadButton = widget_button(upRightBase, value = ' Load Datasets from Server ', uvalue= 'LOADSETS', /align_top)
  datasetList = widget_list(upRightBase, value=' ', /align_top, scr_xsize = 300, scr_ysize = 230, uvalue='DATASETLIST', uname='DATASETLIST')


  ; Selected dataset
  dataInfoLabel = widget_label(botLeftBase, value='3. Selected dataset', /align_top)
  selectedDataset = widget_text(botLeftBase, value=' ', /align_top, scr_xsize = 250 )
  selectServerLabelEmpty31 = widget_label(botLeftBase, value=' ', /align_top, scr_xsize = 250)
  selectServerLabelEmpty32 = widget_label(upLeftBase, value=' ', /align_top, scr_xsize = 250)
  dataInfoButton = widget_button(botLeftBase, value = ' Get dataset information ', uvalue= 'DATAINFO', /align_top)
  dataInfoShowLabel = widget_text(botLeftBase, value=' ', /align_top, scr_xsize = 250, scr_ysize = 100, /SCROLL)


  ;Time
  selectDatesLabel = widget_label(botRightBase, value='4. Select dates and prefix', /align_top)
  ;selectServerLabelEmpty41 = widget_label(botRightBase, value=' ', /align_top, scr_xsize = 250)
  new_col_base = widget_base(botRightBase, col=1)

  timeWidget = spd_ui_time_widget(new_col_base,$
    statusBar,$
    historyWin,$
    timeRangeObj=timeRangeObj,$
    uname='TIME_WIDGET',$
    startyear = 1965)

  prefixLabel = widget_label(botRightBase, value='Prefix for tplot variables:', /align_top)
  prefixText = widget_text(botRightBase, /edit, xsiz = 20, uval = 'PREFIXTEXT', uname = 'PREFIXTEXT', val = '' )

  ; Close buttons
  buttonBase = Widget_Base(mainbase, /row, /align_center, /GRID_LAYOUT)
  loadButton = widget_button(buttonBase, value = ' Load Data ', uvalue= 'LOADDATA', /align_center )
  exitButton = widget_button(buttonBase, value = ' Close ', uvalue= 'QUIT', /align_center )

  state = {mainBase:mainBase, serverList:serverList, hapi_servers:hapi_servers, selectedServer:selectedServer, capabilitiesLabel:capabilitiesLabel, $
    selectedDataset:selectedDataset, datasetList:datasetList, dataInfoShowLabel:dataInfoShowLabel, timeWidget:timeWidget, prefixText:prefixText, datasets:ptr_new() }
  Widget_Control, mainBase, Set_UValue=state

  widget_control, mainBase, /realize
  xmanager, 'spd_ui_load_hapi', mainBase, /no_block
end
