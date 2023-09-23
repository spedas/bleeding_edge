;+
; Procedure:
;  sosmag_hapi_load_data
;
; Purpose:
;  Loads SOSMAG data using the ESA HAPI server.
;
; Keywords:
;     trange:     Time range of interest (array with 2 elements, start and end time)
;     dataset:    Two datasets are available: recalibrated (default) and 1-min:
;                      'spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_recalib'
;                      'spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_1m'
;     recalib:    If 1 then select recalibrated dataset, if 0 select 1-min dataset
;     prefix:     String to append to the beginning of the loaded tplot variables
;     tplotnames: Array of strings with the tplot variables that were loaded.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2023-09-05 16:26:53 -0700 (Tue, 05 Sep 2023) $
;$LastChangedRevision: 32080 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/sosmag/hapi/sosmag_hapi_load_data.pro $
;-

pro sosmag_hapi_data_to_tplot, data, param=param, desc=desc, tplotnames=tplotnames, prefix=prefix
  ; Use data to fill tplot variables.
  ;
  ; TODO: Currently (2021-12-02) there is an inconsistency in json data. The position data are elements 11,12,13
  ; but the corresponding parameters are elements 8,9,10. This will probably be fixed in the future and the
  ; following code will have to be changed.

  if ~keyword_set(prefix) then prefix='sosmag_'
  if ~keyword_set(desc) then desc=''

  if keyword_set(param) then begin
    p_b_gse = param[2]
    p_b_hpen = param[5]
    p_pos = param[8]
  endif else begin
    pempty = {description:'', units:''}
    p_b_gse = pempty
    p_b_hpen = pempty
    p_pos = pempty
  endelse

  d = data.toarray()
  td = time_double(d[*,0])

  ; 'b_gse_x', 'b_gse_y', 'b_gse_z'
  ; data: 2,3,4
  ; parameters: 2,3,4
  p = p_b_gse
  y = [[double(d[*, 2])], [double(d[*, 3])], [double(d[*, 4])]]
  tname = prefix + 'b_gse'
  pd = 'Magnetic Field B in GSE coordinates'
  data_att = {project:'SOSMAG', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'nT', coord_sys:'gse', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['b_x','b_y','b_z']+'_gse', ysubtitle: '[nT]', description: desc}
  store_data, tname, data={x: td, y:y}, dlimits=dlimits

  append_array, tplotnames, tname

  ; 'b_hpen_p', 'b_hpen_e', 'b_hpen_n'
  ; data: 5,6,7
  ; parameters: 5,6,7
  p = p_b_hpen
  y = [[double(d[*, 5])], [double(d[*, 6])], [double(d[*, 7])]]
  tname = prefix + 'b_hpen'
  store_data, tname, data={x:td, y:y}
  options, tname, 'description', desc , /def
  pd = 'Magnetic Field B in HPEN coordinates'
  data_att = {project:'SOSMAG', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'nT', coord_sys:'hpen', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['b_x','b_y','b_z']+'_hpen', ysubtitle: '[nT]', description: desc}
  store_data, tname, data={x: td, y:y}, dlimits=dlimits

  append_array, tplotnames, tname

  ;'position_x', 'position_y', 'position_z'
  ; data: 11,12,13
  ; parameters: 8,9,10
  p = p_pos
  y = [[double(d[*, 11])], [double(d[*, 12])], [double(d[*, 13])]]
  tname = prefix + 'pos'
  pd = 'Spacecraft Position in GSE'
  data_att = {project:'SOSMAG', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'km', coord_sys:'gse', st_type: 'pos', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['x','y','z']+'_gse', ysubtitle: '[km]', description: desc}
  store_data, tname, data={x: td, y:y}, dlimits=dlimits

  append_array, tplotnames, tname

end

pro sosmag_hapi_load_data, trange=trange, dataset=dataset, recalib=recalib, tplotnames=tplotvars, prefix=prefix
  ; Load SOSMAG data from HAPI server.

  ; Two sets of data:
  ; 1. (1m) Near-realtime Magnetic Field Data with 1-16Hz from SOSMAG on GEO-KOMPSAT-2A in geostationary orbit at 128.2E.
  ; 2. (recalib, default) Recalibrated L2 Magnetic Field Data with 1-16Hz from SOSMAG on GEO-KOMPSAT-2A in geostationary orbit at 128.2E.

  compile_opt idl2

  ; Catch errors.
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    dprint, dlevel=0, !error_state.msg
    return
  endif

  ; Setup colors. In the future, this may go into sosmag_init
  spd_graphics_config

  ; Default dataset is the recalibrated L2 Magnetic Field Data
  if ~keyword_set(recalib) then recalib=1 else recalib=0

  if ~keyword_set(dataset) then begin
    if recalib eq 1 then begin
      dataset = 'spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_recalib'
    endif else begin
      dataset = 'spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_1m'
    endelse
  endif

  ; Set default prefix if none is given.
  if ~keyword_set(prefix) then begin
    if dataset eq 'spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_1m' then prefix = 'sosmag_1m_'
    if dataset eq 'spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_recalib' then prefix = 'sosmag_'
  endif

  ; Set a default date if none is given.
  if ~keyword_set(trange) || n_elements(trange) ne 2 then begin
    trange = ['2021-03-23/00:00:00', '2021-03-24/00:00:00']
  endif

  ; Create the query string for the HAPI server data.
  dataid = "id=" + dataset
  t0 = time_string(trange[0], precision=3)
  timemin = "time.min=" + t0.replace('/', 'T') + "Z"
  t1 = time_string(trange[1], precision=3)
  timemax= "time.max=" + t1.replace('/', 'T') + "Z"
  hquery = "data?" + dataid + "&" + timemin + "&" + timemax + "&format=json"

  ; Get the data
  sosmag_hapi_query, hquery=hquery, query_response=query_response
  if query_response eq '-1' then begin
    return
  endif else if query_response eq '' then begin
    dprint, 'Error: no data received from server.'
    return
  endif

  ; Check if there was data returned.
  data_json = sosmag_json_parse(query_response)
  data_ok = ""
  no_data = 1
  if data_json.haskey("status") then begin
    if data_json["status"].haskey("message") then begin
      data_ok = (data_json["status"])["message"] ; should be "OK"
    endif
  endif
  if data_ok ne "OK" then begin
    dprint, "Could not get response from server."
    return
  endif

  ; Save data into tplot variables.
  if data_json.haskey("data") then begin
    d = data_json["data"]
    if data_json.haskey("parameters") then param = data_json["parameters"]
    if data_json.haskey("description") then desc = data_json["description"]
    if n_elements(d) gt 0 then begin

      sosmag_hapi_data_to_tplot, d, param=param, desc=desc, tplotnames=tplotvars, prefix=prefix

    endif else begin
      dprint, "Empty data was received from server."
    endelse
  endif else begin
    dprint, "No data was received from server."
  endelse

end