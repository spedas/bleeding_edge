;+
; Read esvy_mgse.
; Adopted from rbsp_efw_make_l2_esvy_despun, rbsp_load_efw_esvy_mgse, rbsp_efw_vxb_subtract_crib.

; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-


pro phasef_read_esvy_despun, date, probe=probe, errmsg=errmsg, log_file=log_file


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

    data_type = 'esvy_despun'
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
    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe
    rbsp_efw_read_q_uvw2gse, time_range, probe=probe
    ; UVW to MGSE
    e_uvw_var = prefix+'e_uvw'
    e_uvw = get_var_data(e_uvw_var, times=times)
    e_mgse = cotran(e_uvw, times, 'uvw2mgse', probe=probe)

    ; rbspx_[emod,evxb,ecoro].
    rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
    evxb_var = prefix+'evxb_mgse'
    interp_time, evxb_var, times
    evxb_mgse = get_var_data(evxb_var)

    esvy_despun = e_mgse-evxb_mgse
    esvy_despun_var = prefix+'esvy_mgse'
    store_data, esvy_despun_var, times, esvy_despun

end

probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2019-10-13'
phasef_read_esvy_despun, date, probe=probe
end
