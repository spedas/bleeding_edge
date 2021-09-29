;+
;
;NAME:
; spd_ui_load_hapi
;
;PURPOSE:
; Load data from a HAPI server
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-08-27 11:53:41 -0700 (Tue, 27 Aug 2019) $
;$LastChangedRevision: 27673 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_load_hapi.pro $
;-

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

end

pro spd_ui_hapi_get_capabilities, server, capabilities=capabilities

  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)

  spd_ui_hapi_set_server, server, neturl=neturl

  neturl->GetProperty, URL_PATH=url_path
  neturl->SetProperty, URL_PATH=url_path+'/capabilities'
  server_capabilities = json_parse(string(neturl->get(/buffer)))
  capabilities = 'HAPI v' + server_capabilities['HAPI'] + newline + $
    'Output formats: ' + strjoin(server_capabilities['outputFormats'].toArray(), ', ')

end

pro spd_ui_hapi_get_datasets, server, datasets=datasets

  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)

  spd_ui_hapi_set_server, server, neturl=neturl

  neturl->GetProperty, URL_PATH=url_path
  neturl->SetProperty, URL_PATH=url_path+'/catalog'

  catalog = json_parse(string(neturl->get(/buffer)))
  available_datasets = catalog['catalog']
  datasets = []
  for dataset_idx = 0, n_elements(available_datasets)-1 do begin
    datasets = [datasets, (available_datasets[dataset_idx])['id']]
  endfor
end

pro spd_ui_hapi_get_dataset_info, server, dataset, dinfo=dinfo

  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)

  spd_ui_hapi_set_server, server, neturl=neturl

  neturl->GetProperty, URL_PATH=url_path

  neturl->SetProperty, URL_PATH=url_path+'/info?id='+dataset
  info = json_parse(string(neturl->get(/buffer)))

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
      index = ev.index
      server=state.hapi_servers[index]
      server = STRTRIM(server, 2)
      widget_control, state.selectedServer, set_value=server
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
      index = ev.index
      x = state.datasets
      sd = *x
      selected_dataset = sd[index]
      selected_dataset = STRTRIM(selected_dataset, 2)
      widget_control, state.selectedDataset, set_value=selected_dataset

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

      hapi_load_data, trange=[starttime, endtime], dataset=dataset, server=server, tplotnames=tplotvars, prefix=prefix
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

  mainBase = widget_base(/column, title = 'Load Data using HAPI', /modal, Group_Leader=gui_id, scr_xsize = 700)

  topBase = widget_base(mainbase, col=2, /align_top)
  bottomBase = widget_base(mainbase, col=2, /align_top)

  upLeftBase = widget_base(topBase, /col, /align_top, scr_xsize = 300, scr_ysize = 300)
  upRightBase = widget_base(topBase, /col, /align_top, scr_xsize = 300, scr_ysize = 300)

  botLeftBase = widget_base(bottomBase, /col, /align_top, scr_xsize = 300)
  botRightBase = widget_base(bottomBase, /col, /align_top)

  ;Select hapi server
  selectServerLabel = widget_label(upLeftBase, value='1. Select HAPI server', /align_top)
  ; https://github.com/hapi-server/servers/blob/master/all.txt
  hapi_servers=['https://cdaweb.gsfc.nasa.gov/hapi','https://pds-ppi.igpp.ucla.edu/hapi', $
    'http://planet.physics.uiowa.edu/das/das2Server/hapi','https://iswa.gsfc.nasa.gov/IswaSystemWebApp/hapi', $
    'http://lasp.colorado.edu/lisird/hapi']
  serverList = widget_list(upLeftBase, value=hapi_servers, /align_top, scr_xsize = 250, scr_ysize = 100, uvalue='SERVERLIST', uname='SERVERLIST')
  selectServerLabelEmpty11 = widget_label(upLeftBase, value=' ', /align_top, scr_xsize = 250)
  selectServerLabel = widget_label(upLeftBase, value='Selected HAPI server:', /align_top, scr_xsize = 250)
  selectedServer = widget_text(upLeftBase, value=' ', /editable, /align_top, scr_xsize = 250 )
  selectServerLabelEmpty12 = widget_label(upLeftBase, value=' ', /align_top, scr_xsize = 250)
  getServerInfoButton = widget_button(upLeftBase, value = 'Get HAPI server info ', uvalue= 'SERVERINFO', /align_top, scr_xsize = 150)
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
  dataInfoButton = widget_button(botLeftBase, value = ' Get dataset information ', uvalue= 'DATAINFO', /align_top, scr_xsize = 150)
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
  loadButton = widget_button(buttonBase, value = ' Load Data ', uvalue= 'LOADDATA', /align_center, scr_xsize = 150 )
  exitButton = widget_button(buttonBase, value = ' Close ', uvalue= 'QUIT', /align_center, scr_xsize = 150 )

  state = {mainBase:mainBase, serverList:serverList, hapi_servers:hapi_servers, selectedServer:selectedServer, capabilitiesLabel:capabilitiesLabel, $
    selectedDataset:selectedDataset, datasetList:datasetList, dataInfoShowLabel:dataInfoShowLabel, timeWidget:timeWidget, prefixText:prefixText, datasets:ptr_new() }
  Widget_Control, mainBase, Set_UValue=state

  widget_control, mainBase, /realize
  xmanager, 'spd_ui_load_hapi', mainBase, /no_block
end
