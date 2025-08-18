;+
; Read all flags for all boom_pairs.
; Adopted from rbsp_efw_get_flag_values.
;-

pro rbsp_efw_read_flags_gen_file, time, probe=probe, filename=file

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

    prefix = 'rbsp'+probe+'_'
    date = time[0]-(time[0] mod secofday)
    time_range = date+[0,secofday]
    timespan, time_range[0], total(time_range*[-1,1]), /second
    boom_pairs = ['12','34','13','14','23','24']

    ; Init flags and common_times.
    time_step = 10.
    common_times = make_bins(time_range, time_step)
    ntime = n_elements(common_times)

    ; Not all channels are used or filled.
    flag_names = [$
        'eclipse',$
        'maneuver',$
        'efw_sweep',$
        'efw_deploy',$
        'autobias',$
        'v1_saturation',$
        'v2_saturation',$
        'v3_saturation',$
        'v4_saturation',$
        'v5_saturation',$
        'v6_saturation',$
        'Espb_magnitude',$      ; not used anymore, used in rbsp_efw_make_l2_esvy_uvw.
        'Eparallel_magnitude',$ ; not used.
        'spinaxis_Bo_angle',$   ; not used.
        'magnetic_wake_'+['12','34'],$
        'boomflag1',$
        'boomflag2',$
        'boomflag3',$
        'boomflag4',$
        'boomflag5',$   ; not used.
        'boomflag6',$   ; not used.
        'charging_'+boom_pairs, $
        'charging_extreme_'+boom_pairs]
    nflag = n_elements(flag_names)
    ; Fill values for flag
    na_val = !values.f_nan     ;not applicable value
    flag_arr = fltarr(ntime,nflag)+na_val


;---Wake flags.
    rbsp_efw_phasef_read_wake_flag, time_range, probe=probe
    interp_time, prefix+'eu_wake_flag', common_times
    interp_time, prefix+'ev_wake_flag', common_times
    eu = get_var_data(prefix+'eu_wake_flag')
    ev = get_var_data(prefix+'ev_wake_flag')
    index = (where(flag_names eq 'magnetic_wake_12'))[0]
    flag_arr[*,index] = eu
    index = (where(flag_names eq 'magnetic_wake_34'))[0]
    flag_arr[*,index] = ev


;---Boom saturation.
    ; Set flag if antenna potential exceeds max value
    rbsp_efw_phasef_read_vsvy, time_range, probe=probe
    vsvy_var = prefix+'efw_vsvy_interp'
    copy_data, prefix+'efw_vsvy', vsvy_var
    interp_time, vsvy_var, common_times

    vsvy = get_var_data(vsvy_var)
    maxvolts = 195.               ;Max antenna voltage above which the saturation flag is thrown
    nboom = 6
    for ii=0,nboom-1 do begin
        flag_name = 'v'+string(ii+1,format='(I0)')+'_saturation'
        index = (where(flag_names eq flag_name))[0]
        flag_arr[*,index] = abs(vsvy[*,ii]) ge maxvolts
    endfor


;---Mild and extreme charging flags.
    vsvy = get_var_data(vsvy_var)
    rbsp_read_spice_var, time_range, probe=probe
    lshell_var = prefix+'lshell_interp'
    copy_data, prefix+'lshell', lshell_var
    interp_time, lshell_var, common_times
    lshell = get_var_data(lshell_var)

    foreach boom_pair, boom_pairs do begin
        ii = fix(strmid(boom_pair,0,1))-1
        jj = fix(strmid(boom_pair,1,1))-1
        sumpair = total(vsvy[*,[ii,jj]],2)*0.5

        ; Mild charging (also thrown when extreme_charging flag is thrown)
        charging_flag = fltarr(ntime)
        goo = where((lshell gt 4) and (sumpair gt 0),/null)
        charging_flag[goo] = 1B
        goo = where(sumpair lt -20,/null)
        charging_flag[goo] = 1B

        ; Extreme charging.
        charging_flag_extreme = fltarr(ntime)
        goo = where((lshell gt 4) and (sumpair gt 20),/null)
        charging_flag_extreme[goo] = 1B
        goo = where(sumpair lt -20,/null)
        charging_flag_extreme[goo] = 1B


        ;PAD THE CHARGING FLAG....
        ;But, we'll also remove values +/- 10 minutes at start and
        ;finish of charging times (Scott indicates that this is a good thing
        ;to do)
        padch = 10.*60.

        ;force first and last elements to be zero. This guarantees that we have
        ;charging start times before end times.
        charging_flag[0] = 0. & charging_flag[-1] = 0.

        ;Determine start and end times of charging
        chdiff = charging_flag - shift(charging_flag,1)
        chstart_i = where(chdiff eq 1,/null)
        chend_i = where(chdiff eq -1,/null)


        chunksz_sec = ceil((common_times[-1] - common_times[0])/ntime)
        chunksz_i = ceil(padch/chunksz_sec) ;number of data chunks in "padch"


        if n_elements(chstart_i) ge 1 then begin
            for i=0,n_elements(chstart_i)-1 do begin
                ;Pad charging times at beginning of charging
                if chstart_i[i]-chunksz_i lt 0 then charging_flag[0:chstart_i[i]] = 1 else $
                charging_flag[chstart_i[i]-chunksz_i:chstart_i[i]] = 1
                ;Pad charging times at end of charging
                if chend_i[i]+chunksz_i ge ntime then charging_flag[chend_i[i]:-1] = 1 else $
                charging_flag[chend_i[i]:chend_i[i]+chunksz_i] = 1
            endfor
        endif

        index = (where(flag_names eq 'charging_'+boom_pair))[0]
        flag_arr[*,index] = charging_flag
        index = (where(flag_names eq 'charging_extreme_'+boom_pair))[0]
        flag_arr[*,index] = charging_flag_extreme
    endforeach



;---Eclipse flag.
    padec = 10.*60. ;plus/minus value (sec) outside of the eclipse start and stop times for throwing the eclipse flag

    flag_index = (where(flag_names eq 'eclipse'))[0]
    flag_arr[*,flag_index] = 0
    etimes = rbsp_load_eclipse_times(probe)
    for bb=0,n_elements(etimes.estart)-1 do begin
        goo = where((common_times ge (etimes.estart[bb]-padec)) and (common_times le (etimes.eend[bb]+padec)), count)
        if count ne 0 then flag_arr[goo,flag_index] = 1
    endfor


;---Antenna deployment flag.
    dep = rbsp_efw_boom_deploy_history(date,allvals=av)

    if probe eq 'a' then begin
        ds12 = strmid(av.deploystarta12,0,10)
        ds34 = strmid(av.deploystarta34,0,10)
        ds5 = strmid(av.deploystarta5,0,10)
        ds6 = strmid(av.deploystarta6,0,10)
        de12 = strmid(av.deployenda12,0,10)
        de34 = strmid(av.deployenda34,0,10)
        de5 = strmid(av.deployenda5,0,10)
        de6 = strmid(av.deployenda6,0,10)
        deps_alltimes = time_double([av.deploystarta12,av.deploystarta34,av.deploystarta5,av.deploystarta6])
        depe_alltimes = time_double([av.deployenda12,av.deployenda34,av.deployenda5,av.deployenda6])
    endif else begin
        ds12 = strmid(av.deploystartb12,0,10)
        ds34 = strmid(av.deploystartb34,0,10)
        ds5 = strmid(av.deploystartb5,0,10)
        ds6 = strmid(av.deploystartb6,0,10)

        de12 = strmid(av.deployendb12,0,10)
        de34 = strmid(av.deployendb34,0,10)
        de5 = strmid(av.deployendb5,0,10)
        de6 = strmid(av.deployendb6,0,10)

        deps_alltimes = time_double([av.deploystartb12,av.deploystartb34,av.deploystartb5,av.deploystartb6])
        depe_alltimes = time_double([av.deployendb12,av.deployendb34,av.deployendb5,av.deployendb6])
    endelse

    ;all the dates of deployment times (note: all deployments start and
    ;end on same date)
    dep_dates = depe_alltimes-(depe_alltimes mod secofday)
    flag_index = (where(flag_names eq 'efw_deploy'))[0]
    flag_arr[*,flag_index] = 0
    goo = where(date eq dep_dates)
    if goo[0] ne -1 then begin
        for y=0,n_elements(goo)-1 do begin
            boo = where((common_times ge deps_alltimes[goo[y]]) and (common_times le depe_alltimes[goo[y]]))
            if boo[0] ne -1 then flag_arr[boo,flag_index] = 1
        endfor
    endif


;---Maneuver times.
    flag_index = (where(flag_names eq 'maneuver'))[0]
    flag_arr[*,flag_index] = 0
    m = rbsp_load_maneuver_times(probe)
    for bb=0,n_elements(m.estart)-1 do begin
        goo = where((common_times ge (m.estart[bb])) and (common_times le (m.eend[bb])))
        if goo[0] ne -1 then flag_arr[goo,flag_index] = 1
    endfor


;---Bias sweeps.
    sdt = rbsp_load_sdt_times(probe)
    bias_sweep_flag = replicate(0,ntime)
    for i=0,n_elements(sdt.sdtstart)-1 do begin $
        goo = where((common_times ge sdt.sdtstart[i]) and (common_times le sdt.sdtend[i])) & $
        if goo[0] ne -1 then bias_sweep_flag[goo] = 1
    endfor
    flag_index = (where(flag_names eq 'efw_sweep'))[0]
    flag_arr[*,flag_index] = bias_sweep_flag


;---Auto bias.
    ; Load the needed data.
    rbsp_efw_phasef_read_autobias_flag, time_range, probe=probe
    ab_flag_var = prefix+'ab_flag'
    interp_time, ab_flag_var, common_times
    flag_index = (where(flag_names eq 'autobias'))[0]
    flag_arr[*,flag_index] = get_var_data(ab_flag_var)


;---Boom flag.
    ; original boom flag is 1 for a working boom.
    ; need to flip and use 1 for bad booms.
    rbsp_efw_read_boom_flag, time_range, probe=probe
    boom_flag_var = prefix+'boom_flag'
    interp_time, boom_flag_var, common_times
    boom_flags = get_var_data(boom_flag_var)
    for boom_id=0,3 do begin
        flag_name = 'boomflag'+string(boom_id+1,format='(I0)')
        flag_index = (where(flag_names eq flag_name))[0]
        flag_arr[*,flag_index] = boom_flags[*,boom_id] ne 1
    endfor



;;---Set global flag
;;Conditions for throwing global flag
;;..........Vx or Vy, corresponding to boom pair used (e.g. V12), saturation flags are thrown
;;..........the eclipse flag is thrown
;;..........maneuver
;;..........charging flag thrown (normal or extreme charging)
;;..........antenna deploy
;;..........bias sweep
;
;    boom_ids = [strmid(boom_pair,0,1),strmid(boom_pair,1,1)]
;    flag_keys = [$
;        'eclipse', $
;        'maneuver', $
;        'efw_sweep', $
;        'efw_deploy', $
;        x'charging', $
;        x'charging_extreme', $
;        'v'+boom_ids+'_saturation', $
;        'boomflag'+boom_ids ]
;    index = []
;    foreach key, flag_keys do index = [index,where(flag_names eq key)]
;
;    flag_index = (where(flag_names eq 'global_flag'))[0]
;    flag_arr[*,flag_index] = total(flag_arr[*,index],2) ne 0

    flag_var = prefix+'efw_flags'
    store_data, flag_var, common_times, float(flag_arr)
    add_setting, flag_var, dictionary($
        'UNITS', '#', $
        'FIELDNAM', 'flags to mark bad data (flag=1)' )


;---spinaxis_Bo_angle.
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe, id='b_mgse'

    b_mgse_var = prefix+'b_mgse'
    interp_time, b_mgse_var, common_times, quadratic=1
    b_mgse = get_var_data(b_mgse_var)
    deg = constant('deg')
    b_angle = asin(b_mgse[*,0]/snorm(b_mgse))*deg
    b_angle_var = prefix+'spinaxis_b_angle'
    store_data, b_angle_var, common_times, float(b_angle)
    add_setting, b_angle_var, dictionary($
        'UNITS', 'deg', $
        'FIELDNAM', 'angle b/w B and spin axis' )


;---Espb_magnitude.
    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe
    e_uvw_var = prefix+'e_uvw'
    interp_time, e_uvw_var, common_times
    e_uvw = get_var_data(e_uvw_var)
    flag_index = (where(flag_names eq 'Espb_magnitude'))[0]
    flag_arr[*,flag_index] = snorm(e_uvw[*,0:1])


;---Save data.
    path = fgetpath(file)
    if file_test(path,/directory) eq 0 then file_mkdir, path
    data_file = file
    if file_test(data_file) eq 1 then file_delete, data_file  ; overwrite old files.

    ginfo = dictionary($
        'TITLE', 'RBSP EFW flags', $
        'TEXT', 'Generated by Sheng Tian at the University of Minnesota, adopted from rbsp_efw_get_flag_values' )
    cdf_save_setting, ginfo, filename=file
    save_var = [flag_var, b_angle_var]
    stplot2cdf, save_var, istp=1, filename=file, time_var='epoch'

    label_var = 'flag_labels'
    cdf_save_setting, 'LABL_PTR_1', label_var, filename=file, varname=flag_var
    cdf_save_var, label_var, filename=file, value=transpose(flag_names)
    settings = dictionary($
        'VAR_TYPE', 'support_data' )
    cdf_save_setting, settings, filename=file, varname=label_var

end


;stop
;probes = ['a','b']
;root_dir = join_path([rbsp_efw_phasef_local_root()])
;secofday = constant('secofday')
;foreach probe, probes do begin
;    prefix = 'rbsp'+probe+'_'
;    rbspx = 'rbsp'+probe
;    time_range = rbsp_efw_phasef_get_valid_range('flags_all', probe=probe)
;time_range = time_double(['2012-09-05','2013-01-01'])
;    days = make_bins(time_range+[0,-1]*secofday, secofday)
;    foreach day, days do begin
;        str_year = time_string(day,tformat='YYYY')
;        path = join_path([root_dir,'efw_flag','flags',rbspx,str_year])
;        base = prefix+'efw_flags_'+time_string(day,tformat='YYYY_MMDD')+'_v01.cdf'
;        file = join_path([path,base])
;;if file_test(file) eq 1 then continue
;        print, file
;        rbsp_efw_read_flags_gen_file, day, probe=probe, filename=file
;    endforeach
;endforeach
;
;stop


time_range = time_double(['2014-08-01','2014-08-02'])
time_range = time_double(['2016-01-01','2016-01-02'])
time_range = time_double(['2015-10-18','2015-10-19'])
probe = 'b'


time_range = time_double(['2012-09-25','2012-09-26'])
time_range = time_double(['2019-02-23','2019-02-24'])
time_range = time_double(['2012-09-13','2012-09-14'])
; SDT.
time_range = time_double(['2018-10-08','2018-10-09'])
; Charging flag.
time_range = time_double(['2013-06-07','2013-06-08'])

probe = 'a'
file = join_path([homedir(),'test_flag.cdf'])

rbsp_efw_read_flags_gen_file, time_range, probe=probe, filename=file

end
