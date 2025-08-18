;+
; Read the EMFISIS B field with corrections including:
;   spicek removal, downsampled to 16 S/s, time tag correction.
;-

pro rbsp_efw_phasef_read_b_mgse, time, probe=probe, $
    version=version, local_root=local_root, remote_root=remote_root


    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    ; v01 is essentially emfisis original data with invalid data removed.
    ; v02 adds time tag correction to cast emfisis data to the true measured times.
    if n_elements(version) eq 0 then version = 'v02'


;---Init settings.
    valid_range = rbsp_efw_phasef_get_valid_range('b_mgse', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_b_mgse_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','b_mgse_'+version,rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','b_mgse_'+version,rbspx,'%Y']


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
                'in_vars', rbspx+'_b_mgse', $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_read_b_mgse_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request
    prefix = 'rbsp'+probe+'_'
    b_mgse_var = prefix+'b_mgse'
    add_setting, b_mgse_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', 'nT', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )


end

;secofday = constant('secofday')
;days = make_bins(time_double(['2012','2020']),secofday)
;probes = ['a']
;foreach probe, probes do begin
;    foreach day, days do begin
;        rbsp_efw_phasef_read_b_mgse, day+[0,secofday], probe=probe
;    endforeach
;endforeach
;stop

time_range = time_double(['2013-01-01','2013-01-02'])
time_range = time_double(['2015-12-29','2015-12-31'])   ; wrong data.
time_range = time_double(['2012-09-06','2012-09-07'])
probe = 'a'

time_range = time_double(['2018-09-27','2018-09-28'])   ; weird data.
probe = 'b'
rbsp_efw_phasef_read_b_mgse, time_range, probe=probe
end
