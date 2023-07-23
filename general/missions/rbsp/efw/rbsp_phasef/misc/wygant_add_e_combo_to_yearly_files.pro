;+
; Add Ey V13, V14, V23, V24
; Add Ez V13, V14, V23, V24
;-


    probes = ['a','b']
    years = [2015,2016,2017,2018,2019]
    local_root = join_path([default_local_root(),'rbsp','prelim_yearly_files'])
    pairs = ['13','14','23','24']
    time_var = 'epoch'
    foreach year, years do begin
        time_range = time_double(string(year+[0,1],format='(I4)'))
        foreach probe, probes do begin
            prefix = 'rbsp'+probe+'_'
            data_file1 = join_path([local_root,$
                prefix+'preliminary_e_spinfit_mgse_'+time_string(time_range[0],tformat='YYYY')+'_v01.cdf'])
            data_file = join_path([local_root,$
                prefix+'preliminary_e_spinfit_mgse_'+time_string(time_range[0],tformat='YYYY')+'_v02.cdf'])
            
            
            if file_test(data_file1) eq 0 then continue
            file_copy, data_file1, data_file, /overwrite
            
            times = sfmepoch(cdf_read_var(time_var, filename=data_file),'unix')
            foreach pair, pairs do begin
                var = prefix+'e_spinfit_v'+pair
                if cdf_has_var(var, filename=data_file) then continue

                var2 = prefix+'e_spinfit_mgse_v'+pair
                if cdf_has_var(var2, filename=data_file) then begin
                    edata = float(cdf_read_var(var2, filename=data_file))
                    cdf_del_var, var2, filename=data_file
                endif else begin
                    rbsp_efw_phasef_read_e_spinfit_diagonal, time_range, probe=probe, pairs=pair, remove_perigee=1
                    interp_time, var2, times
                    edata = float(get_var_data(var2))
                endelse
                cdf_save_var, var, value=edata, filename=data_file
                settings = dictionary($
                    'VAR_TYPE', 'data', $
                    'DEPEND_0', time_var, $
                    'UNIT', 'mV/m', $
                    'time_var_type', 'epoch' )
                cdf_save_setting, settings, varname=var, filename=data_file
            endforeach
        endforeach
    endforeach

end
