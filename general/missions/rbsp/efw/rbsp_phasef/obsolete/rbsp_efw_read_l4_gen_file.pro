;+
; NAME:
;   rbsp_efw_read_l4_gen_file
;
; PURPOSE:
;   Generate level-4 EFW CDF files, adopted from rbsp_efw_make_l4
;
;
; CALLING SEQUENCE:
;   rbsp_efw_read_l4_gen_file, date, probe=sc
;
; ARGUMENTS:
;   date: IN, REQUIRED
;       A date string in format like '2013-02-13'
;
; KEYWORDS:
;   probe=: IN, REQUIRED
;       'a' or 'b'
;   filename=. In, required. The file name for the CDF file to be saved.
;   skeleton_file=. In, optional. By default the skeleton file should be in the same folder of this program.
;   density_min=. In, optional. Default is 10 cc.
;   errmsg=. Out. The error massege if the program fails.
;
;-


pro rbsp_efw_read_l4_gen_file, date0, $
    probe=sc0, filename=file, skeleton_file=skeleton_file, $
    errmsg=errmsg, density_min=dmin


;---Check input.
    if n_elements(sc0) eq 0 then begin
        errmsg = 'No input probe ...''
        return
    endif
    sc = strlowcase(sc0[0])
    probe = sc  ; to be compatible for some codes.
    rbx = 'rbsp'+sc+'_'

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
    cdfid = cdf_open(file)
    all_saved_vars = list()


    ;Make IDL behave nicely
    compile_opt idl2


    ; Clean slate
    store_data,tnames(),/delete
    rbsp_efw_init


;---Load spinfit data, with evxb and ecoro removed.
    bps = ['12','34','13','14','23','24']
    nbp = n_elements(bps)
    ; Change names and interpolate to common time tags.
    rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
    old_vars = rbx+'e_spinfit_mgse_v'+bps
    new_vars = rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_'+bps

    ; Get common_times and save it as epoch to file.
    get_data, old_vars[0], common_times
    ncommon_time = n_elements(common_times)
    epoch = tplot_time_to_epoch(common_times, epoch16=1)
    cdf_var = 'epoch'
    cdf_varput, cdfid, cdf_var, epoch
    all_saved_vars.add, cdf_var

    ; Interpolate to common_times.
    foreach bp, bps, bp_id do begin
        tplot_rename, old_vars[bp_id], new_vars[bp_id]
        interp_time, new_vars[bp_id], common_times
    endforeach

    ; Add ecoro back.
    rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
    ecoro_var = rbx+'ecoro_mgse'
    interp_time, ecoro_var, common_times
    e1_vars = rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_'+bps
    e2_vars = rbx+'efw_esvy_mgse_vxb_removed_spinfit_'+bps
    foreach bp, bps, bp_id do begin
        add_data, e1_vars[bp_id], ecoro_var, newname=e2_vars[bp_id], copy_dlimits=1
    endforeach


;---Calc E dot B = 0.
    ; Load and preprocess B field data.
    smooth_window = 1800.   ; sec.
    rbsp_efw_phasef_read_wobble_free_var, time_range+[-1,1]*smooth_window, probe=probe, id='b_mgse'
    b_var = rbx+'b_mgse'
    rbsp_detrend, b_var, smooth_window
    b_smoothed_var = rbx+'b_mgse_smoothed'
    foreach var, [b_var,b_smoothed_var] do begin
        interp_time, var, common_times
    endforeach

    ; Calc E dot B = 0.
    foreach e_var, [e1_vars,e2_vars] do begin
        pos = strlen(e_var)-2
        new_var = strmid(e_var,0,pos)+'edotb_'+strmid(e_var,pos)
        rbsp_efw_calc_edotb_to_zero, e_var, b_smoothed_var, newname=new_var, no_preprocess=1
    endforeach


;---Save magnetic field related data.
    cdf_var = 'diagBratio'
    b_mgse_smoothed = get_var_data(rbx+'b_mgse_smoothed')
    byz2bx = abs(b_mgse_smoothed[*,1:2]/b_mgse_smoothed[*,[0,0]])
    cdf_varput, cdfid, cdf_var, transpose(byz2bx)
    all_saved_vars.add, cdf_var

    cdf_var = 'angle_spinplane_Bo'
    bmag = snorm(b_mgse_smoothed)
    deg = 1d/!dtor
    angles = acos(b_mgse_smoothed[*,1:2]/bmag[*,[0,0]])*deg
    cdf_varput, cdfid, cdf_var, transpose(angles)
    all_saved_vars.add, cdf_var

    cdf_var = 'bfield_mgse'
    var = rbx+'b_mgse'
    b_mgse = get_var_data(var)
    cdf_varput, cdfid, cdf_var, transpose(b_mgse)
    all_saved_vars.add, cdf_var

    cdf_var = 'bfield_magnitude'
    cdf_varput, cdfid, cdf_var, transpose(snorm(b_mgse))
    all_saved_vars.add, cdf_var

    cdf_old_vars = ['corotation_efield_mgse','VxB_mgse']
    cdf_new_vars = ['VxB_efield_of_earth_mgse','VscxB_motional_efield_mgse']
    vars = rbx+['ecoro_mgse','evxb_mgse']
    foreach var, vars, var_id do begin
        interp_time, var, common_times
        cdf_varrename, cdfid, cdf_old_vars[var_id], cdf_new_vars[var_id]
        cdf_varput, cdfid, cdf_new_vars[var_id], transpose(get_var_data(var))
    endforeach
    all_saved_vars.add, cdf_new_vars, /extract


;---Load flags.
    ; Create master flag array.
    nflag = 20
    flag_arr = intarr(ncommon_time,nflag,nbp)
    if ~keyword_set(dmin) then dmin = 10.     ; min density.
    foreach bp, bps, bp_id do begin
        tmp = rbsp_efw_get_flag_values(sc, common_times, density_min=dmin, boom_pair=bp, _extra=extra)
        flag_arr[*,*,bp_id] = tmp.flag_arr

        ;Set the density flag based on the antenna pair used.
        ;flag_arr[*,16,bp_id] = 0
        ;index = where(tmp.flag_arr[*,0] eq 1, count)
        flag_arr[*,16,bp_id] = tmp.flag_arr[*,0] eq 1
    endforeach

    flag_var = rbx+'flag_arr'
    store_data, flag_var, common_times, flag_arr


    ; Flags for each time and boom pair
    ; charging, autobias, eclipse, and extreme charging flags all in one variable for convenience
    map_index = [15,14,1,16]
    flags = flag_arr[*,map_index,*]


;---Save flags and density to file.
    cdf_vars = 'flags_all_'+bps
    foreach bp, bps, bp_id do begin
        cdf_varput, cdfid, cdf_vars[bp_id], transpose(flag_arr[*,*,bp_id])
    endforeach
    all_saved_vars.add, cdf_vars, /extract

    cdf_vars = 'flags_charging_bias_eclipse_'+bps
    foreach bp, bps, bp_id do begin
        cdf_varput, cdfid, cdf_vars[bp_id], transpose(flags[*,*,bp_id])
    endforeach
    all_saved_vars.add, cdf_vars, /extract

    vars = rbx+'density'+bps
    cdf_vars = 'density_'+bps
    foreach var, vars, var_id do begin
        get_data, var, times
        if n_elements(times) ne ncommon_time then interp_time, var, common_times
        cdf_varput, cdfid, cdf_vars[var_id], transpose(get_var_data(var))
    endforeach
    all_saved_vars.add, cdf_vars, /extract

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
    all_saved_vars.add, 'burst'+['1','2']+'_avail', /extract



;---Apply flags to E field data.
    fillval = -1e31
    e_vars = rbx+'efw_esvy_mgse_'+[$
        'vxb_removed_spinfit_'+bps, $
        'vxb_removed_spinfit_edotb_'+bps, $
        'vxb_removed_coro_removed_spinfit_'+bps, $
        'vxb_removed_coro_removed_spinfit_edotb_'+bps ]
    ; Sheng: not applied?
;    eclipse_index = where(flag_arr[*,1,0] eq 1, count)
;    if count ne 0 then begin
;        foreach e_var, e_vars do begin
;            get_data, e_var, times, e_vec
;            e_vec[eclipse_index,*] = fillval
;            store_data, e_var, times, e_vec
;        endforeach
;    endif


;---Save E field data.
    old_names = 'efield_'+[$
        'inertial_spinfit_mgse_', $
        'inertial_spinfit_edotb_mgse_', $
        'corotation_spinfit_mgse_', $
        'corotation_spinfit_edotb_mgse_' ]
    new_names = 'efield_in_'+[$
        'inertial_frame_spinfit_mgse_', $
        'inertial_frame_spinfit_edotb_mgse_', $
        'corotation_frame_spinfit_mgse_', $
        'corotation_frame_spinfit_edotb_mgse_' ]
    e_vars = rbx+'efw_esvy_mgse_'+[$
        'vxb_removed_spinfit_', $
        'vxb_removed_spinfit_edotb_', $
        'vxb_removed_coro_removed_spinfit_', $
        'vxb_removed_coro_removed_spinfit_edotb_' ]
    foreach bp, bps, bp_id do begin
        cdf_old_vars = old_names+bp
        cdf_new_vars = new_names+bp
        vars = e_vars+bp
        foreach var, vars, var_id do begin
            cdf_varrename, cdfid, cdf_old_vars[var_id], cdf_new_vars[var_id]
            cdf_varput, cdfid, cdf_new_vars[var_id], transpose(get_var_data(var))
        endforeach
        all_saved_vars.add, cdf_new_vars, /extract
    endforeach


;---Load SPICE and save data.
    ; Sheng: once/min cadence?
	rbsp_read_spice_var, time_range, probe=sc
	spice_vars = rbx+['state_'+['pos_gse','vel_gse','mlt','mlat','lshell'],$
	   'spinaxis_direction_gse']
    foreach var, spice_vars do begin
        interp_time, var, common_times
    endforeach

    cdf_vars = ['position_gse','velocity_gse','mlt','mlat','lshell','spinaxis_gse']
    foreach cdf_var, cdf_vars, var_id do begin
        cdf_varput, cdfid, cdf_var, transpose(get_var_data(spice_vars[var_id]))
    endforeach
    all_saved_vars.add, cdf_vars, /extract



;---Load and save spacecraft potential.
    rbsp_load_efw_waveform, probe=probe, datatype='vsvy', coord='uvw', noclean=1
    l1_efw_var = 'rbsp'+probe+'_efw_vsvy'
    get_data, l1_efw_var, times, vsvy

    rbsp_efw_read_l1_time_tag_correction, probe=probe
    get_data, rbx+'_l1_time_tag_correction', start_times, time_ranges, corrections
    nsection = n_elements(corrections)
    if n_elements(time_ranges) le 1 then nsection = 0
    var_updated = 0
    for ii=0, nsection-1 do begin
        tmp = where(times ge time_ranges[ii,0] and times le time_ranges[ii,1], count)
        if count eq 0 then continue
        var_updated = 1
        ; Have to find the closest time, otherwise the index can be 1 record off.
        if min(times) ge time_ranges[ii,0] then i0 = 0 else begin
            index = min(times-time_ranges[ii,0], /absolute, i0)
        endelse
        if max(times) le time_ranges[ii,1] then i1 = n_elements(times) else begin
            index = min(times-time_ranges[ii,1], /absolute, i1)
        endelse
        times[i0:i1-1] += corrections[ii]
    endfor
    if var_updated then store_data, l1_efw_var, times, vsvy

    interp_time, l1_efw_var, common_times
    vsvy = get_var_data(l1_efw_var)
    cdf_old_vars = 'vsvy_vavg_combo_'+bps
    cdf_new_vars = 'spacecraft_potential_'+bps
    foreach bp, bps, bp_id do begin
        cdf_varrename, cdfid, cdf_old_vars[bp_id], cdf_new_vars[bp_id]
        index = fix([strmid(bp,0,1),strmid(bp,1,1)])-1
        data = total(vsvy[*,index],2)*0.5
        cdf_varput, cdfid, cdf_new_vars[bp_id], transpose(data)
    endforeach
    all_saved_vars.add, cdf_new_vars, /extract



;---Subtract model B field.
    models = ['t89','igrf']
    pos_var = rbx+'state_pos_gsm'
    cotrans,rbx+'state_pos_gse', pos_var, /gse2gsm
    ndim = 3
    re1 = 1d/6378.
    rgsm = get_var_data(pos_var)*re1
    par = 2

    b_t89_gsm = fltarr(ncommon_time,ndim)
    b_igrf_gsm = fltarr(ncommon_time,ndim)
    foreach time, common_times, time_id do begin
        tilt = geopack_recalc(time)
        rx = rgsm[time_id,0]
        ry = rgsm[time_id,1]
        rz = rgsm[time_id,2]

        geopack_igrf_gsm, rx,ry,rz, bx,by,bz
        geopack_t89, par, rx,ry,rz, dbx,dby,dbz
        b_igrf_gsm[time_id,*] = [bx,by,bz]
        b_t89_gsm[time_id,*] = b_igrf_gsm[time_id,*]+[dbx,dby,dbz]
    endforeach
    b_t89_mgse = cotran(b_t89_gsm, common_times, 'gsm2mgse', probe=probe)
    b_igrf_mgse = cotran(b_igrf_gsm, common_times, 'gsm2mgse', probe=probe)
    store_data, rbx+'mag_mgse_t89', common_times, b_t89_mgse
    store_data, rbx+'mag_mgse_igrf', common_times, b_igrf_mgse

    b_mgse = get_var_data(rbx+'b_mgse')
    bfield_magnitude = snorm(b_mgse)
    foreach model, models do begin
        data = get_var_data(rbx+'mag_mgse_'+model)
        var = rbx+'mag_mgse_mag_dif_'+model
        store_data, var, common_times, bfield_magnitude-snorm(data)
        var = rbx+'mag_mgse_'+model+'_dif'
        store_data, var, common_times, b_mgse-data
    endforeach

    cdf_prefix = 'bfield_'+['minus_model_mgse_','model_mgse_','magnitude_minus_modelmagnitude_']
    foreach model, models do begin
        cdf_vars = cdf_prefix+model
        vars = rbx+'mag_mgse_'+[model+'_dif',model,'mag_dif_'+model]
        foreach var, vars, var_id do begin
            cdf_varput, cdfid, cdf_vars[var_id], transpose(get_var_data(var))
        endforeach
        all_saved_vars.add, cdf_vars, /extract
    endforeach


;---Load all the HSK data, if required
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
    all_saved_vars.add, cdf_vars, /extract


;;---Add label vars.
;    all_saved_vars.add, /extract, [$
;        'angle_Ey_Ez_Bo_LABL_1', $
;        'bfield_labl', $
;        'bfield_minus_model_mgse_LABL_1', $
;        'bias_current_LABL_1', $
;        'diagBratio_labl', $
;        'efield_mgse_LABL_1', $
;        'efw_flags_labl', $
;        'flag_labl', $
;        'guard_voltage_LABL_1', $
;        'metavar0', $
;        'metavar3', $
;        'metavar5', $
;        'pos_gse_LABL_1', $
;        'usher_voltage_LABL_1', $
;        'vel_gse_LABL_1']
;
;
;;---Delete vars that are not used.
;    foreach cdf_var, cdf_vars(cdfid) do begin
;        if all_saved_vars.where(cdf_var) ne !null then continue
;        cdf_vardelete, cdfid, cdf_var
;    endforeach

    cdf_close, cdfid
    cdf_del_unused_vars, file


;---Add orbit_num.
    phasef_add_orbit_num_to_l4, date, probe=probe, filename=file


end

;stop
;probes = ['b']
;days = time_double([$
;    '2015-09-15', $
;    '2015-09-16', $
;    '2015-10-10', $
;    '2015-10-11', $
;    '2015-10-12', $
;    '2016-01-24', $
;    '2016-05-18', $
;    '2017-01-11', $
;    '2017-01-12', $
;    '2018-03-25', $
;    '2018-09-03', $
;    '2019-05-14', $
;    '2019-05-15' ])
;
;root_dir = join_path([default_local_root(),'rbsp'])
;foreach probe, probes do begin
;    prefix = 'rbsp'+probe+'_'
;    rbspx = 'rbsp'+probe
;    foreach day, days do begin
;        str_year = time_string(day,tformat='YYYY')
;        path = join_path([root_dir,rbspx,'level4',str_year])
;        base = prefix+'efw-l4_'+time_string(day,tformat='YYYYMMDD')+'_v03.cdf'
;        file = join_path([path,base])
;        if file_test(file) eq 1 then continue
;        rbsp_efw_read_l4_gen_file, day, probe=probe, filename=file
;    endforeach
;endforeach


;;stop
;probes = ['b']
;root_dir = join_path([default_local_root(),'rbsp'])
;foreach probe, probes do begin
;    prefix = 'rbsp'+probe+'_'
;    rbspx = 'rbsp'+probe
;    time_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-14']): time_double(['2012-09-08','2019-07-16'])
;    days = make_bins(time_range, constant('secofday'))
;    foreach day, days do begin
;        str_year = time_string(day,tformat='YYYY')
;        path = join_path([root_dir,rbspx,'level4',str_year])
;        base = prefix+'efw-l4_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
;        file = join_path([path,base])
;        if file_test(file) eq 1 then continue
;        rbsp_efw_read_l4_gen_file, day, probe=probe, filename=file
;    endforeach
;endforeach
;
;stop


date = '2017-09-07'
probe = 'a'
file = join_path([homedir(),'test_level4.cdf'])
tic
rbsp_efw_read_l4_gen_file, date, probe=probe, file=file
toc
end
