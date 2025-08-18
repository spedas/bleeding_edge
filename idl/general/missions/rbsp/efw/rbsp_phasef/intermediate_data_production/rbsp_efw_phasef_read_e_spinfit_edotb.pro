;+
; Read spinfit E field with EdotB=0 correction in MGSE for all boom pairs.
;
; time. The time range in unix time.
; probe=. 'a' or 'b'.
; local_root=. The local root directory for saving rbsp data.
; remote_root=. The URL for grabing rbsp data.
; version=. Default is 'v01'.
;-

pro rbsp_efw_phasef_read_e_spinfit_edotb, time, probe=probe, pairs=pairs

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
    valid_range = rbsp_efw_phasef_get_valid_range('e_spinfit', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_e_spinfit_edotb_mgse_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','e_spinfit_edotb_'+version,rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','e_spinfit_edotb_'+version,rbspx,'%Y']
    if n_elements(pairs) eq 0 then pairs = ['12','34','13','14','23','24']

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
                'in_vars', rbspx+['_e_spinfit_mgse_edotb_v'+pairs,'_b_mgse_smoothed'], $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_read_e_spinfit_edotb_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    prefix = 'rbsp'+probe+'_'
    vars = prefix+'e_spinfit_mgse_edotb_v'+pairs
    foreach var, vars do begin
        if tnames(var) eq '' then continue
        add_setting, var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'mV/m', $
            'short_name', 'E', $
            'coord', 'MGSE', $
            'coord_labels', ['x','y','z'] )
    endforeach
end

stop
secofday = constant('secofday')
days = make_bins(time_double(['2012-09','2020']),secofday)
probes = ['a']
foreach probe, probes do begin
    foreach day, days do begin
        rbsp_efw_phasef_read_e_spinfit_edotb, day+[0,secofday], probe=probe
    endforeach
endforeach
stop

time_range = time_double(['2014-08-28','2014-08-29'])
;time_range = time_double(['2014','2015'])
probe= 'a'
rbsp_efw_phasef_read_e_spinfit_edotb, time_range, probe=probe
end
