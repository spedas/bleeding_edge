;+
;NAME:
;   icon_struct_to_cdfstruct
;
;PURPOSE:
;   Converts an IDL structure returned from a ICON netCDF file
;         into an IDL structure that can be passed to cdf_info_to_tplot
;
;KEYWORDS:
;   netCDFi: ICON IDL structure from icon_netcdf_load_vars
;
;OUTPUT:
;   IDL structure that follows the SPDF CDF standard
;      (at least enough so to be read by cdf_info_to_tplot)
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2020-02-21 13:58:54 -0800 (Fri, 21 Feb 2020) $
;$LastChangedRevision: 28328 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/common/icon_struct_to_cdfstruct.pro $
;
;-------------------------------------------------------------------

function icon_struct_to_cdfstruct, netCDFi
  compile_opt idl2
  if ~is_struct(netCDFi) then begin
    dprint, dlevel=1, 'Must provide a netCDF structure'
    return, -1
  endif
  newstruct = create_struct('filename', netCDFi.filename, 'nv', netCDFi.nv)

  if tag_exist(netCDFi.g_attributes, 'conventions') then begin

    instr = netCDFi.g_attributes.instrument
    case instr of
      'IVM'       : instru = 'ivm'
      'IVM-A'     : instru = 'ivm-a'
      'FUV'       : instru = 'fuv'
      'FUV-A'     : instru = 'fuv-a'
      'FUV-B'     : instru = 'fuv-b'
      'EUV'       : instru = 'euv'
      'MIGHTI'    : instru = 'mighti'
      'MIGHTI-A'  : instru = 'mighti-a'
      'MIGHTI-B'  : instru = 'mighti-b'
      'EPHEMERIS' : instru = 'ephemeris'

      ;
      ;NEEDS TO BE UPDATED WITH OTHER INSTRAMENTS WHEN THEY BECOME AVAILABLE
      ;

    endcase
    source_name = netCDFI.g_attributes.source_name
    discipline = netCDFI.g_attributes.discipline
    process_level = netCDFi.g_attributes.descriptor
    data_version = netCDFi.g_attributes.data_version
    pi_name = netCDFi.g_attributes.pi_name
    pi_afflilation = netCDFi.g_attributes.pi_affiliation
    title = netCDFi.g_attributes.title
 ;   instrument_type = netCDFi.g_attributes.instrument_type
    mission_group = netCDFi.g_attributes.mission_group
    l_source_description = netCDFi.g_attributes.logical_source_description
    time_resolution = netCDFi.g_attributes.time_resolution
    rules = netCDFi.g_attributes.rules_of_use
    gen_by = netCDFi.g_attributes.generated_by
    acknow = netCDFi.g_attributes.acknowledgement
 ;   link_title = netCDFi.g_attributes.link_title
    http = netCDFi.g_attributes.http_link

    g_attributes = create_struct('PROJECT', 'ICON')
    str_element, g_attributes, 'SOURCE_NAME', source_name , /add
    str_element, g_attributes, 'DISCIPLINE', disciplaine , /add
    str_element, g_attributes, 'DATA_TYPE', strupcase(instru), /add
    str_element, g_attributes, 'DESCRIPTOR', process_level, /add
    str_element, g_attributes, 'DATA_VERSION', data_version, /add
    str_element, g_attributes, 'PI_NAME', pi_name , /add
    str_element, g_attributes, 'PI_AFFILIATION',pi_afflilation , /add
    str_element, g_attributes, 'TEXT', title, /add
    str_element, g_attributes, 'INSTRUMENT_TYPE', instrument_type, /add
    str_element, g_attributes, 'MISSION_GROUP', mission_group, /add
    str_element, g_attributes, 'LOGICAL_SOURCE_DESCRIPTION', l_source_description, /add
    str_element, g_attributes, 'TIME_RESOLUTION', time_resolution, /add
    str_element, g_attributes, 'RULES_OF_USE', rules, /add
    str_element, g_attributes, 'GENERATED_BY', gen_by, /add
    str_element, g_attributes, 'ACKNOWLEDGEMENT', acknow, /add
    str_element, g_attributes, 'LINK_TITLE', link_title, /add
    str_element, g_attributes, 'HTTP_LINK', http, /add
    str_element, g_attributes, 'FILE_NAMING_CONVENTION', 'source_descriptor_datatype', /add

    inq = create_struct('nzvars', netCDFi.nv)
    str_element, inq, 'ndims', 0, /add
    str_element, inq, 'DECODING', 'HOST_DECODING', /add
    str_element, inq, 'ENCODING', 'NETWORK_ENCODING', /add
    str_element, inq, 'MAJORITY', 'ROW_MAJOR', /add
    str_element, inq, 'MAXREC', -1, /add
    str_element, inq, 'nvars', 0, /add
    str_element, inq, 'natts', netCDFi.nv, /add
    str_element, inq, 'dim', 0, /add

    vars = create_struct('name', 'default')

    str_element, vars, 'num', 0, /add
    str_element, vars, 'is_zvar', 1, /add
    str_element, vars, 'datatype', 'CDF_REAL', /add
    str_element, vars, 'numattr', -1, /add
    str_element, vars, 'numelem', 1, /add
    str_element, vars, 'recvary', byte(1), /add
    str_element, vars, 'numrec', 1, /add
    str_element, vars, 'ndimen', 0, /add
    str_element, vars, 'd', 0, /add
    str_element, vars, 'dataptr', ptr_new(0), /add
    str_element, vars, 'attrptr', ptr_new(0), /add
    str_element, vars, 'type', 5, /add

    dataptrs = ptrarr(netCDFi.nv)
    attrptrs = ptrarr(netCDFi.nv)
    variables = replicate(vars, netCDFi.nv)

    ; loop through the variables again, this time associating
    ; the time variable with data variables
    for i = 0, netCDFi.nv-1 do begin
      attr = create_struct('DEPEND_0', 'Epoch')
      if (strmatch(netCDFi.vars.(i).name , 'Epoch',/fold_case) ) then begin
        ; ISSUE WITH EPOCH FUV version 2 revions 5 not begin in milliseconds
        ;        if(instru eq 'fuv-a' || instru eq 'fuv-b') then data = *netCDFi.vars.(i).dataptr else
        data = *netCDFi.vars.(i).dataptr/1000.D ; convert from ms to seconds
        if(data[0] gt 1e13) then str_element, vars, 'datatype', 'CDF_EPOCH', /add
        if(data[0] lt 1e13) then str_element, vars, 'datatype', 'CDF_TIME_TT2000', /add
      endif else begin
        str_element, vars, 'datatype', 'CDF_REAL', /add
        data = *netCDFi.vars.(i).dataptr
      endelse
      ;
      n_d = size(data,/N_dimensions)
       if(tag_exist(netcdfi.vars.(i), 'DEPEND_1')) then begin
        str_element,attr,'DEPEND_1',netCDFI.vars.(i).depend_1,/add
      endif

      if(tag_exist(netcdfi.vars.(i), 'DEPEND_2')) then begin
        str_element,attr,'DEPEND_2',netCDFI.vars.(i).depend_2,/add
      endif
      ;

      if(tag_exist(netcdfi.vars.(i), 'DISPLAY_TYPE')) then begin
        display = netCDFi.vars.(i).display_type
        IF((strupcase(display) ne 'TIME_SERIES') ||  strupcase(display) ne 'SPECTROGRAM') THEN BEGIN
          IF(n_d gt 1) then display = 'spectrogram' else display = 'time_series'
        endif
        str_element, attr, 'DISPLAY_TYPE', display, /add
      endif


      str_element, netCDFi.vars.(i), '_FillValue', missingval, SUCCESS=s
      if s ne 0 then str_element, attr, 'FILLVAL', missingval, /add ;else str_element, attr, 'FILLVAL', !values.f_nan, /add
      ;
      ; check if this variable has the attribute 'FORMAT'
      str_element, netCDFi.vars.(i), 'FORMAT', val, SUCCESS=s
      if s ne 0 then str_element, attr, 'FORMAT', netCDFi.vars.(i).format,/add
      str_element,netcdfi.vars.(i),'VAR_TYPE',var,succes=s
      str_element, attr, 'COORDINATE_SYSTEM', 'unknown', /add
      str_element,netcdfi.vars.(i), 'UNITS', unt, succes=s
      if s ne 0 then str_element, attr, 'UNITS', string(byte(netCDFi.vars.(i).units)), /add

      variables[i].dataptr = ptr_new(data)
      variables[i].attrptr = ptr_new(attr)

      variables[i].name = netCDFi.vars.(i).name
      variables[i].type = size(data,/type)
      variables[i].ndimen = size(data,/n_dimen)-1
      variables[i].datatype = vars.datatype
      ;      if(variables[i].ndimen gt 1) then stop
    endfor
    ; construct the structure in a format similar to that returned by cdf_load_vars
    str_element, newstruct, 'g_attributes', g_attributes, /add
    str_element, newstruct, 'inq', inq, /add
    str_element, newstruct, 'vars', variables, /add
  endif else begin
    dprint, dlevel=1, 'This structure does not appear to contain valid ICON data'
  endelse
  return, newstruct
end