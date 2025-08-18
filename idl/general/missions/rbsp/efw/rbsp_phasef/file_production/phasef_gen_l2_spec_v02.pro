;+
; Generate L2 spec v02 cdfs.
;   v01 files are not in the same format. v02 cdfs will be in the same format.
;-

pro phasef_gen_l2_spec_v02_per_day, date, probe=probe, filename=file, log_file=log_file

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

    data_type = 'spec'
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

;---Load data.
    str_year = time_string(date,tformat='YYYY')
    l1_path = join_path([homedir(),'data','rbsp',rbspx,'spec',str_year])
    l1_file = join_path([l1_path,prefix+'efw-l2_spec_'+time_string(date,tformat='YYYYMMDD')+'_v01.cdf'])
    if file_test(l1_file) eq 0 then begin
        lprmsg, 'L1 file does not exist ...', log_file
        return
    endif

    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    file_copy, l1_file, file
    cdf_del_unused_vars, file

end

;stop
probes = ['a','b']
root_dir = join_path([homedir(),'data','rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = phasef_get_valid_range('spec', probe=probe)
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'level2','spec',str_year])
        base = prefix+'efw-l2_spec_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
        if file_test(file) eq 1 then continue
        phasef_gen_l2_spec_v02_per_day, day, probe=probe, filename=file
    endforeach
endforeach
stop

date = time_double('2015-05-28')
probe = 'b'
file = join_path([homedir(),'test_level2_spec.cdf'])
phasef_gen_l2_spec_v02_per_day, date, probe=probe, file=file
end
