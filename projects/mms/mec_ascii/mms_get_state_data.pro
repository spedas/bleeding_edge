;+
; PROCEDURE:
;         mms_get_state_data
;
; PURPOSE:
;         Helper routine for mms_load_state
;
;
; data product:
;   defatt - definitive attitude data; currently loads RAs, decl of L vector
;   defeph - definitive ephemeris data; should load position, velocity
;   predatt - predicted attitude data
;   predeph - predicted ephemeris data
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-05-25 14:40:54 -0700 (Wed, 25 May 2016) $
;$LastChangedRevision: 21203 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec_ascii/mms_get_state_data.pro $
;-
pro mms_get_state_data, probe = probe, trange = trange, tplotnames = tplotnames, $
    login_info = login_info, datatypes = datatypes, level = level, $
    local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
    no_download=no_download, pred_or_def=pred_or_def, suffix=suffix, $
    public=public

    probe = strcompress(string(probe), /rem)
    start_time = time_double(trange[0])-60*60*24.
    ;end_time = time_double(trange[1])+60*60*24.
    end_time = time_double(trange[1])

    ; check if end date is anything other than 00:00:00, if so
    ; add a day to the end time to ensure that all data is downloaded
    end_struct = time_struct(end_time)
    if (end_struct.hour GT 0) or (end_struct.min GT 0) then add_day = 60*60*24. else add_day = 0.

    start_time_str = time_string(start_time, tformat='YYYY-MM-DD')
    end_time_str = time_string(end_time+add_day, tformat= 'YYYY-MM-DD')

    ;file_dir = local_data_dir + 'mms' + probe + '/state/' + level + '/'

    idx=where(datatypes EQ 'pos' OR datatypes EQ 'vel',ephcnt)
    if ephcnt gt 0 then filetype = ['eph']
    idx=where(datatypes EQ 'spinras' OR datatypes EQ 'spindec',attcnt)
    if attcnt gt 0 then begin
        if undefined(filetype) then filetype = ['att'] else filetype = [filetype, 'att']
    endif

    for i = 0, n_elements(filetype)-1 do begin
        file_dir = local_data_dir + 'ancillary/' + 'mms' + probe + '/' + level + filetype[i] + '/'

        product = level + filetype[i]
        ;keep last iteration's file list from being appended to
        undefine, daily_names
        ;get file info from remote server
        ;if the server is contacted then a string array or empty string will be returned
        ;depending on whether files were found, if there is a connection error the
        ;neturl response code is returned instead
        if ~keyword_set(no_download) then begin

            if level EQ 'def' then begin
                ancillary_file_info = mms_get_ancillary_file_info(sc_id='mms'+probe, $
                    product=product, start_date=start_time_str, end_date=end_time_str, $
                    public=public)

                ; if pred_or_def flag was set check that files were found and/or the time frame
                ; covers the entire time requested
                if pred_or_def then begin
                    switch_to_pred = 0    ; assume files found and start/end covers time span
                    if ~is_array(ancillary_file_info) or ancillary_file_info[0] eq '' then begin
                        switch_to_pred = 1     ; no files found
                    endif else begin
                        remote_file_info = mms_parse_json(ancillary_file_info)
                        file_start = min(time_double(remote_file_info.startdate))
                        file_end = max(time_double(remote_file_info.enddate))
                        if file_start gt start_time or file_end lt end_time then switch_to_pred = 1   ; time range not covered
                    endelse

                    if switch_to_pred then begin
                        dprint, 'Definitive state data not found for this time period. Looking for predicted state data'
                        level = 'pred'
                        product = level + filetype[i]
                        ancillary_file_info = mms_get_state_pred_info(sc_id='mms'+probe, $
                            product=product, start_date=start_time_str, end_date=end_time_str, $
                            public=public)
                    endif
                endif

            endif else begin
                ancillary_file_info = mms_get_state_pred_info(sc_id='mms'+probe, $
                    product=product, start_date=start_time_str, end_date=end_time_str, $
                    public=public)
            endelse
        endif

        if is_array(ancillary_file_info) && ancillary_file_info[0] ne '' then begin
            remote_file_info = mms_parse_json(ancillary_file_info)
            doys = n_elements(remote_file_info)

            ; make sure the directory exists
            dir_search = file_search(file_dir, /test_directory)
            if dir_search eq '' then file_mkdir2, file_dir

            for doy_idx = 0, doys-1 do begin
                ; check if the file exists
                same_file = mms_check_file_exists(remote_file_info[doy_idx], file_dir = file_dir)
                if same_file eq 0 then begin
                    dprint, dlevel = 0, 'Downloading ' + remote_file_info[doy_idx].filename + ' to ' + file_dir
                    status = get_mms_ancillary_file(filename=remote_file_info[doy_idx].filename, local_dir=file_dir,public=public)
                    if status eq 0 then append_array, daily_names, file_dir + remote_file_info[doy_idx].filename
                endif else begin
                    dprint, dlevel = 0, 'Loading local file ' + file_dir + remote_file_info[doy_idx].filename
                    append_array, daily_names, file_dir + remote_file_info[doy_idx].filename
                endelse
            endfor

            ; if no remote list was found then search locally
        endif else begin
            local_files = mms_get_local_state_files(probe='mms'+probe, level= level, filetype=filetype[i], trange=[start_time, end_time])
            if is_string(local_files) then begin
                append_array, daily_names, local_files
            endif else begin
                dprint, dlevel = 0, 'No MMS ' + product + ' files found for this time period.'
                return
            endelse

        endelse

        ; figure out the type of data and read and load the data
        if filetype[i] EQ 'eph' then $
            mms_load_eph_tplot, daily_names, tplotnames = tplotnames, prefix = 'mms'+probe, level = level, $
            probe=probe, datatypes = datatypes, trange = trange, suffix=suffix
        if filetype[i] EQ 'att' then $
            mms_load_att_tplot, daily_names, tplotnames = tplotnames, prefix = 'mms'+probe, level = level, $
            probe=probe, datatypes = datatypes, trange = trange, suffix=suffix

    endfor

end