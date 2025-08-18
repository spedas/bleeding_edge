;+
; Some files do not have the correct L1 time tag correction.
; Reprocess thoes files.
;-

probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
;root_dir = join_path([homedir(),'data','rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    rbsp_efw_read_l1_time_tag_correction, probe=probe
    get_data, prefix+'l1_time_tag_correction', start_times, time_ranges, corrections
    ntime_range = n_elements(time_ranges)*0.5
    for ii=0,ntime_range-1 do days = [days,break_down_times(time_ranges[ii,*],'day')]
    days = time_string(days,tformat='YYYY-MM-DD')
    days = time_double(sort_uniq(days))
    days = (probe eq 'b')? time_double(['2015-06-12']): []
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')

    ;---e_uvw.
        path = join_path([root_dir,rbspx,'e_uvw',str_year])
        base = prefix+'efw_e_uvw_'+time_string(day,tformat='YYYY_MMDD')+'_v02.cdf'
        file = join_path([path,base])
        print, file
        print, file_test(file)
        rbsp_efw_phasef_read_e_uvw_gen_file, day, probe=probe, filename=file

    ;---e_uvw_diagonal.
        path = join_path([root_dir,rbspx,'e_uvw_diagonal',str_year])
        base = prefix+'efw_e_combo_'+time_string(day,tformat='YYYY_MMDD')+'_v01.cdf'
        file = join_path([path,base])
        print, file
        print, file_test(file)
        rbsp_efw_phasef_read_e_uvw_diagonal_gen_file, day, probe=probe, filename=file

    ;---L4.
        path = join_path([root_dir,rbspx,'level4',str_year])
        base = prefix+'efw-l4_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
        print, file
        print, file_test(file)
        rbsp_efw_read_l4_gen_file, day, probe=probe, filename=file
    endforeach
endforeach

end
