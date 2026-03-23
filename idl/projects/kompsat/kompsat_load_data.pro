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
; Special keywords:
;     getrest:     One of: capabilities, catalog, info, data (default, doesn't have to be set)
;     showrestout:    This contains JSON result (or empty string if request has failed)
;
;     Only one (or none) of the getcap, getsets, getinfo should be set.
;
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-03-19 09:53:57 -0700 (Thu, 19 Mar 2026) $
;$LastChangedRevision: 34271 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/kompsat_load_data.pro $
;-


pro esa_hapi_server_parse, datastr=datastr, datatype=datatype, prefix=prefix, suffix=suffix, tplotvars=tplotvars
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
        kompsat_to_tplot, dd, param=param, desc=desc, dataset=datatype,prefix=prefix, suffix=suffix, tplotvars=tplotvars

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

pro kompsat_load_data, trange=trange, dataset=dataset, prefix=prefix, suffix=suffix, tplotvars=tplotvars, getrest=getrestin, showrest=showrestout

  compile_opt idl2
  RESOLVE_ROUTINE, 'check_esa_hapi_connection', /COMPILE_FULL_FILE, /EITHER

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

  ; Format the dataid
  if undefined(dataset) then dataset = 'recalib'
  datatype='recalib'
  if dataset eq 'p' || STRPOS(dataset, 'kma_gk2a_ksem_pd_p_l1') NE -1 then begin
    dataid = 'spase://SSA/NumericalData/GEO-KOMPSAT-2A/kma_gk2a_ksem_pd_p_l1'
    datatype = 'p'
  endif else if dataset eq 'e' || STRPOS(dataset, 'kma_gk2a_ksem_pd_e_l1') NE -1 then begin
    dataid = 'spase://SSA/NumericalData/GEO-KOMPSAT-2A/kma_gk2a_ksem_pd_e_l1'
    datatype = 'e'
  endif else if dataset eq '1m' || dataset eq '1min' || STRPOS(dataset, 'd3s_gk2a_sosmag_1m') NE -1 then begin
    dataid = 'spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_1m'
    datatype = '1m'
  endif else dataid = 'spase://SSA/NumericalData/D3S/d3s_gk2a_sosmag_recalib'


  ; Check if it is possible to connect to server
  if check_esa_hapi_connection() ne 1 then begin
    dprint, "Cannot connect to ESA HAPI server."
    return
  end

  ; Default is to get data
  if undefined(getrestin) then getrestin='data'

  if getrestin eq 'capabilities' then begin
    ; Return capabilities

    dataURL = 'https://swe.ssa.esa.int/hapi/capabilities'
    showrestout = get_esa_hapi_data(dataURL)
    return

  endif else if getrestin eq 'catalog' then begin
    ; Return catalog

    dataURL = 'https://swe.ssa.esa.int/hapi/catalog'
    showrestout = get_esa_hapi_data(dataURL)
    return

  endif else if getrestin eq 'info' then begin
    ; Return info for the dataset

    dataURL = 'https://swe.ssa.esa.int/hapi/info?id='+dataid
    showrestout = get_esa_hapi_data(dataURL)
    return

  endif else begin
    ; Return data for the dataset

    dataURL = 'https://swe.ssa.esa.int/hapi/data?id=' + dataid + '&time.min=' + timemin + '&time.max=' + timemax + '&format=json'
    showrestout = get_esa_hapi_data(dataURL)

    if strlen(showrestout) le 5 then begin
      dprint, 'No results for this time range.'
      return
    endif

    esa_hapi_server_parse, datastr=showrestout, datatype=datatype, prefix=prefix, suffix=suffix, tplotvars=tplotvars

  endelse
end

