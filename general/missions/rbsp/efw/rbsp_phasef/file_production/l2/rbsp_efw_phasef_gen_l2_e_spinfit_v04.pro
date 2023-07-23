;+
; Generate L2 e_spinfit v04 cdfs.
; v04 removes orbit_num, use new efw_qual, from E uvw with corrected time tags.
;-

pro rbsp_efw_phasef_gen_l2_e_spinfit_v04_skeleton, file

    if file_test(file) eq 0 then return

    base = file_basename(file)
    if strmid(base,0,4) ne 'rbsp' then return

    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    gatts = dictionary( $
        'Logical_source', prefix+'efw-l2_e-spinfit-mgse', $
        'Data_version', 'v04', $
        'MODS', '', $
        'Acknowledgement', "This work was supported by Van Allen Probes (RBSP) EFW funding provided by JHU/APL Contract No. 922613 under NASA's Prime Contract No. NNN06AA01C; EFW PI, J. R. Wygant, UMN.", $
        'Generation_date', time_string(systime(1),tformat='YYYY:MM:DDThh:mm:ss'), $
        'Logical_file_id', strmid(base,0,strlen(base)-4), $
        'Project', 'RBSP>Radiation Belt Storm Probes' )

    foreach key, gatts.keys() do begin
        cdf_save_setting, key, gatts[key], filename=file
    endforeach

    vars = ['epoch','epoch_hsk']
    var_notes = 'Epoch tagged at the center of each interval, resolution is '+['about 11','256']+' sec'
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

    cdf_save_setting, 'VAR_NOTES', 'Spinfit electric field in the MGSE coordinate system (Vsc x B and Omega x R x B subtracted)', $
        varname='efield_spinfit_mgse', filename=file

end


pro rbsp_efw_phasef_gen_l2_e_spinfit_v04_per_day, date, probe=probe, filename=file, log_file=log_file


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


;---Prepare skeleton.
    data_type = 'e-spinfit-mgse'
    skeleton_base = prefix+'efw-l2_'+data_type+'_00000000_v04.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load data.
    routines = 'rbsp_efw_phasef_read_'+['e_spinfit_l2','spinaxis_gse','pos_var','efw_qual','hsk']
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, errmsg=errmsg, log_file=log_file
        if errmsg ne '' then return
    endforeach


;---Do something.
    bp = rbsp_efw_phasef_get_boom_pair(date, probe=probe)
    ; efw_qual is already using the optimum boom pair.

    ; efield_spinfit_mgse -> rbspx_e_spinfit_mgse
    ; VxB_mgse -> rbspx_evxb_mgse
    ; efield_coro_mgse -> rbspx_ecoro_mgse
    e_spinfit_var = prefix+'e_spinfit_mgse'
    old_var = prefix+'e_spinfit_mgse_v'+bp
    rename_var, old_var, to=e_spinfit_var
    get_data, e_spinfit_var, times
    foreach var, prefix+['evxb_mgse','ecoro_mgse'] do begin
        interp_time, var, times
    endforeach


    ; Apply global flag to e_spinfit and remove ew.
    flag_var = prefix+'efw_qual'
    get_data, flag_var, times, flags
    e_var = prefix+'e_spinfit_mgse'
    get_data, e_var, common_times, e_mgse
    flags = sinterpol(flags, times, common_times)
    flags = flags gt 0
    store_data, prefix+'flags_all', common_times, flags

    fillval = -1e31
    index = where(flags[*,0] ne 0, count)
    if count ne 0 then e_mgse[index,*] = fillval
    e_mgse[*,0] = fillval
    store_data, e_var, common_times, e_mgse


    ; vars depend on epoch.
    vars = prefix+['spinaxis_gse', $
        'v_gse','r_gse','lshell','mlat','mlt']
    get_data, e_var, common_times
    foreach var, vars do interp_time, var, common_times


;---Save to file.
    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    file_copy, skeleton, file, /overwrite
    cdf_rename_var, 'efield_spinfit_mgse_'+bp, to='efield_spinfit_mgse', filename=file
    cdf_rename_var, 'corotation_efield_mgse', to='efield_coro_mgse', filename=file

    old_vars = ['position_gse','velocity_gse']
    new_vars = ['pos_gse','vel_gse']
    foreach old_var, old_vars, var_id do begin
        new_var = new_vars[var_id]
        cdf_rename_var, old_var, to=new_var, filename=file
    endforeach

    routines = 'rbsp_efw_phasef_save_'+['e_spinfit_l2','spinaxis_gse','pos_var','flags_all','bias_current']+'_to_file'
    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, filename=file
    endforeach
    cdf_del_unused_vars, file
    rbsp_efw_phasef_fix_cdf_metadata, file
    rbsp_efw_phasef_gen_l2_e_spinfit_v04_skeleton, file

end


stop
probes = ['a','b']
root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    log_file = join_path([root_dir,rbspx,'l2','e-spinfit-mgse_v04','rbsp_efw_phasef_gen_l2_e_spinfit_v04.log'])
    if file_test(log_file) eq 0 then ftouch, log_file

    time_range = rbsp_efw_phasef_get_valid_range('e_spinfit', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l2','e-spinfit-mgse_v04',str_year])
        base = prefix+'efw-l2_e-spinfit-mgse_'+time_string(day,tformat='YYYYMMDD')+'_v04.cdf'
        file = join_path([path,base])
if file_test(file) eq 1 then continue
        print, file
        rbsp_efw_phasef_gen_l2_e_spinfit_v04_per_day, day, probe=probe, filename=file, log_file=log_file
    endforeach
endforeach

stop




date = '2014-01-01'
probe = 'a'
file = join_path([homedir(),'test_e_spinfit_l2_v04.cdf'])
rbsp_efw_phasef_gen_l2_e_spinfit_v04_per_day, date, probe=probe, filename=file
end
