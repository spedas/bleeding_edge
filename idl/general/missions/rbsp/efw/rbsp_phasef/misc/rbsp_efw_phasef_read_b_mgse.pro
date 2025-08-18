;+
; Preprocess and load b_mgse to memory.
;-

pro rbsp_efw_phasef_read_b_mgse, time_range, probe=probe

    prefix = 'rbsp'+probe+'_'
    the_var = prefix+'b_mgse'
    if ~check_if_update(the_var, time_range, dtime=60) then return

    ; Load B UVW.
    b_uvw_var = prefix+'b_uvw'
    if check_if_update(b_uvw_var, time_range, dtime=60) then rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'

    ; Fix wobble.
    is_fixed = get_setting(b_uvw_var, 'is_fixed', exist)
    if ~exist then need_fix = 1 else need_fix = ~is_fixed
    if need_fix then begin
        rbsp_fix_b_uvw, time_range, probe=probe
        options, b_uvw_var, 'is_fixed', 1
    endif

    ; Conver to MGSE.
    rbsp_read_q_uvw2gse, time_range, probe=probe
    b_uvw = get_var_data(prefix+'b_uvw', times=times)
    b_mgse = cotran(b_uvw, times, 'uvw2mgse', probe=probe)
    b_mgse_var = prefix+'b_mgse'
    store_data, b_mgse_var, times, b_mgse
    add_setting, b_mgse_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', 'nT', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )
        
    if probe eq 'b' then begin
        bad_time_range = time_double(['2018-09-27/04:00','2018-09-27/14:00'])
        index = lazy_where(times, '[]', bad_time_range, count=count)
        if count ne 0 then begin
            b_mgse[index,*] = !values.f_nan
            store_data, b_mgse_var, times, b_mgse
        endif
    endif


end
time_range = time_double(['2013-01-01','2013-01-02'])
time_range = time_double(['2015-12-29','2015-12-31'])   ; wrong data.
time_range = time_double(['2012-09-06','2012-09-07'])
probe = 'a'

time_range = time_double(['2018-09-27','2018-09-28'])   ; weird data.
probe = 'b'
rbsp_efw_phasef_read_b_mgse, time_range, probe=probe
end
