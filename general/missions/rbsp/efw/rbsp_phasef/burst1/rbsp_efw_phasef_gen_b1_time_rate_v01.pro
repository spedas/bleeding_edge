;+
; Scan all vb1_split and mscb1_split files for time_range and data_rate.
; Needs to run on a computer with all vb1_split mscb1_split data are downloaded.
;
; data_dir. Data should be saved at data_dir/YYYY/*.cdf.
; log_file=. Save time range and sampling rate (median and mean) in texts.
; filename=. Save time_range and sampling rate (median and mean) in value in cdf.
; datatype=. can be 'vb1' or 'mscb1'.
;
; Note: median and mean are both saved for sanity check.
;   There are 2 times when they disagree. I've verified
;   that median is good, mean is off b/c data gap. -Sheng 2021-09-05.
;
; Data file procudes is used by rbsp_efw_phasef_read_b1_time_rate.
;-

pro rbsp_efw_phasef_gen_b1_time_rate_v01, data_dir, log_file=log_file, filename=cdf_file, datatype=b1_type

    if n_elements(data_dir) eq 0 then begin
        lprmsg, 'No input data directory ...'
        return
    endif

    if file_test(data_dir) eq 0 then begin
        lprmsg, 'Input data directory does not exist ...'
        return
    endif

    files = file_search(join_path([data_dir,'*','*.cdf']))
    nfile = n_elements(files)
    if nfile eq 0 then begin
        lprmsg, 'No file is found ...'
        return
    endif


    tr_list = list()
    sr_median_list = list()
    sr_mean_list = list()
    buffer = []
    time_var = 'epoch'
    time_type = 'epoch16'
    valid_srs = 2^make_bins([9,14],1)    ; valid sampling rates: 512, ..., 16,384 S/s.
    valid_dr = 1d/valid_srs              ; corresponding data rate, in sec.
    data_gap_dtime = 29d    ; We put 60 sec between mode switches, but I've seen gap of ~50 sec. Make it slightly smaller than 30 sec to deal with irregularities.
    min_sec_dur = 20d       ; in sec. The min duration of a section.
    msg = extend_string('start time',length=28)+extend_string('end time',length=28)+$
        extend_string('median S/s',length=10,left=1)+extend_string('mean S/s',length=10,left=1)
    lprmsg, msg, log_file
    nfile = n_elements(files)
    foreach file, files, file_id do begin
        ; Read in a new file.
        lprmsg, 'Processing '+file+' ...'
        ;cdf2tplot, file
        ;get_data, b1_type, next_buffer
        next_buffer = convert_time(cdf_read_var(time_var, filename=file), from=time_type,to='unix')

        ; Put it into buffer if buffer is empty or the times are connected.
        if n_elements(buffer) eq 0 then begin
            lprmsg, 'Current buffer is empty, save to buffer ...'
            buffer = next_buffer
            if file_id ne nfile-1 then continue
        endif

        if file_id ne nfile-1 then begin
            last_time = buffer[-1]
            next_time = next_buffer[0]
            dtime = next_time-last_time
            if dtime le data_gap_dtime then begin
                lprmsg, 'Merge to existing buffer ...'
                buffer = [buffer,next_buffer]
                continue
            endif
        endif


        lprmsg, 'Processing times in buffer ...'
        times = buffer
        buffer = []

        ; Remove dtimes<0, or too small.
        dtimes = times[1:-1]-times[0:-2]
        index = where(dtimes ge min(valid_dr)*0.5, count)
        if count lt 2 then continue
        times = times[index]
        ntime = n_elements(times)
        dtimes = times[1:-1]-times[0:-2]
        round_srs = 2^(-round(alog2(dtimes)))

        ; Break data into sections according to data gap.
        ; This covers the most common situation: 1 section at 1 sampling rate.
        index = where(dtimes gt data_gap_dtime, count)
        nsec = count+1
        if count eq 0 then begin
            sec_index_ranges = [[0],[ntime-1]]
        endif else begin
            sec_index_ranges = [[0,index+1],[index,ntime-1]]
        endelse
        for sec_id=0,nsec-1 do begin
            i0 = sec_index_ranges[sec_id,0]
            i1 = sec_index_ranges[sec_id,1]
            sec_times = times[i0:i1]
            sec_dtimes = dtimes[i0:i1-1]
            sec_srs = round_srs[i0:i1-1]
            uniq_srs = sort_uniq(sec_srs)

            foreach uniq_sr, uniq_srs do begin
                index = where(valid_srs eq uniq_sr, count)
                if count eq 0 then continue

                index = where(sec_srs eq uniq_sr, count)
                if count eq 0 then continue
                subsec_index_ranges = time_to_range(index,time_step=1)
                nsubsec = n_elements(subsec_index_ranges)*0.5

                ; Merge the time ranges if they are close in time.
                for subsec_id=1,nsubsec-1 do begin
                    subsec_i0 = subsec_index_ranges[subsec_id,0]
                    subsec_i1 = subsec_index_ranges[subsec_id-1,1]
                    if abs((sec_times[subsec_i1+1]-sec_times[subsec_i0])) gt min_sec_dur then continue
                    subsec_index_ranges[subsec_id-1,1] = subsec_index_ranges[subsec_id,1]
                    subsec_index_ranges[subsec_id,0] = subsec_index_ranges[subsec_id-1,0]
                endfor
                subsec_index_ranges = subsec_index_ranges[uniq(subsec_index_ranges[*,0]),*]
                subsec_index_ranges = subsec_index_ranges[uniq(subsec_index_ranges[*,1]),*]
                nsubsec = n_elements(subsec_index_ranges)*0.5

                ; Loop through each subsection.
                for subsec_id=0,nsubsec-1 do begin
                    subsec_i0 = subsec_index_ranges[subsec_id,0]
                    subsec_i1 = subsec_index_ranges[subsec_id,1]
                    subsec_tr = sec_times[[subsec_i0,subsec_i1+1]]
                    subsec_dur = total(subsec_tr*[-1,1])
                    if subsec_dur lt min_sec_dur then continue

                    sr_median = median(sec_srs[subsec_i0:subsec_i1])
                    sr_mean = 1d/mean(sec_dtimes[subsec_i0:subsec_i1],/nan)

                    msg = strjoin(time_string(subsec_tr,tformat='YYYY-MM-DD/hh:mm:ss.ffffff  '))+$
                        string(sr_median,format='(I10)')+$
                        string(sr_mean,format='(I10)')
                    lprmsg, msg, log_file
                    if n_elements(log_file) ne 0 then lprmsg, msg
                    tr_list.add, subsec_tr
                    sr_median_list.add, sr_median
                    sr_mean_list.add, sr_mean
                endfor
            endforeach
        endfor
    endforeach


    nsec = tr_list.length
    tr = reform(tr_list.toarray())
    sr_median = sr_median_list.toarray()
    sr_mean = sr_mean_list.toarray()
    index = sort(tr[*,0])
    tr = tr[index,*]
    sr_median = sr_median[index]
    sr_mean = sr_mean[index]

    cdf_save_var, 'time_range', value=tr, filename=cdf_file
    cdf_save_var, 'median_sample_rate', value=sr_median, filename=cdf_file
    cdf_save_var, 'mean_sample_rate', value=sr_mean, filename=cdf_file

end

case susrhost() of
    'shengtian@m472e.space.umn.edu': root_dir = '/Volumes/data/rbsp'
    'kersten@xwaves7.space.umn.edu': root_dir = '/Volumes/UserA/user_volumes/kersten/data_external/rbsp'
    else: message, 'Unknown usrhost: '+susrhost()+' ...'
endcase
probes = ['b','a']
b1_types = ['mscb1']
foreach b1_type, b1_types do begin
    foreach probe, probes do begin
        rbspx = 'rbsp'+probe
        data_dir = join_path([root_dir,rbspx,'l1',b1_type+'_split'])
if susrhost() eq 'shengtian@m472e.space.umn.edu' then data_dir = '/Volumes/Research/data/rbsp/'+rbspx+'/efw/l1/vb1_split'
        log_file = join_path([data_dir,rbspx+'_l1_'+b1_type+'_time_rate_v01.txt'])
        cdf_file = join_path([data_dir,rbspx+'_l1_'+b1_type+'_time_rate_v01.cdf'])
;if susrhost() eq 'kersten@xwaves7.space.umn.edu' then if file_test(cdf_file) eq 1 then continue

        file_delete, log_file, /allow_nonexistent
        ftouch, log_file
        rbsp_efw_phasef_gen_b1_time_rate_v01, data_dir, log_file=log_file, filename=cdf_file, datatype=b1_type
    endforeach
endforeach


end
