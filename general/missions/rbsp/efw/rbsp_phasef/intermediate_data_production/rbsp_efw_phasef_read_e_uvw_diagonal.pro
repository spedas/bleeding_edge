;+
; The components are the E fields along diagonal directions, not UVW.
;-

pro rbsp_efw_phasef_read_e_uvw_diagonal, time, probe=probe, pairs=pairs

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v01'

;---Init settings.
    valid_range = rbsp_efw_phasef_get_valid_range('e_uvw', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_e_uvw_diagonal_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','e_uvw_diagonal',rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','e_uvw_diagonal',rbspx,'%Y']
    if n_elements(pairs) eq 0 then pairs = ['13','14','23','24']

    request = dictionary($
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
                'in_vars', rbspx+'_efw_esvy_'+pairs, $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_read_e_uvw_diagonal_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request


;---Fix time tag offset.
    dtime = 1d/16
    prefix = 'rbsp'+probe+'_'
    vars = prefix+'efw_esvy_'+['13','14','23','24']
    foreach var, vars do begin
        get_data, var, times, data
        store_data, var, times-dtime, data
    endforeach

end

time_range = time_double(['2013-01-01','2013-02-01'])
time_range = time_double(['2015-01-01','2016-01-01'])
time_range = time_double(['2014-01-01','2014-01-02'])
rbsp_efw_phasef_read_e_uvw_diagonal, time_range, probe='a'
end
