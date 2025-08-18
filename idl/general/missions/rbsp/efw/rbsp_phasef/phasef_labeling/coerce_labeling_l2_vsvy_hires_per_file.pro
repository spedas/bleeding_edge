;+
; Coerce to the proper labeling.
;-

pro coerce_labeling_l2_vsvy_hires_per_file, file_in, file_out, log_file, $
    delete_unused_var=delete_unused_var, delete_unwanted_var=delete_unwanted_var


;---From the big table in Chapter 7 Data availability and software.
    wanted_vars = ['vsvy','vsvy_vavg',$
        'orbit_num','vel_gse','pos_gse',$
        'mlt','mlat','lshell']
    map_vars = dictionary($
        'old_vars', ['velocity_gse','position_gse'], $
        'new_vars', ['vel_gse','pos_gse'])
    coerce_labeling_per_file, file_in, file_out, wanted_vars, log_file, $
        delete_unused_var=delete_unused_var, map_vars=map_vars, $
        delete_unwanted_var=delete_unwanted_var

end

file_in = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_vsvy-hires_20190101_v01.cdf'
file_out = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_vsvy-hires_20190101_v02.cdf'
log_file = '/Users/shengtian/Downloads/sample_l2/coerce_labeling_l2_vsvy.txt'
coerce_labeling_l2_vsvy_hires_per_file, file_in, file_out, log_file, delete_unused_var=1, delete_unwanted_var=1
end
