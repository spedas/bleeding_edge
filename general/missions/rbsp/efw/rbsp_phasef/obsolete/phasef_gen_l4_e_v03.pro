;+
; Make some minor changes to v02 files.
;-

pro phasef_gen_l4_e_v03_per_day, date, $
    probe=probe, filename=file, log_file=log_file

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

    data_type = 'e_spinfit'
    valid_range = rbsp_efw_phasef_get_valid_range(data_type, probe=probe)
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
    secofday = 86400d
    time_range = date+[0,secofday]
    rbsp_efw_read_l4, time_range, probe=probe, files=old_file, get_file=1, version='v02'
    old_file = old_file[0]

    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    if old_file eq file then message, 'Output file cannot be the same as input ...'
    file_copy, old_file, file, /overwrite


;---Do something.
    vars = ['bfield_mgse']
    foreach var, vars do begin
        if cdf_has_var(var, filename=file) then begin
            cdf_del_var, var, filename=file
        endif
    endforeach
    cdf_del_unused_vars, file


;---Save data.
    ; Already done.

end

probes = ['a','b']
root_dir = join_path([homedir(),'data','rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = (probe eq 'a')? time_double(['2012-09-13','2019-02-23']): time_double(['2012-09-13','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'level4',str_year])
        base = prefix+'efw-l4_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
        file = join_path([path,base])
        if file_test(file) eq 1 then continue
        phasef_gen_l4_e_v03_per_day, day, probe=probe, filename=file
    endforeach
endforeach

stop


date = time_double('2015-05-28')
probe = 'a'
file = join_path([homedir(),'test_level4.cdf'])
phasef_gen_l4_e_v03_per_day, date, probe=probe, file=file
end
