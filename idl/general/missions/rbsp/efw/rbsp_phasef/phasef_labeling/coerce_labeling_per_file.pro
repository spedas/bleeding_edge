;+
; Coerce to the proper labeling.
;
; file_in. A string for the input file.
; file_out. A string for the output file.
; wanted_vars. An array for the wanted vars.
; log_file. A string for the log file to record missing vars.
; delete_unused_var=. A boolean, set to delete unused vars.
; delete_unwanted_var=. A boolean, set to delete unwanted vars.
; map_vars=. A dictionary with (old_vars, new_vars).
; unwanted_vars=. An array or a list of unwanted vars.
;-

pro coerce_labeling_per_file, file_in, file_out, wanted_vars, log_file, $
    delete_unused_var=delete_unused_var, map_vars=map_vars, $
    delete_unwanted_var=delete_unwanted_var, unwanted_vars=unwanted_vars

    if n_elements(file_in) eq 0 then begin
        msg = 'file_in does not exist ...'
        lprmsg, msg, log_file
        return
    endif

    if file_test(file_in) eq 0 then begin
        msg = file_in+' does not exist ...'
        lprmsg, msg, log_file
        return
    endif

    if n_elements(file_out) eq 0 then begin
        msg = 'file_out does not exist ...'
        lprmsg, msg, log_file
        return
    endif

    if n_elements(wanted_vars) eq 0 then begin
        msg = 'no wanted_vars ...'
        lprmsg, msg, log_file
        return
    endif
    wanted_labels = dictionary()
    foreach var, wanted_vars do wanted_labels[var] = phasef_get_labeling(var)


;---Coerce labeling.
    path_out = file_dirname(file_out)
    if file_test(path_out,/directory) then file_mkdir, path_out
    file_copy, file_in, file_out, /overwrite, /allow_same


;---Map vars.
    if n_elements(map_vars) ne 0 then begin
        old_vars = map_vars.old_vars
        new_vars = map_vars.new_vars
        foreach old_var, old_vars, var_id do begin
            if ~cdf_has_var(old_var, filename=file_out) then continue
            cdf_rename_var, old_var, to=new_vars[var_id], filename=file_out
        endforeach
    endif


;---Remove unwanted vars.
    if keyword_set(delete_unwanted_var) then begin
        if n_elements(unwanted_vars) eq 0 then begin
            unwanted_vars = list()
            unused_vars = cdf_detect_unused_vars(file_out, used_vars=used_vars)
            all_data_vars = list(unused_vars['data'],used_vars['data'], /extract)
            foreach var, all_data_vars do begin
                index = where(wanted_vars eq var, count)
                if count ne 0 then continue
                unwanted_vars.add, var
            endforeach
        endif
        foreach var, unwanted_vars do begin
            if ~cdf_has_var(var, filename=file_out) then continue
            cdf_del_var, var, filename=file_out
        endforeach
    endif



;---Go through wanted vars.
    foreach data_var, wanted_labels.keys() do begin
        wanted_label = wanted_labels[data_var]
        if ~cdf_has_var(data_var, filename=file_out) then begin
            msg = file_in+' missing data_var: '+data_var
            lprmsg, msg, log_file
            continue
        endif

        vatts = cdf_read_setting(data_var, filename=file_out)
        foreach the_key, ['VAR_NOTES','UNITS','LABL_PTR_1','CATDESC'] do begin
            if ~wanted_label.haskey(the_key) then continue
            vatts[the_key] = wanted_label[the_key]
        endforeach
        cdf_save_setting, vatts, filename=file_out, varname=data_var

        the_key = 'labels'
        if wanted_label.haskey(the_key) then begin
            label_var = vatts['LABL_PTR_1']
            if cdf_has_var(label_var, filename=file_out) then begin
                label_vatts = cdf_read_setting(label_var, filename=file_out)
            endif else label_vatts = dictionary()
            cdf_save_var, label_var, filename=file_out, $
                value=transpose(wanted_label[the_key])
            if n_elements(label_vatts) ne 0 then begin
                cdf_save_setting, label_vatts, filename=file_out, varname=label_var
            endif
        endif
    endforeach


;---Remove unused vars.
    if keyword_set(delete_unused_var) then begin
        unused_vars = cdf_detect_unused_vars(file_out)
        all_vars = cdf_vars(file_out)
        foreach key, unused_vars.keys() do begin
            foreach var, unused_vars[key] do begin
                index = where(all_vars eq var, count)
                if count eq 0 then continue
                cdf_del_var, var, filename=file_out
            endforeach
        endforeach
    endif



end

;file_in = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_vsvy-hires_20190101_v01.cdf'
;file_out = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_vsvy-hires_20190101_v02.cdf'
;log_file = '/Users/shengtian/Downloads/sample_l2/coerce_labeling_l2_vsvy.txt'
;coerce_labeling_l2_vsvy_hires_per_file, file_in, file_out, log_file, delete_unused_var=1

;file_in = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_e-spinfit-mgse_20140608_v02.cdf'
;file_out = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_e-spinfit-mgse_20140608_v03.cdf'
;log_file = '/Users/shengtian/Downloads/sample_l2/coerce_labeling_l2_e_spinfit.txt'
;coerce_labeling_l2_e_spinfit_per_file, file_in, file_out, log_file, delete_unused_var=1

file_in = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_esvy_despun_20170103_v02.cdf'
file_out = '/Users/shengtian/Downloads/sample_l2/rbspb_efw-l2_esvy_despun_20170103_v03.cdf'
log_file = '/Users/shengtian/Downloads/sample_l2/coerce_labeling_l2_esvy_despun.txt'
coerce_labeling_l2_esvy_despun_per_file, file_in, file_out, log_file, delete_unused_var=1
end
