;+
; Apply wake effect correction to e_uvw.
;-

pro rbsp_efw_phasef_read_wake_flag_gen_file, time, probe=probe, filename=file

;---Check inputs.
    if n_elements(file) eq 0 then begin
        errmsg = handle_error('No output file ...')
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif

    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif


;---Constants and settings.
    secofday = 86400d
    errmsg = ''
    del_data, '*'


;---Load E UVW.
    rbspx = 'rbsp'+probe
    date = time[0]-(time[0] mod secofday)
    time_range = date+[0,secofday]
    long_time_range = time_range+[-1,1]*60d
    rbsp_efw_phasef_read_e_uvw, long_time_range, probe=probe


;---Settings.
    spin_period = rbsp_info('spin_period')
    const_periods = spin_period/[1.,2,3,4]
    prefix = 'rbsp'+probe+'_'
    min_data_ratio = 0.5    ; Needs more than this amount of data.
    ndim = 3
    xyz = constant('xyz')
    uvw = constant('uvw')

    time_step = 1d/16
    common_times = make_bins(long_time_range, time_step)
    e_uvw_var = prefix+'e_uvw'
    interp_time, e_uvw_var, common_times
    stplot_split, e_uvw_var, newname=prefix+'e'+uvw, colors=[0,0,0]
    components = ['u','v']


;---Do wavelet analysis at the target freqs.
    foreach component, components do begin
        comp_var = prefix+'e'+component

    ;---Calculate cwt.
        cwt_var = comp_var+'_cwt'
        target = wake_effect_init_target_scales(spin_period)
        target_periods = target['periods']
        target_scales = target['scales']
        ntarget_scale = target['nscale']
        if check_if_update(cwt_var, time_range) then begin
            calc_psd, comp_var, scales=target_scales
        endif

    ;---Calculate the amplitude.
        amp_var = comp_var+'_amp'
        duration = 120. ; about 10x11 sec.
        if check_if_update(amp_var, time_range) then begin
            nsection = round(secofday/duration)
            section_times = smkarthm(time_range[0], duration, nsection, 'x0')+duration*0.5
            amps = dblarr(nsection,ntarget_scale)

            edata = get_var_data(comp_var)
            cwt = get_var_data(cwt_var)
            ww = cwt.w_nj
            s2t = cwt.s2t
            cdelta = cwt.cdelta
            dt = cwt.dt

            foreach time, section_times, ii do begin
                section_time_range = time+[-0.5,0.5]*duration
                index = lazy_where(common_times, section_time_range, count=N)
                uts = common_times[index]
                ees = edata[index]
                wps = abs(ww[index,*])^2
                gws = total(wps,1)/N
                psd = gws*2*s2t*dt/cdelta
                amps[ii,*] = sqrt(psd)
            endforeach
            store_data, amp_var, section_times, amps, target_periods
            add_setting, amp_var, /smart, {$
                ytitle: 'Period (sec)', $
                yrange: [1,20], $
                zrange: [0.05,5], $
                zlog: 1, $
                display_type: 'spec', $
                unit: '[mV/m] /Hz!U1/2!N', $
                constant: const_periods, $
                const_color: sgcolor('white'), $
                short_name: '|E|'}
            options, amp_var, 'no_interp', 0
            options, amp_var, 'x_no_interp', 1
            options, amp_var, 'y_no_interp', 0
        endif


    ;---Calculate the flag.
        amps = get_var_data(amp_var, times=section_times)
        nsection = n_elements(section_times)
        bad_data_flags = bytarr(nsection)   ; 1 for bad data.
        bg_index = [2,7,9,12]
        xf_index = [4,8,10]
        foreach time, section_times, ii do begin
            target_amp = reform(amps[ii,*])

        ;---Calculate spectral peak.
            xf_bg = interpol(target_amp[bg_index], target_periods[bg_index], target_periods[xf_index])
            xf_height = target_amp[xf_index]-xf_bg
            xf_ratio = target_amp[xf_index]/xf_bg

        ;---Identify peaks.
            min_peak_ratio = [2,1.3,1.3]
            xf_have_peak = xf_ratio ge min_peak_ratio
            have_1f_peak = xf_have_peak[0]
            have_2f_peak = xf_have_peak[1]
            have_3f_peak = xf_have_peak[2]

        ;---Tell good or bad.
            amp_3f = target_amp[xf_index[2]]
            amp_2f = target_amp[xf_index[1]]
            amp_1f = target_amp[xf_index[0]]
            is_bad = have_3f_peak and (amp_3f ge 0.2) and (amp_2f lt amp_3f) or (amp_2f ge amp_1f)
            bad_data_flags[ii] = is_bad
        endforeach

        ; Flip isolated flags.
        ; Change 1-0-1 to 1-1-1.
        iso_index = list()
        for ii=1, nsection-2 do begin
            if bad_data_flags[ii] eq 1 then continue
            if bad_data_flags[ii-1]+bad_data_flags[ii+1] eq 2 then iso_index.add, ii
        endfor
        if n_elements(iso_index) gt 0 then begin
            iso_index = iso_index.toarray()
            bad_data_flags[iso_index] = 1
        endif
        ; Change 0-1-0 to 0-0-0.
        iso_index = list()
        for ii=1, nsection-2 do begin
            if bad_data_flags[ii] eq 0 then continue
            if bad_data_flags[ii-1]+bad_data_flags[ii+1] eq 0 then iso_index.add, ii
        endfor
        if n_elements(iso_index) gt 0 then begin
            iso_index = iso_index.toarray()
            bad_data_flags[iso_index] = 0
        endif

        ; Extend by 1 duration.
        index = where(bad_data_flags eq 1, count)
        for ii=0, count-1 do begin
            i0 = index[ii]-1 > 0
            i1 = index[ii]+1 < nsection-1
            bad_data_flags[i0:i1] = 1
        endfor
        ; Change 1-0-1 to 1-1-1.
        iso_index = list()
        for ii=1, nsection-2 do begin
            if bad_data_flags[ii] eq 1 then continue
            if bad_data_flags[ii-1]+bad_data_flags[ii+1] eq 2 then iso_index.add, ii
        endfor
        if n_elements(iso_index) gt 0 then begin
            iso_index = iso_index.toarray()
            bad_data_flags[iso_index] = 1
        endif

        ; Treat edges.
        bad_data_flags[0] = bad_data_flags[1]
        bad_data_flags[nsection-1] = bad_data_flags[nsection-2]

        flag_var = comp_var+'_wake_flag'
        store_data, flag_var, section_times, bad_data_flags
        add_setting, flag_var, /smart, {$
            display_type: 'scalar', $
            yrange: [-0.2,1.2], $
            yticks: 1, $
            ytickv: [0,1], $
            yminor: 0, $
            ytitle: '', $
            short_name: 'Bad E'}

        ; Convert to full time resolution.
        bad_data_flags = interpol(bad_data_flags, section_times, common_times) ne 0
        store_data, flag_var, common_times, bad_data_flags


    ;---Remove 2f and 3f.
        f1_index = [3,4,5]
        badf_index = [6,7,8,9,10,11,12]
        get_data, cwt_var, 0, cwt
        edata = get_var_data(comp_var, limit=lim)

        f1_e = wavelet_reconstruct(cwt, index=f1_index)
        edata2 = f1_e
    ;    f23_e = wavelet_reconstruct(cwt, index=badf_index)
    ;    edata2 = edata-f23_e

        comp_var_new = comp_var+'_fixed'
        store_data, comp_var_new, common_times, edata2, limit=lim
        options, comp_var_new, 'labels', 'E fixed'
        options, comp_var_new, 'colors', 0

        comp_var_combo = comp_var+'_combo'
        store_data, comp_var_combo, common_times, [[edata],[edata2]], limit=lim
        options, comp_var_combo, 'labels', ['E orig','E fixed']
        options, comp_var_combo, 'colors', [6,0]
    endforeach


    get_data, prefix+'eu_wake_flag', times, eu_wake_flag, limits=lim
    get_data, prefix+'ev_wake_flag', times, ev_wake_flag
    wake_flag = eu_wake_flag and ev_wake_flag
    store_data, prefix+'wake_flag', times, wake_flag, limits=lim


;---Trim data to wanted time.
    time_index = lazy_where(common_times,'[)', time_range)
    common_times = common_times[time_index]
    foreach var, prefix+['eu_wake_flag','ev_wake_flag','eu_fixed','ev_fixed','ew'] do begin
        data = get_var_data(var)
        store_data, var, common_times, data[time_index,*]
    endforeach


;---Save data.
    if file_test(file) eq 1 then file_delete, file

    time_var = 'unix_time'
    cdf_save_var, time_var, value=common_times, filename=file
    settings = dictionary($
        'VAR_TYPE', 'data', $
        'unit', 'sec', $
        'time_var_type', 'unix')
    cdf_save_setting, varname=time_var, filename=file, settings

    foreach component, components do begin
        comp_var = prefix+'e'+component

        ; Save the flag.
        flag_var = comp_var+'_wake_flag'
        bad_data_flags = byte(get_var_data(flag_var, limits=lim))
        the_var = flag_var
        cdf_save_var, the_var, value=bad_data_flags, filename=file
        settings = dictionary(lim)
        settings['depend_0'] = time_var
        settings['VAR_TYPE'] = 'data'
        cdf_save_setting, varname=the_var, filename=file, settings

        ; Save the efield at spin periods.
        fix_data_var = comp_var+'_fixed'
        edata = float(get_var_data(fix_data_var, limits=lim))
        the_var = fix_data_var
        cdf_save_var, the_var, value=edata, filename=file
        settings = dictionary(lim)
        settings['depend_0'] = time_var
        settings['VAR_TYPE'] = 'data'
        cdf_save_setting, varname=the_var, filename=file, settings
    endforeach
    the_var = prefix+'ew'
    edata = float(get_var_data(the_var))
    cdf_save_var, the_var, value=edata, filename=file
    settings['depend_0'] = time_var
    settings['VAR_TYPE'] = 'data'
    cdf_save_setting, varname=the_var, filename=file, settings

end


;probes = ['a']
;root_dir = join_path([default_local_root(),'rbsp'])
;foreach probe, probes do begin
;    prefix = 'rbsp'+probe+'_'
;    rbspx = 'rbsp'+probe
;    time_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-14']): time_double(['2012-09-08','2019-07-16'])
;    days = make_bins(time_range, constant('secofday'))
;    foreach day, days do begin
;        str_year = time_string(day,tformat='YYYY')
;        path = join_path([root_dir,rbspx,'wake_flag',str_year])
;        base= 'rbsp'+probe+'_efw_wake_flag_'+time_string(day,tformat='YYYY_MMDD')+'_v02.cdf'
;        file = join_path([path,base])
;        if file_test(file) eq 1 then continue
;        rbsp_efw_phasef_read_wake_flag_gen_file, day, probe=probe, filename=file
;    endforeach
;endforeach
;stop



time = time_double('2013-05-01')
probe = 'a'
file = join_path([homedir(),'test.cdf'])
if file_test(file) eq 1 then file_delete, file
rbsp_efw_phasef_read_wake_flag_gen_file, time, probe=probe, filename=file
end
