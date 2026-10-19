;+
; Procedure:
;     goesr_load_data
;
; Purpose:
;     Loads data from GOES-R satelites (GOES-16, GOES-17, GOES-18, GOES-19)
;     or reprocessed data from earlier satelites (GOES 8-15).
;
; Keywords:
;     trange:       Time range of interest
;     datatype:     Type of GOES-R data to be loaded.
;                   Valid data types for L2 data are:
;                     'mag': Magnetometer (default: 1 min, 'hires': 0.1 sec)
;                            For GOES 8-15, only hires is available.
;                     'xrs': EXIS X-Ray Sensor (default: 1 min, 'hires': 1 sec);
;                            For GOES 8-15, both hires and 1 min avg are available.
;                     'mpsh': Magnetospheric Electrons and Protons, Medium and High Energy (MPSH)
;                             (default: 5 min, hires: 1 min)
;                     'sgps': Solar and Galactic Proton Sensors (SGPS)
;                             (default: 5 min, Hires: 1 min)
;                   Valid data types for L1 data, probes 16+, are:
;                     'mag': Magnetometer
;                     'xrs': EXIS X-Ray Sensor (two bands, 0.05-0.4 nm, 0.1-0.8 nm)
;                     'mpsh': SEISS Magnetospheric Particle Sensor–High Energy
;                     'euvs': EXIS Extreme Ultraviolet Sensor
;                     'sgps': Solar and Galactic Proton Sensors (SGPS)
;
;     prefix:        String to append to the beginning of the loaded tplot variables
;     suffix:        String to append to the end of the loaded tplot variables
;     probes:        Array of GOES spacecrafts (8-19). Default is probes=['16'].
;     level:         'l1' or 'l2' (default). L1 is only for probes 16-19.
;     source:        Retrieval settings structure; defaults to !goesr.
;     downloadonly: Download files but don't load them into tplot.
;     hires:        If set, download full data files (larger files, can be over 180MB).
;                   If not set, use lowest available resolution (default).
;     no_time_clip: Don't clip the tplot variables.
;     get_support_data: For l1 files only. Load all auxiliary variables; otherwise load science
;                       variables and required time/coordinate datasets. 
;
; Notes:
;     NOAA Site:  https://www.ncei.noaa.gov/products/satellite/goes-r
;     data GOES 16-19:   https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/
;     reprocessed data GOES 8-15: https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/science/
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-10-15 18:38:10 -0700 (Thu, 15 Oct 2026) $
; $LastChangedRevision: 34986 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/goesr_load_data.pro $
;-

function goesr_l1_get_time_dict, datatype
  compile_opt idl2
  ; Explicit mappings are needed only for L1 products with multiple time axes.
  ; product_time contains per-file start/end bounds, not a 1-D time axis;
  ; input_file metadata and static labels/coordinates are not mapped.
  ; MAG ambient/total fields and DQF share sample_number with both sensor
  ; clocks; the CDL does not identify which clock to use, so leave unmapped.
  time_dict = dictionary()
  if datatype eq 'mag' then begin
    time_dict = dictionary( $
      'IB_time', [ $
      'IB_data_uncorrected', $
      'IB_mag_ACRF_uncorrected', $
      'IB_mag_BRF_uncorrected', $
      'IB_mag_ECI_uncorrected', $
      'IB_mag_EPN_uncorrected', $
      'IB_data', $
      'IB_mag_ACRF', $
      'IB_mag_BRF', $
      'IB_mag_ECI', $
      'IB_mag_EPN', $
      'IB_status' $
      ], $
      'OB_time', [ $
      'OB_data_uncorrected', $
      'OB_mag_ACRF_uncorrected', $
      'OB_mag_BRF_uncorrected', $
      'OB_mag_ECI_uncorrected', $
      'OB_mag_EPN_uncorrected', $
      'OB_data', $
      'OB_mag_ACRF', $
      'OB_mag_BRF', $
      'OB_mag_ECI', $
      'OB_mag_EPN', $
      'OB_status' $
      ], $
      'report_time', [ $
      'Instrument_ID', $
      'yaw_flip', $
      'eclipse_flag', $
      'ECEF_X', $
      'ECEF_Y', $
      'ECEF_Z', $
      'solar_array_current' $
      ], $
      'quat_timestamp', [ $
      'attitude_quat_Q0', $
      'attitude_quat_Q1', $
      'attitude_quat_Q2', $
      'attitude_quat_Q3', $
      'orbit_quat_Q0', $
      'orbit_quat_Q1', $
      'orbit_quat_Q2', $
      'orbit_quat_Q3' $
      ] $
      )
  endif else if datatype eq 'xrs' then begin
    ; Map report-aligned arrays, including embedded observation times, to the
    ; one-dimensional report time. Embedded times remain raw auxiliary values.
    time_dict = dictionary( $
      'time', [ $
      'irradiance_xrsa1', $
      'irradiance_xrsa2', $
      'primary_xrsa', $
      'irradiance_xrsb1', $
      'irradiance_xrsb2', $
      'primary_xrsb', $
      'xrs_ratio', $
      'corrected_current_xrsa_1', $
      'corrected_current_xrsa_2', $
      'corrected_current_xrsa_3', $
      'corrected_current_xrsa_4', $
      'corrected_current_xrsb_1', $
      'corrected_current_xrsb_2', $
      'corrected_current_xrsb_3', $
      'corrected_current_xrsb_4', $
      'dispersion_angle', $
      'crossdispersion_angle', $
      'sc_power_side', $
      'exis_flight_model', $
      'exis_configuration_id', $
      'xrs_runctrlmd', $
      'integration_time', $
      'exs_sl_pwr_ena', $
      'asic1_temperature', $
      'asic2_temperature', $
      'invalid_flags', $
      'xrs_det_chg', $
      'xrs_mode', $
      'sps_obs_time', $
      'sps_int_time', $
      'sps_temperature', $
      'sps_det_chg', $
      'num_angle_pairs', $
      'yaw_flip_flag', $
      'au_factor', $
      'quality_flags', $
      'packet_count', $
      'fov_unknown', $
      'fov_eclipse', $
      'fov_lunar_transit', $
      'fov_planet_transit', $
      'fov_off_point', $
      'quaternion_Q0', $
      'quaternion_Q1', $
      'quaternion_Q2', $
      'quaternion_Q3', $
      'ecef_X', $
      'ecef_Y', $
      'ecef_Z', $
      'solar_array_current', $
      'SC_eclipse_flag' $
      ], $
      'SPP_roll_angle_time', ['SPP_roll_angle'] $
      )
  endif

  return, time_dict
end

function goesr_find_in_list, alist, astr, notstr = notstr
  compile_opt idl2
  ; Find a substring in a list, exclude all notstr
  names = ['']
  if undefined(notstr) then begin
    positions = strpos(alist, astr)
    idx = where(positions ne -1, count)
    if count ge 1 then begin
      names = tnames(alist[idx])
    endif
  endif else begin
    positions = strpos(alist, astr)
    nopositions = strpos(alist, notstr)
    idx = where(positions ne -1 and nopositions eq -1, count)
    if count ge 1 then begin
      names = tnames(alist[idx])
    endif
  endelse

  return, names[0]
end

pro goesr_sgps_postprocessing, varnames, prefix = prefix, suffix = suffix
  compile_opt idl2
  ; Create separate tplot variables for each of the two sensors
  ; Total of 13 energy channels

  if undefined(prefix) then prefix = ''
  if undefined(suffix) then suffix = ''

  v = prefix + 'AvgDiffProtonFlux' + suffix
  vn = prefix + 'AvgDiffProtonFluxUncert' + suffix
  protons = goesr_find_in_list(varnames, v, notstr = vn)

  v = prefix + 'DiffProtonEffectiveEnergy' + suffix
  protons_energies = goesr_find_in_list(varnames, v)

  if protons ne '' and protons ne '-1' then begin
    get_data, protons, data = dp, dl = dlp
    str_element, dlp, 'CDF.VATT.EffectiveEnergies', energy_values, success = have_energies
    if have_energies eq 1 then dpen = {y: energy_values} else get_data, protons_energies, data = dpen, dl = dlpen
    dlp.ylog = 1
    str_element, dlp, 'labels', ['P1', 'P2A', 'P2B', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8A', 'P8B', 'P8C', 'P9', 'P10'], /add
    str_element, dlp, 'labflag', -1, /add
    for i = 0, 1 do begin
      new_name = protons + '_' + strcompress(string(i), /remove_all)
      if have_energies eq 1 then sensor_y = reform(dp.y[*, i, *], n_elements(dp.x), n_elements(dp.y[0, i, *])) $
      else sensor_y = transpose([reform([dp.y[*, i, *]])])
      store_data, new_name, data = {x: dp.x, y: sensor_y}, dl = dlp
      options, /def, new_name, 'sensor', strcompress(string(i), /remove_all)
      varnames = [varnames, new_name]
      if is_struct(dpen) then begin
        ; Effective energies should have 13 elements
        efen = reform(dpen.y[*, i])
        if n_elements(efen) gt 13 then efen = efen[0 : 12]
        options, /def, new_name, 'EffectiveEnergies', efen ; Effective sensor energies
      endif
    endfor
  endif
end

pro goesr_mpsh_postprocessing, varnames, prefix = prefix, suffix = suffix
  compile_opt idl2
  ; Create separate tplot variables for each telescope

  if undefined(prefix) then prefix = ''
  if undefined(suffix) then suffix = ''

  ; Proton telescopes: T1, T4, T2, T5, T3
  ; Total of 11 energy channels.
  v = prefix + 'AvgDiffProtonFlux' + suffix
  vn = prefix + 'AvgDiffProtonFluxUncert' + suffix
  protons = goesr_find_in_list(varnames, v, notstr = vn)

  v = prefix + 'DiffProtonEffectiveEnergy' + suffix
  protons_energies = goesr_find_in_list(varnames, v)
  protons_energies = protons_energies[0]

  tprotons = ['T1', 'T4', 'T2', 'T5', 'T3']
  if protons ne '' and protons ne '-1' then begin
    get_data, protons, data = dp, dl = dlp
    str_element, dlp, 'CDF.VATT.EffectiveEnergies', energy_values, success = have_energies
    if have_energies eq 1 then dpen = {y: energy_values} else get_data, protons_energies, data = dpen, dl = dlpen
    dlp.ylog = 1
    str_element, dlp, 'labels', ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9', 'P10', 'P11'], /add
    str_element, dlp, 'labflag', -1, /add
    for i = 0, 4 do begin
      new_name = protons + '_' + strcompress(string(i), /remove_all)
      if have_energies eq 1 then sensor_y = reform(dp.y[*, i, *], n_elements(dp.x), n_elements(dp.y[0, i, *])) $
      else sensor_y = transpose([reform([dp.y[*, i, *]])])
      store_data, new_name, data = {x: dp.x, y: sensor_y}, dl = dlp
      options, /def, new_name, 'telescope', tprotons[i]
      varnames = [varnames, new_name]
      if is_struct(dpen) then begin
        ; Effective energies should have 11 elements
        efen = reform(dpen.y[*, i])
        if n_elements(efen) gt 11 then efen = efen[0 : 10]
        options, /def, new_name, 'EffectiveEnergies', efen ; Effective telescope energies
      endif
    endfor
  endif

  ; Electron telescopes: T3, T1, T4, T2, T5
  ; Total of 10 energy channels.
  v = prefix + 'AvgDiffElectronFlux' + suffix
  vn = prefix + 'AvgDiffElectronFluxUncert' + suffix
  electrons = goesr_find_in_list(varnames, v, notstr = vn)

  v = prefix + 'DiffElectronEffectiveEnergy' + suffix
  electrons_energies = goesr_find_in_list(varnames, v)

  telectrons = ['T3', 'T1', 'T4', 'T2', 'T5']
  if electrons ne '' and electrons ne '-1' then begin
    get_data, electrons, data = de, dl = dle
    str_element, dle, 'CDF.VATT.EffectiveEnergies', energy_values, success = have_energies
    if have_energies eq 1 then deen = {y: energy_values} else get_data, electrons_energies, data = deen, dl = dleen
    dle.ylog = 1
    str_element, dle, 'labels', ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9', 'E10'], /add
    str_element, dle, 'labflag', -1, /add
    for i = 0, 4 do begin
      new_name = electrons + '_' + strcompress(string(i), /remove_all)
      if have_energies eq 1 then sensor_y = reform(de.y[*, i, *], n_elements(de.x), n_elements(de.y[0, i, *])) $
      else sensor_y = transpose([reform([de.y[*, i, *]])])
      store_data, new_name, data = {x: de.x, y: sensor_y}, dl = dle
      options, /def, new_name, 'telescope', telectrons[i]
      varnames = [varnames, new_name]
      if is_struct(deen) then begin
        ; Effective energies should have 10 elements
        efen = reform(deen.y[*, i])
        if n_elements(efen) gt 10 then efen = efen[0 : 9]
        options, /def, new_name, 'EffectiveEnergies', efen ; Effective telescope energies
      endif
    endfor
  endif
end

pro goesr_l1_particle_postprocessing, varnames, datatype = datatype, clock_name = clock_name
  compile_opt idl2
  ; Particle arrays are [time, sensor/telescope, energy].
  nsensors = 5
  option_name = 'telescope'
  sgps = 0b
  if n_elements(datatype) gt 0 then sgps = datatype eq 'sgps'
  if sgps then begin
    nsensors = 2
    option_name = 'sensor'
    get_data, clock_name, data = clocks
    if ~is_struct(clocks) then return
  endif
  names = varnames
  result = !null
  foreach name, names do begin
    get_data, name, data = d, dlimits = dl, limits = lim
    split = 0b
    if sgps then begin
      if name eq clock_name then begin
        result = [result, name]
        continue
      endif
    endif
    if is_struct(d) then begin
      str_element, d, 'y', y, success = have_y
      str_element, d, 'x', x, success = have_x
      if (have_y eq 1) && (have_x eq 1) then begin
        dims = size(y, /dimensions)
        rank = n_elements(dims)
        if (rank eq 3) || (sgps && (rank eq 2)) then split = (dims[0] eq n_elements(x)) && (dims[1] eq nsensors)
      endif
    endif
    if ~split then begin
      result = [result, name]
      continue
    endif
    for i = 0, nsensors - 1 do begin
      new_name = name + '_' + strtrim(string(i), 2)
      sensor_x = x
      if sgps then sensor_x = reform(clocks.y[*, i], dims[0])
      if rank eq 3 then sensor_y = reform(y[*, i, *], dims[0], dims[2]) else sensor_y = reform(y[*, i], dims[0])
      store_data, new_name, data = {x: sensor_x, y: sensor_y}, dlimits = dl, limits = lim
      options, /def, new_name, option_name, strtrim(string(i), 2)
      result = [result, new_name]
    endfor
    del_data, name
  endforeach
  varnames = result
end

pro goesr_mag_postprocessing, varnames
  compile_opt idl2
  ; Clean declared fills in science and auxiliary data, including single records.
  goesr_l1_postprocessing, varnames
end

pro goesr_xrs_postprocessing, varnames
  compile_opt idl2
  ; Clean declared fills in science and auxiliary data, including single records.
  goesr_l1_postprocessing, varnames
end

pro goesr_l1_postprocessing, varnames
  compile_opt idl2
  ; Replace declared fill values in floating-point data; preserve integer flags.

  if n_elements(varnames) eq 0 then return
  foreach vname, varnames do begin
    if vname eq '' then continue
    get_data, vname, data = d, dl = dl
    if ~is_struct(d) then continue
    str_element, d, 'y', y, success = have_y
    if have_y ne 1 then continue
    data_type = size(y, /type)
    if (data_type ne 4) && (data_type ne 5) then continue

    ; hdf2tplot retains the source variable attributes under CDF.VATT.
    str_element, dl, 'CDF.VATT', vatt, success = have_vatt
    if have_vatt ne 1 then continue
    fill_tag = IDL_ValidName('_FillValue', /convert_all)
    str_element, vatt, fill_tag, fill_value, success = have_fill
    if have_fill ne 1 then begin
      str_element, vatt, 'FILLVAL', fill_value, success = have_fill
    endif
    if have_fill ne 1 then continue
    if n_elements(fill_value) ne 1 then continue
    if ~finite(fill_value) then continue

    idx = where(y eq fill_value, count)
    if count eq 0 then continue
    if data_type eq 5 then y[idx] = !values.d_nan else y[idx] = !values.f_nan
    d.y = y
    store_data, vname, data = d, dl = dl
  endforeach
end

pro goesr_load_data, trange = trange, datatype = datatype, probes = probes, prefix = prefix, suffix = suffix, hires = hires, level = level, $
  downloadonly = downloadonly, no_time_clip = no_time_clip, get_support_data = get_support_data, source = source
  compile_opt idl2

  goesr_init

  ; handle possible server errors
  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel = 1, 'Error: ', !error_state.msg
    catch, /cancel
    return
  endif
  if undefined(suffix) then suffix = ''
  custom_source = keyword_set(source)

  if not keyword_set(level) then level = 'l2'
  ; set the default datatype to MAG data
  if not keyword_set(datatype) then datatype = 'mag'
  if not keyword_set(probes) then probes = ['16']
  if ~custom_source then source = !goesr
  if ~is_struct(source) then begin
    dprint, dlevel = 1, 'Error: source must be a retrieval settings structure.'
    return
  endif
  if undefined(downloadonly) then downloadonly = source.downloadonly
  if not keyword_set(hires) then resolution = 'lowres' else resolution = 'hires'
  if n_elements(trange) gt 0 then begin
    if n_elements(trange) ne 2 then begin
      dprint, dlevel = 1, 'Error: trange must contain a start and an end time.'
      return
    endif
    if time_double(trange[0]) gt time_double(trange[1]) then begin
      msg = 'Starting time cannot be larger than ending time.'
      dprint, dlevel = 1, 'Error: ', msg
      return
    endif
    tr = timerange(trange)
  endif else begin
    tr = timerange()
  endelse

  level = strlowcase(level)
  datatype = strlowcase(datatype)
  if (level ne 'l1') && (level ne 'l2') then begin
    dprint, dlevel = 1, 'Error: level must be l1 or l2.'
    return
  endif
  if level eq 'l1' then valid_types = ['mag', 'xrs', 'euvs', 'mpsh', 'sgps'] else valid_types = ['mag', 'xrs', 'mpsh', 'sgps']
  if total(datatype eq valid_types) eq 0 then begin
    dprint, dlevel = 1, 'Error: unsupported datatype for ' + level + ': ' + datatype
    return
  endif
  foreach probe, probes do begin
    if ~is_numeric(strtrim(string(probe), 2)) then begin
      dprint, dlevel = 1, 'Error: probes must be spacecraft numbers 8-19.'
      return
    endif
    probe_number = double(probe)
    if ~finite(probe_number) then begin
      dprint, dlevel = 1, 'Error: probes must be finite spacecraft numbers 8-19.'
      return
    endif
    if (probe_number lt 8) || (probe_number gt 19) || (probe_number ne long(probe_number)) then begin
      dprint, dlevel = 1, 'Error: probes must be spacecraft numbers 8-19.'
      return
    endif
    if (probe_number lt 16) && ((level eq 'l1') || ((datatype ne 'mag') && (datatype ne 'xrs'))) then begin
      dprint, dlevel = 1, 'Error: this level/datatype requires probes 16-19.'
      return
    endif
  endforeach

  ; Map attributes to ISTP/CDF variables.
  gatt2istp = dictionary( $
    'PROJECT', ':project', $
    'DATA_TYPE', ':title', $
    'DESCRIPTOR', ':processing_level', $
    'PI_NAME', ':creator_name', $
    'PI_AFFILIATION', ':creator_institution', $
    'TEXT', ':summary', $
    'MISSION_GROUP', ':program', $
    'LOGICAL_SOURCE_DESCRIPTION', ':source', $
    'TIME_RESOLUTION', ':time_coverage_resolution', $
    'RULES_OF_USE', ':license', $
    'Generation_date', ':date_created', $
    'ACKNOWLEDGEMENT', ':acknowledgment', $
    'HTTP_LINK', ':publisher_url', $
    'LINK_TITLE', ':publisher_name')

  if level eq 'l1' then begin
    gatt2istp['SOURCE_NAME'] = ':platform_ID'
    gatt2istp['INSTRUMENT_TYPE'] = ':instrument_type'
    gatt2istp['Logical_file_id'] = ':dataset_name'
  endif else begin
    gatt2istp['SOURCE_NAME'] = ':platform'
    gatt2istp['INSTRUMENT_TYPE'] = ':instrument'
    gatt2istp['Logical_file_id'] = ':id'
  endelse

  ; Coordinate list in variable names
  coord_list = ['SENSOR', 'EPN', 'ECI', 'GSE', 'GSM', 'VDH', 'ACRF', 'BRF']

  for pidx = 0, n_elements(probes) - 1 do begin ; loop through the probes
    goesp = string(long(double(probes[pidx])), format = '(I02)')
    sc = 'goes' + goesp
    sc0 = 'g' + goesp
    if ~keyword_set(prefix) then localprefix = sc + '_' else localprefix = prefix

    if goesp ge 16 then begin
      ; For GOES 16-19
      ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/
      remote_path = source.remote_data_dir
    endif else begin
      ; For GOES 8-15
      if custom_source then remote_path = source.remote_data_dir $
      else remote_path = 'https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/science/'
    endelse

    if level eq 'l1' then begin
      time_dict = goesr_l1_get_time_dict(datatype)
      time_var = 'time'
      if (datatype eq 'mpsh') || (datatype eq 'sgps') then time_var = 'L1a_SciData_TimeStamp'
      if datatype eq 'sgps' then multidim = 'sgps'
      case datatype of
        'mag': begin
          ; Magnetometer l1
          ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes19/l1b/mag-l1b-flat/2026/01/ops_mag-l1b-flat_g19_d20260101_v0-0-0.nc
          pathformat = sc + '/l1b/mag-l1b-flat/YYYY/MM/ops_mag-l1b-flat_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
        end
        'xrs': begin
          ; X-Ray Sensor l1
          ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes19/l1b/exis-l1b-sfxr_science/2026/01/sci_exis-l1b-sfxr_g19_d20260101_v0-0-2.nc
          pathformat = sc + '/l1b/exis-l1b-sfxr_science/YYYY/MM/sci_exis-l1b-sfxr_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
        end
        'euvs': begin
          ; EXIS Extreme Ultraviolet Sensor l1
          ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes19/l1b/exis-l1b-sfeu_science/2026/01/sci_exis-l1b-sfeu_g19_d20260101_v1-0-5.nc
          pathformat = sc + '/l1b/exis-l1b-sfeu_science/YYYY/MM/sci_exis-l1b-sfeu_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
        end
        'mpsh': begin
          ; Magnetospheric Particle Sensor l1
          ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes19/l1b/seis-l1b-mpsh_science/2025/01/sci_seis-l1b-mpsh_g19_d20250101_v0-0-0.nc
          pathformat = sc + '/l1b/seis-l1b-mpsh_science/YYYY/MM/sci_seis-l1b-mpsh_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
        end
        'sgps': begin
          ; Solar and Galactic Proton Sensors l1
          ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes16/l1b/seis-l1b-sgps/2025/01/ops_seis-l1b-sgps_g16_d20250101_v0-0-0.nc
          pathformat = sc + '/l1b/seis-l1b-sgps/YYYY/MM/ops_seis-l1b-sgps_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
        end
        else: begin
          msg = 'GOES-R L1 datatype cannot be downloaded at this time: ' + datatype
          dprint, dlevel = 1, 'Error: ', msg
          break
        end
      endcase
    endif else begin ; l2

      case datatype of
        'mag': begin
          ; Magnetometer l2
          if goesp ge 16 then begin
            ; GOES 16, 18, 19
            ; Lowres is 1 min. Hires is 0.1 second, large files (>180MB).
            res0 = 'avg1m'
            if resolution eq 'hires' then begin
              res0 = 'hires'
            endif
            lr = level + '-' + res0
            ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes19/l2/data/magn-l2-avg1m/2026/01/dn_magn-l2-avg1m_g19_d20260101_v2-0-4.nc
            pathformat = sc + '/' + level + '/data/magn-' + lr + '/YYYY/MM/dn_magn-' + lr + '_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
          endif else begin
            ; GOES 8-15: only high resolution is available (Nov 2025)
            res0 = 'hires'
            lr = level + '-' + res0
            pathformat = 'mag/' + sc + '/magn-' + lr + '/YYYY/MM/dn_magn-' + lr + '_' + sc0 + '_dYYYYMMDD_v?_?_?.nc'
          endelse
        end
        'xrs': begin
          ; High cadence measurements from the EXIS X-Ray Sensor (XRS)
          if goesp ge 16 then begin
            ; GOES 16, 17
            ; Hires is 1 second. Lowres is 1 min (default).
            res0 = 'avg1m'
            if resolution eq 'hires' then begin
              res0 = 'flx1s'
            endif
            lr = level + '-' + res0
            ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes19/l2/data/xrsf-l2-avg1m_science/2026/01/sci_xrsf-l2-avg1m_g19_d20260101_v2-2-1.nc
            pathformat = sc + '/' + level + '/data/xrsf-' + lr + '_science/YYYY/MM/sci_xrsf-' + lr + '_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
          endif else begin
            ; GOES 13, 14, 15
            ; Hires is 2-sec fluxes. Lowres is 1-min averages (default).
            if resolution eq 'hires' then begin
              res0 = 'irrad'
            endif else res0 = 'avg1m'
            lr = level + '-' + res0
            if resolution eq 'hires' then begin
              pathformat = 'xrs/' + sc + '/gxrs-' + lr + '_science/YYYY/MM/sci_gxrs-' + lr + '_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
            endif else begin
              pathformat = 'xrs/' + sc + '/xrsf-' + lr + '_science/YYYY/MM/sci_xrsf-' + lr + '_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
            endelse
          endelse
        end
        'mpsh': begin
          ; Magnetospheric Electrons and Protons, Medium and High Energy (MPSH)
          ; Hires is 1 min. Lowres is 5 min (default).
          ; Electrons: 5 telescopes, 10 channels
          ; Protons: 5 telescopes, 11 channels
          time_var = 'L2_SciData_TimeStamp'
          multidim = 'mpsh' ; contains many multi-dimensional variables that require special treatment
          res0 = 'avg5m'
          if resolution eq 'hires' then begin
            res0 = 'avg1m'
          endif
          lr = level + '-' + res0
          ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes19/l2/data/mpsh-l2-avg1m_science/2026/01/sci_mpsh-l2-avg1m_g19_d20260101_v2-0-3.nc
          pathformat = sc + '/' + level + '/data/mpsh-' + lr + '_science/YYYY/MM/sci_mpsh-' + lr + '_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
        end
        'sgps': begin
          multidim = 'sgps'
          ; Solar and Galactic Proton Sensors (SGPS)
          ; Two sensors, one looking eastward and one looking westward
          ; Hires is 1 min. Low res is 5 min (default).
          if goesp ge 16 then begin
            ; GOES 16, 17
            time_var = 'L2_SciData_TimeStamp'
            res0 = 'avg5m'
            scidn = 'sci'
            if (resolution eq 'hires') then begin
              res0 = 'avg1m'
              scidn = 'sci'
            endif
            lr = level + '-' + res0
            ; https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes19/l2/data/sgps-l2-avg1m/2026/01/sci_sgps-l2-avg1m_g19_d20260101_v3-0-2.nc
            pathformat = sc + '/' + level + '/data/sgps-' + lr + '/YYYY/MM/' + scidn + '_sgps-' + lr + '_' + sc0 + '_dYYYYMMDD_v?-?-?.nc'
          endif
        end
        else: begin
          msg = 'GOES-R L2 datatype cannot be downloaded at this time: ' + datatype
          dprint, dlevel = 1, 'Error: ', msg
          break
        end
      endcase
    endelse

    for j = 0, n_elements(pathformat) - 1 do begin
      ; Download file.
      relpathnames = file_dailynames(file_format = pathformat[j], trange = tr, addmaster = addmaster, /unique)
      tplotnames = ''
      files = spd_download(remote_file = relpathnames, remote_path = remote_path, local_path = source.local_data_dir, /last_version, $
        no_download = (source.no_download || source.no_server), no_update = (source.no_update || source.no_clobber), $
        min_age_limit = source.min_age_limit, force_download = source.force_download)
      if n_elements(files) eq 0 then continue
      if files[0] eq '' then continue
      if keyword_set(downloadonly) then continue
      ; Retain every dictionary clock, even if its dependents are filtered out.
      load_vars = '*'
      if (level eq 'l1') && ~keyword_set(get_support_data) then begin
        case datatype of
          'mag': load_vars = ['*/IB_mag_ECI', '*/OB_mag_ECI']
          'xrs': load_vars = ['*/irradiance_xrs*', '*/primary_xrs*', '*/xrs_ratio']
          'euvs': load_vars = ['*/irradianceSpectrum', '*/avgIrradiance*', '*/lowWavelength', '*/highWavelength']
          'mpsh': load_vars = ['*Flux*']
          'sgps': load_vars = ['*Flux*']
        endcase
        ; Query the dictionary itself; KEYS may return an empty container.
        if time_dict.Count() gt 0 then begin
          foreach clock, time_dict.keys() do load_vars = [load_vars, '*/' + clock]
        endif else load_vars = [load_vars, '*/' + time_var]
      endif
      ; Load file into tplot.
      hdf2tplot, files, varnames = load_vars, tplotnames = tplotnames, prefix = localprefix, suffix = suffix, gatt2istp = gatt2istp, vatt2istp = vatt2istp, coord_list = coord_list, time_offset = time_offset, time_var = time_var, multidim = multidim, time_dict = time_dict

      if n_elements(tplotnames) eq 0 then continue
      if tplotnames[0] eq '' then continue

      ; Post processing of tplot variables.
      if level eq 'l1' then begin
        goesr_l1_postprocessing, tplotnames
        if (datatype eq 'mpsh') || (datatype eq 'sgps') then begin
          goesr_l1_particle_postprocessing, tplotnames, datatype = datatype, clock_name = localprefix + time_var + suffix
        endif
      endif else begin
        case datatype of
          'mag': begin
            ; Magnetometer data contains a lot of -9999.0f FillValues instead of NaNs.
            goesr_mag_postprocessing, tplotnames
          end
          'xrs': begin
            ; Replace -9999.0f FillValues with NaNs.
            goesr_xrs_postprocessing, tplotnames
          end
          'mpsh': begin
            ; The attribute-based fill cleanup also applies to L2 data.
            goesr_l1_postprocessing, tplotnames
            ; Separate data from 5 telescopes.
            goesr_mpsh_postprocessing, tplotnames, prefix = localprefix, suffix = suffix
          end
          'sgps': begin
            ; The attribute-based fill cleanup also applies to L2 data.
            goesr_l1_postprocessing, tplotnames
            ; Separate data from 2 sensors.
            goesr_sgps_postprocessing, tplotnames, prefix = localprefix, suffix = suffix
          end
        endcase
      endelse
      ;
      ; Time clip
      if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
          if ~keyword_set(no_time_clip) then time_clip, tplotnames, tr[0], tr[1], replace = 1, error = error
        endif
      endif
    endfor
  endfor
end
