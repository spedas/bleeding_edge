;+
; Generate yearly boom flag CDF.
;-

years = make_bins([2012,2019],1)
probes = ['a','b']
common_time_step = 10.
fillval = !values.f_nan

foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'
    foreach year, years do begin
    ;---Create overall time and flag.
        time_range = time_double(time_string(string(year+[0,1],format='(I4)')+'-01-01'))
        common_times = make_bins(time_range+[0,-1]*common_time_step, common_time_step)
        ncommon_time = n_elements(common_times)
        boom_flag = bytarr(ncommon_time)+1
        vsc = fltarr(ncommon_time)+fillval

    ;---Collect the files.
        str_year = string(year,format='(I4)')
        data_dir = join_path([default_local_root(),'sdata','rbsp',rbspx,'flags','boom',str_year])
        cdf_files = file_search(join_path([data_dir,'*v01.cdf']))
        flag_var = 'boom_flag'
        vsc_var = 'vsc_median'
        time_var = 'ut_flag'
        
        start_time = (cdf_read_var(time_var, filename=cdf_files[0]))[0]
        end_time = (cdf_read_var(time_var, filename=cdf_files[0]))[1]
        time_range = [start_time,end_time]


        request = dictionary($
            'var_list', list($
                dictionary($
                    'in_vars', ['boom_flag','vsc_median'], $
                    'out_vars', prefix+['boom_flag','vsc_median'], $
                    'time_var_name', 'ut_flag', $
                    'time_var_type', 'unix')))

        read_files, time_range, files=cdf_files, request=request
        
        the_var = prefix+vsc_var
        get_data, the_var, times, data
        index = uniq(times, sort(times))
        times = times[index]
        data = data[index]
        store_data, the_var, times, data, limits={ytitle:'(V)'}
        
        the_var = prefix+flag_var
        get_data, the_var, times, data
        index = uniq(times, sort(times))
        times = times[index]
        data = data[index,*]
        flags = total(data,2) eq 4
        store_data, the_var, times, flags, limits={ytitle: '(#)', yrange:[-0.2,1.2]}


        vars = prefix+[flag_var,vsc_var]
        yearly_file = join_path([homedir(),'yearly_boom_flag',prefix+'boom_flag_'+str_year+'_v01.cdf'])
        if file_test(yearly_file) eq 1 then file_delete, yearly_file
        stplot2cdf, vars, filename=yearly_file, time_var='epoch', istp=1
    endforeach
endforeach

end