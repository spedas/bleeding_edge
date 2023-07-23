;+
; Add orbit_num to L4 data.
;-

pro phasef_add_orbit_num_to_l4, day, probe=probe, filename=file

    if n_elements(file) eq 0 then return
    if file_test(file) eq 0 then return

    cdf_var = 'orbit_num'
    time_var = 'epoch'
    if ~cdf_has_var(time_var, filename=file) then return
    if cdf_has_var(cdf_var, filename=file) then return

    if n_elements(probe) eq 0 then return
    prefix = 'rbsp'+probe+'_'
    skeleton = join_path([srootdir(),prefix+'efw-l2_e-spinfit-mgse_00000000_v03.cdf'])
    if file_test(skeleton) eq 0 then return

    epochs = cdf_read_var(time_var, filename=file)
    times = convert_time(epochs, from='epoch16', to='unix')
    phasef_read_orbit_num, day, probe=probe
    tplot_var = prefix+'orbit_num'
    interp_time, tplot_var, times
    settings = cdf_read_setting(cdf_var, filename=skeleton)
    settings['DEPEND_0'] = time_var

    ; Treat irregularities.
    get_data, tplot_var, times, data
    data = round(data)
    index = where(data le 0, count)
    if count ne 0 then begin
        sections = time_to_range(index,time_step=1)
        nsection = n_elements(sections)*0.5
        for sec_id=0,nsection-1 do begin
            data_id = sections[sec_id,0]-1
            if data_id lt 0 then data_id = sections[sec_id,1]+1
            ; if data_id is <0 or >ndata, then there must be something wrong. will stop with an error.
            data[sections[sec_id,0]:sections[sec_id,1]] = data[data_id]
        endfor
    endif

    index = where(data le 0, count)
    if count ne 0 then stop
    cdf_save_var, cdf_var, value=data, filename=file
    cdf_save_setting, settings, filename=file, varname=cdf_var

end
