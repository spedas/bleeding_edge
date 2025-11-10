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
;         time_offset: time offset in miliseconds
;                   default is 0.0 ('1970-01-01/00:00:00.000')
;         varnames: list of variable names to load
;         gatt2istp: dictionary, mapping of HDF global attributes to ISTP global attributes
;         vatt2istp: dictionary, mapping of HDF variable attributes to ISTP variable attributes
;         coord_list: list of coordinate systems, if set the variable name is used for coordinate system
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-11-07 11:02:21 -0800 (Fri, 07 Nov 2025) $
; $LastChangedRevision: 33840 $
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
  gatt2istp = gatt2istp, vatt2istp = vatt2istp, coord_list = coord_list, _extra = _extra
  ; Converts a Netcdf-4/HDF-5 structure to a CDF structure.
  compile_opt idl2

  vbs = keyword_set(verbose) ? verbose : 0
  hdfi_find_dims, hdfi, hdfi_names = hdfi_names, hdfi_types = hdfi_types, hdfi_dims = hdfi_dims, hdfi_points = hdfi_points, hdfi_spec = hdfi_spec

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

  ; Create output structures.
  newstruct = create_struct('filename', file)
  g_attributes = create_struct('PROJECT', 'GOES-R')
  inq = create_struct('nzvars', 0)
  variables = create_struct('name', 'default')

  ; Open file.
  fid = h5f_open(file)

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
  hdftime = hdftime + time_offset

  time_orbit_nbr = 0
  if time_orbit_missing eq 0 then begin
    dataset_id = h5d_open(fid, time_orbit_var)
    hdftime_orbit = h5d_read(dataset_id)
    time_orbit_nbr = n_elements(hdftime_orbit)
    h5d_close, dataset_id
    hdftime_orbit = hdftime_orbit + time_offset
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

        vn = '/' + variable_name
        vai = h5d_open(fid, vn)
        if h5d_get_storage_size(vai) eq 0 then begin
          ; empty data
          varnew.dataptr = ptr_new()
        endif else begin
          if variable_name eq time_var then begin
            varnew.name = 'time'
            varnew.dataptr = ptr_new(hdftime)
          endif else if variable_name eq time_orbit_var then begin
            varnew.dataptr = ptr_new(hdftime_orbit)
          endif else begin
            vr = h5d_read(vai) ; this is the data
            si0 = size(vr, /dimensions)
            if (n_elements(si0) eq 2) && (si0[0] lt si0[1]) then begin
              vr = transpose(vr)
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
        if hdfi_points[j] eq time_nbr then begin ; time variable
          varatt.depend_time = 'time'
          varatt.var_type = 'data'
        endif else if hdfi_points[j] eq time_orbit_nbr then begin ; time orbit variable
          varatt.depend_time = 'time_orbit'
          varatt.var_type = 'support data'
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
