;+
; Generate data for calc e_fit, including
;   emod_mgse, vcoro_mgse, v_mgse, r_mgse,
;   b_mgse, e_mgse, ex_dotb_mgse, flag_25.
;-

pro rbsp_efw_phasef_read_e_fit_var_gen_file, time_range, probe=probe, filename=file

;---Check inputs.
    if n_elements(file) eq 0 then begin
        errmsg = handle_error('No output file ...')
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif

    if n_elements(time_range) ne 2 then begin
        errmsg = handle_error('No input time ...')
        return
    endif

;---Settings.
    secofday = 86400d
    tr = time_range
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'
    timespan, tr[0], total(tr*[-1,1]), /seconds


;---Load data.
    ; b_mgse, e_mgse, r_mgse, v_mgse.
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
    get_data, prefix+'b_mgse', common_times

    ; omega_mgse.
    ntime = n_elements(common_times)
    ndim = 3
    omega_gei = dblarr(ntime,ndim)
    omega_gei[*,2] = (2*!dpi)/constant('secofday')
    omega_mgse = cotran(omega_gei,common_times,'gei2mgse', probe=probe)
    var = prefix+'omega_mgse'
    store_data, var, common_times, omega_mgse
    add_setting, var, /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'rad/sec', $
        'short_name', tex2str('Omega'), $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )

    ; flag_25.
    rbsp_efw_phasef_read_flag_25, time_range, probe=probe
    var = prefix+'flag_25'
    flag_25 = get_var_data(var, at=common_times) gt 0
    store_data, var, common_times, flag_25

    ; edotb.
    var = prefix+'edotb_mgse'
    rbsp_efw_calc_edotb_to_zero, prefix+'e_mgse', prefix+'b_mgse', newname=var, no_preprocess=1
    edotb_mgse = get_var_data(var)
    var = prefix+'ex_dotb_mgse'
    store_data, var, common_times, edotb_mgse[*,0]
    add_setting, var, /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'mV/m', $
        'short_name', 'MGSE Bx' )

;---Save data.
    vars = prefix+['b_mgse','e_mgse','r_mgse','v_mgse','omega_mgse',$
        'flag_25','ex_dotb_mgse']
    stplot2cdf, vars, filename=file, time_var='epoch', istp=1

end


time_range = time_double(['2012','2013'])
probe = 'b'
file = join_path([homedir(),'rbspb_efw_e_fit_var_2012_v02.cdf'])
rbsp_efw_phasef_read_e_fit_var_gen_file, time_range, probe=probe, filename=file
end
