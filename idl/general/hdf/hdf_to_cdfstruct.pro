;+
; Procedure:
;         hdf_to_cdfstruct
;
; Purpose:
;         Transform an IDL structure that was created from a Netcdf-4/HDF-5 file
;         into an cdf structure compatible with cdf_info_to_tplot
;
; Input:
;         hdfi: IDL structure created by hdf_load_vars
;         file: full path of Netcdf-4/HDF-5 file
;
; Keywords:
;         time_var: name of the time variable
;                   default is 'time'
;         time_dict: dictionary mapping time variable names to arrays of dependent variable names
;                   overrides time_var and automatic time dependencies when nonempty
;                   each time variable uses its own units unless time_offset is supplied
;         time_offset: time offset in miliseconds
;                   default is 0.0 ('1970-01-01/00:00:00.000')
;         varnames: list of variable names to load
;         gatt2istp: dictionary, mapping of HDF global attributes to ISTP global attributes
;         vatt2istp: dictionary, mapping of HDF variable attributes to ISTP variable attributes
;         multidim: GOES-R L2 particle layout (mpsh or sgps); time first, static energies
;         coord_list: list of coordinate systems, if set the variable name is used for coordinate system
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-10-15 18:38:10 -0700 (Thu, 15 Oct 2026) $
; $LastChangedRevision: 34986 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/hdf/hdf_to_cdfstruct.pro $
;-

function hdfi_read_attribute, id
  ; Read the attribute string.
  ; Some files contain H5T_CSET_UTF8 strings and IDL cannot read them.
  compile_opt idl2

  catch, err
  if err ne 0 then begin
    catch, /cancel
    print, !error_state.msg
    RETURN, ''
  endif

  result = h5a_read(id)
  return, result
end

function hdfi_get_number, s
  compile_opt idl2
  ; Returns an integer from a string which contains mixed chars and numbers.
  pos = stregex(s, '[0123456789]+', len = len)
  if len gt 0 then begin
    a = strmid(s, pos, len)
    an = fix(0l + a, type = 3)
    return, an
  endif else return, 0
end

function hdfi_get_coords_from_name, vname, coord_list
  compile_opt idl2
  ; Finds the coordinate system from the variable name
  result = ''

  for i = 0, n_elements(coord_list) - 1 do begin
    coord = '_' + coord_list[i]
    if strlen(coord) lt 3 then continue
    if strlen(vname) le (strlen(coord) + 1) then continue
    if strlowcase(coord) eq strlowcase(strmid(vname, strlen(coord) - 1, strlen(coord), /reverse_offset)) then begin
      if strlowcase(coord_list[i]) eq 'eci' then begin
        return, 'GEI' ; return 'GEI' when the filename ends in 'eci'
      endif else begin
        return, coord_list[i]
      endelse
    endif
  endfor

  return, result
end

pro hdfi_find_dims, hdfi, hdfi_names = hdfi_names, hdfi_types = hdfi_types, hdfi_dims = hdfi_dims, hdfi_points = hdfi_points, hdfi_spec = hdfi_spec
  compile_opt idl2
  ; Returns the names, dimensions, data types, and the number of points as separate arrays.
  ; Parses hdfi, which contains elements similar to the following
  ; dataset /orbit_llr_geo H5T_FLOAT [3, 86400]
  hdfi_names = []
  hdfi_types = []
  hdfi_dims = []
  hdfi_points = []
  hdfi_spec = []
  for i = 0, n_elements(hdfi[0, *]) - 1 do begin
    hd = hdfi[*, i]
    n = n_elements(hd)
    if n ge 3 then begin
      if hd[0] eq 'dataset' then begin
        hdn = hd[1]
        if strlen(hdn) gt 0 then begin
          if strmid(hdn, 0, 1) eq '/' then begin
            hdn = strmid(hdn, 1)
          endif
        endif
        hdfi_names = [hdfi_names, hdn]
        hdfi_types = [hdfi_types, '']
        hdfi_dims = [hdfi_dims, 0l]
        hdfi_points = [hdfi_points, 0l]
        hdfi_spec = [hdfi_spec, 0l]

        s = strsplit(hd[2], /extract)
        sn = n_elements(s)
        if sn eq 4 then begin ; spectrogram
          hdfi_types[i] = s[0]
          hdfi_spec[i] = hdfi_get_number(s[1])
          hdfi_dims[i] = hdfi_get_number(s[2])
          hdfi_points[i] = hdfi_get_number(s[3])
        endif else if sn eq 3 then begin
          hdfi_types[i] = s[0]
          hdfi_dims[i] = hdfi_get_number(s[1])
          hdfi_points[i] = hdfi_get_number(s[2])
          hdfi_spec[i] = 0l
        endif else if sn eq 2 then begin
          hdfi_types[i] = s[0]
          hdfi_dims[i] = 1l
          hdfi_points[i] = hdfi_get_number(s[1])
          hdfi_spec[i] = 0l
        endif else begin
          hdfi_types[i] = s
          hdfi_dims[i] = 0l
          hdfi_points[i] = 0l
          hdfi_spec[i] = 0l
        endelse
      endif else begin
        ; Only datasets need dims
        hdfi_names = [hdfi_names, '']
        hdfi_types = [hdfi_types, '']
        hdfi_dims = [hdfi_dims, 0l]
        hdfi_points = [hdfi_points, 0l]
        hdfi_spec = [hdfi_spec, 0l]
      endelse
    endif else begin
      ; Wrong structure
      hdfi_names = [hdfi_names, '']
      hdfi_types = [hdfi_types, '']
      hdfi_dims = [hdfi_dims, 0l]
      hdfi_points = [hdfi_points, 0l]
      hdfi_spec = [hdfi_spec, 0l]
    endelse
  endfor
end

function hdf_get_time_offset, dataset_id
  ; Returns the time offset for a dataset.
  ; GOES files can have different time offsets depending on the 'units' attribute (either 2000 or 1970).
  ; dataset_id: HDF-5 dataset ID for the 'time' variable
  compile_opt idl2

  time_offset1 = time_double('1970-01-01/00:00:00.000')
  time_offset2 = time_double('2000-01-01/12:00:00.000')

  time_offset = time_offset1 ; default is 0.0

  na = h5a_get_num_attrs(dataset_id)
  for i = 0, na - 1 do begin
    aid = h5a_open_idx(dataset_id, i)
    an = h5a_get_name(aid)
    str1 = strlowcase(an)
    str2 = 'units'
    position = strpos(str1, str2)
    if position ne -1 then begin
      av = hdfi_read_attribute(aid)
      str3 = strlowcase(av)
      str4 = '2000-01-01'
      position2 = strpos(str3, str4)
      if position2 ne -1 then begin
        time_offset = time_offset2
      endif
    endif
    h5a_close, aid
  endfor

  return, time_offset
end

function hdf_to_cdfstruct, hdfi, file, verbose = verbose, varnames = varnames, time_var = time_var, time_offset = time_offset, $
  gatt2istp = gatt2istp, vatt2istp = vatt2istp, coord_list = coord_list, time_dict=time_dict, multidim=multidim, _extra = _extra
  ; Converts a Netcdf-4/HDF-5 structure to a CDF structure.
  compile_opt idl2

  vbs = keyword_set(verbose) ? verbose : 0
  hdfi_find_dims, hdfi, hdfi_names = hdfi_names, hdfi_types = hdfi_types, hdfi_dims = hdfi_dims, hdfi_points = hdfi_points, hdfi_spec = hdfi_spec

  ; Opt-in layout handling for the GOES-R L2 particle products.
  particle_data = 0b
  if keyword_set(multidim) then particle_data = (multidim eq 'mpsh') || (multidim eq 'sgps')
  use_time_dict = 0
  if n_elements(time_dict) gt 0 then begin
    ; Count entries explicitly rather than testing the KEYS container.
    use_time_dict = time_dict.Count() gt 0
    if use_time_dict then time_keys = time_dict.keys()
  endif

  if use_time_dict then particle_data = 0b
  sensor_clocks = 0b
  if particle_data && keyword_set(time_var) then sensor_clocks = (multidim eq 'sgps') && (time_var eq 'L1a_SciData_TimeStamp')

  if use_time_dict then begin
    ; Dictionary keys are the time datasets; no common 'time' dataset is required.
    foreach time_name, time_keys do begin
      time_id = where('/' + time_name eq hdfi[1, *], time_count)
      if time_count ne 1 then begin
        msg = 'hdf_to_cdfstruct: Missing or ambiguous time variable: ' + time_name
        DPRINT, dlevel = 1, verbose = verbose, msg
        return, 0
      endif
    endforeach
  endif else begin
    if ~keyword_set(time_var) then begin
      time_var = 'time'
    endif

    time_id = where('/' + time_var eq hdfi[1, *])
    if time_id[0] eq -1 then begin ; try 'time' as time variable
      time_id = where('/' + 'time' eq hdfi[1, *])
      if time_id[0] ne -1 then time_var = 'time'
    endif
    if time_id[0] eq -1 then begin
      msg = 'hdf_to_cdfstruct: Did not find the time variable: ' + time_var
      DPRINT, dlevel = 1, verbose = verbose, msg
      return, 0
    endif else if n_elements(time_id) gt 1 then begin
      msg = 'hdf_to_cdfstruct: Ambiguous time variable: ' + time_var
      DPRINT, dlevel = 1, verbose = verbose, msg
      return, 0
    endif

    time_orbit_missing = 0
    time_orbit_var = time_var + '_orbit'
    time_orbit_id = where('/' + time_orbit_var eq hdfi[1, *])
    if time_orbit_id[0] eq -1 then begin
      time_orbit_missing = 1
    endif
  endelse

  ; Create output structures.
  newstruct = create_struct('filename', file)
  g_attributes = create_struct('PROJECT', 'GOES-R')
  inq = create_struct('nzvars', 0)
  variables = create_struct('name', 'default')

  ; Open file.
  fid = h5f_open(file)

  ; Dictionary time datasets are converted individually in the variable loop below.
  if ~use_time_dict then begin
    ; 1. Read time data.
    dataset_id = h5d_open(fid, time_var)
    hdftime = h5d_read(dataset_id)
    time_nbr = n_elements(hdftime)
    if undefined(time_offset) then begin
      ; Try to find the time offset from the dataset attributes
      time_offset = hdf_get_time_offset(dataset_id)
    endif
    h5d_close, dataset_id
    if time_nbr le 0 then begin
      msg = 'hdf_to_cdfstruct: Time variable not found.'
      DPRINT, dlevel = 1, verbose = verbose, msg
      return, 0
    endif
    if sensor_clocks then begin
      ; SGPS L1 provides one clock per sensor, in raw HDF [sensor, time] order.
      sensor_times = transpose(hdftime)
      bad_time = where(sensor_times le -1d30, nbad)
      sensor_times = sensor_times + time_offset
      if nbad gt 0 then sensor_times[bad_time] = !values.d_nan
      hdftime = reform(hdftime[0, *])
      time_nbr = n_elements(hdftime)
    endif
    hdftime = hdftime + time_offset

    time_orbit_nbr = 0
    if time_orbit_missing eq 0 then begin
      dataset_id = h5d_open(fid, time_orbit_var)
      hdftime_orbit = h5d_read(dataset_id)
      time_orbit_nbr = n_elements(hdftime_orbit)
      h5d_close, dataset_id
      hdftime_orbit = hdftime_orbit + time_offset
    endif
  endif

  ; 2. Read global attributes
  ; gatt2istp provides a mapping of HDF global attributes to ISTP global attributes
  ; if gatt2istp is given, then use it, otherwise use the raw HDF global attributes
  natt = h5a_get_num_attrs(fid)
  if n_elements(gatt2istp) gt 0 then begin
    gk = gatt2istp.keys()
    use_gatt2istp = 1
  endif else use_gatt2istp = 0
  for i = 0, natt - 1 do begin
    aid = h5a_open_idx(fid, i)
    an = h5a_get_name(aid)
    ar = hdfi_read_attribute(aid)

    if use_gatt2istp then begin
      idx = where(gatt2istp.values() eq ':' + an)
      if idx[0] ne -1 then begin
        attname = gk[idx[0]]
        str_element, g_attributes, attname, ar, /add
      endif
    endif else begin
      str_element, g_attributes, an, ar, /add
    endelse
    ; print, an, ar
    h5a_close, aid
  endfor

  ; 3. Read variables
  ; Create a template for a cdf-like variable
  vars = create_struct('name', 'default')
  str_element, vars, 'num', 0, /add
  str_element, vars, 'is_zvar', 1, /add
  str_element, vars, 'datatype', 'CDF_REAL', /add
  str_element, vars, 'type', 5, /add
  str_element, vars, 'numattr', -1, /add
  str_element, vars, 'numelem', 1, /add
  str_element, vars, 'recvary', byte(1), /add
  str_element, vars, 'numrec', 1, /add
  str_element, vars, 'ndimen', 0, /add
  str_element, vars, 'd', 0, /add
  str_element, vars, 'dataptr', ptr_new(0), /add
  str_element, vars, 'attrptr', ptr_new(0), /add

  attr = create_struct('DEPEND_0', 'epoch')
  str_element, attr, 'DEPEND_TIME', 'time', /add
  str_element, attr, 'DISPLAY_TYPE', 'time_series', /add
  str_element, attr, 'VAR_TYPE', 'data', /add
  str_element, attr, 'COORDINATE_SYSTEM', 'unknown', /add
  str_element, attr, 'UNITS', '', /add

  ; Create a structure with all the HDF variables (datasets)
  allvars = where(hdfi[0, *] eq 'dataset', nv)
  dataptrs = ptrarr(nv)
  attrptrs = ptrarr(nv)
  variables = replicate(vars, nv)

  ; If vatt2istp is given, then use it, otherwise use the raw HDF variable attributes
  variables = []
  for j = 0, n_elements(hdfi[0, *]) - 1 do begin
    if hdfi[0, j] eq 'dataset' then begin
      if (hdfi_names[j] ne '') && (hdfi_types[j] eq 'H5T_FLOAT' || hdfi_types[j] eq 'H5T_INTEGER') && (hdfi_points[j] gt 0) then begin ; skip empty vars
        varnew = replicate(vars, 1)
        varatt = replicate(attr, 1)
        variable_name = hdfi_names[j]
        varnew.name = variable_name
        if particle_data then begin
          ; These products' *Energy arrays are static, even in short files
          ; whose record count happens to equal an energy-table dimension.
          particle_record = (hdfi_points[j] eq time_nbr) && ~strmatch(variable_name, '*Energy')
        endif

        vn = '/' + variable_name
        vai = h5d_open(fid, vn)
        if h5d_get_storage_size(vai) eq 0 then begin
          ; empty data
          varnew.dataptr = ptr_new()
        endif else begin
          if use_time_dict then begin
            vr = h5d_read(vai)
            time_idx = where(variable_name eq time_keys, time_count)
            if time_count gt 0 then begin
              ; Do not reuse one dataset's inferred offset for the other time arrays.
              if undefined(time_offset) then mapped_offset = hdf_get_time_offset(vai) else mapped_offset = time_offset
              vr = vr + mapped_offset
            endif else begin
              si0 = size(vr, /dimensions)
              ; Restore netCDF order for dictionary-mapped L1 arrays of any rank.
              if n_elements(si0) gt 1 then vr = transpose(vr, reverse(indgen(n_elements(si0))))
            endelse
            varnew.dataptr = ptr_new(vr)
          endif else if variable_name eq time_var then begin
            varnew.name = 'time'
            varnew.dataptr = ptr_new(hdftime)
          endif else if variable_name eq time_orbit_var then begin
            varnew.dataptr = ptr_new(hdftime_orbit)
          endif else begin
            vr = h5d_read(vai) ; this is the data
            si0 = size(vr, /dimensions)
            if particle_data then begin
              if particle_record && (n_elements(si0) gt 1) then vr = transpose(vr, reverse(indgen(n_elements(si0))))
            endif else if (hdfi_points[j] eq time_nbr) || (hdfi_points[j] eq time_orbit_nbr) then begin
              if n_elements(si0) gt 1 then vr = transpose(vr, reverse(indgen(n_elements(si0))))
            endif
            varnew.dataptr = ptr_new(vr)
          endelse
        endelse

        ; Variable attributes
        vatt = h5a_get_num_attrs(vai)
        if n_elements(vatt2istp) gt 0 then begin
          vk = vatt2istp.keys()
          use_vatt2istp = 1
        endif else use_vatt2istp = 0
        for i = 0, vatt - 1 do begin
          vaid = h5a_open_idx(vai, i)
          van = h5a_get_name(vaid)
          vart = hdfi_read_attribute(vaid)

          if use_vatt2istp then begin
            idx = where(vatt2istp.values() eq ':' + van)
            if idx[0] ne -1 then begin
              vattname = vk[idx[0]]
              str_element, varatt, vattname, vart, /add
            endif
          endif else begin
            str_element, varatt, van, vart, /add
          endelse

          ; print, van, vart
          h5a_close, vaid
        endfor

        h5d_close, vai
        if use_time_dict then begin
          ; Explicit dependencies take precedence over attributes and record counts.
          varatt.depend_0 = ''
          varatt.depend_time = ''
          varatt.var_type = 'support data'
          varnew.recvary = 0b
          foreach time_name, time_keys do begin
            dependents = time_dict[time_name]
            dep_idx = where(variable_name eq dependents, dep_count)
            if (variable_name eq time_name) || (dep_count gt 0) then begin
              varatt.depend_0 = time_name
              varatt.depend_time = time_name
              varnew.recvary = 1b
              str_element, varatt, 'HDF_TIME_FIRST', 1b, /add
              if dep_count gt 0 then varatt.var_type = 'data'
              break
            endif
          endforeach
        endif else if (hdfi_points[j] eq time_nbr) && (variable_name ne 'coordinate') then begin ; time variable
          varatt.depend_0 = 'time'
          varatt.depend_time = 'time'
          varatt.var_type = 'data'
          str_element, varatt, 'HDF_TIME_FIRST', 1b, /add
        endif else if hdfi_points[j] eq time_orbit_nbr then begin ; time orbit variable
          varatt.depend_0 = 'time_orbit'
          varatt.depend_time = 'time_orbit'
          varatt.var_type = 'support data'
          str_element, varatt, 'HDF_TIME_FIRST', 1b, /add
        endif else begin
          varatt.depend_0 = ''
          varatt.depend_time = ''
          varatt.var_type = 'support data'
          varnew.recvary = 0b
        endelse

        if particle_data then begin
          varatt.depend_0 = ''
          varatt.depend_time = ''
          varnew.recvary = byte(particle_record)
          if particle_record then begin
            varatt.depend_0 = 'time'
            varatt.depend_time = 'time'
            str_element, varatt, 'HDF_TIME_FIRST', 1b, /add
            ; Keep static energies in variable metadata, not on a time axis.
            energy_name = ''
            if strmatch(variable_name, 'AvgDiffProtonFlux*') then energy_name = 'DiffProtonEffectiveEnergy'
            if strmatch(variable_name, 'AvgDiffElectronFlux*') then energy_name = 'DiffElectronEffectiveEnergy'
            if strmatch(variable_name, 'AvgDiffAlphaFlux*') then energy_name = 'DiffAlphaEffectiveEnergy'
            if energy_name ne '' then begin
              energy_id = h5d_open(fid, energy_name)
              str_element, varatt, 'EffectiveEnergies', h5d_read(energy_id), /add
              h5d_close, energy_id
            endif
          endif else varatt.var_type = 'support data'
        endif

        ; Set coordinates from variable name
        if defined(coord_list) then begin
          coord_name = hdfi_get_coords_from_name(variable_name, coord_list)
          if coord_name ne '' then begin
            varatt.coordinate_system = coord_name
          endif
        endif

        varnew.attrptr = ptr_new(varatt)
        variables = [variables, varnew]
        if sensor_clocks && (variable_name eq time_var) then begin
          ; Retain both clocks as record-varying data so multi-file merges
          ; concatenate them along time before mission sensor splitting.
          clock_var = varnew
          clock_var.name = time_var
          clock_var.dataptr = ptr_new(sensor_times)
          clock_attr = varatt
          clock_attr.var_type = 'data'
          clock_var.attrptr = ptr_new(clock_attr)
          variables = [variables, clock_var]
        endif
      endif
    endif
  endfor

  ; Close file.
  h5f_close, fid

  ; Construct the structure in a format similar to that returned by cdf_load_vars
  str_element, newstruct, 'nv', n_elements(variables), /add ; Number of variables
  str_element, newstruct, 'g_attributes', g_attributes, /add ; Attributes
  str_element, newstruct, 'inq', inq, /add ;
  str_element, newstruct, 'vars', variables, /add ; Variables and data as pointers

  return, newstruct
end
