;+
; Read VB1 data, the splitited version.
;-

pro rbsp_efw_phasef_read_vb1, time, probe=probe

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([diskdir('data'),'rbsp'])
    if n_elements(remote_root) eq 0 then remote_root = 'http://rbsp.space.umn.edu/rbsp_efw'
    if n_elements(version) eq 0 then version = '.*'

;---Init settings.
    valid_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-15']): time_double(['2012-09-08','2019-07-17'])
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_l1_vb1_%Y%m%d_%H%M_'+version+'.cdf'
    local_path = [local_root,rbspx,'l1','vb1_split','%Y']
    remote_path = [remote_root,rbspx,'l1','vb1_split','%Y']

    request = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 600., $
        'extension', fgetext(base_name), $
        ; Other vars are vb1_labl, vb1_unit.
        'var_list', list($
            dictionary($
                'in_vars', 'vb1', $
                'out_vars', rbspx+'_vb1', $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch16')))

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

;---Read data from files and save to memory.
    read_files, time, files=files, request=request


end

time_range = time_double(['2013-06-10/05:57','2013-06-10/06:05'])
probe = 'b'
rbsp_efw_phasef_read_vb1, time_range, probe=probe
end
