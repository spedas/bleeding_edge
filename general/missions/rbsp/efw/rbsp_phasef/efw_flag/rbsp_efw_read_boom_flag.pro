;+
; Read RBSP boom flag, where 1 is for working boom.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; probe=. A string set the probe to read data for.
; local_root=. A string to set the local root directory.
; remote_root=. A string to set the remote root directory.
; version=. A string to set specific version of files. By default, the
;   program finds the files of the highest version.
;-

pro rbsp_efw_read_boom_flag, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('no probe ...')
        return
    endif
    index = where(probe eq ['a','b'])
    if index[0] eq -1 then begin
        errmsg = handle_error('invalid probe ...')
        return
    endif
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v01'

;---Init settings.
    type_dispatch = hash()
    valid_range = rbsp_efw_phasef_get_valid_range('flags_all', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_boom_flag_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_flag','boom_flag',rbspx,'%Y']
    remote_path = [remote_root,'efw_flag','boom_flag',rbspx,'%Y']


    type_dispatch['all'] = dictionary($
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
                'in_vars', ['boom_flag','vsc_median'], $
                'out_vars', rbspx+'_'+['boom_flag','vsc_median'], $
                'time_var_name', 'ut_flag', $
                'time_var_type', 'unix')))

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return
    endif

;---Dispatch patterns.
    datatype = 'all'
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_efw_read_boom_flag_gen_file, file_time, probe=probe, filename=local_file, local_root=local_root
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    prefix = 'rbsp'+probe+'_'
    var = prefix+'boom_flag'
    add_setting, var, /smart, dictionary($
        'display_type', 'stack', $
        'yrange', [-0.2,1.2], $
        'labels', 'V'+['1','2','3','4'] )

end

time_range = time_double(['2013-09-25','2013-09-26'])
probe = 'a'
file = join_path([homedir(),'test_flag.cdf'])

rbsp_efw_read_boom_flag, time_range, probe=probe
stop

;probe = 'a'
;date = time_double('2014-06-19')    ; Vsvy miss data on that day.
;
;probe = 'b'
;date = time_double('2013-01-27')    ; Flag on at the beginning of the day.
;date = time_double('2014-01-09')    ; Small data gaps.
;date = time_double('2014-08-27')    ; Charging.
;date = time_double('2014-08-29')    ; Flag on in a small chunck.
;
;data_file = join_path([homedir(),'test.cdf'])
;rbsp_efw_read_boom_flag_gen_file, date, probe=probe, filename=data_file
;stop


; Run through the whole mission.
stop
secofday = constant('secofday')
foreach probe, ['a','b'] do begin
    valid_time_range = rbsp_info('efw_l2_data_range', probe=probe)
    valid_time_range = time_double(['2016-02-27','2016-02-29'])
    dates = make_bins(valid_time_range, secofday)
    foreach date, dates do begin
        date_time_range = date+[0,secofday]
        rbsp_efw_read_boom_flag, date_time_range, probe=probe
    endforeach
endforeach
end
