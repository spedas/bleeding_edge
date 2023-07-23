;+
; Save the time ranges of SDT.
;-

probes = ['a','b']
save_vars = list()
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    the_var = prefix+'sdt_time_ranges'
    save_vars.add, the_var
    if ~check_if_update(the_var) then continue
    time_range = rbsp_info('spice_data_range', probe=probe)
    rbsp_read_sdt_flag, time_range, probe=probe
    flags = get_var_data(prefix+'sdt_flag', times=times)
    time_step = total(times[0:1]*[-1,1])
    index = where(flags eq 1, count)
    sdt_time_ranges = time_to_range(times[index], time_step=time_step)
    store_data, the_var, 0, sdt_time_ranges
    
    nsdt_time_range = n_elements(sdt_time_ranges)*0.5
    for ii=0, nsdt_time_range-1 do print, time_string(reform(sdt_time_ranges[ii,*]))
endforeach


save_vars = save_vars.toarray()
tplot_save, save_vars, filename=join_path([srootdir(),'rbsp_sdt_time_ranges.tplot'])

end
