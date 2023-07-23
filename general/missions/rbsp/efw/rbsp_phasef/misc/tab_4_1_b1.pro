
probes = ['a','b']
sampling_rates = 2^make_bins([9,14],1)

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'

    ; Read B1 data info.
    rbsp_efw_phasef_read_b1_time_rate, probe=probe, datatype='vb1'
    get_data, prefix+'efw_vb1_time_rate', tmp, b1_trs, b1_srs

    overall_duration = 0
    overall_count = 0
    foreach sampling_rate, sampling_rates do begin
        ; Select the time ranges for the wanted sampling rate.
        index = where(sampling_rate eq b1_srs, nsec)
        total_duration = 0d
        total_count = 0d
        if nsec ne 0 then begin
            the_trs = b1_trs[index,*]
            for sec_id=0,nsec-1 do begin
                the_tr = reform(the_trs[sec_id,*])
                duration = total(the_tr*[-1,1])
                total_duration += duration
                total_count += duration*sampling_rate
            endfor
        endif
        msg = ''
        msg += 'RBSP-'+strupcase(probe)+'  '
        msg += string(total_duration/3600d,format='(I10)')
        msg += string(total_count*1e-9,format='(F10.2)')
        lprmsg, msg

        overall_duration += total_duration
        overall_count += total_count
    endforeach

    msg = ''
    msg += 'RBSP-'+strupcase(probe)+'  '
    msg += string(overall_duration/3600d,format='(I10)')
    msg += string(overall_count*1e-9,format='(F10.2)')
    lprmsg, msg
endforeach

end
