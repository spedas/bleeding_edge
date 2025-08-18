;+
; Procedure:
;  kompsat_to_tplot
;
; Purpose:
;  Create tplot variables from KOMPSAT data.
;  Works with kompsat_load_data.pro and kompsat_load_csv.pro
;
; Keywords:
; data, dataset=dataset, param=param, desc=desc, prefix=prefix, suffix=suffix, tplotvars=tplotvars
;     data:       An array of data
;     dataset:    Four datasets are available: recalib (default), 1m, p, e
;     param:      Optional parameters with descriptions
;     desc:       Optional description
;     prefix:     String to append to the beginning of the loaded tplot variable names
;     suffix:     String to append to the end of the loaded tplot variable names
;     tplotvars:  Returned array of strings, with the tplot variables that were loaded
;
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2024-11-09 15:31:36 -0800 (Sat, 09 Nov 2024) $
;$LastChangedRevision: 32939 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/kompsat_to_tplot.pro $
;-




pro kompsat_pe_data2tplot, data, dataset=dataset, param=param, desc=desc, prefix=prefix, suffix=suffix, tplotvars=tplotvars
  ; Create tplot variables for particle data (particle detector)
  ; param is a list with 34 elements with descriptions of each data
  ; data contails is a list with as many elements as the rows and each row has 34 columns
  ; column 0 is utc time, [1-10] electron or proton flux, [31, 32, 33] is position in GSE, the rest is flags

  if undefined(dataset) then dataset='p'
  if dataset ne 'p' && dataset ne 'e' then dataset='p'
  if ~keyword_set(prefix) then prefix='kompsat_' + dataset + '_'
  if ~keyword_set(suffix) then suffix=''
  if ~keyword_set(desc) then desc=''

  d = strtrim(data, 2)
  td = time_double(d[*,0])

  if dataset eq 'e' then begin
    flux_start = ['100','150','225','325','450','700','1350','1800','2600','3800']
  endif else begin
    flux_start = ['77','119','148','229','354','548','681','1052','2021','3123','6000']
  endelse

  ; Array to hold the descriptions
  pp = strarr(10)
  if n_elements(param) ge 11 then begin
    for i=1,10 do begin
      if param[i].HasKey('description') then pp[i-1]=(param[i])['description']
    endfor
  endif

  eall = []
  for i=0, 9 do begin
    ; Create one variable for each energy band
    y = double(d[*, i+1])
    tname = prefix + string(i, format='(I0)')
    pd = pp[i]
    e =  'e' + string(i+1, format='(I0)') + ' ' + flux_start[i]
    data_att = {project:'KOMPSAT', observatory:'GEO-KOMPSAT-2A', instrument:'particle detector', units:'keV', coord_sys:'gse', description:pd}
    dlimits = {data_att: data_att, labels: e, ysubtitle: '[keV]', description: desc}
    store_data, tname, data={x: td, y:y}, dlimits=dlimits
    append_array, tplotvars, tname
    eall = [eall, e]
  endfor

  ; All energies in one variable
  ;y = [[double(d[*, 1])], [double(d[*, 2])], [double(d[*, 3])], [double(d[*, 4])], [double(d[*, 5])], [double(d[*, 6])], [double(d[*, 7])], [double(d[*, 8])], [double(d[*, 9])]]
  y = double(d[*, 1:10])
  tname = prefix + 'all'
  if dataset eq 'e' then pd = 'Electron flux' else pd = 'Proton flux'
  data_att = {project:'KOMPSAT', observatory:'GEO-KOMPSAT-2A', instrument:'particle detector', units:'keV', coord_sys:'gse', description:pd}
  dlimits = {data_att: data_att, labels: eall, ysubtitle: '[keV]', description: desc}
  store_data, tname, data={x: td, y:y}, dlimits=dlimits
  append_array, tplotvars, tname

  ;'position_x', 'position_y', 'position_z'
  ; data: 31,32,33
  ; parameters: 31,32,33
  y = double(d[*, 31:33])
  tname = prefix + 'pos'
  pd = 'Spacecraft Position in GSE'
  data_att = {project:'KOMPSAT', observatory:'GEO-KOMPSAT-2A', instrument:'particle detector', units:'km', coord_sys:'gse', st_type: 'pos', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['x','y','z']+'_gse', ysubtitle: '[km]', description: desc}
  store_data, tname, data={x: td, y:y}, dlimits=dlimits

  append_array, tplotvars, tname

end

pro kompsat_b_data2tplot, data, dataset=dataset, param=param, desc=desc, prefix=prefix, suffix=suffix, tplotvars=tplotvars
  ; Create tplot variables for magnetic field (SOSMAG instrument)
  ; param is a list with 14 elements with descriptions of each data
  ; data contails is a list with as many elements as the rows and each row has 14 columns
  ; column 0 is utc time, [2,3,4] is b_gse, [5,6,7] is b_hpen, [8,9,10] is position in GSE, the rest is flags

  if ~keyword_set(prefix) then prefix='kompsat_' else prefix=prefix + 'kompsat_'
  if ~keyword_set(suffix) then suffix=''
  if dataset eq '1m' then suffix='_1m'+ suffix
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

  d = strtrim(data, 2)
  td = time_double(d[*,0])

  ; 'b_gse_x', 'b_gse_y', 'b_gse_z'
  ; data: 2,3,4
  ; parameters: 2,3,4
  p = p_b_gse
  y = double(d[*, 2:4])
  tname = prefix + 'b_gse' + suffix
  pd = 'Magnetic Field B in GSE coordinates'
  data_att = {project:'KOMPSAT', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'nT', coord_sys:'gse', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['b_x','b_y','b_z']+'_gse', ysubtitle: '[nT]', description: desc}
  store_data, tname, data={x: td, y:y}, dlimits=dlimits

  append_array, tplotvars, tname

  ; 'b_hpen_p', 'b_hpen_e', 'b_hpen_n'
  ; data: 5,6,7
  ; parameters: 5,6,7
  p = p_b_hpen
  y = double(d[*, 5:7])
  tname = prefix + 'b_hpen' + suffix
  store_data, tname, data={x:td, y:y}
  options, tname, 'description', desc , /def
  pd = 'Magnetic Field B in HPEN coordinates'
  data_att = {project:'KOMPSAT', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'nT', coord_sys:'hpen', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['b_x','b_y','b_z']+'_hpen', ysubtitle: '[nT]', description: desc}
  store_data, tname, data={x: td, y:y}, dlimits=dlimits

  append_array, tplotvars, tname

  ;'position_x', 'position_y', 'position_z'
  ; data: 8,9,10
  ; parameters: 8,9,10
  p = p_pos
  y = double(d[*, 8:10])
  tname = prefix + 'pos' + suffix
  pd = 'Spacecraft Position in GSE'
  data_att = {project:'KOMPSAT', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'km', coord_sys:'gse', st_type: 'pos', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['x','y','z']+'_gse', ysubtitle: '[km]', description: desc}
  store_data, tname, data={x: td, y:y}, dlimits=dlimits

  append_array, tplotvars, tname

end

pro kompsat_to_tplot, data, dataset=dataset, param=param, desc=desc, prefix=prefix, suffix=suffix, tplotvars=tplotvars

  if dataset eq 'e' or dataset eq 'p' then begin
    kompsat_pe_data2tplot, data, dataset=dataset, param=param, desc=desc, prefix=prefix, suffix=suffix, tplotvars=tplotvars
  endif else begin
    kompsat_b_data2tplot, data, dataset=dataset, param=param, desc=desc, prefix=prefix, suffix=suffix, tplotvars=tplotvars
  endelse

end
