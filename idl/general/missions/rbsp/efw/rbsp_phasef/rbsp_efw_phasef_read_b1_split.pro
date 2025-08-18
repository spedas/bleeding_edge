;+
; Read VB1 data, the splitited version.
; 
; time. The time range in unix timestamp.
; probe=. 'a' or 'b'.
; id=. 'vb1', 'mscb1', or 'eb1'.
;-

pro rbsp_efw_phasef_read_b1_split, time, probe=probe, id=data_type

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = 'http://rbsp.space.umn.edu/rbsp_efw'
    if n_elements(version) eq 0 then version = 'v02'
    if n_elements(data_type) eq 0 then message, 'No input data_type ...'

;---Init settings.
    valid_range = rbsp_efw_phasef_get_valid_range(data_type, probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_l1_'+data_type+'_%Y%m%d_%H%M_'+version+'.cdf'
    local_path = [local_root,rbspx,'l1',data_type+'_split','%Y']
    remote_path = [remote_root,rbspx,'l1',data_type+'_split','%Y']

    request = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 15*60., $
        'extension', fgetext(base_name), $
        ; Other vars are vb1_labl, vb1_unit.
        'var_list', list($
            dictionary($
                'in_vars', data_type, $
                'out_vars', rbspx+'_'+data_type, $
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

time_range = time_double(['2014-01-01','2014-01-02'])
probe = 'a'
rbsp_efw_phasef_read_b1_split, time_range, probe=probe, id='vb1'
end
