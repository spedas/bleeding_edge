;+
; Read the DC offset from L1 esvy.
; Adopted from rbsp_efw_phasef_read_e_uvw_gen_file.
; Store data to tplot var: rbspx_efw_e_uvw_dc_offset.
;-

pro rbsp_efw_phasef_read_dc_offset, time_range, probe=probe

    secofday = 86400d
    errmsg = ''

;---Read L1 esvy.
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'
    date = time_range[0]-(time_range[0] mod secofday)
    tr = time_range
    timespan, tr[0], total(tr*[-1,1]), /seconds
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', coord='uvw', noclean=1

;---Manually rule out some times.
    mask_list = list()
    mask_list.add, dictionary($
        'probe', 'a', $
        'time_range', time_double(['2017-04-13/23:00','2017-04-14/00:01']))
    mask_list.add, dictionary($
        'probe', 'b', $
        'time_range', time_double(['2015-06-12/10:00','2015-06-12/10:40']))

    l1_efw_var = prefix+'efw_esvy'
    get_data, l1_efw_var, times, e_uvw
    foreach mask, mask_list do begin
        if mask.probe ne probe then continue
        index = lazy_where(times, '[]', mask.time_range, count=count)
        if count ne 0 then times[index] = !values.f_nan
    endforeach
    index = where(finite(times))
    times = times[index]
    e_uvw = e_uvw[index,*]
    store_data, l1_efw_var, times, e_uvw


;---Implement the time correction, if necessary.
    rbsp_efw_read_l1_time_tag_correction, probe=probe
    get_data, prefix+'l1_time_tag_correction', start_times, time_ranges, corrections
    nsection = n_elements(corrections)
    get_data, l1_efw_var, times, e_uvw
    var_updated = 0
    for ii=0, nsection-1 do begin
        tmp = where(times ge time_ranges[ii,0] and times le time_ranges[ii,1], count)
        if count eq 0 then continue
        var_updated = 1
        time_step = sdatarate(times)
        dtimes = times[1:-1]-times[0:-2]
        bad_index = where(abs(dtimes) ge 0.5, count)
        if count eq 0 then bad_index = !null    ; Can have no bad index but the whole day is shifted.
        if min(times) ge time_ranges[ii,0] then i0 = 0 else begin
            foreach index, bad_index do begin
                if round(dtimes[index]) ne -round(corrections[ii]) then continue
                if abs(times[index+1]-time_ranges[ii,0]) ge time_step then continue
                i0 = index+1
            endforeach
        endelse
        if max(times) le time_ranges[ii,1] then i1 = n_elements(times) else begin
            foreach index, bad_index do begin
                if round(dtimes[index]) ne round(corrections[ii]) then continue
                if abs(times[index+1]-time_ranges[ii,1]) ge time_step then continue
                i1 = index+1
            endforeach
        endelse
        times[i0:i1-1] += corrections[ii]
    endfor
    if var_updated then store_data, l1_efw_var, times, e_uvw


;---Leap second corrections.
    rbsp_efw_read_l1_time_tag_leap_second, probe=probe
    get_data, prefix+'l1_time_tag_leap_second', start_times
    nsection = n_elements(start_times)
    get_data, l1_efw_var, times, e_uvw
    var_updated = 0
    for ii=0, nsection-1 do begin
        tmp = where(times[0] le start_times[ii] and times[-1] ge start_times[ii], count)
        if count eq 0 then continue
        var_updated = 1
        dtimes = times[1:-1]-times[0:-2]
        bad_index = where(abs(dtimes) ge 0.5, count)
        for jj=0, count-1 do begin
            i0 = bad_index[jj]
            tmp = times[0:i0]
            index = where(tmp ge times[i0+1], count)
            if count eq 0 then continue
            tmp[index] = !values.d_nan
            times[0:i0] = tmp
        endfor
        index = where(finite(times), count)
        if count eq 0 then stop    ; Something is wrong, must have some finite data.
        times = times[index]
        e_uvw = e_uvw[index,*]
    endfor
    if var_updated then store_data, l1_efw_var, times, e_uvw

    dtimes = round(times[1:-1]-times[0:-2])
    bad_index = where(abs(dtimes) eq 1, count)
    if count ne 0 then stop


;---Get rid of non-monotonic times, which sometimes show up.
    get_data, l1_efw_var, times, e_uvw
    index = uniq(times, sort(times))
    times = times[index]
    e_uvw = e_uvw[index,*]
    store_data, l1_efw_var, times, e_uvw
    
;---Move time tags to the center.
    dtime = 1d/32
    times = times-dtime
    store_data, l1_efw_var, times, e_uvw


;---Read euvw.
    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe
    var2 = prefix+'e_uvw'
    interp_time, l1_efw_var, to=var2
    
    get_data, var2, times, e_no_offset
    e_has_offset = get_var_data(l1_efw_var)
    dc_offset = e_has_offset-e_no_offset
    store_data, prefix+'efw_e_uvw_dc_offset', times, dc_offset

end
