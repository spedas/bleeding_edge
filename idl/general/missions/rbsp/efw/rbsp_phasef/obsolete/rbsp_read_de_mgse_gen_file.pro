;+
; Read dE = E_mgse - Emod_mgse
;-

pro rbsp_read_de_mgse_gen_file, time, probe=probe, filename=file

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


;---Constants and settings.
    errmsg = ''
    xyz = constant('xyz')
    secofday = constant('secofday')
    fillval = !values.f_nan

    prefix = 'rbsp'+probe+'_'
    day = time[0]-(time[0] mod secofday)
    time_range = time_double(day)+[0,secofday]
    common_time_step = 10.
    common_times = make_bins(time_range+[1,0]*common_time_step, common_time_step)

    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
    rbsp_read_e_model, time_range, probe=probe

    vars = prefix+['r','e','emod']+'_mgse'
    foreach var, vars do interp_time, var, common_times

    dis = snorm(get_var_data(prefix+'r_mgse'))
    store_data, prefix+'dis', common_times, dis
    add_setting, prefix+'dis', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'Re', $
        'short_name', '|R|' )

    e_mgse = get_var_data(prefix+'e_mgse')
    e_mgse[*,0] = fillval
    store_data, prefix+'e_mgse', common_times, e_mgse[*,1:2]
    add_setting, prefix+'e_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'MGSE', $
        'coord_labels', ['y','z'], $
        'colors', sgcolor(['green','blue']) )

    emod_mgse = get_var_data(prefix+'emod_mgse')
    emod_mgse[*,0] = fillval
    store_data, prefix+'emod_mgse', common_times, emod_mgse[*,1:2]
    add_setting, prefix+'emod_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Model E', $
        'coord', 'MGSE', $
        'coord_labels', ['y','z'], $
        'colors', sgcolor(['green','blue']) )


    de_mgse = e_mgse-emod_mgse
    store_data, prefix+'de_mgse', common_times, de_mgse[*,1:2]
    add_setting, prefix+'de_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'coord', 'MGSE', $
        'coord_labels', ['y','z'], $
        'colors', sgcolor(['green','blue']) )


    save_vars = prefix+[['e','emod','de']+'_mgse','dis']
    stplot2cdf, save_vars, filename=file, istp=1, time_var='epoch'
end


probe = 'b'
time = time_double('2014-04-28')
;time = time_double('2018-04-29')
file = join_path([homedir(),'tmp.cdf'])
if file_test(file) then file_delete, file
rbsp_read_de_mgse_gen_file, time, probe=probe, filename=file
end
