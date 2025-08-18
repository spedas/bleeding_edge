;+
; Generate L2 vsvy_hires v04 cdfs.
;   v03 time tags are off by 1/32 sec. This is fixed in v04.
;   v03 -A uses -B's skeleton. This is fixed in v04.
;
; Note the time tags are fixed at rbsp_efw_phasef_read_vsvy---a lower
;   level program. Thus the codes for generating v04 data are the same as v03.
;-

pro rbsp_efw_phasef_gen_l2_vsvy_hires_v04_skeleton, file

    if file_test(file) eq 0 then return

    base = file_basename(file)
    if strmid(base,0,4) ne 'rbsp' then return

    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    gatts = dictionary( $
        'Logical_source', prefix+'efw-l2_vsvy-hires', $
        'Data_version', 'v04', $
        'Data_type', 'vsvy-hires', $
        'Logical_source_description', 'Single-ended potential values for boom 1-6', $
        'Generation_date', time_string(systime(1),tformat='YYYY:MM:DDThh:mm:ss'), $
        'Logical_file_id', strmid(base,0,strlen(base)-4), $
        'MODS', '', $
        'Acknowledgement', "This work was supported by Van Allen Probes (RBSP) EFW funding provided by JHU/APL Contract No. 922613 under NASA's Prime Contract No. NNN06AA01C; EFW PI, J. R. Wygant, UMN.", $
        'Project', 'RBSP>Radiation Belt Storm Probes' )

    foreach key, gatts.keys() do begin
        cdf_save_setting, key, gatts[key], filename=file
    endforeach

    keys = []
    foreach key, keys do cdf_del_setting, key, filename=file


    vars = ['epoch','epoch_v']
    var_notes = 'Epoch tagged at the center of each interval, resolution is '+['1','1/16']+' sec'
    foreach var, vars, var_id do begin
        cdf_save_setting, 'VAR_NOTES', var_notes[var_id], filename=file, varname=var
        cdf_save_setting, 'UNITS', 'ps (pico-second)', filename=file, varname=var
    endforeach

    cdf_save_setting, dictionary('LABLAXIS','Vsvy_LABL_1'), $
        varname='Vsvy_LABL_1', filename=file

end

pro rbsp_efw_phasef_gen_l2_vsvy_hires_v04_per_day, date, probe=probe, filename=file, log_file=log_file


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
    skeleton_base = prefix+'efw-l2_'+data_type+'_00000000_v04.cdf'
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

    
;---Wrap up.
    cdf_del_unused_vars, file
    rbsp_efw_phasef_fix_cdf_metadata, file
    rbsp_efw_phasef_gen_l2_vsvy_hires_v04_skeleton, file

end


;---Change the labeling.
pro rbsp_efw_phasef_gen_l2_vsvy_hires_v04_fit_spdf_standard, probes=probes
    if n_elements(probes) eq 0 then probes = ['a','b']
    root_dir = join_path([rbsp_efw_phasef_local_root()])
    secofday = constant('secofday')
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        rbspx = 'rbsp'+probe

        time_range = rbsp_efw_phasef_get_valid_range('vsvy_hires', probe=probe)
        days = make_bins(time_range+[0,-1]*secofday, secofday)
        foreach day, days do begin
            str_year = time_string(day,tformat='YYYY')
            path = join_path([root_dir,rbspx,'l2','vsvy-hires_v04',str_year])
            base = prefix+'efw-l2_vsvy-hires_'+time_string(day,tformat='YYYYMMDD')+'_v04.cdf'
            file = join_path([path,base])
    ;if file_test(file) eq 1 then continue
            print, file
            rbsp_efw_phasef_gen_l2_vsvy_hires_v04_skeleton, file

;            test_file = join_path([homedir(),file_basename(file)])
;            file_copy, file, test_file
;            rbsp_efw_phasef_gen_l2_vsvy_hires_v04_skeleton, test_file
;            stop
        endforeach
    endforeach
end

rbsp_efw_phasef_gen_l2_vsvy_hires_v04_fit_spdf_standard, probes=['a','b']
stop


;---Generate the files.
    probes = ['b']
    root_dir = join_path([rbsp_efw_phasef_local_root()])
    secofday = constant('secofday')
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        rbspx = 'rbsp'+probe

        log_file = join_path([root_dir,rbspx,'l2','vsvy-hires_v04','rbsp_efw_phasef_gen_l2_vsvy_hires_v04.log'])
        if file_test(log_file) eq 0 then ftouch, log_file

        time_range = rbsp_efw_phasef_get_valid_range('vsvy_hires', probe=probe)
        days = make_bins(time_range+[0,-1]*secofday, secofday)
        foreach day, days do begin
            str_year = time_string(day,tformat='YYYY')
            path = join_path([root_dir,rbspx,'l2','vsvy-hires_v04',str_year])
            base = prefix+'efw-l2_vsvy-hires_'+time_string(day,tformat='YYYYMMDD')+'_v04.cdf'
            file = join_path([path,base])
    ;if file_test(file) eq 1 then continue
            print, file
            rbsp_efw_phasef_gen_l2_vsvy_hires_v04_per_day, day, probe=probe, filename=file, log_file=log_file
        endforeach
    endforeach

stop



date = '2014-01-01'
probe = 'a'
file = join_path([homedir(),'test_vsvy_v04.cdf'])
rbsp_efw_phasef_gen_l2_vsvy_hires_v04_per_day, date, probe=probe, filename=file
end
