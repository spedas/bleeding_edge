
; /Users/shengtian/Projects/idl/spacephys/stdas/aaron_spedas_efw_code/efw/calibration_files/rbsp_efw_boom_length.pro

pro phasef_read_boom_property, date, probe=probe, errmsg=errmsg, log_file=log_file

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

    data_type = 'boom_property'
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
    timespan, date, secofday, /second
    boom_length = rbsp_efw_boom_length(probe, date)
    boom_shorting_factor = [1d,1,1]
    store_data, prefix+'boom_length', date, boom_length
    store_data, prefix+'boom_shorting_factor', date, boom_length

end
