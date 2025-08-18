;+
; Adopted from rbsp_efw_read_l3_gen_file.
; v04 uses the spinfit E from E uvw with corrected time tags.
;-

pro rbsp_efw_phasef_gen_l3_v04_skeleton, file

    if file_test(file) eq 0 then return

    base = file_basename(file)
    if strmid(base,0,4) ne 'rbsp' then return

    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    gatts = dictionary( $
        'Logical_source', prefix+'efw-l3', $
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

end


pro rbsp_efw_phasef_gen_l3_v04, date, probe=probe, filename=file, log_file=log_file

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
    skeleton_base = prefix+'efw-l3_00000000_v04.cdf'
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

;---Save the used boom pair.
    the_boom_pair = '12'
    if probe eq 'a' and time_range[0] ge time_double('2015-01-01') then the_boom_pair = '24'
    bp_var = 'boom_pair_used'
    cdf_save_var, bp_var, value=fix(the_boom_pair), filename=file
    date_var = 'date'
    settings = dictionary($
        'DEPEND_0', date_var, $
        'FORMAT', 'I2', $
        'LABLAXIS', 'boom_pair_used_for_spinfit', $
        'FIELDNAM', 'boom_pair_used_for_spinfit', $
        'CATDESC', 'boom_pair_used_for_spinfit', $
        'VAR_TYPE', 'data' )
    cdf_save_setting, settings, filename=file, varname=bp_var
    cdf_save_var, date_var, value=time_range[0], filename=file
    settings = dictionary($
        'FIELDNAM', 'date', $
        'CATDESC', 'date', $
        'VAR_TYPE', 'metadata' )
    cdf_save_setting, settings, filename=file, varname=date_var


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
    ; angle_spinplane_Bo
    ; global_flag
    ; flags_charging_bias_eclipse
    ; flags_all
    rbsp_efw_phasef_read_flag_25, time_range, probe=probe, boom_pair=the_boom_pair
    fillval = !values.f_nan
    flag_var = prefix+'flag_25'
    flags = get_var_data(flag_var, at=common_times) gt 0
    bad_index = where(flags[*,0] ne 0, nbad_index)

    ; Useful subset of the flags.
    flag_names = get_setting(flag_var, 'labels')
    wanted_flags = ['charging','autobias','eclipse','charging_extreme']
    wanted_index = []
    foreach wanted_flag, wanted_flags do begin
        wanted_index = [wanted_index, where(flag_names eq wanted_flag)]
    endforeach
    cdf_save_data, 'flags_charging_bias_eclipse', value=transpose(flags[*,wanted_index]), filename=file
    cdf_save_data, 'global_flag', value=flags[*,0], filename=file

    ; B angle with spin axis.
    rbsp_efw_phasef_read_angle_spinplane_Bo, time_range, probe=probe
    cdf_var = 'angle_spinplane_Bo'
    b_angle = get_var_data(prefix+cdf_var, at=common_times)
    cdf_save_data, cdf_var, value=transpose(b_angle), filename=file

    cdf_var = 'flags_all'
    if cdf_has_var(cdf_var, filename=file) then cdf_del_var, cdf_var, filename=file
    cdf_rename_var, 'flags_all2_'+the_boom_pair, to=cdf_var, filename=file
    cdf_save_data, cdf_var, value=transpose(flags), filename=file


;---Save wanted E field as wanted names:
    ; efield_in_corotation_frame_spinfit_mgse
    ; efield_in_corotation_frame_spinfit_edotb_mgse
    ; efield_in_inertial_frame_spinfit_mgse
    ; efield_in_inertial_frame_spinfit_edotb_mgse
    ; VxB_efield_of_earth_mgse
    ; VscxB_motional_efield_mgse
    rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
    rbsp_efw_phasef_read_e_spinfit, time_range, probe=probe
    rbsp_efw_phasef_read_e_spinfit_diagonal, time_range, probe=probe
    rbsp_efw_phasef_read_e_spinfit_edotb, time_range, probe=probe
    rbsp_efw_phasef_read_e_fit, time_range, probe=probe


    ; Change var names in CDF.
    new_e_var1s = 'efield_in_corotation_frame_spinfit'+['','_edotb']+'_mgse'
    new_e_var2s = 'efield_in_inertial_frame_spinfit'+['','_edotb']+'_mgse'
    old_e_var1s = 'efield_corotation_spinfit'+['','_edotb']+'_mgse_'+the_boom_pair
    old_e_var2s = 'efield_inertial_spinfit'+['','_edotb']+'_mgse_'+the_boom_pair
    new_vars = [new_e_var1s,new_e_var2s]
    old_vars = [old_e_var1s,old_e_var2s]
    foreach new_var, new_vars, var_id do begin
        old_var = old_vars[var_id]
        cdf_rename_var, old_var, to=new_var, filename=file
    endforeach


    ; Save E fields.
    efit = get_var_data(prefix+'efit_mgse', at=common_times)
    e_coro = get_var_data(prefix+'ecoro_mgse', at=common_times)
    e_vxb = get_var_data(prefix+'evxb_mgse', at=common_times)
    e_vars = prefix+'e_spinfit_mgse'+['','_edotb']+'_v'+the_boom_pair
    foreach e_var, e_vars, var_id do begin
        edata = get_var_data(e_var)
        if nbad_index ne 0 then edata[bad_index,*] = fillval

        ; Check if efit reduces the perigee data.
        de = edata-efit
        diff = snorm(de) - snorm(edata)
        dis = snorm(get_var_data(prefix+'r_gse'))/constant('re')
        index = where(dis le 2, count)
        perigee_times = common_times[time_to_range(index,time_step=1)]
        nperigee = n_elements(perigee_times)*0.5
        for perigee_id=0,nperigee-1 do begin
            time_index = lazy_where(common_times, '[]', perigee_times[perigee_id,*])
            if mean(diff[time_index],/nan) ge 0 then begin
                de[time_index,*] = !values.f_nan
            endif
        endfor

        cdf_save_data, new_e_var1s[var_id], filename=file, value=transpose(de)
        cdf_save_data, new_e_var2s[var_id], filename=file, value=transpose(de+e_coro)
    endforeach
    cdf_var = 'VxB_efield_of_earth_mgse'
    cdf_rename_var, 'corotation_efield_mgse', to=cdf_var, filename=file
    cdf_save_data, cdf_var, value=transpose(e_coro), filename=file
    cdf_var = 'VscxB_motional_efield_mgse'
    cdf_rename_var, 'VxB_mgse', to=cdf_var, filename=file
    cdf_save_data, cdf_var, value=transpose(e_vxb), filename=file


;---Density, spacecraft_potential.
    ; density
    ; spacecraft_potential
    rbsp_efw_phasef_read_density, time_range, probe=probe, boom_pairs=the_boom_pair
    dens_var = prefix+'density_'+the_boom_pair
    interp_time, dens_var, common_times
    cdf_var = 'density'
    cdf_rename_var, 'density_'+the_boom_pair, to=cdf_var, filename=file
    cdf_save_data, cdf_var, filename=file, value=get_var_data(dens_var)

    rbsp_efw_phasef_read_vsvy, time_range, probe=probe
    vsvy_var = prefix+'efw_vsvy'
    interp_time, vsvy_var, common_times
    vsvy = get_var_data(vsvy_var)
    boom_index = fix([strmid(the_boom_pair,0,1),strmid(the_boom_pair,1,1)])-1
    vsc = total(vsvy[*,boom_index],2)*0.5
    cdf_var = 'spacecraft_potential'
    cdf_rename_var, 'vsvy_vavg_combo_'+the_boom_pair, to=cdf_var, filename=file
    cdf_save_data, cdf_var, filename=file, value=vsc


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
    ; bias_current
    rbsp_efw_phasef_read_hsk, time_range, probe=probe
    rbsp_efw_phasef_save_bias_current_to_file, time_range, probe=probe, filename=file


;---Wrap up.
    cdf_del_unused_vars, file
    rbsp_efw_phasef_fix_cdf_metadata, file
    rbsp_efw_phasef_gen_l3_v04_skeleton, file

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
        path = join_path([root_dir,rbspx,'l3_v04',str_year])
        base = prefix+'efw-l3_'+time_string(day,tformat='YYYYMMDD')+'_v04.cdf'
        file = join_path([path,base])
if file_test(file) eq 1 then continue
        print, file
        rbsp_efw_phasef_gen_l3_v04, day, probe=probe, filename=file
    endforeach
endforeach
stop


date = time_double('2015-05-28')
date = time_double('2018-10-08')
probe = 'a'

date = time_double('2017-01-08')
probe = 'b'

file = join_path([homedir(),'test_level3.cdf'])
rbsp_efw_phasef_gen_l3_v04, date, probe=probe, file=file
end
