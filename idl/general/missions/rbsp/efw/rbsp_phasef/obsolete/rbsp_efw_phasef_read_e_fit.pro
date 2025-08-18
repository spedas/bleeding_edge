;+
; Read E fit in MGSE.
;-

pro rbsp_efw_phasef_read_e_fit, time, probe=probe

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v01'
    if n_elements(datatype) eq 0 then datatype = 'e_fit'

;---Init settings.
    type_dispatch = hash()
    valid_range = rbsp_efw_phasef_get_valid_range('e_fit', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_efit_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'e_fit','%Y']
    remote_path = [remote_root,'e_fit',rbspx,'%Y']

    type_dispatch['e_fit'] = dictionary($
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
                'in_vars', rbspx+'_efit_mgse', $
                'out_vars', rbspx+'_efit_mgse', $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))

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
            rbsp_efw_phasef_read_e_fit_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    var = rbspx+'_efit_mgse'
    add_setting, var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'E', $
        'unit', 'mV/m', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )

end


probe = 'a'
time_range = time_double(['2013-05-01','2013-05-03'])
rbsp_efw_phasef_read_e_fit, time_range, probe=probe
end
