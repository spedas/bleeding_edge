;+
; Fit E_measure-E_model per maneuver.
;
; time_range. Optional, used because at early stage not all data are available.
;-

function rbsp_phasef_read_fit_coef_v01, time_range, probe=probe


;---Settings and constants.
    prefix = 'rbsp'+probe+'_'
    fillval = !values.f_nan
    xyz = constant('xyz')

    rbspx = 'rbsp'+probe
    root_dir = join_path([default_local_root(),'rbsp',rbspx,'e_fit'])
    if file_test(root_dir) eq 0 then file_mkdir, root_dir


    ; Load the time of the sections.
    txt_file = join_path([root_dir,prefix+'maneuver_list_for_efit.txt'])
    section_times = rbsp_phasef_read_fit_times(probe=probe, filename=txt_file)
    nsection = n_elements(section_times)*0.5
    if n_elements(time_range) eq 0 then time_range = minmax(section_times)

    ; The file to save data.
    sav_file = join_path([root_dir, prefix+'efit_coef_v01.sav'])
    if file_test(sav_file) eq 0 then begin
        fit_list = list()
        for section_id=0, nsection-1 do begin
            section_time_range = reform(section_times[section_id,*])
            fit_info = dictionary()
            fit_info.time_range = section_time_range
            fit_list.add, fit_info
        endfor
        save, fit_list, filename=sav_file
    endif
    restore, filename=sav_file



;---Loop through the sections to see if update is needed.
    is_updated = 0
    min_nsection = 4
    n_fit_section = 10
    foreach fit_info, fit_list do begin
        section_time_range = fit_info.time_range
        if section_time_range[0] lt time_range[0] then continue
        if section_time_range[1] gt time_range[1] then continue
        if fit_info.haskey('y') and fit_info.haskey('z') then continue


    ;---Determine the time ranges for the fit.
        rbsp_efw_phasef_prepare_residue_removal, section_time_range, probe=probe
        dis = snorm(get_var_data(prefix+'r_mgse', times=times))
        store_data, prefix+'dis', times, dis
        orbit_time_step = total(times[0:1]*[-1,1])
        index = where(dis le 2)
        perigee_times = times[time_to_range(index, time_step=1)]
        store_data, prefix+'perigee_times', 0, perigee_times
        index = where(perigee_times[*,0] ge section_time_range[0] and $
            perigee_times[*,1] le section_time_range[1], count)
        if count lt min_nsection then begin
            fit_info['y'] = fltarr(4)+fillval
            fit_info['z'] = fltarr(4)+fillval
            continue
        endif else if count lt n_fit_section+1 then begin
            fit_times = perigee_times[index,*]
        endif else begin
            fit_times = perigee_times[index[count-1-n_fit_section:count-1],*]
        endelse
        fit_time_range = minmax(fit_times)


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
            if the_time_range[0] lt fit_time_range[0] then continue
            if the_time_range[1] gt fit_time_range[1] then continue
            rbsp_efw_phasef_read_e_uvw, the_time_range, probe=probe
            time_index = lazy_where(common_times,'[]',the_time_range)
            the_times = common_times[time_index]
            the_var = prefix+'e_uvw'
            interp_time, the_var, the_times
            data = cotran(get_var_data(the_var), the_times, 'uvw2mgse', probe=probe)
            e_mgse[time_index,*] = data[*,*]
            e_mgse[time_index,0] = 1
        endfor
;        ; Remove eclipse.
;        ; Do not use b/c perigee data look fine during eclipse.
;        ; Removing eclipse results in insufficient data for the fit.
        perigee_time_index = where(e_mgse[*,0] eq 1)
        xxs = xxs[*,perigee_time_index,*]
        yys = e_mgse[perigee_time_index,*]
        times = common_times[perigee_time_index]
        store_data, prefix+'fit_data', times, xxs, yys



    ;---Do fit.
        get_data, prefix+'fit_data', times, xxs, yys
        time_index = lazy_where(times, '[]', fit_time_range, count=count)
        if count eq 0 then message, 'Inconsistency ...'
        xxs = xxs[*,time_index,*]
        yys = yys[time_index,*]
        uts = times[time_index]


        ; Calc fit coefs.
        fit_coef = fltarr(ndim+1,ndim)+fillval
        foreach jj, fit_index do begin
            yy = yys[*,jj]
            xx = xxs[*,*,jj]
            index = where(finite(yy) and finite(snorm(transpose(xx))), count)
            if count lt 10 then continue

            res = regress(xx[*,index],yy[index], sigma=sigma, const=const)
            fit_coef[*,jj] = [res[*],const]

            yfit = reform(xxs[*,*,jj] ## res)+const
            store_data, prefix+'de'+xyz[jj]+'_fit', uts, [[yy],[yfit],[yy-yfit]], $
                limits={colors:sgcolor(['red','green','blue']),labels:['old','fit','new']}
        endforeach
        

        ; Save fit coefs.
        foreach jj, fit_index do fit_info[xyz[jj]] = reform(fit_coef[*,jj])
        is_updated = 1
    endforeach


    if is_updated then begin
        save, fit_list, filename=sav_file

        log_file = join_path([root_dir, prefix+'maneuver_fit_coef_v01.txt'])
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
    endif

    return, fit_list

end


foreach probe, ['a','b'] do fit_list = rbsp_phasef_read_fit_coef_v01(probe=probe)
stop


end
