;+
; Adopted from test_perigee_residue_correction_save_file.
; Save the E model which includes E_coro and E_vxb.
;-

pro rbsp_read_e_model_gen_file, time, probe=probe, filename=file

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

    prefix = 'rbsp'+probe+'_'
    day = time[0]-(time[0] mod secofday)
    time_range = time_double(day)+[0,secofday]


;---Prepare low-level quantities.
    rbsp_read_q_uvw2gse, time_range, probe=probe
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe


;---Common times.
    common_time_step = 10.
    common_times = make_bins(time_range, common_time_step)
    common_times = make_bins(time_range+[1,0]*common_time_step, common_time_step)
    foreach var, prefix+['r','v','b']+'_mgse' do interp_time, var, common_times


;---Calculate E_coro.
    vcoro_mgse = calc_vcoro(r_var=prefix+'r_mgse', probe=probe)
    vcoro_var = prefix+'vcoro_mgse'
    store_data, vcoro_var, common_times, vcoro_mgse
    add_setting, vcoro_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'Coro V', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

    vcoro_mgse = get_var_data(vcoro_var)*1e-3
    b_mgse = get_var_data(prefix+'b_mgse')
    ecoro_mgse = -vec_cross(vcoro_mgse,b_mgse)
    ecoro_var = prefix+'ecoro_mgse'
    store_data, ecoro_var, common_times, ecoro_mgse
    add_setting, ecoro_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Coro E', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

;---Calculate E_vxb.
    v_mgse = get_var_data(prefix+'v_mgse')*1e-3
    evxb_mgse = vec_cross(v_mgse,b_mgse)
    evxb_var = prefix+'evxb_mgse'
    store_data, evxb_var, common_times, evxb_mgse
    add_setting, evxb_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'VxB E', $
        'coord', 'MGSE', $
        'coord_labels', xyz)


;---E_model = E_coro + E_vxb.
    emod_mgse = evxb_mgse+ecoro_mgse
    emod_var = prefix+'emod_mgse'
    store_data, emod_var, common_times, emod_mgse
    add_setting, emod_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'VxB+Coro E', $
        'coord', 'MGSE', $
        'coord_labels', xyz )



;---Save data.
    save_vars = list()
    save_vars.add, prefix+['vcoro','ecoro','evxb','emod']+'_mgse', /extract
    save_vars = save_vars.toarray()

    cdf_file = file
    epochs = stoepoch(common_times,'unix')
    time_var = 'epoch'
    cdf_save_var, time_var, value=epochs, filename=cdf_file
    cdf_save_setting, varname=time_var, filename=cdf_file, dictionary($
        'FIELDNAM', 'epoch', $
        'UNITS', 'msec', $
        'VAR_TYPE', 'support_data' )

    foreach var, save_vars do begin
        data = get_var_data(var, limits=lims)
        settings = dictionary()
        settings['DEPEND_0'] = time_var
        settings['VAR_TYPE'] = 'data'
        settings['FIELDNAM'] = var
        settings['UNITS'] = lims.unit
        cdf_save_var, var, value=data, filename=cdf_file
        cdf_save_setting, varname=var, filename=cdf_file, settings
    endforeach


end


probe = 'b'
time = time_double('2012-09-05')
;time = time_double('2018-04-29')
file = join_path([homedir(),'tmp.cdf'])
if file_test(file) then file_delete, file
rbsp_read_e_model_gen_file, time, probe=probe, filename=file
end
