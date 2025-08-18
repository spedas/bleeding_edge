;+
; Update flags for all related data product.
;-

probes = ['a','b']
root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')

time_range = rbsp_efw_phasef_get_valid_range('flags_all')
days = make_bins(time_range+[0,-1]*secofday, constant('secofday'))

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')

        boom_pair = rbsp_efw_phasef_get_boom_pair(day, probe=probe)
        rbsp_efw_phasef_read_flag_25, the_time_range, probe=probe, boom_pair=boom_pair
        rbsp_efw_phasef_read_flag_20, the_time_range, probe=probe, boom_pair=boom_pair

        
    endforeach
endforeach
