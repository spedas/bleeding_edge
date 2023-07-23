;+
; Scan all vb1_split files for time_range and data_rate.
; Needs to run on a computer with all vb1 or vb1_split data are downloaded.
;
; data_dir. Data should be saved at data_dir/YYYY/*.cdf.
;-

pro rbsp_efw_phasef_scan_vb1_data_rate, data_dir, log_file=log_file, filename=cdf_file

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
    valid_sr = 2^make_bins([9,14],1)    ; valid sampling rates: 512, ..., 16,384 S/s.
    valid_dr = 1d/valid_sr              ; corresponding data rate, in sec.
    data_gap_dtime = 59d    ; it's actually 60 sec, use 59 to allow some fluctuations around 60 sec.
    msg = extend_string('start time',length=28)+extend_string('end time',length=28)+$
        extend_string('median S/s',length=10,left=1)+extend_string('mean S/s',length=10,left=1)
    lprmsg, msg, log_file
    nfile = n_elements(files)
    foreach file, files, file_id do begin
        ; Read in a new file.
        lprmsg, 'Processing '+file+' ...'
        cdf2tplot, file
        get_data, 'vb1', next_buffer
        ;next_buffer = convert_time(cdf_read_var(time_var, filename=file), from=time_type,to='unix')
        
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
        index = where(dtimes gt min(valid_dr)*0.5, count)
        if count lt 2 then continue
        times = times[index]
        ntime = n_elements(times)
        dtimes = times[1:-1]-times[0:-2]
        
        ; Locate data gaps.
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
            the_tr = times[[i0,i1]]
            round_srs = 2^(-round(alog2(dtimes[i0:i1-1])))
            sr_median = median(round_srs)
            srs = 2^(-alog2(dtimes[i0:i1-1]))
            sr_mean = mean(srs,/nan)
            
            msg = strjoin(time_string(the_tr,tformat='YYYY-MM-DD/hh:mm:ss.ffffff  '))+$
                string(sr_median,format='(I10)')+$
                string(sr_mean,format='(I10)')
            lprmsg, msg, log_file
            if n_elements(log_file) ne 0 then lprmsg, msg
            tr_list.add, the_tr
            sr_median_list.add, sr_median
            sr_mean_list.add, sr_mean
        endfor
    endforeach


    nsec = tr_list.length
    tr = reform(tr_list.toarray())
    sr_median = sr_median_list.toarray()
    sr_mean = sr_mean_list.toarray()
    cdf_save_var, 'time_range', value=tr, filename=cdf_file
    cdf_save_var, 'median_sample_rate', value=sr_median, filename=cdf_file
    cdf_save_var, 'mean_sample_rate', value=sr_mean, filename=cdf_file

end

case susrhost() of
    'shengtian@m472e.space.umn.edu': root_dir = '/Volumes/data/rbsp'
    'kersten@xwaves7.space.umn.edu': root_dir = '/Volumes/UserA/user_volumes/kersten/data_external/rbsp'
    else: message, 'Unknown usrhost: '+susrhost()+' ...'
endcase
probes = ['a','b']
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    data_dir = join_path([root_dir,rbspx,'l1','vb1_split'])
;data_dir = '/Volumes/Research/data/rbsp/'+rbspx+'/efw/l1/vb1_split'
    log_file = join_path([data_dir,rbspx+'_l1_vb1_time_rate.txt'])
    cdf_file = join_path([data_dir,rbspx+'_l1_vb1_time_rate.cdf'])
    
    file_delete, log_file, /allow_nonexistent
    ftouch, log_file
    rbsp_efw_phasef_scan_vb1_data_rate, data_dir, log_file=log_file, filename=cdf_file
endforeach


end
