;+
; Read orbit number.
;
; time. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
; local_root=. The local root directory for saving rbsp data.
; remote_root=. The URL for grabing rbsp data.
; version=. Default is 'v01'.
;-

pro rbsp_efw_phasef_read_orbit_num, time, probe=probe, $
    version=version, local_root=local_root, remote_root=remote_root, $
    errmsg=errmsg

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'a'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v01'

;---Init settings.
    valid_range = rbsp_efw_phasef_get_valid_range('orbit_num', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_orbit_num_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','orbit_num',rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','orbit_num',rbspx,'%Y']

    request = dictionary($
        'pattern', dictionary($
;            'remote_file', join_path([remote_path,base_name]), $
;            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_orbit_num', $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if errmsg ne '' then begin
        request.nonexist_files = request.files
    endif
    if n_elements(request.nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_read_orbit_num_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    var = 'rbsp'+probe+'_orbit_num'
    store_data, var, limits={$
        ynozero:1, $
        ytitle:'(#)', $
        labels: 'Orbit #' }


end

stop
probes = ['a','b']
secofday = 86400d
foreach probe, probes do begin
    time_range = rbsp_efw_phasef_get_valid_range('spice', probe=probe)
    days = make_bins(time_range, secofday)
    foreach day, days do begin
        tr = day+[0,secofday]
        rbsp_efw_phasef_read_orbit_num, tr, probe=probe
    endforeach
endforeach
stop

; No orbit num for this day.
probe = 'b'
time_range = time_double(['2019-01-01','2020-01-01'])
rbsp_efw_phasef_read_orbit_num, time_range, probe=probe
end
