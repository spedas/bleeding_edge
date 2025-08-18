;+
; Patch to add orbit_num to l4 spinfit, b/c this is slow to load.
;-


probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
;root_dir = join_path([homedir(),'data','rbsp'])

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    time_range = (probe eq 'a')? time_double(['2012-09-05','2019-10-13']): time_double(['2012-09-05','2019-07-16'])
    days = break_down_times(time_range,'day')
;    days = time_double('2015-07-01')
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')

    ;---L4.
        path = join_path([root_dir,rbspx,'level4',str_year])
        base = prefix+'efw-l4_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
        if file_test(file) eq 0 then continue
        print, file
        phasef_add_orbit_num_to_l4, day, probe=probe, filename=file
    endforeach
endforeach

end
