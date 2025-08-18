;+
; Read EFW quality, which is an older version of flags_all.
; Adopted from rbsp_efw_make_l2_esvy_uvw.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro phasef_read_efw_qual, date, probe=probe, errmsg=errmsg, log_file=log_file

    errmsg = ''


;---Check input.
    if n_elements(probe) eq 0 then begin
        errmsg = 'No input probe ...'
        lprmsg, errmsg, log_file
        return
    endif
    if probe ne 'a' and probe ne 'b' then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        lprmsg, errmsg, log_file
        return
    endif
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    data_type = 'efw_qual'
    valid_range = phasef_get_valid_range(data_type, probe=probe)
    if n_elements(date) eq 0 then begin
        errmsg = 'No input date ...'
        lprmsg, errmsg, log_file
        return
    endif
    if size(date,/type) eq 7 then date = time_double(date)
    if product(date-valid_range) gt 0 then begin
        errmsg = 'Input date: '+time_string(date,tformat='YYYY-MM-DD')+' is out of valid range ...'
        lprmsg, errmsg, log_file
        return
    endif

;---Load data.
    secofday = 86400d
    time_range = date+[0,secofday]
    rbsp_efw_read_flags, time_range, probe=probe, errmsg=errmsg
    time_step = 5d
    common_times = make_bins(time_range+[0,-1]*time_step, time_step)
    ntime = n_elements(common_times)
    ndim = 20
    flag_var = prefix+'efw_flags'
    flags = intarr(ntime,ndim)-2
    ; Look-up table for quality flags
    ;  0: global_flag
    ;  1: eclipse
    ;  2: maneuver
    ;  3: efw_sweep
    ;  4: efw_deploy
    ;  5: v1_saturation
    ;  6: v2_saturation
    ;  7: v3_saturation
    ;  8: v4_saturation
    ;  9: v5_saturation
    ; 10: v6_saturation
    ; 11: Espb_magnitude
    ; 12: Eparallel_magnitude
    ; 13: magnetic_wake
    ; 14: undefined
    ; 15: undefined
    ; 16: undefined
    ; 17: undefined
    ; 18: undefined
    ; 19: undefined


    ; Flags set are: eclipse, saturation V1-V6, Espb_magnitude.
    the_index = [1,5,6,7,8]
    map_index = [0,5,6,7,8]
    if errmsg eq '' then begin
        all_flags = get_var_data(flag_var, at=common_times)
        index = where(finite(all_flags,/nan), count)
        if count ne 0 then all_flags[index] = 0
        all_flags = all_flags ne 0
        flags[*,the_index] = all_flags[*,map_index]
    endif

    ; Global flag is triggered by eclipse, saturation V1-V4.
    flags[*,0] = total(abs(flags[*,the_index]),2) ne 0
    efw_qual_var = prefix+'efw_qual'
    store_data, efw_qual_var, common_times, flags

end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2012-09-05'
date = '2019-01-13'
date = '2016-01-01'
phasef_read_efw_qual, date, probe=probe
end
