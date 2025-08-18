;+
; Read spinfit E MGSE.
;
; time. The time range in unix time.
; probe=. 'a' or 'b'.
; local_root=. The local root directory for saving rbsp data.
; remote_root=. The URL for grabing rbsp data.
; version=. Default is 'v03'.
;
; v03 uses the E field with fixed time tag offset.
;-

pro rbsp_efw_phasef_read_e_spinfit, time, probe=probe, $
    version=version, local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v03'

;---Init settings.
    valid_range = rbsp_efw_phasef_get_valid_range('e_spinfit', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_e_spinfit_mgse_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','e_spinfit_'+version,rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','e_spinfit_'+version,rbspx,'%Y']

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
                'in_vars', rbspx+'_e_spinfit_mgse_v'+['12','34'], $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))



;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_read_e_spinfit_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    fillval = !values.f_nan
    foreach var, 'rbsp'+probe+'_e_spinfit_mgse_v'+['12','34'] do begin
        get_data, var, times, data
        index = where(abs(data) ge 500, count)
        if count ne 0 then begin
            data[index] = fillval
            store_data, var, times, data
        endif

        add_setting, var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', 'E', $
            'unit', 'mV/m', $
            'coord', 'MGSE', $
            'coord_labels', constant('xyz') )
    endforeach

end

secofday = constant('secofday')
days = make_bins(time_double(['2012-09','2020']),secofday)
probes = ['b']
foreach probe, probes do begin
    foreach day, days do begin
        rbsp_efw_phasef_read_e_spinfit, day+[0,secofday], probe=probe
    endforeach
endforeach

stop


time_range = time_double(['2013-01-01','2013-01-02'])
;time_range = time_double(['2013-12-01','2014-02-01'])
;time_range = time_double(['2014-01-01','2014-02-01'])
rbsp_efw_phasef_read_e_spinfit, time_range, probe='a'
end





;    root_dir = '/Volumes/Research/sdata/rbsp/long_term_l3'
;    prefix = 'rbsp'+probe+'_'
;    files = file_search(join_path([root_dir,prefix+'*.cdf']))
;
;    request = dictionary($
;        'var_list', list($
;            dictionary($
;                'in_vars', ['efield_in_corotation_frame_spinfit_mgse'], $
;                'out_vars', prefix+['e_mgse'], $
;                'time_var_name', 'epoch', $
;                'time_var_type', 'epoch16')))
;
;
;;---Read data from files and save to memory.
;    read_files, time_range, files=files, request=request
;
;    the_var = prefix+'e_mgse'
;    add_setting, the_var, /smart, dictionary($
;        'display_type', 'vector', $
;        'short_name', 'E', $
;        'unit', 'mV/m', $
;        'coord', 'MGSE', $
;        'coord_labels', ['x','y','z'] )
