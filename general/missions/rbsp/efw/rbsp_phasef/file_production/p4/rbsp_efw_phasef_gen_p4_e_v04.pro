;+
; Generate P4 v04 data.
; To replace rbsp_efw_read_l4_gen_file.
;
; Use the e_spinfit and e_diagonal_spinfit updated on 2021-07-07.
; Use the 25-element flags and have a more explicit structure for the flag system.
;-

pro rbsp_efw_phasef_gen_p4_v04, date, $
    probe=probe, filename=file, log_file=log_file

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

    data_type = 'e_spinfit_p4'
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
    skeleton_base = prefix+'efw-p4_00000000_v04.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif
    path = file_dirname(file)
    if file_test(path,/directory) eq 0 then file_mkdir, path
    file_copy, skeleton, file, overwrite=1


;---Settings.
    secofday = 86400d
    time_range = date+[0,secofday]
    bps = ['12','34','13','14','23','24']
    nbp = n_elements(bps)



;---Fix labeling.
    foreach var, cdf_vars(file) do begin
        labeling = phasef_get_labeling(var)
        if n_elements(labeling) eq 0 then continue
        cdf_save_setting, labeling, varname=var, filename=file

        ; Check labels if needed.
        the_key = 'labels'
        if labeling.haskey(the_key) then begin
            vatts = cdf_read_setting(var, filename=file)
            label_var = vatts['LABL_PTR_1']
            if cdf_has_var(label_var, filename=file) then begin
                label_vatts = cdf_read_setting(label_var, filename=file)
            endif else label_vatts = dictionary()
            cdf_save_var, label_var, filename=file, $
                value=transpose(labeling[the_key])
            if n_elements(label_vatts) ne 0 then begin
                cdf_save_setting, label_vatts, filename=file, varname=label_var
            endif
        endif
    endforeach


;---Save common times.
    rbsp_efw_phasef_read_sunpulse_time, time_range, probe=probe
    get_data, prefix+'sunpulse_times', common_times
    epoch = tplot_time_to_epoch(common_times, epoch16=1)
    time_var = 'epoch'
    cdf_save_data, time_var, value=epoch, filename=file


;---Save spice var.
    ; position_gse, velocity_gse, spinaxis_gse, mlt, mlat, lshell
    rbsp_efw_phasef_read_spinaxis_gse, date, probe=probe
    rbsp_efw_phasef_read_pos_var, date, probe=probe
    foreach var, prefix+[['spinaxis','r','v']+'_gse','mlt','mlat','lshell'] do begin
        interp_time, var, common_times
    endforeach
    rbsp_efw_phasef_save_position_var_to_file, date, filename=file, probe=probe
    rbsp_efw_phasef_save_spinaxis_gse_to_file, date, filename=file, probe=probe


;---Flags and the related vars.
    ; angle_spinplane_Bo, diagBratio
    ; flags_all_ij, flags_charging_bias_eclipse_ij
    foreach the_boom_pair, bps do begin
        rbsp_efw_phasef_read_flag_25, time_range, probe=probe, boom_pair=the_boom_pair
        fillval = !values.f_nan
        flag_var = prefix+'flag_25'
        interp_time, flag_var, common_times
        flags = get_var_data(flag_var) gt 0

        ; Useful subset of the flags.
        flag_names = get_setting(flag_var, 'labels')
        wanted_flags = ['charging','autobias','eclipse','charging_extreme']
        wanted_index = []
        foreach wanted_flag, wanted_flags do begin
            wanted_index = [wanted_index, where(flag_names eq wanted_flag)]
        endforeach
        cdf_var = 'flags_charging_bias_eclipse_'+the_boom_pair
        cdf_save_data, cdf_var, value=transpose(flags[*,wanted_index]), filename=file

        cdf_var = 'flags_all_'+the_boom_pair
        if cdf_has_var(cdf_var, filename=file) then cdf_del_var, cdf_var, filename=file
        cdf_rename_var, 'flags_all2_'+the_boom_pair, to=cdf_var, filename=file
        cdf_save_data, cdf_var, value=transpose(flags), filename=file
    endforeach


    ; B angle with spin axis.
    rbsp_efw_phasef_read_angle_spinplane_bo, time_range, probe=probe
    cdf_var = 'angle_spinplane_Bo'
    b_angle = get_var_data(prefix+cdf_var, at=common_times)
    cdf_save_data, cdf_var, value=transpose(b_angle), filename=file
    rbsp_efw_phasef_read_diagbratio, time_range, probe=probe
    cdf_var = 'diagBratio'
    b_ratio = get_var_data(prefix+cdf_var, at=common_times)
    cdf_save_data, cdf_var, value=transpose(b_ratio), filename=file




;---Save wanted E field as wanted names:
    ; efield_in_corotation_frame_spinfit_mgse_ij
    ; efield_in_corotation_frame_spinfit_edotb_mgse_ij
    ; efield_in_inertial_frame_spinfit_mgse_ij
    ; efield_in_inertial_frame_spinfit_edotb_mgse_ij
    ; VxB_efield_of_earth_mgse
    ; VscxB_motional_efield_mgse
    rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
    rbsp_efw_phasef_read_e_spinfit, time_range, probe=probe
    rbsp_efw_phasef_read_e_spinfit_diagonal, time_range, probe=probe
    rbsp_efw_phasef_read_e_spinfit_edotb, time_range, probe=probe
    rbsp_efw_phasef_read_e_fit, time_range, probe=probe


    ; Change var names in CDF.
    efit = get_var_data(prefix+'efit_mgse', at=common_times)
    e_coro = get_var_data(prefix+'ecoro_mgse', at=common_times)
    e_vxb = get_var_data(prefix+'evxb_mgse', at=common_times)
    foreach the_boom_pair, bps do begin
        new_e_var1s = 'efield_in_corotation_frame_spinfit'+['','_edotb']+'_mgse_'+the_boom_pair
        new_e_var2s = 'efield_in_inertial_frame_spinfit'+['','_edotb']+'_mgse_'+the_boom_pair
        old_e_var1s = 'efield_corotation_spinfit'+['','_edotb']+'_mgse_'+the_boom_pair
        old_e_var2s = 'efield_inertial_spinfit'+['','_edotb']+'_mgse_'+the_boom_pair
        new_vars = [new_e_var1s,new_e_var2s]
        old_vars = [old_e_var1s,old_e_var2s]
        foreach new_var, new_vars, var_id do begin
            old_var = old_vars[var_id]
            cdf_rename_var, old_var, to=new_var, filename=file
        endforeach

        ; Save E fields.
        e_vars = prefix+'e_spinfit_mgse'+['','_edotb']+'_v'+the_boom_pair
        foreach e_var, e_vars, var_id do begin
            edata = get_var_data(e_var)
            cdf_save_data, new_e_var1s[var_id], filename=file, value=transpose(edata-efit)
            cdf_save_data, new_e_var2s[var_id], filename=file, value=transpose(edata-efit+e_coro)
        endforeach
    endforeach
    cdf_var = 'VxB_efield_of_earth_mgse'
    cdf_rename_var, 'corotation_efield_mgse', to=cdf_var, filename=file
    cdf_save_data, cdf_var, value=transpose(e_coro), filename=file
    cdf_var = 'VscxB_motional_efield_mgse'
    cdf_rename_var, 'VxB_mgse', to=cdf_var, filename=file
    cdf_save_data, cdf_var, value=transpose(e_vxb), filename=file


;---Density, spacecraft_potential.
    ; density_ij
    ; spacecraft_potential_ij
    rbsp_efw_phasef_read_density, time_range, probe=probe
    foreach the_boom_pair, bps do begin
        cdf_var = 'density_'+the_boom_pair
        interp_time, prefix+cdf_var, common_times
        cdf_save_data, cdf_var, filename=file, value=get_var_data(prefix+cdf_var)
    endforeach

    rbsp_efw_phasef_read_vsvy, time_range, probe=probe
    vsvy_var = prefix+'efw_vsvy'
    interp_time, vsvy_var, common_times
    vsvy = get_var_data(vsvy_var)
    foreach the_boom_pair, bps do begin
        boom_index = fix([strmid(the_boom_pair,0,1),strmid(the_boom_pair,1,1)])-1
        vsc = total(vsvy[*,boom_index],2)*0.5
        cdf_var = 'spacecraft_potential_'+the_boom_pair
        cdf_rename_var, 'vsvy_vavg_combo_'+the_boom_pair, to=cdf_var, filename=file
        cdf_save_data, cdf_var, filename=file, value=vsc
    endforeach


;---Burst 1 and 2 avail flag.
    ; rbspx_burst1_avail
    ; rbspx_burst2_avail
    rbsp_efw_phasef_read_burst_flag, time_range, probe=probe
    vars = 'burst'+['1','2']+'_avail'
    foreach var, vars do begin
        flags = get_var_data(prefix+var, at=common_times) gt 0
        cdf_save_data, var, value=flags, filename=file
    endforeach


;---HSK data.
    ; bias_current, usher_voltage, guard_voltage.
    rbsp_efw_phasef_read_hsk, time_range, probe=probe
    rbsp_efw_phasef_save_hsk_to_file, date, probe=probe, filename=file


;---Orbit number.
    ; orbit_num.
    rbsp_efw_phasef_read_orbit_num, time_range, probe=probe
    var = prefix+'orbit_num'
    interp_time, var, common_times
    store_data, var, common_times, round(get_var_data(var))
    rbsp_efw_phasef_save_orb_num_to_file, time_range, probe=probe, filename=file



;---B mGSE and B-B_model.
    ; b_mgse
    ; bfield_magnitude
    ; bfield_model_mgse_t89
    ; bfield_model_mgse_igrf
    ; bfield_minus_model_mgse_t89
    ; bfield_minus_model_mgse_igrf
    ; bfield_magnitude_minus_model_magnitude_t89
    ; bfield_magnitude_minus_model_magnitude_igrf
    rbsp_efw_phasef_read_b_mgse, time_range, probe=probe
    rbsp_efw_phasef_read_b_model, time_range, probe=probe
    models = ['t89','igrf']
    foreach var, prefix+'b_mgse'+['','_'+models] do begin
        interp_time, var, common_times
    endforeach
    b_var = 'bfield_mgse'
    b_mgse = get_var_data(prefix+'b_mgse')
    bmag = snorm(b_mgse)
    foreach model, models do begin
        bmod_mgse = get_var_data(prefix+'b_mgse_'+model)
        cdf_save_data, 'bfield_model_mgse_'+model, value=transpose(bmod_mgse), filename=file
        db_mgse = b_mgse-bmod_mgse
        cdf_save_data, 'bfield_minus_model_mgse_'+model, value=transpose(db_mgse), filename=file
        dbmag = bmag-snorm(bmod_mgse)
        cdf_rename_var, 'bfield_magnitude_minus_modelmagnitude_'+model, to='bfield_magnitude_minus_model_magnitude_'+model, filename=file
        cdf_save_data, 'bfield_magnitude_minus_model_magnitude_'+model, value=dbmag, filename=file
    endforeach
    cdf_save_var, b_var, value=b_mgse, filename=file
    settings = cdf_read_setting('bfield_model_mgse_'+models[0], filename=file)
    settings['VAR_NOTES'] = 'Bfield in the MGSE coordinate system'
    settings['FIELDNAM'] = b_var
    settings['LABLAXIS'] = 'Bfield (MGSE)'
    settings['CATDESC'] = b_var
    cdf_save_setting, settings, filename=file, varname=b_var
    cdf_save_data, 'bfield_magnitude', value=bmag, filename=file


;---Wrap up.
    cdf_del_unused_vars, file


end



stop
probes = ['b']
root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = rbsp_efw_phasef_get_valid_range('e_spinfit', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'p4',str_year])
        base = prefix+'efw-p4_'+time_string(day,tformat='YYYYMMDD')+'_v04.cdf'
        file = join_path([path,base])
if file_test(file) eq 1 then continue
        print, file
        rbsp_efw_phasef_gen_p4_v04, day, probe=probe, filename=file
    endforeach
endforeach
stop



date = '2013-02-07'
probe = 'a'
; A shock event
date = '2017-09-07'
probe = 'a'

file = join_path([homedir(),'test_level4.cdf'])
tic
rbsp_efw_phasef_gen_p4_v04, date, probe=probe, file=file
toc
end