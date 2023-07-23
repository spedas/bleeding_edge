;+
; Generate L2 e_hires_uvw v02 cdfs.
;   v01 files are not in the same format. v02 cdfs will be in the same format.
;-

pro phasef_gen_l2_e_hires_uvw_v02_per_day, date, probe=probe, filename=file, log_file=log_file

    on_error, 0
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

    data_type = 'e_hires_uvw'
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
    data_type = 'e-hires-uvw'
    skeleton_base = prefix+'efw-l2_'+data_type+'_00000000_v02.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load data.
    routines = 'phasef_read_'+['e_hires_uvw','efw_qual','spinaxis_gse','boom_property']
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, errmsg=errmsg, log_file=log_file
        if errmsg ne '' then return
    endforeach


;---Do something.
    ; Apply global flag to e_uvw and remove ew.
    flag_var = prefix+'efw_qual'
    get_data, flag_var, times, flags
    e_var = prefix+'efw_esvy_no_offset'
    get_data, e_var, common_times, e_uvw
    fillval = -1e31
    flags = interpol(flags[*,0], times, common_times)
    index = where(flags ne 0, count)
    if count ne 0 then e_uvw[index,*] = fillval
    e_uvw[*,2] = fillval
    store_data, e_var, common_times, e_uvw

    time_step = 5d
    secofday = 86400d
    time_range = date+[0,secofday]
    common_times = make_bins(time_range+[0,-1]*time_step, time_step)
    interp_time, prefix+'spinaxis_gse', common_times


;---Save to file.
    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    file_copy, skeleton, file, /overwrite

    routines = 'phasef_save_'+['e_hires_uvw','e_hires_uvw_hsk','efw_qual_hires','l_vector','boom_property']+'_to_file'
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, filename=file
    endforeach
    cdf_del_unused_vars, file

end


probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    log_file = join_path([root_dir,rbspx,'l2','e-hires-uvw','phasef_gen_l2_e_hires_uvw_v02.log'])
    if file_test(log_file) eq 0 then ftouch, log_file

    time_range = (probe eq 'a')? time_double(['2012-09-13','2019-10-13']): time_double(['2012-09-13','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l2','e-hires-uvw',str_year])
        base = prefix+'efw-l2_e-hires-uvw_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
        if file_test(file) eq 1 then continue
        phasef_gen_l2_e_hires_uvw_v02_per_day, day, probe=probe, filename=file, log_file=log_file
    endforeach
endforeach

stop


date = '2014-01-01'
probe = 'a'
file = join_path([homedir(),'test_e_hires_uvw_v02.cdf'])
phasef_gen_l2_e_hires_uvw_v02_per_day, date, probe=probe, filename=file
end
