;+
; Read E UVW after calibration.
; 
; keep_spin_axis=. Set to keep spin axis data. Set to it to 0 by default.
;-

pro rbsp_efw_phasef_read_e_uvw, time, probe=probe, keep_spin_axis=keep_spin_axis

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v02'


;---Init settings.
    valid_range = rbsp_efw_phasef_get_valid_range('e_uvw', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_e_uvw_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','e_uvw',rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','e_uvw',rbspx,'%Y']

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
                'in_vars', rbspx+'_efw_esvy', $
                'out_vars', rbspx+'_e_uvw', $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_read_e_uvw_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    var = rbspx+'_e_uvw'
    dtime = 1d/32
    if tnames(var) ne '' then begin
        get_data, var, times, e_uvw
        if ~keyword_set(keep_spin_axis) then e_uvw[*,2] = 0
        store_data, var, times-dtime, e_uvw
    endif
    add_setting, var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'E', $
        'unit', 'mV/m', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )

end


probe = 'a'
time_range = time_double(['2013-05-01','2013-05-03'])
rbsp_efw_phasef_read_e_uvw, time_range, probe=probe
end
