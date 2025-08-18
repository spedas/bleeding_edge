;+
; Apply the time tag correction to a certain L1 tplot var.
;-

pro rbsp_efw_phasef_apply_l1_time_tag_correction, l1_var, probe=probe

    prefix = 'rbsp'+probe+'_'


;---Check out the time tag corrections we know of.
    rbsp_efw_read_l1_time_tag_correction, probe=probe
    get_data, prefix+'l1_time_tag_correction', start_times, time_ranges, corrections
    nsection = n_elements(corrections)
    if n_elements(time_ranges) le 1 then nsection = 0
    l1_var = 'rbsp'+probe+'_efw_vsvy'
    get_data, l1_var, times, data
    var_updated = 0
    pad_time = 2d
    for ii=0, nsection-1 do begin
        tmp = where(times ge time_ranges[ii,0] and times le time_ranges[ii,1], count)
        if count eq 0 then continue
        var_updated = 1

        dtimes = round(times[1:-1]-times[0:-2])
        corr = round(corrections[ii])
        time0 = time_ranges[ii,0]-pad_time
        time1 = time_ranges[ii,1]+pad_time
        i0 = where(dtimes eq -corr and times ge time0 and times le time1, count0)
        i1 = where(dtimes eq  corr and times ge time0 and times le time1, count1)

        if count1 eq 1 and count0 eq 1 then begin
            ; The easy case. The sections match.
            times[i0+1:i1] += corrections[ii]
        endif else if count1 eq 0 and count0 eq 1 then begin
            ; We have the start of the section, the end is in the next day.
            times[i0+1:-1] += corrections[ii]
        endif else if count0 eq 0 and count1 eq 1 then begin
            ; We have the end of the section, the start is in the previous day.
            times[0:i1] += corrections[ii]
        endif else begin
            ; There are more sections per day.
            if count1 eq count0 then begin
                for sec_id=0,count1-1 do begin
                    times[i0[sec_id]+1:i1[sec_id]] += corrections[ii]
                endfor
            endif
        endelse
    endfor   
    if var_updated then store_data, l1_var, times, data
    dtimes = round(times[1:-1]-times[0:-2])
    index = where(abs(dtimes) eq 1, count)
    if count eq 0 then return


;---There are some cases are likely to be leap second.
    rbsp_efw_read_l1_time_tag_leap_second, probe=probe
    get_data, prefix+'l1_time_tag_leap_second', start_times
    nsection = n_elements(start_times)
    get_data, l1_var, times, data
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
        data = data[index,*]
    endfor
    if var_updated then store_data, l1_var, times, data


;---If there's still 1-sec jump in time tag, then there's something wrong.
    dtimes = round(times[1:-1]-times[0:-2])
    index = where(abs(dtimes) eq 1, count)
    if count ne 0 then message, 'Something is wrong ...'

end



probe = 'a'
date = time_double('2014-01-05')
date = time_double('2016-04-11')
prefix = 'rbsp'+probe+'_'
var = prefix+'efw_vsvy'
tr = date+[0,86400d]
timespan, tr[0], total(tr*[-1,1]), /seconds
rbsp_load_efw_waveform, probe=probe, datatype='vsvy', noclean=1
rbsp_efw_phasef_apply_l1_time_tag_correction, var, probe=probe
stop


;test_date = time_double('2014-07-09')
foreach probe, ['a','b'] do begin
    prefix = 'rbsp'+probe+'_'
    rbsp_efw_read_l1_time_tag_correction, probe=probe
    get_data, prefix+'l1_time_tag_correction', start_times, time_ranges, corrections
    ntime_range = n_elements(time_ranges)*0.5
    dates = []
    for ii=0,ntime_range-1 do begin
        dates = [dates,break_down_times(time_ranges[ii,*],'day')]
    endfor
    dates = sort_uniq(dates)
    var = prefix+'efw_vsvy'
    foreach date, dates do begin
;if date ne test_date then continue
        tr = date+[0,86400d]
        timespan, tr[0], total(tr*[-1,1]), /seconds
        rbsp_load_efw_waveform, probe=probe, datatype='vsvy', noclean=1
        rbsp_efw_phasef_apply_l1_time_tag_correction, var, probe=probe
    endforeach
endforeach

end
