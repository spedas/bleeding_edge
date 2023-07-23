;+
; Preprocess and load r_mgse to memory.
;-

pro rbsp_efw_phasef_read_r_mgse, time_range, probe=probe

    prefix = 'rbsp'+probe+'_'
    the_var = prefix+'r_mgse'
    if ~check_if_update(the_var, time_range) then return

    r_gse_var = prefix+'r_gse'
    rbsp_read_orbit, time_range, probe=probe

    rbsp_read_q_uvw2gse, time_range, probe=probe
    r_gse = get_var_data(r_gse_var, times=times)
    r_mgse = cotran(r_gse, times, probe=probe, 'gse2mgse')
    store_data, the_var, times, r_mgse
    add_setting, the_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'Re', $
        'short_name', 'R', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )

end

time_range = time_double(['2013-01-01','2013-01-02'])
probe = 'a'
rbsp_efw_phasef_read_r_mgse, time_range, probe=probe
end
