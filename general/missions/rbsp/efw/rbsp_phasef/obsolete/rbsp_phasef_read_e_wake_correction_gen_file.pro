;+
; E_wake_correction = (E_wake_mgse-E_mgse) down sampled to 1 min cadence.
;-

pro rbsp_phasef_read_e_wake_correction_gen_file, time, probe=probe, filename=file


;---Check inputs.
    if n_elements(file) eq 0 then begin
        errmsg = handle_error('No output file ...')
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif

    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif


    ; Get the time range.
    secofday = 86400d
    date = time-(time mod secofday)
    day_time_range = date+[0,secofday]

    time_step = 60.
    pad_time = 5*time_step
    time_range = day_time_range+[-1,1]*pad_time
    common_times = make_bins(time_range, time_step)


    prefix = 'rbsp'+probe+'_'
    pairs = ['12','34']
    rbsp_efw_phasef_read_e_spinfit, time_range, probe=probe
    rbsp_phasef_read_e_wake_spinfit, time_range, probe=probe
    foreach pair, pairs do begin
        var1 = prefix+'e_wake_spinfit_mgse_v'+pair
        var0 = prefix+'e_spinfit_mgse_v'+pair
        var2 = prefix+'e_wake_correction_mgse_v'+pair
        e_wake_mgse = get_var_data(var1, times=times)
        e_mgse = get_var_data(var0, times=times)
        de_mgse = e_wake_mgse-e_mgse
        width = pad_time/total(times[0:1]*[-1,1])
        for ii=1,2 do begin
            de_mgse[*,ii] = smooth(de_mgse[*,ii], width, /edge_zero, /nan)
        endfor
        de_mgse = sinterpol(de_mgse, times, common_times)
        store_data, var2, common_times, de_mgse
    endforeach



;---Save data.
    path = fgetpath(file)
    if file_test(path,/directory) eq 0 then file_mkdir, path
    data_file = file
    if file_test(data_file) eq 1 then file_delete, data_file  ; overwrite old files.

    ginfo = dictionary($
        'TITLE', 'RBSP EFW E spinfit in the corotation frame', $
        'TEXT', 'Generated by Sheng Tian at the University of Minnesota, adopted from rbsp_efw_spinfit_vxb_crib' )
    cdf_save_setting, ginfo, filename=file
    save_vars = prefix+'e_wake_correction_mgse_v'+pairs
    time_index = lazy_where(common_times, '[]', day_time_range)
    common_times = common_times[time_index]
    foreach save_var, save_vars do begin
        de_mgse = get_var_data(save_var)
        store_data, save_var, common_times, $
            float(de_mgse[time_index,*]), limits={units:'mV/m', coord:'mgse'}
    endforeach
    stplot2cdf, save_vars, istp=1, filename=file, time_var='epoch'


end

 time = time_double('2014-08-01')
 time = time_double('2013-06-07')
 probe = 'a'
 file = join_path([homedir(),'test.cdf'])
 if file_test(file) eq 1 then file_delete, file
 rbsp_phasef_read_e_wake_correction_gen_file, time, probe=probe, filename=file
stop

probes = ['a']
root_dir = join_path([default_local_root(),'rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-14']): time_double(['2012-09-08','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'e_wake_correction',str_year])
        base = prefix+'efw_e_wake_correction_mgse_'+time_string(day,tformat='YYYY_MMDD')+'_v01.cdf'
        file = join_path([path,base])
        rbsp_phasef_read_e_wake_correction_gen_file, day, probe=probe, filename=file
    endforeach
endforeach

end
