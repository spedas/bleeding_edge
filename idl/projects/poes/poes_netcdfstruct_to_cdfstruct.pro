;function cdf_struct2cdf_info_struct,cdf_struct
;    ; omits 'compression', 'gzip_level', and 'g_att_names', since 
;    ; those attributes aren't used.
;    cdf_info_struct = create_struct($
;      'filename',cdf_struct.filename,$
;      'inq',cdf_struct.inq,$
;      'g_attributes',cdf_struct.g_attributes,$
;      'nv',cdf_struct.nv,$
;      'vars',cdf_struct.vars)
;    return cdf_info_struct
;end

;function get_formatted_vars,cdf_info_struct,varformat=varformat,spdf_dependencies=spdf_dependencies
;    ; take optional list of variable formats and optional 
;    ; spdf_dependencies keyword and return list of variables which must be 
;    ; extracted from the netcdf file
;    if ~keyword_set(varformat) then begin
;        dprint,verbose=verbose,'Variable format list required! Returning original structure...'
;        return,cdf_info_struct
;    endif else begin
;        vars_filtered=''
;        vars_filtered = [vars_filtered, strfilter(cdf_info_struct.vars.name,varformat,delimiter=' ')]
;        vars_filtered = vars_filtered[1:*]
;        if keyword_set(spdf_dependencies) then begin
;            depnames = ''
;            for i=0,n_elements(vars_filtered)-1 do begin
;                vnum = where(vars_filtered[i] eq cdf_info_struct.vars.name,nvnum)
;                if nvnum eq 0 then message,'This should never happen, report error to D. Larson: davin@ssl.berkeley.edu'
;                vi = cdf_info_struct.vars[vnum]
;                depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_TIME',default='')]   ;bpif vars[i] eq 'tha_fgl'
;                depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_0',default='')]
;                ndim = vi.ndimen
;                for j=1,ndim do begin
;                    depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_'+strtrim(j,2),default='')]
;                endfor
;            endfor
;            if keyword_set(depnames) then depnames=depnames[[where(depnames)]]
;            depnames = depnames[uniq(depnames,sort(depnames))]
;            vars_filtered = [vars_filtered,depnames]
;            vars_filtered = vars_filtered[uniq(vars_filtered,sort(vars_filtered))]
;            vars_filtered = vars_filtered[where(vars_filtered)]
;        endif
;        return vars_filtered
;    endelse
;end
;
;function extract_var_list,cdf_info_struct,var_list
;    ; copy input structure into one which can be modified:
;    reformatted_struct = cdf_info_struct
;    ; Loop over the input variable list:
;    for j=0,n_elements(var_list)-1 do begin
;        ; nw seems to hold a count of occurrences of the 
;        ; current variable in the input structure's 
;        ; variable names attribute
;        ;  
;        ; w is the first subscript/index of that instance 
;        ; where the current variable is found in the input 
;        ; structure's variable names attribute
;        w = (where( strcmp(reformatted_struct.vars.name, var_list[j]) , nw))[0]
;        ; if the current variable appears at least once, continue. Otherwise, print warning:
;        if nw ne 0 then begin
;            ; set vi as the variable structure belonging to the current variable name:
;            vi = reformatted_struct.vars[w]
;            dprint,verbose=verbose,dlevel=7,vi.name
;            
;;            vars = create_struct('name', 'default')
;;            str_element, vars, 'num', 0, /add
;;            str_element, vars, 'is_zvar', 1, /add
;;            str_element, vars, 'datatype', 'CDF_REAL', /add
;;            str_element, vars, 'type', 5, /add ;;;;;;;;;;;;;;;;;;;;;;;;;; double
;;            str_element, vars, 'numattr', -1, /add
;;            str_element, vars, 'numelem', 1, /add
;;            str_element, vars, 'recvary', byte(1), /add
;;            str_element, vars, 'numrec', 1, /add
;;            str_element, vars, 'ndimen', 0, /add
;;            str_element, vars, 'd', 0, /add
;;            str_element, vars, 'dataptr', ptr_new(0), /add
;;            str_element, vars, 'attrptr', ptr_new(0), /add                        
;            ; Determine the number of records associated with the current variable:
;            ; TODO: get from reformatted structure:
;;            q=!quiet & !quiet=1 & cdf_control,id,variable=vi.name,get_var_info=vinfo & !quiet=q
;;            numrec = vinfo.maxrec+1
;            numrec = vi.numrec
;            ; Check if the current variable has more than one record:
;            if numrec gt 0 then begin
;                ;q = !quiet
;                value = 0
;                ; If so, check if a variable is a zvar:
;                if vi.is_zvar then begin
;                    ; TODO: get from reformatted structure:
;                    cdf_varget,id,vi.name,value=value,/string,rec_count=numrec
;                endif else begin
;                    ; TODO: get from reformatted structure:
;                    vinq = cdf_varinq(id,vi.num,zvar=vi.is_zvar)
;                    dimc = vinq.dimvar * info.inq.dim
;                    dimw = where(dimc eq 0,c)
;                    if c ne 0 then dimc[dimw] = 1
;                    
;                    ; TODO: get from reformatted structure:
;                    CDF_varget,id,vi.num,zvar=0,value=value,/string,COUNT=dimc,REC_COUNT=numrec
;                    
;                    value = reform(value,/overwrite)
;                    dprint,phelp=2,dlevel=5,vi,dimc,value
;                endelse
;                
;                
;                ;!quiet = q
;                ;Check if the record varies:
;                if vi.recvary then begin
;                    ; If it does, check if the number of dimensions is greater than one:
;                    if (vi.ndimen ge 1) then begin
;                        ; If they are, check if the variable only has a single record:
;                        if numrec eq 1 then begin
;                          ; If it does, throw a warning and define value as 1:
;                          dprint,dlevel=3,'Warning: Single record! ',vi.name,vi.ndimen,vi.d
;                          value = reform(/overwrite,value, [1,size(/dimensions,value)] )  ; Special case for variables with a single record
;                        endif else begin
;                          
;                          transshift = shift(indgen(vi.ndimen+1),1)
;                          value=transpose(value,transshift)
;                        endelse
;                    endif else value = reform(value,/overwrite)
;                    
;                    if not keyword_set(vi.dataptr) then begin
;                        vi.dataptr = ptr_new(value,/no_copy)
;                    endif else begin
;                        *vi.dataptr = [*vi.dataptr,temporary(value)]
;                    endelse
;                    
;                endif else begin
;                    if not keyword_set(vi.dataptr) then vi.dataptr = ptr_new(value,/no_copy)
;                endelse
;            endif
;            
;            if not keyword_set(vi.attrptr) then begin
;                ; TODO: get from reformatted structure:
;                vi.attrptr = ptr_new( cdf_var_atts(id,vi.name) )
;            endif
;            
;            ; replace the current variable in the output structure with the modified variable:
;            reformatted_struct.vars[w] = vi
;            
;        endif else dprint,dlevel=1,verbose=verbose,'WARNING: Variable "'+var_list[j]+'" not found!'
;    endfor
;    return reformatted_struct
;end

function poes_netcdfstruct_to_cdfstruct, netCDFi, varformat=varformat
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
        
        process_level = netCDFi.g_attributes.PROCESSING_LEVEL
        title = netCDFi.g_attributes.title
        
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
    
    ; pass newstruct to helper functions to extract variables according to 
    ; varformat and spdf_dependencies:
    ; newstuct should already include proper variables for the info struct 
    ; required by helper functions, and the functions return new 
    ; structures, so it the newstruct may be passed directly
;    new_formatted_struct = extract_var_list($
;        newstruct,$
;        get_formatted_vars($
;            newstruct,$
;            varformat=varformat,$
;            spdf_dependencies=spdf_dependencies)$
;        )
    return, newstruct
    ;return, new_formatted_struct
end