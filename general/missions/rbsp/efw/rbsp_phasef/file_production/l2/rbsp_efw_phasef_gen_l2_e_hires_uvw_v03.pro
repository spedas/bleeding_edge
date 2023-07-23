;+
; Generate L2 e_hires_uvw v03 cdfs.
;   v02 time tag is off by 1/32 sec. This is corrected in v03.
;-

pro rbsp_efw_phasef_gen_l2_e_hires_uvw_v03_skeleton, file

    if file_test(file) eq 0 then return

    base = file_basename(file)
    if strmid(base,0,4) ne 'rbsp' then return

    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    gatts = dictionary( $
        'Logical_source', prefix+'efw-l2_e-hires-uvw', $
        'Data_version', 'v03', $
        'MODS', '', $
        'Acknowledgement', "This work was supported by Van Allen Probes (RBSP) EFW funding provided by JHU/APL Contract No. 922613 under NASA's Prime Contract No. NNN06AA01C; EFW PI, J. R. Wygant, UMN.", $
        'Generation_date', time_string(systime(1),tformat='YYYY:MM:DDThh:mm:ss'), $
        'Logical_file_id', strmid(base,0,strlen(base)-4), $
        'Project', 'RBSP>Radiation Belt Storm Probes' )

    foreach key, gatts.keys() do begin
        cdf_save_setting, key, gatts[key], filename=file
    endforeach

    vars = ['epoch','epoch_qual']
    var_notes = 'Epoch tagged at the center of each interval, resolution is '+['1/32','10']+' sec'
    foreach var, vars, var_id do begin
        cdf_save_setting, 'VAR_NOTES', var_notes[var_id], filename=file, varname=var
        cdf_save_setting, 'UNITS', 'ps (pico-second)', filename=file, varname=var
    endforeach

    ; Save label.
    label_var = 'efw_qual_labl'
    if tnames(label_var) eq '' then begin
        rbsp_efw_phasef_read_flag_20, time_double(['2012-10-01','2012-10-02']), probe=probe
        the_var = prefix+'flag_20'
        labels = get_setting(the_var, 'labels')
        store_data, label_var, 0, labels
    endif
    get_data, label_var, 0, labels
    cdf_save_data, label_var, value=labels, filename=file

end


pro rbsp_efw_phasef_gen_l2_e_hires_uvw_v03_per_day, date, probe=probe, filename=file, log_file=log_file

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
    data_type = 'e-hires-uvw'
    skeleton_base = prefix+'efw-l2_'+data_type+'_00000000_v03.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load data.
    routines = 'rbsp_efw_phasef_read_'+['e_hires_uvw','efw_qual','spinaxis_gse','boom_property']
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, errmsg=errmsg, log_file=log_file
        if errmsg ne '' then return
    endforeach


;---Do something.
    ; Apply global flag to e_uvw and remove ew.
    flag_var = prefix+'efw_qual'
    get_data, flag_var, flag_times, flags
    e_var = prefix+'efw_esvy_no_offset'
    get_data, e_var, common_times, e_uvw
    fillval = -1e31
    flags = interpol(flags[*,0], flag_times, common_times)
    index = where(flags ne 0, count)
    if count ne 0 then e_uvw[index,*] = fillval
    e_uvw[*,2] = fillval
    store_data, e_var, common_times, e_uvw


    interp_time, prefix+'spinaxis_gse', flag_times


;---Save to file.
    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    file_copy, skeleton, file, /overwrite

    routines = 'rbsp_efw_phasef_save_'+['e_hires_uvw','efw_qual_hires','l_vector','boom_property']+'_to_file'
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, filename=file
    endforeach
    cdf_del_unused_vars, file
    rbsp_efw_phasef_fix_cdf_metadata, file
    rbsp_efw_phasef_gen_l2_e_hires_uvw_v03_skeleton, file

end


;---Change the labeling.
pro rbsp_efw_phasef_gen_l2_e_hires_uvw_v03_fit_spdf_standard, probes=probes

    if n_elements(probes) eq 0 then probes = ['a','b']
    root_dir = join_path([rbsp_efw_phasef_local_root()])
    secofday = constant('secofday')
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        rbspx = 'rbsp'+probe

        log_file = join_path([root_dir,rbspx,'l2','e-hires-uvw_v03','rbsp_efw_phasef_gen_l2_e_hires_uvw_v03.log'])
        if file_test(log_file) eq 0 then ftouch, log_file

        time_range = rbsp_efw_phasef_get_valid_range('e_hires_uvw', probe=probe)
        days = make_bins(time_range+[0,-1]*secofday, secofday)
        foreach day, days do begin
            str_year = time_string(day,tformat='YYYY')
            path = join_path([root_dir,rbspx,'l2','e-hires-uvw_v03',str_year])
            base = prefix+'efw-l2_e-hires-uvw_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
            file = join_path([path,base])
            print, file
            rbsp_efw_phasef_gen_l2_e_hires_uvw_v03_skeleton, file
        endforeach
    endforeach
end




    probes = ['a','b']
    root_dir = join_path([rbsp_efw_phasef_local_root()])
    secofday = constant('secofday')
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        rbspx = 'rbsp'+probe

        time_range = rbsp_efw_phasef_get_valid_range('e_hires_uvw', probe=probe)
        days = make_bins(time_range+[0,-1]*secofday, secofday)
        foreach day, days do begin
            str_year = time_string(day,tformat='YYYY')
            path = join_path([root_dir,rbspx,'l2','e-hires-uvw_v03',str_year])
            base_new = prefix+'efw-l2_e-hires-uvw_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
            file_new = join_path([path,base_new])
            base_old = prefix+'efw-l2_e-hires_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
            file_old = join_path([path,base_old])
            print, file_old
            if file_test(file_old) eq 0 then continue
            file_move, file_old, file_new, /overwrite
        endforeach
    endforeach



stop
probes = ['a','b']
root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    log_file = join_path([root_dir,rbspx,'l2','e-hires-uvw_v03','rbsp_efw_phasef_gen_l2_e_hires_uvw_v03.log'])
    if file_test(log_file) eq 0 then ftouch, log_file

    time_range = rbsp_efw_phasef_get_valid_range('e_hires_uvw', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l2','e-hires-uvw_v03',str_year])
        base = prefix+'efw-l2_e-hires-uvw_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
        file = join_path([path,base])
if file_test(file) eq 1 then continue
        print, file
        rbsp_efw_phasef_gen_l2_e_hires_uvw_v03_per_day, day, probe=probe, filename=file, log_file=log_file
    endforeach
endforeach

stop


; Last day.
date = '2012-10-14'
probe = 'a'
file = join_path([homedir(),'test_e_hires_uvw_v03.cdf'])
rbsp_efw_phasef_gen_l2_e_hires_uvw_v03_per_day, date, probe=probe, filename=file
end
