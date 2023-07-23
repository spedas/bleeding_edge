;+
;
;-

pro rbsp_efw_read_l3_gen_file, date0, $
    probe=sc0, filename=file, _extra=ex

;---Check input.
    if n_elements(sc0) eq 0 then begin
        errmsg = 'No input probe ...''
        return
    endif
    sc = strlowcase(sc0[0])
    probe = sc  ; to be compatible for some codes.
    rbx = 'rbsp'+sc+'_'
    prefix = rbx

    if n_elements(date0) eq 0 then begin
        errmsg = 'No input date ...'
        return
    endif
    date = time_double(date0[0])
    secofday = 86400d
    date = date-(date mod secofday)
    time_range = date+[0,secofday]
    timespan, date, 1, /day

    if n_elements(file) eq 0 then begin
        errmsg = 'No input file ...'
        return
    endif
    folder = fgetpath(file)
    if file_test(folder) eq 0 then file_mkdir, folder

    ; '<spedas>/idl/general/missions/rbsp/efw/cdf_file_production/rbx+'efw-lX_00000000_vXX.cdf''
    if n_elements(skeleton_file) eq 0 then begin
        skeleton_file = join_path([srootdir(),rbx+'efw-lX_00000000_vXX.cdf'])
    endif
    if file_test(skeleton_file) eq 0 then begin
        errmsg = 'Input skeleton_file does not exist ...'
        return
    endif
    file_copy, skeleton_file, file, overwrite=1


    ;Make IDL behave nicely
    compile_opt idl2


    ; Clean slate
    store_data,tnames(),/delete
    rbsp_efw_init


;---Load data, L4 and boom flag.
    rbsp_efw_read_l4, time_range, probe=probe
    rbsp_efw_read_boom_flag, time_range, probe=probe


;---Prepare flag and the used pair.
    the_boom_pair = '12'
    if probe eq 'a' and time_range[0] ge time_double('2015-01-01') then the_boom_pair = '24'

    flag_var = 'flags_all_'+the_boom_pair
    boom_flag_var = prefix+'boom_flag'
    interp_time, boom_flag_var, to=flag_var

    ; Add boom_flag to flags_all.
    boom_flags = get_var_data(boom_flag_var, times=common_times)
    flags = get_var_data(flag_var)

    ; New flags.
    ntime = n_elements(common_times)
    new_flags = fltarr(ntime,25)
    new_flags[*,0:17] = flags[*,0:17]
    ; The original boom_flag has 1 for a working boom,
    ; Data are good only when all boom_flags are 1.
    ; After this conversion, the new boom_flag has 1 for bad data.
    ; Data are good only when all new boom_flags are 0.
    new_flags[*,18:21] = 1-boom_flags
    new_flags >= 0
    store_data, 'flags_all', common_times, new_flags

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
    store_data, 'global_flag', common_times, global_flag
    bad_index = where(global_flag eq 1, count)
    if count eq 0 then bad_index = !null


;---Mask bad data.
    e_vars = [$
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


;---Save data.
    cdfid = cdf_open(file)
    all_saved_vars = list()


    ; Convert old names to new names.
    vars = ['flags_charging_bias_eclipse','flags_all']
    foreach var, vars do cdf_vardelete, cdfid, var
    cdf_old_vars = [$
        'flags_all2', $
        'vsvy_vavg_combo_'+the_boom_pair, $
        'corotation_efield_mgse','VxB_mgse', $
        'efield_'+[$
        'inertial_spinfit_mgse_', $
        'inertial_spinfit_edotb_mgse_', $
        'corotation_spinfit_mgse_', $
        'corotation_spinfit_edotb_mgse_' ]+the_boom_pair ]
    cdf_new_vars = [$
        'flags_all', $
        'spacecraft_potential_'+the_boom_pair, $
        'VxB_efield_of_earth_mgse','VscxB_motional_efield_mgse', $
        'efield_in_'+[$
        'inertial_frame_spinfit_mgse_', $
        'inertial_frame_spinfit_edotb_mgse_', $
        'corotation_frame_spinfit_mgse_', $
        'corotation_frame_spinfit_edotb_mgse_' ]+the_boom_pair ]
    foreach var, cdf_old_vars, var_id do begin
        cdf_varrename, cdfid, cdf_old_vars[var_id], cdf_new_vars[var_id]
    endforeach


    ; Over boom_pair dependent vars.
    bp_vars = [ 'density','spacecraft_potential', $
        'flags_charging_bias_eclipse', $
        'efield_in_corotation_frame_spinfit_mgse',$
        'efield_in_corotation_frame_spinfit_edotb_mgse',$
        'efield_in_inertial_frame_spinfit_mgse', $
        'efield_in_inertial_frame_spinfit_edotb_mgse']
    foreach var, bp_vars do begin
        cdf_varrename, cdfid, var+'_'+the_boom_pair, var
        cdf_varput, cdfid, var, transpose(get_var_data(var+'_'+the_boom_pair))
        cdf_save_setting, filename=cdfid, varname=var, 'boom_pair', the_boom_pair
    endforeach
    all_saved_vars.add, bp_vars, /extract



    ; Directly saved vars.
    vars = [$
        'flags_all', $
        'VxB_efield_of_earth_mgse', $
        'VscxB_motional_efield_mgse', $
        'velocity_gse','position_gse','angle_spinplane_Bo','mlt','mlat','lshell', $
        'spinaxis_gse', $
        'global_flag', $
        'burst1_avail', $
        'burst2_avail', $
        'bfield_mgse', $
        'bias_current']
    ; Removed: bfield_gse, efield_moving_with_sc_mgse_Wygant.
    foreach var, vars do begin
        cdf_varput, cdfid, var, transpose(get_var_data(var))
    endforeach
    all_saved_vars.add, vars, /extract


    ; Time.
    var = 'epoch'
    get_data, vars[0], times
    epoch = tplot_time_to_epoch(times, epoch16=1)
    cdf_varput, cdfid, var, epoch
    all_saved_vars.add, var



    ; Add label.
    label_key = 'LABL_PTR_1'
    foreach var, all_saved_vars do begin
        settings = cdf_read_setting(var, filename=cdfid)
        if ~settings.haskey(label_key) then continue
        label_var = settings[label_key]
        if all_saved_vars.where(label_var) ne !null then continue
        all_saved_vars.add, label_var
    endforeach


;---Delete vars that are not used.
    foreach cdf_var, cdf_vars(cdfid) do begin
        if all_saved_vars.where(cdf_var) ne !null then continue
        cdf_vardelete, cdfid, cdf_var
    endforeach

    cdf_close, cdfid



end

probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = (probe eq 'a')? time_double(['2012-09-08','2019-02-23']): time_double(['2012-09-08','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'level3',str_year])
        base = prefix+'efw-l3_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
        if file_test(file) eq 1 then continue
        rbsp_efw_read_l3_gen_file, day, probe=probe, filename=file
    endforeach
endforeach

stop


date = time_double('2017-05-28')
probe = 'a'
file = join_path([homedir(),'test_level3.cdf'])
tic
rbsp_efw_read_l3_gen_file, date, probe=probe, file=file
toc
end
