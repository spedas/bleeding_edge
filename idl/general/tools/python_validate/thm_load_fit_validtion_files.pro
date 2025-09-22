; Validation files from thm_load_fit data 

; thm_load_fit with calibration
del_data, '*'

thm_load_fit, trange=['2008-03-15', '2008-03-16'], probe='a', type='calibrated'
 
; Save output, tha_fit, tha_fgs, tha_fgs_sigma, tha_fit_bfit, tha_fit_efit
; 'tha_efs_0','tha_efs_dot0', tha_efs, tha_efs_sigma
filename = './cal_fit'
tplot_save,['tha_fit', 'tha_fgs','tha_fgs_sigma', 'tha_fit_bfit','tha_fit_efit', $
            'tha_efs','tha_efs_sigma', 'tha_efs_0','tha_efs_dot0'], filename=filename

; thm_load_fit with calibration and /n_cal flag
del_data, '*'
thm_load_fit, trange=['2008-03-15', '2008-03-16'], probe='a', type='calibrated', /no_cal

; Save tha_efs with no_cal flag
filename = './tha_efs_no_cal'
tplot_save,['tha_efs'], filename=filename

end
