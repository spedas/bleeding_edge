;+
; Read EFW housekeeping data, including usher, gaurd, ibias.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro phasef_read_efw_hsk, date, probe=probe, errmsg=errmsg, log_file=log_file

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

    data_type = 'efw_hsk'
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


;;---Load data.
;    secofday = 86400d
;    time_range = date+[0,secofday]
;    timespan, date, secofday, /second
;    ; rbspx_efw_hsk_beb_analog_IEFI_[GUARD,USHER,IBIAS].
;    rbsp_load_efw_hsk, probe=probe, get_support_data=0
;
;    suffix = string(findgen(6)+1,format='(I0)')
;    vars = prefix+'efw_hsk_beb_analog_IEFI_IBIAS'+suffix
;    get_data, vars[0], times
;    ntime = n_elements(times)
;    if ntime eq 1 then begin
;        errmsg = 'No valid data ...'
;        lprmsg, errmsg, log_file
;        return
;    endif
;    ndim = n_elements(suffix)
;    data = fltarr(ntime,ndim)
;    foreach var, vars, var_id do begin
;        data[*,var_id] = get_var_data(var)
;    endforeach
;    store_data, prefix+'ibias', times, data

;---Load data.
    secofday = 86400d
    time_range = date+[0,secofday]
    rbsp_efw_read_l4, time_range, probe=probe

    old_vars = prefix+['bias_current','usher_voltage','guard_voltage']
    new_vars = prefix+['ibias','usher','guard']
    foreach old_var, old_vars, var_id do begin
        new_var = new_vars[var_id]
        rename_var, old_var, to=new_var
    endforeach


end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2012-09-05'
date = '2019-01-13'
date = '2016-01-01'
phasef_read_efw_hsk, date, probe=probe
end
