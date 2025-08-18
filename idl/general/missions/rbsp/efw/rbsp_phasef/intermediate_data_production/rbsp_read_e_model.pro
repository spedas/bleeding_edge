;+
; Read E model = E_coro + E_vxb.
; 
; id=. Can be e_model, e_model_related.
;-

pro rbsp_read_e_model, time, probe=probe, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v02'
    coord = 'mgse'
    if n_elements(datatype) eq 0 then datatype = 'e_model'

;---Init settings.
    type_dispatch = hash()
    valid_range = rbsp_efw_phasef_get_valid_range('e_model', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_e_model_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','e_model_'+version,rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','e_model_'+version,rbspx,'%Y']
    ; E model only.
    type_dispatch['e_model'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_emod_'+coord, $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))
    ; E model, E_coro and E_vxb.
    type_dispatch['e_model_related'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_'+['emod','evxb','ecoro','vcoro']+'_'+coord, $
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
            rbsp_read_e_model_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request



;    ; Remove overlapping times.
;    foreach var_list, request.var_list do begin
;        out_vars = var_list.out_vars
;        if n_elements(out_vars) eq 0 then out_vars = var_list.in_vars
;        foreach var, out_vars do begin
;            get_data, var, times, data
;            index = uniq(times, sort(times))
;            store_data, var, times[index], data[index,*]
;        endforeach
;    endforeach


    out_vars = list()
    foreach var_list, request.var_list do begin
        vars = (var_list.haskey('out_vars'))? var_list.out_vars: var_list.in_vars
        out_vars.add, vars, /extract
    endforeach

    xyz = constant('xyz')
    prefix = 'rbsp'+probe+'_'
    foreach var, out_vars do begin

        case var of
            prefix+'vcoro_mgse': unit = 'km/s'
            else: unit = 'mV/m'
        endcase

        case var of
            prefix+'vcoro_mgse': short_name = 'Coro V'
            prefix+'ecoro_mgse': short_name = 'Coro E'
            prefix+'evxb_mgse': short_name = 'VxB E'
            prefix+'emod_mgse': short_name = 'Model E'
        endcase

        add_setting, var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', short_name, $
            'unit', unit, $
            'coord', 'MGSE', $
            'coord_labels', xyz )
    endforeach

    ; This is treated at a lower level.
;    fillval = !values.f_nan
;    mask_list = list()
;    mask_list.add, dictionary($
;        'probe', 'b', $
;        'time_range', time_double(['2018-09-27/04:00','2018-09-27/14:00']) )
;    foreach info, mask_list do begin
;        if info.probe ne probe then continue
;        foreach var, vars do begin
;            get_data, var, times, data
;            index = lazy_where(times, '[]', info.time_range, count=count)
;            if count eq 0 then continue
;            times[index] = fillval
;            store_data, var, times, data
;        endforeach
;    endforeach

end


stop

secofday = constant('secofday')
foreach probe, ['b'] do begin
    time_range = rbsp_efw_phasef_get_valid_range('e_model', probe=probe)
    time_range = time_double(['2012-09-05','2013'])
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    foreach day, days do begin
        tr = day+[0,secofday]
        rbsp_read_e_model, tr, probe=probe
    endforeach
endforeach
stop




;probe = 'b'
;time_range = time_double(['2013-09-01','2015-01-01'])
;time_range = time_double(['2015-01-01','2017-01-01'])
;time_range = time_double(['2017-01-01','2019-11-01'])
;rbsp_read_e_model, probe=probe, time_range


;time_range = time_double(['2018-04-28','2018-04-30'])
time_range = time_double(['2018-09-20','2018-09-30'])
time_range = time_double(['2013-01-01','2017-01-01'])
time_range = time_double(['2018-08-20','2018-09-01'])
time_range = time_double(['2015-12-19','2015-12-20'])
probe = 'b'
rbsp_read_e_model, time_range, probe=probe
rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe

prefix = 'rbsp'+probe+'_'
emod_mgse = get_var_data(prefix+'emod_mgse', times=times)
e_mgse = get_var_data(prefix+'e_mgse', at=times, limits=lim)
de_mgse = e_mgse-emod_mgse

; Remove spin-axis data.
de_mgse[*,0] = !values.f_nan

; Remove apogee data.
dis = snorm(get_var_data(prefix+'r_mgse', at=times))
index = where(dis ge 3)
de_mgse[index,*] = !values.f_nan

;; Remove other invalid data.
;rbsp_efw_read_boom_flag, time_range, probe=probe
;flags = total(get_var_data(prefix+'boom_flag', times=uts),2)
;index = where(flags ne 4, count)
;if count ne 0 then begin
;    bad_time_ranges = uts[time_to_range(index,time_step=1)]
;    nbad_time_range = n_elements(bad_time_ranges)*0.5
;    for ii=0,nbad_time_range-1 do begin
;        index = lazy_where(times, '[]', bad_time_ranges[ii,*]+[-1,1]*600, count=count)
;        if count eq 0 then continue
;        de_mgse[index,*] = !values.f_nan
;    endfor
;endif

store_data, prefix+'de_mgse', times, de_mgse, limits=lim


end
