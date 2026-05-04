function poes_netcdfstruct_to_cdfstruct, netCDFi
  compile_opt idl2
    if ~is_struct(netCDFi) then begin
        dprint, dlevel=1, 'Must provide a netCDF structure'
        return, -1
    endif
    newstruct = create_struct('filename', netCDFi.filename, 'nv', netCDFi.nv)
    
    if tag_exist(netCDFi.g_attributes, 'project') then begin
      att_project_name=netCDFi.g_attributes.project
      if att_project_name eq 'POES/MetOp' then begin
        ; Preliminary checks passed 
        ; extract spacecraft ID:
        path_array=STRSPLIT(netCDFi.FILENAME,"/",/extract)
        if n_elements(patharray) eq 0 then begin
          path_array=STRSPLIT(netCDFi.FILENAME,"\\",/extract)
        endif  
        satellite_id=path_array[-2]
        ; extract spacecraft prefix:
        probe_num = STRMID((STRSPLIT(satellite_id, '[^0-9]+', /REGEX, /EXTRACT))[-1], 1, /REVERSE_OFFSET)
        probename = STRSPLIT(satellite_id,probe_num,/EXTRACT)
        prefix=strmid(probename,0,1) + string(probe_num,format='(I02)')
        
        ; note: don't appear to have instrument. skipping...
;        case netCDFi.g_attributes.instrument of
;          'Magnetometer': instru = 'fgm'
;          'Electron,Proton,Alpha Detector': instru = 'epead'
;          'Energetic Particle Sensor': instru = 'eps'
;          'Magnetospheric Electron Detector': instru = 'maged'
;          'Magnetospheric Proton Detector': instru = 'magpd'
;          'High energy Proton and Alpha Detector': instru = 'hepad'
;          'X-ray Sensor': instru = 'xray'
;        endcase
        process_level = netCDFi.g_attributes.PROCESSING_LEVEL
        title = netCDFi.g_attributes.title
        
        ; note: don't appear to have sample__time and sample_units. skipping...
        sample_timeresolution = netCDFi.g_attributes.TIME_COVERAGE_RESOLUTION
        sample_timeresolution_numval = STRSPLIT(sample_timeresolution, '[^0-9]+', /REGEX, /EXTRACT)
        if n_elements(sample_timeresolution_numval) eq 2 then begin
          sample_time = sample_timeresolution_numval[0] + "." + sample_timeresolution_numval[1]
        endif else begin
          sample_time = sample_timeresolution_numval
        endelse
        sample_units = STRSPLIT(sample_timeresolution, sample_time, /EXTRACT)
        
        g_attributes = create_struct('PROJECT', 'POES/MetOp')
        str_element, g_attributes, 'SOURCE_NAME', prefix+'>Polar Orbiting Environmental Satellites/Meteorological Operational satellite', /add
        str_element, g_attributes, 'DISCIPLINE', ["Earth Science > Sun-earth Interactions > Ionosphere/Magnetosphere Particles > Electron Flux", "Earth Science > Sun-earth Interactions > Ionosphere/Magnetosphere Particles "], /add
        str_element, g_attributes, 'DATA_TYPE', 'Particle Precipitation data.', /add
        str_element, g_attributes, 'DESCRIPTOR', process_level, /add
        str_element, g_attributes, 'DATA_VERSION', '1', /add
        str_element, g_attributes, 'PI_NAME', 'Rob Redmon', /add
        str_element, g_attributes, 'PI_AFFILIATION', 'NOAA National Centers for Environmental Information', /add
        str_element, g_attributes, 'TEXT', title, /add
        str_element, g_attributes, 'INSTRUMENT_TYPE', "Space Environment Monitor (SEM-2) spectrometer", /add
        str_element, g_attributes, 'MISSION_GROUP', 'POES/MetOp', /add
        str_element, g_attributes, 'LOGICAL_SOURCE_DESCRIPTION', 'temp', /add
        str_element, g_attributes, 'TIME_RESOLUTION', sample_time + ' ' + sample_units, /add
        str_element, g_attributes, 'RULES_OF_USE', 'Open Data for Scientific Use. Every effort has been made to provide the highest quality data but the instruments have known inherent limitations. Please contact the data provider for information on how to properly use the data.', /add
        str_element, g_attributes, 'GENERATED_BY', 'THEMIS/IGPP', /add
        str_element, g_attributes, 'ACKNOWLEDGEMENT', 'temp', /add
        str_element, g_attributes, 'LINK_TITLE', 'POES/MetOp Data Archive', /add
        str_element, g_attributes, 'HTTP_LINK', 'http://www.ngdc.noaa.gov/stp/satellite/poes/index.html', /add
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
          ; need to check if the time units are in milliseconds
          ; if so, convert to seconds and update the units attribute
          if stregex(netCDFi.vars.(i).units, 'millisec') ne -1 then begin
            time_data = *netCDFi.vars.(i).dataptr/1000. ; convert to seconds
            netCDFi.vars.(i).units = 'seconds'
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
          
          if (netCDFi.vars.(i).name eq 'time') then begin
            str_element, vars, 'datatype', 'CDF_EPOCH', /add
            data = *netCDFi.vars.(i).dataptr/1000. ; convert from ms to seconds
          endif else begin
            str_element, vars, 'datatype', 'CDF_REAL', /add
            data = *netCDFi.vars.(i).dataptr
          endelse

          str_element, attr, 'DEPEND_TIME', 'time', /add
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
        dprint, dlevel=1, 'netCDF structure project attribute must be "POES/MetOp"'
        return, -1
      endelse
    endif else begin
      dprint, dlevel=1, 'netCDF structure must contain "project" global attribute'
      return, -1
    endelse
    
    return, newstruct
end