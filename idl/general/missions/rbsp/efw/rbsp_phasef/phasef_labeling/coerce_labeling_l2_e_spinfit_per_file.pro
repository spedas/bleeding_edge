;+
; Coerce to the proper labeling.
;-

pro coerce_labeling_l2_e_spinfit_per_file, file_in, file_out, log_file, $
    delete_unused_var=delete_unused_var, delete_unwanted_var=delete_unwanted_var


;---From the big table in Chapter 7 Data availability and software.
    wanted_vars = ['efield_spinfit_mgse','VxB_mgse','efield_coro_mgse',$
        'orbit_num','vel_gse','pos_gse',$
        'mlt','mlat','lshell',$
        'spinaxis_gse','flags_all','bias_current']
    coerce_labeling_per_file, file_in, file_out, wanted_vars, log_file, delete_unused_var=delete_unused_var, delete_unwanted_var=delete_unwanted_var

;    if keyword_set(delete_unused_var) then begin
;        del_vars = [$
;            'diagEx1','diagEx2','diagBratio',$
;            'epoch_e','epoch_v','epoch_hsk',$
;            'bfield_labl','bfield_minus_model_LABL_1','angle_Ey_Ez_Bo_LABL_1',$
;            'vsvy_vavg_LABL_1','vsvy_vavg_UNIT','metavar_vcoro',$
;            'vel_coro_mgse_UNIT','efield_mgse_LABL_1','diagBratio_labl']
;        foreach del_var, del_vars do begin
;            if cdf_has_var(del_var, filename=file_out) then $
;                cdf_del_var, del_var, filename=file_out
;        endforeach
;    endif

end

file_in = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_e-spinfit-mgse_20140608_v02.cdf'
file_out = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_e-spinfit-mgse_20140608_v03.cdf'
log_file = '/Users/shengtian/Downloads/sample_l2/coerce_labeling_l2_e_spinfit.txt'
coerce_labeling_l2_e_spinfit_per_file, file_in, file_out, log_file, delete_unused_var=1
end
