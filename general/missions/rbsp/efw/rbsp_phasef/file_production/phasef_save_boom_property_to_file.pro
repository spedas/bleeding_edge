;+
; Save boom property to file.
;-

pro phasef_save_boom_property_to_file, date, probe=probe, filename=file, $
    errmsg=errmsg, log_file=log_file, saved_vars=new_vars


    errmsg = ''

;---Check input.
    if n_elements(file) eq 0 then begin
        errmsg = 'cdf file is not set ...'
        lprmsg, errmsg, log_file
        return
    endif
    if file_test(file) eq 0 then begin
        errmsg = 'file does not exist ...'
        lprmsg, errmsg, log_file
        return
    endif

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


;---Check data availability.
    secofday = 86400d
    time_range = date+[0,secofday]
    timespan, date, secofday, /second

    ; Needs rbspx_boom_length, rbspx_boom_shorting_factor.
    ;phasef_read_boom_property, date, probe=probe, errmsg=errmsg, log_file=log_file
    tplot_vars = prefix+['boom_length','boom_shorting_factor']
    foreach var, tplot_vars do begin
        if check_if_update(var) then begin
            errmsg = 'Var does not exist: '+var+' ...'
            lprmsg, errmsg, log_file
            return
        endif
    endforeach


;---Save to CDF.
    new_vars = ['e_boom_length','e_shorting_factor']
    foreach new_var, new_vars, var_id do begin
        tplot_var = tplot_vars[var_id]
        new_var = new_vars[var_id]
        get_data, tplot_var, times, data
        ntime = n_elements(times)

        ; Save data.
        cdf_save_data, new_var, value=data, filename=file
        cdf_save_setting, 'VAR_TYPE', 'data', varname=new_var, filename=file
    endforeach

end
