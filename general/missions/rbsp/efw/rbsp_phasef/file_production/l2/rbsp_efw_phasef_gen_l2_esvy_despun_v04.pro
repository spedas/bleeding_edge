;+
; Generate L2 esvy_despun v04 cdfs.
;
; v03 time tags are off by 1/32 sec. This is fixed in v04.
;
; Note the time tags are fixed at rbsp_efw_phasef_read_e_uvw---a lower
;   level program. Thus the codes for generating v04 data are the same as v03.
;-

pro rbsp_efw_phasef_gen_l2_esvy_despun_v04_skeleton, file

    if file_test(file) eq 0 then return

    base = file_basename(file)
    if strmid(base,0,4) ne 'rbsp' then return

    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    gatts = dictionary( $
        'Logical_source', prefix+'efw-l2_esvy_despun', $
        'Data_version', 'v04', $
        'MODS', '', $
        'Acknowledgement', "This work was supported by Van Allen Probes (RBSP) EFW funding provided by JHU/APL Contract No. 922613 under NASA's Prime Contract No. NNN06AA01C; EFW PI, J. R. Wygant, UMN.", $
        'Generation_date', time_string(systime(1),tformat='YYYY:MM:DDThh:mm:ss'), $
        'Logical_file_id', strmid(base,0,strlen(base)-4), $
        'Project', 'RBSP>Radiation Belt Storm Probes' )

    foreach key, gatts.keys() do begin
        cdf_save_setting, key, gatts[key], filename=file
    endforeach

    vars = ['epoch','epoch_e','epoch_hsk']
    var_notes = 'Epoch tagged at the center of each interval, resolution is '+['60','1/32','60']+' sec'
    foreach var, vars, var_id do begin
        cdf_save_setting, 'VAR_NOTES', var_notes[var_id], filename=file, varname=var
        cdf_save_setting, 'UNITS', 'ps (pico-second)', filename=file, varname=var
    endforeach

    ; Save label.
    label_var = 'efw_flags_labl'
    if tnames(label_var) eq '' then begin
        rbsp_efw_phasef_read_flag_20, time_double(['2012-10-01','2012-10-02']), probe=probe
        the_var = prefix+'flag_20'
        labels = get_setting(the_var, 'labels')
        store_data, label_var, 0, labels
    endif
    get_data, label_var, 0, labels
    cdf_save_data, label_var, value=labels, filename=file

end


pro rbsp_efw_phasef_gen_l2_esvy_despun_v04_per_day, date, probe=probe, filename=file, log_file=log_file

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
    data_type = 'esvy_despun'
    skeleton_base = prefix+'efw-l2_'+data_type+'_00000000_v04.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load data.
    routines = 'rbsp_efw_phasef_read_'+['esvy_despun','spinaxis_gse','pos_var','efw_qual','orb_num','hsk']
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, errmsg=errmsg, log_file=log_file
        if errmsg ne '' then return
    endforeach

;    ; hsk data starts from 2012-09-14, we need to manually fill in ibias for days before this day.
;    rbsp_efw_phasef_read_hsk, date, probe=probe, errmsg=errmsg
;    if errmsg ne '' then begin
;        secofday = 86400d
;        time_range = date+[0,secofday]
;        time_step = 60d
;        times = make_bins(time_range, time_step)
;        ntime = n_elements(times)
;        ndim = 6
;        fillval = -1e31
;        data = fltarr(ntime,ndim)+fillval
;        store_data, prefix+'ibias', times, data
;    endif


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
        'r_gse','v_gse','lshell','mlat','mlt']
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

    routines = 'rbsp_efw_phasef_save_'+['esvy_despun','spinaxis_gse','efw_qual','pos_var','orb_num','bias_current']+'_to_file'
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, filename=file
    endforeach
    cdf_del_unused_vars, file
    rbsp_efw_phasef_fix_cdf_metadata, file
    rbsp_efw_phasef_gen_l2_esvy_despun_v04_skeleton, file


end


pro rbsp_efw_phasef_gen_l2_esvy_despun_v04_fit_spdf_standard, probes=probes

    if n_elements(probes) eq 0 then probes = ['a','b']
    root_dir = join_path([rbsp_efw_phasef_local_root()])
    secofday = constant('secofday')
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        rbspx = 'rbsp'+probe

        log_file = join_path([root_dir,rbspx,'l2','esvy_despun_v04','rbsp_efw_phasef_gen_l2_esvy_despun_v04.log'])
        if file_test(log_file) eq 0 then ftouch, log_file

        time_range = rbsp_efw_phasef_get_valid_range('esvy_despun', probe=probe)
        days = make_bins(time_range+[0,-1]*secofday, constant('secofday'))
        foreach day, days do begin
            str_year = time_string(day,tformat='YYYY')
            path = join_path([root_dir,rbspx,'l2','esvy_despun_v04',str_year])
            base = prefix+'efw-l2_esvy_despun_'+time_string(day,tformat='YYYYMMDD')+'_v04.cdf'
            file = join_path([path,base])
            ; if file_test(file) eq 1 then continue
            print, file
            rbsp_efw_phasef_gen_l2_esvy_despun_v04_skeleton, file
        endforeach
    endforeach
end

rbsp_efw_phasef_gen_l2_esvy_despun_v04_fit_spdf_standard, probes=['a','b']
stop


probes = ['a']
root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    log_file = join_path([root_dir,rbspx,'l2','esvy_despun_v04','rbsp_efw_phasef_gen_l2_esvy_despun_v04.log'])
    if file_test(log_file) eq 0 then ftouch, log_file

    time_range = rbsp_efw_phasef_get_valid_range('esvy_despun', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l2','esvy_despun_v04',str_year])
        base = prefix+'efw-l2_esvy_despun_'+time_string(day,tformat='YYYYMMDD')+'_v04.cdf'
        file = join_path([path,base])
; if file_test(file) eq 1 then continue
        print, file
        rbsp_efw_phasef_gen_l2_esvy_despun_v04_per_day, day, probe=probe, filename=file, log_file=log_file
    endforeach
endforeach

stop




date = '2014-01-01'
probe = 'a'
file = join_path([homedir(),'test_esvy_despun_v04.cdf'])
rbsp_efw_phasef_gen_l2_esvy_despun_v04_per_day, date, probe=probe, filename=file
end
