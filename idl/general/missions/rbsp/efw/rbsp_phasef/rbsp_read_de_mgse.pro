;+
; Read dE = E_mgse - Emod_mgse
;-

pro rbsp_read_de_mgse, time, probe=probe, datatype=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','rbsp'])
    if n_elements(version) eq 0 then version = 'v01'
    if n_elements(datatype) eq 0 then datatype = 'de_mgse'


;---Init settings.
    type_dispatch = hash()
    valid_range = rbsp_info('spice_data_range', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_de_mgse_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'de_mgse','%Y']

    type_dispatch['de_mgse'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_de_mgse', $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))

    type_dispatch['de_related'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_'+[['de','e','emod']+'_mgse','dis'], $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))


    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    request = type_dispatch[datatype]


;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_read_de_mgse_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request


end

probe = 'b'
time_range = time_double(['2012-09-08','2016-01-01'])
time_range = time_double(['2016-01-01','2019-11-01'])

rbsp_read_de_mgse, time_range, probe=probe, datatype='de_related'
prefix = 'rbsp'+probe+'_'
dis = get_var_data(prefix+'dis')
index = where(dis ge 2, count)
if count ne 0 then begin
    de_mgse = get_var_data(prefix+'de_mgse', times=times)
    de_mgse[index,*] = !values.f_nan
    store_data, prefix+'de_mgse', times, de_mgse
endif

rbsp_efw_read_boom_flag, time_range, probe=probe
flags = total(get_var_data(prefix+'boom_flag', times=uts),2)
index = where(flags ne 4, count)
if count ne 0 then begin
    bad_time_ranges = uts[time_to_range(index,time_step=1)]
    nbad_time_range = n_elements(bad_time_ranges)*0.5
    for ii=0,nbad_time_range-1 do begin
        index = lazy_where(times, '[]', bad_time_ranges[ii,*]+[-1,1]*300, count=count)
        if count eq 0 then continue
        de_mgse[index,*] = !values.f_nan
    endfor
    store_data, prefix+'de_mgse', times, de_mgse
endif



;foreach probe, ['a','b'] do begin
;    full_time_range = rbsp_info('efw_phasef', probe=probe)
;    times = make_bins(full_time_range, 86400d)
;    nday = n_elements(times)-1
;    for ii=0,nday-1 do begin
;        time_range = times[ii:ii+1]
;        rbsp_read_de_mgse, time_range, probe=probe
;    endfor
;endforeach
end
