;+
; Load quantities for fitting perigee corrections.
;-

pro rbsp_phasef_load_fit_quantities, probe=probe

    time_range = time_double(['2013-01-01','2019-01-01'])
    cdf_file = join_path([homedir(),'rbsp_phasef_fit_quantities.cdf'])

;---Common times.
    common_time_step = 10.
    time_var = 'time'
    if ~cdf_has_var(time_var, filename=cdf_file) then begin
        data = make_bins(time_range+[1,0]*common_time_step, common_time_step)
        time_var_settings = dictionary($
            'var_type', 'support_data', $
            'unit', 'sec', $
            'time_var_type', 'unix' )
        cdf_save_var, time_var, value=data, filename=cdf_file
        cdf_save_setting, time_var_settings, filename=cdf_file, varname=time_var
    endif
    common_times = cdf_read_var(time_var, filename=cdf_file)
    ncommon_time = n_elements(common_times)


;---Other quantities.
    prefix = 'rbsp'+probe+'_'

    de_mgse_var = prefix+'de_mgse'
    if ~cdf_has_var(de_mgse_var, filename=cdf_file) then begin
        rbsp_read_de_mgse, time_range, probe=probe
        interp_time, de_mgse_var, common_times

        vname = de_mgse_var
        data = float(get_var_data(vname))
        settings = dictionary($
            'depend_0', time_var, $
            'var_type', 'data', $
            'display_type', 'vector', $
            'short_name', 'dE', $
            'coord', 'MGSE', $
            'coord_labels', ['y','z'], $
            'colors', sgcolor(['green','blue']) )

        cdf_save_var, vname, value=data, filename=cdf_file
        cdf_save_setting, settings, filename=cdf_file, varname=vname
    endif
    cdf_load_var, de_mgse_var, filename=cdf_file

    b_mgse_var = prefix+'b_mgse'
    if ~cdf_has_var(b_mgse_var, filename=cdf_file) then begin
        vname = b_mgse_var
        if check_if_update(vname) then rbsp_efw_phasef_prepare_residue_removal, time_range, probe=probe
        interp_time, vname, common_times

        data = float(get_var_data(vname))
        settings = dictionary($
            'depend_0', time_var, $
            'var_type', 'data', $
            'display_type', 'vector', $
            'short_name', 'B', $
            'coord', 'MGSE', $
            'coord_labels', ['x','y','z'], $
            'colors', sgcolor(['red','green','blue']) )

        cdf_save_var, vname, value=data, filename=cdf_file
        cdf_save_setting, settings, filename=cdf_file, varname=vname
    endif
    cdf_load_var, b_mgse_var, filename=cdf_file

    r_mgse_var = prefix+'r_mgse'
    if ~cdf_has_var(r_mgse_var, filename=cdf_file) then begin
        vname = r_mgse_var
        if check_if_update(vname) then rbsp_efw_phasef_prepare_residue_removal, time_range, probe=probe
        interp_time, vname, common_times

        data = float(get_var_data(vname))
        settings = dictionary($
            'depend_0', time_var, $
            'var_type', 'data', $
            'display_type', 'vector', $
            'short_name', 'R', $
            'coord', 'MGSE', $
            'coord_labels', ['x','y','z'], $
            'colors', sgcolor(['red','green','blue']) )

        cdf_save_var, vname, value=data, filename=cdf_file
        cdf_save_setting, settings, filename=cdf_file, varname=vname
    endif
    cdf_load_var, r_mgse_var, filename=cdf_file
    
    
    bad_e_flag_var = prefix+'bad_e_flag'
    if ~cdf_has_var(bad_e_flag_var, filename=cdf_file) then begin
        vname = bad_e_flag_var
        if check_if_update(vname) then begin
            boom_flag_var = prefix+'boom_flag'
            if check_if_update(boom_flag_var) then rbsp_read_boom_flag, time_range, probe=probe
            flags = total(get_var_data(boom_flag_var, times=times),2) ne 4
            store_data, vname, times, flags
        endif
        interp_time, vname, common_times
        
        data = byte(get_var_data(vname))
        settings = dictionary($
            'depend_0', time_var, $
            'var_type', 'data', $
            'display_type', 'scalar', $
            'short_name', 'Boom flag', $
            'yrange', [-0.2,1.2] )

        cdf_save_var, vname, value=data, filename=cdf_file
        cdf_save_setting, settings, filename=cdf_file, varname=vname
    endif
    


;---Remove bad data in dE.
    de_mgse = get_var_data(de_mgse_var)
    fillval = !values.f_nan
    
    dis = snorm(get_var_data(r_mgse_var))
    index = where(dis ge 2, count)
    if count ne 0 then de_mgse[index,*] = fillval
    
    
    rbsp_read_eclipse_flag, time_range, probe=probe
    flag_var = prefix+'eclipse_flag'
    flags = get_var_data(flag_var, times=times)
    index = where(flags eq 1, count)
    pad_time = 300.
    if count ne 0 then begin
        bad_time_ranges = times[time_to_range(index,time_step=1)]
        bad_time_ranges[*,0] -= pad_time
        bad_time_ranges[*,1] += pad_time
        bad_index_ranges = (bad_time_ranges-time_range[0])/common_time_step
        bad_index_ranges <= ncommon_time-1
        bad_index_ranges >= 0
        nbad_section = n_elements(bad_time_ranges)*0.5
        for ii=0,nbad_section-1 do begin
            i0 = bad_index_ranges[ii,0]
            i1 = bad_index_ranges[ii,1]
            de_mgse[i0:i1,*] = fillval
        endfor
    endif
    
    
    flag_var = prefix+'boom_flag'
    flags = total(get_var_data(flag_var, times=times),2)
    index = where(flags ne 4, count)
    pad_time = 300.
    if count ne 0 then begin
        bad_time_ranges = times[time_to_range(index,time_step=1)]
        bad_time_ranges[*,0] -= pad_time
        bad_time_ranges[*,1] += pad_time
        bad_index_ranges = (bad_time_ranges-time_range[0])/common_time_step
        bad_index_ranges <= ncommon_time-1
        bad_index_ranges >= 0
        nbad_section = n_elements(bad_time_ranges)*0.5
        for ii=0,nbad_section-1 do begin
            i0 = bad_index_ranges[ii,0]
            i1 = bad_index_ranges[ii,1]
            de_mgse[i0:i1,*] = fillval
        endfor
    endif
    
    
    labels = ['y','z']
    for ii=0,1 do begin
        the_var = prefix+'de'+labels[ii]
        store_data, the_var, common_times, de_mgse[*,ii]
        add_setting, the_var, /smart, dictionary($
            'display_type', 'scalar', $
            'short_name', 'dE'+labels[ii], $
            'unit', 'mV/m', $
            'yrange', [-1,1]*10 )
    endfor

end

foreach probe, ['a','b'] do rbsp_phasef_load_fit_quantities, probe=probe
end