;+
; Read EFW burst data. Save data in rbspx_efw_eb1_<coord>.
;
; datatype can be 'vb1','vb2'.
;
; coord=. A lower case string sets the coordinate of the output data. 'mgse' by default.
; keep_spin_axis=. A boolean, set to keep the spin axis E field. 0 by default.
; keep_shadow_spike=. A boolean, set to keep shadow spike. 0 by default.
;-

pro rbsp_efw_read_l1_burst_efield, tr, probe=probe, $
    datatype=datatype, trange=trange, $
    coord=coord, keep_spin_axis=keep_spin_axis, $
    apply_dc_flag=apply_dc_flag, $
    keep_shadow_spike=keep_shadow_spike, $
    level=level, verbose=verbose, downloadonly=downloadonly, $
    cdf_data=cdf_data,get_support_data=get_support_data, $
    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
    varformat=varformat, valid_names=valid_names, files=files, $
    type=type, _extra=_extra

    rbsp_efw_init
    vb = keyword_set(verbose) ? verbose : 0
    vb = vb > !rbsp_efw.verbose

    if n_elements(coord) eq 0 then coord = 'mgse'
    if n_elements(keep_spin_axis) eq 0 then keep_spin_axis = 0
    if n_elements(datatype) eq 0 then datatype = 'vb1-split'

    data_types = ['vb1','vb2','vb1-split']
    data_type = datatype[0]
    index = where(data_types eq data_type, count)
    if count eq 0 then begin
        dprint, 'Invalid datatype: '+data_type+' ...', verbose=vb
        return
    endif
    if data_type eq 'vb1-split' then begin
        rbsp_efw_read_l1_burst_split, tr, probe=probe, $
            datatype=data_type, trange=trange, $
            level=level, verbose=verbose, downloadonly=downloadonly, $
            cdf_data=cdf_data,get_support_data=get_support_data, $
            tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
            varformat=varformat, valid_names=valid_names, files=files, $
            type=type, _extra=_extra
    endif else begin
        rbsp_efw_read_l1, tr, probe=probe, $
            datatype=data_type, trange=trange, $
            level=level, verbose=verbose, downloadonly=downloadonly, $
            cdf_data=cdf_data,get_support_data=get_support_data, $
            tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
            varformat=varformat, valid_names=valid_names, files=files, $
            type=type, _extra=_extra
    endelse


;---Calbirate E field.
    prefix = 'rbsp'+probe+'_'
    if data_type eq 'vb2' then begin
        data_type2 = 'vb2'
    endif else begin
        data_type2 = 'vb1'
    endelse
    v_var = prefix+'efw_'+data_type2
    get_data, v_var, data=dd
    if size(dd,/type) ne 8 then begin
        errmsg = 'No data ...'
        return
    endif
    store_data, v_var, dlimits={data_att:{units:'ADC'}}
    time_range = time_double(tr)
    timespan, time_range[0], total(time_range*[-1,1]), second=1
    rbsp_efw_cal_waveform, probe=probe, datatype=data_type2, trange=time_range

    ; Convert vsvy to esvy.
    cp0 = rbsp_efw_get_cal_params(time_range[0])
    cp = (probe eq 'a')? cp0.a: cp0.b
    boom_length = cp.boom_length
;    boom_shorting_factor = cp.boom_shorting_factor

    get_data, v_var, times, vsvy
    ntime = n_elements(times)
    ndim = 3
    esvy = dblarr(ntime,ndim)
    for eid=0,ndim-1 do begin
        vid = eid*2
        coef = 1d3/boom_length[eid]
        ;coef = 1d
        esvy[*,eid] = (vsvy[*,vid]-vsvy[*,vid+1])*coef
    endfor

    data_type3 = 'e'+strmid(data_type2,1,2)
    in_var = prefix+'efw_'+data_type3
    store_data, in_var, times, esvy

;---Remove DC offset, use E UVW.
    survey_time_range = minmax(times)+[-1,1]*30
    rbsp_efw_phasef_read_dc_offset, survey_time_range, probe=probe
    get_data, prefix+'efw_e_uvw_dc_offset', uts, euvw_offset
    esvy -= sinterpol(euvw_offset, uts, times)
    store_data, in_var, times, esvy


;---Spin-axis data.
    if ~keyword_set(keep_spin_axis) then begin
        esvy[*,2] = 0
        store_data, in_var, times, esvy
    endif
    

;---Convert vector from UVW to wanted coord.
    rgb = [6,4,2]
    xyz = ['x','y','z']
    get_data, in_var, times, vec, limits=lim
    vec = cotran(vec, times, 'uvw2'+coord[0], probe=probe, use_orig_quaternion=1)
    out_var = in_var+'_'+coord[0]
    store_data, out_var, times, vec, limits={$
        ytitle:prefix+'burst_efield!C[mV/m]', $
        labels:strupcase(coord)+' E'+xyz, $
        colors:rgb }
        
    ; Load shadow flag.
    if ~keyword_set(keep_shadow_spike) then begin
        shadow_trs = rbsp_efw_phasef_read_shadow_spike_time(time_range, probe=probe)
        index = where(shadow_trs[*,0] le max(times) and shadow_trs[*,1] ge min(times), ntr)
        if ntr ne 0 then begin
            get_data, out_var, times, esvy
            shadow_trs = shadow_trs[index,*]
            for ii=0,ntr-1 do begin
                index = lazy_where(times, '[]', shadow_trs[ii,0]+[-1,1]*0.3, count=count)
                if count eq 0 then continue
                esvy[index,0] = !values.f_nan
            endfor
            store_data, out_var, times, esvy
        endif
    endif
    
    ; Load flags.
    if keyword_set(apply_dc_flag) then begin
        rbsp_efw_phasef_read_flag_25, time_range, probe=probe
        get_data, out_var, times, esvy
        global_flags = get_var_data(prefix+'flag_25', at=times)
        index = where(global_flags ne 0, count)
        if count ne 0 then begin
            esvy[index,*] = !values.f_nan
            store_data, out_var, times, esvy
        endif
    endif
    

if keyword_set(test) then begin
    vars = prefix+'efw_eb1'+['','_mgse']
    options, vars, 'colors', constant('rgb')
    tplot_options, 'labflag', -1
    options, vars[0], 'labels', 'UVW E'+['u','v','w']
    options, vars, 'ytitle', ' '
    options, vars, 'ysubtitle', '(mV/m)'
    tplot_options, 'version', 1
    plot_file = join_path([homedir(),'fig_rbsp_efw_phasef_example_shadow_spike_removal.pdf'])
;plot_file = 0
    sgopen, plot_file, xsize=6, ysize=4
    poss = sgcalcpos(2,margins=[8,4,8,1], xchsz=xchsz, ychsz=ychsz)
    tplot, vars, trange=['2013-06-07/02:17:40','2013-06-07/02:18:20'], position=poss
    timebar, shadow_trs[*,0], color=sgcolor('yellow')
    tpos = poss[*,0]
    tx = tpos[0]+xchsz*1
    ty = tpos[3]-ychsz*1
    xyouts, tx,ty, normal=1, strupcase('RBSP-'+probe)+' Burst1 E field'
    sgclose
    stop
endif
    
end


; Set the time and probe for loading data.
time_range = ['2013-06-10/05:57:20','2013-06-10/05:59:40']
probe = 'b'

time_range = ['2013-06-07/02:17:40','2013-06-07/02:19:20']
probe = 'a'

; Load the spinfit data.
rbsp_efw_read_l1_burst_efield, time_range, probe=probe, $
    datatype='vb1-split', coord='mgse', keep_spin_axis=1, apply_dc_flag=1

prefix = 'rbsp'+probe+'_efw_'
vars = prefix+[$

    ; The E field in UVW.
    'eb1_mgse' ]

; Plot the variables.
tplot, vars, trange=time_range



end
