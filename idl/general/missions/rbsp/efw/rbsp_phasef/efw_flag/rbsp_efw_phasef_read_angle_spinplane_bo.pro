;+
; Read the angles between Bx mGSE and y and z axes in deg.
; Save to rbspx_angle_spinplane_Bo.
;-

pro rbsp_efw_phasef_read_angle_spinplane_bo, time_range, probe=probe

    prefix = 'rbsp'+probe+'_'
    smooth_window = 1800.   ; sec.
    rbsp_efw_phasef_read_wobble_free_var, time_range+[-1,1]*smooth_window, probe=probe, id='b_mgse'
    b_var = prefix+'b_mgse'
    rbsp_detrend, b_var, smooth_window
    b_smoothed_var = prefix+'b_mgse_smoothed'
    get_data, b_smoothed_var, times, data
    index = lazy_where(times, '[]', time_range)
    times = times[index]
    data = data[index,*]
    store_data, b_smoothed_var, times, data

    var = prefix+'angle_spinplane_Bo'
    b_mgse_smoothed = get_var_data(b_smoothed_var)
    bmag = snorm(b_mgse_smoothed)
    deg = 1d/!dtor
    angles = acos(b_mgse_smoothed[*,1:2]/bmag[*,[0,0]])*deg
    store_data, var, times, angles

end
