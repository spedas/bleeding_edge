;+
; Save the following data to CDF:
;   q_uvw2gse. Fixed for artificial wobble, Saved at 1 sec cadence.
;   r_mgse. In Re, 10 sec.
;   v_mgse. In km/s, 10 sec.
;   e_mgse. In mV/m, 10 sec, include Ex.
;   b_mgse. In nT, 10 sec.
;-

pro rbsp_efw_phasef_prepare_residue_removal, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'rbsp'])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v02'
    if n_elements(datatype) eq 0 then datatype = 'perigee_correction_products'


;---Init settings.
    type_dispatch = hash()
    valid_range = (probe eq 'a')? ['2012-09-05','2019-10-15']: ['2012-09-05','2019-07-17']
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_perigee_correction_products_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'perigee_correction_products','%Y']
    remote_path = [remote_root,'perigee_correction_products',rbspx,'%Y']
    ; quaternion.
    type_dispatch['quaternion'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_q_uvw2gse', $
                'time_var_name', 'q_time', $
                'time_var_type', 'unix')))
    ; other variables.
    type_dispatch['perigee_correction_products'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_'+['r','v','e','b']+'_mgse', $
                'time_var_name', 'time', $
                'time_var_type', 'unix')))
    type_dispatch['b_mgse'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_'+['b']+'_mgse', $
                'time_var_name', 'time', $
                'time_var_type', 'unix')))

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_prepare_residue_removal_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request


;---Add settings.
    foreach var_list, request.var_list do begin
        out_vars = (var_list.haskey('out_vars'))? var_list.out_vars: var_list.in_vars
        foreach var, out_vars do begin
            get_data, var, times, data
            index = uniq(times)
            store_data, var, times[index], data[index,*]
        endforeach
    endforeach

    prefix = 'rbsp'+probe+'_'
    xyz = constant('xyz')

    r_var = prefix+'r_mgse'
    if tnames(r_var) ne '' then begin
        add_setting, r_var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'Re', $
            'short_name', 'R', $
            'coord', 'MGSE', $
            'coord_labels', xyz )
    endif

    v_var = prefix+'v_mgse'
    if tnames(v_var) ne '' then begin
        add_setting, v_var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'km/s', $
            'short_name', 'V', $
            'coord', 'MGSE', $
            'coord_labels', xyz )
    endif

    e_var = prefix+'e_mgse'
    if tnames(e_var) ne '' then begin
        add_setting, e_var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'mV/m', $
            'short_name', 'E', $
            'coord', 'MGSE', $
            'coord_labels', xyz )
    endif

    b_var = prefix+'b_mgse'
    if tnames(b_var) ne '' then begin
        add_setting, b_var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'nT', $
            'short_name', 'B', $
            'coord', 'MGSE', $
            'coord_labels', xyz )
    endif


end



stop
time_range = time_double(['2012-09-05','2019-12-31'])
probes = ['a']
;time_range = time_double(['2012-09-05','2019-12-31'])
;probes = ['a']

secofday = constant('secofday')
days = make_bins(time_range, secofday)
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    foreach day, days do begin
        time = day+[0,secofday]
        rbsp_efw_phasef_prepare_residue_removal, time, probe=probe
    endforeach
endforeach

end
