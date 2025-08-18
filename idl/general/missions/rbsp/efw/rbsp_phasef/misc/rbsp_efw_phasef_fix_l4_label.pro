;+
; Load skeleton file and add missing labels.
;
; This is already fixed in rbsp_efw_read_l4_gen_file.
;-

probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])

skeleton_base = prefix+'efw-lX_00000000_vXX.cdf'
skeleton_path = join_path([homedir(),'Projects','idl','spacephys','stdas','aaron_spedas_efw_code','efw','cdf_file_production'])
skeleton_file = join_path([skeleton_path,skeleton_base])

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    time_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-14']): time_double(['2012-09-08','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'level4',str_year])
        base = prefix+'efw-l4_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
        if file_test(file) eq 0 then rbsp_efw_read_l4_gen_file, day, probe=probe, filename=file

    ;---Start to fix label.
        vars = cdf_vars(file)

        cdf0 = cdf_open(file)
        cdf1 = cdf_open(skeleton_file)
        label_key = 'LABL_PTR_1'
        foreach var, vars do begin
            settings = cdf_read_setting(var, filename=cdf0)
            if ~settings.haskey(label_key) then continue
            label_var = settings[label_key]
            if cdf_has_var(label_var, filename=cdf0) then continue
            label_data = cdf_read_var(label_var, filename=cdf1)
            label_settings = cdf_read_setting(label_var, filename=cdf1)
            cdf_save_var, label_var, value=label_data, filename=cdf0
            cdf_save_setting, label_settings, varname=label_var, filename=cdf0
        endforeach
        cdf_close, cdf0
        cdf_close, cdf1
    endforeach
endforeach


end