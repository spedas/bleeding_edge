;+
; Read the ratios of By/Bx and Bz/Bx in mGSE.
; Save to rbspx_diagBratio.
;-

pro rbsp_efw_phasef_read_diagbratio, time_range, probe=probe

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

    var = prefix+'diagBratio'
    b_mgse_smoothed = get_var_data(b_smoothed_var)
    b_ratio = b_mgse_smoothed[*,1:2]/b_mgse_smoothed[*,0]
    store_data, var, times, b_ratio

end
