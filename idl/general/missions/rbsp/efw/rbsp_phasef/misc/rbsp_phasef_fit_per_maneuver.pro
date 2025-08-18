;+
; Fit E_measure-E_model per maneuver.
;-

pro rbsp_phasef_fit_per_maneuver, time_range, probe=probe

    prefix = 'rbsp'+probe+'_'
    fillval = !values.f_nan
    xyz = constant('xyz')

    section_times = rbsp_phasef_read_fit_times(probe=probe)
    nsection = n_elements(section_times)*0.5
    root_dir = join_path([homedir(),'test_fit_e_mgse'])
    if file_test(root_dir) eq 0 then file_mkdir, root_dir
    data_dir = join_path([homedir(),'test_fit_e_mgse','rbsp'+probe])
    if file_test(data_dir) eq 0 then file_mkdir, data_dir
    sav_file = join_path([data_dir, prefix+'fit_coef.sav'])
    if file_test(sav_file) eq 1 then return
    
    log_file = join_path([data_dir, prefix+'fit_coef.txt'])
    tab = '    '
    if file_test(log_file) eq 1 then file_delete, log_file
    if file_test(log_file) eq 0 then ftouch, log_file


    fit_result = list()
    for section_id=0, nsection-1 do begin
        section_time_range = reform(section_times[section_id,*])
        if section_time_range[0] lt time_range[0] then continue
        if section_time_range[1] gt time_range[1] then continue


        fit_info = dictionary()
        fit_info.time_range = section_time_range
        

    ;---Load data.
        rbsp_efw_phasef_prepare_residue_removal, section_time_range, probe=probe
        rbsp_read_e_model, section_time_range, probe=probe, datatype='e_model_related'
        rbsp_efw_phasef_read_e_spinfit, section_time_range, probe=probe


        dis = snorm(get_var_data(prefix+'r_mgse', times=times))
        store_data, prefix+'dis', times, dis
        orbit_time_step = total(times[0:1]*[-1,1])
        index = where(dis le 2)
        perigee_times = times[time_to_range(index, time_step=1)]
        store_data, prefix+'perigee_times', 0, perigee_times
        perigee_times = get_var_data(prefix+'perigee_times')


    ;---Prepare fitting.
        b_mgse = get_var_data(prefix+'b_mgse', times=times)
        v_mgse = get_var_data(prefix+'v_mgse')
        vcoro_mgse = get_var_data(prefix+'vcoro_mgse')
        u_mgse = (v_mgse-vcoro_mgse)*1e-3

        ndim = 3
        nrec = n_elements(times)
        xxs = fltarr(ndim,nrec,ndim)
        ; For Ey.
        xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
        xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
        xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
        ; For Ez.
        xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
        xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
        xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]

        copy_data, prefix+'e_mgse', prefix+'de_mgse'
        get_data, prefix+'de_mgse', uts, dat
        index = where(finite(dat[*,1]), count)
        if count ne 0 then dat[index,0] = 0
        store_data, prefix+'de_mgse', uts, dat
        interp_time, prefix+'de_mgse', times
        yys = get_var_data(prefix+'de_mgse')
        store_data, prefix+'fit_data', times, xxs, yys


    ;---Do fit.
        ; Find the last several perigees.
        nfit_section = 10
        index = where(perigee_times[*,0] ge section_time_range[0] and $
            perigee_times[*,1] le section_time_range[1], count)
        if count eq 0 or count lt nfit_section+1 then message, 'Inconsistency ...'
        fit_time_ranges = perigee_times[index[count-1-nfit_section:count-1],*]
        nfit_time_range = n_elements(fit_time_ranges)*0.5

        get_data, prefix+'fit_data', times, xxs, yys
        time_index = []
        for jj=0,nfit_time_range-1 do begin
            index = lazy_where(times, '[]', fit_time_ranges[jj,*], count=count)
            if count eq 0 then continue
            time_index = [time_index,index]
        endfor
        xxs = xxs[*,time_index,*]
        yys = yys[time_index,*]
        uts = times[time_index]

        ; Calc fit coefs.
        fit_coef = fltarr(ndim+1,ndim)+fillval
        fit_index = [1,2]
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
        
        msg = ''
        msg += strjoin(time_string(fit_info.time_range,tformat='YYYY-MM-DD/hh:mm:ss'),'  ')+tab
        msg += strjoin(string(fit_info['y'],format='(F13.10)'),'  ')+tab
        msg += strjoin(string(fit_info['z'],format='(F13.10)'),'  ')+tab
        lprmsg, msg, log_file
        fit_result.add, fit_info
        continue


    ;---Apply fit coefs.
        get_data, prefix+'fit_data', times, xxs, yys
        foreach jj, fit_index do begin
            yy = yys[*,jj]
            res = fit_coef[0:ndim-1,jj]
            const = fit_coef[ndim,jj]
            yfit = reform(xxs[*,*,jj] ## res);+const
            store_data, prefix+'de'+xyz[jj], times, [[yy],[yfit],[yy-yfit]], $
                limits={colors:sgcolor(['red','green','blue']),labels:['old','fit','new']}
        endforeach

;        ; Remove data > 2 Re.
        vars = prefix+['dey','dez']
        ylim, vars, [-1,1]*6
        tplot_options, 'labflag', -1

;        dis = get_var_data(prefix+'dis')
;        time_index = where(dis ge 2)
;        foreach var, vars do begin
;            get_data, var, times, data
;            data[time_index,*] = fillval
;            devs = fltarr(3)
;            for jj=0,2 do devs[jj] = stddev(data[*,jj],/nan)
;            options, var, 'devs', devs
;            store_data, var, times, data
;            labels = ''+['old','fit','new']+''+string(devs,format='(F5.2)')
;            options, var, 'labels', labels
;        endforeach
;        tplot, vars, trange=section_time_range
;
;        foreach var, vars do begin
;            devs = get_setting(var, 'devs')
;            print, devs
;        endforeach

        data_file = join_path([data_dir,prefix+'fit_e_mgse_'+strjoin(time_string(section_time_range,tformat='YYYY_MMDD_hhmm_ss'),'_to_')+'.cdf'])
        stplot2cdf, vars, time_var='epoch', istp=1, filename=data_file
    endfor



    save, fit_result, filename=sav_file


;    files = file_search(join_path([data_dir,prefix+'fit_e_mgse_'+time_string(time_range[0],tformat='YYYY')+'*.cdf']))
;    cdf2tplot, files
;    vars = prefix+['dey','dez']
;    foreach var, vars do begin
;        get_data, var, times, data
;        store_data, var, times, float(data)
;        options, var, 'labels', ['old','fit','new']
;    endforeach
;    
;    plot_file = join_path([root_dir,prefix+'fit_e_mgse_'+time_string(time_range[0],tformat='YYYY')+'_v01.pdf'])
;    sgopen, plot_file, xsize=6, ysize=4
;    tplot, vars, trange=time_range
;    timebar, section_times
;    sgclose
;    
;    cdf_file = join_path([root_dir,prefix+'fit_e_mgse_'+time_string(time_range[0],tformat='YYYY')+'_v01.cdf'])
;    stplot2cdf, vars, time_var='epoch', istp=1, filename=cdf_file
    

end


time_range = time_double(['2018-01-01','2019-01-01'])
time_range = time_double(['2013-01-01','2019-01-01'])
foreach probe, ['a','b'] do rbsp_phasef_fit_per_maneuver, time_range, probe=probe


end
