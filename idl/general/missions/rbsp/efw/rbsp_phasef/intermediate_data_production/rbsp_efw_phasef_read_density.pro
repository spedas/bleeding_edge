;+
; Read the EFW density calibrated according to the upper-hybrid line.
; Applied density range and flags.
;
; time. The time range in unix time.
; probe=. 'a' or 'b'.
; boom_pairs=. The boom pair. Default is ['12','34','13','14','23','24'].
; dmin=. Minimum valid density. Default is 10 cc.
; dmax=. Maximum valid density. Default is 3000 cc.
; local_root=. The local root directory for saving rbsp data.
; remote_root=. The URL for grabing rbsp data.
; version=. Default is 'v02'. v02 fixed time tag offset.
;-

pro rbsp_efw_phasef_read_density, time, probe=probe, boom_pairs=boom_pairs, dmin=dmin, dmax=dmax, $
    version=version, local_root=local_root, remote_root=remote_root


    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v02'
    if n_elements(boom_pairs) eq 0 then boom_pairs = ['12','34','13','14','23','24']
    if n_elements(dmin) eq 0 then dmin = 10d
    if n_elements(dmax) eq 0 then dmax = 3000d


;---Init settings.
    valid_range = rbsp_efw_phasef_get_valid_range('density_uh', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_density_uh_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','density_uh_'+version,rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','density_uh_'+version,rbspx,'%Y']

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
                'in_vars', rbspx+['_density_'+boom_pairs], $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_phasef_read_density_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request


;---Apply flags.
    rbsp_efw_read_flags, time, probe=probe
    prefix = 'rbsp'+probe+'_'
    get_data, prefix+'density_'+boom_pairs[0], common_times
    flag_var = prefix+'efw_phasef_flags'
    interp_time, flag_var, common_times
    flags = get_var_data(flag_var)
    flag_names = get_setting(flag_var, 'labels')
    fillval = !values.f_nan
    foreach boom_pair, boom_pairs do begin
        var = prefix+'density_'+boom_pair
        density = get_var_data(var)
        foreach flag_type, ['charging','charging_extreme'] do begin
            index = where(flag_names eq flag_type+'_'+boom_pair, count)
            if count ne 0 then begin
                index = where(flags[*,index] eq 1, count)
                if count ne 0 then density[index] = fillval
            endif
        endforeach

        index = lazy_where(density, '][', [dmin,dmax], count=count)
        if count ne 0 then density[index] = fillval

        store_data, var, common_times, density, limits={ylog:1, ytitle:'(cm!U-3!N)', labels:'Density '+boom_pair}
    endforeach

end


time_range = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
rbsp_efw_phasef_read_density, time_range, probe=probe
end
