;+
;Procedure: poes_netcdf2tplot.pro
;
;Purpose:
;   Load NETCDF variables into tplot variables from POES/METOP data files
;     
;Keywords:
;   files        : Filepath to NETCDF file (string) 
;   temporal_dim : Name of expected NETCDF variable where temporal data is stored (string, default: 'record')
;   verbose      : For cdf_info_to_tplot; prints more statements
;   prefix       : For cdf_info_to_tplot; modifies tplot variable names
;   suffix       : For cdf_info_to_tplot; modifies tplot variable names
;   tplotnames   : Returned array of tplot variable names
;   load_labels  : keyword to copy labels from labl_ptr_1 in attributes into dlimits
;   
; Output structure will have the following fields:
;     filename     : netCDFi.filename
;     nv           : netCDFi.nv (maybe update if skipping non-epoch variables?)
;     g_attributes (only one structure)
;     inq          (only one structure--essentially output of cdf_inquire())
;         nzvars   : default netCDFi.nv         (number of zvariables in structure)
;         ndims    : default 0                  (The longword integer specifying the number of dimensions in the rVariables in the current CDF)
;         DECODING : default 'HOST_DECODING'
;         ENCODING : default 'NETWORK_ENCODING'
;         MAJORITY : default 'ROW_MAJOR'
;         MAXREC   : default -1                 (integer specifying highest record number written in the rVariables in the current CDF. The MAXREC field will contain the value -1 if no rVariables have yet been written to the CDF.)
;         nvars    : default 0                  (integer specifying number of rVariables (regular variables) in the CDF.)
;         natts    : default netCDFi.nv         (integer specifying number of attributes in the CDF. includes both global and variable attributes. You can use the GET_NUMATTR keyword to the CDF_CONTROL routine to determine the number of each. why set to nv?)
;         dim      : default 0                  (A vector where each element contains the corresponding dimension size for the rVariables in the current CDF. For 0-dimensional CDF’s, this argument contains a single element (a zero). )
;     vars         (one for each variable)
;         name     : variable name
;         num      : variable index in structure
;         datatype : variable data type
;         type     : default 5       (variable type, see cdf_var_type in cdf_info)
;         is_zvar  : default 1       (designates zvariable)
;         numattr  : default -1      (update using attrptr)
;         numelem  : default 1       (number of elements???)
;         recvary  : default byte(1) (designates if variable is record-varying)
;         numrec   : default 1       (number of records?)
;         ndimen   : default 0       (number of dimensions?)
;         d        : default 0       (???)
;         dataptr
;         attrptr
;             CATDESC
;             DEPEND_0
;             DEPEND_1
;             DEPEND_2
;             DEPEND_3
;             DISPLAY_TYPE
;             FIELDNAM
;             FILLVAL
;             FORMAT (all not using FORM_PTR)
;             FORM_PTR (1D data, support_data, and metadata not using FORMAT)
;             LABLAXIS
;             LABL_PTR_1
;             LABL_PTR_2
;             LABL_PTR_3
;             UNITS (data and support_data not using UNIT_PTR)
;             UNIT_PTR (1D data and support_data not using UNITS)
;             VALIDMIN
;             VALIDMAX
;             VAR_TYPE
;             VAR_NOTES
;             MONOTON (Epoch)
;             TIME_BASE (for Epoch-- fixed (0AD, 1900, 1970 (POSIX), J2000 (used by CDF_TIME_TT2000), 4714 BC (Julian)) or flexible (provider-defined))
;             TIME_SCALE (for Epoch--TT (same as TDT, used by CDF_TIME_TT2000), TAI (same as IAT, TT-32.184s), UTC (includes leap seconds), TDB (same as SPICE ET), EME1950 [default: UTC] )
;             LEAP_SECONDS_INCLUDED (for Epoch--Recommended for UTC only)
;-

; take POES netcdf variable and construct a cdf variable from it:
function poes_netcdfvar2cdfvar, netcdf_var
    netcdf_var_name = netcdf_var.name
    netcdf_var_dataptr_data = *netcdf_var.dataptr[0]
    netcdf_var_dataptr_data_typename = typename(netcdf_var_dataptr_data)
    ; Construct output variable structure:
    cdf_var = create_struct($
        'name', netcdf_var_name,$       ; variable name
        'num', 0, $               ; variable index in cdf structure
        'is_zvar', 1, $           ; designates zvariable, should be always true
        'datatype', 'CDF_REAL8',$ ; variable data type -- A string describing the data type of the variable. The string has the form ‘CDF_XXX’ where XXX is FLOAT, DOUBLE, EPOCH, UCHAR, etc.
        'type', 5, $              ; variable type, see function cdf_var_type in cdf_info
        'numattr', -1, $          ; update using attrptr
        'numelem', 1, $           ; The number of elements of the data type at each variable value. This is always 1 except in the case of string type variables (CDF_CHAR, CDF_UCHAR).)
        'recvary', byte(1), $     ; designates if variable is record-varying
        'numrec', 1, $            ; if data is 1D and time varying, should be data array_length
        'ndimen', 0, $            ; An array of bytes. The value of each element is zero if there is no variance with that dimension and one if there is variance. For zero-dimensional CDFs, DIMVAR will have one element whose value is zero. if data is 1D and time varying, should be [byte(1)]
        'd', 0, $                 ; An array of longs. The value of each element corresponds to the dimension of the variable. This field is only included in the structure if the variable is a zVariable. if data is 1D and time varying, should be [numrecL] (cast to long)
        'dataptr', ptr_new(0), $  ; Data pointer, points to array containing data
        'attrptr', ptr_new(0))    ; Attribute pointer, points to structure containing attribute values
    ; Construct output variable attribute structure:
    cdf_var_attr = create_struct($
        'DEPEND_0',"Epoch",$
        'DISPLAY_TYPE',"time_series",$
        'VAR_TYPE', 'data')
    
    ; Try to set CDF variable catdesc attribute:
    str_element, netcdf_var, 'long_name', var_att_val, SUCCESS=s
    if s then str_element, cdf_var_attr, 'CATDESC', var_att_val, /add
    ; Try to set CDF variable units attribute:
    str_element, netcdf_var, 'units', var_att_val, SUCCESS=s
    if s then str_element, cdf_var_attr, 'UNITS', var_att_val, /add
    
    ; Compare IDL type name to NETCDF variable datatype field, and
    ; throw warning if they're different:
    if ~netcdf_var_dataptr_data_typename.matches(netcdf_var.datatype) then begin
        dprint, dlevel=1, 'WARNING: '+netcdf_var_name+' datatype ' + netcdf_var.datatype + ' does not match stored variable IDL datatype: ' + netcdf_var_dataptr_data_typename + '. Setting datatype to ' + netcdf_var_dataptr_data_typename
    endif
    
    ; Use IDL type name to define variable field values:
    cdf_var_dtype = idl2cdftype($
        netcdf_var_dataptr_data, $
        format_out=format_out, $
        fillval_out=fillval_out,$
        validmin_out=validmin_out, $
        validmax_out=validmax_out)
    ; If a respective CDF variable datatype has been found, 
    ; update variable field and attribute values:
    if keyword_set(cdf_var_dtype) then begin
        str_element, cdf_var, 'datatype', cdf_var_dtype, /add
        str_element, cdf_var_attr, 'FORMAT',format_out, /add
        str_element, cdf_var_attr, 'FILLVAL',fillval_out, /add
        str_element, cdf_var_attr, 'VALIDMIN',validmin_out, /add
        str_element, cdf_var_attr, 'VALIDMAX',validmax_out, /add
    endif
    
    ; If NETCDF variable is the time variable, create an 
    ; Epoch variable instead:
    if netcdf_var_name.matches('time') then begin
        ; Determine time format and update variable fields and attribute values accordingly:
        ; idl2cdftype should assign metop CDF datatype as 
        ; 'CDF_UINT8', because it's a ULONG64 array; however, metop 
        ; time data since it seems to be saved in the form of 
        ; milliseconds since 1970, we will convert it to seconds 
        ; using double-precision, update the cdf variable datatype 
        ; (which should then be CDF_DOUBLE), and manually set the 
        ; datatype as 'CDF_S1970' to represent a unix time.
        
        ; Add general Epoch-relevant attributes:
        str_element, cdf_var_attr, 'MONOTON', 'INCREASE', /add
        str_element, cdf_var_attr, 'VAR_TYPE', 'support_data', /add
        ; Add general Epoch-relevant variable fields:
        str_element, cdf_var, 'datatype', 'CDF_EPOCH', /add
        ; Determine Epoch type
        case(netcdf_var_dataptr_data.typecode) of
            5: begin
                ; CDF datatype CDF_DOUBLE. Could be CDF_EPOCH, or 
                ; CDF_S1970 -- Assume CDF_EPOCH:
                str_element, cdf_var, 'datatype', 'CDF_EPOCH', /add
                str_element, cdf_var_attr, 'UNITS','ms', /add
            end
            9: begin
                ; CDF datatype should be unassigned. Assign as 
                ; CDF_EPOCH16:
                str_element, cdf_var, 'datatype', 'CDF_EPOCH16', /add
                format_out = 'E34.0'
                fillval_out = DCOMPLEX(double(-1.0d31),double(-1.0d31))
                validmin_out = DCOMPLEX(double(-1.0d31),double(-1.0d31)) 
                validmax_out = DCOMPLEX(double(1.0d31),double(1.0d31))
                str_element, cdf_var_attr, 'UNITS','ps', /add
            end
            14: begin
                ; CDF datatype CDF_INT8, but IDL type code is 
                ; LONG64, so should be CDF_TIME_TT2000. Unit 
                ; should be in ns, so if units:
                str_element, cdf_var, 'datatype', 'CDF_TIME_TT2000', /add
                str_element, cdf_var_attr, 'UNITS','ns', /add
            end
            15: begin
                ; CDF datatype CDF_INT8, but IDL type code is ULONG64, so it's probably unix time, in ms.
                ; convert to time to seconds and update datatype as CDF_S1970:
                str_element, netcdf_var, 'units', units_val, SUCCESS=s
                if s then ms_u = units_val.matches('millisec')
                str_element, netcdf_var, 'long_name', long_name_val, SUCCESS=s
                if s then ms_ln = long_name_val.matches('milliseconds since 1970')
                if ms_u || ms_ln then begin
                    netcdf_var_dataptr_data_corrected = double(netcdf_var_dataptr_data/double(1000.0))
                    cdf_var_dtype = idl2cdftype($
                        netcdf_var_dataptr_data_corrected, $
                        format_out=format_out, $
                        fillval_out=fillval_out,$
                        validmin_out=validmin_out, $
                        validmax_out=validmax_out)
                    if keyword_set(cdf_var_dtype) && netcdf_var_dataptr_data_corrected.typecode eq 5 then begin
                        netcdf_var_dataptr_data = netcdf_var_dataptr_data_corrected
                        str_element, cdf_var_attr, 'FORMAT',format_out, /add
                        str_element, cdf_var_attr, 'FILLVAL',fillval_out, /add
                        str_element, cdf_var_attr, 'VALIDMIN',validmin_out, /add
                        str_element, cdf_var_attr, 'VALIDMAX',validmax_out, /add
                    endif else begin
                        dprint, dlevel=1, 'WARNING: NETCDF CDF_S1970 time variable correction failed!'
                    endelse
                    str_element, cdf_var, 'datatype', 'CDF_S1970', /add
                    str_element, cdf_var_attr, 'UNITS','s', /add
                endif else begin
                    dprint, dlevel=1, 'WARNING: NETCDF time variable had ULONG64 datatype but fails UNIX time check.'
                endelse
            end
            else: dprint, dlevel=1, 'WARNING: NETCDF time variable datatype not recognized.'
        endcase
    endif else begin
        str_element, netcdf_var, 'missing_value', SUCCESS=s
        if s ne 0 then str_element, cdf_var_attr, 'FILLVAL', netcdf_var.missing_value, /add else str_element, cdf_var_attr, 'FILLVAL', !values.f_nan, /add
        str_element, netcdf_var, 'FORMAT', SUCCESS=s
        if s ne 0 then str_element, cdf_var_attr, 'FORMAT', netcdf_var.format, /add
        str_element, netcdf_var, 'LIN_LOG', SUCCESS=s
        if s ne 0 then str_element, cdf_var_attr, 'SCALETYP', netcdf_var.lin_log, /add
        ; check the name to see if this is support data
        ; QUAL_FLAG or NUM_PTS
        if netcdf_var_name.matches('QUAL_FLAG') || netcdf_var_name.matches('NUM_PTS') then begin
            str_element, cdf_var_attr, 'VAR_TYPE', 'support_data', /add
        endif else begin
            str_element, cdf_var_attr, 'VAR_TYPE', 'data', /add
        endelse
        str_element, cdf_var_attr, 'COORDINATE_SYSTEM', 'unknown', /add
    endelse
    
    ; update numattr:
    str_element, cdf_var, 'numattr', n_tags(cdf_var_attr), /add
    ; update numrec. if data is 1D and time varying, should be data array_length:
    numrec = n_elements(netcdf_var_dataptr_data)
    str_element, cdf_var, 'numrec', numrec, /add
    ; update ndimen (if needed). if data is 1D and time varying, should be [byte(1)]:
    str_element, cdf_var, 'ndimen', [byte(1)], /add
    ; update d (if needed). if data is 1D and time varying, should be [numrecL] (cast to long):
    str_element, cdf_var, 'd', [long(numrec)], /add
    cdf_var.dataptr = ptr_new(netcdf_var_dataptr_data)
    cdf_var.attrptr = ptr_new(cdf_var_attr)
    
    return, cdf_var
end

function poes_netcdfstruct_to_cdfstruct, netCDFi
    compile_opt idl2
    ; Perform preliminary checks before proceeding:
    if ~is_struct(netCDFi) then begin
        dprint, dlevel=1, 'Must provide a netCDF structure'
        return, -1
    endif
    if ~tag_exist(netCDFi.g_attributes, 'project') then begin
        dprint, dlevel=1, 'netCDF structure must contain "project" global attribute'
        return, -1
    endif 
    if netCDFi.g_attributes.project ne 'POES/MetOp' then begin
        dprint, dlevel=1, 'netCDF structure project attribute must be "POES/MetOp"'
        return, -1
    endif
    str_element, netCDFi.vars, 'time', SUCCESS=s
    if ~s then begin
        dprint, dlevel=1, 'netCDF structure must have "time" variable'
        return, -1
    endif
    ; Extract spacecraft ID:
    path_array=STRSPLIT(netCDFi.FILENAME,"/",/extract)
    if n_elements(path_array) eq 0 then begin
        path_array=STRSPLIT(netCDFi.FILENAME,"\\",/extract)
    endif
    if n_elements(path_array) eq 0 then begin
        dprint, dlevel=1, 'ERROR! NETCDF filename could not be extracted.'
        dprint, dlevel=1, 'Detected filename value:'
        dprint, dlevel=1, netCDFi.FILENAME
        return, -1
    endif   
    satellite_id=path_array[-2]
    ; Extract spacecraft prefix:
    probe_num = STRMID((STRSPLIT(satellite_id, '[^0-9]+', /REGEX, /EXTRACT))[-1], 1, /REVERSE_OFFSET)
    probename = (STRSPLIT(satellite_id,probe_num,/EXTRACT))[0]
    prefix=strmid(probename,0,1) + string(probe_num,format='(I02)')
    sample_timeresolution = netCDFi.g_attributes.TIME_COVERAGE_RESOLUTION
    sample_timeresolution_numval = STRSPLIT(sample_timeresolution, '[^0-9]+', /REGEX, /EXTRACT)
    if n_elements(sample_timeresolution_numval) eq 2 then begin
        sample_time = sample_timeresolution_numval[0] + "." + sample_timeresolution_numval[1]
    endif else begin
        sample_time = sample_timeresolution_numval[0]
    endelse
    sample_units = (STRSPLIT(sample_timeresolution, sample_time, /EXTRACT))[0]
    g_attributes = create_struct($
        'PROJECT', netCDFi.g_attributes.project,$
        'SOURCE_NAME', prefix+'>Polar Orbiting Environmental Satellites/Meteorological Operational satellite',$
        'DISCIPLINE', ["Earth Science > Sun-earth Interactions > Ionosphere/Magnetosphere Particles > Electron Flux", "Earth Science > Sun-earth Interactions > Ionosphere/Magnetosphere Particles "], $
        'DATA_TYPE', 'Particle Precipitation data.', $
        'DESCRIPTOR', netCDFi.g_attributes.PROCESSING_LEVEL, $
        'DATA_VERSION', '1', $
        'PI_NAME', netCDFi.g_attributes.point_of_contact, $
        'PI_AFFILIATION', netCDFi.g_attributes.institution, $
        'TEXT', netCDFi.g_attributes.title, $
        'INSTRUMENT_TYPE', "Space Environment Monitor (SEM-2) spectrometer", $
        'MISSION_GROUP', 'POES/MetOp', $
        'LOGICAL_FILE_ID', '',$ ; ISTP: (source_name / data_type / descriptor / date / data_version)
        'LOGICAL_SOURCE_DESCRIPTION', STRUPCASE(satellite_id) + " SEM-2 Particle Fluxes", $
        'TIME_RESOLUTION', sample_time + ' ' + sample_units, $
        'RULES_OF_USE', 'Open Data for Scientific Use. Every effort has been made to provide the highest quality data but the instruments have known inherent limitations. Please contact the data provider for information on how to properly use the data.', $
        'GENERATED_BY', 'THEMIS/IGPP', $
        'ACKNOWLEDGEMENT', '', $
        'LINK_TITLE', 'POES/MetOp Data Archive', $
        'HTTP_LINK', 'http://www.ngdc.noaa.gov/stp/satellite/poes/index.html', $
        'FILE_NAMING_CONVENTION', 'source_descriptor_datatype')
    all_attrs_arr = tag_names(g_attributes)
    inq = create_struct($
        'nzvars', netCDFi.nv, $
        'ndims', 0, $
        'DECODING', 'HOST_DECODING', $
        'ENCODING', 'NETWORK_ENCODING', $
        'MAJORITY', 'ROW_MAJOR', $
        'MAXREC', -1, $
        'nvars', 0, $
        'natts', netCDFi.nv, $
        'dim', 0)

    ; Create output cdf structure:
    cdf_struct = create_struct('filename', netCDFi.filename, 'nv', netCDFi.nv)
    ; Start by creating an epoch structure from the time varible:
    cdf_epoch_struct = poes_netcdfvar2cdfvar(netCDFi.vars.time[0])
    ; Initialize array to hold all variables:
    cdf_record = [cdf_epoch_struct]
    all_attrs_arr = [all_attrs_arr,tag_names(*cdf_epoch_struct.attrptr[0])]
    
    ; Loop through netcdf structure fields, create CDF variables for them, and append them to cdf_record:
    for i = 0, netCDFi.nv-1 do begin
        ; Ignore variables which are part of Epoch:
        if where(['time','year','day','msec'] eq netCDFi.vars.(i).name) eq -1 then begin
            cdf_var_struct = poes_netcdfvar2cdfvar(netCDFi.vars.(i))
            cdf_record = [cdf_record,cdf_var_struct]
            all_attrs_arr = [all_attrs_arr,tag_names(*cdf_var_struct.attrptr[0])]
        endif
    endfor
    ; define nv using number of elements in the cdf_record array:
    nzvars = n_elements(cdf_record)
    ; Loop through nv_val and update variable num
    for i=0, nzvars-1 do begin
        str_element, cdf_record[i], 'num', i, /add
    endfor
    ; Update inq structure using cdf_record
    str_element, inq, 'nzvars', nzvars, /add
    str_element, inq, 'natts', n_elements( all_attrs_arr[UNIQ(all_attrs_arr, SORT(all_attrs_arr))] ), /add
    ; Add structures and structure arrays to CDF structure fields:
    str_element, cdf_struct, 'g_attributes', g_attributes, /add
    str_element, cdf_struct, 'inq', inq, /add
    str_element, cdf_struct, 'vars', cdf_record, /add
    str_element, cdf_struct, 'nv', nzvars, /add
    return, cdf_struct
end

pro poes_netcdf2tplot, files, temporal_dim=temporal_dim, verbose=verbose, prefix = prefix, suffix=suffix, tplotnames=tplotnames, load_labels=load_labels
    ; Load netcdf structure from file name:
    netCDFi = netcdf_load_vars(files,temporal_dim=temporal_dim)
    ; Create CDF-like structure from netcdf structure:
    cdf_struct = poes_netcdfstruct_to_cdfstruct(netCDFi)
    ; Load tplot variables using CDF-like structure:
    cdf_info_to_tplot, cdf_struct, verbose=verbose, prefix=prefix, suffix=suffix, tplotnames=tplotnames, load_labels=load_labels
end
