;+
; Generate L2 vsvy_hires v03 cdfs.
;   v03 files will be in the same format.
;   v03 uses the spice orbit_num (v02 uses ect orbit_num, which is sometimes wrong)
;-

pro rbsp_efw_phasef_gen_l2_vsvy_hires_v03_per_day, date, probe=probe, filename=file, log_file=log_file


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

    data_type = 'vsvy_hires'
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


;---Prepare skeleton.
    data_type = 'vsvy_hires'
    skeleton_base = prefix+'efw-l2_'+data_type+'_00000000_v03.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load data.
    routines = 'rbsp_efw_phasef_read_'+['vsvy_l2','pos_var','orb_num']
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, errmsg=errmsg, log_file=log_file
        if errmsg ne '' then return
    endforeach


;---Do something.
    ; Interpolate pos_var and orbit_num to the same time tags.
    var1 = prefix+'r_gse'
    var2 = prefix+'orbit_num'
    get_data, var1, common_times
    interp_time, var2, common_times


;---Save to file.
    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    file_copy, skeleton, file, /overwrite

    routines = 'rbsp_efw_phasef_save_'+['vsvy_l2','pos_var','orb_num']+'_to_file'
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, filename=file
    endforeach
    cdf_del_unused_vars, file

end




stop
probes = ['a','b']
root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    log_file = join_path([root_dir,rbspx,'l2','vsvy-hires','rbsp_efw_phasef_gen_l2_vsvy_hires_v03.log'])
    if file_test(log_file) eq 0 then ftouch, log_file

    time_range = rbsp_efw_phasef_get_valid_range('vsvy_hires', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l2','vsvy-hires',str_year])
        base = prefix+'efw-l2_vsvy-hires-uvw_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
        file = join_path([path,base])
;if file_test(file) eq 1 then continue
        print, file
        rbsp_efw_phasef_gen_l2_vsvy_hires_v03_per_day, day, probe=probe, filename=file, log_file=log_file
    endforeach
endforeach

stop



date = '2014-01-01'
probe = 'a'
file = join_path([homedir(),'test_vsvy_v03.cdf'])
rbsp_efw_phasef_gen_l2_vsvy_hires_v03_per_day, date, probe=probe, filename=file
end
