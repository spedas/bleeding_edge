;+
; Generate yearly files include:
;   1. Ey V12 V34
;   2. Ez V12 V34
;   3. Ey wake V12 V34
;   4. Ez wake V12 V34
;-

    probes = ['a','b']
    years = make_bins([2012,2019],1)
    local_root = join_path([default_local_root(),'rbsp','prelim_yearly_files'])
    foreach year, years do begin
        time_range = time_double(string(year+[0,1],format='(I4)'))
        foreach probe, probes do begin
            prefix = 'rbsp'+probe+'_'
            data_file = join_path([local_root,$
                prefix+'preliminary_e_spinfit_mgse_'+time_string(time_range[0],tformat='YYYY')+'_v01.cdf'])

        ;---Load data.
            rbsp_efw_phasef_read_e_spinfit, time_range, probe=probe
            rbsp_phasef_read_e_wake_spinfit, time_range, probe=probe
            rbsp_efw_phasef_read_e_fit, time_range, probe=probe
            bg_var = prefix+'efit_mgse'
            var_types = ['e','e_wake']
            boom_types = ['v12','v34']

        ;---Load eclipse and maneuver flags.
            rbsp_read_eclipse_flag, time_range, probe=probe
            flags = get_var_data(prefix+'eclipse_flag', times=flag_times)
            flag_time_step = total(flag_times[0:1]*[-1,1])
            nflag_time = n_elements(flag_times)
            index = where(flags eq 1, count)
            eclipse_time_ranges = (count eq 0)? !null: $
                time_to_range(flag_times[index], time_step=flag_time_step)
            neclipse = n_elements(eclipse_time_ranges)*0.5
            flags = intarr(nflag_time)
            for ii=0,neclipse-1 do begin    ; eclipse time tend to be off?
                index = lazy_where(flag_times, '[]', eclipse_time_ranges[ii,*]+[-10,5]*flag_time_step, count=count)
                if count eq 0 then continue
                flags[index] = 1
            endfor
            store_data, prefix+'eclipse_flag', flag_times, flags

            ; Maneuver.
            maneuver_time_ranges = rbsp_read_maneuver_time(time_range, probe=probe)
            nmaneuver = n_elements(maneuver_time_ranges)*0.5
            flags = intarr(nflag_time)
            for ii=0,nmaneuver-1 do begin   ; pad a little to ensure exclusion.
                index = lazy_where(flag_times, '[]', maneuver_time_ranges[ii,*]+[-2,2]*flag_time_step, count=count)
                if count eq 0 then continue
                flags[index] = 1
            endfor
            store_data, prefix+'maneuver_flag', flag_times, flags

            flags = get_var_data(prefix+'eclipse_flag')+get_var_data(prefix+'maneuver_flag')
            store_data, prefix+'flag', flag_times, flags


            save_vars = list()
            foreach var_type, var_types do begin
                in_vars = prefix+var_type+'_spinfit_mgse_'+boom_types
                out_vars = prefix+var_type+'_spinfit_'+boom_types
                bg_var2 = bg_var+'_copy'
                copy_data, bg_var, bg_var2
                interp_time, bg_var2, to=in_vars[0]
                bg = get_var_data(bg_var2)

                flags = get_var_data(prefix+'flag', times=flag_times)
                index = where(flags ge 1, count)
                get_data, in_vars[0], times
                if count ne 0 then begin
                    flag_times = flag_times[time_to_range(index,time_step=1)]
                endif else flag_times = !null
                nflag_time = n_elements(flag_times)*0.5
                for flag_id=0,nflag_time-1 do begin
                    index = lazy_where(times, '[]', flag_times[flag_id,*], count=count)
                    if count eq 0 then continue
                    times[index] = !values.d_nan
                endfor
                time_index = where(finite(times,/nan), count)
                if count eq 0 then time_index = !null


                foreach in_var, in_vars, var_id do begin
                    data = get_var_data(in_var, times=times, limits=lim)-bg
                    if n_elements(time_index) ne 0 then data[time_index,*] = !values.f_nan
                    store_data, out_vars[var_id], times, data, limits=lim
                endforeach
                options, [in_vars,out_vars], 'yrange', [-1,1]*5
                save_vars.add, out_vars, /extract
            endforeach



        ;---Save data.
            foreach save_var, save_vars, var_id do begin
                if var_id eq 0 then continue
                interp_time, save_var, to=save_vars[0]
            endforeach
            stplot2cdf, save_vars.toarray(), time_var='epoch', istp=1, filename=data_file
        endforeach
    endforeach



end
