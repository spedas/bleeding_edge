;+
; Generate L4 v04 data.
; To replace rbsp_efw_read_l4_gen_file.
;
; Use the e_spinfit and e_diagonal_spinfit updated on 2021-07-07.
; Use the 25-element flags and have a more explicit structure for the flag system.
;-

pro rbsp_efw_phasef_gen_l4_e_v03_per_day, date, $
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
    valid_range = phasef_get_valid_range(data_type, probe=probe)
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
    sc = probe
    rbx = 'rbsp'+probe+'_'
    prefix = rbx
    file_copy, skeleton, file, overwrite=1
    cdfid = cdf_open(file)


;---Load data.
    secofday = 86400d
    time_range = date+[0,secofday]

;---Spinfit E fields.
    bps = ['12','34','13','14','23','24']
    nbp = n_elements(bps)

    ; The spinfit data should already be on a common time.
    rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
    e_spinfit_vars = rbx+'e_spinfit_mgse_v'+bps

    ; Get common_times and save it as epoch to file.
    get_data, e_spinfit_vars[0], common_times
    ncommon_time = n_elements(common_times)
    epoch = tplot_time_to_epoch(common_times, epoch16=1)
    cdf_var = 'epoch'
    cdf_varput, cdfid, cdf_var, epoch

;---Edotb spinfit data.
    rbsp_efw_phasef_read_e_spinfit_edotb, time_range, probe=probe
    e_spinfit_edotb_vars = rbx+'e_spinfit_mgse_edotb_v'+bps


;---Change names and add ecoro back.
    rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
    ecoro_var = rbx+'ecoro_mgse'
    interp_time, ecoro_var, common_times
    foreach suffix, '_'+bps, bp_id do begin
        add_data, e_spinfit_vars[bp_id], ecoro_var, newname=prefix+'efield_in_inertial_frame_spinfit_mgse'+suffix, copy_dlimits=1
        tplot_rename, e_spinfit_vars[bp_id], prefix+'efield_in_corotation_frame_spinfit_mgse'+suffix
        add_data, e_spinfit_edotb_vars[bp_id], ecoro_var, newname=prefix+'efield_in_inertial_frame_spinfit_edotb_mgse'+suffix, copy_dlimits=1
        tplot_rename, e_spinfit_edotb_vars[bp_id], prefix+'efield_in_corotation_frame_spinfit_edotb_mgse'+suffix
    endforeach


;---Save the spinfit E fields to CDF.
    old_names = 'efield_'+[$
        'inertial_spinfit_mgse', $
        'inertial_spinfit_edotb_mgse', $
        'corotation_spinfit_mgse', $
        'corotation_spinfit_edotb_mgse' ]
    new_names = 'efield_in_'+[$
        'inertial_frame_spinfit_mgse', $
        'inertial_frame_spinfit_edotb_mgse', $
        'corotation_frame_spinfit_mgse', $
        'corotation_frame_spinfit_edotb_mgse' ]
    foreach suffix, '_'+bps, bp_id do begin
        cdf_old_vars = old_names+bp
        cdf_new_vars = new_names+bp
        vars = prefix+new_names+bp
        foreach var, vars, var_id do begin
            cdf_varrename, cdfid, cdf_old_vars[var_id], cdf_new_vars[var_id]
            cdf_varput, cdfid, cdf_new_vars[var_id], transpose(get_var_data(var))
        endforeach
    endforeach



;---Save magnetic field related data.
    cdf_var = 'diagBratio'
    b_mgse_smoothed = get_var_data(rbx+'b_mgse_smoothed')
    byz2bx = abs(b_mgse_smoothed[*,1:2]/b_mgse_smoothed[*,[0,0]])
    cdf_varput, cdfid, cdf_var, transpose(byz2bx)

    cdf_var = 'angle_spinplane_Bo'
    bmag = snorm(b_mgse_smoothed)
    deg = 1d/!dtor
    angles = acos(b_mgse_smoothed[*,1:2]/bmag[*,[0,0]])*deg
    cdf_varput, cdfid, cdf_var, transpose(angles)

    cdf_var = 'bfield_mgse'
    var = rbx+'b_mgse'
    rbsp_efw_phasef_prepare_residue_removal, time_range, probe=probe, id='b_mgse'
    interp_time, var, common_times
    b_mgse = get_var_data(var)
    cdf_varput, cdfid, cdf_var, transpose(b_mgse)

    cdf_var = 'bfield_magnitude'
    cdf_varput, cdfid, cdf_var, transpose(snorm(b_mgse))


;---Save other E field data to CDF.
    cdf_old_vars = ['corotation_efield_mgse','VxB_mgse']
    cdf_new_vars = ['VxB_efield_of_earth_mgse','VscxB_motional_efield_mgse']
    vars = rbx+['ecoro_mgse','evxb_mgse']
    foreach var, vars, var_id do begin
        interp_time, var, common_times
        cdf_varrename, cdfid, cdf_old_vars[var_id], cdf_new_vars[var_id]
        cdf_varput, cdfid, cdf_new_vars[var_id], transpose(get_var_data(var))
    endforeach


;---Load flags and save to CDF.
    rbsp_efw_read_flags, time_range, probe=probe
    flag_var = prefix+'efw_flags'
    interp_time, flag_var, common_times
    all_flags = get_var_data(flag_var, limits=lim) ne 0
    flag_names = lim.labels

    foreach bp, bps, bp_id do begin
        suffix = '_'+bp
        ; The key flags.
        cdf_var = 'flags_charging_bias_eclipse'+suffix
        wanted_flag_names = ['charging'+suffix,'autobias','eclipse','charging_extreme'+suffix]
        wanted_flag_index = []
        foreach wanted_flag_name, wanted_flag_names do begin
            wanted_flag_index = [wanted_flag_index,where(flag_names eq wanted_flag_name, count)]
            if count eq 0 then message, 'No wanted flag ...'
        endforeach
        cdf_varput, cdfid, cdf_var, transpose(all_flags[*,wanted_flag_index])
        var_note = 'charging, autobias, eclipse flags, extreme charging'
        cdf_attput, cdfid, 'VAR_NOTES', cdf_var, /zvariable, var_note

        ; 20-element flags.
        rbsp_efw_phasef_read_flag_20, time_range, probe=probe, boom_pair=bp
        cdf_var = 'flags_all'+suffix
        flag_arr = get_var_data(prefix+'flag_20')
        cdf_varput, cdfid, cdf_var, transpose(flag_arr)
    endforeach


;---Load density and save to CDF.
    if ~keyword_set(dmin) then dmin = 10.     ; min density.
    foreach bp, bps, bp_id do begin
        suffix = '_'+bp
        rbsp_efw_phasef_read_density, time_range, probe=probe, boom_pair=bp, dmin=dmin
        density_var = prefix+'density'+suffix
        interp_time, density_var, common_times
        cdf_var = 'density'+suffix
        cdf_varput, cdfid, cdf_var, transpose(get_var_data(density_var))
    endforeach


;---Load SPICE data and save to CDF.
	rbsp_load_spice_cdf_file, sc
	spice_vars = rbx+['state_'+['pos_gse','vel_gse','mlt','mlat','lshell'],$
	   'spinaxis_direction_gse']
    foreach var, spice_vars do begin
        interp_time, var, common_times
    endforeach

    cdf_vars = ['position_gse','velocity_gse','mlt','mlat','lshell','spinaxis_gse']
    foreach cdf_var, cdf_vars, var_id do begin
        cdf_varput, cdfid, cdf_var, transpose(get_var_data(spice_vars[var_id]))
    endforeach


;---Load all the HSK data and save to CDF.
    rbsp_load_efw_hsk, probe=sc, get_support_data=1
    pre = rbx+'efw_hsk_'
    pre2 = 'idpu_analog_'

    get_data,pre+pre2+'IMON_BEB', timeshsk
    ntimehsk = n_elements(timeshsk)
    epoch_hsk = tplot_time_to_epoch(timeshsk, epoch16=1)


;---Save HSK data.
    cdf_var = 'epoch_hsk'
    cdf_varput, cdfid, cdf_var, epoch_hsk
    all_saved_vars.add, cdf_var

    suffix = ['1','2','3','4','5','6']
    nboom = n_elements(suffix)
    cdf_vars = ['guard_voltage','usher_voltage','bias_current']
    foreach hsk_data, ['guard','usher','ibias'], hsk_id do begin
        vars = pre+'beb_analog_'+'IEFI_'+strupcase(hsk_data)+suffix
        data = fltarr(ntimehsk,nboom)+!values.f_nan
        foreach var, vars, var_id do begin
            ;tinterpol_mxn, var, timeshsk, /overwrite, /spline
            ;if tnames(var) eq '' then continue  ; sometimes no hsk data, e.g., 2012-11-16 b.
            get_data, var, tmp
            if n_elements(tmp) le 3 then continue   ; not enough data, e.g., 2012-11-27 b.
            interp_time, var, timeshsk  ; tinterpol_mxn sometimes fails, e.g., 2012-11-14 b.
            tmp = get_var_data(var)
            if n_elements(tmp) ne ntimehsk then continue
            data[*,var_id] = temporary(tmp)
        endforeach

        cdf_varput, cdfid, cdf_vars[hsk_id], transpose(data)
    endforeach


;---Burst data times.
    ;--------------------------------------------------
    ;Get burst times
    ;This is a bit complicated for spinperiod data b/c the short
    ;B2 snippets can be less than the spinperiod.
    ;So, I'm padding the B2 times by +/- a half spinperiod so that they don't
    ;disappear upon interpolation to the spinperiod data.
    ;--------------------------------------------------
    b1_flag = intarr(ncommon_time)
    b2_flag = b1_flag

    ;get B1 times and rates from this routine
    b1t = rbsp_get_burst_times_rates_list(sc)

    ;get B2 times from this routine
    b2t = rbsp_get_burst2_times_list(sc)
    ;Pad B2 by +/- half spinperiod
    b2t.startb2 -= 6.
    b2t.endb2   += 6.

    for q=0,n_elements(b1t.startb1)-1 do begin
        goodtimes = where((common_times ge b1t.startb1[q]) and (common_times le b1t.endb1[q]), count)
        if count ne 0 then b1_flag[goodtimes] = b1t.samplerate[q]
    endfor
    for q=0,n_elements(b2t.startb2[*,0])-1 do begin
        goodtimes = where((common_times ge b2t.startb2[q]) and (common_times le b2t.endb2[q]), count)
        if count ne 0 then b2_flag[goodtimes] = 1
    endfor
    cdf_varput,cdfid,'burst1_avail',b1_flag
    cdf_varput,cdfid,'burst2_avail',b2_flag


    cdf_close, cdfid
    stop


end


date = '2017-09-07'
probe = 'a'
file = join_path([homedir(),'test_level4.cdf'])
tic
rbsp_efw_phasef_gen_l4_e_v03_per_day, date, probe=probe, file=file
toc
end
