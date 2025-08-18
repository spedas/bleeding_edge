;+
; Fix spin tone in B UVW, remove bad data.
;-

pro rbsp_fix_b_uvw, time_range, probe=probe, test=test, common_time_step=common_time_step

    prefix = 'rbsp'+probe+'_'
    b_uvw_var = prefix+'b_uvw'
    if check_if_update(b_uvw_var) then stop


    ; Mask invalid data with NaN.
    cal_state = get_var_data(prefix+'cal_state', times=uts)
    mag_valid = get_var_data(prefix+'mag_valid')
    bad_index = where(cal_state ne 0 or mag_valid eq 1, count, complement=good_index)
    fillval = !values.f_nan
    pad_time = 5.   ; sec.
    if count ne 0 then begin
        time_ranges = uts[time_to_range(bad_index,time_step=1)]
        ntime_range = n_elements(time_ranges)*0.5
        b_uvw = get_var_data(b_uvw_var, times=uts)
        for ii=0,ntime_range-1 do begin
            index = lazy_where(uts, '[]', time_ranges[ii,*]+[-1,1]*pad_time, count=count)
            if count eq 0 then continue
            b_uvw[index,*] = fillval
        endfor
        store_data, b_uvw_var, uts, b_uvw
    endif


;---Read data.
    ndim = 3
    uvw = constant('uvw')
    xyz = constant('xyz')
    if n_elements(common_time_step) eq 0 then common_time_step = 1d/16
    if common_time_step gt 1 then message, 'Cadence too low ...'
    common_times = make_bins(time_range, common_time_step)
    ncommon_time = n_elements(common_times)
    data_gap_window = 4*common_time_step
    interp_time, b_uvw_var, common_times, data_gap_window=data_gap_window
    add_setting, b_uvw_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'UVW', $
        'coord_labels', uvw )
    b_uvw = get_var_data(b_uvw_var)


;---Convert to DSC.
    rad = constant('rad')
    spin_phase_var = prefix+'spin_phase'
    rbsp_read_spin_phase, time_range, probe=probe, times=common_times
    spin_phase = get_var_data(spin_phase_var)*rad
    cost = cos(spin_phase)
    sint = sin(spin_phase)
    b_dsc = dblarr(ncommon_time,ndim)
    b_dsc_var = prefix+'b_dsc'
    b_dsc[*,0] = b_uvw[*,0]*cost-b_uvw[*,1]*sint
    b_dsc[*,1] = b_uvw[*,0]*sint+b_uvw[*,1]*cost
    b_dsc[*,2] = b_uvw[*,2]
    store_data, b_dsc_var, common_times, b_dsc
    add_setting, b_dsc_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', '#', $
        'coord', 'DSC', $
        'coord_labels', xyz )


;---Correct in DSC.
    ; Get the background field.
    section_window = 60.
    section_times = make_bins(time_range, section_window)
    nsection_time = n_elements(section_times)-1
    b_dsc_bg = fltarr(nsection_time, ndim)
    b_dsc = get_var_data(b_dsc_var)
    for ii=0,nsection_time-1 do begin
        index = lazy_where(common_times, '[]', section_times[ii:ii+1])
        for jj=0,ndim-1 do b_dsc_bg[ii,jj] = median(b_dsc[index,jj])
    endfor
    center_times = section_times[0:nsection_time-1]+section_window*0.5
    b_dsc_bg = sinterpol(b_dsc_bg, center_times, common_times, /quadratic)
    if keyword_set(test) then $
        store_data, prefix+'b_dsc_bg', common_times, b_dsc_bg, limits={colors:constant('rgb')}


    ; Remove spikes and bad data around apogee.
    dbmag = abs(snorm(b_uvw)-snorm(b_dsc_bg))
    ; Normalize with R.
    r_var = prefix+'r_gse'
    rbsp_read_orbit, time_range, probe=probe
    dis = snorm(get_var_data(r_var, times=orbit_times))
    dis = interpol(dis, orbit_times, common_times)
    perigee_shell = 2.5
    dbmag *= (dis/perigee_shell)^1.5
    ; Normalize according to range_flag.
    range_flag = get_var_data(prefix+'range_flag', times=uts)
    range_index = where(range_flag ne 1, range_count)
    if range_count ne 0 then begin
        time_ranges = uts[time_to_range(range_index,time_step=1)]
        ntime_range = n_elements(time_ranges)*0.5
        for ii=0,ntime_range-1 do begin
            index = lazy_where(common_times, '[]', time_ranges[ii,*], count=count)
            if count eq 0 then continue
            dbmag[index] *= 0.25
        endfor
    endif
    ; Remove mode switch around apogee.
    range_flag = interpol(range_flag, uts, common_times)
    index = where(range_flag ne 1 and dis ge perigee_shell, count)
    if count ne 0 then begin
        time_ranges = common_times[time_to_range(index,time_step=1)]
        ntime_range = n_elements(time_ranges)*0.5
        for ii=0,ntime_range-1 do begin
            index = lazy_where(common_times, '[]', time_ranges[ii,*]+[-1,1]*pad_time, count=count)
            if count eq 0 then continue
            dbmag[index] = fillval
        endfor
    endif
    ; Remove spikes around the perigee mode switch.
    index = where(dbmag ge 10 and dis lt perigee_shell, count)
    if count ne 0 then dbmag[index] = fillval
    ; Remove obvious bad data.
    bmag = snorm(b_uvw)
    index = where(bmag ge 3.4e4, count)
    if count ne 0 then begin
        time_ranges = common_times[time_to_range(index,time_step=1)]
        ntime_range = n_elements(time_ranges)*0.5
        for ii=0,ntime_range-1 do begin
            index = lazy_where(common_times, '[]', time_ranges[ii,*]+[-1,1]*300, count=count)
            if count eq 0 then continue
            dbmag[index] = fillval
        endfor
    endif


    ; Mask invalid data.
    index = where(finite(dbmag,/nan), count)
    if count ne 0 then begin
        b_uvw[index,*] = fillval
        b_dsc[index,*] = fillval
    endif
        


    ; Smooth to remove wobble.
    smooth_width = 11d/common_time_step
    for ii=0,ndim-1 do begin
        b_dsc[*,ii] = smooth(b_dsc[*,ii], smooth_width, /edge_mirror, /nan)
    endfor

    ; Update the data.
    b_dsc_var = prefix+'b_dsc_fix'
    store_data, b_dsc_var, common_times, b_dsc


;---Change back to UVW.
    b_dsc = get_var_data(prefix+'b_dsc_fix')
    b_uvw[*,0] = b_dsc[*,0]*cost+b_dsc[*,1]*sint
    b_uvw[*,1] =-b_dsc[*,0]*sint+b_dsc[*,1]*cost
    b_uvw[*,2] = b_dsc[*,2]
    store_data, b_uvw_var, common_times, b_uvw
    add_setting, b_uvw_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', '#', $
        'coord', 'UVW', $
        'coord_labels', uvw )


;test = 1
    two_colors = sgcolor(['blue','red'])
    if keyword_set(test) then begin
        vec_old = get_var_data(b_dsc_var)
        vec_new = get_var_data(b_dsc_var+'_fix')
        for ii=0,ndim-1 do begin
            the_var = prefix+'b'+xyz[ii]+'_dsc'
            store_data, the_var, common_times, [[vec_old[*,ii]],[vec_new[*,ii]]], $
                limits={colors:two_colors, labels:['orig','fixed'], ytitle:'(nT)'}
        endfor
        tplot_options, 'labflag', -1
        tplot_options, 'ynozero', 1
    endif

end

time_range = time_double(['2014-08-28','2014-08-29'])
time_range = time_double(['2014-04-14','2014-04-15'])   ; Bw<-9999 nT.
;time_range = time_double(['2018-09-27','2018-09-28'])   ; weird data.
probe = 'b'

time_range = time_double(['2012-10-02','2012-10-03'])   ; spike and gap.
probe = 'a'
rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'
rbsp_fix_b_uvw, time_range, probe=probe, test=test
end
