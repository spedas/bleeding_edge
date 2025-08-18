;+
; Read diag related vars.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro phasef_read_diag_var, date, probe=probe, errmsg=errmsg, log_file=log_file


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

    data_type = 'diag_var'
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


;    smooth_window = 1800.   ; sec.
;    secofday = 86400d
;    time_range = date+[0,secofday]
;    rbsp_efw_phasef_prepare_residue_removal, time_range+[-1,1]*smooth_window, probe=probe, id='b_mgse'
;    b_var = prefix+'b_mgse'
;    rbsp_detrend, b_smoothed_var, smooth_window
;    b_smoothed_var = prefix+'b_mgse_smoothed'
;
;
;    b_mgse_smoothed = get_var_data(prefix+'b_mgse_smoothed', times=times)
;    byz2bx = abs(b_mgse_smoothed[*,1:2]/b_mgse_smoothed[*,[0,0]])
;    store_data, prefix+'diag_bratio', times, byz2bx

    secofday = 86400d
    time_range = date+[0,secofday]
    rbsp_efw_read_l4, time_range, probe=probe
    rename_var, 'diagBratio', to=prefix+'diag_bratio'
end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2019-10-13'
phasef_read_diag_var, date, probe=probe
end