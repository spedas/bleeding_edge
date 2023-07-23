;+
; Read spinaxis_gse related vars.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro phasef_read_spinaxis_gse, date, probe=probe, errmsg=errmsg, log_file=log_file

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

    data_type = 'spinaxis_gse'
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
    rbsp_efw_read_q_uvw2gse, time_range, probe=probe

    q_uvw2gse_var = prefix+'q_uvw2gse'
    get_data, q_uvw2gse_var, times, q_uvw2gse
    m_uvw2gse = qtom(q_uvw2gse)
    spinaxis_gse = m_uvw2gse[*,*,2]
    spinaxis_gse_var = prefix+'spinaxis_gse'
    store_data, spinaxis_gse_var, times, spinaxis_gse


end


probe = 'a'
date = '2012-01-01'
date = '2014-01-01'
;date = '2019-10-13'
phasef_read_spinaxis_gse, date, probe=probe
end
