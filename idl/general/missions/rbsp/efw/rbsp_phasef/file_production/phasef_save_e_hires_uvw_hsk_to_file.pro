;+
; Save e_hires_hsk related vars for a given date to a given CDF.
; Adopted from rbsp_efw_make_l2_esvy_uvw.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
; filename=. A string for the CDF file where data to be saved.
; saved_vars=. Output, the vars saved in the CDF file.
;-


pro phasef_save_e_hires_uvw_hsk_to_file, date, probe=probe, filename=file, errmsg=errmsg, log_file=log_file, saved_vars=new_vars

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

    data_type = 'e_hires_uvw'
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


    ; Needs rbspx_efw_esvy_ccsds_data_DFB_config, rbspx_efw_esvy_ccsds_data_BEB_config.
    ;phasef_read_e_hires_uvw, date, probe=probe, errmsg=errmsg, log_file=log_file
    tplot_vars = prefix+'efw_esvy_ccsds_data_'+['BEB','DFB']+'_config'
    foreach var, tplot_vars do begin
        if check_if_update(var) then begin
            errmsg = 'Var does not exist: '+var+' ...'
            lprmsg, errmsg, log_file
            return
        endif
    endforeach


;---Save to CDF.
    new_vars = 'e_hires_uvw_'+['BEB','DFB']+'_config'
    foreach new_var, new_vars, var_id do begin
        tplot_var = tplot_vars[var_id]
        new_var = new_vars[var_id]
        get_data, tplot_var, times, data
        ntime = n_elements(times)

        ; Check if need to write epoch.
        vatts = cdf_read_setting(new_var, filename=file)
        time_var = vatts['DEPEND_0']
        epochs = cdf_read_var(time_var, filename=file)
        if n_elements(epochs) eq 0 then begin
            ;epochs = tplot_time_to_epoch(times, epoch16=1)
            epochs = convert_time(times, from='unix', to='epoch16')
            cdf_save_data, time_var, value=epochs, filename=file
        endif
        if n_elements(epochs) ne n_elements(times) then message, 'Inconsistent epoch and data ...'

        ; Save data.
        cdf_save_data, new_var, value=transpose(data), filename=file
    endforeach

end


file = join_path([homedir(),'test_e_hires_uvw.cdf'])
probe = 'a'
date = '2012-01-01'
date = '2012-09-05'
date = '2019-10-13'
;phasef_read_e_hires_uvw, date, probe=probe
phasef_save_e_hires_uvw_hsk_to_file, date, probe=probe, filename=file
end
