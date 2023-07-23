;+
; Generate L2 esvy_despun v03 cdfs.
;   v01 and v02 files are not in the same format. v03 cdfs will be in the same format.
;-

pro phasef_gen_l2_esvy_despun_v03_per_day, date, probe=probe, filename=file, log_file=log_file

    errmsg = ''

    msg = 'Processing '+file+' ...'
    lprmsg, msg, log_file

;---Check input.
    if n_elements(file) eq 0 then begin
        errmsg = 'cdf file is not set ...'
        lprmsg, errmsg, log_file
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = 'No input probe ...'
        lprmsg, errmsg, log_file
        return
    endif
    if probe ne 'a' and probe ne 'b' then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        lprmsg, errmsg, log_file
        return
    endif
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    data_type = 'esvy_despun'
    valid_range = phasef_get_valid_range(data_type, probe=probe)
    if n_elements(date) eq 0 then begin
        errmsg = 'No input date ...'
        lprmsg, errmsg, log_file
        return
    endif
    if size(date,/type) eq 7 then date = time_double(date)
    if product(date-valid_range) gt 0 then begin
        errmsg = 'Input date: '+time_string(date,tformat='YYYY-MM-DD')+' is out of valid range ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Prepare skeleton.
    data_type = 'esvy_despun'
    skeleton_base = prefix+'efw-l2_'+data_type+'_00000000_v03.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load data.
    routines = 'phasef_read_'+['esvy_despun','spinaxis_gse','pos_var','efw_qual','orbit_num']
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, errmsg=errmsg, log_file=log_file
        if errmsg ne '' then return
    endforeach

    phasef_read_efw_hsk, date, probe=probe, errmsg=errmsg
    if errmsg ne '' then begin
        secofday = 86400d
        time_range = date+[0,secofday]
        time_step = 60d
        times = make_bins(time_range, time_step)
        ntime = n_elements(times)
        ndim = 6
        fillval = -1e31
        data = fltarr(ntime,ndim)+fillval
        store_data, prefix+'ibias', times, data
    endif


;---Do something.
    ; Apply global flag to e_uvw and remove ew.
    flag_var = prefix+'efw_qual'
    get_data, flag_var, times, flags
    e_var = prefix+'esvy_mgse'
    get_data, e_var, common_times, e_mgse
    fillval = -1e31
    flags = interpol(flags[*,0], times, common_times)
    index = where(flags ne 0, count)
    if count ne 0 then e_mgse[index,*] = fillval
    e_mgse[*,0] = fillval
    store_data, e_var, common_times, e_mgse

    ; vars depend on epoch.
    vars = ['orbit_num', 'vel_gse', 'pos_gse', 'lshell', 'mlat', 'mlt', $
        'efw_qual', 'bias_current', 'spinaxis_gse']
    vars = prefix+['orbit_num', 'spinaxis_gse', 'efw_qual', 'ibias', $
        'state_'+['vel_gse','pos_gse','lshell','mlat','mlt']]
    time_step = 60.
    secofday = 86400d
    time_range = date+[0,secofday]
    common_times = make_bins(time_range, time_step)
    foreach var, vars do interp_time, var, common_times

    orbit_num_var = prefix+'orbit_num'
    get_data, orbit_num_var, times, data
    data = round(data)
    store_data, orbit_num_var, times, data


;---Save to file.
    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    file_copy, skeleton, file, /overwrite

    old_vars = ['flags_all','position_gse','velocity_gse']
    new_vars = ['efw_qual','pos_gse','vel_gse']
    foreach old_var, old_vars, var_id do begin
        new_var = new_vars[var_id]
        cdf_rename_var, old_var, to=new_var, filename=file
    endforeach

    routines = 'phasef_save_'+['esvy_despun','spinaxis_gse','efw_qual','pos_var','orbit_num','bias_current']+'_to_file'
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, filename=file
    endforeach
    cdf_del_unused_vars, file


end


probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
root_dir = join_path([homedir(),'data','rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    log_file = join_path([root_dir,rbspx,'l2','esvy_despun','phasef_gen_l2_esvy_despun_v03.log'])
    if file_test(log_file) eq 0 then ftouch, log_file

    time_range = (probe eq 'a')? time_double(['2012-09-13','2019-02-22']): time_double(['2012-09-13','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l2','esvy_despun',str_year])
        base = prefix+'efw-l2_esvy_despun_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
        file = join_path([path,base])
        if file_test(file) eq 1 then continue
        phasef_gen_l2_esvy_despun_v03_per_day, day, probe=probe, filename=file, log_file=log_file
    endforeach
endforeach

stop




date = '2014-01-01'
probe = 'a'
file = join_path([homedir(),'test_esvy_despun_v03.cdf'])
phasef_gen_l2_esvy_despun_v03_per_day, date, probe=probe, filename=file
end
