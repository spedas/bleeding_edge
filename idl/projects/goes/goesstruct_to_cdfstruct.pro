;+
; Function:    
;         GOESstruct_to_cdfstruct
;         
; Purpose:
;         Converts an IDL structure returned from a GOES netCDF file 
;         into an IDL structure that can be passed to cdf_info_to_tplot
;         
; Input:
;         netCDFi: GOES IDL structure from ncdf_load_vars
;         
; Output: 
;         IDL structure that follows the SPDF CDF standard
;         (at least enough so to be read by cdf_info_to_tplot)
;         
; 
; $LastChangedBy: nikos $
; $LastChangedDate: 2023-02-02 07:46:23 -0800 (Thu, 02 Feb 2023) $
; $LastChangedRevision: 31461 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/goesstruct_to_cdfstruct.pro $
;-
function GOESstruct_to_cdfstruct, netCDFi
    compile_opt idl2
    if ~is_struct(netCDFi) then begin
        dprint, dlevel=1, 'Must provide a netCDF structure'
        return, -1
    endif
    newstruct = create_struct('filename', netCDFi.filename, 'nv', netCDFi.nv)

    if tag_exist(netCDFi.g_attributes, 'conventions') then begin
        ; find the GOES spacecraft id
        satellite_id = strsplit(netCDFi.g_attributes.satellite_id, '^GOES-', /regex, /extract)
        prefix = 'g'+satellite_id[0]

        case netCDFi.g_attributes.instrument of
            'Magnetometer': instru = 'fgm'
            'Electron,Proton,Alpha Detector': instru = 'epead'
            'Energetic Particle Sensor': instru = 'eps'
            'Magnetospheric Electron Detector': instru = 'maged'
            'Magnetospheric Proton Detector': instru = 'magpd'
            'Magnetospheric Electron Detector (MAGED)': instru = 'maged'
            'Magnetospheric Proton Detector (MAGPD)': instru = 'magpd'
            'High energy Proton and Alpha Detector': instru = 'hepad'
            'X-ray Sensor': instru = 'xray'
            else:  instru = 'unknown'
        endcase
        process_level = netCDFi.g_attributes.process_level
        title = netCDFi.g_attributes.title
        sample_time = netCDFi.g_attributes.sample_time
        sample_units = netCDFi.g_attributes.sample_unit
        
        g_attributes = create_struct('PROJECT', 'GOES')
        str_element, g_attributes, 'SOURCE_NAME', prefix+'>Geostationary Operational Environmental Satellite', /add
        str_element, g_attributes, 'DISCIPLINE', 'Space Physics>Magnetospheric Science', /add
        str_element, g_attributes, 'DATA_TYPE', strupcase(instru), /add
        str_element, g_attributes, 'DESCRIPTOR', process_level, /add
        str_element, g_attributes, 'DATA_VERSION', '1', /add
        str_element, g_attributes, 'PI_NAME', 'Howard J. Singer', /add
        str_element, g_attributes, 'PI_AFFILIATION', 'NOAA Space Weather Prediction Center', /add
        str_element, g_attributes, 'TEXT', title, /add
        str_element, g_attributes, 'INSTRUMENT_TYPE', netCDFi.g_attributes.instrument, /add
        str_element, g_attributes, 'MISSION_GROUP', 'GOES', /add
        str_element, g_attributes, 'LOGICAL_SOURCE_DESCRIPTION', 'temp', /add
        str_element, g_attributes, 'TIME_RESOLUTION', sample_time + ' ' + sample_units, /add
        str_element, g_attributes, 'RULES_OF_USE', 'Open Data for Scientific Use', /add
        str_element, g_attributes, 'GENERATED_BY', 'THEMIS/IGPP', /add
        str_element, g_attributes, 'ACKNOWLEDGEMENT', 'NASA Contract NAS5-02099', /add
        str_element, g_attributes, 'LINK_TITLE', 'National Geophysical Data Center', /add
        str_element, g_attributes, 'HTTP_LINK', 'https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/', /add
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
        str_element, vars, 'type', 5, /add ;;;;;;;;;;;;;;;;;;;;;;;;;; double
        str_element, vars, 'numattr', -1, /add
        str_element, vars, 'numelem', 1, /add
        str_element, vars, 'recvary', byte(1), /add
        str_element, vars, 'numrec', 1, /add
        str_element, vars, 'ndimen', 0, /add
        str_element, vars, 'd', 0, /add 
        str_element, vars, 'dataptr', ptr_new(0), /add
        str_element, vars, 'attrptr', ptr_new(0), /add

        dataptrs = ptrarr(netCDFi.nv)
        attrptrs = ptrarr(netCDFi.nv)
        variables = replicate(vars, netCDFi.nv)
        
        ; loop through the variables to find the time, location data
        for i = 0, netCDFi.nv-1 do begin
            ; make sure this variable has a valid data ptr before trying to use it below
            if ~ptr_valid(netCDFi.vars.(i).dataptr) then continue
            
            ; need to check if the time units are in milliseconds
            ; if so, convert to seconds and update the units attribute
            if stregex(netCDFi.vars.(i).units, 'milliseconds') ne -1 then begin
                ; check that the dataptr is a valid pointer
                if ptr_valid(netCDFi.vars.(i).dataptr) then begin
                    time_data = *netCDFi.vars.(i).dataptr/1000. ; convert to seconds
                    netCDFi.vars.(i).units = 'seconds'
                endif else continue
            endif
            if netCDFi.vars.(i).name eq 'inclination' then begin
                inclination_data = *netCDFi.vars.(i).dataptr ; in degrees
            endif else if netCDFi.vars.(i).name eq 'time_tag_orbit' then begin
                ;time_data_orbit = *netCDFi.vars.(i).dataptr/1000. ; times for long/inclination pairs, convert to seconds
            endif else if netCDFi.vars.(i).name eq 'west_longitude' then begin
                west_longitude = *netCDFi.vars.(i).dataptr ; west longitude
            endif 
        endfor
        
        
        ; loop through the variables again, this time associating 
        ; the time variable with data variables
        for i = 0, netCDFi.nv-1 do begin
            attr = create_struct('DEPEND_0', 'epoch')
            if (netCDFi.vars.(i).name eq 'time_tag' || netCDFi.vars.(i).name eq 'time_tag_orbit') then begin
                str_element, vars, 'datatype', 'CDF_EPOCH', /add
                data = *netCDFi.vars.(i).dataptr/1000. ; convert from ms to seconds
            endif else begin
                str_element, vars, 'datatype', 'CDF_REAL', /add
                data = *netCDFi.vars.(i).dataptr
            endelse
            
            ; 'time_tag' is used consistently as the time variable tag for non-ephemeris data in the GOES data files
            ; 'time_tag_orbit' is used as the time variable tag for ephemeris data in the GOES data files
            if (netCDFi.vars.(i).name eq 'time_tag_orbit' || netCDFi.vars.(i).name eq 'inclination' || netCDFi.vars.(i).name eq 'west_longitude') then begin
                str_element, attr, 'DEPEND_TIME', 'time_tag_orbit', /add
            endif else begin
                str_element, attr, 'DEPEND_TIME', 'time_tag', /add
            endelse 
            str_element, attr, 'DISPLAY_TYPE', 'time_series', /add
            
            str_element, netCDFi.vars.(i), 'missing_value', missingval, SUCCESS=s
            if s ne 0 then str_element, attr, 'FILLVAL', missingval, /add else str_element, attr, 'FILLVAL', !values.f_nan, /add

            ; check if this variable has the attribute 'FORMAT'
            str_element, netCDFi.vars.(i), 'FORMAT', val, SUCCESS=s
            if s ne 0 then str_element, attr, 'FORMAT', netCDFi.vars.(i).format,/add

            str_element, netCDFi.vars.(i), 'LIN_LOG', linlogval, SUCCESS=s
            if s ne 0 then str_element, attr, 'SCALETYP', netCDFi.vars.(i).lin_log, /add

            ; check the name to see if this is support data
            ; QUAL_FLAG or NUM_PTS
            if (stregex(netCDFi.vars.(i).name, 'QUAL_FLAG') ne -1 || stregex(netCDFi.vars.(i).name, 'NUM_PTS') ne -1) then begin
                str_element, attr, 'VAR_TYPE', 'support_data', /add
            endif else begin
                str_element, attr, 'VAR_TYPE', 'data', /add
            endelse
            
            ; Unfortunately, the GOES variable structures do not contain 
            ; the coordinates outside of the description of the variable
            
            str_element, attr, 'COORDINATE_SYSTEM', 'unknown', /add
            str_element, attr, 'UNITS', netCDFi.vars.(i).units, /add

            variables[i].dataptr = ptr_new(data)
            variables[i].attrptr = ptr_new(attr)

            variables[i].name = netCDFi.vars.(i).name
        endfor
        ; construct the structure in a format similar to that returned by cdf_load_vars
        str_element, newstruct, 'g_attributes', g_attributes, /add
        str_element, newstruct, 'inq', inq, /add
        str_element, newstruct, 'vars', variables, /add
    endif else begin
        dprint, dlevel=1, 'This structure does not appear to contain valid GOES data'
    endelse
    return, newstruct
end