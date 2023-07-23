;+
; Apply the time tag correction to a certain L1 tplot var.
;-

pro rbsp_efw_apply_l1_time_tag_correction, l1_var, probe=probe

    prefix = 'rbsp'+probe+'_'


;---Check out the time tag corrections we know of.
    rbsp_efw_read_l1_time_tag_irregularity, probe=probe
    get_data, prefix+'efw_l1_paired_jumps', tmp, paired_jumps
    get_data, prefix+'efw_l1_isolated_jumps', tmp, isolated_jumps


;---Shift time tags fall into the paired jumps.
    get_data, l1_var, times, data
    if n_elements(times) le 2 then return
    var_updated = 0

    nsection = n_elements(paired_jumps.section_start.current_times)
    section_time_ranges = dblarr(nsection,2)
    section_time_ranges[*,0] = paired_jumps.section_start.current_times
    section_time_ranges[*,1] = paired_jumps.section_end.current_times
    section_start_dtimes = paired_jumps.section_start.current_times-paired_jumps.section_start.previous_times
    section_end_dtimes = paired_jumps.section_end.current_times-paired_jumps.section_end.previous_times

    pad_time = 2d
    for section_id=0,nsection-1 do begin
        the_time_range = section_time_ranges[section_id,*]+[-1,1]*pad_time
        tmp = lazy_where(times, '[]', the_time_range, count=count)
        if count eq 0 then continue
        var_updated = 1

        dtimes = round(times[1:-1]-times[0:-2])

        time0 = the_time_range[0]
        time1 = the_time_range[1]
        i0 = where(dtimes eq round(section_start_dtimes[section_id]) and times ge time0 and times le time1, count0)
        i1 = where(dtimes eq round(section_end_dtimes[section_id]) and times ge time0 and times le time1, count1)
        if count0 eq 0 and count1 eq 0 then continue

        data_rate = sdatarate(times)
        the_correction = -section_start_dtimes[section_id]+data_rate
        if count1 eq 1 and count0 eq 1 then begin
            ; The easy case. The sections match.
            times[i0+1:i1] += the_correction
        endif else if count1 eq 0 and count0 eq 1 then begin
            ; We have the start of the section, the end is in the next day.
            times[i0+1:-1] += the_correction
        endif else if count0 eq 0 and count1 eq 1 then begin
            ; We have the end of the section, the start is in the previous day.
            times[0:i1] += the_correction
        endif else begin
            ; There are more sections per day.
            if count1 eq count0 then begin
                for sec_id=0,count1-1 do begin
                    times[i0[sec_id]+1:i1[sec_id]] += the_correction
                endfor
            endif
        endelse
    endfor
    if var_updated then store_data, l1_var, times, data
    dtimes = round(times[1:-1]-times[0:-2])
    index = where(abs(dtimes) eq 1, count)
    if count eq 0 then return


;---Remove time tags that are 1 sec before isolated_jumps.
    get_data, l1_var, times, data
    var_updated = 0

    nsection = n_elements(isolated_jumps.current_times)
    section_time_ranges = dblarr(nsection,2)
    section_time_ranges[*,0] = isolated_jumps.current_times ; such jumps alwasy jump backward in time, i.e., previous time is larger than current time.
    section_time_ranges[*,1] = isolated_jumps.previous_times
    for section_id=0, nsection-1 do begin
        the_time_range = section_time_ranges[section_id,*]+[-1,1]*pad_time
        tmp = lazy_where(times, '[]', the_time_range, count=count)
        if count eq 0 then continue
        var_updated = 1

        dtimes = times[1:-1]-times[0:-2]

        time0 = the_time_range[0]
        time1 = the_time_range[1]
        ; The end is the jump.
        i1 = where(round(dtimes) eq -1 and times ge time0 and times le time1, count0)
        if count0 ne 1 then stop    ; Something is wrong, must have some finite data.
        tmp = findgen(n_elements(times))
        index = where(tmp le i1[0] and times ge time0+pad_time)
        times[index] = !values.d_nan
        index = where(finite(times))
        times = times[index]
        data = data[index,*]
    endfor
    if var_updated then store_data, l1_var, times, data


;---If there's still 1-sec jump in time tag, then there's something wrong.
    dtimes = round(times[1:-1]-times[0:-2])
    index = where(abs(dtimes) eq 1, count)
    if count ne 0 then message, 'Something is wrong ...'

end



;probe = 'a'
;date = time_double('2014-01-05')
;date = time_double('2016-04-11')
;; This day doesn't work.
;probe = 'b'
;date = time_double('2015-06-12')
;prefix = 'rbsp'+probe+'_'
;var = prefix+'efw_vsvy'
;tr = date+[0,86400d]
;timespan, tr[0], total(tr*[-1,1]), /seconds
;rbsp_load_efw_waveform, probe=probe, datatype='vsvy', noclean=1
;rbsp_efw_apply_l1_time_tag_correction, var, probe=probe
;stop


;test_date = time_double('2014-07-09')

foreach probe, ['a','b'] do begin
    prefix = 'rbsp'+probe+'_'
    rbsp_efw_read_l1_time_tag_irregularity, probe=probe
    get_data, prefix+'efw_l1_paired_jumps', tmp, paired_jumps
    get_data, prefix+'efw_l1_isolated_jumps', tmp, isolated_jumps
    start_times = [paired_jumps.section_start.previous_times,isolated_jumps.previous_times]
    end_times = [paired_jumps.section_end.current_times,isolated_jumps.current_times]

    ntime_range = n_elements(start_times)
    time_ranges = dblarr(ntime_range,2)
    time_ranges[*,0] = start_times
    time_ranges[*,1] = end_times
    dates = []
    for ii=0,ntime_range-1 do begin
        dates = [dates,break_down_times(time_ranges[ii,*],'day')]
    endfor
    dates = sort_uniq(dates)
    foreach l1_type, ['esvy'] do begin
        var = prefix+'efw_'+l1_type
        foreach date, dates do begin
            ;if date ne test_date then continue
            tr = date+[0,86400d]
            timespan, tr[0], total(tr*[-1,1]), /seconds
            rbsp_load_efw_waveform, probe=probe, datatype=l1_type, noclean=1
            rbsp_efw_apply_l1_time_tag_correction, var, probe=probe
        endforeach
    endforeach
endforeach

end
