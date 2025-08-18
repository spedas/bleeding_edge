;+
; Read orbit number.
; Adopted fromrbsp_read_ect_mag_ephem.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro phasef_read_orbit_num, date, probe=probe, errmsg=errmsg, log_file=log_file


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

    data_type = 'spice'
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
    ; Try L4 data first.
    secofday = 86400d
    time_range = date+[0,secofday]
    var_name = 'orbit_num'
    del_data, var_name
    rbsp_efw_read_l4, time_range, probe=probe
    if tnames(var_name) ne '' then begin
        rename_var, var_name, to=prefix+var_name
        return
    endif
    

    timespan, date, secofday, /second
    rbsp_read_ect_mag_ephem, probe
    rename_var, prefix+'ME_orbitnumber', to=prefix+'orbit_num'
    
    ; In rare cases, this data is missing for some days.
    get_data, prefix+'orbit_num', data=dd
    if size(dd,/type) ne 8 then begin
        tr = time_range-secofday
        
        phasef_read_orbit_num, tr[0], probe=probe
        orbit_num = get_var_data(prefix+'orbit_num', times=times)
        rename_var, prefix+'orbit_num', to=prefix+'orbit_num1'

        ;timespan, tr[0], secofday, /second
        ;rbsp_read_ect_mag_ephem, probe
        ;orbit_num = get_var_data(prefix+'ME_orbitnumber')
        
        diff = orbit_num[1:-1]-orbit_num[0:-2]
        index = where(diff eq 1, count)
        if count eq 0 then begin
            perigee_times = tr[0]
            orbit_nums = orbit_num[0]
            orbit_num0 = orbit_nums[-1]
        endif else begin
            perigee_times = times[index]
            orbit_nums = orbit_num[index+1] ; The new orbit number after passing perigee.
            orbit_num0 = orbit_nums[-1]
        endelse

        ; Read one more orbit to ensure we catch the full perigee.
        rbsp_read_orbit, time_range+[-9,9]*3600, probe=probe, coord='gse'
        dis = snorm(get_var_data(prefix+'r_gse', times=uts))
        index = where(dis le 2, count)
        if count eq 0 then message, 'Invalid orbit data ...'
        perigee_time_ranges = uts[time_to_range(index,time_step=1)]
        nperigee = n_elements(perigee_time_ranges)*0.5
        perigee_uts = dblarr(nperigee)
        for perigee_id=0, nperigee-1 do begin
            index = lazy_where(uts, '[]', perigee_time_ranges[perigee_id,*])
            min_dis = min(dis[index], min_index)
            perigee_uts[perigee_id] = (uts[index])[min_index]
        endfor
        max_time = max(perigee_times)
        index = where(perigee_uts ge max_time)
        perigee_uts = [max_time,perigee_uts[index]]
        
        
        time_step = sdatarate(times)
        common_times = make_bins(time_range, time_step)
        ncommon_time = n_elements(common_times)
        data = fltarr(ncommon_time)
        nperigee_ut = n_elements(perigee_uts)-1
        for ii=0, nperigee_ut-1 do begin
            index = lazy_where(common_times, '[)', perigee_uts[ii:ii+1], count=count)
            if count eq 0 then continue
            data[index] = orbit_num0
            orbit_num0 += 1
        endfor
        store_data, prefix+'orbit_num', common_times, data
    endif
    

end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2012-09-05'
date = '2019-01-13'
date = '2016-01-01'

; No orbit num for this day.
probe = 'a'
date = '2015-06-30'
phasef_read_orbit_num, date, probe=probe
end