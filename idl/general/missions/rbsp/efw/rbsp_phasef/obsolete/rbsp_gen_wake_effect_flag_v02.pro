;+
; Generate v02 data, which adds Ew to the file.
;-

pro rbsp_gen_wake_effect_flag_v02, probe=probe

    local_root = join_path([default_local_root(),'sdata','rbsp'])

    if n_elements(time_range) eq 0 then begin
        case probe of
            'a': time_range = ['2012-09-05','2019-10-15']
            'b': time_range = ['2012-09-05','2019-07-17']
        endcase
        time_range = time_double(time_range)
    endif
time_range = time_double(['2013-03-03','2019-07-17'])

    dates = break_down_times(time_range, 'day')
    base_name_pattern = 'rbsp'+probe+'_efw_wake_effect_flag_and_euv_%Y_%m%d_v01.cdf'
    base_name_pattern2 = 'rbsp'+probe+'_efw_wake_effect_flag_and_euv_%Y_%m%d_v02.cdf'
    foreach date, dates do begin
        base_name = apply_time_to_pattern(base_name_pattern, date)
        year = time_string(date,tformat='YYYY')
        data_file = join_path([local_root,'wake_effect_flag','rbsp'+probe,year,base_name])
        if file_test(data_file) eq 0 then continue

        the_time_range = date+[0,constant('secofday')]
        timespan, the_time_range[0], total(the_time_range*[-1,1]), /seconds
        rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='cal', coord='uvw', /noclean, trange=the_time_range

        prefix = 'rbsp'+probe+'_'
        e_var = prefix+'efw_esvy'
        time_var = 'unix_time'
        times = cdf_read_var(time_var, filename=data_file)
        ew = (get_var_data(e_var, at=times))[*,2]

        the_var = prefix+'ew'
        cdf_save_var, the_var, value=ew, filename=data_file
        settings = dictionary($
            'depend_0', time_var, $
            'unit', 'mV/m', $
            'VAR_TYPE', 'data' )
        cdf_save_setting, varname=the_var, filename=data_file, settings
    endforeach
end

foreach probe, ['b'] do rbsp_gen_wake_effect_flag_v02, probe=probe
end
