;+
; Add labeling to v08 files, to make sure variables are properly labeled.
;-

root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')
probes = ['a','b']

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    time_range = rbsp_efw_phasef_get_valid_range('spice', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,'efw_phasef','spice_var',rbspx,str_year])
        base = prefix+'spice_products_'+time_string(day,tformat='YYYY_MMDD')+'_v08.cdf'
        file = join_path([path,base])
        print, file
        if file_test(file) eq 0 then stop
        rbsp_read_spice_gen_file_add_label, filename=file
    endforeach
endforeach

end
