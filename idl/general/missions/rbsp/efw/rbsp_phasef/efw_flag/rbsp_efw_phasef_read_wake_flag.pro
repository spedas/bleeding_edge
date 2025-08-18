pro rbsp_efw_phasef_read_wake_flag, time, probe=probe, id=datatype, $
    print_data_type=print_data_type, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    min_bw_ratio=min_bw_ratio

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v02'
    if n_elements(datatype) eq 0 then datatype = 'wake_flag'


;---Init settings.
    type_dispatch = hash()
    valid_range = rbsp_efw_phasef_get_valid_range('e_uvw', probe=probe)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'
    base_name = rbspx+'_efw_wake_flag_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_flag','wake_flag',rbspx,'%Y']
    remote_path = [remote_root,'efw_flag','wake_flag',rbspx,'%Y']

    type_dispatch['wake_flag'] = dictionary($
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
                'in_vars', prefix+['eu','ev']+'_wake_flag', $
                'time_var_name', 'unix_time', $
                'time_var_type', 'unix')))

    type_dispatch['euv'] = dictionary($
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
                'in_vars', prefix+['eu','ev']+'_fixed', $
                'time_var_name', 'unix_time', $
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
            rbsp_efw_phasef_read_wake_flag_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    if datatype eq 'wake_flag' then begin
        eu_flag = get_var_data(prefix+'eu_wake_flag', times=times)
        ev_flag = get_var_data(prefix+'ev_wake_flag')
        store_data, prefix+'wake_flag', times, (eu_flag or ev_flag)
        add_setting, prefix+'wake_flag', /smart, dictionary($
            'display_type', 'scalar', $
            'unit', '#', $
            'short_name', 'Wake', $
            'yrange', [-0.2,1.2] )
    endif

end

time_range = time_double(['2013-01-12','2013-01-13'])
probe = 'b'
rbsp_efw_phasef_read_wake_flag, time_range, probe=probe, id='euv'
rbsp_efw_phasef_read_wake_flag, time_range, probe=probe, id='wake_flag'
end
