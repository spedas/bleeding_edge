;+
; Coerce to the proper labeling.
;-

pro coerce_labeling_l2_e_hires_uvw_per_file, file_in, file_out, log_file, $
    delete_unused_var=delete_unused_var, delete_unwanted_var=delete_unwanted_var


;---From the big table in Chapter 7 Data availability and software.
    wanted_vars = ['vsvy','vsvy_vavg',$
        'orbit_num','vel_gse','pos_gse',$
        'mlt','mlat','lshell']
    map_vars = dictionary($
        'old_vars',['efield_raw_uvw','efield_uvw'], $
        'new_vars', ['e_hires_uvw_raw','e_hires_uvw'])
    coerce_labeling_per_file, file_in, file_out, wanted_vars, log_file, $
        delete_unused_var=delete_unused_var, map_vars=map_vars, $
        delete_unwanted_var=delete_unwanted_var

end
