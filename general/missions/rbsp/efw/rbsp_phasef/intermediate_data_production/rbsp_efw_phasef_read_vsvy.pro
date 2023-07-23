;+
; Read the Vsvy data ready for >L2 data production.
; This is the L1 vsvy data with time tag correction applied.
;
; time. The time range in unix time.
; probe=. 'a' or 'b'.
; local_root=. The local root directory for saving rbsp data.
; remote_root=. The URL for grabing rbsp data.
; version=. Default is 'v01'.
;-

pro rbsp_efw_phasef_read_vsvy, time, probe=probe, $
    version=version, local_root=local_root, remote_root=remote_root

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
    valid_range = rbsp_efw_phasef_get_valid_range('vsvy_l1', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_vsvy_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','vsvy',rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','vsvy',rbspx,'%Y']

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
                'in_vars', rbspx+'_efw_vsvy', $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_read_vsvy_gen_file, file_time, probe=probe, filename=local_file, version=version
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    prefix = 'rbsp'+probe+'_'
    var = prefix+'efw_vsvy'
    nboom = 6
    store_data, var, limits={$
        labels:'V'+string(indgen(nboom)+1,format='(I0)'), $
        labflag: -1, $
        ytitle: rbspx+'!Cefw_vsvy!C(V)' }

    dtime = 1d/16
    get_data, var, times, data
    store_data, var, times-dtime, data

end

time_range = time_double(['2015-01-01','2016-01-01'])
time_range = time_double(['2014-01-01','2014-01-05'])
rbsp_efw_phasef_read_vsvy, time_range, probe='a'
end
