;+
; Fit E_measure-E_model per maneuver.
;
; time_range. Optional, used because at early stage not all data are available.
;-

function rbsp_phasef_read_fit_coef_v02, time_range, probe=probe


;---Settings and constants.
    prefix = 'rbsp'+probe+'_'
    fillval = !values.f_nan
    xyz = constant('xyz')

    rbspx = 'rbsp'+probe
    root_dir = join_path([default_local_root(),'rbsp',rbspx,'e_fit'])
    ; The file to save data.
    sav_file = join_path([root_dir, prefix+'efit_coef_v02.sav'])
    if file_test(sav_file) eq 1 then begin
        restore, sav_file
        return, fit_list
    endif


;---Load v01 fit coef and modify if needed.
    fit_list = rbsp_phasef_read_fit_coef_v01(time_range, probe=probe)
    section_times = list()
    y_coef = list()
    z_coef = list()
    foreach fit_info, fit_list do begin
        time_range = fit_info.time_range
        section_times.add, time_range
        y_coef.add, fit_info.y
        z_coef.add, fit_info.z
    endforeach
    section_times = section_times.toarray()
    y_coef = y_coef.toarray()
    z_coef = z_coef.toarray()


    ; Remove large angle.
    the_times = section_times[*,0]
    rad = constant('rad')
    max_angle = 5.*rad  ; rad
    for ii=0,2 do begin
        index = where(abs(y_coef[*,ii]) lt max_angle and y_coef[*,ii] ne 0)
        y_coef[*,ii] = interpol(y_coef[index,ii], the_times[index], the_times)
        index = where(abs(z_coef[*,ii]) lt max_angle and z_coef[*,ii] ne 0)
        z_coef[*,ii] = interpol(z_coef[index,ii], the_times[index], the_times)
    endfor
    y_coef[*,ii] = 0
    z_coef[*,ii] = 0
    store_data, prefix+'maneuver_fit_coef', section_times, y_coef, z_coef



;---Loop through the sections.
    foreach fit_info, fit_list, fit_id do begin
        section_time_range = fit_info.time_range

    ;---Determine the time ranges for the fit.
        rbsp_efw_phasef_read_wobble_free_var, section_time_range, probe=probe
        dis = snorm(get_var_data(prefix+'r_mgse', times=times))
        store_data, prefix+'dis', times, dis
        orbit_time_step = total(times[0:1]*[-1,1])
        index = where(dis le 2)
        perigee_times = times[time_to_range(index, time_step=1)]
        index = where(perigee_times[*,0] ge section_time_range[0] and $
            perigee_times[*,1] le section_time_range[1], count)
        perigee_times = perigee_times[index,*]
        store_data, prefix+'perigee_times', 0, perigee_times


    ;---Prepare data for the fit. Save all perigee data, use last 10 orbits to do fit.
        ; Prepare the model data.
        rbsp_read_e_model, section_time_range, probe=probe, datatype='e_model_related'
        b_mgse = get_var_data(prefix+'b_mgse', times=common_times)
        v_mgse = get_var_data(prefix+'v_mgse')
        vcoro_mgse = get_var_data(prefix+'vcoro_mgse')
        u_mgse = (v_mgse-vcoro_mgse)*1e-3

        ndim = 3
        ncommon_time = n_elements(common_times)
        xxs = fltarr(ndim,ncommon_time,ndim)
        ; For Ey.
        xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
        xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
        xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
        ; For Ez.
        xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
        xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
        xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]


        ; Prepare the real data.
        fit_index = [1,2]
        e_mgse = fltarr(ncommon_time,ndim)+fillval
        perigee_times = get_var_data(prefix+'perigee_times')
        nperigee_time = n_elements(perigee_times)*0.5
        for ii=0,nperigee_time-1 do begin
            the_time_range = reform(perigee_times[ii,*])
            rbsp_efw_phasef_read_e_uvw, the_time_range, probe=probe
            time_index = lazy_where(common_times,'[]',the_time_range)
            the_times = common_times[time_index]
            the_var = prefix+'e_uvw'
            interp_time, the_var, the_times
            data = cotran(get_var_data(the_var), the_times, 'uvw2mgse', probe=probe)
            e_mgse[time_index,*] = data[*,*]
            e_mgse[time_index,0] = 1
        endfor
        perigee_time_index = where(e_mgse[*,0] eq 1)
        xxs = xxs[*,perigee_time_index,*]
        yys = e_mgse[perigee_time_index,*]
        times = common_times[perigee_time_index]
        store_data, prefix+'fit_data', times, xxs, yys



    ;---See if fit reduces perigee residue.
        get_data, prefix+'fit_data', uts, xxs, yys

        ; Calc fit coefs.
        fit_coef = fltarr(ndim+1,ndim)+fillval
        fit_coef[*,1] = y_coef[fit_id,*]
        fit_coef[*,2] = z_coef[fit_id,*]
        foreach jj, fit_index do begin
            res = fit_coef[0:2,jj]
            yfit = reform(xxs[*,*,jj] ## res)
            yold = yys[*,jj]
            ynew = yold-yfit
            stddev_old = stddev(abs(yold),/nan)
            stddev_new = stddev(abs(ynew),/nan)
            if stddev_new gt stddev_old then fit_coef[*,jj] = 0
        endforeach
        fit_list[fit_id].y = fit_coef[*,1]
        fit_list[fit_id].z = fit_coef[*,2]
    endforeach

    save, fit_list, filename=sav_file
    log_file = join_path([root_dir, prefix+'maneuver_fit_coef_v02.txt'])
    tab = '    '
    if file_test(log_file) eq 1 then file_delete, log_file
    ftouch, log_file
    foreach fit_info, fit_list do begin
        msg = ''
        msg += strjoin(time_string(fit_info.time_range,tformat='YYYY-MM-DD/hh:mm:ss'),'  ')+tab
        the_y = fit_info.haskey('y')? fit_info['y']: 0
        the_z = fit_info.haskey('z')? fit_info['z']: 0
        msg += strjoin(string(the_y,format='(F13.10)'),'  ')+tab
        msg += strjoin(string(the_z,format='(F13.10)'),'  ')+tab
        lprmsg, msg, log_file
    endforeach

    return, fit_list

end


foreach probe, ['a','b'] do fit_list = rbsp_phasef_read_fit_coef_v02(probe=probe)

end
