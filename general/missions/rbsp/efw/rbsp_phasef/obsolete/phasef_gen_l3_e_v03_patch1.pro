;+
; Add used_boom_pair to v03 files.
;-

pro phasef_gen_l3_e_v03_patch1, file

    var = 'used_boom_pair'
    if cdf_has_var(var, filename=file) then return

    evar = 'efield_in_inertial_frame_spinfit_mgse'
    if ~cdf_has_var(evar, filename=file) then message, 'Run phasef_gen_l3_e_v03 first ...'
    vatt = cdf_read_setting(evar, filename=file)
    the_boom_pair = strmid(vatt['FIELDNAM'],10,2)
    cdf_save_var, var, value=fix(the_boom_pair), filename=file
    settings = dictionary($
        'FORMAT', 'I2', $
        'LABLAXIS', 'boom_pair_used_for_spinfit', $
        'FIELDNAM', 'boom_pair_used_for_spinfit', $
        'CATDESC', 'boom_pair_used_for_spinfit', $
        'VAR_TYPE', 'metadata' )
    cdf_save_setting, settings, filename=file, varname=var

end


;stop
probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = (probe eq 'a')? time_double(['2012-09-13','2019-02-23']): time_double(['2012-09-13','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l3',str_year])
        base = prefix+'efw-l3_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
        file = join_path([path,base])
        if file_test(file) eq 0 then continue
        phasef_gen_l3_e_v03_patch1, file
    endforeach
endforeach

stop
file = '/Users/shengtian/test_level3.cdf'
phasef_gen_l3_e_v03_patch1, file
end
