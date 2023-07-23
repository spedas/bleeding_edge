;+
; Coerce to the proper labeling.
;-

pro coerce_labeling_l2_esvy_despun_per_file, file_in, file_out, log_file, $
    delete_unused_var=delete_unused_var, delete_unwanted_var=delete_unwanted_var


;---From the big table in Chapter 7 Data availability and software.
    wanted_vars = ['efield_mgse', $
        'orbit_num','vel_gse','pos_gse', $
        'mlt','mlat','lshell', $
        'spinaxis_gse','bias_current']
    coerce_labeling_per_file, file_in, file_out, wanted_vars, log_file, delete_unused_var=delete_unused_var, delete_unwanted_var=delete_unwanted_var

;    del_vars = ['diagEx1','diagEx2','diagBratio']
;    foreach del_var, del_vars do begin
;        if cdf_has_var(del_var, filename=file_out) then $
;            cdf_del_var, del_var, filename=file_out
;    endforeach

end

file_in = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_esvy_despun_20170103_v02.cdf'
file_out = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_esvy_despun_20170103_v03.cdf'
log_file = '/Users/shengtian/Downloads/sample_l2/coerce_labeling_l2_esvy_despun.txt'
coerce_labeling_l2_esvy_despun_per_file, file_in, file_out, log_file
end
