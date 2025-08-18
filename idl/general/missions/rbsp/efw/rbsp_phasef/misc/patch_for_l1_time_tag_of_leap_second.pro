;+
; There are days when there is a -1 sec jump in time tag, but looks like leap second. However, they need to be treated because the time tag is still non-monotonic.
;-

probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
;root_dir = join_path([homedir(),'data','rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    rbsp_efw_read_l1_time_tag_leap_second, probe=probe
    get_data, prefix+'l1_time_tag_leap_second', start_times
    secofday = 86400d
    days = start_times-(start_times mod secofday)
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
