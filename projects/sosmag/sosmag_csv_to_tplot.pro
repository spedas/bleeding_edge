;+
; Procedure:
;         sosmag_csv_to_tplot
;
; Purpose:
;         Load SOSMAG data from a structure s into tplot variables
;
; Keywords:
;         s : a structure with sosmag data, usually the result of read_csv()
;         tformat (optional): string, time format, for example 'DD.MM.YYYY hh:mm:ss'
;                             default time format is 'YYYY-MM-DDThh:mm:ss.fffZ'
;                             for more details, see time_struct.pro
;         desc (optional): string, description of the data
;         prefix (optional): string, prefix for tplot variables
;         suffix (optional): string, suffix for tplot variables
;
; Notes:
;
; Fields in the CSV files:
; [{"name":"utc","type":"isotime","length":24,"units":"UTC","fill":null,"description":"Timestamp in coordinated Universal Time (UTC)"},
; {"name":"version","type":"double","units":"dimensionless","fill":null,"description":"Data version identifier"},
; {"name":"b_gse_x","type":"double","units":"nT","fill":"NaN","description":"Magnetic Field B in GSE coordinates (X component)"},
; {"name":"b_gse_y","type":"double","units":"nT","fill":"NaN","description":"Magnetic Field B in GSE coordinates (Y component)"},
; {"name":"b_gse_z","type":"double","units":"nT","fill":"NaN","description":"Magnetic Field B in GSE coordinates (Z component)"},
; {"name":"b_hpen_p","type":"double","units":"nT","fill":"NaN","description":"Magnetic Field B in HPEN coordinates (P component)"},
; {"name":"b_hpen_e","type":"double","units":"nT","fill":"NaN","description":"Magnetic Field B in HPEN coordinates (E component)"},
; {"name":"b_hpen_n","type":"double","units":"nT","fill":"NaN","description":"Magnetic Field B in HPEN coordinates (N component)"},
; {"name":"position_x","type":"double","units":"km","fill":"NaN","description":"Spacecraft Position in GSE (X component)"},
; {"name":"position_y","type":"double","units":"km","fill":"NaN","description":"Spacecraft Position in GSE (Y component)"},
; {"name":"position_z","type":"double","units":"km","fill":"NaN","description":"Spacecraft Position in GSE (Z component)"},
; {"name":"data_flags","type":"double","units":"dimensionless","fill":null,"description":"Data flags, see InformationURL"},
; {"name":"final","type":"double","units":"dimensionless","fill":null,"description":"Calibration status, see InformationURL"},
; {"name":"frequency","type":"double","units":"dimensionless","fill":null,"description":"Current sampling frequency"}],
;
; Dataset description:
; "description":"Recalibrated L2 Magnetic Field Data with 1-16Hz from SOSMAG on GEO-KOMPSAT-2A in geostationary orbit at 128.2E."
; "description":"Near-realtime Magnetic Field Data with 1-16Hz from SOSMAG on GEO-KOMPSAT-2A in geostationary orbit at 128.2E."
;
; See also:
;   sosmag_load_csv.pro
; 
; $LastChangedBy: nikos $
; $LastChangedDate: 2023-09-07 09:09:32 -0700 (Thu, 07 Sep 2023) $
; $LastChangedRevision: 32087 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/sosmag/sosmag_csv_to_tplot.pro $
;-

pro sosmag_csv_to_tplot, s, tformat=tformat, desc=desc, prefix=prefix, suffix=suffix

  if ~keyword_set(s) then begin
    dprint, "No data to load into tplot."
    return
  endif
  if ~keyword_set(desc) then begin
    desc = "Magnetic Field Data with 1-16Hz from SOSMAG on GEO-KOMPSAT-2A in geostationary orbit at 128.2E."
  endif
  if ~keyword_set(prefix) then begin
    prefix = ""
  endif
  if ~keyword_set(suffix) then begin
    suffix = ""
  endif

  time = time_double(s.field01, tformat=tformat)
  b = [[s.field03], [s.field04], [s.field05]]
  b_hpen = [[s.field06], [s.field07], [s.field08]]
  btotal = (s.field03^2 + s.field04^2 + s.field05^2)^0.5
  loc = [[s.field09], [s.field10], [s.field11]]
  earth_radius = 6371.
  loc_re = loc/earth_radius

  ; Spacecraft position in GSE
  pos = prefix +'sosmag_pos' + suffix ; in km
  pd = 'Spacecraft Position in GSE'
  data_att = {project:'SOSMAG', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'km', coord_sys:'gse', st_type: 'pos', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['x','y','z']+'_gse', ytitle:'Position (GSE)', ysubtitle: '[km]', description: desc}
  store_data, pos, data={x:time, y:loc}, dlimits=dlimits

  pos_gse = prefix +'sosmag_pos_gse' + suffix ;in RE
  store_data, pos_gse, data={x:time, y:loc_re}, dlimits=dlimits
  options, pos_gse, 'ysubtitle', '[RE]', /add, /def
  options, pos_gse, 'data_att.units', '[RE]', /add, /def

  pos_gsm = prefix +'sosmag_pos_gsm' + suffix ;in RE
  cotrans, pos_gse, pos_gsm, /GSE2GSM
  options, pos_gsm, 'LABELS', ['x_gsm', 'y_gsm', 'z_gsm'], /add, /def

  pos_sm = prefix +'sosmag_pos_sm' + suffix ; in RE
  cotrans, pos_gsm, pos_sm, /GSM2SM
  options, pos_sm, 'LABELS', ['x_sm', 'y_sm', 'z_sm'], /add, /def

  ; B field in GSE
  b_var_gse = prefix +'sosmag_b_gse' + suffix
  pd = 'Magnetic Field B in GSE coordinates'
  data_att = {project:'SOSMAG', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'nT', coord_sys:'gse', description:pd}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['Bx','By','Bz']+'_gse', ytitle:'B (GSE)', ysubtitle: '[nT]', description: desc}
  store_data, b_var_gse, data={x:time, y:b}, dlimits=dlimits

  ; B field in HPEN
  bh_var_gse = prefix +'sosmag_b_hpen' + suffix
  pdh = 'Magnetic Field B in HPEN coordinates'
  data_att = {project:'SOSMAG', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'nT', coord_sys:'hpen', description:pdh}
  dlimits = {data_att: data_att, colors: [2,4,6], labels: ['Bp','Be','Bn'], ytitle:'B (HPEN)', ysubtitle: '[nT]', description: desc}
  store_data, bh_var_gse, data={x:time, y:b_hpen}, dlimits=dlimits

  ; B field in GSM
  b_var_gsm = prefix +'sosmag_b_gsm' + suffix
  cotrans, b_var_gse, b_var_gsm , /GSE2GSM
  options, b_var_gsm, 'ytitle', 'B (GSM)', /add, /def
  options, b_var_gsm, 'LABELS', ['Bx_gsm', 'By_gsm', 'Bz_gsm'], /add, /def
  options, b_var_gsm, 'data_att.DESCRIPTION', 'Magnetic Field B in GSM coordinates', /add, /def

  ; B field in SM
  b_var_sm = prefix +'sosmag_b_sm' + suffix
  cotrans, b_var_gsm, b_var_sm , /GSM2SM
  options, b_var_sm, 'ytitle', 'B (SM)', /add, /def
  options, b_var_sm, 'LABELS', ['Bx_sm', 'By_sm', 'Bz_sm'], /add, /def
  options, b_var_sm, 'data_att.DESCRIPTION', 'Magnetic Field B in SM coordinates', /add, /def

  ; B-field with total B in SM
  get_data, b_var_sm, dlimits = b_sm_dlimits, data=b_sm_data
  bt = [[b_sm_data.y], [btotal]]
  bt_var = prefix +'sosmag_bt_sm' + suffix
  pds = 'Magnetic Field B in SM coordinates'
  data_att = {project:'SOSMAG', observatory:'GEO-KOMPSAT-2A', instrument:'SOSMAG', units:'nT', coord_sys:'sm', description:pds}
  dlimits = {data_att: data_att, colors: [2,4,6,0], labels: ['Bx','By','Bz', 'Btot'], ytitle:'B (SM)', ysubtitle: '[nT]', description: desc}
  store_data, bt_var, data={x:time, y:bt}, dlimits=dlimits

end
