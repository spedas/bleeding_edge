;+
; Preprocess and load v_mgse to memory.
;-

pro rbsp_efw_phasef_read_v_mgse, time_range, probe=probe

    prefix = 'rbsp'+probe+'_'
    the_var = prefix+'v_mgse'
    if ~check_if_update(the_var, time_range) then return

    v_gse_var = prefix+'v_gse'
    rbsp_read_sc_vel, time_range, probe=probe

    rbsp_read_q_uvw2gse, time_range, probe=probe
    v_gse = get_var_data(v_gse_var, times=times)
    v_mgse = cotran(v_gse, times, probe=probe, 'gse2mgse')
    store_data, the_var, times, v_mgse
    add_setting, the_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'V', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )

end

time_range = time_double(['2013-01-01','2013-01-02'])
probe = 'a'
rbsp_efw_phasef_read_v_mgse, time_range, probe=probe
end
