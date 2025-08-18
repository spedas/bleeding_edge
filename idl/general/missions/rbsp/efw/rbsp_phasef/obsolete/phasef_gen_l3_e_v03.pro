;+
; Adopted from rbsp_efw_read_l3_gen_file.
;
;-

pro phasef_gen_l3_e_v03_per_day, date, $
    probe=probe, filename=file, log_file=log_file

    errmsg = ''

    msg = 'Processing '+file+' ...'
    lprmsg, msg, log_file


;---Check input.
    if n_elements(file) eq 0 then begin
        errmsg = 'cdf file is not set ...'
        lprmsg, errmsg, log_file
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = 'No input probe ...'
        lprmsg, errmsg, log_file
        return
    endif
    if probe ne 'a' and probe ne 'b' then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        lprmsg, errmsg, log_file
        return
    endif
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe

    data_type = 'e_spinfit'
    valid_range = rbsp_efw_phasef_get_valid_range(data_type, probe=probe)
    if n_elements(date) eq 0 then begin
        errmsg = 'No input date ...'
        lprmsg, errmsg, log_file
        return
    endif
    if size(date,/type) eq 7 then date = time_double(date)
    if product(date-valid_range) gt 0 then begin
        errmsg = 'Input date: '+time_string(date,tformat='YYYY-MM-DD')+' is out of valid range ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Prepare skeleton.
    skeleton_base = prefix+'efw-l3_00000000_v03.cdf'
    skeleton = join_path([srootdir(),skeleton_base])
    if file_test(skeleton) eq 0 then begin
        errmsg = 'Skeleton file is not found ...'
        lprmsg, errmsg, log_file
        return
    endif


;---Load data.
    secofday = 86400d
    time_range = date+[0,secofday]
    rbsp_efw_read_l4, time_range, probe=probe
    rbsp_efw_read_flags, time_range, probe=probe
    rbsp_efw_phasef_read_e_fit, time_range, probe=probe


;---Do something.
    ; Determine the used boom pair.
    the_boom_pair = '12'
    if probe eq 'a' and time_range[0] ge time_double('2015-01-01') then the_boom_pair = '24'

    ; Remove e_fit.
    e_vars = prefix+[$
        'efield_in_corotation_frame_spinfit_mgse',$
        'efield_in_corotation_frame_spinfit_edotb_mgse',$
        'efield_in_inertial_frame_spinfit_mgse', $
        'efield_in_inertial_frame_spinfit_edotb_mgse']+'_'+the_boom_pair
    get_data, e_vars[0], common_times
    efit = get_var_data(prefix+'efit_mgse', at=common_times)
    foreach e_var, e_vars do begin
        store_data, e_var, common_times, get_var_data(e_var)-efit
    endforeach

    ; Add boom_flag to flags_all.
    flag_var = prefix+'flags_all_'+the_boom_pair
    flags = get_var_data(flag_var)
    all_flags = get_var_data(prefix+'efw_flags', at=common_times, limits=lim)
    index = where(lim.labels eq 'boomflag1')
    boom_flags = all_flags[*,index[0]+[0,1,2,3]] ne 0

    ; New flags.
    ntime = n_elements(common_times)
    new_flags = fltarr(ntime,25)
    new_flags[*,0:17] = flags[*,0:17]
    new_flags[*,18:21] = boom_flags
    new_flags >= 0
    store_data, prefix+'flags_all', common_times, new_flags

    global_flag = total(new_flags,2) ne 0
    bad_index = where(global_flag eq 1, count)
    if count ne 0 then begin
        pad_time = 600. ; sec.
        bad_times = common_times[time_to_range(bad_index,time_step=1)]
        nbad_time = n_elements(bad_times)*0.5
        for ii=0,nbad_time-1 do begin
            index = lazy_where(common_times, '[]', bad_times[ii,*]+[-1,1]*pad_time, count=count)
            if count eq 0 then continue
            global_flag[index] = 1
        endfor
    endif
    store_data, prefix+'global_flag', common_times, global_flag
    bad_index = where(global_flag eq 1, count)
    if count eq 0 then bad_index = !null


    ; Mask bad data.
    e_vars = prefix+[$
        'efield_in_corotation_frame_spinfit_mgse',$
        'efield_in_corotation_frame_spinfit_edotb_mgse',$
        'efield_in_inertial_frame_spinfit_mgse', $
        'efield_in_inertial_frame_spinfit_edotb_mgse']+'_'+the_boom_pair
    fillval = !values.f_nan
    foreach e_var, e_vars do begin
        get_data, e_var, times, data
        if n_elements(bad_index) ne 0 then data[bad_index,*] = fillval
        store_data, e_var, times, data
    endforeach
    ; Rename tplot_vars so that save_xxx_to_file routines run.
    old_vars = prefix+['bias_current']
    new_vars = prefix+['ibias']
    foreach old_var, old_vars, var_id do begin
        new_var = new_vars[var_id]
        rename_var, old_var, to=new_var
    endforeach


;---Save data.
    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    file_copy, skeleton, file, /overwrite
    ; Map cdf old_vars to new_vars.
    old_vars = [$
        'flags_all2', $
        'corotation_efield_mgse','VxB_mgse', $
        ['vsvy_vavg_combo']+'_'+the_boom_pair, $
        'efield_'+[$
            'inertial_spinfit_mgse', $
            'inertial_spinfit_edotb_mgse', $
            'corotation_spinfit_mgse', $
            'corotation_spinfit_edotb_mgse']+'_'+the_boom_pair ]
    new_vars = [$
        'flags_all', $
        'VxB_efield_of_earth_mgse','VscxB_motional_efield_mgse', $
        ['spacecraft_potential']+'_'+the_boom_pair, $
        'efield_in_'+[$
            'inertial_frame_spinfit_mgse', $
            'inertial_frame_spinfit_edotb_mgse', $
            'corotation_frame_spinfit_mgse', $
            'corotation_frame_spinfit_edotb_mgse']+'_'+the_boom_pair]
    foreach old_var, old_vars, var_id do begin
        new_var = new_vars[var_id]
        if cdf_has_var(new_var, filename=file) then cdf_del_var, new_var, filename=file
        cdf_rename_var, old_var, to=new_var, filename=file
    endforeach
    ; Map boom_pair dependent var.
    bp_vars = [ 'density','spacecraft_potential', $
        'flags_charging_bias_eclipse', $
        'efield_in_corotation_frame_spinfit_mgse',$
        'efield_in_corotation_frame_spinfit_edotb_mgse',$
        'efield_in_inertial_frame_spinfit_mgse', $
        'efield_in_inertial_frame_spinfit_edotb_mgse']
    foreach var, bp_vars do begin
        old_var = var+'_'+the_boom_pair
        new_var = var
        if cdf_has_var(new_var, filename=file) then cdf_del_var, new_var, filename=file
        cdf_rename_var, old_var, to=new_var, filename=file
        rename_var, prefix+old_var, to=prefix+new_var
    endforeach


    routines = 'phasef_save_'+[$
        'e_spinfit_l3', $
        'spinaxis_gse', $
        'position_var', $
        'bias_current', $
        'flags_all']+'_to_file'

    foreach routine, routines do begin
        call_procedure, routine, date, probe=probe, filename=file
    endforeach
    cdf_del_unused_vars, file
    phasef_gen_l3_e_v03_patch1, file


end

;stop
;probes = ['b']
;root_dir = join_path([homedir(),'data','rbsp'])
;foreach probe, probes do begin
;    prefix = 'rbsp'+probe+'_'
;    rbspx = 'rbsp'+probe
;    time_range = (probe eq 'a')? time_double(['2012-09-13','2019-02-23']): time_double(['2012-09-13','2019-07-16'])
;    days = make_bins(time_range, constant('secofday'))
;    foreach day, days do begin
;        str_year = time_string(day,tformat='YYYY')
;        path = join_path([root_dir,rbspx,'level3',str_year])
;        base = prefix+'efw-l3_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
;        file = join_path([path,base])
;        if file_test(file) eq 1 then continue
;        phasef_gen_l3_e_v03_per_day, day, probe=probe, filename=file
;    endforeach
;endforeach


date = time_double('2015-05-28')
;date = time_double('2019-09-28')
probe = 'a'
file = join_path([homedir(),'test_level3.cdf'])
phasef_gen_l3_e_v03_per_day, date, probe=probe, file=file
end
